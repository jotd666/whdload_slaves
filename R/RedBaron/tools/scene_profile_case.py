"""Short direct-scene comparison using the established local native-input harness.

Run from tmp/dev. Set BENCH_DEVELOPER=1 and BENCH_BATCH_KEYS=1.
Use the same frozen developer binary for both masks; only the feature under test may differ.
The local completion_boot driver supports BENCH_FROZEN_SLAVE for this purpose.
"""
import argparse,hashlib,json,os,subprocess,sys,time
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/'tools'))
import route_status as r
p=argparse.ArgumentParser();p.add_argument('machine',choices=('a500','020','030','030-nommu','040','060'));p.add_argument('mask',type=lambda s:int(s,0));p.add_argument('out',type=Path);p.add_argument('--bank-after',type=int,default=0,help='Additional held-bank FPS window after level flight');p.add_argument('--resume-entry',action='store_true');p.add_argument('--check-only',action='store_true',help='Normal-build default and CPU-gate smoke check, without profiling');p.add_argument('--fields',type=int,default=250);p.add_argument('--dma-fields',type=int,default=0,help='Optional bounded page-safety trace after profiling');p.add_argument('--groups',nargs='+',choices=('stages','draw','fps','rate'),default=['stages','draw']);a=p.parse_args()
if a.bank_after and (not 250 <= a.bank_after <= 2000 or a.check_only or a.dma_fields):p.error('Bank-after requires 250–2000 fields and excludes check-only/DMA')
if not 10 <= a.fields <= 2000:p.error('Use a bounded 10–2000-field window')
if a.dma_fields and (not 10 <= a.dma_fields <= 40 or a.check_only or 'stages' not in a.groups):p.error('DMA checking requires stages and 10–40 fields')
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
run('tools/completion_keys.py',hex(sim),'sim','tab','return','--polls','1')
w6_enabled = bool(a.mask & (1<<13)) if ready['environment']['DEVELOPER']=='1' else bool(int(os.environ.get('BENCH_CUSTOM3','0')) & 1)
if w6_enabled:
 # W6 consumes hardware keyboard transitions in flight, not the menu queue.
 # Enter flight first, then use the established D5 native IRQ F10 route.
 r.command(f'until {sim+0x21d30:#x}')
 run(TRACKED/'completion_host_input.py',f'irq-down:{sim},200588,89')
 r.command(f'until {sim+0x1fb3a:#x}')
 run(TRACKED/'completion_host_input.py',f'irq-up:{sim},200588,89')
else:run('tools/completion_keys.py',hex(sim),'sim','f10','--polls','1')
keys=['tab']*5+['return']+['right']*20+['return','tab','return']+['right']*20+['return','tab','return']+['tab']*5+['return']
run('tools/completion_keys.py',hex(sim),'sim',*keys)
r.command(f'until {sim+0x21d30:#x}')
env=ready['environment']
meta=dict(machine=a.machine,mask=a.mask,build_mode='developer' if env['DEVELOPER']=='1' else 'normal',sim=sim,ps=ps,slave_sha256=hashlib.sha256((a.out/'slave.slave').read_bytes()).hexdigest(),environment={k:env[k] for k in ['CPU','AMIGA_MODEL','CHIP_KB','FAST_KB','EXTRA_ARGS','WHD_ARGS']},realism_sha256=hashlib.sha256((Path(os.environ['GAME'])/'data/mreal.prf').read_bytes()).hexdigest(),route='Damage-protected benchmark fixture; native keyboard queue via host debugger; maximum World/Aircraft, Ground ON IN COMBAT; unchanged Time Scale')
(a.out/'entry.json').write_text(json.dumps(meta,indent=2)+'\n')
if os.environ.get('BENCH_OMIT_CUSTOM2')=='1':
 proof=r.command(f'gdb x/1hx {sim+0xb06:#x}')
 assert '0x7001' in proof,proof
 fence_proof=r.command(f'gdb x/1hx {sim+0x31522:#x}')
 assert ('0x4ef9' if a.machine in ('030','030-nommu','040','060') else '0x2039') in fence_proof,fence_proof
 cockpit_proof=r.command(f'gdb x/1hx {sim+0x2c144:#x}\nx/1hx {sim+0x830:#x}')
 expected_cockpit=('0x4ef9','0x4eb9') if a.machine in ('030','030-nommu','040','060') else ('0x3239','0x3039')
 assert all(op in cockpit_proof for op in expected_cockpit),cockpit_proof
 gauge_proof=r.command(f'gdb x/1hx {sim+0x19ba6:#x}\nx/1hx {sim+0x19d98:#x}')
 expected_gauge=('0x4ef9','0x4eb9') if a.machine=='060' else ('0x4e55','0x4eba')
 assert all(op in gauge_proof for op in expected_gauge),gauge_proof
 span_proof=r.command(f'gdb x/1hx {sim+0x2f312:#x}')
 assert ('0x4ef9' if a.machine in ('040','060') else '0x3806') in span_proof,span_proof
 (a.out/'default-selection.txt').write_text(proof+fence_proof+cockpit_proof+gauge_proof+span_proof)


