"""Check named shape-selection ownership across native W6 render calls."""
import argparse
import json
import struct
from pathlib import Path
from presentation_state import symbol
from render_mutations import Snapshot
from shape_selection import selection


def state(read, h3):
    parts = [read(h3 + offset, 4) for offset in (0x4278, 0xa278)]
    if any(len(part) != 4 for part in parts):
        raise ValueError('Truncated shape selection')
    return b''.join(parts)


def check_draw(before, rendered, after, h3, saved):
    initial = selection(before, h3)
    selection(rendered, h3)
    selection(after, h3)
    original = state(before, h3)
    if saved != original:
        raise ValueError('Saved shape selection differs from entry')
    if state(after, h3) != original:
        raise ValueError('Shape selection leaked past rendering')
    # A saved selected pointer is meaningful only while its resource table lives.
    descriptor = before(h3 + 0x4262, 12)
    if len(descriptor) != 12:
        raise ValueError('Truncated shape resource descriptor')
    table = int.from_bytes(descriptor[:4], 'big')
    size = initial['list_count'] * 12
    content = before(table, size)
    if len(content) != size:
        raise ValueError('Truncated shape resource table')
    for read in (rendered, after):
        if read(h3 + 0x4262, 12) != descriptor or read(table, size) != content:
            raise ValueError('Shape resource table changed during render lease')
    return int(state(rendered, h3) != original)


def check_selftest(cases, storage, result):
    expected = (0, 0xffffffff, 0x01000100, 0x002468ac, 0x00ff005a, 0x0013579c)
    if cases != struct.pack('>6I', *expected):
        raise ValueError('Unexpected native shape self-test cases')
    if storage != struct.pack('>4I', 0x13579bdf, *expected[-2:], 0x2468ace0):
        raise ValueError('Private shape test state or guards differ')
    if result != struct.pack('>I', 3):
        raise ValueError('Native shape self-test did not complete')
    return dict(cases=3, restored_private_bytes=24, guards_preserved=True)


def check(path, allow_unchanged=False):
    data = json.loads(path.read_text())
    root = path.parent
    entry = json.loads((root / 'entry.json').read_text())
    if data['sha256'] != entry['slave_sha256']:
        raise ValueError('Capture build identity mismatch')
    lines = (root / 'slave.lst').read_text(encoding='latin-1').splitlines()
    base = entry['entry']['game_anchor'] - symbol(lines, 'tape_game_anchor')
    saved = base + symbol(lines, 'time_present_shape_saved')
    changed = 0
    for row in data['frames']:
        if row['world_during']:
            raise ValueError('World ran inside the render lease')
        before = Snapshot(root, row['before'])
        rendered = Snapshot(root, row['list_before_restore'])
        after = Snapshot(root, row['after'])
        changed += check_draw(before.read, rendered.read, after.read, data['h3'],
                              rendered.read(saved, 8))
    if not data['frames'] or (not changed and not allow_unchanged):
        raise ValueError('Capture never changed the selected shape state')
    return dict(sha256=data['sha256'], draws=len(data['frames']),
                changed_selections_restored=changed, changed_value_coverage=bool(changed),
                scope='Named shape selection and stable resource tables only; not full render purity.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest', type=Path)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--allow-unchanged', action='store_true',
                   help='Report preservation without claiming changed-value coverage')
    args = p.parse_args()
    result = check(args.manifest, args.allow_unchanged)
    args.out.write_text(json.dumps(result, indent=2) + '\n')
    print(result)
