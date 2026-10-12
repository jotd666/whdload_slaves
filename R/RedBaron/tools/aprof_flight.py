"""Exact per-PC cycle profile (aprof FS-UAE) of steady flight, VERIFY tape route.

Run from the local harness (tmp/dev, env.sh sourced). The VERIFY tape replaces the lldb
keyboard driver, which cannot attach to arm64 FS-UAE. aprof needs a cycle-exact 020/030
without an MMU model, so use APROF_CPU=68EC030 for the 030 class. CUSTOM2 should be the
normal build's CPU-filtered selection (030: 0x7f0ffa). The capture uses the unmodified
VERIFY source, including artwork twins.
  APROF_CPU=68EC030 UNTIL_TIMEOUT=1500 python3 -B ../../R/RedBaron/tools/aprof_flight.py \
    030-nommu 0x7f0ffa tmp/prof/aprof-030n-1 --warm 500 --fields 50
Summarize with aprof_flight_report.py CAPTURE --slave-base <live slave copy>.
"""
import argparse,hashlib,json,os,re,struct,subprocess,sys
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/'tools'))
sys.path.insert(0,str(Path.cwd().parents[1]/'R/RedBaron/tools'))
import route_status as r
from completion_machines import environment
p=argparse.ArgumentParser();p.add_argument('machine');p.add_argument('mask',type=lambda s:int(s,0));p.add_argument('out',type=Path)
p.add_argument('--warm',type=int,default=500);p.add_argument('--fields',type=int,default=50);a=p.parse_args()
if a.out.exists():raise SystemExit('Refusing overwrite')
env=environment(a.machine,a.mask);env.pop('BOOT_BREAK',None)
if os.environ.get('APROF_CPU'):env['CPU']=os.environ['APROF_CPU']
env['FSUAE']=os.path.expanduser('~/.local/share/amiga/fs-uae-aprof/fs-uae')
env['GAME']=str(Path.cwd()/'tmp/game/completion-benchmark/RedBaron')
os.environ.update(env)
subprocess.run([sys.executable,'-B','tools/reach_flight.py','--no-shot','--out',str(a.out)],env=env,check=True)
at=r.locate();state=r.read(at);sim=state['sim']
vbl=sim+0x2d34e
r.command(f'gdb delete\nbreak *{vbl:#x}\nignore $bpnum {a.warm}\ncontinue\ndelete')
r.command('stop')
# Refuse to profile a build which silently bypasses the artwork correctness check.
listing=(a.out/'slave.lst').read_text(encoding='latin1')
def symbol(name):
 return int(re.search(r'^'+re.escape(name)+r'\s+00:([0-9A-Fa-f]+)',listing,re.M)[1],16)
base=state['game_anchor']-symbol('tape_game_anchor')
def words(name,count):
 address=base+symbol(name);path=a.out/(name+'.bin')
 r.command(f'gdb dump binary memory {path} {address:#x} {address+count*4:#x}')
 return list(struct.unpack('>'+count*'I',path.read_bytes()))
effective=words('perf_mask',1)[0]
twins={}
if effective&(1<<19):
 twins['artwork']=words('artwork_cache_twin_result',4)
 if twins['artwork'] != [63,0,0,6]:raise RuntimeError('Artwork twins incomplete or failed: '+str(twins))
if effective&(1<<20):
 twins['scene']=words('scene_twin_result',5)
 if twins['scene'] != [7,0,3,0,0]:raise RuntimeError('Scene twins incomplete or failed: '+str(twins))
if effective&(1<<22):
 twins['cockpit']=words('cockpit_fast_twin_result',5)
 if twins['cockpit'] != [3,0,2,0,0]:raise RuntimeError('Cockpit twins incomplete or failed: '+str(twins))
 twins['cockpit_final_checks']=words('cockpit_fast_final_checks',1)[0]
 if twins['cockpit_final_checks'] < 2:raise RuntimeError('Final cockpit checks incomplete')
if effective&(1<<23):
 from gauge_fast import check
 def raw_words(name, count):
  return struct.pack('>'+count*'I', *words(name,count))
 twins['gauges']=check(raw_words('gauge_fast_twin_checked',2),
                       raw_words('instrument_cache_twin_result',8),
                       raw_words('gauge_fast_draws',1))
(a.out/'twins.json').write_text(json.dumps(twins,indent=2)+'\n')
flight_entry=json.loads((a.out/'entry.json').read_text())
regions=r.memory_regions()
for lo,hi in regions:r.command(f'gdb dump binary memory {a.out}/ram-{lo:x}.bin {lo:#x} {hi:#x}')
print(r.command('gdb monitor aprof start'),flush=True)
r.command(f'gdb break *{vbl:#x}\nignore $bpnum {a.fields-1}\ncontinue\ndelete')
print(r.command(f'gdb monitor aprof stop {(a.out/"flight.prof").resolve()}'),flush=True)
(a.out/'entry.json').write_text(json.dumps(dict(machine=a.machine,mask=a.mask,effective_mask=effective,sim=sim,slave_base=base,regions=regions,warm=a.warm,fields=a.fields,
  slave_sha256=hashlib.sha256((a.out/"slave.slave").read_bytes()).hexdigest(),twins=twins,flight_entry=flight_entry,
  environment={k:env.get(k) for k in ['CPU','AMIGA_MODEL','CHIP_KB','FAST_KB','EXTRA_ARGS','WHD_ARGS','FSUAE']}),indent=2)+'\n')
r.command('shot '+str((a.out/'final.png').resolve()))
r.command('quit')
print('APROF COMPLETE',a.out,flush=True)
