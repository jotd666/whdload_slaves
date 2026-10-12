#!/usr/bin/env python3
"""Attribute an aprof_flight.py profile: frame stages, routines, chip-bus units, blitter polls.

Per-PC records give exact emulated units and the share spent in Chip-bus accesses. Stage
totals use the call tree: inclusive units of each callee of the render function sim:0056c
(and the world step sim:01098), plus interrupt (exception) subtrees.
Usage (from tmp/dev): python3 ../../R/RedBaron/tools/aprof_flight_report.py CAPTURE [--top N] [--slave-base ADDR]
"""
import argparse,bisect,collections,json,re,struct
from pathlib import Path

def main():
    p=argparse.ArgumentParser();p.add_argument('cap',type=Path);p.add_argument('--top',type=int,default=30);p.add_argument('--slave-base',type=lambda x:int(x,0));a=p.parse_args()
    meta=json.loads((a.cap/'entry.json').read_text());sim=meta['sim']
    banks=[(lo,(a.cap/f'ram-{lo:x}.bin').read_bytes()) for lo,hi in meta['regions'] if (a.cap/f'ram-{lo:x}.bin').exists()]
    def read(x,n):
        for lo,b in banks:
            if lo<=x and x+n<=lo+len(b):return b[x-lo:x-lo+n]
        return b''
    word=lambda x:struct.unpack('>H',read(x,2))[0] if len(read(x,2))==2 else None
    simlen=0x3e384
    slave_file=(a.cap/'slave.slave').read_bytes()
    import sys;sys.path.insert(0,str(Path.cwd()/'tools'))
    from redbaron_report import hunks
    off,n=hunks(slave_file)[0];slave=slave_file[off:off+n];sbase=None
    for probe in (0x2000,0x4000,0x8000):
        chunk=slave[probe:probe+64]
        for lo,b in banks:
            i=b.find(chunk)
            if i>=0:sbase=lo+i-probe;break  # first (live) copy; a later one is the PRELOAD file
        if sbase:break
    if a.slave_base:sbase=a.slave_base
    lst=(a.cap/'slave.lst').read_bytes().decode('latin1');syms=[]
    if 'Symbols by value:' in lst:
        for m in re.finditer(r'^([0-9A-F]{8}) ([A-Za-z_][\w.]*)$',lst.split('Symbols by value:',1)[1],re.M):
            v=int(m.group(1),16)
            if v<len(slave) and not m.group(2).startswith('_'):syms.append((v,m.group(2)))
    syms.sort();symv=[v for v,_ in syms]
    hdr,pcs,nodes={},{},{}
    for line in (a.cap/'flight.prof').read_text().splitlines()[1:]:
        f=line.split()
        if f[0]=='P':pcs[int(f[1],16)]=(int(f[2]),int(f[3]),int(f[4]),int(f[5]))
        elif f[0]=='N':nodes[int(f[1])]=(int(f[2]),int(f[3],16),int(f[4]),int(f[5]),int(f[6]))
        elif len(f)==2:hdr[f[0]]=f[1]
    units=int(hdr['units']);fields=int(hdr['vsyncs']);uf=units/fields
    ms=lambda u:u/uf*20.0
    starts={x for x in range(sim,sim+simlen,2) if word(x)==0x4e55}
    long=lambda x:struct.unpack('>I',read(x,4))[0] if len(read(x,4))==4 else None
    def stub(t):
        return long(t+2) if word(t)==0x4ef9 else t
    nodes={n:(par,stub(t) if k==0 else t,k,s,c) for n,(par,t,k,s,c) in nodes.items()}
    starts|={t for (_,t,k,_,_) in nodes.values() if k==0 and sim<=t<sim+simlen}
    order=sorted(starts)
    def fn(pc):
        if sim<=pc<sim+simlen:
            i=bisect.bisect_right(order,pc)-1;return f'sim:{order[i]-sim:05x}' if i>=0 else f'sim:{pc-sim:05x}'
        if sbase and sbase<=pc<sbase+len(slave):
            i=bisect.bisect_right(symv,pc-sbase)-1;return 'slave:'+(syms[i][1] if i>=0 else hex(pc-sbase))
        if pc>=0xf80000:return 'rom'
        return f'other:{pc:x}'
    def ispoll(pc):
        b=read(pc,8)
        if len(b)<4:return False
        w0,w1=struct.unpack('>HH',b[:4])
        if (w0&0xfff8)==0x0828 and w1 in (6,14) and b[4:6]==b'\x00\x02':return True  # btst #n,2(An)
        if w0==0x0839 and w1 in (6,14) and b[4:8]==b'\x00\xdf\xf0\x02':return True
        if w0 in (0x4a39,0x4a79) and b[2:6]==b'\x00\xdf\xf0\x02':return True
        return False
    polls=set()
    for pc in pcs:
        if ispoll(pc):
            polls.add(pc)
            for d in (4,6,8):
                w=word(pc+d)
                if w is not None and (w&0xff00) in (0x6600,0x6700):polls.add(pc+d)
    # Exclusive by routine.
    ex=collections.Counter();exchip=collections.Counter();expoll=collections.Counter();excalls=collections.Counter()
    for pc,(u,n,cu,ca) in pcs.items():
        k=fn(pc);ex[k]+=u;exchip[k]+=cu
        if pc in polls:expoll[k]+=u
    totchip=int(hdr['chip_units'])
    # Call tree inclusive.
    kids=collections.defaultdict(list)
    for n,(par,t,k,s,c) in nodes.items():
        if n:kids[par].append(n)
    incl={}
    def inc(n):
        st=[(n,0)];out=[]
        while st:
            x,state=st.pop()
            if state==0:st.append((x,1));st.extend((c,0) for c in kids[x])
            else:incl[x]=nodes[x][3]+sum(incl[c] for c in kids[x])
    inc(0)
    def label(t,k):return fn(t) if k==0 else f'exception {k}'
    agg=collections.Counter();aggcalls=collections.Counter();aggpar=collections.defaultdict(collections.Counter)
    for n,(par,t,k,s,c) in nodes.items():
        if not n:continue
        # Count each routine once per path: skip if an ancestor has the same label.
        x=par;dup=False;lab=label(t,k)
        while x:
            if label(nodes[x][1],nodes[x][2])==lab:dup=True;break
            x=nodes[x][0]
        if not dup:agg[lab]+=incl[n];aggcalls[lab]+=c
        aggpar[label(nodes[par][1],nodes[par][2]) if par else '[top]'][lab]+=incl[n]
    frames=aggcalls.get('sim:0056c',0) or 1
    print('slave base',hex(sbase) if sbase else None)
    print(f'# {a.cap}: {fields} fields, {units} units, cacr {hdr["cacr"]}; render calls {aggcalls.get("sim:0056c")}, '
          f'world calls {aggcalls.get("sim:01098")}; {50*frames/fields:.2f} FPS')
    print(f'Chip-bus units {100*totchip/units:.1f}% of all; chip accesses {int(hdr["chip_accesses"])/fields:.0f}/field; '
          f'recognised blitter polls {100*sum(expoll.values())/units:.1f}%')
    def perframe(u):return ms(u)/frames
    print('\n## Render-function callees (inclusive ms/frame)')
    for k,v in aggpar['sim:0056c'].most_common(25):
        print(f"{perframe(v):8.2f}  {k}")
    print('\n## Top-level / interrupts (inclusive ms per frame)')
    for k,v in aggpar['[top]'].most_common(12):print(f'{perframe(v):8.2f}  {k}')
    print('\n## Inclusive routines (ms/frame, calls/frame)')
    for k,v in agg.most_common(a.top):print(f'{perframe(v):8.2f} {aggcalls[k]/frames:7.1f}  {k}')
    print('\n## Exclusive routines (ms/frame; % of that in Chip-bus access; blitter-poll ms)')
    for k,v in ex.most_common(a.top):
        print(f'{perframe(v):8.2f} {100*exchip[k]/v if v else 0:5.0f}% {perframe(expoll[k]):6.2f}  {k}')

if __name__=='__main__':main()
