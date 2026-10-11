"""Check private native compositor tests against an independent host reference."""
import argparse
import json
from pathlib import Path
from cockpit_raster import composite

CASES=[(12,30,64,71),(14,31,64,72)]


def initial():
    result=bytearray();state=0x5a
    for _ in range(45240):
        result.append(state)
        state=((state<<1) ^ (0x11d if state&128 else 0)) & 255
    return bytes(result)


def expected(case):
    words,height,x,y=CASES[case-1];pitch=words*2;size=pitch*height
    raw=initial();result=bytearray(raw)
    image=raw[40016:40016+5*size];mask=raw[44356:44356+size]
    locations=[16+plane*8000+(y+row)*40+x//8+column
               for plane in range(5) for row in range(height) for column in range(pitch)]
    old=bytes(raw[i] for i in locations)
    composed=composite(old,image,mask)
    for offset,value in zip(locations,composed):result[offset]=value
    combinations=set()
    for i,(a,b) in enumerate(zip(image,old)):
        m=mask[i%size]
        combinations.update((((m>>bit)&1)<<2)|(((a>>bit)&1)<<1)|((b>>bit)&1) for bit in range(8))
    if combinations!=set(range(8)):raise ValueError('Incomplete mask/image/destination truth-table coverage')
    return bytes(result)


def audit(path):
    capture=json.loads(path.read_text());root=path.parent
    if [r['case'] for r in capture['cases']]!=[1,2]:raise ValueError('Missing native test case')
    for row in capture['cases']:
        case=row['case']
        if row['count']!=case or row['checked']!=case*45240 or row['dmacon']&0x4000:
            raise ValueError('Incomplete native comparison or busy blitter')
        reference=expected(case)
        if (root/f'blit-{case}-chip.bin').read_bytes()!=reference:
            raise ValueError('Native chip pixels/source/mask/guards differ from host reference')
        if (root/f'blit-{case}-cpu.bin').read_bytes()!=reference[16:40016]:
            raise ValueError('Native CPU oracle differs from host reference')
    if 'FREED 0 0 2 90480' not in (root/'blit-freed.txt').read_text():
        raise ValueError('Private buffers were not observed freed')
    return dict(sha256=capture['sha256'],cases=2,chip_bytes_checked=90480,cpu_reference_bytes_checked=80000,
                limitation='Synthetic private-buffer compositor check; not cache integration, game-pixel equivalence, CPU capacity, or FPS acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=audit(a.capture);a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
