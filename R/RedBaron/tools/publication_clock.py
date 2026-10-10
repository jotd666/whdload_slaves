"""Check publication spacing and exact W6 funding across native draw/wait intervals."""
import argparse
import json
from pathlib import Path
from game_time_core import DENOMINATOR, THRESHOLD
from pacing_model import MASK, safe_line


def phase(row):
    return sum(row[f'phase{i}'] << (96-32*i) for i in range(4))


def check(data, minimum):
    rows=data['rows']
    if len(rows)<3:
        raise ValueError('Need at least three publications')
    intervals=[(b['field']-a['field']) & MASK for a,b in zip(rows,rows[1:])]
    if any(n<minimum or n>=1<<31 for n in intervals):
        raise ValueError('Publication deadline violated')
    if not all(safe_line((r['beam']>>8)&511) for r in rows):
        raise ValueError('Publication outside native safe beam window')
    active=[r for r in rows if r['active']]
    checked=0
    for a,b in zip(active,active[1:]):
        if a['divisor']!=b['divisor'] or not 10<=a['divisor']<=80:
            raise ValueError('This capture requires constant Time Scale')
        if a['due'] or b['due']:
            raise ValueError('World work remained due at publication')
        if a['mask'] & 0x2300 != 0x2300 or b['mask'] & 0x2300 != 0x2300:
            raise ValueError('Missing W6 safe-publication dependency')
        elapsed=(b['cursor']-a['cursor']) & MASK
        steps=(b['steps']-a['steps']) & MASK
        if elapsed>=1<<31 or steps>=1<<31:
            raise ValueError('Nonmonotonic clock or world steps')
        if not 0<=phase(a)<THRESHOLD or not 0<=phase(b)<THRESHOLD:
            raise ValueError('Invalid fractional phase')
        increment=DENOMINATOR//a['divisor']*1024
        if steps*THRESHOLD+phase(b)-phase(a)!=elapsed*increment:
            raise ValueError('Native completed ticks/phase do not match funded CIA time')
        checked+=1
    if rows[0]['mask'] & 8192 and checked<2:
        raise ValueError('Too few active W6 clock observations')
    debts=[(r['cia']-r['cursor']) & MASK for r in active]
    if any(n>=1<<31 for n in debts):
        raise ValueError('Clock cursor ahead of observed CIA time')
    return dict(sha256=data['sha256'],publications=len(rows),minimum_fields=minimum,
                interval_fields=intervals,counter_wrapped=any(a['field']>b['field'] for a,b in zip(rows,rows[1:])),
                exact_clock_intervals=checked,repeated_world_tick_pairs=sum(a['steps']==b['steps'] for a,b in zip(active,active[1:])),
                observed_debt_cia_range=[min(debts),max(debts)] if debts else None,
                scope='Publication policy and constant-rate clock accounting; not capacity, pixels or full gameplay convergence.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--minimum',type=int,choices=[1,2],required=True);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(json.loads(a.capture.read_text()),a.minimum);a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
