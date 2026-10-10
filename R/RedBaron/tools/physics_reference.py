"""Compare forced-step airborne trajectories at equal accumulated primary time.

This reports differences, not a physics/combat acceptance verdict. Forces are
native inputs to the separately checked position integrator.
"""
import argparse
import json
import math
from pathlib import Path
from player_kinematics import audit,word
from render_mutations import Snapshot,region
from game_heap import allocations,segments


def trajectory(rows,records):
    if len(rows)<2:raise ValueError('Need consecutive trajectory samples')
    if [r['step'] for r in rows]!=list(range(rows[0]['step'],rows[-1]['step']+1)):
        raise ValueError('Nonconsecutive physics samples')
    ring={r['step']:r for r in records}
    if len(ring)!=len(records):raise ValueError('Duplicate native step records')
    sampled=[ring[r['step']] for r in rows]
    if len({(r['F'],r['time_scale']) for r in sampled})!=1:
        raise ValueError('Changing Time Scale')
    dt={r['dt'] for r in sampled}
    if len(dt)!=1 or not 0<next(iter(dt))<=400:
        raise ValueError('Requires fixed proportional-regime primary dt')
    keys=[r.get('held_key') for r in rows]
    if any(k!=dict(code=0x4e,value=1) for k in keys):
        raise ValueError('Constant Right input was not observed throughout')
    quantum=dt.pop()
    return dict(quantum=quantum,budget=(len(rows)-1)*quantum,
                updates=len(rows)-1,F=sampled[0]['F'],time_scale=sampled[0]['time_scale'],
                distance=sum(math.dist(a['position'],b['position']) for a,b in zip(rows,rows[1:])),
                initial_position=rows[0]['position'],final_position=rows[-1]['position'],
                initial_orientation=rows[0]['orientation'],final_orientation=rows[-1]['orientation'])


def compare(left,right):
    if left['budget']!=right['budget'] or (left['F'],left['time_scale'])!=(right['F'],right['time_scale']):
        raise ValueError('Unequal simulated time or Time Scale')
    if left['initial_position']!=right['initial_position'] or left['initial_orientation']!=right['initial_orientation']:
        raise ValueError('Different starting pose')
    if right['quantum']>=left['quantum']:raise ValueError('Reference must use a smaller step')
    return dict(candidate=left,reference=right,
                endpoint_separation=math.dist(left['final_position'],right['final_position']),
                orientation_difference=[word(a-b) for a,b in zip(left['final_orientation'],right['final_orientation'])],
                distance_difference_percent=100*(left['distance']/right['distance']-1) if right['distance'] else None)


def check(left,right):
    le=json.loads((left/'entry.json').read_text());re=json.loads((right/'entry.json').read_text())
    if le['slave_sha256']!=re['slave_sha256']:raise ValueError('Different fixture builds')
    summaries=[];models=[];initial=[]
    for root in (left,right):
        p=root/'players';rows=json.loads((p/'players.json').read_text())
        records=json.loads((p/'steps.json').read_text())['records']
        summaries.append(trajectory(rows,records));models.append(audit(p))
        initial.append((p/f"player-{rows[0]['step']}.bin").read_bytes())
    if initial[0]!=initial[1] or len(initial[0])!=0x118:
        raise ValueError('Initial complete player states differ')
    lm=json.loads((left/'players/initial.json').read_text())
    rm=json.loads((right/'players/initial.json').read_text())
    if (lm['sim'],lm['h3'])!=(rm['sim'],rm['h3']):raise ValueError('Different initial address layout')
    l=Snapshot(left/'players',lm['banks']);r=Snapshot(right/'players',rm['banks'])
    h3=lm['h3'];la=allocations(l.read,h3);ra=allocations(r.read,h3)
    if la!=ra or any(l.read(p,n)!=r.read(p,n) for p,n in la):
        raise ValueError('Initial tracked heap differs')
    ls=segments(l.read,lm['sim']);rs=segments(r.read,rm['sim'])
    if ls!=rs:raise ValueError('Initial segment layouts differ')
    differences=[]
    for index,(pointer,size) in enumerate(ls):
        a=l.read(pointer,size);b=r.read(pointer,size)
        differences.append(dict(index=index,changes=region(a,b)))
        if index==3:
            if int.from_bytes(a[0x4834:0x4836],'big')!=summaries[0]['quantum'] or int.from_bytes(b[0x4834:0x4836],'big')!=summaries[1]['quantum']:
                raise ValueError('Initial forced dt differs from sampled dt')
            a=a[:0x4834]+b[0x4834:0x4836]+a[0x4836:]
        if a!=b:raise ValueError('Initial sim state differs beyond the intentional primary dt')
    initial_check=dict(allocations=len(la),allocation_bytes=sum(n for _,n in la),segment_differences=differences)
    return dict(sha256=le['slave_sha256'],**compare(*summaries),kinematics=models,initial=initial_check,
                limitation='Observed airborne bank trajectory only; no force model, contact/hit outcome, other Time Scale, scheduler or performance acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('candidate',type=Path);p.add_argument('reference',type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.candidate,a.reference);a.out.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
