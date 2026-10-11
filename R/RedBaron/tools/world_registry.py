"""Compare full dynamic registry storage, active prefixes and projectile pool.

Only native fixed object h3:4860 and 50 explicit 44-byte pool slots relocate.
Other addresses must match exactly. This does not compare full object records.
"""
import argparse
import hashlib
import json
from pathlib import Path
from game_heap import exact
from hunks import read_hunks
from player_links import SIM_SHA
from pose_history import registry
from prelude_state import check as prelude_check
from render_mutations import Snapshot,region
from world_comparison import load
from world_controls import compare as compare_controls,extract

POOL=0x5934
STRIDE=44
COUNT=50
REGISTRY_CAPACITY=500


def storage(read,h3):
    raw=exact(read,h3+0x85a0,REGISTRY_CAPACITY*4)
    return [identity(int.from_bytes(raw[i:i+4],'big'),h3)
            for i in range(0,len(raw),4)]


def identity(pointer,h3):
    offset=pointer-h3
    if offset==0x4860 or POOL<=offset<POOL+STRIDE*COUNT and (offset-POOL)%STRIDE==0:
        return ('h3',offset)
    return ('absolute',pointer)


def observation(read,h3,lifecycle):
    pointers=registry(read,h3)
    return dict(storage=storage(read,h3),registry=[(identity(p,h3),exact(read,p,26).hex()) for p in pointers],
                lifecycle=[identity(p,h3) for p in lifecycle],
                pool=exact(read,h3+POOL,STRIDE*COUNT).hex())


def equal(left,right):
    for key in ('registry','lifecycle','pool','storage'):
        if left[key]!=right[key]:raise ValueError(f'Differing {key} state/order')


def contracts(h3):
    return {0xfdd2:bytes.fromhex('3239')+(h3+0x859e).to_bytes(4,'big')+bytes.fromhex('0c4101f46c46'),
            0xfef2:bytes.fromhex('41f9')+(h3+0x85a0).to_bytes(4,'big')+bytes.fromhex('2248d3c12451'),
            0xff06:bytes.fromhex('5379')+(h3+0x859e).to_bytes(4,'big')+bytes.fromhex('3039')+(h3+0x859e).to_bytes(4,'big')+bytes.fromhex('48c0e580d1c02290'),
            0x4146:bytes.fromhex('4879')+(h3+0x4860).to_bytes(4,'big')+bytes.fromhex('4eba09a8'),
            0x1291a:bytes.fromhex('72323f01742c3f024879')+(h3+POOL+1).to_bytes(4,'big')+bytes.fromhex('4879')+(h3+POOL).to_bytes(4,'big'),
            0x129a0:bytes.fromhex('303c08983f004879')+(h3+POOL).to_bytes(4,'big')}


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError('Unexpected native fixed-object/pool contract')
    roots=(left,right);loaded=[load(p) for p in roots];checks=[prelude_check(p) for p in roots]
    if len({c['sha256'] for c in checks})!=1 or any(m[0]['sim_sha256']!=SIM_SHA for m in loaded):
        raise ValueError('Different frozen or original executables')
    controls=compare_controls(*(extract(p) for p in roots))
    sequences=[[dict(banks=m[2]['banks'],lifecycle=[])]+m[1]['frames'] for m in loaded]
    if len(sequences[0])!=len(sequences[1]):raise ValueError('Different checkpoint counts')
    rows=[]
    for index,frames in enumerate(zip(*sequences)):
        states=[];raw_addresses=[];raw_storage=[]
        for root,m,frame in zip(roots,loaded,frames):
            ram=Snapshot(root,frame['banks']);h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,data in contracts(h3).items():
                if exact(ram.read,sim+at,len(data))!=data:raise ValueError('Live fixed-object/pool contract changed')
            states.append(observation(ram.read,h3,frame['lifecycle']))
            raw_addresses.append(registry(ram.read,h3))
            raw_storage.append(exact(ram.read,h3+0x85a0,REGISTRY_CAPACITY*4))
        equal(*states)
        rows.append(dict(boundary='initial' if not index else index-1,registered_objects=len(states[0]['registry']),
                         lifecycle_events=len(states[0]['lifecycle']),lifecycle=states[0]['lifecycle'],
                         pool_sha256=hashlib.sha256(bytes.fromhex(states[0]['pool'])).hexdigest(),
                         raw_registry_addresses=raw_addresses,
                         storage=states[0]['storage'],storage_slots=REGISTRY_CAPACITY,
                         raw_storage_difference=region(*raw_storage)))
    return dict(sha256=checks[0]['sha256'],rows=rows,matched_prefixes=sum(r['registered_objects'] for r in rows),
                pool_bytes_per_checkpoint=STRIDE*COUNT,input_boundaries=len(controls['rows']),
                scope='All 500 dynamic registry pointer slots including unused tail, active order/26-byte prefixes, explicit fixed-object identities, observed lifecycle order and entire 50-slot projectile pool only. No full aircraft records, between-sample alias/lifetime proof, collision outcomes, globals or capacity acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('original','left','right'):p.add_argument(name,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    r=check(a.original,a.left,a.right);a.out.write_text(json.dumps(r,indent=2)+'\n')
    print('Matched',r['matched_prefixes'],'registered prefixes and complete projectile pool at',len(r['rows']),'checkpoints')
