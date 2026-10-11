"""Pair private original/candidate calls within one native matrix twin invocation."""
import argparse
import hashlib
import json
from pathlib import Path
import barto
from presentation_state import symbol
from render_mutations import Snapshot


def paired(trace,entry,routines,irq):
    rows=[];pair=None;active=None
    for field in trace.fields:
        for pc,cycles,regs in trace.instructions(field):
            sp=regs[15];is_irq=irq[0]<=sp<irq[1]
            if pc==entry:
                if pair is not None:raise ValueError('Unfinished/reentrant twin')
                pair=dict(case=63-regs[7],ccr=regs[6],calls={})
                if not 0<=pair['case']<64 or not 0<=pair['ccr']<32:raise ValueError('Bad twin iteration')
            if pair is None:continue
            for name,(start,end) in routines.items():
                if pc==start:
                    if active is not None or name in pair['calls'] or is_irq:raise ValueError('Unexpected call entry')
                    active=dict(name=name,sp=sp,main=0,irq=0,irq_entry=0,wall=0)
            if active is not None:
                active['wall']+=cycles
                if pc==0x7fffffff:active['irq_entry']+=cycles
                elif is_irq:active['irq']+=cycles
                else:
                    if not active['sp']-0x4000<=sp<=active['sp']:raise ValueError('Unclassified stack')
                    active['main']+=cycles
                if pc==routines[active['name']][1]:
                    if is_irq or sp!=active['sp']:raise ValueError('Bad return stack')
                    name=active.pop('name');active.pop('sp');pair['calls'][name]=active;active=None
                    if name=='candidate':
                        if set(pair['calls'])!={'original','candidate'}:raise ValueError('Candidate without original')
                        rows.append(pair);pair=None
    return rows,pair is not None


def check(root):
    m=json.loads((root/'entry.json').read_text());digest=hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest()
    if digest!=m['slave_sha256']:raise ValueError('Frozen binary mismatch')
    if m['cpu']!='68000':raise ValueError('This timing protocol requires the 68000 capture')
    if 'TWINS 2048' not in (root/'matrix-completion.log').read_text():raise ValueError('Native twins did not complete')
    lines=(root/'slave.lst').read_text(encoding='latin-1').splitlines();base=m['entry']['game_anchor']-symbol(lines,'tape_game_anchor');at=lambda n:base+symbol(lines,n)
    routines={n:(at('time_matrix_'+n),at('time_matrix_'+n)+0x400) for n in ('original','candidate')}
    rows=[];cut=[];bounds=None
    for i in range(3):
        d=root/f'matrix-cost-{i}'
        banks=[dict(file=p.name,base=int(p.stem.split('-')[1],16),size=p.stat().st_size) for p in d.glob('memory-*.bin')]
        ram=Snapshot(d,banks)
        native=ram.read(m['entry']['sim']+0x3648c,0x402)
        if native!=ram.read(at('time_matrix_original'),0x402):raise ValueError('Private original differs from unpatched game')
        if native[:4]!=bytes.fromhex('4e550000') or ram.read(at('time_matrix_candidate'),4)!=bytes.fromhex('4e55fffa'):
            raise ValueError('Unexpected matrix entry')
        t=barto.load(d/'trace.bin')
        if len(t.fields)!=(100,100,50)[i]:raise ValueError('Requires the complete 250 recorded fields')
        pages={r[15]&~0xfff for f in t.fields for pc,_,r in t.instructions(f) if pc==m['entry']['sim']+0x2ffcc}
        if len(pages)!=1:raise ValueError('Ambiguous IRQ stack')
        low=pages.pop();irq=(low,low+4096)
        if bounds is not None and irq!=bounds:raise ValueError('Changed IRQ stack')
        bounds=irq
        found,incomplete=paired(t,at('time_matrix_twin'),routines,irq)
        rows.extend(found)
        if incomplete:cut.append(i)
    if not rows:raise ValueError('No complete twin pairs')
    if len({(r['case'],r['ccr']) for r in rows})!=len(rows):raise ValueError('Repeated twin identity')
    groups=[]
    for case in sorted({r['case'] for r in rows}):
        group=[r for r in rows if r['case']==case]
        a=sum(r['calls']['original']['main'] for r in group);b=sum(r['calls']['candidate']['main'] for r in group)
        groups.append(dict(case=case,pairs=len(group),original_main=a,candidate_main=b,saved_main=a-b,change_percent=100*(b-a)/a))
    a=sum(x['original_main'] for x in groups);b=sum(x['candidate_main'] for x in groups)
    return dict(sha256=digest,pairs=len(rows),original_main=a,candidate_main=b,change_percent=100*(b-a)/a,
                cases=groups,cut_chunks=cut,rows=rows,scope='Matched private twin inputs and CCR in one 250-field A500 trace; routine main cycles include helper/stack work. Not installed-hook or game FPS savings.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    r=check(a.capture);a.out.write_text(json.dumps(r,indent=2)+'\n');print({k:v for k,v in r.items() if k not in ('rows','cases')});print(r['cases'])
