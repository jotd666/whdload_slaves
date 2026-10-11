"""Check installed private-cache lifetime hooks and native CCR self-test evidence."""
import argparse
import json
from pathlib import Path
from overlay_shadow_check import check as shadow_check
from presentation_state import symbol
from render_mutations import Snapshot

HOOKS=(('reset',0x28516,6),('load',0x28556,8),('rebuild',0x286fc,8),
       ('release',0x28df4,6),('bitmap_load',0x301d8,8),
       ('bitmap_release',0x303ac,6),('bitmap_all',0x3038e,6))


def check(path):
    prior=shadow_check(path);root=path.parent;m=json.loads(path.read_text())
    entry=json.loads((root/'entry.json').read_text());lines=(root/'slave.lst').read_text(encoding='latin-1').splitlines()
    base=entry['entry']['game_anchor']-symbol(lines,'tape_game_anchor');sim=entry['entry']['sim']
    at=lambda n:base+symbol(lines,n);rows=[]
    try:fixture_at=at('ovlife_refill_result')
    except ValueError:fixture_at=None
    for frame in m['frames']:
        for phase in ('before','after'):
            ram=Snapshot(root,frame[phase]['banks']);read=ram.read
            for name,off,length in HOOKS:
                expected=b'\x4e\xf9'+at('ovlife_'+name).to_bytes(4,'big')+b'\x4e\x71'*((length-6)//2)
                if read(sim+off,length)!=expected:raise ValueError('Wrong lifetime hook '+name)
                expected=b'\x4e\xf9'+(sim+off+length).to_bytes(4,'big')
                if read(at('ovlife_'+name+'_tail'),6)!=expected:raise ValueError('Wrong lifetime continuation '+name)
            if read(at('ovlife_zero_tail'),6)!=b'\x4e\xf9'+(sim+0x303ee).to_bytes(4,'big'):
                raise ValueError('Wrong null bitmap continuation')
            result=read(at('ovlife_count'),8)
            count=int.from_bytes(result[:4],'big');cases=int.from_bytes(result[4:],'big')
            if cases!=32:raise ValueError('Missing lifetime native CCR cases')
            flags=[int.from_bytes(read(at('overlay_shadow_valid')+i*4,4),'big') for i in range(2)]
            if any(v not in (0,1) for v in flags):raise ValueError('Invalid cache validity flag')
            injected=int.from_bytes(read(fixture_at,4),'big') if fixture_at is not None else 0
            if injected not in (0,1) or count<injected:raise ValueError('Invalid lifetime fixture accounting')
            rows.append(dict(frame=frame['index'],phase=phase,operations=count-injected,
                             private_invalidations=injected,invalidations=count,ccr_cases=cases,valid=flags))
    return dict(sha256=entry['slave_sha256'],rows=rows,
                scope='Seven installed lifetime hooks/continuations, native 32-CCR invalidation cases and existing private pixel/state twins. Not all lifecycle paths exercised, complete cache keys, skipped native drawing or a performance result.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();r=check(a.capture);a.out.write_text(json.dumps(r,indent=2)+'\n');print(r)