for path in a.out.glob('locate-*.bin'):path.unlink()
if a.check_only:
 assert meta['build_mode']=='normal' and os.environ.get('BENCH_OMIT_CUSTOM2')=='1'
 proof=r.command(f'gdb x/1hx {sim+0x2eb96:#x}\nx/1hx {sim+0x2fcd6:#x}')
 expected=('0x2c3c','0x48a7') if a.machine in ('a500','020') else ('0x4ef9','0x4ef9')
 assert all(proof.count(x)>=expected.count(x) for x in expected),proof
 (a.out/'scene-selection.txt').write_text(proof)
 if w6_enabled and a.machine in ('040','060'):
  proof=r.command(f'gdb x/1hx {sim+0xf06c:#x}\nx/1hx {sim+0xf5f4:#x}')
  assert '0x4eb9' in proof and '0x4ef9' in proof,proof
  (a.out/'scenery-selection.txt').write_text(proof)
  # Bounded normal-build draw after Preferences returns, with FC8 selected.
  flight=r.command(f'gdb break *{sim+0x21d30:#x}\nignore $bpnum 39\ncontinue\ndelete\nprintf "SCENERY_FLIGHT %x\\n", $pc')
  assert f'SCENERY_FLIGHT {sim+0x21d30:x}' in flight,flight
  (a.out/'scenery-flight.txt').write_text(flight)


# Resolve the live slave through an installed hook, never a PRELOAD copy.
if 'time_present_cache_buffer_ptr:' in (a.out/'slave.lst').read_text(encoding='latin1'):
 import re
 from runtime_buffers import check_live
 from presentation_state import symbol
 lines=(a.out/'slave.lst').read_text(encoding='latin1').splitlines()
 hook,target=(0x21d28,'time_loop_gate') if w6_enabled else (0x2c552,'scene_frame_enter')
 scene_enabled = bool(a.mask & (1<<20)) if meta['build_mode']=='developer' else os.environ.get('BENCH_OMIT_CUSTOM2')=='1'
 if w6_enabled or (scene_enabled and a.machine in ('030','030-nommu','040','060')):
  raw=r.command(f'gdb printf "BUFFER_HOOK %u\\n", *(unsigned int*){sim+hook+2:#x}')
  base=int(re.search(r'BUFFER_HOOK (\d+)',raw)[1])-symbol(lines,target)
  if 'scene_raster_selected:' in '\n'.join(lines) and scene_enabled:
   raw=r.command(f'gdb printf "RASTER_SELECTED %u %u\\n", *(unsigned int*){base+symbol(lines,"scene_raster_selected"):#x}, *(unsigned int*){base+symbol(lines,"perf_mask"):#x}')
   selected,effective=map(int,re.search(r'RASTER_SELECTED (\d+) (\d+)',raw).groups())
   expected=base+symbol(lines,'scene_raster_fast_code' if effective&(1<<26) else 'scene_raster_code')
   assert selected==expected,raw
   (a.out/'raster-selection.json').write_text(json.dumps(dict(selected=selected,effective_mask=effective,fc9=bool(effective&(1<<26))),indent=2)+'\n')
   if 'overlay_generation_enabled:' in '\n'.join(lines):
    raw=r.command(f'gdb printf "OVERLAY_GENERATION %u\\n", *(unsigned short*){base+symbol(lines,"overlay_generation_enabled"):#x}')
    active=int(re.search(r'OVERLAY_GENERATION (\d+)',raw)[1])
    assert bool(active)==bool(effective&(1<<27)),raw
    (a.out/'overlay-generation.json').write_text(json.dumps(dict(active=active,effective_mask=effective),indent=2)+'\n')
  result=check_live(lines,base,r.command,w6_enabled,a.machine!='a500')
  (a.out/'runtime-buffers.json').write_text(json.dumps(result,indent=2)+'\n')

