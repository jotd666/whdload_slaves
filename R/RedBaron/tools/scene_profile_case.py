"""Short direct-scene comparison using the established local native-input harness.

Run from tmp/dev. Set BENCH_DEVELOPER=1 and BENCH_BATCH_KEYS=1.
Use the same frozen developer binary for both masks; only bit 20 may differ.
The local completion_boot driver supports BENCH_FROZEN_SLAVE for this purpose.
"""
import argparse,hashlib,json,os,subprocess,sys,time
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/'tools'))
import route_status as r
p=argparse.ArgumentParser();p.add_argument('machine',choices=('a500','020','030','030-nommu','040','060'));p.add_argument('mask',type=lambda s:int(s,0));p.add_argument('out',type=Path);p.add_argument('--resume-entry',action='store_true');p.add_argument('--check-only',action='store_true',help='Normal-build default and CPU-gate smoke check, without profiling');p.add_argument('--groups',nargs='+',choices=('stages','draw'),default=['stages','draw']);a=p.parse_args()
ROOT=Path.cwd();os.environ['GAME']=str(ROOT/'tmp/game/completion-benchmark/RedBaron');TRACKED=ROOT.parents[1]/'R/RedBaron/tools'
def run(*args):subprocess.run([sys.executable,'-B',*map(str,args)],check=True)
if not a.resume_entry:run('tools/completion_boot.py',a.machine,a.mask,a.out,'--entry-only')
ready=json.loads((a.out/'ps-ready.json').read_text());ps=ready['ps']
ready['environment']={k:v for k,v in ready['environment'].items() if k in ('CPU','AMIGA_MODEL','CHIP_KB','FAST_KB','EXTRA_ARGS','WHD_ARGS','DEVELOPER','VERIFY')}
(a.out/'ps-ready.json').write_text(json.dumps(ready,indent=2)+'\n')
with (a.out/'input.log').open('w') as log:
 host=subprocess.Popen([sys.executable,'-B',str(TRACKED/'completion_host_input.py'),'--serve','--ps',hex(ps)],stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
(a.out/'input-server.pid').write_text(str(host.pid))
end=time.monotonic()+1000
while 'INPUT READY' not in (a.out/'input.log').read_text():
 if host.poll() is not None:raise RuntimeError('Input server exited; inspect input.log')
 if time.monotonic()>end:raise TimeoutError('Input attachment still pending; inspect existing process, do not restart')
 time.sleep(1)
run('tools/completion_keys.py',hex(ps),'ps',*(['return']*4+['tab']*4+['return','tab','return']))
# Reuse the boot scanner without invoking its CLI again.
import ast,struct
s=ast.parse(Path('tools/completion_boot.py').read_text());fn=next(n for n in s.body if isinstance(n,ast.FunctionDef) and n.name=='locate');exec(compile(ast.Module(body=[fn],type_ignores=[]),'locate','exec'))
sim=locate('sim',0x1ef92,[0x309cc,0x30a4e,0x30aec])
run('tools/completion_keys.py',hex(sim),'sim','tab','return','f10','--polls','1')
keys=['tab']*5+['return']+['right']*20+['return','tab','return']+['right']*20+['return','tab','return']+['tab']*5+['return']
run('tools/completion_keys.py',hex(sim),'sim',*keys)
r.command(f'until {sim+0x21d30:#x}')
env=ready['environment']
meta=dict(machine=a.machine,mask=a.mask,build_mode='developer' if env['DEVELOPER']=='1' else 'normal',sim=sim,ps=ps,slave_sha256=hashlib.sha256((a.out/'slave.slave').read_bytes()).hexdigest(),environment={k:env[k] for k in ['CPU','AMIGA_MODEL','CHIP_KB','FAST_KB','EXTRA_ARGS','WHD_ARGS']},realism_sha256=hashlib.sha256((Path(os.environ['GAME'])/'data/mreal.prf').read_bytes()).hexdigest(),route='Damage-protected benchmark fixture; native keyboard queue via host debugger; maximum World/Aircraft, Ground ON IN COMBAT; unchanged Time Scale')
(a.out/'entry.json').write_text(json.dumps(meta,indent=2)+'\n')
if os.environ.get('BENCH_OMIT_CUSTOM2')=='1':
 proof=r.command(f'gdb x/1hx {sim+0xb06:#x}')
 assert '0x7001' in proof,proof
 (a.out/'default-selection.txt').write_text(proof)


for path in a.out.glob('locate-*.bin'):path.unlink()
if a.check_only:
 assert meta['build_mode']=='normal' and os.environ.get('BENCH_OMIT_CUSTOM2')=='1'
 proof=r.command(f'gdb x/1hx {sim+0x2eb96:#x}\nx/1hx {sim+0x2fcd6:#x}')
 expected=('0x2c3c','0x48a7') if a.machine in ('a500','020') else ('0x4ef9','0x4ef9')
 assert all(proof.count(x)>=expected.count(x) for x in expected),proof
 (a.out/'scene-selection.txt').write_text(proof)
for group in (() if a.check_only else a.groups):
 run(TRACKED/'render_profile.py',a.out,'--group',group,'--fields',250)
(a.out/'debug.uae').write_bytes(Path('amiga/.run/fsuae/Cache/Logs/debug.uae').read_bytes())
r.command('shot '+str((a.out/'final.png').resolve()))
run(TRACKED/'completion_host_input.py','quit');host.wait(timeout=20)
r.command('quit')
print('RENDER PROFILE COMPLETE',a.out,flush=True)
