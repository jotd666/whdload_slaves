#!/usr/bin/env python3
"""Correlate VERIFY first-fill observations with actual framebuffer DMA writes.

The first trace field's VBlank number must be supplied explicitly; no cropped or
shifted comparison is accepted implicitly. Publication timestamps precede the
pointer MOVEM, so gaps here are from the observer, not completion of publication.
"""
import argparse,json,struct,bisect
from pathlib import Path
import barto
import display_ownership
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('trace',type=Path)
p.add_argument('--paint',type=Path,required=True)
p.add_argument('--first-vbl',type=int,required=True)
p.add_argument('--sim',type=lambda v:int(v,0),required=True)
p.add_argument('--buffers',required=True)
p.add_argument('--out',type=Path,required=True)
a=p.parse_args()
buffers=[int(v,0) for v in a.buffers.split(':')]
ownership=display_ownership.analyse(a.trace,a.sim,buffers)
t=barto.load(a.trace)
paint=json.loads(a.paint.read_text())
base=a.first_vbl
writes={buf:[] for buf in buffers}
for f in t.fields:
 for slot in range(len(f.dma)//58):
  i=slot*58;kind=f.dma[i+29];reg=struct.unpack_from('<H',f.dma,i)[0]
  if (kind==5 and reg==0) or (kind==2 and reg==0x1102):
   addr=struct.unpack_from('<I',f.dma,i+12)[0]
   for buf,rows in writes.items():
    if buf<=addr<buf+40000:rows.append((f.index*313*227+slot,addr,kind))
rows=[]
for r in paint['records']:
 sf=r['swap_vbl']-base;df=r['draw_vbl']-base
 if not 0<=sf<len(t.fields):continue
 start=(sf*313+r['swap_line'])*227+(r['swap_beam']&255)
 w=writes[r['old_display']];at=bisect.bisect_right(w,(start,2**32,255))
 if at==len(w):raise RuntimeError('No write after swap')
 pos,addr,kind=w[at];f,rem=divmod(pos,313*227);line,hpos=divmod(rem,227)
 logged=(df*313+r['draw_line'])*227+(r['draw_beam']&255)
 rows.append(dict(step=r['step'],swap_field=sf,swap_line=r['swap_line'],draw_field=f,draw_line=line,draw_hpos=hpos,logged_draw_field=df,logged_draw_line=r['draw_line'],destination_matches=addr==r['destination'],first_write_minus_log_slots=pos-logged,gap_fields=(pos-start)/(313*227),shown_roles=ownership['shown'][f],old_role=ownership['buffers'].index(r['old_display']),kind=kind))
result=dict(field_vbl_base=base,records=rows,observable=ownership['observable'],writes=ownership['framebuffer_writes'],conflicts=len(ownership['active_display_conflicts']),conflicts_fetched_later=ownership['conflicts_fetched_later'],conflict_fields=sorted({r['field'] for r in ownership['active_display_conflicts']}))
result['all_correlated']=bool(rows) and all(r['destination_matches'] and 0<=r['first_write_minus_log_slots']<227 for r in rows)
result['scope']='First writes after observer publication timestamps, with the optional VERIFY first-fill diagnostic enabled; not an uninstrumented FPS measurement.'
a.out.write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='records'},indent=2))
raise SystemExit(not (result['observable'] and result['all_correlated']))
