"""Independent byte model and native-capture check for projection ownership.

Only the named object fields are restored. Framebuffer, IRQ and global rendering
state are deliberately outside this check; passing is not whole-render purity.
"""
import argparse
import json
import re
import struct
from pathlib import Path
from render_mutations import Snapshot

CAPACITY = 512
STRIDE = 28


def records(read, objects):
    if len(objects) > CAPACITY:
        raise ValueError('Object list exceeds supported native capacity')
    result = []
    for address in objects:
        flag = read(address, 1)[0]
        if flag & 64 or not flag & 8:
            continue
        result.append(struct.pack('>IBx', address, flag) + read(address+26, 4) + read(address+34, 18))
    return result


def restore(write, saved):
    for record in saved:
        if len(record) != STRIDE:
            raise ValueError('Truncated projection record')
        address = struct.unpack_from('>I', record)[0]
        write(address, record[4:5])
        write(address+26, record[6:10])
        write(address+34, record[10:28])


def symbol(lines, name):
    for i, line in enumerate(lines):
        if re.search(r'\b'+re.escape(name)+':', line):
            for next_line in lines[i:]:
                match = re.match(r'00:([0-9A-F]+)\s', next_line)
                if match:
                    return int(match[1], 16)
    raise ValueError('Missing capture symbol '+name)


def buffer_address(lines, base, name, read):
    """Resolve runtime buffers, while retaining historical embedded captures."""
    try:
        cell = base + symbol(lines, name + '_ptr')
    except ValueError:
        return base + symbol(lines, name)
    address = int.from_bytes(read(cell, 4), 'big')
    if not address or address & 1:
        raise ValueError('Unallocated or invalid buffer ' + name)
    return address


def check(path):
    metadata = json.loads(path.read_text())
    entry = json.loads((path.parent/'entry.json').read_text())
    lines = (path.parent/'slave.lst').read_text(encoding='latin-1').splitlines()
    base = entry['entry']['game_anchor']-symbol(lines, 'tape_game_anchor')
    header = base+symbol(lines, 'time_present_active')
    checked = changed = 0
    for frame in metadata['frames']:
        before = Snapshot(path.parent, frame['render_before'])
        rendered = Snapshot(path.parent, frame['render_after'])
        after = Snapshot(path.parent, frame['after'])
        buffer = buffer_address(lines, base, 'time_present_cache_buffer', rendered.read)
        saved = records(before.read, frame['objects'])
        if rendered.read(header, 4) != struct.pack('>HH', 1, len(saved)):
            raise ValueError('Incorrect active owner or record count')
        if rendered.read(buffer, len(saved)*STRIDE) != b''.join(saved):
            raise ValueError('Native saved records differ from byte model')
        if after.read(header, 4) != bytes(4):
            raise ValueError('Owner not released at outer return')
        for record in saved:
            address = struct.unpack_from('>I', record)[0]
            for offset, data in [(0, record[4:5]), (26, record[6:10]), (34, record[10:28])]:
                if after.read(address+offset, len(data)) != data:
                    raise ValueError('Projection state leaked past outer draw')
                changed += rendered.read(address+offset, len(data)) != data
            checked += 1
    if not checked or not changed:
        raise ValueError('Capture never exercised a changed projection record')
    return dict(sha256=metadata['sha256'], draws=len(metadata['frames']),
                records_checked=checked, mutated_regions_restored=changed)


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest', type=Path)
    p.add_argument('--out', type=Path, required=True)
    args = p.parse_args()
    result = check(args.manifest)
    args.out.write_text(json.dumps(result, indent=2)+'\n')
    print(result)
