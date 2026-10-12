#!/usr/bin/env python3
"""Report accepted call times and parent-contained costs without double counting.

Child sums exclude ambiguous beam endpoints and are explicitly lower bounds.
Different probe groups are adjacent windows, never one additive frame budget.
"""
import argparse,collections,json,re,statistics
from pathlib import Path
from routine_wall_time import summarize
RATE=49.92041
SLOTS=313*227

def tick(r):return r['vbl']*SLOTS+r['line']*227+r['hpos']
def report(path):
 d=json.loads(path.read_text());raw=d['raw'];threshold=d['timing']['phase_safe_from_line'];known={p['vbl'] for p in raw['vblank_phase']}
 def valid(c):
  a,b=c['entry'],c['return_record']
  return all(x['vbl'] in known and x['line']>=threshold and x['hpos']>1 for x in (a,b)) and tick(b)>=tick(a)
 good=[c for c in raw['calls'] if valid(c)]
 result={k:d[k] for k in ('machine','group','fields','fps','slave_sha256')}
 result['calls']={name:dict(**v,total_ms=sum(c['fields'] for c in d['timing']['accepted'] if c['routine']==name)*1000/RATE) for name,v in d['timing']['summaries'].items()}
 result['excluded_calls']=len(d['timing']['excluded']);result['below_resolution_calls']=len(d.get('below_beam_resolution',[]));result['parents']={}
 for pname in ('scene_total','cockpit_total'):
  parents=[c for c in good if c['routine']==pname]
  if not parents:continue
  children=[c for c in good if c['routine'] not in ('scene_total','cockpit_total')]
  sums=collections.defaultdict(float);counts=collections.Counter();union=0
  for parent in parents:
   lo,hi=tick(parent['entry']),tick(parent['return_record']);intervals=[]
   for c in children:
    a,b=tick(c['entry']),tick(c['return_record'])
    if lo<=a<=b<=hi:
     sums[c['routine']]+=b-a;counts[c['routine']]+=1;intervals.append((a,b))
   end=lo
   for a,b in sorted(intervals):
    union+=max(0,b-max(a,end));end=max(end,b)
  parent_slots=sum(tick(c['return_record'])-tick(c['entry']) for c in parents)
  result['parents'][pname]=dict(frames=len(parents),parent_mean_ms=parent_slots/len(parents)/SLOTS*1000/RATE,child_union_mean_ms_lower_bound=union/len(parents)/SLOTS*1000/RATE,children={n:dict(calls=counts[n],calls_per_frame=counts[n]/len(parents),mean_ms_per_parent_lower_bound=v/len(parents)/SLOTS*1000/RATE) for n,v in sums.items()})
 if d['group']=='programs':
  text=path.with_suffix('.log').read_text();program_ids={};pending=None
  for line in text.splitlines():
   m=re.match(r'CLOCK program enter (\d+) (\d+) (\d+) (\d+) (\d+)$',line)
   if m:pending=tuple(map(int,m.groups()[:4]))
   m=re.match(r'PROGRAM (\d+) (\d+) (\d+)$',line)
   if m:
    if pending is None or pending[0]!=int(m[1]):raise ValueError('Program ID has no matching entry')
    program_ids[pending]=int(m[3]);pending=None
  def key(c):
   e=c['entry'];return e['step'],e['vbl'],e['beam'],e['sp']
  calls=[c for c in raw['calls'] if c['routine']=='program']
  if any(key(c) not in program_ids for c in calls):raise ValueError('Missing program ID')
  result['programs']={}
  for n in sorted(set(program_ids.values())):
   selected=[c for c in calls if program_ids[key(c)]==n and valid(c)]
   result['programs'][n]=dict(entries=list(program_ids.values()).count(n),accepted=len(selected),mean_ms=statistics.mean(tick(c['return_record'])-tick(c['entry']) for c in selected)/SLOTS*1000/RATE if selected else None)
 if d['group']=='stages':
  worlds=sorted([c['entry'] for c in raw['calls'] if c['routine']=='world'],key=tick);rows=[]
  for a,b in zip(worlds,worlds[1:]):
   cs=[c for c in raw['calls'] if c['entry']['step']==a['step']]
   if b['step']!=a['step']+1 or len(cs)!=6 or not valid(dict(entry=a,return_record=b)) or not all(valid(c) for c in cs):continue
   total=tick(b)-tick(a);parts={c['routine']:tick(c['return_record'])-tick(c['entry']) for c in cs}
   if not all(tick(a)<=tick(c['entry'])<=tick(c['return_record'])<=tick(b) for c in cs):continue
   parts['residual']=total-sum(parts.values());assert parts['residual']>=0
   parts['total']=total;rows.append(parts)
  result['accounting']=dict(matched_frames=len(rows),mean_ms={k:statistics.mean(x[k] for x in rows)/SLOTS*1000/RATE for k in rows[0]} if rows else {},scope='World entry to next world entry; same six accepted brackets, non-overlapping; residual includes input and unbracketed code.')
 if d['group']=='blits':
  text=path.with_suffix('.log').read_text();rows=re.findall(r'^BLIT (\w+) (\d+) (\d+) (\d+) (\d+)$',text,re.M)
  frame_ids=[int(x) for x in re.findall(r'^FRAME (\d+)',text,re.M)];full=set(frame_ids[:-1]);totals={}
  for off,step,stage,size,con in rows:
   if int(step) not in full:continue
   w=int(size)&63 or 64;h=int(size)>>6 or 1024
   key=f'{stage}:{off}';rec=totals.setdefault(key,dict(launches=0,plane_bytes=0,sizes=collections.Counter()))
   rec['launches']+=1;rec['plane_bytes']+=2*w*h;rec['sizes'][f'{w}x{h}']+=1
  result['blits']=dict(complete_frames=len(full),sites=totals)
 return result

if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('captures',nargs='+',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
 data=[report(f) for root in a.captures for f in sorted(root.glob('*.json')) if f.stem in ('stages','cockpit','draw','bitmap','lines','programs','wait_overlay','wait_rectangle','wait_polygon','blits','cpu_backend')]
 a.out.write_text(json.dumps(data,indent=2)+'\n')
 for d in data:print(d['machine'],d['group'],d['parents'])
