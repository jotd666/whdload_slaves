#!/usr/bin/env python3
"""Summarize retained W6 probes; fail if their comparison boundaries differ."""
import argparse
import json
import math
from pathlib import Path
from player_kinematics import audit


def load_players(base):
    rows = {}
    for path in sorted(base.glob('players*/players.json')):
        for row in json.loads(path.read_text()):
            if row['step'] in rows and row != rows[row['step']]:
                raise ValueError('Overlapping samples disagree')
            rows[row['step']] = row
    if not rows or sorted(rows) != list(range(1, max(rows)+1)):
        raise ValueError('Missing player sample')
    return rows


def probe_summary(root):
    ground = {}
    for dt in (100, 225, 450, 900, 2200):
        data = json.loads((root / f'w6-ground-{dt}/ground-result.json').read_text())
        impacts = [e for e in data['events'] if e[0] == 'impact']
        if len(impacts) != 1 or data['flight_ended'] or data['last_step'] != 11:
            raise ValueError('Unexpected ground fixture boundary')
        e = impacts[0]
        ground[dt] = dict(step=int(e[1]), primary_time=int(e[1])*dt,
                          vertical_position=int(e[3]), vertical_velocity=int(e[4]), damage=int(e[5]))
    weapons = {}
    for dt in (225, 900):
        data = json.loads((root / f'w6-fire-{dt}/projectiles.json').read_text())
        moves = [e for e in data['events'] if e['kind'] == 'move']
        player = [e for e in moves if e['owner'] == data['player']]
        first = []
        for e in player:
            if e['object'] != player[0]['object']:
                continue
            if first and e['life'] >= first[-1]['life']:
                break  # Reused allocation, not the first projectile's lifetime.
            first.append(e)
        hits = [e for e in data['events'] if e['kind'] == 'result' and e['d0'] != 0]
        weapons[dt] = dict(player_queries=len(player), npc_queries=len(moves)-len(player),
                           first_moves=len(first), first_life=[first[0]['life'], first[-1]['life']],
                           first_distance=sorted({e['distance'] for e in first}),
                           first_path_raw=sum(math.dist(e['old'], e['new']) for e in first),
                           hits=[dict(step=e['step'], player_owned=e['owner'] == data['player']) for e in hits])
    return dict(ground=ground, weapons=weapons)


def summarize(root):
    forced = {dt: load_players(root / f'w6-force-{dt}') for dt in (100, 225, 450, 900, 2200)}
    first = forced[100][1]
    baseline = (root / 'w6-force-100/entry-h3.bin').read_bytes()
    for dt in forced:
        base = root / f'w6-force-{dt}'
        initial = (base / 'entry-h3.bin').read_bytes()
        differences = [i for i, (a, b) in enumerate(zip(baseline, initial)) if a != b]
        if len(initial) != len(baseline) or any(i not in (0x4834, 0x4835) for i in differences):
            raise ValueError('Forced entry h3 differs outside its explicit primary clock')
        for path in base.glob('players*/steps.json'):
            records = json.loads(path.read_text())['records']
            if any(r['dt'] != dt for r in records):
                raise ValueError('Forced primary clock was not observed')
            if any(b['world_frames'] != a['world_frames']+1 for a, b in zip(records, records[1:])):
                raise ValueError('Not one world update per recorded frame')
    for rows in forced.values():
        if rows[1] != first:
            raise ValueError('Forced runs do not share the same initial player')
    comparisons = []
    for total, values in ((9900, (100, 225, 450, 900)), (8800, (100, 2200)), (19800, (225, 450, 900, 2200))):
        group = []
        for dt in values:
            end = 1 + total // dt
            assert total % dt == 0
            rows = forced[dt]
            distance = sum(math.dist(rows[i]['position'], rows[i+1]['position']) for i in range(1, end))
            group.append(dict(dt=dt, steps=end-1, path_raw=distance, endpoint=rows[end]['position'],
                              orientation=rows[end]['orientation'], velocity=rows[end]['body_velocity_f4']))
        for row in group:
            row['path_difference_percent'] = 100*(row['path_raw']/group[0]['path_raw']-1)
        comparisons.append(dict(primary_time=total, reference_dt=values[0], rows=group))
    audits = []
    for dt in forced:
        # The later 100-unit run leaves this airborne model's domain at step 165.
        # Retain that failure; do not silently filter individual coordinate mismatches.
        paths = sorted((root / f'w6-force-{dt}').glob('players*/players.json'))
        for path in paths:
            if dt == 100 and path.parent.name != 'players-1-100':
                continue
            audits.append(dict(dt=dt, directory=path.parent.name, result=audit(path.parent)))
    pairs, scopes = [], []
    starts = []
    for mode in ('normal', 'slow'):
        base = root / f'w6-tracking-{mode}'
        starts.append((base / 'entry-h3.bin').read_bytes())
        rows = load_players(base)
        records = json.loads((base / 'players/steps.json').read_text())['records']
        if [r['step'] for r in records] != sorted(rows):
            raise ValueError('Tracking step log mismatch')
        if any(r['dt'] in (64, 450) for r in records):
            raise ValueError('Tracking capture reached scalar floor/clamp')
        pairs.append({r['ticks']-records[0]['ticks']: (r, rows[r['step']]) for r in records})
        scopes.append(dict(mode=mode, fields=records[-1]['vbl']-records[0]['vbl'],
                           cia_ticks=records[-1]['ticks']-records[0]['ticks'],
                           dt_values=sorted({r['dt'] for r in records}),
                           above_400=[r['step'] for r in records if r['dt'] > 400]))
    if starts[0] != starts[1]:
        raise ValueError('Tracking entry h3 differs')
    shared = []
    for tick in sorted(set(pairs[0]) & set(pairs[1])):
        a, b = pairs[0][tick], pairs[1][tick]
        shared.append(dict(cia_ticks=tick, steps=[a[0]['step'], b[0]['step']],
                           position_distance_raw=math.dist(a[1]['position'], b[1]['position'])))
    return dict(forced=comparisons, airborne_audits=audits, probes=probe_summary(root),
                tracking=dict(entry_h3_equal=True, runs=scopes, shared=shared),
                scope='Forced clocks are experimental. Raw positions, not physical units. Shared CIA boundaries use no trajectory interpolation.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('root', type=Path)
    p.add_argument('--out', type=Path, required=True)
    args = p.parse_args()
    result = summarize(args.root)
    args.out.write_text(json.dumps(result, indent=2)+'\n')
    print('Validated forced boundaries, airborne model checks and', len(result['tracking']['shared']), 'shared CIA checkpoints')
