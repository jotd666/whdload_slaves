"""Model h3 drawing-state effects of audited cockpit programs 3 and 4.

No runtime cache is installed. Registers, hardware state and memory outside h3
need separate verification before a cached replacement can be accepted.
"""
import argparse
import hashlib
import json
from pathlib import Path
from cockpit_program import decode, colour_state
from overlay_snapshot import audit
from render_mutations import Snapshot


def expected(read,h3,program):
    if program not in (3,4):raise ValueError('Only audited front programs supported')
    data=bytearray(read(h3,0xbd0c))
    if len(data)!=0xbd0c:raise ValueError('Truncated original h3')
    uint=lambda at,n:int.from_bytes(read(at,n),'big')
    pointer=uint(h3+0x7b52+program*4,4)
    decoded=decode(read,pointer)
    writes=[]
    def put(offset,width,value):
        data[offset:offset+width]=value.to_bytes(width,'big');writes.append([offset,width,value])
    table=None;image=None
    for command in decoded['commands']:
        args=command['args'];kind=command['kind']
        if kind=='colours':
            pen,fg,bg=colour_state(read,h3,*args)
            put(0x4164,2,pen);put(0x9d52,2,fg);put(0x9d50,2,bg)
        elif kind=='image_set':
            table=uint(h3+0x3b02+args[0]*4,4)
            if not table:raise ValueError('Missing native image table')
            put(0x7c22,2,args[0]);put(0x7c24,4,table);put(0x7c2c,4,table)
        elif kind=='image':
            if table is None:raise ValueError('Incoming image table dependency')
            image=uint(table+args[0]*4,4)
            if not image:raise ValueError('Missing native bitmap descriptor')
            put(0x7c28,4,image)
        elif kind=='bitmap':
            if image is None or command['mode']!=0:raise ValueError('Unsupported bitmap mode')
            put(0x7c1c,2,command['mode'])
        elif kind=='rectangle':
            # A104 selects filled mode one at sim:28be8 before drawing.
            # A114 selects outline mode zero; that opcode is not accepted.
            put(0x9d54,2,1)
        elif kind!='line':raise ValueError('Unsupported drawing-state command')
    return bytes(data),writes


def check(path):
    audit(path)
    root=path.parent;metadata=json.loads(path.read_text());entry=json.loads((root/'entry.json').read_text())
    if entry['sim_sha256']!='e9b3889bc6f177e0bcfc74987665cdafbccd984b3a031bdd1f98f6c445dd8839':
        raise ValueError('Unsupported original drawing interpreter')
    if hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest()!=metadata['sha256'] or entry['slave_sha256']!=metadata['sha256']:
        raise ValueError('Frozen capture build differs')
    h3=metadata['h3'];rows=[]
    for frame in metadata['frames']:
        before=Snapshot(root,frame['before']['banks']);after=Snapshot(root,frame['after']['banks'])
        result,writes=expected(before.read,h3,frame['before']['program'])
        actual=after.read(h3,len(result))
        if result!=actual:
            differences=[f'h3:{i:05x}' for i,(a,b) in enumerate(zip(result,actual)) if a!=b]
            raise ValueError('Unmodelled native h3 post-state: '+', '.join(differences[:20]))
        rows.append(dict(index=frame['index'],program=frame['before']['program'],checked_bytes=len(result),writes=writes,
                         changed_bytes=sum(a!=b for a,b in zip(before.read(h3,len(result)),actual))))
    return dict(sha256=metadata['sha256'],frames=rows,
                scope='Whole h3 post-state for retained audited programs only. No register, hardware, other-memory, complete-key, runtime-cache or speed claim.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.capture);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Complete h3 post-state matches',len(result['frames']),'native overlay calls')
