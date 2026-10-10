"""Compare bank/fire acquisition and held state for equal-tick W6 captures.

Requires the four-transition keyboard fixture and the same executable build.
Does not establish combat outcomes or substitute for the full state inventory.
"""
import argparse
import json
import struct
from pathlib import Path
from render_mutations import Snapshot
from presentation_state import symbol
from world_comparison import load, clock_layout, clock_snapshot

MASK=(1<<32)-1
EXPECTED=[(0x4e,1),(0x4e,0),(0x40,1),(0x40,0)]


def events(queue,acquisitions,origin,paused,clocks=None):
    head,tail,overflow,high=struct.unpack_from('>4H',queue)
    if head!=4 or tail!=4 or overflow or not 1<=high<=4:
        raise ValueError('Fixture not completely consumed or input overflow')
    result=[]
    for i,expected in enumerate(EXPECTED):
        acquired,key,down=struct.unpack_from('>IHH',acquisitions,i*8)
        deadline,encoded,value,x,y=struct.unpack_from('>IHHII',queue,16+i*16)
        modal=False
        expected_deadline=(acquired-paused+1)&MASK
        if clocks is not None:
            active,excluded,start,base=struct.unpack_from('>IIII',clocks,i*16)
            if active not in (0,1):raise ValueError('Invalid acquisition clock owner')
            modal=not active
            expected_deadline=((start-base if modal else acquired-excluded)+1)&MASK
        if (key,down)!=expected or (encoded,value,x,y)!=(key|(0x100 if modal else 0),down,0,0):
            raise ValueError('Unexpected fixture input')
        if deadline!=expected_deadline:
            raise ValueError('Acquisition timestamp does not match active deadline')
        result.append(dict(deadline=((deadline-origin+(1<<31))&MASK)-(1<<31),key=key,down=down,modal=modal))
    return result


def validate_consumption(rows,history):
    if not rows or rows[0]['tick']!=0 or rows[0]['consumed'] or rows[0]['popped']:
        raise ValueError('Missing untouched initial input boundary')
    held=bytearray.fromhex(rows[0]['held']);at=pending=popped=0
    if len(held)!=128:raise ValueError('Truncated held-key bitmap')
    for before,row in zip(rows,rows[1:]):
        if row['tick']!=before['tick']+1:raise ValueError('Nonconsecutive input ticks')
        while at<len(history) and history[at]['deadline']<=row['cursor']:
            event=history[at];held[event['key']]=event['down']
            pending+=bool(event['down'] and not event['modal']);at+=1
        if pending:pending-=1;popped+=1
        if (row['held'],row['consumed'],row['popped'])!=(held.hex(),at,popped):
            raise ValueError('Input consumption differs from timestamp replay')
    if at!=len(history) or pending:raise ValueError('Unconsumed replay events')


def extract(root):
    entry,poses,initial,base,lines=load(root)
    at=lambda n:base+symbol(lines,n)
    fields=clock_layout(base,lines,entry['entry']['sim'])
    rows=[]
    for frame in poses['frames']:
        ram=Snapshot(root,frame['banks']);clock=clock_snapshot(ram,fields)
        consumed,popped=struct.unpack('>II',ram.read(at('time_keys_consumed'),8))
        rows.append(dict(tick=clock['completed'],cursor=(clock['cursor']-clock['paused'])&MASK,
                         paused=clock['paused'],held=ram.read(at('time_keys_bitmap'),128).hex(),
                         consumed=consumed,popped=popped))
    if not rows or any(b['tick']!=a['tick']+1 for a,b in zip(rows,rows[1:])):
        raise ValueError('Missing or nonconsecutive tick sequence')
    if any(row['paused']!=rows[0]['paused'] for row in rows):
        raise ValueError('This fixture comparison excludes modal transitions')
    if rows[0]['tick']!=0:raise ValueError('Requires initial zero-tick clock origin')
    origin=rows[0]['cursor']
    for row in rows:row['cursor']=(row['cursor']-origin)&MASK
    final=Snapshot(root,poses['frames'][-1]['banks'])
    acquired=events(final.read(at('time_input_observe_queue'),4112),
                    final.read(at('time_input_fixture_log'),32),origin,rows[-1]['paused'],
                    final.read(at('time_input_fixture_clocks'),64))
    for row in rows:del row['paused']
    commands=sum(e['down'] and not e['modal'] for e in acquired)
    if (rows[-1]['consumed'],rows[-1]['popped'])!=(4,commands):
        raise ValueError('Missing or repeated controls')
    if not any(bytes.fromhex(row['held'])[0x4e] for row in rows):
        raise ValueError('No completed update held Right')
    if not any(bytes.fromhex(row['held'])[0x40] for row in rows):
        raise ValueError('No completed update held Fire')
    validate_consumption(rows,acquired)
    return dict(sha256=entry['slave_sha256'],events=acquired,rows=rows)


def compare(left,right):
    if left['sha256']!=right['sha256']:raise ValueError('Different executable builds')
    if left['events']!=right['events']:raise ValueError('Different active-time input histories')
    if left['rows']!=right['rows']:raise ValueError('Different equal-tick input consumption')
    return dict(sha256=left['sha256'],events=left['events'],rows=left['rows'],
                same_input_history=True,limitation='Input agreement only; gameplay state and combat outcomes require separate checks.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('left',type=Path);p.add_argument('right',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=compare(extract(a.left),extract(a.right))
    a.out.write_text(json.dumps(result,indent=2)+'\n')
    print(f"Identical four-event input history and {len(result['rows'])} tick snapshots")
