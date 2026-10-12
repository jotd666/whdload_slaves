"""Read-only guest observations and bounded stepping for D5 native-input checks."""
import json,os,re,signal,subprocess,sys,threading,time
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/'tools'))
import route_status as r

class Live:
    def __init__(self,out):
        self.out=Path(out)
        m=json.loads((self.out/'runtime.json').read_text())
        self.sim,self.h3,self.base=m['sim'],m['h3'],m['slave']
        self.syms={m[1]:int(m[2],16) for line in (self.out/'slave.lst').read_text(encoding='latin1').splitlines() if (m:=re.match(r'^(\w+)\s+00:([0-9a-fA-F]+)\s*$',line))}
        self.state=self.sym('time_loop_state')
    def attach_input(self):
        with (self.out/'input.log').open('w') as log:
            host=subprocess.Popen([sys.executable,'-B',str(Path(__file__).with_name('completion_host_input.py')),'--serve','--irq-only'],stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
        (self.out/'input-server.pid').write_text(str(host.pid))
        deadline=time.monotonic()+1000
        while 'INPUT READY' not in (self.out/'input.log').read_text():
            if host.poll() is not None or time.monotonic()>deadline:
                raise RuntimeError('Input attachment incomplete; inspect existing process before retrying')
            time.sleep(1)
    def sym(self,name):return self.base+self.syms[name]
    def value(self,expr):
        text=r.command('gdb p/u '+expr)
        match=re.search(r'\$\d+ = (\d+)',text)
        if not match:raise ValueError(text)
        return int(match[1])
    def u(self,at):return self.value(f'*(unsigned int*){at:#x}')
    def w(self,at):return self.value(f'*(unsigned short*){at:#x}')
    def irq(self,raw,up=False):
        subprocess.run([sys.executable,'-B',str(Path(__file__).parent/'completion_host_input.py'),f'irq-{"up" if up else "down"}:{self.sim},200588,{raw}'],check=True,stdout=subprocess.DEVNULL)
    def bounded_command(self,command):
        # A flight VBL disappears when sim unloads. Also bound host time so a
        # stale guest address cannot strand a test indefinitely.
        pid=int(Path('amiga/.run/gdb.pid').read_text())
        identity=subprocess.check_output(['ps','-p',str(pid),'-o','command='],text=True)
        if 'm68k-amiga-elf-gdb -q -nx' not in identity:raise RuntimeError('Unexpected owned debugger')
        expired=threading.Event()
        def interrupt():
            expired.set()
            current=subprocess.run(['ps','-p',str(pid),'-o','command='],capture_output=True,text=True)
            if current.stdout==identity:os.kill(pid,signal.SIGINT)
        timer=threading.Timer(120,interrupt);timer.start()
        try:result=r.command(command)
        finally:timer.cancel()
        if expired.is_set():raise TimeoutError('Owned D5 debugger exceeded the host-time bound')
        return result
    def until(self,at,fields=2000):
        cmd=['delete','set $d5f=0',f'break *{at:#x}',f'break *{self.sim+0x2d34e:#x}','commands','silent','set $d5f=$d5f+1',f'if $d5f < {fields}','continue','end','end','continue','printf "D5STOP %u %u\\n", $pc, $d5f','delete']
        log=self.bounded_command('gdb '+'\n'.join(cmd));match=re.search(r'D5STOP (\d+) (\d+)',log)
        if not match or int(match[1])!=at:raise RuntimeError('Bounded target not reached: '+log[-1200:])
        return int(match[2])
    def fields(self,count):
        return self.bounded_command(f'gdb delete\nbreak *{self.sim+0x2d34e:#x}\nignore $bpnum {count-1}\ncontinue\ndelete')
    def snapshot(self):
        return dict(cia=self.u(self.sim+0x30006),cursor=self.u(self.state+20),steps=self.u(self.state+28),active=self.u(self.state+40),paused=self.u(self.state+44),due=self.w(self.state+24),quantum=self.w(self.sym('time_loop_quantum')))
