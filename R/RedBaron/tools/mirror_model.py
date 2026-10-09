"""Independent host models of sim:304d0, including padding bits and regenerated mask.
The descriptor's plane-size field is not consumed by this routine: the source planes
are contiguous rounded-width rows. Dimensions here cover the approved test domain.
"""
import struct

def reverse_word(word,previous=0):
    """Sixteen LSR.W/ROXL.W pairs. Return word and final X (not a full CCR model)."""
    word&=0xffff;result=previous&0xffff;x=0
    for _ in range(16):
        carry=word&1;word>>=1
        x=result>>15;result=((result<<1)|carry)&0xffff
    return result,x

def reverse_byte(value):
    return sum(((value>>i)&1)<<(7-i) for i in range(8))

TABLE=bytes(reverse_byte(v) for v in range(256))

def mirror(planes,width,height,depth,table=False):
    if not (1<=width<=320 and 1<=height<=200 and depth in (4,5)):
        raise ValueError('Outside verified dimension domain')
    words=(width+15)//16;stride=words*2
    if len(planes)!=stride*height*depth:raise ValueError('Wrong plane payload size')
    out=bytearray(planes);mask=bytearray((stride+2)*height)
    previous=0
    for plane in range(depth):
        for y in range(height):
            start=(plane*height+y)*stride
            row=planes[start:start+stride]
            if table:
                result=bytes(TABLE[v] for v in reversed(row))
            else:
                stack=[]
                for (word,) in struct.iter_unpack('>H',row):
                    previous,_=reverse_word(word,previous);stack.append(previous)
                result=b''.join(struct.pack('>H',v) for v in reversed(stack))
            out[start:start+stride]=result
            for x,v in enumerate(result):mask[y*(stride+2)+x]|=v
    return bytes(out),bytes(mask)
