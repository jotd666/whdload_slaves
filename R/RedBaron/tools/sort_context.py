"""Audit sim-v1 sorting context lifetimes; never normalize world-state bytes."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
import barto
from hunks import read_hunks

CONTEXT=0x4e1a


def original_contract(raw):
    hunks=read_hunks(raw)
    refs=[]
    for index,hunk in enumerate(hunks):
        for at,target in hunk.relocations:
            value=struct.unpack_from('>I',hunk.data,at)[0]
            if target==3 and CONTEXT<=value<CONTEXT+4:
                refs.append((index,at,value))
    if sorted(refs)!=[(0,0xe44a,CONTEXT),(0,0xe49a,CONTEXT)]:
        raise ValueError('Unclassified sorting context reference')
    code=hunks[0].data
    expected={0xe448:'207900004e1a',0xe498:'23ca00004e1a',
              0xe49e:'487aff8870013f003f07486dff6a4eba00b0',
              0xe44e:'2030180090b02800',0xe4fa:'4e75'}
    for at,hexbytes in expected.items():
        block=bytes.fromhex(hexbytes)
        if code[at:at+len(block)]!=block:raise ValueError('Changed sorting context contract')
    return dict(sim_sha256=hashlib.sha256(raw).hexdigest(),
                context='h3:04e1a',store='sim:0e498',read='sim:0e448',
                scope='Exact supported writer, callback handoff and indexed reads; computed aliases need separate analysis.')


class Audit:
    def __init__(self):
        self.active=None
        self.calls=[]
        self.leading_reads=0

    def feed(self,pc,regs):
        if pc==0xe470:
            if self.active is not None:raise ValueError('Nested sort context owner')
            self.active=dict(pointer=None,reads=0,pending=False)
        s=self.active
        if pc==0xe498:
            if s is None:raise ValueError('Context store without owner')
            if s['pointer'] is not None:raise ValueError('Repeated context publication')
            s['pointer']=regs[10]
        if pc==0xe448:
            if s is None:
                self.leading_reads+=1
                return
            if s['pointer'] is None:raise ValueError('Comparator read before context initialization')
            s['pending']=True
        if pc==0xe44e and s is not None:
            if not s['pending'] or regs[8]!=s['pointer']:
                raise ValueError('Comparator did not use current context')
            s['reads']+=1;s['pending']=False
        if pc==0xe4fa:
            if s is None:return
            if s['pointer'] is None or s['pending']:
                raise ValueError('Incomplete context lifetime')
            self.calls.append(s);self.active=None


def check(root,chunk):
    meta=json.loads((chunk/'before.json').read_text())
    irq=json.loads((root/'capacity-costs.json').read_text())['irq_stack']
    audit=Audit();trace=barto.load(chunk/'trace.bin')
    for field in trace.fields:
        for pc,cycles,regs in trace.instructions(field):
            if pc in (None,0x7fffffff) or irq[0]<=regs[15]<irq[1]:continue
            audit.feed(pc-meta['sim'],regs)
    if not audit.calls or not sum(c['reads'] for c in audit.calls):
        raise ValueError('No complete sorting context with comparator reads observed')
    return dict(sha256=json.loads((root/'entry.json').read_text())['slave_sha256'],
                chunk=chunk.name,calls=audit.calls,leading_reads=audit.leading_reads,
                incomplete=audit.active is not None,
                limitation='Complete observed main-task calls only; no global state exclusion or unobserved-path proof.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('sim',type=Path);p.add_argument('capture',type=Path)
    p.add_argument('chunk');p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=dict(contract=original_contract(a.sim.read_bytes()),
                                observed=check(a.capture,a.capture/a.chunk))
    a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
