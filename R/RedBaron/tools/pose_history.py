"""Reference ownership/lifecycle model for W6 interpolated poses.

Native integration must supply every add/remove/teleport and view transition.
This module does not infer continuity from pointers, distance, or render order.
"""
from contextlib import contextmanager
from dataclasses import dataclass
import struct
from presentation_math import angle, position

CAPACITY = 500
POSE = struct.Struct('>iiiHHH')


@dataclass(frozen=True)
class Sample:
    generation: int
    model: int
    pose: bytes


def registry(read, h3):
    count = int.from_bytes(read(h3+0x859e, 2), 'big')
    if count > CAPACITY:
        raise ValueError('Native dynamic registry exceeds 500 objects')
    raw = read(h3+0x85a0, count*4)
    if len(raw) != count*4:
        raise ValueError('Truncated dynamic registry')
    pointers = [int.from_bytes(raw[i:i+4], 'big') for i in range(0, len(raw), 4)]
    if any(not ptr or ptr & 1 for ptr in pointers) or len(set(pointers)) != count:
        raise ValueError('Null, odd or duplicate registered object')
    return pointers


def read_pose(read, pointer):
    header = read(pointer, 4)
    if len(header) != 4 or header[0] & 64:
        raise ValueError('Compact/unreadable object cannot use normal pose layout')
    pose = read(pointer+8, POSE.size)
    if len(pose) != POSE.size:
        raise ValueError('Truncated pose')
    return int.from_bytes(header[2:4], 'big'), pose


class History:
    def __init__(self):
        self.serial = 0
        self.live = {}
        self.previous = {}
        self.current = {}
        self.tick = None
        self.view = None
        self.leased = False

    def _idle(self):
        if self.leased:
            raise ValueError('Simulation/lifecycle change during presentation lease')

    def add(self, pointer):
        self._idle()
        if pointer in self.live:
            raise ValueError('Duplicate registration without removal')
        if len(self.live) >= CAPACITY:
            raise ValueError('Registry capacity exceeded')
        self.serial += 1
        self.live[pointer] = self.serial

    def remove(self, pointer):
        self._idle()
        if pointer not in self.live:
            raise ValueError('Removal without registration')
        del self.live[pointer]

    def discontinuity(self, pointer):
        self._idle()
        if pointer not in self.live:
            raise ValueError('Discontinuity for an unregistered object')
        self.serial += 1
        self.live[pointer] = self.serial

    def view_change(self, view):
        self._idle()
        if view != self.view:
            self.previous.clear()
            self.current.clear()
            self.view = view

    def reset(self):
        self._idle()
        self.live.clear()
        self.previous.clear()
        self.current.clear()
        self.tick = self.view = None

    def capture(self, tick, pointers, read, view):
        self._idle()
        if not 0 <= tick <= 0xffffffff:
            raise ValueError('World tick ID outside unsigned long')
        if self.tick is not None and tick != (self.tick+1) & 0xffffffff:
            raise ValueError('Snapshots must bracket consecutive completed world ticks')
        if len(pointers) != len(set(pointers)) or set(pointers) != set(self.live):
            raise ValueError('Lifecycle events disagree with current registry')
        current = {p: Sample(self.live[p], *read_pose(read, p)) for p in pointers}
        self.previous = self.current if view == self.view else {}
        self.current, self.tick, self.view = current, tick, view

    def blended(self, fraction):
        if not 0 <= fraction <= 65536:
            raise ValueError('Invalid interpolation fraction')
        result = {}
        for pointer, new in self.current.items():
            if self.live.get(pointer) != new.generation:
                continue  # Despawn/reuse after the snapshot must not touch stale RAM.
            old = self.previous.get(pointer)
            if old is None or (old.generation, old.model) != (new.generation, new.model):
                result[pointer] = new.pose
                continue
            a, b = POSE.unpack(old.pose), POSE.unpack(new.pose)
            result[pointer] = POSE.pack(*(position(a[i], b[i], fraction) if i < 3
                                         else angle(a[i], b[i], fraction) for i in range(6)))
        return result

    @contextmanager
    def presentation(self, fraction, read, write):
        """Lease only pose bytes; finally restores them even if drawing fails."""
        self._idle()
        target = self.blended(fraction)
        for pointer in target:
            model, pose = read_pose(read, pointer)
            if (model, pose) != (self.current[pointer].model, self.current[pointer].pose):
                raise ValueError('World/camera moved without a matching completed snapshot')
        undo = []
        self.leased = True
        try:
            for pointer, pose in target.items():
                undo.append((pointer+8, self.current[pointer].pose))
                write(pointer+8, pose)
            yield
        finally:
            for address, pose in reversed(undo):
                write(address, pose)
            self.leased = False


def inventory(path):
    import json
    from render_mutations import Snapshot
    metadata = json.loads(path.read_text())
    result = []
    for frame in metadata['frames']:
        snapshot = Snapshot(path.parent, frame['before'])
        pointers = registry(snapshot.read, metadata['h3'])
        poses = [(pointer, *read_pose(snapshot.read, pointer)) for pointer in pointers]
        camera = int.from_bytes(snapshot.read(metadata['h3']+0x8d72, 4), 'big')
        result.append(dict(index=frame['index'], registered=len(poses), camera_registered=camera in pointers,
                           objects=[dict(pointer=p, model=model, pose=pose.hex()) for p, model, pose in poses]))
    if not result:
        raise ValueError('No captured frames')
    return dict(sha256=metadata['sha256'], frames=result,
                limitation='Registry/layout inventory only. Draw snapshots are not consecutive world-tick snapshots and contain no lifecycle event history.')


if __name__ == '__main__':
    import argparse
    import json
    from pathlib import Path
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    result = inventory(args.manifest)
    args.out.write_text(json.dumps(result, indent=2)+'\n')
    for frame in result['frames']:
        print('draw', frame['index'], 'registered', frame['registered'], 'camera registered', frame['camera_registered'])
