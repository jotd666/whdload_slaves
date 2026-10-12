#!/usr/bin/env python3
"""External, bounded normal-build renderer brackets; run from the local harness.

No guest patches. Stops at native VBlank; all times include IRQs and bus waits.
The existing PAL counter-phase filter rejects ambiguous beam endpoints.
"""
import argparse,json,re,sys
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/'tools'))
import route_status as r
from routine_wall_time import summarize

GROUPS={
 'stages': [('background',0x5fe,[0x6bc]),('scene',0x6bc,[0x7c4]),
            ('cockpit',0x7c4,[0x830]),('messages',0x830,[0xafe]),
            ('publication',0xafe,[0xb10]),('world',0x1098,[0x11c8])],
 'cockpit':[('top',0x7c4,[0x80e]),('overlay',0x80e,[0x81a]),
            ('dashboard_dispatch',0x81e,[0x822]),('instruments',0x82a,[0x82e]),
            ('picture_script',0x19ba6,[0x19e12])],
 'draw':[('polygon',0x2f292,[0x2f268,0x2f27c,0x2f290,0x2f552]),
         ('rectangle',0x2fc68,[0x2fca4,0x2fdfe])],
 'wait_overlay':[('overlay_entry_wait',0x2c172,[0x2c180]),('overlay_plane_wait',0x2c1c2,[0x2c1d0]),('overlay_clip_entry_wait',0x2c234,[0x2c242]),('overlay_clip_plane_wait',0x2c26a,[0x2c278])],
 'wait_rectangle':[('rectangle_plane_wait',0x2fd74,[0x2fd82])],
 'wait_polygon':[('polygon_fill_wait',0x2f3f0,[0x2f3fe]),('polygon_edges_wait',0x2f496,[0x2f4a4]),('polygon_merge_wait',0x2f4e8,[0x2f4f6])],
 'programs':[('program',0x28962,[0x28d58]),('gauge_restore',0x19d8c,[0x19d90]),('gauge_bitmap',0x19d98,[0x19d9c]),('gauge_callback',0x19dd2,[0x19dd4])],
 'lines':[('line',0x2ea28,[0x2ec9c,0x2ecac,0x2ed56,0x2ee04,0x2ee5e,0x2ee62,0x2eebe,0x2eff8])],
 'blits':[],
 'bitmap':[('bitmap',0x30572,[0x305ce,0x307cc]),
           ('overlay_body',0x2c144,[0x2c1fc,0x2c2b0])],
}

