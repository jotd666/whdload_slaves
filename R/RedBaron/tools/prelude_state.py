"""Validate the VERIFY fixed-clock prelude and its handoff to W6.

This checks fixture ownership, not equal gameplay state or capacity.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
from presentation_state import symbol
from render_mutations import Snapshot
from world_comparison import load


def validate(initial,rows):
    if initial['active'] or initial['count']<=0 or initial['clocks']!=[225,225]:
        raise ValueError('Prelude did not establish both fixed clocks before W6')
    if not rows:raise ValueError('Missing W6 ownership observations')
    for tick,row in enumerate(rows):
        if row['tick']!=tick or row['active']!=1 or row['count']!=initial['count']:
            raise ValueError('Prelude fixture continued writing or invalid W6 boundary')
        # Boundary zero precedes the first scheduled world update; retain its
        # original clock residue. The world gate sets 225 before dispatch.
        if tick and row['clocks'][0]!=225:raise ValueError('Unexpected W6 primary quantum')


def check(root):
    entry,poses,initial,base,lines=load(root)
    digest=hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest()
    if {entry['slave_sha256'],poses['sha256'],initial['sha256']}!={digest}:
        raise ValueError('Mismatched frozen slave')
    args={int(k):int(v)&0xffffffff for k,v in re.findall(r'CUSTOM([245])=(-?\d+)',entry['whd_args'])}
    if args.get(4)!=0x40000 or not args.get(2,0)&8192 or not args.get(5,0)&512:
        raise ValueError('Capture lacks selected W6 deferred prelude fixture')
    h3=poses['h3'];at=lambda n:base+symbol(lines,n)
    def read(banks):
        ram=Snapshot(root,banks)
        return dict(count=int.from_bytes(ram.read(at('time_prelude_count'),4),'big'),
                    active=int.from_bytes(ram.read(at('time_loop_state')+40,4),'big'),
                    clocks=list(struct.unpack('>2H',ram.read(h3+0x4834,4))),
                    tick=int.from_bytes(ram.read(at('time_pose_header')+4,4),'big'))
    before=read(initial['banks']);rows=[read(f['banks']) for f in poses['frames']]
    validate(before,rows)
    return dict(sha256=digest,initial=before,rows=rows,
                scope='Fixed native setup clocks and no further fixture writes during observed W6 ownership. No claim of equal initial gameplay or capacity.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();r=check(a.capture);a.out.write_text(json.dumps(r,indent=2)+'\n')
    print('Prelude writes:',r['initial']['count'],'; unchanged through',len(r['rows']),'W6 boundaries')
