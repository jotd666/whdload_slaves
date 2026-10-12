"""Prepare an owned D5 developer flight for external acceptance checks.

Run from tmp/dev. Leaves the emulator paused and native input server available;
finish with completion_host_input.py quit and redbaron.py quit.
"""
import argparse,hashlib,json,os,shutil,struct,subprocess,sys,time
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/'tools'))
import route_status as r
p=argparse.ArgumentParser();p.add_argument('machine');p.add_argument('mask',type=lambda s:int(s,0));p.add_argument('out',type=Path);p.add_argument('--resume-entry',action='store_true');p.add_argument('--scale',type=int,choices=(0,40,60),default=40);p.add_argument('--scene',choices=('ace','squadron'),default='ace');a=p.parse_args()
os.environ['BENCH_DEVELOPER']='1'
os.environ['BENCH_BATCH_KEYS']='1'
ROOT=Path.cwd();TRACKED=ROOT.parents[1]/'R/RedBaron/tools'
# Use the game's own persisted preference input; slider key repeat under warp
# cannot select a reproducible exact value. Never modify the source fixture.
fixture=ROOT/'tmp/game'/('d5-'+a.out.name)/'RedBaron'
if not a.resume_entry:
 if fixture.exists():raise FileExistsError(fixture)
 shutil.copytree(ROOT/'tmp/game/completion-benchmark/RedBaron',fixture)
 pref=fixture/'data/SIMPREFS.PRF';data=bytearray(pref.read_bytes())
 struct.pack_into('>H',data,0,a.scale);pref.write_bytes(data)
os.environ['GAME']=str(fixture)
def run(*args):subprocess.run([sys.executable,'-B',*map(str,args)],check=True)
if not a.resume_entry:run('tools/completion_boot.py',a.machine,a.mask,a.out,'--entry-only')
ready=json.loads((a.out/'ps-ready.json').read_text());ps=ready['ps']
with (a.out/'input.log').open('w') as log:
 host=subprocess.Popen([sys.executable,'-B',str(TRACKED/'completion_host_input.py'),'--serve','--ps',hex(ps)],stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
(a.out/'input-server.pid').write_text(str(host.pid))
end=time.monotonic()+1000
while 'INPUT READY' not in (a.out/'input.log').read_text():
 if host.poll() is not None:raise RuntimeError('Input server exited; inspect input.log')
 if time.monotonic()>end:raise TimeoutError('Input attachment still pending; inspect existing process, do not restart')
 time.sleep(1)
scene=a.scene
pskeys=(['return','tab','return']+['tab']*3+['return','tab','return']+['tab']*12+['return']+['tab']*3+['return']) if scene=='squadron' else (['return']*4+['tab']*4+['return','tab','return'])
run('tools/completion_keys.py',hex(ps),'ps',*pskeys)
# Reuse the boot scanner without invoking its CLI again.
import ast,struct
s=ast.parse(Path('tools/completion_boot.py').read_text());fn=next(n for n in s.body if isinstance(n,ast.FunctionDef) and n.name=='locate');exec(compile(ast.Module(body=[fn],type_ignores=[]),'locate','exec'))
sim=locate('sim',0x1ef92,[0x309cc,0x30a4e,0x30aec])
(a.out/'sim.json').write_text(json.dumps(dict(sim=sim,ps=ps)))
run('tools/completion_keys.py',hex(sim),'sim','tab','return','--polls','1')
r.command(f'until {sim+0x21d30:#x}')
print('FLIGHT READY',hex(sim),flush=True)

def irq(raw,up=False):
 run(TRACKED/'completion_host_input.py',f'irq-{"up" if up else "down"}:{sim},{0x30f8c},{raw}')
irq(0x59)
r.command(f'until {sim+0x1fb3a:#x}')
irq(0x59,True)
keys=['tab']*5+['return']+['right']*20+['return','tab','return']+['right']*20+['return','tab','return']+['tab']*5+['return']
scale=a.scale
run('tools/completion_keys.py',hex(sim),'sim',*keys)
(a.out/'scenario.json').write_text(json.dumps(dict(scene=scene,requested_time_scale=scale)))
run('tools/completion_d5_runtime.py',a.out)
r.command(f'until {sim+0x21d30:#x}')
from d5_live import Live
actual=Live(a.out).w(json.loads((a.out/'runtime.json').read_text())['h3']+0x3d56)
assert actual==scale, (actual,scale)
for scan in a.out.glob('locate-*.bin'):scan.unlink()
(a.out/'entry.json').write_text(json.dumps(dict(machine=a.machine,mask=a.mask,sim=sim,ps=ps,build_mode='developer',slave_sha256=hashlib.sha256((a.out/'slave.slave').read_bytes()).hexdigest(),time_scale=scale,scene=scene),indent=2)+'\n')
print('D5 READY',a.out,flush=True)
