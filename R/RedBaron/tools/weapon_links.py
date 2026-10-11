"""Compare selected ammunition and all ten native projectile-linked records."""
import argparse
import hashlib
import json
from pathlib import Path
from aircraft_pool import check as aircraft_check, STRIDE as AIRCRAFT_STRIDE
from world_registry import check as registry_check, POOL, STRIDE, COUNT
from pairwise_table import owned
from game_heap import allocations, exact
from hunks import read_hunks
from player_links import SIM_SHA
from render_mutations import Snapshot, region
from world_comparison import load


def state(read, h3, extents):
    u = lambda at,n: int.from_bytes(exact(read, at, n), 'big')
    count=u(h3+0x5578,2); aircraft=u(h3+0x5584,4)
    if u(h3+0x135c,2)!=AIRCRAFT_STRIDE or not 0<count<=500:
        raise ValueError('Unsupported aircraft layout')
    owned(read,extents,aircraft,count*AIRCRAFT_STRIDE)
    ammo=[]
    for slot in range(count):
        pointer=u(aircraft+slot*AIRCRAFT_STRIDE+120,4)
        ammo.append(pointer); owned(read,extents,pointer,4)
    if len(set(ammo))!=count: raise ValueError('Ambiguous ammunition owner')
    selected=u(h3+0x583c,4)
    if selected and selected not in ammo: raise ValueError('Selected ammunition is not an exact aircraft payload')
    selected_slot=ammo.index(selected) if selected else None
    raw=exact(read,h3+0x5844,240); records=[]
    for offset in range(0,240,24):
        record=raw[offset:offset+24]; pointer=int.from_bytes(record[20:24],'big')
        slot=None
        if pointer:
            slot,remain=divmod(pointer-h3-POOL,STRIDE)
            if remain or not 0<=slot<COUNT: raise ValueError('Unsupported projectile owner')
        records.append(dict(body=record[:20].hex(),owner=slot))
    return dict(selected=selected_slot, ammo=[exact(read,p,4).hex() for p in ammo],
                records=records,raw_table=raw,raw_selected=exact(read,h3+0x583c,4))


def equal(a,b):
    for key in ('selected','ammo','records'):
        if a[key]!=b[key]: raise ValueError('Weapon link state differs: '+key)


def contracts(h3):
    a=lambda off:(h3+off).to_bytes(4,'big'); b=bytes.fromhex
    return {
        0x12370:b('24680078d5c02f082f0a23ca')+a(0x583c),
        0x129b2:b('303c00f03e804879')+a(0x5844)+b('4eba3f20'),
        0x132d6:b('2b7c')+a(0x5844)+b('fff8700abe40'),
        0x132f4:b('226d000821490014'),
        0x13312:b('7018d1adfff8'),
        0x13350:b('45f9')+a(0x5844)+b('700abe406c16206a0014'),
        0x13364:b('42aa0014'),
        0x1336c:b('d4fc0018'),
    }


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA: raise ValueError('Unsupported sim')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data: raise ValueError(f'Original weapon contract {at:x}')
    prior=aircraft_check(original,left,right); registry=registry_check(original,left,right)
    if prior['sha256']!=registry['sha256']: raise ValueError('Different prerequisite builds')
    roots=(left,right); loaded=[load(p) for p in roots]
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]): raise ValueError('Unequal checkpoint sequences')
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,bank in zip(roots,loaded,banks):
            ram=Snapshot(root,bank);h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,data in contracts(h3).items():
                if exact(ram.read,sim+at,len(data))!=data: raise ValueError('Changed live weapon contract')
            states.append(state(ram.read,h3,allocations(ram.read,h3)))
        a,b=states; equal(a,b)
        rows.append(dict(boundary='initial' if not index else index-1, selected=a['selected'],
                         ammo=a['ammo'],records=a['records'],raw_differences={
                             key:region(a['raw_'+key],b['raw_'+key]) for key in ('table','selected')}))
    return dict(sha256=prior['sha256'],sim_sha256=SIM_SHA,rows=rows,
                scope='Selected four-byte ammunition payload bound to an exact aircraft slot; all ten 24-byte records with only explicit +20 null/projectile-slot owners bound. Requires full aircraft and projectile-pool comparison. No unobserved owner types, multi-gun payloads, between-checkpoint lifetime, all-combat or real-time-speed verdict.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('original','left','right'): p.add_argument(name,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.original,a.left,a.right);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Complete weapon links match at',len(result['rows']),'checkpoints')
