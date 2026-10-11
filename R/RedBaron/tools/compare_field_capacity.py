"""Compare paired render/no-render funding without equating FPS with game speed."""
import argparse
import hashlib
import json
import re
from fractions import Fraction
from pathlib import Path
from field_capacity import check as capacity_check
from sustained_capacity import backlog
from time_capacity import interval


def options(text):
    found=re.findall(r'CUSTOM([245])=(-?\d+)',text)
    if len(found)!=3 or len({k for k,v in found})!=3:raise ValueError('Ambiguous CUSTOM options')
    return {int(k):int(v)&0xffffffff for k,v in found}


def compare(entries,censuses):
    if len(entries)!=2 or len(censuses)!=2:raise ValueError('Requires render/no-render pair')
    for key in ('slave_sha256','sim_sha256','preferences_sha256','cpu','chip_kb','fast_kb','extra_args','detail'):
        if entries[0][key]!=entries[1][key]:raise ValueError('Pair configuration differs: '+key)
    left,right=[options(e['whd_args']) for e in entries]
    remainder=[re.sub(r'CUSTOM5=-?\d+', 'CUSTOM5=<fixture>',e['whd_args']) for e in entries]
    if remainder[0]!=remainder[1]:raise ValueError('Non-fixture launch arguments differ')
    if left[2]!=right[2] or left[4]!=right[4] or left[5]&(1<<30) or right[5]!=left[5]|(1<<30):
        raise ValueError('Only no-render fixture may differ')
    if any(c['sha256']!=e['slave_sha256'] or c['whd_args']!=e['whd_args'] for c,e in zip(censuses,entries)):
        raise ValueError('Census does not match entry configuration')
    checked=[capacity_check(c) for c in censuses];rows=[]
    for c,checks in zip(censuses,checked):
        a=c['windows'][0]['before'];b=c['windows'][-1]['after'];r=interval(a,b)
        funded=Fraction(r['elapsed_cia_ticks']*1024,a['divisor']*225)
        before,after=backlog(a),backlog(b)
        if after-before!=funded-r['completed_world_ticks']:raise ValueError('Unaccounted world credit')
        r.update(divisor=a['divisor'],backlog_before=float(before),backlog_after=float(after),
                 publications=sum(w['publications'] for w in checks['windows']))
        rows.append(r)
    if rows[0]['elapsed_fields']!=rows[1]['elapsed_fields'] or rows[0]['divisor']!=rows[1]['divisor']:
        raise ValueError('Different field duration or Time Scale')
    if not rows[0]['publications'] or rows[1]['publications'] or rows[1]['completed_draws']:
        raise ValueError('Pair did not exercise rendering versus no rendering')
    return dict(sha256=entries[0]['slave_sha256'],render=rows[0],no_render=rows[1],
                funding_per_cia_tick_equal=True,
                scope='Same-build/configuration render versus no-render elapsed-time accounting, with all completion differences retained as credit/debt. Does not prove equal initial/full world state, events, trajectories, physical latency or sustained/all-scene capacity.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('render',type=Path);p.add_argument('no_render',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    roots=(a.render,a.no_render)
    entries=[json.loads((r/'entry.json').read_text()) for r in roots]
    if any(hashlib.sha256((r/'slave.slave').read_bytes()).hexdigest()!=e['slave_sha256'] for r,e in zip(roots,entries)):
        raise ValueError('Frozen binary does not match capture identity')
    result=compare(entries,[json.loads((r/'field-census.json').read_text()) for r in roots])
    a.out.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
