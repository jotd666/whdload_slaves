"""Compare message logical clocks and native priority inputs across render schedules.

Keeps erasure events and raw timers visible. This is not a pixel or complete
message-API proof; startup reset inherits the existing native timer unchanged.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from hunks import read_hunks
from message_time import DURATION, legacy, remaining, shortened
from presentation_state import symbol
from render_mutations import Snapshot
from world_comparison import load

MASK = 0xffffffff


def priority_open(timer):
    if not 0 <= timer <= 65535: raise ValueError('Invalid native timer word')
    signed = timer-65536 if timer & 32768 else timer
    return signed < 7500


def policy(events, startup_timer):
    """Validate complete ledger beginning at the native flight-reset arm."""
    if not events: raise ValueError('Missing native message ledger')
    current = None
    for index, event in enumerate(events):
        if len(event) != 8: raise ValueError('Truncated message event')
        now, deadline, kind, phase, timer, dirty, draws, pointer = event
        if kind == 1:
            expected = startup_timer if index == 0 else 15000
            valid = ((deadline-now)&MASK) == DURATION and phase == 1 and timer == expected
        elif kind == 2:
            valid = current is not None and pointer == current[7] and phase == 1 and 0 <= timer <= 15000 and ((deadline-now)&MASK) == shortened(timer)
        elif kind == 3:
            valid = current is not None and current[3] == 1 and (deadline,pointer) == (current[1],current[7]) and now == deadline and phase == 2 and timer == 1 and dirty == 2
        elif kind == 4:
            valid = current is not None and current[3] == 2 and (deadline,pointer) == (current[1],current[7]) and phase == 0 and timer == 0 and remaining(deadline,now) == 0
        else: valid = False
        if not valid: raise ValueError(f'Invalid message event {index}')
        current = event


def check_row(row, startup=False):
    phase,timer,deadline,now = (row[k] for k in ('phase','timer','deadline','now'))
    if startup:
        # Reset arms a new deadline without replacing the inherited native word.
        valid = phase == 1 and remaining(deadline,now) == DURATION and 0 < timer <= 15000
    elif phase == 1:
        left = remaining(deadline,now)
        valid = 0 < left <= DURATION and timer == legacy(left)
    elif phase == 2: valid = remaining(deadline,now) == 0 and timer == 1
    elif phase == 0: valid = remaining(deadline,now) == 0 and timer == 0
    else: valid = False
    if not valid: raise ValueError('Message timer/phase differs from active-time policy')
    return priority_open(timer)


def logical_events(events, epoch):
    # Publication is reported separately, never silently erased from raw data.
    return [[(e[0]-epoch)&MASK,(e[1]-epoch)&MASK,e[2],e[4],e[7]] for e in events if e[2] != 4]


def capture(root):
    entry,poses,initial,base,lines = load(root)
    digest = hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest()
    if {entry['slave_sha256'],poses['sha256'],initial['sha256']} != {digest}:
        raise ValueError('Different capture or frozen builds')
    at = lambda name: base+symbol(lines,name)
    h3=poses['h3']; rows=[]; previous=[]
    for frame in poses['frames']:
        ram=Snapshot(root,frame['banks']);read=ram.read
        tick=int.from_bytes(read(at('time_pose_header')+4,4),'big')
        if tick != len(rows): raise ValueError('Expected consecutive world boundaries from zero')
        if int.from_bytes(read(at('time_message_test_result'),4),'big') != 179:
            raise ValueError('Native message arithmetic checks did not pass')
        expected_priority=bytes.fromhex('0c791d4c')+(h3+0x4820).to_bytes(4,'big')+bytes.fromhex('6c0813fc0064')+(h3+0x4830).to_bytes(4,'big')
        if read(entry['entry']['sim']+0x114e,18) != expected_priority:
            raise ValueError('Native priority consumer was changed')
        loop=read(at('time_loop_state'),60)
        now=(int.from_bytes(loop[20:24],'big')-int.from_bytes(loop[44:48],'big'))&MASK
        deadline,start,phase=struct.unpack('>IIH',read(at('time_message_state'),10))
        count=int.from_bytes(read(at('time_message_count'),4),'big')
        if not 0 < count < 128: raise ValueError('Missing or saturated message ledger')
        events=[list(struct.unpack('>II4HII',read(at('time_message_log')+24*j,24))) for j in range(count)]
        if events[:len(previous)] != previous: raise ValueError('Ledger prefix changed')
        timer=int.from_bytes(read(h3+0x4820,2),'big')
        pointer=int.from_bytes(read(h3+0x481c,4),'big')
        row=dict(tick=tick,now=now,deadline=deadline,start=start,phase=phase,timer=timer,
                 pointer=pointer,format_state=read(h3+0x482e,3).hex(),events=count)
        row['priority_open']=check_row(row,startup=tick==0)
        policy(events,rows[0]['timer'] if rows else timer)
        if (deadline,phase,pointer) != (events[-1][1],events[-1][3],events[-1][7]):
            raise ValueError('Message state differs from last ledger event')
        rows.append(row);previous=events
    if len(rows)<2: raise ValueError('No post-start observations')
    epoch=rows[0]['now']
    return dict(sha256=digest,sim_sha256=entry['sim_sha256'],h3=h3,rows=rows,events=previous,epoch=epoch,
                logical_events=logical_events(previous,epoch),
                erasures=[dict(relative_now=(e[0]-epoch)&MASK,relative_deadline=(e[1]-epoch)&MASK,draws=e[6]) for e in previous if e[2]==4])


def compare(original, roots):
    code=read_hunks(original.read_bytes())[0].data
    if hashlib.sha256(code[0x114e:0x1160]).hexdigest() != 'ba2e65f1e01077c74ee66b91b4314b0b7c0dee2966ff361fa95326bc7273d135':
        raise ValueError('Unsupported native priority consumer')
    results=[capture(root) for root in roots]
    if len(results)<2 or len({r['sha256'] for r in results})!=1:
        raise ValueError('Need matching builds from at least two schedules')
    if len({r['h3'] for r in results}) != 1 or {r['sim_sha256'] for r in results} != {hashlib.sha256(original.read_bytes()).hexdigest()}:
        raise ValueError('Different global allocation or original executable')
    reference=results[0]
    for other in results[1:]:
        if other['logical_events'] != reference['logical_events'] or len(other['rows']) != len(reference['rows']):
            raise ValueError('Message logical event sequence differs')
        for a,b in zip(reference['rows'],other['rows']):
            for key in ('tick','pointer','format_state','priority_open'):
                if a[key]!=b[key]: raise ValueError(f'Differing native message input: {key}')
            for key in ('now','deadline','start'):
                if (a[key]-reference['epoch'])&MASK != (b[key]-other['epoch'])&MASK:
                    raise ValueError(f'Differing relative message clock: {key}')
            if (a['phase']==1)!=(b['phase']==1): raise ValueError('Message liveness differs')
    return dict(captures={root.name:r for root,r in zip(roots,results)},
                boundaries=len(reference['rows']),logical_events_equal=True,priority_inputs_equal=True,
                scope='Native message ledger and priority inputs at retained boundaries. Erasure remains render-dependent; no pixel, other message-API, terrain or whole-gameplay verdict.')


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('original',type=Path);p.add_argument('captures',type=Path,nargs='+')
    p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=compare(a.original,a.captures)
    a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Message logical events and priority inputs match at',result['boundaries'],'boundaries across',len(result['captures']),'schedules')
