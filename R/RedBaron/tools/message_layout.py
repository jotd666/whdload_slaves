"""Validate retained single-message layout across render schedules.

The native erasure copies expanded draw bounds back to the message rectangle.
Keep those raw differences visible; this is not a gameplay-state exclusion mask.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from hunks import read_hunks
from message_boundaries import compare
from render_mutations import Snapshot
from world_comparison import load

SIM_SHA='e9b3889bc6f177e0bcfc74987665cdafbccd984b3a031bdd1f98f6c445dd8839'


def expanded(rect):
    if len(rect)!=8:raise ValueError('Expected four native rectangle words')
    words=struct.unpack('>4H',rect)
    return struct.pack('>4H',*((v+d)&65535 for v,d in zip(words,(-3,-3,6,6))))


def expected(initial,scratch,events):
    if len(scratch)!=8 or scratch!=expanded(initial):
        raise ValueError('Draw bounds differ from native border expansion')
    if not events or events[0][2]!=1 or sum(e[2]==1 for e in events)!=1:
        raise ValueError('Only one inherited message without replacement is supported')
    if any(e[7]!=events[0][7] for e in events):
        raise ValueError('Message pointer changed')
    erasures=sum(e[2]==4 for e in events)
    if erasures>1:raise ValueError('Repeated erasure without replacement')
    return scratch if erasures else initial


def check(original,roots):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original executable')
    code=read_hunks(raw)[0].data
    # Native border expansion followed by stores to h3:456a..4571.
    if code[0x8d2:0x8f2]!=bytes.fromhex('303900004822574032390000482457413439000048265c423639000048285c43'):
        raise ValueError('Unexpected native rectangle expansion')
    # Erasure copies those four words to h3:4822..4829.
    copy=bytes.fromhex('33f90000456a0000482233f90000456c0000482433f90000456e0000482633f90000457000004828')
    if code[0xa7e:0xaa6]!=copy:raise ValueError('Unexpected erasure rectangle copy')
    refs=[]
    for number,hunk in enumerate(read_hunks(raw)):
        for operand,target in hunk.relocations:
            value=struct.unpack_from('>I',hunk.data,operand)[0]
            if target==3 and (0x4822<=value<0x482a or value==0x706):
                refs.append(dict(hunk=number,operand=f'{operand:05x}',target=f'h3:{value:05x}'))
    ledger=compare(original,roots);runs={}
    for root in roots:
        entry,poses,*_=load(root);h3=poses['h3'];log=ledger['captures'][root.name]
        rows=[];initial=None
        for frame,eventrow in zip(poses['frames'],log['rows']):
            ram=Snapshot(root,frame['banks']);rect=ram.read(h3+0x4822,8);scratch=ram.read(h3+0x456a,8)
            if ram.read(h3+0x706,4)!=(h3+0x4822).to_bytes(4,'big'):
                raise ValueError('Native text-layout alias changed')
            if initial is None:initial=rect
            events=log['events'][:eventrow['events']]
            want=expected(initial,scratch,events)
            if rect!=want:raise ValueError('Native message rectangle differs from erasure model')
            rows.append(dict(tick=frame['index'],rectangle=list(struct.unpack('>4h',rect)),
                             draw_bounds=list(struct.unpack('>4h',scratch)),erased=any(e[2]==4 for e in events),
                             raw_changed_bytes=sum(a!=b for a,b in zip(initial,rect))))
        runs[root.name]=rows
    return dict(sha256=next(iter(ledger['captures'].values()))['sha256'],captures=runs,direct_references=refs,alias='h3:00706 -> h3:04822',
                scope='Single inherited message, border expansion and erasure-copy bytes at retained boundaries. No replacement, complete dirty-buffer pixels, arbitrary aliases or whole-gameplay acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('original',type=Path)
    p.add_argument('captures',type=Path,nargs='+');p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.original,a.captures)
    a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Message rectangle model matches',sum(len(r) for r in result['captures'].values()),'retained boundaries')
