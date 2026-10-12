"""Accounting controls: nested spans must not become extra frame time."""
import json,tempfile,unittest
from pathlib import Path
from render_profile_report import report, RATE, SLOTS
from routine_wall_time import summarize

def call(name,a,b,step=1):
 def row(line):return dict(step=step,vbl=1,beam=line*256+20,line=line,hpos=20,sp=100,stage=1)
 return dict(routine=name,entry=row(a),return_record=row(b))

def data(calls,group='draw'):
 raw=dict(complete=True,calls=calls,vblank_phase=[dict(vbl=n,line=0,beam=20) for n in (1,2)])
 return dict(machine='test',group=group,fields=2,fps=0,slave_sha256='test',raw=raw,timing=summarize(raw,0,100))

class Accounting(unittest.TestCase):
 def run_report(self,d):
  with tempfile.TemporaryDirectory() as tmp:
   p=Path(tmp)/'sample.json';p.write_text(json.dumps(d));return report(p)
 def test_nested_cost_is_union(self):
  r=self.run_report(data([call('scene_total',50,150),call('outer',60,100),call('inner',70,90)]))['parents']['scene_total']
  self.assertAlmostEqual(r['child_union_mean_ms_lower_bound']/r['parent_mean_ms'],.4)
 def test_six_brackets_account_for_same_frame(self):
  cs=[call(n,a,b) for n,a,b in [('world',20,25),('background',25,30),('scene',30,80),('cockpit',80,120),('messages',120,125),('publication',125,140)]]+[call('world',150,155,2)]
  r=self.run_report(data(cs,'stages'))['accounting'];self.assertEqual(r['matched_frames'],1)
  v=r['mean_ms'];self.assertAlmostEqual(sum(x for k,x in v.items() if k!='total'),v['total'])
  self.assertAlmostEqual(v['residual']/v['total'],10/130)
 def test_bad_return_stack_rejected(self):
  c=call('scene_total',50,150);c['return_record']['sp']+=4
  with self.assertRaises(ValueError):data([c])
 def test_field_gap_rejected(self):
  d=data([call('scene_total',50,150)]);d['raw']['vblank_phase'][1]['vbl']=3
  with self.assertRaises(ValueError):summarize(d['raw'],0,100)

if __name__=='__main__':unittest.main()
