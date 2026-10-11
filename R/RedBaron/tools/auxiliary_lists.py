"""Compare complete native 16/12-byte auxiliary lists without pointer masking."""
import argparse
import hashlib
import json
from pathlib import Path
from auxiliary_pools import payload
from aircraft_pool import check as aircraft_check
from game_heap import allocations, exact
from hunks import read_hunks
from player_links import SIM_SHA
from render_mutations import Snapshot, region
from world_comparison import load


def state(read, h3, extents):
    u = lambda at, n: int.from_bytes(exact(read, h3 + at, n), 'big')
    lists = []
    for root, count, stride in ((0x57d4, 0x57de, 16), (0x57d8, 0x57e0, 12)):
        # This capture contract requires a populated, exactly owned allocation.
        # Empty/freed lists need separate lifecycle evidence, not guessed sizes.
        raw = payload(read, extents, u(root, 4), u(count, 2), stride)
        lists.append(dict(stride=stride, count=u(count, 2), raw=raw.hex(),
                          active=sum(any(raw[i:i+4]) for i in range(0, len(raw), stride))))
    return dict(lists=lists, controls=exact(read, h3+0x57de, 6).hex(),
                raw_roots=exact(read, h3+0x57d4, 8))


def equal(a, b):
    for key in ('lists', 'controls'):
        if a[key] != b[key]:
            raise ValueError('Complete auxiliary list state differs: ' + key)


def contracts(h3):
    a = lambda off: (h3+off).to_bytes(4, 'big')
    b = bytes.fromhex
    return {
        0x1186a: b('33c0')+a(0x57de),
        0x1188a: b('33c1')+a(0x57e0),
        0x118a6: b('e940'),
        0x118be: b('23c0')+a(0x57d4),
        0x118e6: b('3039')+a(0x57e0)+b('6744c0fc000c'),
        0x1190a: b('23c0')+a(0x57d8),
        0x119d8: b('2b79')+a(0x57d4)+b('fffcbc79')+a(0x57de),
        0x119f0: b('208b43e800062c4a22de3296'),
        0x11a0c: b('7010d1adfffc'),
        0x11ae2: b('2479')+a(0x57d8)+b('be79')+a(0x57e0),
        0x11af4: b('248b700035400004'),
        0x11b10: b('d4fc000c'),
        0x11d00: b('2b79')+a(0x57d8)+b('fff4ba79')+a(0x57e0),
        0x11d22: b('5269000a0c697530000a'),
    }


def check(original, left, right):
    raw = original.read_bytes()
    if hashlib.sha256(raw).hexdigest() != SIM_SHA: raise ValueError('Unsupported sim')
    code = read_hunks(raw)[0].data
    for at, data in contracts(0).items():
        if code[at:at+len(data)] != data: raise ValueError(f'Original list contract {at:x}')
    prior = aircraft_check(original, left, right)
    roots = (left, right); loaded = [load(p) for p in roots]
    sequences = [[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0]) != len(sequences[1]): raise ValueError('Unequal checkpoint sequences')
    rows = []
    for index, banks in enumerate(zip(*sequences)):
        states = []
        for root, m, bank in zip(roots, loaded, banks):
            ram = Snapshot(root, bank); h3 = m[1]['h3']; sim = m[0]['entry']['sim']
            for at, data in contracts(h3).items():
                if exact(ram.read, sim+at, len(data)) != data: raise ValueError('Changed live list contract')
            states.append(state(ram.read, h3, allocations(ram.read, h3)))
        a, b = states; equal(a, b)
        rows.append(dict(boundary='initial' if not index else index-1, lists=a['lists'],
                         controls=a['controls'], raw_root_differences=region(a['raw_roots'], b['raw_roots'])))
    return dict(sha256=prior['sha256'], sim_sha256=SIM_SHA, rows=rows,
                scope='Complete 16/12-byte lists and six control bytes at retained equal-tick checkpoints. All owner pointers, inactive slots and tails compared raw; only allocation-root addresses may differ, with exact allocation ownership checked. No recursive owner-state, free/reload, all-combat, capacity or gameplay-speed verdict.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    for name in ('original', 'left', 'right'): p.add_argument(name, type=Path)
    p.add_argument('--out', type=Path, required=True); a = p.parse_args()
    result = check(a.original, a.left, a.right)
    a.out.write_text(json.dumps(result, indent=2)+'\n')
    print('Complete auxiliary lists match at', len(result['rows']), 'checkpoints')
