"""Verify reuse of native packed overlays in a private full-frame CPU twin."""
import argparse
import json
import re
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


def replay_held(origin,cursor,records):
    relative=(cursor-origin)&0xffffffff
    if relative>=0x80000000:raise ValueError('Replay cursor precedes its epoch')
    held={78:0,64:0}
    expected=((32,78,1),(64,78,0),(96,64,1),(128,64,0))
    if len(records)!=4:raise ValueError('Missing scheduled replay records')
    for record,(delta,code,value) in zip(records,expected):
        when,key,state,reserved1,reserved2=record
        if record!=((origin+delta)&0xffffffff,code,value,0,0):
            raise ValueError('Scheduled replay record differs')
        if relative>=delta:held[code]=state
    return relative,held


def check(path):
    packing=check_packing(path);root=path.parent;meta=json.loads(path.read_text())
    entry=json.loads((root/'entry.json').read_text())
    lines=(root/'slave.lst').read_text(encoding='latin-1').splitlines()
    base=entry['entry']['game_anchor']-symbol(lines,'tape_game_anchor')
    header_at=base+symbol(lines,'overlay_shadow_result')
    custom5=int(re.search(r'CUSTOM5=(-?\d+)',entry['whd_args'])[1])&0xffffffff
    scheduled=bool(custom5&(1<<31))
    refill_fixture=int(re.search(r'CUSTOM4=(\d+)',entry['whd_args'])[1])==0x80000
    at=lambda name:base+symbol(lines,name)
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
        refilled=refill_fixture and program in previous
        if refilled:
            old_pointer,old_bytes=previous[program]
            if old_pointer!=selected or old_header[slot]!=selected:
                raise ValueError('Refill replaced its owned allocation')
            poisoned=bytearray(old_bytes);poisoned[16]^=255
            if before.read(selected,5240)!=poisoned:
                raise ValueError('Missing pre-refill poisoned cache evidence')
            if before.read(at('overlay_shadow_valid')+slot*4,4)!=bytes(4):
                raise ValueError('Refill entry was still valid')
            fixture=struct.unpack('>3I',before.read(at('ovlife_refill_result'),12))
            if fixture[0]!=1 or fixture[1+slot]!=selected:
                raise ValueError('Private invalidation fixture identity differs')
            previous[program]=(selected,bytes(cached));hit=False
        else:
            hit=retain(previous,program,selected,cached)
        current_descriptor=tuple(packing['cases'][i]['descriptor'])
        if hit:
            if old_header[slot]!=selected or before.read(selected,5240)!=cached:
                raise ValueError('Hit does not reuse the pre-draw cache')
            hits+=1
        else:
            if not refilled and old_header[slot]!=0:raise ValueError('Miss already had a cache')
            if cached!=(root/frame['pack']['file']).read_bytes():raise ValueError('Seed differs from native pack')
            descriptors[program]=current_descriptor;backgrounds[program]=original;misses+=1
        if (native_hits,native_misses)!=(hits,misses):raise ValueError('Native cache counters differ')
        descriptor=descriptors[program]
        if current_descriptor!=descriptor or tuple(observed[10+6*slot:16+6*slot])!=descriptor:
            raise ValueError('Retained geometry differs')
        output=replay(original,descriptor,cached[16:16+descriptor[-1]])
        checked_frame((root/frame['shadow']['target']).read_bytes(),output)
        if output!=native:raise ValueError('Persistent cache replay differs from original native draw')
        context={}
        if scheduled:
            uint=lambda address,size:int.from_bytes(before.read(address,size),'big')
            state=at('time_loop_state');tick=uint(state+28,4)
            cursor=(uint(state+20,4)-uint(state+44,4))&0xffffffff
            origin=uint(at('time_input_replay_origin'),4)
            records=list(struct.iter_unpack('>IHHII',before.read(at('time_input_replay_records'),64)))
            relative,held=replay_held(origin,cursor,records)
            if tick<4 or uint(at('time_input_replay_done'),2)!=2:
                raise ValueError('Replay capture precedes the delayed world-tick window')
            for key,value in held.items():
                if uint(at('time_keys_bitmap')+key,1)!=value:
                    raise ValueError('Consumed held input differs from scheduled replay')
            player=uint(meta['h3']+0x4578,4)
            rate=int.from_bytes(before.read(player+0xd6,2),'big',signed=True)
            context=dict(world_tick=tick,relative_cursor=relative,right=held[78],fire=held[64],roll_rate=rate)
        left,top,width,height,plane,total=descriptor
        coverage=cached[16+5*plane:16+total];changed_covered=0
        for y in range(height):
            for x in range(width):
                difference=0
                for p in range(5):
                    offset=p*8000+(top+y)*40+left+x
                    difference|=backgrounds[program][offset]^original[offset]
                changed_covered+=(difference&coverage[y*width+x]).bit_count()
        rows.append(dict(program=program,hit=hit,refilled=refilled,checked_frame_bytes=40000,context=context,
                         changed_background_covered_pixels=changed_covered,
                         changed_background_bytes=sum(a!=b for a,b in zip(backgrounds[program],original))))
    expected=(0,4) if refill_fixture else (2,2)
    if (hits,misses)!=expected:raise ValueError('Need both seeds and expected hits/refills')
    return dict(sha256=packing['sha256'],hits=hits,misses=misses,cases=rows,
                scope='Four-call native CPU shadow cache on actual backgrounds. Original renderer always runs. No hardware cache hits, complete invalidation key, speed gain or W6 acceptance claim.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.capture);a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
