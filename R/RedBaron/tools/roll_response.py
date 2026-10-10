"""Model the native airborne roll-rate response, not full aircraft dynamics."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
import barto
from hunks import read_hunks
from player_kinematics import word, scaled_delta
from render_mutations import Snapshot


def response(current, target, gain, accelerating, reversing, dt):
    current, target = word(current), word(target)
    if gain <= 0:
        raise ValueError('Requires positive aircraft roll gain')
    if current == target:
        return dict(rate=current, factor=0, acceleration=0, delta=0)
    error = word(target-current)
    quotient = abs(error*256)//gain
    if quotient > 32767:
        raise ValueError('Native division overflow requires separate handling')
    factor = min(256, max(32, quotient))
    increasing = target > current
    acceleration = (accelerating if current >= 0 else reversing) if increasing else -(accelerating if current <= 0 else reversing)
    acceleration = word((word(acceleration)*factor) >> 8)
    delta = scaled_delta(acceleration, dt)
    rate = word(current+delta)
    if (rate < target and acceleration < 0) or (rate > target and acceleration > 0):
        rate = target
    return dict(rate=rate, factor=factor, acceleration=acceleration, delta=delta)


def snapshots(root):
    p=root/'players'
    rows=json.loads((p/'players.json').read_text())
    steps={r['step']:r for r in json.loads((p/'steps.json').read_text())['records']}
    meta=json.loads((p/'initial.json').read_text())
    memory=Snapshot(p,meta['banks'])
    first=(p/f"player-{rows[0]['step']}.bin").read_bytes()
    params=int.from_bytes(first[0xc2:0xc6],'big')
    accelerating,reversing=struct.unpack('>hh',memory.read(params+0x16,4))
    gain=struct.unpack('>h',memory.read(params+0x1e,2))[0]
    # Native instruction traces independently observe control=248, target=1404.
    # This fixture checks that target's rate history; it is not an input decoder.
    target=word((248*gain)>>8)
    checks=[]
    for left,right in zip(rows,rows[1:]):
        if right['step']!=left['step']+1:
            raise ValueError('Nonconsecutive player samples')
        if left.get('held_key')!=dict(code=78,value=1) or right.get('held_key')!=dict(code=78,value=1):
            raise ValueError('Missing held-Right observation')
        before=(p/f"player-{left['step']}.bin").read_bytes()
        after=(p/f"player-{right['step']}.bin").read_bytes()
        a=struct.unpack_from('>h',before,0xd6)[0]
        b=struct.unpack_from('>h',after,0xd6)[0]
        result=response(a,target,gain,accelerating,reversing,steps[left['step']]['dt'])
        if b!=result['rate']:
            raise ValueError(f"Roll response differs at step {left['step']}")
        checks.append(dict(step=left['step'],before=a,after=b,**result))
    if not checks:raise ValueError('No roll transitions')
    return dict(target=target,gain=gain,accelerating=accelerating,reversing=reversing,checks=checks)


def trace_check(sim_file,root,chunk):
    raw=sim_file.read_bytes();entry=json.loads((root/'entry.json').read_text())
    if hashlib.sha256(raw).hexdigest()!=entry['sim_sha256']:
        raise ValueError('Original sim differs from capture')
    code=read_hunks(raw)[0].data
    for at,expected in ((0x16cb6,'2206924048c1e181'),(0x16cfe,'7220b041'),(0x16d0a,'0c400100'),(0x16d32,'d1680018')):
        b=bytes.fromhex(expected)
        if code[at:at+len(b)]!=b:raise ValueError('Changed roll-response instructions')
    meta=json.loads((chunk/'before.json').read_text());sim=meta['sim']
    memory=Snapshot(chunk,[dict(base=int(f.stem.split('-')[1],16),size=f.stat().st_size,file=f.name) for f in chunk.glob('memory-*.bin')])
    irq=json.loads((root/'capacity-costs.json').read_text())['irq_stack']
    active=False;pending=None;checks=[]
    trace=barto.load(chunk/'trace.bin')
    for field in trace.fields:
        for pc,cycles,regs in trace.instructions(field):
            if pc in (None,0x7fffffff) or irq[0]<=regs[15]<irq[1]:continue
            pc-=sim
            if pc==0x1098:active=True;pending=None
            if pc==0x11c8:active=False;pending=None
            if not active:continue
            if pc==0x16c86:
                params=regs[10]
                acceleration,reversing=struct.unpack('>hh',memory.read(params+0x16,4))
                gain=struct.unpack('>h',memory.read(params+0x1e,2))[0]
                pending=dict(before=word(regs[0]),target=word(regs[6]),gain=gain,accelerating=acceleration,reversing=reversing)
                pending['model']=response(pending['before'],pending['target'],gain,acceleration,reversing,225)
                pending['seen']=[]
            if pending is not None and pc==0x3d76 and pending['seen']==['factor','acceleration']:
                pending['dt']=word(regs[0])
                pending['model']=response(pending['before'],pending['target'],pending['gain'],pending['accelerating'],pending['reversing'],pending['dt'])
            if pending is not None and pc in (0x16d18,0x16d22,0x16d2c):
                name={0x16d18:'factor',0x16d22:'acceleration',0x16d2c:'delta'}[pc]
                if word(regs[0])!=pending['model'][name]:raise ValueError(f'Native roll {name} mismatch')
                pending['seen'].append(name)
                if name=='delta':
                    if 'dt' not in pending:raise ValueError('Missing native time scale input')
                    if pending['seen']!=['factor','acceleration','delta']:raise ValueError('Incomplete response trace')
                    checks.append(pending);pending=None
    if not checks:raise ValueError('No complete roll-response calls')
    return dict(chunk=chunk.name,checks=checks)


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('capture',type=Path);p.add_argument('--sim',type=Path);p.add_argument('--chunk');p.add_argument('--out',type=Path,required=True)
    a=p.parse_args()
    if bool(a.sim)!=bool(a.chunk):p.error('--sim and --chunk must be supplied together')
    result=trace_check(a.sim,a.capture,a.capture/a.chunk) if a.chunk else snapshots(a.capture)
    result['limitation']='Native roll-rate response only; not full force/orientation convergence, render independence, or gameplay acceptance.'
    a.out.write_text(json.dumps(result,indent=2)+'\n');print(len(result['checks']))
