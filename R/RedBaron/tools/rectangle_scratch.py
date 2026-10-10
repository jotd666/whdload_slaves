"""Check observed sim-v1 rectangle scratch lifetimes in an instruction trace.

This classifies only complete calls actually present in the trace. It does not
exclude bytes from world comparisons or prove unobserved callers harmless.
"""
import argparse
import json
from pathlib import Path
import barto

SCRATCH = 0x7914
READS = {0x2526a,0x25274,0x2527a,0x25284,0x252b2,0x252c6,0x252dc,0x252f0}
DIRECT = [0x19808,0x1980a,0x1980c,0x1980e,0x19814,0x19816]
FORWARDED = [0x1a02a,0x1a030,0x1a032,0x19dd4,0x19dd6,0x19dd8,0x19ddc,0x19dde]


class Audit:
    def __init__(self, h3):
        self.h3=h3
        self.active=None
        self.calls=[]

    def feed(self, pc, regs):
        if pc==0x25244:
            if self.active is not None:raise ValueError('Nested or unconsumed rectangle result')
            self.active=dict(initialized=0,returned=False,path=None,index=0,sources=[],destinations=[])
        s=self.active
        if s is None:return
        scratch=self.h3+SCRATCH
        if not s['returned']:
            if pc in (0x2525c,0x2525e):
                index=(pc==0x2525e)
                if s['initialized']!=index or regs[9]!=scratch+4*index:
                    raise ValueError('Unexpected scratch initialization order or destination')
                if max(regs[8],scratch)<min(regs[8]+4,scratch+8):
                    raise ValueError('Input depends on prior scratch contents')
                s['sources'].append(regs[8]);s['initialized']+=1
            if pc in (0x25266,0x25268):
                if max(regs[8],scratch)<min(regs[8]+4,scratch+8):
                    raise ValueError('Second input aliases scratch')
                s['sources'].append(regs[8])
            if pc in READS and s['initialized']!=2:
                raise ValueError('Scratch read before complete initialization')
            if pc==0x25304:
                if s['initialized']!=2 or len(s['sources'])!=4 or regs[0]!=scratch:
                    raise ValueError('Incomplete helper or unexpected return pointer')
                s['returned']=True
            return
        if s['path'] is None:
            s['path']=DIRECT if pc==DIRECT[0] else FORWARDED if pc==FORWARDED[0] else None
            if s['path'] is None:raise ValueError('Unclassified rectangle caller')
        path=s['path'];index=s['index']
        if pc!=path[index]:raise ValueError('Unexpected execution before rectangle consumption')
        if pc in path[-2:]:
            part=pc==path[-1]
            if regs[8]!=scratch+4*part:raise ValueError('Caller did not copy returned scratch')
            if max(regs[9],scratch)<min(regs[9]+4,scratch+8):
                raise ValueError('Caller retained scratch as its destination')
            s['destinations'].append(regs[9])
        s['index']+=1
        if s['index']==len(path):
            if s['destinations'][1]!=s['destinations'][0]+4:
                raise ValueError('Caller did not copy a contiguous rectangle')
            self.calls.append(dict(caller='sim:19804' if path==DIRECT else 'sim:1a026',
                                   copy='sim:19814' if path==DIRECT else 'sim:19ddc',
                                   source_addresses=s['sources'],destination=s['destinations'][0]))
            self.active=None


def check(root, chunk):
    meta=json.loads((chunk/'before.json').read_text())
    irq=json.loads((root/'capacity-costs.json').read_text())['irq_stack']
    audit=Audit(meta['h3']);trace=barto.load(chunk/'trace.bin')
    for field in trace.fields:
        for pc,cycles,regs in trace.instructions(field):
            if pc in (None,0x7fffffff) or irq[0]<=regs[15]<irq[1]:continue
            audit.feed(pc-meta['sim'],regs)
    if not audit.calls:raise ValueError('No complete rectangle lifetimes observed')
    return dict(sha256=json.loads((root/'entry.json').read_text())['slave_sha256'],
                chunk=chunk.name,calls=audit.calls,incomplete=audit.active is not None,
                limitation='Observed complete calls only; no global exclusion or unobserved-path proof.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('capture',type=Path);p.add_argument('chunk');p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.capture,a.capture/a.chunk)
    a.out.write_text(json.dumps(result,indent=2)+'\n')
    print(f"{len(result['calls'])} complete rectangle lifetimes; incomplete={result['incomplete']}")
