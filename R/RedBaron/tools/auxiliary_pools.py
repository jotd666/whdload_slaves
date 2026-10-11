"""Compare full type-five and 44-byte auxiliary pool records across CPU speeds.

Only the explicit auxiliary callback field may relocate. Inactive slots and
record tails stay in the comparison; all allocations must fit exactly.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from aircraft_pool import check as aircraft_check,contracts as type_contracts
from game_heap import exact,allocations
from hunks import read_hunks
from player_links import SIM_SHA
from render_mutations import Snapshot,region
from world_comparison import load


def payload(read,extents,pointer,count,stride):
    if not pointer or pointer&1 or not 0<count<=500:
        raise ValueError('Unsupported auxiliary pool descriptor')
    size=count*stride
    if sum(base+8==pointer and length==size+8 for base,length in extents)!=1:
        raise ValueError('Pool does not exactly fill a tracked allocation')
    return exact(read,pointer,size)


def callbacks(raw,sim):
    if not raw or len(raw)%44:raise ValueError('Incomplete auxiliary records')
    result=[]
    for offset in range(0,len(raw),44):
        record=bytearray(raw[offset:offset+44]);pointer=struct.unpack_from('>I',record,26)[0]
        if pointer==0:identity=None
        elif pointer-sim in (0xdb70,0xdb9e):identity=pointer-sim
        else:raise ValueError('Unsupported auxiliary callback')
        record[26:30]=bytes(4);result.append((record.hex(),identity))
    return result


def contracts(h3):
    out=type_contracts(h3)
    out.update({0x11932:bytes.fromhex('3039')+(h3+0x57dc).to_bytes(4,'big')+bytes.fromhex('6744c0fc002c'),
                0x11956:bytes.fromhex('23c0')+(h3+0x57d0).to_bytes(4,'big'),
                0x11be0:bytes.fromhex('43fabf8e2149001a'),0xdb88:bytes.fromhex('41fa00142548001a'),0xdbb6:bytes.fromhex('41faffb82548001a')})
    return out


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError('Unexpected native pool/callback contract')
    prior=aircraft_check(original,left,right);roots=(left,right);loaded=[load(p) for p in roots]
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded];rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,b in zip(roots,loaded,banks):
            ram=Snapshot(root,b);h3=m[1]['h3'];sim=m[0]['entry']['sim'];read=ram.read
            for at,data in contracts(h3).items():
                if exact(read,sim+at,len(data))!=data:raise ValueError('Live pool/callback contract changed')
            extents=allocations(read,h3);u=lambda at,n:int.from_bytes(exact(read,h3+at,n),'big')
            if u(0x1366,2)!=134:raise ValueError('Unexpected type-five stride')
            typed=payload(read,extents,u(0x5598,4),u(0x5582,2),134)
            auxiliary=payload(read,extents,u(0x57d0,4),u(0x57dc,2),44)
            states.append((typed,auxiliary,callbacks(auxiliary,sim)))
        a,b=states
        if a[0]!=b[0] or a[2]!=b[2]:raise ValueError('Complete auxiliary/type-five pool state differs')
        rows.append(dict(boundary='initial' if not index else index-1,type_five_bytes=len(a[0]),auxiliary_bytes=len(a[1]),
                         type_five_sha256=hashlib.sha256(a[0]).hexdigest(),
                         auxiliary_state_sha256=hashlib.sha256(repr(a[2]).encode()).hexdigest(),
                         callback_counts={str(v):sum(r[1]==v for r in a[2]) for v in (None,0xdb70,0xdb9e)},
                         raw_auxiliary_difference=region(a[1],b[1])))
    return dict(sha256=prior['sha256'],rows=rows,scope='Complete type-five pool raw bytes and auxiliary pool with only explicit null/db70/db9e callback bindings at retained checkpoints. Other globals/pools, all lifecycle paths and gameplay/capacity acceptance remain open.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for n in ('original','left','right'):p.add_argument(n,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args();r=check(a.original,a.left,a.right)
    a.out.write_text(json.dumps(r,indent=2)+'\n');print('Complete auxiliary and type-five pools match at',len(r['rows']),'checkpoints')
