"""Compare the complete native triangular pair table and its explicit owners."""
import argparse
import hashlib
import json
from pathlib import Path
from aircraft_pool import check as aircraft_check,STRIDE
from game_heap import allocations,exact
from hunks import read_hunks
from player_links import SIM_SHA
from render_mutations import Snapshot,region
from world_comparison import load


def owned(read,extents,pointer,size):
    if not pointer or pointer&1 or sum(a+8==pointer and n==size+8 for a,n in extents)!=1:
        raise ValueError('Pair-table storage is not an exact tracked allocation')
    return exact(read,pointer,size)


def state(read,h3,extents):
    u=lambda at,n:int.from_bytes(exact(read,h3+at,n),'big')
    count=u(0x4c3e,2);pairs=u(0x4c3c,2)
    if not 2<=count<=128 or pairs!=count*(count-1)//2:
        raise ValueError('Unsupported pair-table dimensions')
    roots=[u(at,4) for at in (0x4c30,0x4c34,0x4c38)]
    rows=owned(read,extents,roots[0],(count-1)*4)
    values=owned(read,extents,roots[1],pairs*4)
    objects=owned(read,extents,roots[2],count*4)
    if u(0x135c,2)!=STRIDE or u(0x5578,2)!=count:
        raise ValueError('Pair-table objects do not match supported aircraft pool')
    aircraft=u(0x5584,4);owned(read,extents,aircraft,count*STRIDE)
    identities=[]
    for i in range(count):
        pointer=int.from_bytes(objects[i*4:i*4+4],'big')
        slot,remain=divmod(pointer-aircraft,STRIDE)
        if remain or not 0<=slot<count:raise ValueError('Object table points outside aircraft slots')
        if int.from_bytes(exact(read,pointer+106,2),'big')!=i:
            raise ValueError('Object table disagrees with native object ID')
        identities.append(slot)
    if len(set(identities))!=count:raise ValueError('Duplicate pair-table object')
    for i in range(1,count):
        pointer=int.from_bytes(rows[(i-1)*4:i*4],'big')
        if pointer!=roots[1]+i*(i-1)//2*4:
            raise ValueError('Triangular row pointer has the wrong owner or offset')
    return dict(count=count,pairs=pairs,objects=identities,values=values.hex(),
                raw_descriptor=exact(read,h3+0x4c30,16),raw_rows=rows,raw_objects=objects)


def equal(a,b):
    for key in ('count','pairs','objects','values'):
        if a[key]!=b[key]:raise ValueError('Pairwise table state differs: '+key)


def contracts(h3):
    a=lambda off:(h3+off).to_bytes(4,'big');b=bytes.fromhex
    return {
        0xb030:b('3779')+a(0x4c3e)+b('006a5279')+a(0x4c3e),
        0xb040:b('3039')+a(0x4c3e)+b('22005341c3c04a416a025241e2415340e54048b90002')+a(0x4c3c),
        0xb07e:b('48f90001')+a(0x4c30),
        0xb0a4:b('48f90001')+a(0x4c34),
        0xb0c2:b('23c0')+a(0x4c38),
        0xb112:b('302b006a48c0e5802079')+a(0x4c38)+b('218b0800'),
        0xb126:b('2b79')+a(0x4c30)+b('fff02b79')+a(0x4c34)+b('fff47e01'),
        0xb140:b('206dfff020edfff4200748c0e580d1adfff42b48fff0'),
        0xb1fc:b('2079')+a(0x4c30)+b('207008fcd1c12010'),
        0xb21c:b('2079')+a(0x4c30)+b('207008fcd1c12010'),
        0xb510:b('2479')+a(0x4c34)+b('7e01be79')+a(0x4c3e),
        0xb55a:b('4eba0018206f00142080524660ce'),
    }


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported sim')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError(f'Original pair-table contract {at:x}')
    prior=aircraft_check(original,left,right);roots=(left,right);loaded=[load(p) for p in roots]
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]):raise ValueError('Unequal checkpoint sequences')
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,bank in zip(roots,loaded,banks):
            ram=Snapshot(root,bank);h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,data in contracts(h3).items():
                if exact(ram.read,sim+at,len(data))!=data:raise ValueError('Changed live pair-table contract')
            states.append(state(ram.read,h3,allocations(ram.read,h3)))
        a,b=states;equal(a,b)
        rows.append(dict(boundary='initial' if not index else index-1,count=a['count'],pairs=a['pairs'],
                         objects=a['objects'],values=a['values'],
                         raw_differences={key:region(a['raw_'+key],b['raw_'+key]) for key in ('descriptor','rows','objects')}))
    return dict(sha256=prior['sha256'],sim_sha256=SIM_SHA,rows=rows,
                scope='Complete triangular values, explicit row-to-value allocation ownership and aircraft-slot identities at retained equal-tick checkpoints. Raw pointer differences retained. No all-scenario, consumer-order, collision/hit, capacity or whole-gameplay verdict.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('original','left','right'):p.add_argument(name,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.original,a.left,a.right);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Complete pair tables match at',len(result['rows']),'checkpoints')
