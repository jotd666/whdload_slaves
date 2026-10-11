"""Check native projected-coordinate producers and observed direct consumers.

Arithmetic is checked against the original instruction contract, not pixels.
DIVS overflow is rejected as unsupported evidence; it is never normalized away.
Indirect consumers and absence of simulation reads are not proven here.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import struct
from geometry_cache import Cache, check as check_geometry
from hunks import read_hunks
from projection_model import p38c82, norm_loop, norm_bl
from render_mutations import Snapshot

MASK = 0xffffffff
RANGES = ((0x38c82,0x38dcc),(0x38e9c,0x38eec),(0x38fac,0x3902c),
          (0x3acca,0x3ad28),(0x3add6,0x3ae68),(0x392a4,0x394fc),(0x3b30c,0x3b398))
DIGEST = '74b4b75df71e9aea0554cb7e07aea91fab31f383c8d1be5f92ecf71dd4e61bd2'
READS = {0x3932c:0,0x39342:0,0x39376:1,0x393be:0,0x393d4:0,0x3940a:1,
         0x3942e:0,0x39440:0,0x39472:1,0x394a0:0,0x394b4:0,0x394e6:1,
         0x3b35e:0,0x3b366:1,0x3b37e:0,0x3b386:1}


def signed(value, bits=32):
    value &= (1 << bits)-1
    return value-(1 << bits) if value & (1 << (bits-1)) else value


def divword(numerator, denominator):
    n, d = signed(numerator), signed(denominator, 16)
    if d == 0:
        raise ValueError('Native divide by zero cannot yield a projection')
    q = abs(n)//abs(d)
    if (n < 0) != (d < 0): q = -q
    if not -32768 <= q <= 32767:
        raise ValueError('DIVS overflow is outside verified projection evidence')
    return q & MASK


def project(path, a, b, parameter):
    if path not in (16, 17, 32, 33) or len(a) != 3 or len(b) != 3:
        raise ValueError('Unknown projection path or truncated source')
    if any(not 0 <= x <= MASK for x in a+b) or not 0 <= parameter <= 65535:
        raise ValueError('Projection inputs exceed native widths')
    clipping = path in (17, 33)
    if clipping:
        x, y, z = [(v-u) & MASK for u, v in zip(a, b)]
        k = (signed(parameter, 16)-a[1]) & MASK
    else:
        x, y, z = a
        k = (1 << (parameter & 63)) & MASK
    if path in (32, 33):
        result = p38c82(x, z, y, k, norm=norm_loop)[:2]
        if result != p38c82(x, z, y, k, norm=norm_bl)[:2]:
            raise ValueError('Projection normalization models disagree')
    elif clipping:
        result = tuple(divword((signed(v,16)*signed(k,16)) & MASK, y) for v in (x,z))
    else:
        result = tuple(divword((v << (parameter & 63)) & MASK, y) for v in (x,z))
    if clipping:
        result = tuple((v+offset) & MASK for v, offset in zip(result,(a[0],a[2])))
    return list(result)


class Projected:
    def __init__(self, geometry, data):
        if len(data) != 2040: raise ValueError('Truncated screen arrays')
        self.geometry = geometry
        self.data = bytearray(data)
        self.current = {}
        self.pending = None
        self.stats = Counter()
        self.sites = Counter()

    def reset(self):
        if self.pending: raise ValueError('Reset during projection')
        self.current.clear()

    def event(self, kind, row):
        if kind == 'BEGIN':
            if self.pending or not row or row[0] not in (16,17,32,33):
                raise ValueError('Nested or unknown projection')
            path = row[0]
            if len(row) != (10 if path in (17,33) else 6):
                raise ValueError('Malformed projection inputs')
            index = row[1]
            if path in (17,33):
                other = row[2]; a,b,parameter = row[3:6],row[6:9],row[9]
            else:
                other = index; a = b = row[2:5]; parameter = row[5]
            if self.geometry.values.get(index) != a or self.geometry.values.get(other) != b:
                raise ValueError('Projection uses coordinates absent from current epoch')
            self.pending = (path,index,project(path,a,b,parameter))
        elif kind == 'END':
            if self.pending is None or len(row) != 4:
                raise ValueError('Missing or malformed projection result')
            path,index,expected = self.pending
            if row != [path,index,*expected]:
                raise ValueError('Native screen coordinates differ from projection model')
            self.current[index] = expected
            for axis,value in enumerate(expected):
                struct.pack_into('>I',self.data,axis*1020+index*4,value)
            self.stats[f'path_{path}'] += 1; self.pending = None
        elif kind == 'READ':
            if len(row) != 4 or self.pending: raise ValueError('Malformed or premature screen read')
            site,axis,offset,value = row
            if READS.get(site) != axis or offset % 4 or not 0 <= offset < 1020:
                raise ValueError('Unknown consumer or out-of-range screen read')
            if offset//4 not in self.current or self.current[offset//4][axis] != value:
                raise ValueError('Screen consumer reads stale or unexplained coordinates')
            self.stats['reads'] += 1; self.sites[site] += 1
        else:
            raise ValueError('Unknown screen event')

    def checkpoint(self, data):
        if self.pending or self.data != data:
            raise ValueError('Incomplete projection or unobserved screen-array write')


def check(original, root):
    geometry_result = check_geometry(original, root)
    code = read_hunks(original.read_bytes())[0].data
    if hashlib.sha256(b''.join(code[a:b] for a,b in RANGES)).hexdigest() != DIGEST:
        raise ValueError('Unsupported original projection/consumer routines')
    poses = json.loads((root/'poses.json').read_text())
    initial = json.loads((root/'world-initial.json').read_text()); h3 = poses['h3']
    ram = Snapshot(root,initial['banks'])
    geometry = Cache(ram.read(h3+0xa5e6,3060))
    model = Projected(geometry,ram.read(h3+0xb1da,2040))
    for frame in poses['frames']:
        for line in (root/f'pose-{frame["index"]}-events.txt').read_text().splitlines():
            if not line.startswith(('GEO_','SCREEN_')): continue
            match = re.fullmatch(r'(GEO|SCREEN)_([A-Z]+) ([0-9 ]+)',line)
            if not match: raise ValueError('Malformed observation')
            source,kind,values = match.groups(); row = list(map(int,values.split()))
            if source == 'GEO':
                geometry.event(kind,row)
                if kind == 'RESET': model.reset()
            else: model.event(kind,row)
        ram = Snapshot(root,frame['banks'])
        geometry.checkpoint(ram.read(h3+0xa5e6,3060))
        model.checkpoint(ram.read(h3+0xb1da,2040))
    if not model.stats['reads'] or not model.stats['path_32']:
        raise ValueError('No substantive projection/consumer evidence')
    return dict(sha256=poses['sha256'],checkpoints=len(poses['frames']),bytes_per_checkpoint=2040,
                counts={k:model.stats[k] for k in ('path_16','path_17','path_32','path_33','reads')},
                unobserved_paths=[p for p in (16,17,32,33) if not model.stats[f'path_{p}']],
                read_sites={f'sim:{k:05x}':v for k,v in sorted(model.sites.items())},
                unobserved_read_sites=[f'sim:{k:05x}' for k in sorted(READS) if not model.sites[k]],
                geometry=geometry_result,scope='Observed projection arithmetic, all screen-array net writes and selected direct reads; not pixels or all indirect/simulation consumers.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('original',type=Path); p.add_argument('capture',type=Path)
    p.add_argument('--out',type=Path,required=True)
    a = p.parse_args(); result = check(a.original,a.capture)
    a.out.write_text(json.dumps(result,indent=2)+'\n'); print(result)
