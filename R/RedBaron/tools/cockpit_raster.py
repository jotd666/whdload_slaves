"""Independent raster reference for the observed front cockpit programs.

Unsupported bitmap orientation, clipping, or mixed rectangle colours reject;
this is an offline model, not a runtime cache.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from cockpit_program import decode, colour_state
from overlay_snapshot import audit as check_snapshots
from render_mutations import Snapshot


def line_points(x0,y0,x1,y1):
    dx=abs(x1-x0);dy=-abs(y1-y0);sx=1 if x0<x1 else -1;sy=1 if y0<y1 else -1
    error=dx+dy
    while True:
        yield x0,y0
        if (x0,y0)==(x1,y1):return
        twice=2*error
        if twice>=dy:error+=dy;x0+=sx
        if twice<=dx:error+=dx;y0+=sy


def render(read,h3,index,background):
    def uint(at,n):return int.from_bytes(read(at,n),'big')
    if index not in (3,4):raise ValueError('Only audited front programs supported')
    if (uint(h3+0x9d34,4),uint(h3+0x9d3c,2),uint(h3+0x9d42,2))!=(8000,5,40):raise ValueError('Unsupported screen geometry')
    if len(background)!=40000:raise ValueError('Invalid screen payload')
    pointer=uint(h3+0x7b52+4*index,4);program=decode(read,pointer)
    clip=struct.unpack('>4h',read(h3+0x9d48,8));clipped=uint(h3+0x9d46,2)
    result=bytearray(background);coverage=bytearray(8000)
    fg=uint(h3+0x9d52,2);bg=uint(h3+0x9d50,2)
    def point(x,y,colour):
        if not (0<=x<320 and 0<=y<200):raise ValueError('Out-of-screen primitive')
        if clipped and not (clip[0]<=x<=clip[1] and clip[2]<=y<=clip[3]):raise ValueError('Clipped primitive needs separate native model')
        pos=y*40+x//8;bit=128>>(x%8);coverage[pos]|=bit
        for plane in range(5):
            at=plane*8000+pos
            result[at]=(result[at]|bit) if colour&(1<<plane) else (result[at]&(~bit&255))
    for command in program['commands']:
        args=command['args'];kind=command['kind']
        if kind=='colours':
            _,fg,bg=colour_state(read,h3,*args)
        elif kind=='rectangle':
            if fg!=bg:raise ValueError('Mixed rectangle edge colours unsupported')
            x,y,w,h=args
            for yy in range(y,y+h):
                for xx in range(x,x+w):point(xx,yy,bg)
        elif kind=='line':
            for x,y in line_points(*args):point(x,y,fg)
        elif kind=='bitmap':
            table=uint(h3+0x3b02+command['image_set']*4,4)
            image=uint(table+command['image']*4,4)
            data,mask,w,h,size,orientation=struct.unpack('>IIHHIH',read(image,18))
            if orientation or command['mode']:raise ValueError('Oriented bitmap unsupported')
            pitch=((w+15)//16)*2
            if size!=pitch*h:raise ValueError('Unexpected bitmap plane size')
            pixels=read(data,size*5);bits=read(mask,(pitch+2)*h)
            for y in range(h):
                for x in range(pitch*8):
                    bit=128>>(x%8)
                    if bits[y*(pitch+2)+x//8]&bit:
                        colour=sum((1<<plane) for plane in range(5) if pixels[plane*size+y*pitch+x//8]&bit)
                        point(args[0]+x,args[1]+y,colour)
    return bytes(result),bytes(coverage)


def composite(background,image,mask):
    if not mask or len(background)!=len(image) or len(image)%len(mask):
        raise ValueError('Invalid overlay geometry')
    return bytes((old & (~mask[i%len(mask)]&255)) | (pixel & mask[i%len(mask)])
                 for i,(old,pixel) in enumerate(zip(background,image)))


def cache_geometry(mask,pitch=40,depth=5):
    if pitch<=0 or pitch%2 or depth<=0 or not mask or len(mask)%pitch:raise ValueError('Invalid coverage geometry')
    occupied=[i for i,value in enumerate(mask) if value]
    if not occupied:raise ValueError('Empty overlay')
    # Both X ends are rounded to complete 16-pixel blitter words.
    left=min(i%pitch for i in occupied)//2*2
    right=(max(i%pitch for i in occupied)//2+1)*2
    top=min(occupied)//pitch;bottom=max(occupied)//pitch+1
    plane=(right-left)*(bottom-top)
    return dict(x=left*8,y=top,width=(right-left)*8,height=bottom-top,
                plane_bytes=plane,image_bytes=plane*depth,mask_bytes=plane,
                total_chip_bytes=plane*(depth+1))


def audit(path):
    check_snapshots(path)
    meta=json.loads(path.read_text());root=path.parent;h3=meta['h3'];checks=[]
    entry=json.loads((root/'entry.json').read_text())
    if entry['slave_sha256']!=meta['sha256'] or entry['sim_sha256']!='e9b3889bc6f177e0bcfc74987665cdafbccd984b3a031bdd1f98f6c445dd8839':
        raise ValueError('Capture build/original executable mismatch')
    for row in meta['frames']:
        before=Snapshot(root,row['before']['banks']);after=Snapshot(root,row['after']['banks'])
        if row['before']['dmacon']&0x4000 or row['after']['dmacon']&0x4000:raise ValueError('Busy blitter')
        dest=int.from_bytes(before.read(h3+0x9d72,4),'big')
        original=before.read(dest,40000);native=after.read(dest,40000)
        expected,coverage=render(before.read,h3,row['before']['program'],original)
        mismatch=[i for i,(a,b) in enumerate(zip(expected,native)) if a!=b]
        if mismatch:raise ValueError(f"Program {row['before']['program']}: {len(mismatch)} differing bytes; first {mismatch[:12]}")
        dependencies={}
        def read_dependency(address,size):
            value=before.read(address,size);dependencies[(address,size)]=value;return value
        image,mask=render(read_dependency,h3,row['before']['program'],bytes(40000))
        digest=hashlib.sha256()
        for (address,size),value in sorted(dependencies.items()):
            digest.update(struct.pack('>II',address,size)+value)
        if mask!=coverage or composite(original,image,mask)!=native:
            raise ValueError('Cached compositing differs from native output')
        checks.append(dict(program=row['before']['program'],covered_pixels=sum(v.bit_count() for v in coverage),bytes_compared=len(native),cache=cache_geometry(mask),dependency_ranges=len(dependencies),dependency_sha256=digest.hexdigest()))
    if not checks:raise ValueError('No native overlay samples')
    return dict(sha256=meta['sha256'],checks=checks,limitation='Observed front programs only; no runtime cache or state-restoration equivalence.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=audit(a.capture);a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
