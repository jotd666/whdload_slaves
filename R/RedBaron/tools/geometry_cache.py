"""Verify observed per-part vertex-cache epochs, hits and 32-bit misses.

This does not classify projected arrays or prove the absence of other consumers.
The 16-bit miss arithmetic is not modelled; its recorded results establish only
provenance for subsequent observed hits in the same epoch.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import struct
from render_mutations import Snapshot
from hunks import read_hunks
from transform_model import original, candidate

CONTRACTS = (
    (0x38dcc, 0x38e80, '6c9626ae8d3a4fcac85451d861d66258cae50df0a6360b61f5fcbf44cc950631'),
    (0x3a8b4, 0x3a902, '1311a03f820624159f2ee1e0ab019c4903641cd1b715fad8b5cd79fc35c0bf3a'),
    (0x3ab1c, 0x3acca, 'ce0729433df9125357257260635daa388ebf4d516204cd9ea47309df48734443'),
)


class Cache:
    def __init__(self, data=None):
        if data is not None and len(data) != 3*255*4:
            raise ValueError('Truncated coordinate arrays')
        self.data = bytearray(data) if data is not None else None
        self.count = None
        self.values = {}
        self.pending = None
        self.stats = Counter()

    def event(self, kind, row):
        if kind == 'RESET':
            if self.pending or len(row) != 2 or not 0 <= row[0] <= 255 or row[1] != 0:
                raise ValueError('Invalid reset or uncleared validity bytes')
            self.count = row[0]
            self.values.clear()
            self.stats['epochs'] += 1
        elif kind == 'FETCH':
            if self.pending or len(row) != 6:
                raise ValueError('Nested or malformed cache fetch')
            path, index, flag, *xyz = row
            if path not in (16, 17, 32) or self.count is None or not 0 <= index < self.count or flag not in (0, 1, 2, 3):
                raise ValueError('Fetch outside current part or unknown flag')
            if flag and self.values.get(index) != xyz:
                raise ValueError('Hit has no matching calculation in this epoch')
            self.pending = dict(path=path, index=index, flag=flag, expected=xyz if flag else None)
        elif kind == 'INPUT':
            p = self.pending
            if p is None or p['path'] != 32 or p['flag'] or p['expected'] is not None or len(row) != 17:
                raise ValueError('Unexpected transform inputs')
            v, matrix, mode, scale, pos = row[:3], row[3:12], row[12], row[13], row[14:]
            if any(not 0 <= x <= 65535 for x in v+matrix+[scale]) or not 0 <= mode <= 255 or any(not 0 <= x <= 0xffffffff for x in pos):
                raise ValueError('Transform inputs exceed native widths')
            a = original(v, matrix, mode, scale)
            b = candidate(v, matrix, mode, scale)
            if a != b:
                raise ValueError('Independent transform models disagree')
            p['expected'] = [(x+y) & 0xffffffff for x, y in zip(a, pos)]
        elif kind == 'RESULT':
            p = self.pending
            if p is None or len(row) != 9 or row[:2] != [p['path'], p['index']]:
                raise ValueError('Missing or mispaired cache result')
            path, index, flag, *rest = row
            xyz, scratch = rest[:3], rest[3:]
            if flag != (p['flag'] or 1) or any(not 0 <= x <= 0xffffffff for x in xyz):
                raise ValueError('Invalid result validity or coordinate width')
            if path == 32 and p['expected'] is None:
                raise ValueError('Missing 32-bit miss inputs')
            if p['expected'] is not None and xyz != p['expected']:
                raise ValueError('Cache result differs from transform or prior hit')
            mask = 0xffffffff if path == 32 else 65535
            if scratch != [x & mask for x in xyz]:
                raise ValueError('Scratch result differs from cached coordinates')
            self.values[index] = xyz
            if self.data is not None:
                for axis, value in enumerate(xyz):
                    struct.pack_into('>I', self.data, axis*1020+index*4, value)
            self.stats[f'{path}_{"hit" if p["flag"] else "miss"}'] += 1
            self.pending = None
        else:
            raise ValueError('Unknown geometry event')

    def checkpoint(self, data=None):
        if self.pending is not None:
            raise ValueError('Incomplete fetch at world boundary')
        if self.data is not None and data != self.data:
            raise ValueError('Unobserved coordinate-array mutation')


def check(original_path, root):
    raw = original_path.read_bytes()
    code = read_hunks(raw)[0].data
    for start, end, digest in CONTRACTS:
        if hashlib.sha256(code[start:end]).hexdigest() != digest:
            raise ValueError('Unsupported original vertex-cache routine')
    entry = json.loads((root/'entry.json').read_text())
    poses = json.loads((root/'poses.json').read_text())
    initial = json.loads((root/'world-initial.json').read_text())
    if len({entry['slave_sha256'], poses['sha256'], initial['sha256']}) != 1 or not poses['frames']:
        raise ValueError('Missing or mismatched capture')
    if hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest() != poses['sha256']:
        raise ValueError('Frozen slave does not match capture')
    if entry['sim_sha256'] != hashlib.sha256(raw).hexdigest() or initial['h3'] != poses['h3']:
        raise ValueError('Original game or global base differs between records')
    h3 = poses['h3']
    model = Cache(Snapshot(root, initial['banks']).read(h3+0xa5e6, 3060))
    for frame in poses['frames']:
        text = (root/f'pose-{frame["index"]}-events.txt').read_text()
        for line in text.splitlines():
            if not line.startswith('GEO_'):
                continue
            match = re.fullmatch(r'GEO_(RESET|FETCH|INPUT|RESULT) ([0-9 ]+)', line)
            if not match:
                raise ValueError('Malformed geometry observation')
            model.event(match[1], list(map(int, match[2].split())))
        model.checkpoint(Snapshot(root, frame['banks']).read(h3+0xa5e6, 3060))
    if not model.stats['32_miss'] or not model.stats['32_hit']:
        raise ValueError('Capture must exercise both 32-bit misses and hits')
    return dict(sha256=poses['sha256'], sim_sha256=hashlib.sha256(raw).hexdigest(),
                checkpoints=len(poses['frames']), bytes_per_checkpoint=3060, counts=dict(model.stats),
                scope='Observed fetch epochs, cache/scratch values and exact 32-bit misses only; projected arrays, 16-bit arithmetic and complete consumers remain open.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('original', type=Path); p.add_argument('capture', type=Path)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args(); result = check(a.original, a.capture)
    a.out.write_text(json.dumps(result, indent=2)+'\n'); print(result)
