#!/usr/bin/env python3
"""Summarize retained per-step player samples without assuming physical units.

Input directory: players.json, steps.json and h3-LAST.bin from the read-only
flight-anchor collector. Cross-check every sampled position/orientation against
sim:15128's native history. CIA/VBlank time is emulated time, not debugger time.
"""
import argparse
import json
import math
from pathlib import Path
from player_history import decode


def summarize(directory):
    players = json.loads((directory / 'players.json').read_text())
    if not 2 <= len(players) <= 100:
        raise ValueError('Need 2..100 consecutive samples for the native-history check')
    steps = [r['step'] for r in players]
    if steps != list(range(steps[0], steps[-1] + 1)):
        raise ValueError('Player samples are not consecutive')
    records = json.loads((directory / 'steps.json').read_text())['records']
    if len({r['step'] for r in records}) != len(records):
        raise ValueError('Duplicate step-ring records')
    ring = {r['step']: r for r in records}
    samples = [ring[n] for n in steps]
    if any(b['vbl'] <= a['vbl'] or b['ticks'] <= a['ticks']
           for a, b in zip(samples, samples[1:])):
        raise ValueError('Non-increasing emulated clock')
    if any(b['world_frames'] != a['world_frames'] + 1
           for a, b in zip(samples, samples[1:])):
        raise ValueError('Expected exactly one world update per sampled step')
    history = decode((directory / f'h3-{steps[-1]}.bin').read_bytes(), len(players))['records']
    if any(a['position'] != b['position'] or a['orientation'] != b['orientation']
           for a, b in zip(players, history)):
        raise ValueError('Player samples disagree with native history')
    settings = {(r['time_scale'], r['F']) for r in samples}
    if len(settings) != 1:
        raise ValueError('Time Scale changed during the window')
    scale, divisor = settings.pop()
    fields = samples[-1]['vbl'] - samples[0]['vbl']
    distance = sum(math.dist(a['position'], b['position'])
                   for a, b in zip(players, players[1:]))
    return dict(first_step=steps[0], last_step=steps[-1], intervals=len(players)-1,
                time_scale=scale, F=divisor, fields=fields,
                cia_ticks=samples[-1]['ticks']-samples[0]['ticks'],
                dt_values=sorted({r['dt'] for r in samples}),
                distance_raw=distance, distance_raw_per_50_fields=distance*50/fields,
                forward_f6_values=sorted({r['body_velocity_f4'][1] for r in players}),
                native_history_equal=True,
                notice='Raw distance/velocity units; 50 fields is the reporting convention. Not an FPS benchmark or physical airspeed calibration.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('directory', type=Path)
    a = p.parse_args()
    print(json.dumps(summarize(a.directory), indent=2))
