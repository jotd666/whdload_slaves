"""Model original sim:192d8 impact grading and check observed player contacts.

This covers the grading routine, not collision detection, aerodynamic convergence
or safe landing. The synthetic descent is never a performance sample.
"""
import argparse
import hashlib
import json
from pathlib import Path
from hunks import read_hunks


def word(n):
    return ((n+32768) & 65535)-32768


def grade(angle0, angle1, horizontal, vertical, prior, hlimit, vlimit,
          angle_limit, upper_angle, lower_angle):
    values = (angle0, angle1, horizontal, vertical, hlimit, vlimit,
              angle_limit, upper_angle, lower_angle)
    if any(not -32768 <= v <= 32767 for v in values) or not -128 <= prior <= 127:
        raise ValueError('Inputs outside native signed widths')
    damage = prior
    # Native ABS special-cases the most-negative word to +32767.
    pitch = 32767 if angle1 == -32768 else abs(angle1)
    unsafe = (angle0 > upper_angle or angle0 < lower_angle or
              pitch > angle_limit or horizontal > hlimit)
    if unsafe:
        severity = 1 if horizontal <= hlimit >> 1 else 2 if horizontal <= hlimit else 3
        damage = max(damage, severity)
    descent = word(-vertical)
    if descent > vlimit:
        severity = (1 if descent <= word(vlimit*2) else
                    2 if descent <= word(vlimit*4) else 3)
        damage = max(damage, severity)
    return damage & 255


def observed(frames):
    pairs = []
    for frame in frames:
        starts, ends = frame['contacts'], frame['impacts']
        if len(starts) != len(ends):
            raise ValueError('Incomplete or unmatched impact calls')
        for start, end in zip(starts, ends):
            if len(start) != 11 or len(end) != 5:
                raise ValueError('Truncated impact observation')
            tick, *args = start
            if end[0] != tick or end[1]+1 != tick:
                raise ValueError('Impact not inside the observed in-progress world tick')
            expected = grade(*args)
            if end[4] != expected:
                raise ValueError('Native impact grade differs from model')
            pairs.append(dict(tick=tick, inputs=args, grade=expected,
                              altitude_before_correction=end[2], vertical_velocity=end[3]))
    if not pairs:
        raise ValueError('No native player impact observed')
    return pairs


def check(original, capture):
    raw = original.read_bytes()
    code = read_hunks(raw)[0].data
    digest = hashlib.sha256(code[0x192d8:0x193aa]).hexdigest()
    if digest != '7482e546b20dbe65777067a6448b7fe3cadf8fb9aca36f1da61dc947c2987d16':
        raise ValueError('Unsupported original impact-grading routine')
    data = json.loads((capture/'poses.json').read_text())
    entry = json.loads((capture/'entry.json').read_text())
    if entry['slave_sha256'] != data['sha256']:
        raise ValueError('Capture build identity mismatch')
    return dict(sha256=data['sha256'], sim_sha256=hashlib.sha256(raw).hexdigest(),
                routine_sha256=digest, contacts=observed(data['frames']),
                scope='Observed native impact grading only; no collision-detection, landing or physics-convergence verdict.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('original',type=Path)
    p.add_argument('capture',type=Path)
    p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.original,a.capture)
    a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
