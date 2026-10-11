"""Partition complete sim-v1 world calls by their immediate call sites.

Nested callees remain in their owning immediate call. IRQ costs are separated;
chunk-cut world calls are discarded, never joined speculatively.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import capstone
import barto
from hunks import read_hunks
from player_links import SIM_SHA
from render_mutations import Snapshot

START, END = 0x1098, 0x11c8


def partition(trace, sim, sites, irq, start=START, end=END):
    complete=[]; active=None; pending=None
    for field in trace.fields:
        for pc,cycles,regs in trace.instructions(field):
            sp=regs[15]; interrupt=irq[0]<=sp<irq[1]
            if pc==sim+start:
                if active is not None or interrupt:raise ValueError('Nested/IRQ world entry')
                active=dict(entry_sp=sp,groups=Counter(),irq=0,irq_entry=0,wall=0)
            if active is None:continue
            active['wall']+=cycles
            if pc==0x7fffffff:active['irq_entry']+=cycles;continue
            if interrupt:active['irq']+=cycles;continue
            if not active['entry_sp']-0x4000<=sp<=active['entry_sp']:
                raise ValueError('Unclassified main stack')
            if pending and pc==pending[1]:
                if sp!=pending[2]:raise ValueError('Immediate call did not restore stack')
                pending=None
            if pc-sim in sites:
                if pending:raise ValueError('Reentrant world call site')
                pending=(pc-sim,pc+sites[pc-sim],sp)
            active['groups'][pending[0] if pending else 'overhead']+=cycles
            if pc==sim+end:
                if pending or sp!=active['entry_sp']:raise ValueError('Incomplete world return')
                assert sum(active['groups'].values())+active['irq']+active['irq_entry']==active['wall']
                complete.append(active);active=None
    return complete,active is not None


def check(original,root,start=START,end=END):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported sim')
    code=read_hunks(raw)[0].data
    cs=capstone.Cs(capstone.CS_ARCH_M68K,capstone.CS_MODE_M68K_000)
    ins=list(cs.disasm(code[start:end+2],start))
    if sum(x.size for x in ins)!=end+2-start:raise ValueError('Incomplete world decode')
    if not ins or ins[-1].mnemonic!='rts':raise ValueError('Routine must end at RTS')
    calls={x.address:x for x in ins if x.mnemonic.split('.')[0] in ('jsr','bsr')}
    sites={pc:x.size for pc,x in calls.items()}
    meta=json.loads((root/'entry.json').read_text());manifest=json.loads((root/'capacity.json').read_text())
    digest=hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest()
    if {meta['slave_sha256'],manifest['sha256']}!={digest}:raise ValueError('Build mismatch')
    sim=meta['entry']['sim'];results=[];incomplete=[];irq=None
    for chunk in manifest['chunks']:
        directory=root/chunk['path']
        banks=[dict(file=p.name,base=int(p.stem.split('-')[1],16),size=p.stat().st_size) for p in directory.glob('memory-*.bin')]
        ram=Snapshot(directory,banks)
        # This world body has no relocations in its immediate call opcodes.
        for pc,x in calls.items():
            if ram.read(sim+pc,x.size)!=bytes(x.bytes):raise ValueError('Changed immediate call opcode')
        t=barto.load(directory/'trace.bin')
        pages={r[15]&~0xfff for f in t.fields for pc,_,r in t.instructions(f) if pc==sim+0x2ffcc}
        if len(pages)!=1:raise ValueError('Ambiguous interrupt stack')
        low=pages.pop();bounds=(low,low+4096)
        if irq is not None and irq!=bounds:raise ValueError('Interrupt stack changed')
        irq=bounds
        rows,cut=partition(t,sim,sites,irq,start,end);results.extend(rows)
        if cut:incomplete.append(chunk['path'])
    if not results:raise ValueError('No complete world calls')
    groups=Counter()
    for row in results:groups.update(row['groups'])
    total=sum(groups.values())
    return dict(sha256=digest,routine=f'sim:{start:05x}–{end:05x}',complete_calls=len(results),main_cycles=total,
        irq_cycles=sum(r['irq'] for r in results),irq_entry_cycles=sum(r['irq_entry'] for r in results),
        wall_cycles=sum(r['wall'] for r in results),cut_chunks=incomplete,
        groups=[dict(site=f'sim:{pc:05x}' if isinstance(pc,int) else pc,
                     instruction=calls[pc].mnemonic+' '+calls[pc].op_str if isinstance(pc,int) else '',
                     main_cycles=n,percent=100*n/total,mean_per_call=n/len(results))
                for pc,n in groups.most_common()],
        scope='Immediate-call inclusive main-task partition of complete selected-routine calls; not optimization savings or gameplay correctness.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('original',type=Path);p.add_argument('capture',type=Path);p.add_argument('--out',required=True,type=Path);p.add_argument('--routine',default='1098:11c8',help='Hex start:RTS offsets for a single-exit routine');a=p.parse_args()
    start,end=(int(x,16) for x in a.routine.split(':'))
    r=check(a.original,a.capture,start,end);a.out.write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2))
