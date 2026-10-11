"""Check original or W6 exponent calls against the register model; CCR is checked by native twins."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import barto
from exponent_encode import original,cases
from game_heap import exact
from hunks import read_hunks
from player_links import SIM_SHA
from presentation_state import symbol
from render_mutations import Snapshot


def check(sim_file,root,replacement):
    raw=sim_file.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original sim')
    code=read_hunks(raw)[0].data
    entry=json.loads((root/'entry.json').read_text());manifest=json.loads((root/'capacity.json').read_text())
    digest=hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest()
    if {entry['slave_sha256'],manifest['sha256']}!={digest}:raise ValueError('Frozen build mismatch')
    lines=(root/'slave.lst').read_text(encoding='latin-1').splitlines()
    base=entry['entry']['game_anchor']-symbol(lines,'tape_game_anchor');sim=entry['entry']['sim']
    at=lambda name:base+symbol(lines,name)
    start=at('time_exp_fast') if replacement else sim+0x2c31c
    if replacement:
        offset=start-base
        ends=[int(m[1],16) for line in lines if (m:=re.match(r'00:([0-9A-F]+)\s+4E75\s',line)) and int(m[1],16)>=offset]
        end=base+min(ends)
    else:end=sim+0x2c33a
    calls=[];incomplete=[];twins=[]
    for chunk in manifest['chunks']:
        directory=root/chunk['path']
        banks=[dict(file=p.name,base=int(p.stem.split('-')[1],16),size=p.stat().st_size) for p in directory.glob('memory-*.bin')]
        ram=Snapshot(directory,banks)
        expected=bytes.fromhex('4ef9')+start.to_bytes(4,'big') if replacement else code[0x2c31c:0x2c322]
        if exact(ram.read,sim+0x2c31c,6)!=expected:raise ValueError('Wrong live exponent selection')
        if exact(ram.read,sim+0x2c322,26)!=code[0x2c322:0x2c33c]:raise ValueError('Changed original helper tail')
        if replacement:
            if exact(ram.read,at('time_exp_original'),32)!=code[0x2c31c:0x2c33c]:raise ValueError('Twin original differs')
            count=int.from_bytes(exact(ram.read,at('time_exp_result'),4),'big')
            if count!=len(cases())*32:raise ValueError('Incomplete native exponent twins')
            twins.append(count)
        trace=barto.load(directory/'trace.bin');active=None
        for field in trace.fields:
            for pc,cycles,regs in trace.instructions(field):
                if pc==start:
                    if active is not None:raise ValueError('Nested exponent call')
                    active=(regs,field.index)
                if pc==end and active is not None:
                    before,first=active;value,d1,d2,ccr=original(before[0],before[2],before[16]&31)
                    expected=list(before);expected[:3]=value,d1,d2
                    # Barto's retained SR remains stale through flag-changing
                    # instructions in the original trace. Do not use it as CCR
                    # evidence; the private native twins explicitly MOVE CCR/SR.
                    if tuple(expected[:16])!=tuple(regs[:16]):
                        raise ValueError('Native integer-register mismatch')
                    calls.append(dict(chunk=chunk['path'],first_field=first,last_field=field.index,input=before[0],d2=before[2],trace_sr_before=before[16],trace_sr_after=regs[16],output=value))
                    active=None
        if active is not None:incomplete.append(dict(chunk=chunk['path'],first_field=active[1]))
    if not calls:raise ValueError('No complete exponent calls')
    return dict(sha256=digest,replacement=replacement,native_twin_counts=twins,calls=calls,incomplete=incomplete,
                scope='Complete native D0-D7/A0-A7 outputs against sim-v1 model. Trace SR is retained but not CCR evidence; replacement CCR comes from explicit native twins. Incomplete joins retained. Not whole-gameplay or performance acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('original',type=Path);p.add_argument('capture',type=Path)
    p.add_argument('--replacement',action='store_true');p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    r=check(a.original,a.capture,a.replacement);a.out.write_text(json.dumps(r,indent=2)+'\n')
    print(len(r['calls']),'complete native calls match all integer registers')
