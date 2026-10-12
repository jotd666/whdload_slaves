"""Boot a VERIFY-only controlled D5 starting scenario; leave native play paused."""
import argparse,hashlib,json,os,re,shutil,subprocess,sys,time
from pathlib import Path
from completion_machines import environment
p=argparse.ArgumentParser();p.add_argument('machine',choices=('a500','060'));p.add_argument('scenario',choices=('landing','crash','transit','combat'));p.add_argument('out',type=Path);a=p.parse_args()
root=Path(__file__).resolve().parents[3];harness=root/'tmp/dev';os.chdir(harness);sys.path.insert(0,str(harness/'tools'))
import route_status as r
out=a.out.resolve()
if out.exists():raise FileExistsError(out)
pid=harness/'amiga/.run/fsuae.pid'
if pid.exists() and subprocess.run(['ps','-p',pid.read_text().strip()],stdout=subprocess.DEVNULL).returncode==0:
    raise RuntimeError('Close the owned previous emulator first')
out.mkdir(parents=True)
fixture=harness/'tmp/game'/('d5-'+out.name)/'RedBaron'
shutil.copytree(harness/'tmp/game/RedBaron_v2.1/RedBaron',fixture)
if a.scenario=='combat':
    # Native preference: player protection only. Enemy damage remains original.
    realism=fixture/'data/mreal.prf'
    data=bytearray(realism.read_bytes());data[18:20]=bytes(2);realism.write_bytes(data)
mask=0x33fff if a.machine=='a500' else 0x1ff2ffa
env=environment(a.machine,mask);env.update(VERIFY='1',WARP='1',DETERMINISTIC='1',JOY0='none',JOY0_MODE='nothing',JOY1='none',GAME=str(fixture),SLAVE=str(out/'slave.slave'),WHD_ARGS=f'CUSTOM2={mask} CUSTOM5=512')
# VERIFY carries large instrumentation buffers; this is functional CPU coverage,
# not a minimum-memory or timing claim (developer cases cover those separately).
if a.machine=='a500':env['FAST_KB']='8192'
env.pop('BOOT_BREAK',None)
share=Path(env.get('AMIGA_SHARE',str(Path.home()/'.local/share/amiga')))
whd=Path(env.get('WHDLOAD',str(share/'WHDLoad-20.0')))
scenario={'landing':1,'crash':2,'transit':3,'combat':4}[a.scenario]
subprocess.run([env.get('VASM',str(Path.home()/'.local/vasmm68k_mot')),'-DVERIFY=1',f'-DVERIFY_D5_SCENARIO={scenario}','-m68000','-pic','-x','-devpac','-Fhunkexe','-nosym','-I'+str(harness/'tmp/include'),'-I'+str(whd/'Include'),'-I'+str(whd/'Src/sources'),'-I'+env.get('NDK',str(share/'ndk/Include_I')),'-L',str(out/'slave.lst'),'-o',str(out/'slave.slave'),'RedBaronHD.s'],cwd=root/'R/RedBaron/usr/source',check=True)
with (out/'serve.log').open('w') as log:
    server=subprocess.Popen([sys.executable,'tools/redbaron.py','serve'],env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
deadline=time.monotonic()+240
while True:
    if server.poll() is not None:raise RuntimeError('Server exited; inspect serve.log')
    try:marker=r.locate();break
    except (ConnectionRefusedError,FileNotFoundError,RuntimeError):
        if time.monotonic()>deadline:raise
        try:r.command('cont')
        except (ConnectionRefusedError,FileNotFoundError,RuntimeError):pass
        time.sleep(2)
state=r.read(marker)
if state['game_steps']!=0:raise RuntimeError('Missed initial fixture anchor')
r.command(f"until {state['game_anchor']:#x}")
state=r.read(marker);assert state['game_steps']==1 and state['inflight']==1,state
syms={m[1]:int(m[2],16) for line in (out/'slave.lst').read_text(encoding='latin1').splitlines() if (m:=re.match(r'^(\w+)\s+00:([0-9a-fA-F]+)\s*$',line))}
base=state['game_anchor']-syms['tape_game_anchor']
h3=int(r.command(f'gdb p/u *(unsigned int*){base+syms["observe_header"]+28:#x}').split('=')[1])
(out/'runtime.json').write_text(json.dumps(dict(sim=state['sim'],h3=h3,slave=base)))
(out/'sim.json').write_text(json.dumps(dict(sim=state['sim'],ps=state['ps'])))
meta=dict(machine=a.machine,scenario=a.scenario,mask=mask,build_mode='VERIFY controlled initial conditions',player_damage=a.scenario!='combat',fast_kb=env['FAST_KB'],slave_sha256=hashlib.sha256((out/'slave.slave').read_bytes()).hexdigest(),realism_sha256=hashlib.sha256((fixture/'data/mreal.prf').read_bytes()).hexdigest(),scope='Native physics and outcomes from a one-time synthetic start; not ordinary-mission handling or performance evidence')
(out/'entry.json').write_text(json.dumps(meta,indent=2)+'\n')
(harness/'tmp/build/route-ram.bin').unlink(missing_ok=True)
from d5_live import Live
Live(out).attach_input()
print('D5 FIXTURE READY',a.machine,a.scenario,flush=True)
