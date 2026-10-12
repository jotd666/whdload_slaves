"""Bounded direct scene primitive twins; run from tmp/dev after env.sh."""
import json, os, re, subprocess, sys
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/'tools'))
from completion_machines import environment
import route_status as r
import argparse
p=argparse.ArgumentParser(description=__doc__);p.add_argument('out',type=Path);p.add_argument('--machine',choices=('030','040','060'),default='060');p.add_argument('--bank',action='store_true');a=p.parse_args()
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
r.command('shot '+str((out/'final.png').resolve()));r.command('quit')
print('SCENE TWINS PASS',flush=True)
