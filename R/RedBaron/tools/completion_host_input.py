"""Owned-emulator native keyboard queue control through LLDB, explicitly user-authorized."""
import argparse,subprocess,sys,time,socket,json,os
from pathlib import Path
HARNESS=Path(__file__).resolve().parents[3]/'tmp/dev'
os.chdir(HARNESS)
sys.path.insert(0,str(HARNESS/'tools'))
import route_status as r
from redbaron import Gdb
p=argparse.ArgumentParser();p.add_argument('--serve',action='store_true');p.add_argument('--ps',type=lambda x:int(x,0));p.add_argument('--mapping',type=lambda x:int(x,0));p.add_argument('key',nargs='?');a=p.parse_args()
if a.serve and a.ps is None and a.mapping is None:p.error('--serve requires --ps or an observed --mapping for this process')
if not a.serve and a.key is None:p.error('Supply base,bitmap,raw or quit')
SOCK=Path('amiga/.run/completion-input.sock').resolve()
if not a.serve:
 with socket.socket(socket.AF_UNIX) as s:
  s.connect(str(SOCK));s.sendall(a.key.encode());answer=s.recv(65536).decode();print(answer)
 raise SystemExit(0 if answer.startswith(('OK ','bye')) else 1)
pid=Path('amiga/.run/fsuae.pid').read_text().strip()
owned=subprocess.check_output(['ps','-p',pid,'-o','command='],text=True)
assert '--base_dir='+str(Path.cwd()/'amiga/.run/fsuae') in owned
r.command('stop');r.command('gdb delete')
class Host:
 read_until=Gdb.read_until
 def __init__(self):
  self.p=subprocess.Popen(['lldb','-O','settings set target.preload-symbols false','-O',
                            'settings set target.memory-module-load-level minimal','-p',pid],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,bufsize=0);self.buf=b''
 def cmd(self,s):
  self.p.stdin.write((s+'\nscript print("@@REDBARON-DONE@@")\n').encode())
  out=self.read_until('@@REDBARON-DONE@@\n',900)
  if 'error:' in out or 'Traceback (most recent call last)' in out:raise RuntimeError(out)
  return out
h=Host();print(h.cmd('process status'),flush=True)
print(h.cmd('script lldb.debugger.SetAsync(True)'),flush=True)
print(h.cmd('command script import '+json.dumps(str(Path(__file__).with_name('completion_lldb_input.py').resolve()))),flush=True)
if a.mapping is None:
 print(h.cmd(f'script completion_lldb_input.map_ram({a.ps})'),flush=True)
else:
 print(h.cmd(f'script completion_lldb_input._mapping={a.mapping}'),flush=True)
print(h.cmd('process continue'),flush=True)
SOCK.unlink(missing_ok=True)
srv=socket.socket(socket.AF_UNIX);srv.bind(str(SOCK));srv.listen(1)
print('INPUT READY',flush=True)
while True:
 c,_=srv.accept();key=c.recv(100).decode()
 try:
  mode,payload=key.split(':',1) if ':' in key else ('tap',key)
  if mode not in ('tap','queue','release','burst'):raise ValueError('Unknown input mode')
  if key!='quit':
   parts=[int(x,0) for x in payload.split(',')]
   if len(parts)!=(4 if mode=='burst' else 3):raise ValueError('Invalid keyboard command')
   base,bitmap,raw=parts[:3];repeat=parts[3] if mode=='burst' else 1
  r.command('stop');h.cmd('process interrupt')
  while 'stopped' not in h.cmd('process status'):time.sleep(.1)
  if key=='quit':
   h.cmd('process detach');h.p.stdin.write(b'quit\n');c.sendall(b'bye');c.close();break
  if mode=='release':
   result=h.cmd(f'script completion_lldb_input.release({base},{bitmap},{raw})')
  else:
   result=h.cmd(f'script completion_lldb_input.key({base},{bitmap},{raw},{repeat})')
  if mode in ('queue','release'):
   h.cmd('process continue');c.sendall(('OK '+key+' '+result).encode());c.close();continue
  h.cmd('process continue');r.command('cont');time.sleep(.15)
  r.command('stop');h.cmd('process interrupt')
  while 'stopped' not in h.cmd('process status'):time.sleep(.1)
  h.cmd(f'script completion_lldb_input.release({base},{bitmap},{raw})')
  h.cmd('process continue');r.command('cont')
  c.sendall(('OK '+key+' '+result).encode())
 except Exception as ex:
  try:
   if 'stopped' in h.cmd('process status'):h.cmd('process continue')
  except Exception:pass
  c.sendall(('ERROR '+str(ex)).encode())
 c.close()
