"""Exact per-PC cycle profile (aprof FS-UAE) of steady flight, VERIFY tape route.

Run from the local harness (tmp/dev, env.sh sourced). The VERIFY tape replaces the lldb
keyboard driver, which cannot attach to arm64 FS-UAE. aprof needs a cycle-exact 020/030
without an MMU model, so use APROF_CPU=68EC030 for the 030 class. CUSTOM2 should be the
normal build's CPU-filtered selection (030: 0x1f0ffa). The VERIFY artwork twin aborts on
this route, so the build uses a private copy of the source with only that twin removed.
  APROF_CPU=68EC030 UNTIL_TIMEOUT=1500 python3 -B ../../R/RedBaron/tools/aprof_flight.py \
    030-nommu 0x1f0ffa tmp/prof/aprof-030n-1 --warm 500 --fields 50
Summarize with aprof_flight_report.py CAPTURE --slave-base <live slave copy>.
"""
import argparse,json,os,shutil,subprocess,sys
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
# Private source copy: drop only the VERIFY artwork twin calls (they abort on this route).
copy=Path('tmp/aprof-src');shutil.rmtree(copy,ignore_errors=True)
shutil.copytree(Path.cwd().parents[1]/'R/RedBaron/usr/source',copy)
for name in ('artwork-front.s','artwork-solid.s'):
 f=copy/name;t=f.read_text(encoding='latin1')
 t=t.replace(' bsr artwork_cache_twin_before\n',' ; profiling copy: twin removed\n').replace(' bsr artwork_cache_twin_after\n',' ; profiling copy: twin removed\n')
 f.write_text(t,encoding='latin1')
wrapper=Path('tmp/aprof-vasm.sh');real=os.environ.get('VASM',os.path.expanduser('~/.local/vasmm68k_mot'))
wrapper.write_text(f'#!/bin/bash\ncd "{copy.resolve()}" && exec "{real}" "$@"\n');wrapper.chmod(0o755)
env['VASM']=str(wrapper.resolve())
os.environ.update(env)
subprocess.run([sys.executable,'-B','tools/reach_flight.py','--no-shot','--out',str(a.out)],env=env,check=True)
at=r.locate();state=r.read(at);sim=state['sim']
vbl=sim+0x2d34e
r.command(f'gdb delete\nbreak *{vbl:#x}\nignore $bpnum {a.warm}\ncontinue\ndelete')
r.command('stop')
regions=r.memory_regions()
for lo,hi in regions:r.command(f'gdb dump binary memory {a.out}/ram-{lo:x}.bin {lo:#x} {hi:#x}')
print(r.command('gdb monitor aprof start'),flush=True)
r.command(f'gdb break *{vbl:#x}\nignore $bpnum {a.fields-1}\ncontinue\ndelete')
print(r.command(f'gdb monitor aprof stop {(a.out/"flight.prof").resolve()}'),flush=True)
(a.out/'entry.json').write_text(json.dumps(dict(machine=a.machine,mask=a.mask,sim=sim,regions=regions,warm=a.warm,fields=a.fields,
  environment={k:env.get(k) for k in ['CPU','AMIGA_MODEL','CHIP_KB','FAST_KB','EXTRA_ARGS','WHD_ARGS','FSUAE']}),indent=2)+'\n')
r.command('shot '+str((a.out/'final.png').resolve()))
r.command('quit')
print('APROF COMPLETE',a.out,flush=True)
