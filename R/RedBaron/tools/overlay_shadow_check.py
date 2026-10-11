"""Verify reuse of native packed overlays in a private full-frame CPU twin."""
import argparse
import json
import struct
from pathlib import Path
from overlay_pack_check import check as check_packing,replay
from overlay_mask_check import GUARD
from presentation_state import symbol
from render_mutations import Snapshot


def retain(previous,program,pointer,data):
    if not pointer or len(data)!=5240:raise ValueError('Missing persistent cache allocation')
    if program in previous:
        if previous[program]!=(pointer,bytes(data)):
            raise ValueError('Cache hit replaced or mutated its retained allocation')
        return True
    previous[program]=(pointer,bytes(data))
    return False


def checked_frame(data,pixels):
    if len(pixels)!=40000 or data!=GUARD+pixels+GUARD:
        raise ValueError('Private framebuffer or guards differ')


def check(path):
    packing=check_packing(path);root=path.parent;meta=json.loads(path.read_text())
    entry=json.loads((root/'entry.json').read_text())
    lines=(root/'slave.lst').read_text(encoding='latin-1').splitlines()
    base=entry['entry']['game_anchor']-symbol(lines,'tape_game_anchor')
    header_at=base+symbol(lines,'overlay_shadow_result')
    previous={};backgrounds={};descriptors={};rows=[];hits=misses=0
    for i,frame in enumerate(meta['frames']):
        observed=struct.unpack('>10I12H2I',(root/frame['shadow']['header']).read_bytes())
        cache3,cache4,target,native_hits,native_misses,calls,mismatch,first,destination,program=observed[:10]
        selected,unsupported=observed[-2:]
        if (program!=frame['before']['program'] or program not in (3,4) or
            calls!=i+1 or mismatch or first or unsupported or not target):
            raise ValueError('Native twin identity, status or comparison failed')
        slot=program-3
        if selected!=(cache3,cache4)[slot]:raise ValueError('Wrong persistent cache selected')
        before=Snapshot(root,frame['before']['banks']);after=Snapshot(root,frame['after']['banks'])
        old_header=struct.unpack('>10I12H2I',before.read(header_at,72))
        if old_header[2]!=target or old_header[3:6]!=(hits,misses,i):
            raise ValueError('Private target or cache history differs at entry')
        actual_destination=int.from_bytes(before.read(meta['h3']+0x9d72,4),'big')
        if destination!=actual_destination:raise ValueError('Native twin selected a different framebuffer')
        original=before.read(destination,40000);native=after.read(destination,40000)
        checked_frame(before.read(target,40032),original)
        cached=(root/frame['shadow']['cache']).read_bytes()
        hit=retain(previous,program,selected,cached)
        current_descriptor=tuple(packing['cases'][i]['descriptor'])
        if hit:
            if old_header[slot]!=selected or before.read(selected,5240)!=cached:
                raise ValueError('Hit does not reuse the pre-draw cache')
            hits+=1
        else:
            if old_header[slot]!=0:raise ValueError('Miss already had a cache')
            if cached!=(root/frame['pack']['file']).read_bytes():raise ValueError('Seed differs from native pack')
            descriptors[program]=current_descriptor;backgrounds[program]=original;misses+=1
        if (native_hits,native_misses)!=(hits,misses):raise ValueError('Native cache counters differ')
        descriptor=descriptors[program]
        if current_descriptor!=descriptor or tuple(observed[10+6*slot:16+6*slot])!=descriptor:
            raise ValueError('Retained geometry differs')
        output=replay(original,descriptor,cached[16:16+descriptor[-1]])
        checked_frame((root/frame['shadow']['target']).read_bytes(),output)
        if output!=native:raise ValueError('Persistent cache replay differs from original native draw')
        rows.append(dict(program=program,hit=hit,checked_frame_bytes=40000,
                         changed_background_bytes=sum(a!=b for a,b in zip(backgrounds[program],original))))
    if (hits,misses)!=(2,2):raise ValueError('Need a seed and later hit for both programs')
    return dict(sha256=packing['sha256'],hits=hits,misses=misses,cases=rows,
                scope='Four-call native CPU shadow cache on actual backgrounds. Original renderer always runs. No hardware cache hits, complete invalidation key, speed gain or W6 acceptance claim.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.capture);a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
