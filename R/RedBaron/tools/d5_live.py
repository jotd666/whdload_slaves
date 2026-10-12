"""Read-only guest observations and bounded stepping for D5 native-input checks."""
import json,re,subprocess,sys
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
    def until(self,at,fields=2000):
        cmd=['delete','set $d5f=0',f'break *{at:#x}',f'break *{self.sim+0x2d34e:#x}','commands','silent','set $d5f=$d5f+1',f'if $d5f < {fields}','continue','end','end','continue','printf "D5STOP %u %u\\n", $pc, $d5f','delete']
        log=r.command('gdb '+'\n'.join(cmd));match=re.search(r'D5STOP (\d+) (\d+)',log)
        if not match or int(match[1])!=at:raise RuntimeError('Bounded target not reached: '+log[-1200:])
        return int(match[2])
    def fields(self,count):
        return r.command(f'gdb delete\nbreak *{self.sim+0x2d34e:#x}\nignore $bpnum {count-1}\ncontinue\ndelete')
    def snapshot(self):
        return dict(cia=self.u(self.sim+0x30006),cursor=self.u(self.state+20),steps=self.u(self.state+28),active=self.u(self.state+40),paused=self.u(self.state+44),due=self.w(self.state+24),quantum=self.w(self.sym('time_loop_quantum')))
