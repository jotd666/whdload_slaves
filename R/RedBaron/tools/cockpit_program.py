"""Decode the observed front-cockpit drawing programs for cache dependency audit.

This decodes the observed front commands, including program 2's counted
polygon. Raster/cache eligibility remains separate; unknown commands fail closed.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from render_mutations import Snapshot


def signed_byte(value):
    return value-256 if value & 128 else value


def colour_state(read,h3,foreground,background):
    # Native stores first sign-extend each argument's low byte. Remapping tests
    # the original argument words against sign-extended table bytes.
    pen=signed_byte(foreground & 255) & 65535
    fg=pen;bg=signed_byte(background & 255) & 65535
    for group in range(2):
        selector=signed_byte(read(h3+0x3abf+group,1)[0])
        for item in range(4):
            original=signed_byte(read(h3+0x3ab7+group*4+item,1)[0]) & 65535
            mapped=signed_byte(read(h3+0x101d+selector*4+item,1)[0]) & 65535
            if original==foreground:fg=mapped
            if original==background:bg=mapped
    return pen,fg,bg


def decode(read, address, max_bytes=16384):
    start=address;commands=[];image_set=None;image=None
    def words(count):
        nonlocal address
        if address-start+count*2>max_bytes:raise ValueError('Unterminated cockpit program')
        raw=read(address,count*2)
        if len(raw)!=count*2:raise ValueError('Truncated cockpit program')
        address+=count*2
        return list(struct.unpack('>'+str(count)+'H',raw))
    while True:
        offset=address-start;opcode=words(1)[0]
        if opcode==0x0ff0:
            return dict(bytes=address-start,commands=commands,
                        final_image_set=image_set,final_image=image)
        if opcode==0xaf2f:
            count=words(1)[0]
            if not 3<=count<=64:raise ValueError('Unsupported cockpit polygon count')
            args=[count,*words(count*2)];kind='polygon'
        elif opcode==0x2002:
            args=words(2);kind='colours'
        elif opcode in (0xa104,0xa0a4):
            args=words(4);kind='rectangle' if opcode==0xa104 else 'line'
        elif opcode==0x1051:
            args=words(1);kind='image_set';image_set=args[0]
        elif opcode==0x1031:
            args=words(1);kind='image';image=args[0]
        elif opcode&0xff0f==0xa502:
            args=words(2);kind='bitmap'
            if image_set is None or image is None:raise ValueError('Bitmap depends on incoming resource selection')
        else:raise ValueError(f'Unsupported cockpit command {opcode:04x} at byte {offset}')
        if kind in ('image_set','image') and args[0]>=32768:
            raise ValueError('Negative native resource index is outside audited programs')
        record=dict(offset=offset,opcode=f'{opcode:04x}',kind=kind,args=args)
        if kind=='bitmap':record.update(image_set=image_set,image=image,mode=(opcode>>4)&15)
        commands.append(record)


def audit(root):
    entry=json.loads((root/'entry.json').read_text())
    if entry['sim_sha256']!='e9b3889bc6f177e0bcfc74987665cdafbccd984b3a031bdd1f98f6c445dd8839':
        raise ValueError('Unsupported sim executable')
    p=root/'players';meta=json.loads((p/'initial.json').read_text());memory=Snapshot(p,meta['banks'])
    result={}
    for index in (3,4):
        pointer=int.from_bytes(memory.read(meta['h3']+0x7b52+4*index,4),'big')
        program=decode(memory.read,pointer)
        program['sha256']=hashlib.sha256(memory.read(pointer,program['bytes'])).hexdigest()
        program['counts']={kind:sum(c['kind']==kind for c in program['commands']) for kind in sorted({c['kind'] for c in program['commands']})}
        result[str(index)]=program
    return dict(slave_sha256=entry['slave_sha256'],programs=result,
                limitation='Command inventory only. Colour commands call native helpers; resource contents, clip/mode state, overlap, side effects and pixel equivalence must be validated before caching.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=audit(a.capture);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print({k:(v['bytes'],v['counts']) for k,v in result['programs'].items()})
