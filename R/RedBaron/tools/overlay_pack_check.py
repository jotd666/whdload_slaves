"""Check native packed overlays and replay them on independent host backgrounds."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from cockpit_raster import render,cache_geometry
from overlay_mask_check import check as check_masks
from render_mutations import Snapshot


def pack(image,mask,capacity=5208):
    if not 0 < capacity <= 48000:raise ValueError("Invalid cache capacity")
    if len(image)!=40000 or len(mask)!=8000:raise ValueError('Invalid full planar input')
    g=cache_geometry(mask)
    left,top,width,height=g['x']//8,g['y'],g['width']//8,g['height']
    if g['total_chip_bytes']>capacity:raise ValueError('Packed overlay exceeds capacity')
    offsets=[y*40+x for y in range(top,top+height) for x in range(left,left+width)]
    payload=bytes(image[p*8000+i]&mask[i] for p in range(5) for i in offsets)+bytes(mask[i] for i in offsets)
    return (left,top,width,height,g['plane_bytes'],len(payload)),payload


def replay(background,descriptor,payload,capacity=5208):
    if not 0 < capacity <= 48000:raise ValueError("Invalid cache capacity")
    left,top,width,height,plane,total=descriptor
    if (len(background)!=40000 or left<0 or top<0 or width<=0 or height<=0 or
        left%2 or width%2 or left+width>40 or top+height>200 or
        plane!=width*height or total!=6*plane or total>capacity or len(payload)!=total):
        raise ValueError('Invalid packed geometry')
    out=bytearray(background);mask=payload[5*plane:]
    for p in range(5):
        for y in range(height):
            start=p*8000+(top+y)*40+left
            for x in range(width):
                i=y*width+x;m=mask[i]
                out[start+x]=(out[start+x] & (255^m)) | (payload[p*plane+i] & m)
    return bytes(out)


def background(seed):
    out=bytearray()
    for _ in range(40000):
        out.append(seed)
        seed=((seed<<1)^ (0x1d if seed&128 else 0))&255
    return bytes(out)


def check(path):
    masks=check_masks(path);meta=json.loads(path.read_text());root=path.parent;rows=[];previous={}
    backgrounds=(bytes(40000),bytes([255])*40000,background(0x5a))
    for i,frame in enumerate(meta['frames']):
        header=struct.unpack('>4I6H',(root/frame['pack']['header']).read_bytes())
        pointer,status,program,count=header[:4];descriptor=header[4:]
        if not pointer or status!=1 or program!=frame['before']['program'] or count!=i+1:
            raise ValueError('Native pack identity/status differs')
        before=Snapshot(root,frame['before']['banks']);after=Snapshot(root,frame['after']['banks'])
        destination=int.from_bytes(before.read(meta['h3']+0x9d72,4),'big')
        _,mask=render(before.read,meta['h3'],program,bytes(40000))
        wanted_descriptor,payload=pack(after.read(destination,40000),mask)
        if descriptor!=wanted_descriptor:raise ValueError('Native packed geometry differs')
        expected=bytearray(bytes.fromhex('a55ac33c')*1310)
        expected[16:16+len(payload)]=payload
        actual=(root/frame['pack']['file']).read_bytes()
        if actual!=expected:raise ValueError('Native packed image, mask, unused bytes or guards differ')
        native_payload=actual[16:16+len(payload)]
        for bg in backgrounds:
            reference,_=render(before.read,meta['h3'],program,bg)
            if replay(bg,descriptor,native_payload)!=reference:
                raise ValueError('Native packed data retains background or differs on replay')
        if program in previous and previous[program]!=native_payload:
            raise ValueError('Packed overlay differs between physical buffers')
        previous[program]=native_payload
        rows.append(dict(program=program,descriptor=descriptor,payload_sha256=hashlib.sha256(native_payload).hexdigest(),
                         checked_allocation_bytes=len(actual),host_replay_bytes=120000))
    return dict(sha256=masks['sha256'],cases=rows,
                scope='Private native packing plus host replay on three backgrounds. Original native drawing still runs. No live cache hits, hardware replay, cost or W6 completion claim.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();r=check(a.capture);a.out.write_text(json.dumps(r,indent=2)+'\n');print(r)
