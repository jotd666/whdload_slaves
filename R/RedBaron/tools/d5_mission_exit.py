"""Abort through the native menu while flight has unconsumed CIA backlog."""
import argparse,json,subprocess,sys
from pathlib import Path
from d5_live import Live,r
from d5_report import mission_exit
p=argparse.ArgumentParser();p.add_argument('out');p.add_argument('--resume-menu',action='store_true');a=p.parse_args();l=Live(a.out)
if not a.resume_menu:
    l.until(l.sim+0x2c552)
    l.irq(0x10);l.fields(2);l.irq(0x10,True)
    l.until(l.sim+0x1f0d2)
before=l.snapshot();F=l.w(l.h3+0x4838)
assert before['active']==0
# The native entry wait is at most one field; require at least one whole
# quantum of unsampled CIA backlog beyond it, not just a nonzero due word.
backlog=l.u(l.state+48)-before['cursor']
assert backlog>before['quantum']*F/1024+2,(before,F)
l.fields(200);held=l.snapshot()
assert held['steps']==before['steps'] and held['cursor']==before['cursor']
# This combat menu offers Continue, then Abort. Native menu queue input is
# used only while W6 has released flight ownership.
if not a.resume_menu:
    subprocess.run([sys.executable,'-B','tools/completion_keys.py',hex(l.sim),'sim','tab'],check=True)
host=Path(__file__).with_name('completion_host_input.py')
subprocess.run([sys.executable,'-B',str(host),f'queue:{l.sim},200588,68'],check=True)
l.fields(2)
subprocess.run([sys.executable,'-B',str(host),f'release:{l.sim},200588,68'],check=True)
l.until(l.sym('time_loop_exit'))
exiting=l.snapshot();mission_exit(before,held,exiting,backlog,F)
(l.out/'mission-exit.json').write_text(json.dumps(dict(passed=True,before=before,held=held,exiting=exiting,backlog_cia=backlog,F=F,scope='Native Abort menu during unsampled catch-up backlog; no additional world update before flight exit'),indent=2)+'\n')
print('MISSION EXIT PASS',backlog,flush=True)
