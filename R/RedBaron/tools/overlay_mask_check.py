"""Compare private native coverage masks with the independent raster model."""
import argparse
import json
from pathlib import Path
from cockpit_raster import render,cache_geometry,audit as raster_audit
from overlay_abi import check as abi_check
from render_mutations import Snapshot

GUARD=bytes.fromhex('a55ac33c')*4


def check_buffer(data,expected):
    if len(data)!=8032 or len(expected)!=8000:raise ValueError('Incorrect mask allocation size')
    if data[:16]!=GUARD or data[-16:]!=GUARD:raise ValueError('Native mask guard changed')
    if data[16:-16]!=expected:raise ValueError('Native coverage differs from independent model')
    return sum(value.bit_count() for value in expected)


def check(path):
    abi=abi_check(path);raster_audit(path)
    meta=json.loads(path.read_text());root=path.parent;rows=[]
    for i,frame in enumerate(meta['frames']):
        mask=frame['mask']
        if mask['supported']!=1 or mask['count']!=i+1 or mask['program']!=frame['before']['program']:
            raise ValueError('Native mask identity/status differs')
        before=Snapshot(root,frame['before']['banks'])
        _,wanted=render(before.read,meta['h3'],mask['program'],bytes(40000))
        pixels=check_buffer((root/mask['file']).read_bytes(),wanted)
        rows.append(dict(program=mask['program'],checked_bytes=8032,covered_pixels=pixels,cache=cache_geometry(wanted)))
    if len(rows)!=4:raise ValueError('Need four native mask observations')
    return dict(sha256=abi['sha256'],cases=rows,
                scope='Native private coverage component only; original drawing still runs. No cache hit, skipped draw, performance or W6 completion claim.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();r=check(a.capture);a.out.write_text(json.dumps(r,indent=2)+'\n');print(r)
