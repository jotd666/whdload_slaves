"""Check the native W6 shared-model undo journal against retained RAM."""
import argparse
import json
import struct
from pathlib import Path
from presentation_state import symbol
from render_mutations import Snapshot

CAPACITY = 4096
STRIDE = 8


def decode(data):
    if len(data) % STRIDE or len(data) > CAPACITY*STRIDE:
        raise ValueError('Invalid journal length')
    result = []
    for offset in range(0, len(data), STRIDE):
        address, old, size = struct.unpack_from('>I2sH', data, offset)
        if size not in (1, 2):
            raise ValueError('Invalid journal store size')
        result.append((address, old[:size]))
    return result


def restore(write, records):
    for address, old in reversed(records):
        write(address, old)


def check(path):
    metadata = json.loads(path.read_text())
    if not metadata['frames']:
        raise ValueError('No captured draws')
    entry = json.loads((path.parent/'entry.json').read_text())
    lines = (path.parent/'slave.lst').read_text(encoding='latin-1').splitlines()
    base = entry['entry']['game_anchor']-symbol(lines, 'tape_game_anchor')
    header = base+symbol(lines, 'time_model_count')
    buffer = base+symbol(lines, 'time_model_buffer')
    test = base+symbol(lines, 'time_model_test_result')
    rows = []
    for frame in metadata['frames']:
        before = Snapshot(path.parent, frame['before'])
        drawn = Snapshot(path.parent, frame['render_after'])
        after = Snapshot(path.parent, frame['after'])
        if int.from_bytes(after.read(test, 4), 'big') != 1:
            raise ValueError('Native overlapping-write self-test did not pass')
        count = int.from_bytes(drawn.read(header, 2), 'big')
        if not 0 < count <= CAPACITY:
            raise ValueError('No actual model writes or capacity exceeded')
        records = decode(drawn.read(buffer, count*STRIDE))
        first = {}
        for address, old in records:
            for offset, byte in enumerate(old):
                first.setdefault(address+offset, byte)
        for address, byte in first.items():
            if before.read(address, 1) != bytes([byte]):
                raise ValueError('First saved value differs from outer-entry state')
            if after.read(address, 1) != bytes([byte]):
                raise ValueError('Model write leaked past outer return')
        restored = {}
        restore(lambda address, old: restored.update({address+i: b for i, b in enumerate(old)}), records)
        if restored != first:
            raise ValueError('Reverse undo disagrees with first-value model')
        if after.read(header, 2) != bytes(2):
            raise ValueError('Journal not emptied at outer return')
        rows.append(dict(index=frame['index'], writes=count, distinct_bytes=len(first)))
    return dict(sha256=metadata['sha256'], native_overlap_selftest=True, frames=rows,
                limitation='Recorded writes only; no complete renderer-purity or gameplay-equivalence claim.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest', type=Path)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    result = check(a.manifest)
    a.out.write_text(json.dumps(result, indent=2)+'\n')
    print(result)