# Input is finished. Release the host debugger before a long guest-debugger
# capture; only one debugger needs to drive execution during measurement.
run(TRACKED/'completion_host_input.py','quit');host.wait(timeout=20)
for group in (() if a.check_only else a.groups):
 if group=='rate':
  assert a.mask & (1<<13) and meta['build_mode']=='developer'
  run(TRACKED/'w6_rate_profile.py',a.out,'--fields',a.fields)
 else:run(TRACKED/'render_profile.py',a.out,'--group',group,'--fields',a.fields)
if a.bank_after:
 r.command('shot '+str((a.out/'final.png').resolve()))
 bank=a.out/'bank';bank.mkdir()
 with (bank/'input.log').open('w') as log:
  host=subprocess.Popen([sys.executable,'-B',str(TRACKED/'completion_host_input.py'),'--serve','--irq-only'],stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 (bank/'input-server.pid').write_text(str(host.pid))
 end=time.monotonic()+1000
 while 'INPUT READY' not in (bank/'input.log').read_text():
  if host.poll() is not None or time.monotonic()>end:raise RuntimeError('Bank input attachment failed')
  time.sleep(1)
 run(TRACKED/'completion_host_input.py',f'irq-down:{sim},200588,78')
 run(TRACKED/'completion_host_input.py','quit');host.wait(timeout=20)
 bankmeta=dict(meta,route=meta['route']+'; native right-bank IRQ held throughout the following window')
 (bank/'entry.json').write_text(json.dumps(bankmeta,indent=2)+'\n')
 if 'rate' in a.groups:run(TRACKED/'w6_rate_profile.py',bank,'--fields',a.bank_after)
 else:run(TRACKED/'render_profile.py',bank,'--group','fps','--fields',a.bank_after)
 r.command('shot '+str((bank/'final.png').resolve()))
(a.out/'debug.uae').write_bytes(Path('amiga/.run/fsuae/Cache/Logs/debug.uae').read_bytes())
if not a.bank_after:r.command('shot '+str((a.out/'final.png').resolve()))
if a.dma_fields:
 assert 10 <= a.dma_fields <= 40
 pointer_log=r.command(f'gdb printf "PAGES %u %u COPPER %u\\n", *(unsigned int*)*(unsigned int*){sim+0x314c2:#x}, *(unsigned int*)*(unsigned int*){sim+0x314c8:#x}, *(unsigned int*){sim+0x3151a:#x}')
 import re
 match=re.search(r'PAGES (\d+) (\d+) COPPER (\d+)',pointer_log)
 assert match,pointer_log
 pages=list(map(int,match.groups()[:2]));copper=int(match[3])
 trace=(a.out/'display-trace.bin').resolve()
 print(r.command(f'profile {a.dma_fields} {trace}'),flush=True)
 sys.path.insert(0,str(TRACKED))
 from display_ownership import analyse
 display=analyse(trace,sim,pages)
 display['copper']=copper
 (a.out/'display.json').write_text(json.dumps(display,indent=2)+'\n')
 from page_fence_check import check
 result=check(display,(a.out/'stages.log').read_text(),a.fields,pickup_guard=meta['build_mode']=='normal')
 (a.out/'fence-check.json').write_text(json.dumps(result,indent=2)+'\n')
 trace.unlink() # Retain compact evidence, not the large DMA stream.
r.command('quit')
print('RENDER PROFILE COMPLETE',a.out,flush=True)
