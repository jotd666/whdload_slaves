"""Check every matrix output store in complete native calls against the integer model."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import barto
from hunks import read_hunks
from orientation_matrix import matrix
from player_links import SIM_SHA
from render_mutations import Snapshot

START,END,TABLE=0x3648c,0x3688c,0x36d58
# PC before MOVE.W Dn,offset(A3): output byte offset, source data register.
STORES={0x36632:(0,1),0x36640:(2,0),0x3669e:(4,0),0x366fc:(6,0),
        0x36750:(8,0),0x36754:(10,6),0x36762:(12,0),0x36772:(14,1),0x367c6:(16,0),
        0x367fc:(0,0),0x36800:(8,0),0x36828:(2,0),0x3682e:(6,0),
        0x36834:(4,0),0x36838:(10,0),0x3683c:(12,0),0x36840:(14,0),0x36848:(16,0),
        0x3685a:(0,0),0x3685e:(8,0),0x36862:(16,0),0x36868:(2,0),0x3686c:(4,0),
        0x36870:(6,0),0x36874:(10,0),0x36878:(12,0),0x3687c:(14,0)}
FLAGS={0x367cc,0x3684e,0x36882}


def check(original,root):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported SIM')
    h=read_hunks(raw)[0];code=h.data
    table=struct.unpack_from('>2049h',code,TABLE)
    meta=json.loads((root/'entry.json').read_text());manifest=json.loads((root/'capacity.json').read_text())
    digest=hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest()
    if {meta['slave_sha256'],manifest['sha256']}!={digest}:raise ValueError('Build mismatch')
    sim=meta['entry']['sim'];expected=bytearray(code[START:END+2])
    for off,target in h.relocations:
        if START<=off<END+2:
            if target!=0:raise ValueError('Unexpected constructor relocation owner')
            value=int.from_bytes(code[off:off+4],'big')+sim
            expected[off-START:off-START+4]=value.to_bytes(4,'big')
    rows=[];cut=[]
    for chunk in manifest['chunks']:
        d=root/chunk['path'];banks=[dict(file=p.name,base=int(p.stem.split('-')[1],16),size=p.stat().st_size) for p in d.glob('memory-*.bin')]
        ram=Snapshot(d,banks)
        if ram.read(sim+START,len(expected))!=expected:raise ValueError('Changed native constructor')
        if ram.read(sim+TABLE,4098)!=code[TABLE:TABLE+4098]:raise ValueError('Changed native trig table')
        t=barto.load(d/'trace.bin');active=None
        for field in t.fields:
            for pc,cycles,r in t.instructions(field):
                off=pc-sim if pc is not None else -1
                if off==START:
                    if active is not None:raise ValueError('Nested constructor')
                    active=dict(sp=r[15],angles={},out={},first_field=field.index)
                if active is None:continue
                if off==0x3649c:
                    src,dst=r[10],r[11]
                    if max(src,dst)<min(src+6,dst+19):raise ValueError('Aliased input/output needs sequential model')
                    active['destination']=dst
                if off in (0x364ac,0x364d2,0x36524):
                    active['angles'][{0x364ac:0,0x364d2:1,0x36524:2}[off]]=r[0]&65535
                if off==0x367d4:active['angles'].update({0:0,1:0})
                if off==0x367e0:active['angles'][2]=r[0]&65535
                if off==0x36856:active['angles'][2]=0
                if off in STORES:
                    at,reg=STORES[off]
                    if r[11]!=active.get('destination'):raise ValueError('Changed destination owner')
                    if at in active['out']:raise ValueError('Repeated output store')
                    value=r[reg]&65535
                    active['out'][at]=value>>8;active['out'][at+1]=value&255
                if off in FLAGS:active['out'][18]=r[0]&255
                if off==END:
                    if r[15]!=active['sp'] or set(active['angles'])!={0,1,2} or set(active['out'])!=set(range(19)):
                        raise ValueError('Incomplete call state')
                    angles=[active['angles'][i] for i in range(3)]
                    native=bytes(active['out'][i] for i in range(19))
                    modeled,reads=matrix(table,angles);candidate,reused=matrix(table,angles,True)
                    if native!=modeled or native!=candidate:raise ValueError(f'Matrix output mismatch for {angles}: {native.hex()} versus {modeled.hex()}')
                    rows.append(dict(chunk=chunk['path'],angles=angles,output=native.hex(),lookup_reads=reads,reused_lookup_reads=reused))
                    active=None
        if active is not None:cut.append(chunk['path'])
    if not rows:raise ValueError('No complete native calls')
    return dict(sha256=digest,calls=len(rows),flags=sorted({bytes.fromhex(r['output'])[-1] for r in rows}),
                native_lookup_reads=sum(r['lookup_reads'] for r in rows),reused_lookup_reads=sum(r['reused_lookup_reads'] for r in rows),
                rows=rows,cut_chunks=cut,scope='All 19 native output-store bytes in complete nonaliasing calls match the integer model and repeated-expression candidate. No CCR, aliasing, assembly candidate or speed claim.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('original',type=Path);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    r=check(a.original,a.capture);a.out.write_text(json.dumps(r,indent=2)+'\n');print({k:v for k,v in r.items() if k!='rows'})
