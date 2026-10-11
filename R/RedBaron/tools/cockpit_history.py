"""Check the native seven-by-two cockpit rectangle history at h3:07134.

The model verifies slot ownership, copied bounds and the partial redraw clip.
It does not certify callback geometry, pixels, or all indirect consumers.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
from hunks import read_hunks
from render_mutations import Snapshot

BASE = 0x7134
SIZE = 7*2*8


def word(value):
    return ((value+32768) & 65535)-32768


def slot(instrument, page):
    if not 0 <= instrument < 7 or page not in (0, 1):
        raise ValueError('Invalid cockpit history slot')
    return instrument*16+page*8


def clip(rect, padding):
    x, y, width, height = rect
    px, py = padding
    if any(not -32768 <= n <= 32767 for n in rect) or any(not -128 <= n <= 127 for n in padding):
        raise ValueError('Invalid signed native rectangle input')
    return [word(x-px), word(x+width+2*px), word(y-py), word(y+height+2*py)]


class History:
    def __init__(self, data):
        if len(data) != SIZE:
            raise ValueError('Truncated rectangle history')
        self.data = bytearray(data)
        self.pending = None
        self.copies = self.partial_clips = self.full_clips = self.changed_copies = 0
        self.slots = set()

    def event(self, kind, values):
        if kind == 'READ':
            if self.pending is not None or len(values) != 11:
                raise ValueError('Nested or malformed history read')
            tick, instrument, page, offset, *rest = values
            rect, padding, full = rest[:4], rest[4:6], rest[6]
            at = slot(instrument, page)
            if offset != BASE+at or full not in (0, 1):
                raise ValueError('Native history read uses wrong slot or mode')
            if struct.unpack_from('>4h', self.data, at) != tuple(rect):
                raise ValueError('History read differs from the last committed rectangle')
            self.pending = dict(at=at, rect=rect, padding=padding, full=full, phase='CLIP')
        elif self.pending is None or self.pending['phase'] != kind:
            raise ValueError('Missing or reordered cockpit operation')
        elif kind == 'CLIP':
            if len(values) != 4:
                raise ValueError('Truncated clip result')
            if not self.pending['full']:
                if values != clip(self.pending['rect'], self.pending['padding']):
                    raise ValueError('Partial redraw clip differs from model')
                self.partial_clips += 1
            else:
                self.full_clips += 1  # full-viewport helper is outside this model
            self.pending['phase'] = 'STORE'
        elif kind == 'STORE':
            if len(values) != 5 or values[0] != BASE+self.pending['at']:
                raise ValueError('Wrong rectangle destination')
            if any(not -32768 <= n <= 32767 for n in values[1:]):
                raise ValueError('Rectangle outside native signed widths')
            self.pending.update(new=values[1:], phase='AFTER')
        elif kind == 'AFTER':
            at = self.pending['at']
            if values != [BASE+at, *self.pending['new']]:
                raise ValueError('Native rectangle copy differs from callback output')
            new = struct.pack('>4h', *self.pending['new'])
            self.changed_copies += self.data[at:at+8] != new
            self.data[at:at+8] = new
            self.slots.add(at); self.copies += 1; self.pending = None
        else:
            raise ValueError('Unknown cockpit operation')

    def checkpoint(self, data):
        if self.pending is not None or data != self.data:
            raise ValueError('Incomplete call or unobserved rectangle-history mutation')


def check(original, root):
    raw = original.read_bytes(); code = read_hunks(raw)[0].data
    digest = hashlib.sha256(code[0x19cfc:0x19e0c]).hexdigest()
    if digest != 'b8629e61077b692f37fab199edf6e37fce3f1d9b2d368b2e81b964062ca38a39':
        raise ValueError('Unsupported original cockpit history routine')
    entry = json.loads((root/'entry.json').read_text())
    poses = json.loads((root/'poses.json').read_text())
    initial = json.loads((root/'world-initial.json').read_text())
    if len({entry['slave_sha256'], poses['sha256'], initial['sha256']}) != 1 or not poses['frames']:
        raise ValueError('Missing or mismatched native capture')
    h3 = poses['h3']; ram = Snapshot(root, initial['banks'])
    model = History(ram.read(h3+BASE, SIZE))
    for frame in poses['frames']:
        text = (root/f'pose-{frame["index"]}-events.txt').read_text()
        for kind, values in re.findall(r'^RECT_(READ|CLIP|STORE|AFTER) ([0-9 -]+)$', text, re.M):
            model.event(kind, list(map(int, values.split())))
        model.checkpoint(Snapshot(root, frame['banks']).read(h3+BASE, SIZE))
    if not model.copies:
        raise ValueError('No actual cockpit history writes observed')
    return dict(sha256=poses['sha256'], sim_sha256=hashlib.sha256(raw).hexdigest(),
                routine_sha256=digest, checkpoints=len(poses['frames']), copies=model.copies, changed_copies=model.changed_copies,
                partial_clips=model.partial_clips, full_clips_not_modelled=model.full_clips,
                slots=sorted(model.slots), bytes_per_checkpoint=SIZE,
                scope='Observed rectangle history and partial clip only; no pixel, callback-geometry or complete-consumer acceptance.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('original', type=Path); p.add_argument('capture', type=Path)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args(); result = check(a.original, a.capture)
    a.out.write_text(json.dumps(result, indent=2)+'\n'); print(result)
