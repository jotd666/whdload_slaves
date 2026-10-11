"""Validate W6 keyboard acquisition against native post-poll flight inputs.

Rows: tick, active CIA cursor, active CIA now, held Right, held Fire,
raw command, native X axis, native flags, command-pop count.
The fixed-clock oracle supplies deadlines; this checks input ownership only.
"""
from collections import deque
import struct


def modifiers(held):
    return (bool(any(held.get(k, 0) for k in (0x60, 0x61, 0x62))) << 8
            | bool(held.get(0x63, 0)) << 9
            | bool(any(held.get(k, 0) for k in (0x64, 0x65))) << 10
            | bool(any(held.get(k, 0) for k in (0x66, 0x67))) << 11)


def check_capture(queue, fixture, rows, excluded, center_x, right_x, command_queue, counters, clocks=None, modal_key=0x59, first_key=0x4e):
    if modal_key not in (0x59, 0x19) or clocks is None and modal_key != 0x59:
        raise ValueError('Unsupported modal fixture key')
    if first_key not in (0x4e, 0x51) or first_key == 0x51 and clocks is not None:
        raise ValueError('Unsupported first-key fixture')
    sequence = ((first_key,1),(first_key,0),(0x40,1),(0x40,0))
    if clocks is not None:
        sequence += ((modal_key,1),(modal_key,0),(0x45,1),(0x45,0))
        if len(clocks) != 128:
            raise ValueError('Missing modal acquisition clock tuples')
    count = len(sequence)
    head, tail, overflow, high = struct.unpack_from('>4H', queue)
    if (head, tail, overflow) != (count, count, 0) or not 1 <= high <= count:
        raise ValueError('Missing, extra, unconsumed or overflowed keyboard events')
    events = []
    for i, expected in enumerate(sequence):
        acquired, key, down = struct.unpack_from('>IHH', fixture, i*8)
        deadline = (acquired-excluded+1) & 0xffffffff
        encoded = key
        modal = False
        if clocks is not None:
            active, paused, start, base = struct.unpack_from('>IIII', clocks, i*16)
            if active not in (0,1):
                raise ValueError('Invalid acquisition ownership state')
            modal = not active
            deadline = ((start-base if modal else acquired-paused)+1) & 0xffffffff
            encoded |= 0x100 if modal else 0
            if i == 6 and not modal:
                raise ValueError('Escape was not acquired inside the modal loop')
        record = struct.unpack_from('>IHHII', queue, 16+i*16)
        if (key, down) != expected or record != (deadline, encoded, down, 0, 0):
            raise ValueError('Acquisition and active-clock event disagree')
        events.append((deadline, key, down, modal))
    # Preflight acquisitions are held-only, just like modal acquisitions.
    # Derive command count from the independently recorded ownership tuples.
    commands = sum(bool(down) and not modal for _, _, down, modal in events)
    pending, held, at, pops = deque(), {}, 0, 0
    saw_right = saw_fire = saw_first_command = False
    for row in rows:
        tick, cursor, now, right, fire, command, axis, flags, popped = row
        while at < len(events) and ((cursor-events[at][0]) & 0xffffffff) < 2**31:
            _, key, down, modal = events[at]
            held[key] = down
            if down and not modal:
                pending.append(key | modifiers(held))
            at += 1
        expected_command = pending.popleft() if pending else 0
        pops += bool(expected_command)
        expected_right, expected_fire = held.get(0x4e, 0), held.get(0x40, 0)
        if (right, fire, command, popped) != (expected_right, expected_fire, expected_command & 255, pops):
            raise ValueError(f'Wrong held/command history at tick {tick}: {row}')
        if axis != (right_x if expected_right else center_x) or bool(flags & (1 << 29)) != bool(expected_fire):
            raise ValueError(f'Native input did not use the tick snapshot at tick {tick}: {row}')
        saw_first_command |= command == first_key
        saw_right |= bool(right)
        saw_fire |= bool(fire)
    if (at != count or pending or not saw_fire
            or first_key == 0x4e and not saw_right
            or first_key == 0x51 and not saw_first_command):
        raise ValueError('Fixture did not cover the first command, fire and all releases')
    if struct.unpack_from('>HH', command_queue) != (commands, commands) or struct.unpack('>II', counters) != (count, commands):
        raise ValueError('Commands were repeated, lost or left pending')
    return {'rows':len(rows), 'events':count, 'commands':commands, 'held_right_and_fire':bool(saw_right and saw_fire),
            'first_key':first_key, 'first_command_observed':saw_first_command,
            'native_axis_and_fire_flag':True, 'acquisition_deadlines':True}
