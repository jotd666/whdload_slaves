"""Check native angle-table quantization in observed world updates.

Models supported matrix values, not full aircraft dynamics or a replacement.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path
import barto
from hunks import read_hunks
from player_kinematics import word


def pitch(value,table):
    value=word(value)
    if abs(value)>16384:raise ValueError('Matrix component outside supported unit range')
    angle=table[abs(value)>>5]
    return word((4096-angle if value<0 else angle)<<4)


def atan(x,y,table):
    x,y=word(x),word(y)
    if min(x,y)==-32768:raise ValueError('Signed minimum requires separate native handling')
    a,b=abs(x),abs(y)
    if not a and not b:return 0
    if not a:q=1024
    elif not b:q=0
    elif a==b:q=512
    elif b>a:q=1024-table[(a*512)//b]
    else:q=table[(b*512)//a]
    if x<0:q=2048-q
    if y<0:q=4096-q
    return word(q<<4)


def tables(raw):
    code=read_hunks(raw)[0].data
    for at,expected in ((0x368aa,'ea48d040'),(0x368c4,'e948'),(0x38aa2,'e948')):
        b=bytes.fromhex(expected)
        if code[at:at+len(b)]!=b:raise ValueError('Changed angle quantization instructions')
    return struct.unpack_from('>513H',code,0x37d5a),struct.unpack_from('>512H',code,0x3855e)


def check(sim_file,root,chunk):
    raw=sim_file.read_bytes()
    entry=json.loads((root/'entry.json').read_text())
    if hashlib.sha256(raw).hexdigest()!=entry['sim_sha256']:
        raise ValueError('Angle tables do not match captured sim executable')
    pt,at=tables(raw)
    meta=json.loads((chunk/'before.json').read_text());sim=meta['sim']
    irq=json.loads((root/'capacity-costs.json').read_text())['irq_stack']
    trace=barto.load(chunk/'trace.bin')
    active=False;pvalue=None;avalue=None;counts=dict(pitch=0,atan=0)
    values=dict(pitch=[],atan=[])
    for field in trace.fields:
        for pc,cycles,regs in trace.instructions(field):
            if pc in (None,0x7fffffff) or irq[0]<=regs[15]<irq[1]:continue
            pc-=sim
            if pc==0x1098:active=True
            if pc==0x11c8:active=False
            if not active:continue
            if pc==0x368a2:pvalue=word(regs[0])
            if pc==0x368c6 and pvalue is not None:
                predicted=pitch(pvalue,pt);actual=word(regs[0])
                if predicted!=actual:raise ValueError('Native pitch table result mismatch')
                counts['pitch']+=1;values['pitch'].append([pvalue,actual]);pvalue=None
            if pc==0x38a12:avalue=[]
            if pc==0x38a1e and avalue is not None:avalue.append(word(regs[0]))
            if pc==0x38a2a and avalue is not None:avalue.append(word(regs[1]))
            if pc==0x38aa4 and avalue is not None:
                if len(avalue)!=2:raise ValueError('Incomplete native atan arguments')
                predicted=atan(*avalue,at);actual=word(regs[0])
                if predicted!=actual:raise ValueError('Native atan table result mismatch')
                counts['atan']+=1;values['atan'].append(avalue+[actual]);avalue=None
    if not all(counts.values()):raise ValueError('Missing observed world angle conversions')
    return dict(sha256=json.loads((root/'entry.json').read_text())['slave_sha256'],
                chunk=chunk.name,counts=counts,values=values,
                limitation='Observed world angle conversions only; does not attribute the full trajectory difference or accept aircraft physics.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('sim',type=Path);p.add_argument('capture',type=Path)
    p.add_argument('chunk');p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.sim,a.capture,a.capture/a.chunk)
    a.out.write_text(json.dumps(result,indent=2)+'\n');print(result['counts'])
