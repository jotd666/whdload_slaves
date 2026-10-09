#!/usr/bin/env python3
"""Check native velocity conversion and airborne position integration against snapshots.

This models sim:18364/18398/183fa, sim:1918a..19234 and sim:3d68.
It does not model the forces that produce the observed new velocity, or ground contact.
"""
import argparse
import json
import struct
from pathlib import Path
from player_motion import summarize


def word(value):
    return (value + 32768) % 65536 - 32768


def scaled_delta(velocity, dt):
    velocity = word(velocity)
    value = word(velocity * 2) if dt > 400 else (velocity * dt) >> 8
    return max(-32767, min(32767, value))


def integrate(position, fraction, old_velocity, new_velocity, wind, dt, factor):
    velocity = word((word(old_velocity + new_velocity) >> 1) + wind)
    delta = scaled_delta(velocity, dt)
    product = delta * factor
    remainder = (abs(product) & 1023) * (-1 if delta < 0 else 1)
    fraction = word(fraction + remainder)
    carry = 1 if fraction > 1023 else -1 if fraction < -1023 else 0
    fraction = word(fraction - carry * 1024)
    # The original combines arithmetic right shift with a signed remainder.
    # Preserve its negative-direction rounding; do not substitute truncating division.
    increment = word((product >> 10) + carry)
    position = (position + increment + 2**31) % 2**32 - 2**31
    return position, fraction


def audit(directory):
    motion = summarize(directory)
    rows = json.loads((directory / 'players.json').read_text())
    ring = {r['step']: r for r in json.loads((directory / 'steps.json').read_text())['records']}
    first = (directory / f'h3-{rows[0]["step"]}.bin').read_bytes()
    last = (directory / f'h3-{rows[-1]["step"]}.bin').read_bytes()
    for start, end in [(0x72a6, 0x72a8), (0x1c54, 0x1c60), (0x1c86, 0x1c9e)]:
        if first[start:end] != last[start:end]:
            raise ValueError('Conversion factor or wind table changed')
    factor = struct.unpack_from('>h', first, 0x72a6)[0]
    limits = struct.unpack_from('>3i', first, 0x1c54)
    winds = [struct.unpack_from('>3h', first, 0x1c86 + 6*i) for i in range(4)]
    velocity_checks = coordinate_checks = 0
    for row in rows:
        raw = (directory / f'player-{row["step"]}.bin').read_bytes()
        if tuple(row['position']) != struct.unpack_from('>3i', raw, 8) or tuple(row['velocity_fa']) != struct.unpack_from('>3h', raw, 0xfa):
            raise ValueError('JSON position/velocity differs from the retained object')
        native = struct.unpack_from('>6h', raw, 0xf4)
        converted = struct.unpack_from('>6h', raw, 0xca)
        if tuple(word((v*factor) >> 10) for v in native) != converted:
            raise ValueError(f'Native velocity conversion mismatch at step {row["step"]}')
        velocity_checks += 6
    for left, right in zip(rows, rows[1:]):
        a = (directory / f'player-{left["step"]}.bin').read_bytes()
        b = (directory / f'player-{right["step"]}.bin').read_bytes()
        before = struct.unpack_from('>3h', a, 0x100)
        after = struct.unpack_from('>3h', b, 0x100)
        wind = winds[sum(left['position'][2] > bound for bound in limits)]
        dt = ring[left['step']]['dt']
        for axis in range(3):
            predicted = integrate(left['position'][axis], before[axis],
                left['velocity_fa'][axis], right['velocity_fa'][axis], wind[axis], dt, factor)
            if predicted != (right['position'][axis], after[axis]):
                raise ValueError(f'Position/remainder mismatch at step {left["step"]}, axis {axis}')
            coordinate_checks += 1
    # Nominal here means the unclamped elapsed-time coefficient, not physical mph.
    nominal = [r['body_velocity_f4'][1] * factor / 1024 * 4 / motion['F'] for r in rows]
    return dict(time_scale=motion['time_scale'], F=motion['F'], conversion_factor=factor,
        velocity_checks=velocity_checks, coordinate_checks=coordinate_checks,
        all_equal=True, native_forward_values=motion['forward_f6_values'],
        nominal_forward_raw_units_per_cia_tick=[min(nominal), max(nominal)],
        measured_path_raw_units_per_cia_tick=motion['distance_raw']/motion['cia_ticks'],
        notice='Observed airborne velocity history is input. Forces, ground contact and physical distance units are outside this check.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    print(json.dumps(audit(parser.parse_args().directory), indent=2))
