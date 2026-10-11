"""LLDB-side native key queue writes; no target expression evaluation."""
import lldb,struct
_mapping=None

def map_ram(ps):
 global _mapping
 p=lldb.debugger.GetSelectedTarget().GetProcess()
 regs=p.GetMemoryRegions();err=lldb.SBError();hits=[]
 pattern=b''.join(b'\x4e\xf9'+struct.pack('>I',ps+off) for off in (0x2b4f4,0x26e8,0x7e24))
 for i in range(regs.GetSize()):
  reg=lldb.SBMemoryRegionInfo();regs.GetMemoryRegionAtIndex(i,reg)
  lo,hi=reg.GetRegionBase(),reg.GetRegionEnd()
  if not reg.IsReadable() or not reg.IsWritable() or hi-lo>512*1024*1024:continue
  for at in range(lo,hi,1024*1024):
   b=p.ReadMemory(at,min(1024*1024+len(pattern),hi-at),err)
   if not err.Success():continue
   pos=b.find(pattern)
   while pos>=0:
    host=at+pos
    other=p.ReadMemory(host-0x15b3a+0x2b4f4,4,err)
    if err.Success() and other==b'\x30\x3c\0\0':hits.append(host-(ps+0x15b3a))
    pos=b.find(pattern,pos+1)
 hits=sorted(set(hits))
 if len(hits)!=1:raise RuntimeError('Ambiguous RAM map '+repr(hits))
 _mapping=hits[0];print('RAM_MAP',hex(_mapping),flush=True)

def valid_module(p,base,bitmap):
 if bitmap not in (0x2ba5c,0x30f8c):raise ValueError('Unsupported keyboard bitmap')
 off,target=(0x15b3a,0x2b4f4) if bitmap==0x2ba5c else (0x1ef92,0x309cc)
 err=lldb.SBError()
 value=p.ReadMemory(_mapping+base+off,6,err)
 return err.Success() and value==b'\x4e\xf9'+struct.pack('>I',base+target)

def key(base,bitmap,raw):
 if _mapping is None:raise RuntimeError('Map RAM first')
 p=lldb.debugger.GetSelectedTarget().GetProcess();err=lldb.SBError()
 if not 0 <= raw < 128 or not valid_module(p,base,bitmap):raise ValueError('Invalid keyboard owner/key')
 count=p.ReadMemory(_mapping+base+bitmap+0x80,2,err)
 if not err.Success() or count!=b'\0\0':raise ValueError('Native queue is not empty')
 for address,data in [(base+bitmap-0x40,struct.pack('>H',raw)),(base+bitmap+0x80,b'\0\2'),(base+bitmap+raw,b'\1')]:
  n=p.WriteMemory(_mapping+address,data,err)
  if not err.Success() or n!=len(data):raise RuntimeError(str(err))
 print('KEY_QUEUED',hex(raw),flush=True)

def release(base,bitmap,raw):
 err=lldb.SBError();p=lldb.debugger.GetSelectedTarget().GetProcess()
 if not valid_module(p,base,bitmap):
  print('Old keyboard owner unloaded; no release write',flush=True);return
 if p.WriteMemory(_mapping+base+bitmap+raw,b'\0',err)!=1:raise RuntimeError(str(err))
