"""Independent oracle for the native W6 candidate interpolation buffer."""
import argparse
import json
import struct
from pathlib import Path
from pose_history import POSE
from presentation_math import angle, position, phase_fraction
from presentation_state import symbol
from render_mutations import Snapshot
from native_poses import STRIDE


def split(data):
    if len(data) % STRIDE:
        raise ValueError('Truncated pose table')
    rows = [data[i:i+STRIDE] for i in range(0, len(data), STRIDE)]
    if len({row[:4] for row in rows}) != len(rows):
        raise ValueError('Duplicate pose address')
    return rows


def blend(current, previous, fraction):
    if not 0 <= fraction <= 65536:
        raise ValueError('Invalid blend fraction')
    old = {row[:4]: row for row in split(previous)}
    output = []
    blended = snapped = 0
    for row in split(current):
        prior = old.get(row[:4])
        if (row[4:6] != b'\x00\x01' or prior is None or
                prior[4:6] != b'\x00\x01' or prior[6:8] != row[6:8]):
            output.append(row)
            snapped += 1
        else:
            a, b = POSE.unpack(prior[8:]), POSE.unpack(row[8:])
            output.append(row[:8]+POSE.pack(*(position(a[i], b[i], fraction) if i < 3
                                              else angle(a[i], b[i], fraction) for i in range(6))))
            blended += 1
    return b''.join(output), blended, snapped


def check(path):
    metadata=json.loads(path.read_text())
    entry=json.loads((path.parent/'entry.json').read_text())
    lines=(path.parent/'slave.lst').read_text(encoding='latin-1').splitlines()
    base=entry['entry']['game_anchor']-symbol(lines,'tape_game_anchor')
    address=lambda name:base+symbol(lines,name)
    total=blended_total=snapped_total=changed=0
    fractions=[]
    for frame in metadata['frames']:
        ram=Snapshot(path.parent,frame['banks'])
        count,previous_count=struct.unpack('>HH',ram.read(address('time_pose_header'),4))
        current=ram.read(address('time_pose_current'),count*STRIDE)
        previous=ram.read(address('time_pose_previous'),previous_count*STRIDE)
        phase=int.from_bytes(ram.read(address('time_loop_state'),16),'big')
        fraction=phase_fraction(phase)
        expected,blended,snapped=blend(current,previous,fraction)
        header=struct.pack('>IHHHH',fraction,count,blended,snapped,1)
        if ram.read(address('time_blend_header'),12)!=header:
            raise ValueError('Native blend fraction/counts differ from model')
        if ram.read(address('time_blend_output'),len(expected))!=expected:
            raise ValueError('Native blended pose bytes differ from rational model')
        total+=count;blended_total+=blended;snapped_total+=snapped
        changed+=sum(a[8:]!=b[8:] for a,b in zip(split(current),split(expected)))
        fractions.append(fraction)
    if not total or not blended_total or not snapped_total or not changed:
        raise ValueError('Capture lacks real interpolation and lifecycle snaps')
    return dict(sha256=metadata['sha256'],boundaries=len(fractions),poses=total,
                blended=blended_total,snapped=snapped_total,changed=changed,fractions=fractions,
                limitation='Candidate buffer only; no interpolated game-memory writes, rendered frames or gameplay/FPS acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.manifest)
    a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
