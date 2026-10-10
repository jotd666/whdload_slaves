"""Inventory observed native render mutations without excluding unknown bytes.

This is a before/after inventory, not proof of purity: transient writes restored
before return and unexecuted branches require separate instruction/caller audit.
IRQ state and drawing buffers remain in the unclassified RAM differences.
"""
import argparse
import json
import struct
from pathlib import Path


def spans(before, after):
    if len(before) != len(after):
        raise ValueError('Snapshot sizes differ')
    result = []
    start = None
    for i, (left, right) in enumerate(zip(before, after)):
        if left != right and start is None:
            start = i
        elif left == right and start is not None:
            result.append((start, i))
            start = None
    if start is not None:
        result.append((start, len(before)))
    return result


class Snapshot:
    def __init__(self, root, banks):
        self.banks = []
        for bank in banks:
            data = (root / bank['file']).read_bytes()
            if len(data) != bank['size']:
                raise ValueError('Incomplete bank snapshot')
            self.banks.append((bank['base'], data))
        self.banks.sort()
        for (base, data), (next_base, _) in zip(self.banks, self.banks[1:]):
            if base + len(data) > next_base:
                raise ValueError('Overlapping RAM banks')

    def read(self, address, size):
        if size < 0:
            raise ValueError('Negative read size')
        for base, data in self.banks:
            offset = address - base
            if 0 <= offset and offset + size <= len(data):
                return data[offset:offset + size]
        raise ValueError('Requested object outside captured RAM')


def region(before, after):
    changes = spans(before, after)
    return dict(changed_bytes=sum(hi-lo for lo, hi in changes), ranges=[
        dict(start=lo, end=hi, before=before[lo:hi].hex(), after=after[lo:hi].hex())
        for lo, hi in changes])


def compare(left, right, h3, objects):
    if [(base, len(data)) for base, data in left.banks] != [(base, len(data)) for base, data in right.banks]:
        raise ValueError('Different RAM maps')
    memory = []
    for index, ((_, before), (_, after)) in enumerate(zip(left.banks, right.banks)):
        changes = spans(before, after)
        memory.append(dict(bank=index, changed_bytes=sum(hi-lo for lo, hi in changes),
                           ranges=changes))
    records = []
    for index, address in enumerate(objects):
        compact = bool(left.read(address, 1)[0] & 64)
        size = 10 if compact else 26
        record = dict(index=index, compact=compact,
                      prefix=region(left.read(address, size), right.read(address, size)))
        if not compact:
            record['callback_changed'] = left.read(address+26, 4) != right.read(address+26, 4)
            # sim:2c6f6..2c79c uses this extension only for objects with bit 3.
            if left.read(address, 1)[0] & 8:
                record['projection_cache'] = region(left.read(address+34, 18), right.read(address+34, 18))
        records.append(record)
    player = struct.unpack('>I', left.read(h3+0x4578, 4))[0]
    return dict(ram=memory, h3=region(left.read(h3, 0xbd0c), right.read(h3, 0xbd0c)),
                render_objects=records, player=region(left.read(player, 0x118), right.read(player, 0x118)),
                player_pointer_changed=left.read(h3+0x4578, 4) != right.read(h3+0x4578, 4))


def analyze(path):
    metadata = json.loads(path.read_text())
    frames = []
    for frame in metadata['frames']:
        result = dict(index=frame['index'], object_count=len(frame['objects']))
        for label, start, end in [('outer', 'before', 'after'), ('renderer', 'render_before', 'render_after')]:
            left = Snapshot(path.parent, frame[start])
            right = Snapshot(path.parent, frame[end])
            result[label] = compare(left, right, metadata['h3'], frame['objects'])
        frames.append(result)
    return dict(sha256=metadata['sha256'], frames=frames,
                limitation='Observed net mutations only; no bytes excluded, no render-purity or gameplay-equivalence claim.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    result = analyze(args.manifest)
    args.out.write_text(json.dumps(result, indent=2)+'\n')
    for frame in result['frames']:
        print('draw', frame['index'], 'objects', frame['object_count'],
              'h3 changes outer/3D', frame['outer']['h3']['changed_bytes'], frame['renderer']['h3']['changed_bytes'],
              'player changes outer/3D', frame['outer']['player']['changed_bytes'], frame['renderer']['player']['changed_bytes'])


if __name__ == '__main__': main()
