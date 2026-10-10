"""Inventory quiescent native overlay pixels without inferring a coverage mask."""
import argparse
import json
from pathlib import Path
from render_mutations import Snapshot,region


def changed_pixels(before,after,pitch,plane_size,depth):
    if min(pitch,plane_size,depth)<=0:raise ValueError('Nonpositive planar geometry')
    if len(before)!=len(after) or len(before)!=plane_size*depth or plane_size%pitch:
        raise ValueError('Invalid planar payload')
    changed=[]
    for offset in range(plane_size):
        difference=0
        for plane in range(depth):
            at=plane*plane_size+offset
            difference |= before[at]^after[at]
        for bit in range(8):
            if difference & (128>>bit):changed.append(((offset%pitch)*8+bit,offset//pitch))
    bounds=None if not changed else [min(x for x,y in changed),min(y for x,y in changed),max(x for x,y in changed),max(y for x,y in changed)]
    return dict(changed_pixels=len(changed),bounds=bounds)


def audit(path):
    metadata=json.loads(path.read_text());root=path.parent;h3=metadata['h3'];results=[]
    for frame in metadata['frames']:
        a,b=frame['before'],frame['after']
        if a['dmacon']&0x4000 or b['dmacon']&0x4000:raise ValueError('Active blitter at snapshot')
        if (a['program'],a['count'])!=(b['program'],b['count']):raise ValueError('Program identity changed')
        before=Snapshot(root,a['banks']);after=Snapshot(root,b['banks'])
        descriptor={}
        for name,offset,length in [('destination',0x9d72,4),('plane_size',0x9d34,4),('depth',0x9d3c,2),('pitch',0x9d42,2)]:
            raw=before.read(h3+offset,length)
            if raw!=after.read(h3+offset,length):raise ValueError('Destination geometry changed')
            descriptor[name]=int.from_bytes(raw,'big')
        if (descriptor['pitch'],descriptor['plane_size'],descriptor['depth'])!=(40,8000,5):
            raise ValueError('Unsupported framebuffer geometry')
        dest=descriptor.pop('destination');size=descriptor['plane_size']*descriptor['depth']
        old=before.read(dest,size);new=after.read(dest,size)
        results.append(dict(index=frame['index'],program=a['program'],destination=dest,
                            **changed_pixels(old,new,**descriptor),
                            changed_bytes=sum(x!=y for x,y in zip(old,new)),
                            h3_changes=region(before.read(h3,0xbd0c),after.read(h3,0xbd0c))))
    destinations={r['destination'] for r in results}
    if len(destinations)!=2 or {(r['program'],r['destination']) for r in results}!={(program,dest) for program in (3,4) for dest in destinations}:
        raise ValueError('Need front programs on both physical buffers')
    return dict(sha256=metadata['sha256'],results=results,
                limitation='Changed pixels are not a written-pixel/transparency mask. Native state changes remain unfiltered; no cache equivalence or performance claim.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=audit(a.capture);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print([{k:v for k,v in r.items() if k not in ('h3_changes','destination')} for r in result['results']])
