"""Compare full native message descriptor and explicitly owned static text."""
import argparse
import hashlib
import json
from pathlib import Path
from game_heap import exact
from hunks import read_hunks
from player_links import SIM_SHA
from prelude_state import check as prelude_check
from presentation_state import symbol
from render_mutations import Snapshot, region
from world_comparison import load
from world_controls import compare as compare_controls, extract


def state(read,h3,original):
    raw=exact(read,h3+0x481c,22);body=bytearray(raw);owners=[]
    # Native descriptor: main text, countdown/rectangle, secondary text,
    # line count, redraw flag, priority and final byte.
    lines=raw[18]
    for field in (0,14):
        pointer=int.from_bytes(raw[field:field+4],'big')
        owner=None
        if pointer:
            offset=pointer-h3
            if not lines or not 0<=offset<len(original): raise ValueError('Unsupported message text owner/count')
            end=offset
            for _ in range(lines):
                end=original.find(b'\0',end)
                if end<0: raise ValueError('Unterminated original message text')
                end+=1
            text=exact(read,pointer,end-offset)
            if text!=original[offset:end]: raise ValueError('Changed static message text')
            owner=dict(offset=offset,text=text.hex())
        owners.append(owner);body[field:field+4]=bytes(4)
    return dict(body=body.hex(),owners=owners,raw=raw)


def equal(a,b):
    if (a['body'],a['owners'])!=(b['body'],b['owners']): raise ValueError('Message descriptor/text differs')


def contracts(h3):
    a=lambda off:(h3+off).to_bytes(4,'big'); b=bytes.fromhex
    return {
        0x3a7a:b('41f9')+a(0x481c)+b('43edffea700422d851c8fffc3290'),
        0x3bf8:b('23cb')+a(0x481c)+b('200713c0')+a(0x482e),
        0x3c06:b('33fc3a98')+a(0x4820),
        0x3c1e:b('23ca')+a(0x482a),
        0x3c68:b('2079')+a(0x481c)+b('b1cb6610'),
        0x3c7c:b('33c7')+a(0x4820),
        0x3b5e:b('204b4a1866fc538891cb20085240d6c0'),
    }


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA: raise ValueError('Unsupported sim')
    hunks=read_hunks(raw);code=hunks[0].data;data=hunks[3].data
    for at,value in contracts(0).items():
        if code[at:at+len(value)]!=value: raise ValueError(f'Original message contract {at:x}')
    roots=(left,right);loaded=[load(p) for p in roots];prior=[prelude_check(p) for p in roots]
    if len({p['sha256'] for p in prior})!=1 or any(m[0]['sim_sha256']!=SIM_SHA for m in loaded): raise ValueError('Different capture executables')
    compare_controls(*(extract(p) for p in roots))
    if [r['tick'] for r in prior[0]['rows']]!=[r['tick'] for r in prior[1]['rows']]: raise ValueError('Different world boundaries')
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]): raise ValueError('Unequal checkpoints')
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,bank in zip(roots,loaded,banks):
            ram=Snapshot(root,bank);h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,value in contracts(h3).items():
                # Initial prelude precedes deferred W6 installation. Later
                # captures must contain the exact frozen message hooks.
                hook={0x3c06:'time_message_start',0x3c7c:'time_message_shorten'}.get(at)
                if index and hook:
                    value=bytes.fromhex('4eb9')+(m[3]+symbol(m[4],hook)).to_bytes(4,'big')
                    if at==0x3c06: value+=bytes.fromhex('4e71')
                if exact(ram.read,sim+at,len(value))!=value: raise ValueError(f'Changed live message contract {at:x}')
            states.append(state(ram.read,h3,data))
        a,b=states;equal(a,b)
        rows.append(dict(boundary='initial' if not index else index-1,body=a['body'],owners=a['owners'],raw_difference=region(a['raw'],b['raw'])))
    return dict(sha256=prior[0]['sha256'],sim_sha256=SIM_SHA,rows=rows,
                scope='Complete 22-byte message descriptor with explicit null/static h3 text identities and exact original NUL-terminated lines at equal-tick checkpoints. No dynamic text owner, all message paths, physical display latency, whole-gameplay or capacity verdict.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('original','left','right'):p.add_argument(name,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.original,a.left,a.right);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Complete message state matches at',len(result['rows']),'checkpoints')
