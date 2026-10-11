"""Verify retained native modal pause boundaries without normalizing time debt."""
import argparse
import json
import struct
from pathlib import Path


def clock(data):
    if len(data) != 60:
        raise ValueError('Incomplete native clock')
    names = ['cursor', 'steps', 'skips', 'draws', 'active', 'paused', 'start', 'depth', 'base']
    offsets = [20, 28, 32, 36, 40, 44, 48, 52, 56]
    result = {name: struct.unpack_from('>I', data, at)[0] for name, at in zip(names, offsets)}
    result['phase'] = data[:20]
    result['due'], result['services'] = struct.unpack_from('>HH', data, 24)
    return result


def delta(after, before):
    result = (after - before) & 0xffffffff
    if result >= 0x80000000:
        raise ValueError('Invalid clock order')
    return result


def check(rows):
    if [r['label'] for r in rows] != ['before', 'entered', 'leaving', 'resumed', 'world']:
        raise ValueError('Missing native Preferences boundaries')
    before, entered, leaving, resumed, world = rows
    b, e, l, r, w = [row['clock'] for row in rows]
    if [c['active'] for c in (b,e,l,r,w)] != [1,0,0,1,1]:
        raise ValueError('Incorrect flight ownership across panel')
    if [c['depth'] for c in (b,e,l,r,w)] != [0,1,1,0,0]:
        raise ValueError('Incorrect modal nesting')
    for name in ('phase','due','services','steps','skips','draws'):
        if any(c[name] != b[name] for c in (e,l,r)):
            raise ValueError('Simulation clock advanced during Preferences: ' + name)
    if e['cursor'] != b['cursor'] or l['cursor'] != e['cursor']:
        raise ValueError('Cursor advanced while paused')
    if e['paused'] != b['paused'] or l['paused'] != e['paused']:
        raise ValueError('Paused total changed before resume')
    excluded = delta(r['paused'], e['paused'])
    if excluded < 100:
        raise ValueError('Insufficient panel dwell to test exclusion')
    if delta(r['cursor'], e['cursor']) != excluded:
        raise ValueError('Resume discarded pre-existing debt')
    lower = delta(leaving['cia'], e['start'])
    upper = delta(resumed['cia'], e['start'])
    if not lower <= excluded <= upper:
        raise ValueError('Excluded duration not bounded by observed resume')
    if any(row['completed'] != before['completed'] for row in (entered,leaving,resumed)):
        raise ValueError('World advanced inside Preferences')
    if any(row['player'] != entered['player'] or row['player_bytes'] != entered['player_bytes']
           for row in (leaving,resumed)):
        raise ValueError('Player changed inside Preferences')
    if resumed['dt'] != 225 or delta(world['completed'], resumed['completed']) != 1:
        raise ValueError('Fixed-step world did not resume')
    return dict(excluded_cia_ticks=excluded, modal_completed_world_updates=0,
                player_bytes_preserved=len(entered['player_bytes']),
                entry_debt=delta(entered['cia'], e['cursor']),
                resume_debt=delta(resumed['cia'], r['cursor']),
                limitation='Native modal boundary check with fixture inputs; not all modal paths or complete gameplay equivalence.')


def audit(path):
    metadata = json.loads(path.read_text())
    entry = json.loads((path.parent/'entry.json').read_text())
    if metadata['sha256'] != entry['slave_sha256']:
        raise ValueError('Capture identity mismatch')
    rows = []
    for row in metadata['rows']:
        label = row['label']
        row = dict(row, clock=clock((path.parent/f'prefs-{label}-clock.bin').read_bytes()),
                   player_bytes=(path.parent/f'prefs-{label}-player.bin').read_bytes())
        if len(row['player_bytes']) != 0x118:
            raise ValueError('Incomplete player record')
        rows.append(row)
    return dict(sha256=metadata['sha256'], **check(rows))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    result = audit(args.capture)
    args.out.write_text(json.dumps(result, indent=2)+'\n')
    print(result)
