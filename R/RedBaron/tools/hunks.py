"""Read executable HUNK_CODE/DATA/BSS and HUNK_RELOC32, failing on unknown records."""
from dataclasses import dataclass, field
import struct

@dataclass
class Hunk:
    kind: int
    allocation: int
    data: bytes
    relocations: list = field(default_factory=list)


def read_hunks(raw):
    pos=0
    def word():
        nonlocal pos
        if pos+4>len(raw):raise ValueError('Truncated hunk file')
        result=struct.unpack_from('>I',raw,pos)[0];pos+=4
        return result
    def blob(n):
        nonlocal pos
        if pos+n>len(raw):raise ValueError('Truncated hunk payload')
        result=raw[pos:pos+n];pos+=n
        return result
    if word()!=0x3f3:raise ValueError('Not HUNK_HEADER')
    while (n:=word()):blob(n*4)
    count,first,last=word(),word(),word()
    if first!=0 or last!=count-1:raise ValueError('Only complete zero-based executables supported')
    sizes=[]
    for _ in range(count):
        n=word()
        if n>>30==3:word()  # extended memory attribute
        sizes.append((n&0x3fffffff)*4)
    hunks=[]
    for size in sizes:
        kind=word()&0x3fffffff
        if kind not in (0x3e9,0x3ea,0x3eb):raise ValueError(f'Unsupported hunk {kind:#x}')
        n=word()*4
        if n>size:raise ValueError('Payload exceeds allocation')
        h=Hunk(kind,size,bytes(n) if kind==0x3eb else blob(n))
        while True:
            tag=word()&0x3fffffff
            if tag==0x3f2:break
            if tag==0x3ec:
                while (n:=word()):
                    target=word()
                    if target>=count:raise ValueError('Bad relocation target')
                    for _ in range(n):
                        at=word()
                        if at%2 or at+4>len(h.data):raise ValueError('Bad relocation site')
                        h.relocations.append((at,target))
            elif tag==0x3f1:blob(word()*4)
            elif tag==0x3f0:
                while (n:=word()):blob(n*4);word()
            else:raise ValueError(f'Unsupported record {tag:#x}')
        hunks.append(h)
    if pos!=len(raw):raise ValueError('Trailing executable data')
    return hunks


def relocate(h,bases):
    result=bytearray(h.data)
    for at,target in h.relocations:
        v=struct.unpack_from('>I',result,at)[0]
        struct.pack_into('>I',result,at,(v+bases[target])&0xffffffff)
    return result
