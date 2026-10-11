"""Check private native render-scratch BSET/BCLR results, including CCR.

This models byte +36 bit 5, not the complete visibility decision or renderer.
Restoration is checked separately by actual render-lease snapshots.
"""
import argparse
import json
from pathlib import Path
from presentation_state import symbol
from render_mutations import Snapshot


def operation(old, clear, ccr):
    if not 0 <= old <= 255 or clear not in (0, 1) or not 0 <= ccr <= 31:
        raise ValueError('Invalid byte operation inputs')
    return (old & 223 if clear else old | 32), ((ccr & 27) | (0 if old & 32 else 4))


def cases(raw):
    if len(raw) != 512*4:
        raise ValueError('Incomplete native cases')
    for index in range(512):
        old, clear, actual, ccr = raw[index*4:index*4+4]
        if (old, clear) != (index % 256, index // 256):
            raise ValueError('Missing, reordered or duplicated byte case')
        if (actual, ccr) != operation(old, clear, 27):
            raise ValueError('Native byte or CCR differs from model')
    return 512


def check(root):
    entry = json.loads((root/'entry.json').read_text())
    poses = json.loads((root/'poses.json').read_text())
    if entry['slave_sha256'] != poses['sha256'] or not poses['frames']:
        raise ValueError('Missing or mismatched native capture')
    lines = (root/'slave.lst').read_text(encoding='latin-1').splitlines()
    base = entry['entry']['game_anchor']-symbol(lines, 'tape_game_anchor')
    ram = Snapshot(root, poses['frames'][-1]['banks'])
    at = lambda name: base+symbol(lines, name)
    if int.from_bytes(ram.read(at('time_model_flag_result'), 4), 'big') != 512:
        raise ValueError('Native restoration/inactive-owner self-test failed')
    return dict(sha256=poses['sha256'], cases=cases(ram.read(at('time_model_flag_cases'), 2048)),
                scope='Private native byte/CCR and undo self-test; not whole-render purity.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('capture', type=Path)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args(); result = check(a.capture)
    a.out.write_text(json.dumps(result, indent=2)+'\n'); print(result)
