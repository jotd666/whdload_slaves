"""Choose native End Mission after a controlled ground outcome; verify the return."""
import argparse,json,sys
from d5_live import Live,r
from d5_report import ground_outcome
p=argparse.ArgumentParser();p.add_argument('out');p.add_argument('--attach',action='store_true');a=p.parse_args();l=Live(a.out)
if a.attach:l.attach_input()
ground=json.loads((l.out/'ground.json').read_text());scenario=json.loads((l.out/'entry.json').read_text())['scenario']
if scenario=='crash' and ground['stop']=='flight_exit':
    ground_outcome(ground,scenario,None,None,None)
    r.command('wait 12')
    print(r.command('shot '+str((l.out/'debrief.png').resolve())))
    (l.out/'outcome.json').write_text(json.dumps(dict(passed=True,scenario=scenario,automatic_exit=True,state=ground['state'],scope='W6-owned destructive native impact and automatic common flight exit; no menu command or result injection'),indent=2)+'\n')
    print('GROUND OUTCOME PASS automatic crash',flush=True)
    sys.exit(0)
assert ground['stop']=='menu'
assert all(c[1]>=4 for c in ground['contacts']),'Contact preceded W6 activation'
if scenario=='landing':assert all(c[-1]==0 for c in ground['contacts']) and ground['altitude']==50
elif scenario=='crash':assert any(c[-1]>0 for c in ground['contacts'])
else:raise ValueError(scenario)
before=l.snapshot()
for key in (0x42,):
    l.irq(key);l.fields(2);l.irq(key,True);l.fields(2)
l.irq(0x44);l.fields(2);l.irq(0x44,True)
l.until(l.sym('time_loop_exit'))
result=l.value('$d0');assert result==1,('Expected native completed-mission return, not abort',result)
after=l.snapshot();ground_outcome(ground,scenario,result,before,after)
(l.out/'outcome.json').write_text(json.dumps(dict(passed=True,scenario=scenario,native_return=result,before=before,after=after,scope='Controlled native ground contact, automatic mission-over menu and completed-mission return; not a manual approach/handling verdict'),indent=2)+'\n')
# sim is unloaded after the return. Allow disk/menu loading without trapping
# its old VBL address; the objective verdict above is the native return.
r.command('wait 12')
print(r.command('shot '+str((l.out/'debrief.png').resolve())))
print('GROUND OUTCOME PASS',scenario,flush=True)
