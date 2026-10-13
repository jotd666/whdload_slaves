"""LLDB-side native key queue writes; no target expression evaluation."""
import lldb,struct
_mapping=None

def map_ram(ps):
 global _mapping
 p=lldb.debugger.GetSelectedTarget().GetProcess()
 regs=p.GetMemoryRegions();err=lldb.SBError()
 pattern=b''.join(b'\x4e\xf9'+struct.pack('>I',ps+off) for off in (0x2b4f4,0x26e8,0x7e24))
 for i in range(regs.GetSize()):
  reg=lldb.SBMemoryRegionInfo();regs.GetMemoryRegionAtIndex(i,reg)
  lo,hi=reg.GetRegionBase(),reg.GetRegionEnd()
  if not reg.IsReadable() or not reg.IsWritable() or not 512*1024 <= hi-lo <= 512*1024*1024:continue
  for at in range(lo,hi,1024*1024):
   b=p.ReadMemory(at,min(1024*1024+len(pattern),hi-at),err)
   if not err.Success():continue
   pos=b.find(pattern)
   while pos>=0:
    host=at+pos
    other=p.ReadMemory(host-0x15b3a+0x2b4f4,4,err)
    if err.Success() and other==b'\x30\x3c\0\0':
     _mapping=host-(ps+0x15b3a)
     print('RAM_MAP',hex(_mapping),flush=True);return
    pos=b.find(pattern,pos+1)
 raise RuntimeError('Live PS RAM mapping not found')

def valid_module(p,base,bitmap):
 if bitmap not in (0x2ba5c,0x30f8c):raise ValueError('Unsupported keyboard bitmap')
 off,target=(0x15b3a,0x2b4f4) if bitmap==0x2ba5c else (0x1ef92,0x309cc)
 err=lldb.SBError()
 value=p.ReadMemory(_mapping+base+off,6,err)
 return err.Success() and value==b'\x4e\xf9'+struct.pack('>I',base+target)

def key(base,bitmap,raw,repeat=1):
 if _mapping is None:raise RuntimeError('Map RAM first')
 p=lldb.debugger.GetSelectedTarget().GetProcess();err=lldb.SBError()
 if not 0 <= raw < 128 or not 1 <= repeat <= 32 or not valid_module(p,base,bitmap):raise ValueError('Invalid keyboard owner/key')
 count=p.ReadMemory(_mapping+base+bitmap+0x80,2,err)
 if not err.Success() or count!=b'\0\0':raise ValueError('Native queue is not empty')
 for address,data in [(base+bitmap-0x40,struct.pack('>H',raw)*repeat),(base+bitmap+0x80,struct.pack('>H',repeat*2)),(base+bitmap+raw,b'\1')]:
  n=p.WriteMemory(_mapping+address,data,err)
  if not err.Success() or n!=len(data):raise RuntimeError(str(err))
 print('KEY_QUEUED',hex(raw),'count',repeat,flush=True)

def release(base,bitmap,raw):
 err=lldb.SBError();p=lldb.debugger.GetSelectedTarget().GetProcess()
 if not valid_module(p,base,bitmap):
  print('Old keyboard owner unloaded; no release write',flush=True);return
 if p.WriteMemory(_mapping+base+bitmap+raw,b'\0',err)!=1:raise RuntimeError(str(err))


def irq_key(raw, released=False):
 """Queue a hardware key for the emulator's CIA producer, while host is stopped.

 Resolve local keybuf symbols from the running profiling executable. Never call
 target functions or write guest keyboard/simulation state on this path.
 """
 if not 0 <= raw < 128:raise ValueError('Invalid raw key')
 target=lldb.debugger.GetSelectedTarget();p=target.GetProcess()
 if p.GetState()!=lldb.eStateStopped:raise RuntimeError('Stop the owned emulator first')
 found={}
 # The keyboard producer belongs to the emulator executable, not its frameworks.
 for module in (target.GetModuleAtIndex(0),):
  for symbol in module:
   name=symbol.GetName() or ''
   if name in ('kpb_first','kpb_last','keybuf','_ZL9kpb_first','_ZL8kpb_last','_ZL6keybuf'):
    name=name.split('kpb_')[-1] if 'kpb_' in name else 'buffer'
    found.setdefault(name,[]).append(symbol.GetStartAddress().GetLoadAddress(target))
 if len(found.get('first',[]))==1 and len(found.get('last',[]))==1:
  first,last=found['first'][0],found['last'][0]
  buffers=[x for x in found.get('buffer',[]) if 0 < x-first < 4096]
  if last!=first+4 or len(buffers)!=1:raise RuntimeError('Unexpected native keyboard layout')
 else:
  # The installed x86 profiling build is stripped. Match its actual producer
  # instructions before using the RIP-relative addresses they encode.
  module=target.GetModuleAtIndex(0);header=module.GetObjectFileHeaderAddress()
  slide=header.GetLoadAddress(target)-header.GetFileAddress()
  err=lldb.SBError()
  signature=bytes.fromhex('486305f33d1702') # MOVSXD kpb_first(%rip),%rax
  if p.ReadMemory(slide+0x2418e6,len(signature),err)!=signature or not err.Success():
   raise RuntimeError('Unsupported stripped emulator keyboard producer')
  signature=bytes.fromhex('488d15c93d1702893c82890da03d1702')
  if p.ReadMemory(slide+0x241930,len(signature),err)!=signature or not err.Success():
   raise RuntimeError('Unexpected keyboard buffer publication instructions')
  first,last=slide+0x23b56e0,slide+0x23b56e4
  buffers=[slide+0x23b5700]
 err=lldb.SBError();data=p.ReadMemory(first,8,err)
 if not err.Success():raise RuntimeError(str(err))
 head,tail=struct.unpack('<II',data)
 if not 0<=head<256 or not 0<=tail<256:raise RuntimeError('Invalid native keyboard indices')
 next_head=(head+1)%256
 if next_head==tail:raise RuntimeError('Native hardware key queue full')
 for address,data in [(buffers[0]+head*4,struct.pack('<I',(raw<<1)|bool(released))),
                      (first,struct.pack('<I',next_head))]:
  if p.WriteMemory(address,data,err)!=len(data) or not err.Success():raise RuntimeError(str(err))
 print('IRQ_KEY',hex(raw),'up' if released else 'down',flush=True)
