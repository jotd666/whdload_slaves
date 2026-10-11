"""Inventory shared display storage without hiding inactive or compact differences."""
import argparse
import hashlib
import json
from pathlib import Path
from game_heap import exact
from hunks import read_hunks
from player_links import SIM_SHA
from render_mutations import Snapshot,region
from world_comparison import load
from world_registry import identity as dynamic_identity,check as registry_check

COMPACT=0x5280
COMPACT_COUNT=60
COMPACT_STRIDE=10
FIXED=0x129c


def identity(pointer,h3):
    off=pointer-h3
    if off==FIXED or COMPACT<=off<COMPACT+COMPACT_COUNT*COMPACT_STRIDE and (off-COMPACT)%COMPACT_STRIDE==0:
        return ('h3',off)
    return dynamic_identity(pointer,h3)


def state(read,h3,sim):
    count=int.from_bytes(exact(read,h3+0x3fa8,2),'big')
    compact_count=int.from_bytes(exact(read,h3+0x54d8,2),'big')
    if count>500 or compact_count>COMPACT_COUNT:raise ValueError('Unsupported shared display dimensions')
    raw=exact(read,h3+0x7dc8,2000)
    pointers=[int.from_bytes(raw[i:i+4],'big') for i in range(0,2000,4)]
    if any(not p or p&1 for p in pointers[:count]):raise ValueError('Invalid active display pointer')
    fixed=bytearray(exact(read,h3+FIXED,52))
    if int.from_bytes(fixed[26:30],'big')!=sim+0xf984:raise ValueError('Unexpected fixed draw callback')
    fixed[26:30]=bytes(4)
    return dict(count=count,compact_count=compact_count,storage=[identity(p,h3) for p in pointers],
                raw_storage=raw,compact=exact(read,h3+COMPACT,600),fixed=bytes(fixed))


def compare(a,b):
    differing=[i for i,(x,y) in enumerate(zip(a['storage'],b['storage'])) if x!=y]
    return dict(counts=[a['count'],b['count']],compact_counts=[a['compact_count'],b['compact_count']],
                active_order_equal=a['count']==b['count'] and a['storage'][:a['count']]==b['storage'][:b['count']],
                differing_slots=[dict(slot=i,left=a['storage'][i],right=b['storage'][i],
                    active_left=i<a['count'],active_right=i<b['count']) for i in differing],
                raw_storage=region(a['raw_storage'],b['raw_storage']),
                compact=region(a['compact'],b['compact']),fixed_prefix=region(a['fixed'],b['fixed']))


def contracts(h3):
    a=lambda off:(h3+off).to_bytes(4,'big');b=bytes.fromhex
    return {
        0xe82e:b('25bc')+a(FIXED)+b('08005247'),
        0xf326:b('3239')+a(0x54d8)+b('2401c5fc000a41f9')+a(COMPACT)+b('d1c225880800703cb240'),
        0xf366:b('3039')+a(0x54d8)+b('c1fc000a5279')+a(0x54d8)+b('41f9')+a(COMPACT)+b('d1c0226dffc820d920d93091'),
        0xfdc6:b('3039')+a(0x3fa8)+b('0c4001f46c52'),
        0xfdfc:b('41f9')+a(0x7dc8)+b('d1c0208b'),
    }


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported sim')
    hs=read_hunks(raw);code=hs[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError(f'Original shared-list contract {at:x}')
    if (FIXED+26,0) not in hs[3].relocations or int.from_bytes(hs[3].data[FIXED+26:FIXED+30],'big')!=0xf984:
        raise ValueError('Original fixed callback binding changed')
    prior=registry_check(original,left,right);roots=(left,right);loaded=[load(p) for p in roots]
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]):raise ValueError('Different checkpoint counts')
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,bank in zip(roots,loaded,banks):
            ram=Snapshot(root,bank);h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,data in contracts(h3).items():
                if exact(ram.read,sim+at,len(data))!=data:raise ValueError('Changed live shared-list contract')
            states.append(state(ram.read,h3,sim))
        rows.append(dict(boundary='initial' if not index else index-1,**compare(*states)))
    return dict(sha256=prior['sha256'],sim_sha256=SIM_SHA,rows=rows,
        scope='Inventory of all 500 shared display slots, all 60 compact slots and a 52-byte fixed-object prefix with explicit native identities. Differences are reported, not accepted or masked. Active-order equality is not full-state equality, consumer isolation, capacity or gameplay-speed acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('original','left','right'):p.add_argument(name,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.original,a.left,a.right);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Active order matches at',sum(r['active_order_equal'] for r in result['rows']),'of',len(result['rows']),'checkpoints; all storage differences retained')
