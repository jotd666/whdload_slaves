"""Check sampled inactive stream buffers; preserve initial content differences."""
import argparse
import hashlib
import json
from pathlib import Path
from auxiliary_pools import payload
from game_heap import allocations,exact
from hunks import read_hunks
from player_links import SIM_SHA,check as player_check
from render_mutations import Snapshot,region
from world_comparison import load


def inactive_state(read,h3,extents):
    u=lambda off,n:int.from_bytes(exact(read,h3+off,n),'big')
    if u(0x7792,4) or u(0x77ac,4):raise ValueError('Stream handle active')
    descriptors=exact(read,h3+0x78c8,44)
    if descriptors!=bytes(44):raise ValueError('Stream descriptors not pristine/inactive')
    result=[]
    for root,size in ((0x77b0,0x77b4),(0x77b8,0x77bc)):
        if u(size,4)!=1000:raise ValueError('Unexpected stream buffer size')
        result.append(payload(read,extents,u(root,4),1,1000))
    return result


def stable(initial,current):
    if initial!=current:raise ValueError('Stream buffer changed after initial checkpoint')


def contracts(h3):
    a=lambda off:(h3+off).to_bytes(4,'big');b=bytes.fromhex
    return {0x20ea4:b('203c000003e842a72f0023c0')+a(0x77bc)+b('23c0')+a(0x77b4),
            0x20ec6:b('23c0')+a(0x77b0)+b('4eba0be24fef000c23c0')+a(0x77b8),
            0x20f28:b('2eb9')+a(0x77bc)+b('2f39')+a(0x77b8)+b('72023f012f004eba3bb4'),
            0x20f42:b('23c0')+a(0x7792),
            0x20f9c:b('2eb9')+a(0x77b4)+b('2f39')+a(0x77b0)+b('72013f012f004eba3b40'),
            0x20fb6:b('23c0')+a(0x77ac),
            0x24b0a:b('2b7c')+a(0x78c8)+b('fffa7002ba40'),
            0x24b1c:b('082800020001670a52457016d1adfffa'),
            0x24b94:b('21460006214a00022007004000043080')}


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError(f'Unexpected native stream contract {at:x}')
    prior=player_check(original,left,right);roots=(left,right);loaded=[load(p) for p in roots]
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded];rows=[];initial=None
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,b in zip(roots,loaded,banks):
            ram=Snapshot(root,b);h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,data in contracts(h3).items():
                if exact(ram.read,sim+at,len(data))!=data:raise ValueError('Live stream contract changed')
            states.append(inactive_state(ram.read,h3,allocations(ram.read,h3)))
        if initial is None:initial=states
        else:stable(initial,states)
        rows.append(dict(boundary='initial' if not index else index-1,
                         buffers=[dict(root=f'h3:{at:05x}',raw_difference=region(a,b),left_sha256=hashlib.sha256(a).hexdigest(),right_sha256=hashlib.sha256(b).hexdigest()) for at,a,b in zip((0x77b0,0x77b8),*states)]))
    return dict(sha256=prior['sha256'],rows=rows,scope='Two complete stream buffers unchanged from their own initial state, inactive handles and zero descriptors at sampled boundaries. Cross-boot initial differences retained; not absence of intervening accesses or all file/mission-transition behavior.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for n in ('original','left','right'):p.add_argument(n,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args();r=check(a.original,a.left,a.right)
    a.out.write_text(json.dumps(r,indent=2)+'\n');print('Inactive stream buffers unchanged at',len(r['rows']),'checkpoints; initial differences retained')
