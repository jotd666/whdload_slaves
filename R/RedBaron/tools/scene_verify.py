"""Bounded direct scene primitive twins; run from tmp/dev after env.sh."""
import json, os, re, socket, subprocess, sys, time
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/'tools'))
from completion_machines import environment
import route_status as r
import argparse
p=argparse.ArgumentParser(description=__doc__);p.add_argument('out',type=Path);p.add_argument('--machine',choices=('030','040','060'),default='060');p.add_argument('--bank',action='store_true');p.add_argument('--transitions',action='store_true');a=p.parse_args()
assert not (a.bank and a.transitions), 'Scripted bank and native transition input are separate fixtures'
out=a.out;assert not out.exists()
pid=Path('amiga/.run/fsuae.pid')
if pid.exists():
 z=subprocess.run(['ps','-p',pid.read_text().strip(),'-o','stat=,command='],capture_output=True,text=True)
 assert z.returncode or z.stdout.lstrip().startswith('Z'),z.stdout
env=environment(a.machine,0x1f0ffa if a.machine=='040' else 0x1b0ffa)
env.update(GAME=str(Path('tmp/game/completion-benchmark/RedBaron').resolve()),BOOT_TIMEOUT='240',FILL_TRACE='1',TWIN_FAIL_SYMBOL='scene_frame_bad')
subprocess.run([sys.executable,'-B','tools/reach_flight.py','--no-shot','--out',str(out)]+(['--bank'] if a.bank else []),env=env,check=True)
e=json.loads((out/'entry.json').read_text())['entry']
sym={m[1]:int(m[2],16) for line in (out/'slave.lst').read_text(encoding='latin1').splitlines() if (m:=re.match(r'^(\w+)\s+00:([0-9A-Fa-f]+)',line))}
base=e['game_anchor']-sym['tape_game_anchor'];bad=base+sym['scene_frame_bad'];result=base+sym['scene_twin_result']
raw=r.command(f'gdb delete\nbreak *{bad:#x}\nbreak *{e["game_anchor"]:#x}\nignore $bpnum 9\ncontinue\ninfo registers pc\nx/5wx {result:#x}')
(out/'twins.log').write_text(raw);print(raw,flush=True)
assert f'{bad:x}' not in raw.split('Continuing.')[-1],raw
path=out/'twins.bin';r.command(f'gdb dump binary memory {path} {result:#x} {result+20:#x}')
assert path.read_bytes()[:12]==bytes.fromhex('000000070000000000000003'),path.read_bytes().hex()
if a.transitions:
 tracked=Path(__file__).resolve().parent
 with (out/'input.log').open('w') as log:
  host=subprocess.Popen([sys.executable,'-B',str(tracked/'completion_host_input.py'),'--serve','--irq-only'],stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 (out/'input-server.pid').write_text(str(host.pid))
 deadline=time.monotonic()+1000
 while 'INPUT READY' not in (out/'input.log').read_text():
  if host.poll() is not None or time.monotonic()>deadline:raise RuntimeError('Inspect owned input controller')
  time.sleep(1)
 sim=e['sim']
 def key(raw,up=False):
  with socket.socket(socket.AF_UNIX) as sock:
   sock.connect(str(Path('amiga/.run/completion-input.sock').resolve()))
   sock.sendall(f'irq-{"up" if up else "down"}:{sim},200588,{raw}'.encode())
   reply=sock.recv(65536).decode();assert reply.startswith('OK '),reply
 def advance(n):
  raw=r.command(f'gdb delete\nbreak *{bad:#x}\nbreak *{e["game_anchor"]:#x}\nignore $bpnum {n-1}\ncontinue\ninfo registers pc\ndelete')
  assert f'{bad:x}' not in raw.split('Continuing.')[-1],raw
 h3raw=r.command(f'gdb printf "H3 %u\\n", *(unsigned int*){base+sym["scene_frame_h3"]:#x}')
 h3=int(re.search(r'H3 (\d+)',h3raw)[1]);rows=[]
 for label,raw,expected in [('rear',0x51,1),('left',0x52,2),('right',0x53,3),('front',0x50,0)]:
  key(raw);advance(2);key(raw,True);advance(4)
  check=r.command(f'gdb printf "VIEW %u ACTIVE %u\\n", *(unsigned short*){h3+0x6712:#x}, *(unsigned short*){base+sym["scene_frame_active"]:#x}')
  view,active=map(int,re.search(r'VIEW (\d+) ACTIVE (\d+)',check).groups())
  assert view==expected and active==0,check
  r.command('shot '+str((out/(label+'.png')).resolve()))
  rows.append(dict(view=label,passed=True));print(label,'passed',flush=True)
 key(0x40);advance(6);r.command('shot '+str((out/'firing.png').resolve()));key(0x40,True);advance(4)
 (out/'transitions.json').write_text(json.dumps(rows,indent=2)+'\n')
 subprocess.run([sys.executable,'-B',str(tracked/'completion_host_input.py'),'quit'],check=True);host.wait(timeout=20)
r.command('shot '+str((out/'final.png').resolve()));r.command('quit')
print('SCENE TWINS PASS',flush=True)
