"""Inventory shared model fields written by sim:0e0ec / sim:0dee2.

This enumerates possible writes, including unchanged values. It does not prove
that a callback ran or that these fields have no simulation consumers.
"""
import argparse
import json
import struct
from pathlib import Path
from render_mutations import Snapshot


def model_pointer(read, h3, model_id):
    """Native sim:398aa bank lookup, with unsigned 16-bit ID subtraction."""
    count = struct.unpack('>h', read(h3+0x426a, 2))[0]
    table = int.from_bytes(read(h3+0x4262, 4), 'big')
    for index in range(max(0, count)):
        entry = read(table+index*12, 6)
        pointers, size = struct.unpack('>IH', entry)
        if pointers and model_id < size:
            return int.from_bytes(read(pointers+4*model_id, 4), 'big')
        model_id = (model_id-size) & 65535
    return 0


def fields(read, h3, objects, sim):
    """Return deduplicated write locations and their static ownership category."""
    result = {}
    def add(address, size, kind):
        read(address, size)  # Reject inaccessible data, including bad table pointers.
        previous = result.setdefault((address, size), set())
        previous.add(kind)
    for obj in objects:
        if read(obj, 1)[0] & 64:
            continue
        callback = int.from_bytes(read(obj+26, 4), 'big')
        if callback != sim+0xe0ec:
            continue
        aircraft_type = struct.unpack('>b', read(obj+39, 1))[0]
        color_type = struct.unpack('>b', read(h3+0x1075+aircraft_type, 1))[0]
        if color_type >= 17:
            continue  # Native early exit at sim:0e110.
        model = int.from_bytes(read(obj+30, 4), 'big')
        add(model+2, 1, 'model_variant')
        model_id = int.from_bytes(read(obj+2, 2), 'big')
        count = struct.unpack('>h', read(h3+0x1014, 2))[0]
        for index in range(max(0, count)):
            row = h3+0x4c80+50*index
            if int.from_bytes(read(row, 2), 'big') != model_id:
                continue
            base = model_pointer(read, h3, model_id)
            if not base:
                raise ValueError('Native color helper would dereference a missing model')
            for group in range(6):
                add(row+14+2*group, 2, 'cached_color')
                length = struct.unpack('>h', read(row+2+2*group, 2))[0]
                offsets = int.from_bytes(read(row+26+4*group, 4), 'big')
                for item in range(max(0, length)):
                    offset = int.from_bytes(read(offsets+2*item, 2), 'big')
                    add(base+offset+3, 2, 'polygon_colors')
    return [(address, size, sorted(kinds)) for (address, size), kinds in sorted(result.items())]


def analyze(path):
    metadata = json.loads(path.read_text())
    frames = []
    for frame in metadata['frames']:
        before = Snapshot(path.parent, frame['render_before'])
        after = Snapshot(path.parent, frame['render_after'])
        final = Snapshot(path.parent, frame['after'])
        records = []
        for address, size, kinds in fields(before.read, metadata['h3'], frame['objects'], metadata['sim']):
            records.append(dict(address=address, size=size, kinds=kinds,
                                before=before.read(address, size).hex(),
                                after_3d=after.read(address, size).hex(),
                                after_outer=final.read(address, size).hex()))
        frames.append(dict(index=frame['index'], fields=records,
                           net_changes=sum(r['before'] != r['after_outer'] for r in records)))
    return dict(sha256=metadata['sha256'], frames=frames,
                limitation='Potential write set and net differences only; execution, transient values and simulation-consumer coverage remain unproved.')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest', type=Path)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    result = analyze(a.manifest)
    a.out.write_text(json.dumps(result, indent=2)+'\n')
    for frame in result['frames']:
        print('draw', frame['index'], 'potential fields', len(frame['fields']), 'net changes', frame['net_changes'])


if __name__ == '__main__':
    main()
