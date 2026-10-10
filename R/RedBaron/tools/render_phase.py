"""Verify actual W6 pose leases and separate rendering from world ticks."""
import argparse
import json
import struct
from pathlib import Path
from render_mutations import Snapshot
from presentation_state import symbol
from native_pose_blend import blend, split
from native_poses import STRIDE
from presentation_math import phase_fraction
from camera_pose import owner, identity


def dirty_after(value):
    if not -32768 <= value <= 32767:
        raise ValueError('Dirty counter outside signed word')
    return max(value-1,0)


def terrain_cache(before,after,h3,frame):
    for offset,size in ((0x5270,2),(0x54de,14)):
        if before(h3+offset,size)!=after(h3+offset,size):
            raise ValueError('Terrain cache key/flag/countdown not restored')
    if frame['terrain_rebuilds']!=1 or frame['terrain_reuses'] or any(
            key!=0xffffffff for key in frame['terrain_keys']):
        raise ValueError('Draw reused terrain state restored after earlier drawing')


def shared_list(before,after,h3):
    count=int.from_bytes(before(h3+0x3fa8,2),'big')
    if count>500 or before(h3+0x3fa8,2)!=after(h3+0x3fa8,2):
        raise ValueError('Shared display-list count changed across drawing')
    if before(h3+0x7dc8,count*4)!=after(h3+0x7dc8,count*4):
        raise ValueError('Shared active display-list order changed across drawing')
    return count


def check(path):
    metadata=json.loads(path.read_text())
    entry=json.loads((path.parent/'entry.json').read_text())
    lines=(path.parent/'slave.lst').read_text(encoding='latin-1').splitlines()
    base=entry['entry']['game_anchor']-symbol(lines,'tape_game_anchor')
    at=lambda name:base+symbol(lines,name)
    result=[];changed=poses=0
    terrain=any('time_terrain_cache_result:' in line for line in lines)
    for frame in metadata['frames']:
        before,during,after=[Snapshot(path.parent,frame[k]) for k in ('before','during','after')]
        if frame['world_during'] or not frame['stack_checked']:
            raise ValueError('World execution or incorrect stack within render phase')
        state=before.read(at('time_loop_state'),40)
        if state[:36]!=during.read(at('time_loop_state'),36) or state[:36]!=after.read(at('time_loop_state'),36):
            raise ValueError('Rendering changed funded time, debt or world tick counters')
        if terrain:
            terrain_cache(before.read,after.read,metadata['h3'],frame)
        list_entries=None
        list_changed=None
        if any('time_present_list_count:' in line for line in lines):
            list_entries=shared_list(before.read,after.read,metadata['h3'])
            rendered=Snapshot(path.parent,frame['list_before_restore'])
            list_changed=(before.read(metadata['h3']+0x3fa8,2)!=rendered.read(metadata['h3']+0x3fa8,2)
                          or before.read(metadata['h3']+0x7dc8,list_entries*4)!=rendered.read(metadata['h3']+0x7dc8,list_entries*4))
        count,np=struct.unpack('>HH',before.read(at('time_pose_header'),4))
        current=before.read(at('time_pose_current'),count*STRIDE)
        previous=before.read(at('time_pose_previous'),np*STRIDE)
        fraction=phase_fraction(int.from_bytes(state[:16],'big'))
        expected,nb,ns=blend(current,previous,fraction)
        if during.read(at('time_blend_output'),len(expected))!=expected:
            raise ValueError('Render-time candidate buffer differs from model')
        if during.read(at('time_render_active'),2)!=b'\0\1' or after.read(at('time_render_active'),2)!=b'\0\0':
            raise ValueError('Pose lease not active then released')
        if after.read(at('time_present_active'),4)!=bytes(4) or after.read(at('time_model_count'),2)!=bytes(2):
            raise ValueError('Render cache/model ownership left active')
        for current_row,visual in zip(split(current),split(expected)):
            pointer=int.from_bytes(current_row[:4],'big')
            if before.read(pointer+8,18)!=current_row[8:] or after.read(pointer+8,18)!=current_row[8:]:
                raise ValueError('Simulation pose not preserved across drawing')
            if during.read(pointer+8,18)!=visual[8:]:
                raise ValueError('Game object does not contain expected visual pose during drawing')
            changed+=current_row[8:]!=visual[8:];poses+=1
        camera,view,target=identity(before.read,metadata['h3'])
        camera_changed=False
        if any('time_pose_camera_target:' in line for line in lines):
            captured_target=int.from_bytes(before.read(at('time_pose_camera_target'),4),'big')
            captured_camera=int.from_bytes(before.read(at('time_pose_header')+16,4),'big')
            captured_view=int.from_bytes(before.read(at('time_pose_header')+24,2),'big')
            target,attached=owner(before.read,metadata['h3'],entry['entry']['sim'],captured_camera,captured_view,captured_target)
            if during.read(at('time_render_camera_active'),2)!=int(attached).to_bytes(2,'big') or after.read(at('time_render_camera_active'),2)!=bytes(2):
                raise ValueError('Private camera lease ownership mismatch')
            if attached:
                matching=[row for row in split(expected) if int.from_bytes(row[:4],'big')==target]
                if len(matching)!=1 or during.read(camera+8,18)!=matching[0][8:]:
                    raise ValueError('Attached camera did not follow the interpolated target')
                camera_changed=during.read(camera+8,18)!=before.read(camera+8,18)
                if after.read(camera+8,18)!=before.read(camera+8,18):
                    raise ValueError('Private camera simulation pose was not restored')
        else:
            attached=False
        dirty=struct.unpack('>h',before.read(metadata['h3']+0x7856,2))[0]
        if struct.unpack('>h',after.read(metadata['h3']+0x7856,2))[0]!=dirty_after(dirty):
            raise ValueError('Dirty countdown not consumed exactly once per draw')
        draws=int.from_bytes(state[36:40],'big')
        if int.from_bytes(after.read(at('time_loop_state')+36,4),'big')!=(draws+1)&0xffffffff:
            raise ValueError('Draw counter did not advance once')
        result.append(dict(view=view,attached_camera=attached,camera_changed=camera_changed,tick=int.from_bytes(state[28:32],'big'),poses=count,fraction=fraction,blended=nb,snapped=ns,list_entries=list_entries,list_changed_during_draw=list_changed))
    if not result or not poses or not changed:
        raise ValueError('No real changed pose lease observed')
    return dict(sha256=metadata['sha256'],frames=result,poses_checked=poses,changed_visual_poses=changed,
                limitation='Observed render leases only; no full gameplay-state, camera-mode, cadence or capacity acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('manifest',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.manifest);a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