def capture(out,group,fields,reparse=False):
 m=json.loads((out/'entry.json').read_text());sim=m['sim'];stem=out/group
 if stem.with_suffix('.json').exists():raise ValueError('Refuse overwrite')
 if reparse:
  raw=stem.with_suffix('.log').read_text()
 else:
  r.command('stop')
  r.command(f'gdb delete\nbreak *{sim+0x2d34e:#x}\ncontinue\ndelete')
  points={}
  for name,lo,rets in GROUPS[group]:
   for kind,off in [('enter',lo)]+[('return',x) for x in rets]:points.setdefault(off,[]).append((name,kind))
  # Phase transitions establish ownership even for shared primitives.
  for off in ((0x6bc,0x7c4,0x830,0x21d30) if group=='lines' else (0x6bc,0x7c4,0x830,0xafe,0x21d30)):points.setdefault(off,[])
  if group!='stages':
   for name,lo,hi in [('scene_total',0x6bc,0x7c4),('cockpit_total',0x7c4,0x830)]:
    points[lo].append((name,'enter'));points[hi].append((name,'return'))
  if group=='blits':
   for off in (0x2fd8e,0x2f41a,0x2f506,0x2c1e0,0x2c28c):points[off]=[]
  assert len(points)+3<=16,(group,len(points)+3)
  cmd=['delete','set $rfield=0','set $rstep=0','set $rstage=0']
  for off,tags in points.items():
   cmd += [f'break *{sim+off:#x}','commands','silent']
   for name,kind in tags:
    cmd += [f'printf "CLOCK {name} {kind} %u %u %u %u %u\\n", $rstep, $rfield, *(unsigned int*)0xdff004, $sp, $rstage']
   if group=='programs' and off==0x28962:cmd += ['printf "PROGRAM %u %u %u\\n", $rstep, $rstage, *(unsigned short*)($sp+4)']
   if off==0x21d30:cmd+=['set $rstep=$rstep+1','set $rstage=0','printf "FRAME %u %u %u\\n", $rstep, $rfield, *(unsigned int*)0xdff004']
   if group=='blits' and off in (0x2fd8e,0x2f41a,0x2f506,0x2c1e0,0x2c28c):
    size={0x2fd8e:'$d3',0x2f41a:'$d2',0x2f506:'$d2',0x2c1e0:'$d1',0x2c28c:'$d1'}[off]
    cmd += [f'printf "BLIT {off:x} %u %u %u %u\\n", $rstep, $rstage, ({size}&65535), ($d4&65535)']
   if off in (0x6bc,0x7c4,0x830):cmd += [f'set $rstage={ {0x6bc:1,0x7c4:2,0x830:3}[off]}']
   cmd+=['continue','end']
  cmd += [f'break *{sim+0x3154a:#x}','commands','silent','printf "PUB %u %u\\n", $rfield, *(unsigned int*)0xdff004','continue','end',f'break *{sim+0x21f4a:#x}','commands','silent','printf "FLIGHT_EXIT\\n"','end',f'break *{sim+0x2d34e:#x}','commands','silent','set $rfield=$rfield+1','printf "FIELD %u %u\\n", $rfield, *(unsigned int*)0xdff004',f'if $rfield < {fields}','continue','end','end','continue','delete']
  raw=r.command('gdb '+'\n'.join(cmd));stem.with_suffix('.log').write_text(raw)
  if 'FLIGHT_EXIT' in raw:raise RuntimeError('Flight exited')
 phase=[dict(vbl=int(v),beam=int(b),line=(int(b)>>8)&511) for v,b in re.findall(r'^FIELD (\d+) (\d+)$',raw,re.M)]
 assert len(phase)==fields and phase[-1]['vbl']==fields
 active={};calls=[];unmatched=[]
 for name,kind,step,field,beam,sp,stage in re.findall(r'^CLOCK (\w+) (\w+) (\d+) (\d+) (\d+) (\d+) (\d+)$',raw,re.M):
  row=dict(step=int(step),vbl=int(field),beam=int(beam),sp=int(sp),stage=int(stage),line=(int(beam)>>8)&511,hpos=int(beam)&255)
  if kind=='enter':active.setdefault(name,[]).append(row)
  elif active.get(name):
   first=active[name].pop();assert first['sp']==row['sp'],(name,first,row)
   calls.append(dict(routine=name,entry=first,return_record=row))
  else:unmatched.append(dict(routine=name,record=row))
 zero=[c for c in calls if (c['entry']['vbl'],c['entry']['beam'])==(c['return_record']['vbl'],c['return_record']['beam'])]
 log=dict(complete=True,vblank_phase=phase,calls=[c for c in calls if c not in zero])
 summary=summarize(log,0,1000000)
 pubs=re.findall(r'^PUB (\d+) (\d+)$',raw,re.M)
 result=dict(**m,group=group,fields=fields,fps=len(pubs)*49.92041/fields,publications=len(pubs),timing=summary,raw=log,open_calls=active,unmatched_returns=unmatched,below_beam_resolution=zero)
 stem.with_suffix('.json').write_text(json.dumps(result,indent=2)+'\n')
 print(group,result['fps'],summary['summaries'],flush=True)

if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('out',type=Path);p.add_argument('--group',choices=GROUPS,required=True);p.add_argument('--fields',type=int,default=250);p.add_argument('--reparse',action='store_true');a=p.parse_args()
 if not 10<=a.fields<=2000:p.error('Bounded window required')
 capture(a.out,a.group,a.fields,a.reparse)
