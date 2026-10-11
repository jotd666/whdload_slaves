"""Compare the native planning table with explicit self-pointer bindings.

The record area and linked 148-byte pool stay raw; only the index array and
its cursor may relocate within the verified table allocation.
"""
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


def table_state(raw,root,count,used,partition,cursor,records,pool):
    capacity=count+1
    if not 0<count<500 or len(raw)!=capacity*16 or len(records)!=count*148:
        raise ValueError('Unexpected complete planning extent')
    if not 0<=used<=count or partition!=root+capacity*12:
        raise ValueError('Invalid planning partition/count')
    if not partition<=cursor<=partition+capacity*4 or (cursor-partition)%4:
        raise ValueError('Invalid planning cursor')
    body=raw[:capacity*12];indices=[]
    for off in range(0,len(body),12):
        ptr=int.from_bytes(body[off:off+4],'big')
        if ptr and (not pool<=ptr<pool+count*148 or (ptr-pool)%148):
            raise ValueError('Planning record points outside native record slots')
    for off in range(capacity*12,len(raw),4):
        ptr=int.from_bytes(raw[off:off+4],'big')
        if not ptr:indices.append(None)
        elif root<=ptr<partition and (ptr-root)%12==0:indices.append((ptr-root)//12)
        else:raise ValueError('Planning index is not an exact table slot')
    return dict(body=body.hex(),indices=indices,cursor=(cursor-partition)//4,
                used=used,count=count,records=records.hex())


def contracts(h3):
    a=lambda off:(h3+off).to_bytes(4,'big')
    b=bytes.fromhex
    return {0xda44:b('3039')+a(0x5cc)+b('524033c0')+a(0x4c74)+b('c0fc000c2e003039')+a(0x4c74)+b('e5402c002007d046'),
            0xda74:b('4eba6482504f23c0')+a(0x4c66),
            0xdaa6:b('2079')+a(0x4c66)+b('d0c77800'),
            0xdab0:b('2679')+a(0x45e2)+b('23c8')+a(0x4c6a),
            0xcf1e:b('2b79')+a(0x45e2)+b('fffc'),
            0xd028:b('226dfffc2089'),0xdb1e:b('d6fc0094'),
            0xd11c:b('23880800700cd1adfff8'),
            0xd208:b('2079')+a(0x4c6e)+b('245823c8')+a(0x4c6e)+b('23c8')+a(0x4c6e),
            0xd15a:b('23f9')+a(0x4c6a)+a(0x4c6e)+b('3039')+a(0x4c72)+b('48c0e5802079')+a(0x4c6e)+b('42b00800')}


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError('Unexpected native planning contract')
    prior=player_check(original,left,right);roots=(left,right);loaded=[load(p) for p in roots]
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded];rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,b in zip(roots,loaded,banks):
            ram=Snapshot(root,b);h3=m[1]['h3'];sim=m[0]['entry']['sim'];read=ram.read
            for at,data in contracts(h3).items():
                if exact(read,sim+at,len(data))!=data:raise ValueError('Live planning contract changed')
            u=lambda off,n:int.from_bytes(exact(read,h3+off,n),'big')
            count=u(0x5cc,2);capacity=u(0x4c74,2)
            if capacity!=count+1:raise ValueError('Native planning capacity mismatch')
            extents=allocations(read,h3);base=u(0x4c66,4);pool=u(0x45e2,4)
            table=payload(read,extents,base,capacity,16);records=payload(read,extents,pool,count,148)
            states.append((table,table_state(table,base,count,u(0x4c72,2),u(0x4c6a,4),u(0x4c6e,4),records,pool)))
        a,b=states
        if a[1]!=b[1]:raise ValueError('Complete planning table/records differ')
        rows.append(dict(boundary='initial' if not index else index-1,state=a[1],raw_difference=region(a[0],b[0])))
    return dict(sha256=prior['sha256'],rows=rows,scope='Complete planning table, explicit in-table indices/cursor and raw linked 148-byte records at retained boundaries only. No general heap normalization or whole-gameplay acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for n in ('original','left','right'):p.add_argument(n,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args();r=check(a.original,a.left,a.right)
    a.out.write_text(json.dumps(r,indent=2)+'\n');print('Complete planning table matches at',len(r['rows']),'checkpoints')
