"""Check native shape-list selection metadata at retained W6 world boundaries.

This identifies observed global differences; it does not exclude them from
world_comparison or prove the absence of indirect gameplay consumers.
"""
import argparse
import json
from pathlib import Path
from render_mutations import Snapshot


def selection(read, h3):
    def exact(at, size):
        data = read(at, size)
        if len(data) != size:
            raise ValueError('Truncated shape-list state')
        return data

    table = int.from_bytes(exact(h3 + 0x4262, 4), 'big')
    count = int.from_bytes(exact(h3 + 0x426a, 2), 'big')
    selected = int.from_bytes(exact(h3 + 0xa278, 4), 'big')
    delta = selected - table
    if not table or table & 1 or not 0 < count <= 0x7fff:
        raise ValueError('Invalid shape-list table')
    if delta < 0 or delta % 12 or delta // 12 >= count:
        raise ValueError('Selected shape list outside table')
    record = exact(selected, 12)
    if not int.from_bytes(record[:4], 'big') or not int.from_bytes(record[4:6], 'big'):
        raise ValueError('Selected shape list is empty')
    scale = exact(h3 + 0x4278, 4)
    if scale != record[6:10]:
        raise ValueError('Cached shape scale differs from selected record')
    return dict(index=delta // 12, list_count=count, scale=scale.hex())


def audit(root):
    metadata = json.loads((root / 'poses.json').read_text())
    entry = json.loads((root / 'entry.json').read_text())
    if metadata['sha256'] != entry['slave_sha256']:
        raise ValueError('Capture build identity mismatch')
    if not metadata['frames']:
        raise ValueError('No retained boundaries')
    rows = []
    for frame in metadata['frames']:
        snapshot = Snapshot(root, frame['banks'])
        rows.append(selection(snapshot.read, metadata['h3']))
    return dict(sha256=metadata['sha256'], boundaries=len(rows), selections=rows,
                limitation='Observed shape metadata identity only; no global-state exclusions or whole-gameplay equivalence.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    result = audit(args.capture)
    args.out.write_text(json.dumps(result, indent=2) + '\n')
    print(result['boundaries'], 'shape selection checkpoints match')
