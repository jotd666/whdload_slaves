"""Account for W6 completed work, exact funded time, and profile-boundary gaps.

Constant Time Scale, no compression or modal transitions. Publication count is
completed outer draws; trace publication census remains a separate cross-check.
"""
import argparse
import json
from fractions import Fraction
from pathlib import Path
from game_time_core import DENOMINATOR, THRESHOLD
from publication_clock import phase

MASK=(1<<32)-1


def delta(a,b,key):
    value=(b[key]-a[key])&MASK
    if value>=1<<31:
        raise ValueError(f'Nonmonotonic {key}')
    return value


def interval(a,b):
    if not a['active'] or not b['active'] or a['paused']!=b['paused']:
        raise ValueError('Inactive or modal interval is not a flight capacity sample')
    if a['divisor']!=b['divisor'] or not 10<=a['divisor']<=80:
        raise ValueError('Requires constant Time Scale')
    increment=DENOMINATOR//a['divisor']*1024
    for row in (a,b):
        if row.get('transaction',0):
            raise ValueError('Snapshot is inside an uncommitted clock transaction')
        if not 0<=phase(row)<THRESHOLD or not 0<=(row['started']-row['completed'])&MASK<=1:
            raise ValueError('Invalid phase or more than one world update in progress')
        if (row['cia']-row['cursor'])&MASK>=1<<31:
            raise ValueError('Clock cursor ahead of current time')
    elapsed=delta(a,b,'cia');fields=delta(a,b,'field')
    issued=delta(a,b,'started')+b['due']-a['due']
    if issued*THRESHOLD+phase(b)-phase(a)!=delta(a,b,'cursor')*increment:
        raise ValueError('World updates and phase do not conserve funded time')
    completed=delta(a,b,'completed');draws=delta(a,b,'draws')
    nominal=Fraction(elapsed*1024,a['divisor']*225)
    return dict(elapsed_fields=fields,elapsed_cia_ticks=elapsed,completed_world_ticks=completed,
                started_world_ticks=delta(a,b,'started'),nominal_world_ticks=float(nominal),
                completed_over_nominal=float(completed/nominal) if nominal else None,
                in_progress_before=(a['started']-a['completed'])&MASK,in_progress_after=(b['started']-b['completed'])&MASK,
                unprocessed_cia_before=(a['cia']-a['cursor'])&MASK,unprocessed_cia_after=(b['cia']-b['cursor'])&MASK,
                due_before=a['due'],due_after=b['due'],completed_draws=draws,
                completed_draws_per_pal_second=draws*50/fields if fields else None,
                exact_funding=True)


def check(data):
    chunks=data['chunks']
    if sum(x['recorded_fields'] for x in chunks)!=250:
        raise ValueError('Acceptance sample must retain 250 recorded PAL fields')
    for a,b in zip(chunks,chunks[1:]):
        if a['after']!=b['before']:
            raise ValueError('Unaccounted execution between profile chunks')
    rows=[dict(recorded_fields=x['recorded_fields'],**interval(x['before'],x['after'])) for x in chunks]
    return dict(sha256=data['sha256'],recorded_fields=250,chunks=rows,
                overall=interval(chunks[0]['before'],chunks[-1]['after']),
                limitation='One constant-rate window; boundaries include profiler alignment gaps. No whole-game convergence or sustained-capacity acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('manifest',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(json.loads(a.manifest.read_text()));a.out.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
