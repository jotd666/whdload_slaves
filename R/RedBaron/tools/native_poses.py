"""Verify native completed-world pose snapshots and lifecycle invalidation."""
import argparse
import json
import struct
from pathlib import Path
from pose_history import registry, read_pose
from camera_pose import identity
from presentation_state import symbol
from render_mutations import Snapshot

STRIDE = 26


def records(read, pointers):
    return [struct.pack('>IHH', pointer, 1, model)+pose
            for pointer in pointers for model, pose in [read_pose(read, pointer)]]


def invalidate(saved, events):
    events = set(events)
    result = []
    for record in saved:
        if len(record) != STRIDE:
            raise ValueError('Truncated native pose record')
        pointer = int.from_bytes(record[:4], 'big')
        result.append(record[:4]+bytes(2)+record[6:] if pointer in events else record)
    return result


def check(path):
    metadata = json.loads(path.read_text())
    entry = json.loads((path.parent/'entry.json').read_text())
    lines = (path.parent/'slave.lst').read_text(encoding='latin-1').splitlines()
    base = entry['entry']['game_anchor']-symbol(lines, 'tape_game_anchor')
    header = base+symbol(lines, 'time_pose_header')
    current = base+symbol(lines, 'time_pose_current')
    previous = base+symbol(lines, 'time_pose_previous')
    loop = base+symbol(lines, 'time_loop_state')
    target_header = base+symbol(lines,"time_pose_camera_target") if any("time_pose_camera_target:" in line for line in lines) else None
    prior = None
    checked = invalidated = events = 0
    rows = []
    for frame in metadata['frames']:
        ram = Snapshot(path.parent, frame['banks'])
        nc, np, tick, ptick, ready, reserved, camera, pcamera, view, pview, life, captures = struct.unpack('>HHIIHHIIHHII', ram.read(header, 36))
        expected = records(ram.read, registry(ram.read, metadata['h3']))
        if ready != 1 or reserved or nc != len(expected):
            raise ValueError('Invalid current pose header/count')
        if ram.read(current, nc*STRIDE) != b''.join(expected):
            raise ValueError('Native current snapshot differs from live registered poses')
        if tick != int.from_bytes(ram.read(loop+28, 4), 'big'):
            raise ValueError('Pose capture not at the recorded completed tick')
        if camera != int.from_bytes(ram.read(metadata['h3']+0x8d72, 4), 'big') or view != int.from_bytes(ram.read(metadata['h3']+0x6712, 2), 'big'):
            raise ValueError('Camera/view metadata mismatch')
        target=ptarget=None
        if target_header is not None:
            target,ptarget=struct.unpack('>II',ram.read(target_header,8))
            if identity(ram.read,metadata['h3'])!=(camera,view,target):
                raise ValueError('Followed camera target metadata mismatch')
        if prior:
            old_tick, old_camera, old_view, old_target, old_life, old_captures, old_records = prior
            if ptarget!=old_target:
                raise ValueError('Incorrect previous camera target')
            if tick != (old_tick+1)&0xffffffff or ptick != old_tick or captures != (old_captures+1)&0xffffffff:
                raise ValueError('Nonconsecutive snapshot pair')
            if (life-old_life)&0xffffffff != len(frame['lifecycle']):
                raise ValueError('Lifecycle counter/log disagreement')
            if (pcamera,pview) != (old_camera,old_view):
                raise ValueError('Incorrect previous view metadata')
            saved = invalidate(old_records, frame['lifecycle']) if (camera,view,target)==(old_camera,old_view,old_target) else []
            if np != len(saved) or ram.read(previous, np*STRIDE) != b''.join(saved):
                raise ValueError('Previous poses or lifecycle invalidations differ')
            invalidated += sum(r[4:6] == bytes(2) for r in saved)
            events += len(frame['lifecycle'])
        prior = (tick,camera,view,target,life,captures,expected)
        checked += nc
        rows.append(dict(tick=tick,objects=nc,previous=np,lifecycle=life,view=view,camera_target=target))
    if len(rows)<2 or not checked or not events or not invalidated:
        raise ValueError('Capture lacks consecutive poses and actual lifecycle invalidation')
    return dict(sha256=metadata['sha256'], boundaries=len(rows), poses_checked=checked,
                lifecycle_events=events, invalidated_records=invalidated, rows=rows,
                limitation='Observed registered-object snapshots only; no pose interpolation, teleport or unregistered-camera acceptance.')


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.manifest)
    a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
