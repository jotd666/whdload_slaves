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


def check_capture(queue, fixture, rows, excluded, center_x, right_x, command_queue, counters, clocks=None):
    sequence = ((0x4e,1),(0x4e,0),(0x40,1),(0x40,0))
    if clocks is not None:
        sequence += ((0x59,1),(0x59,0),(0x45,1),(0x45,0))
        if len(clocks) != 128:
            raise ValueError('Missing modal acquisition clock tuples')
    count = len(sequence)
    commands = 3 if clocks is not None else 2
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
                raise ValueError('Escape was not acquired inside Preferences')
        record = struct.unpack_from('>IHHII', queue, 16+i*16)
        if (key, down) != expected or record != (deadline, encoded, down, 0, 0):
            raise ValueError('Acquisition and active-clock event disagree')
        events.append((deadline, key, down, modal))
    pending, held, at, pops = deque(), {}, 0, 0
    saw_right = saw_fire = False
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
        saw_right |= bool(right)
        saw_fire |= bool(fire)
    if at != count or pending or not saw_right or not saw_fire:
        raise ValueError('Fixture did not cover both held controls and their releases')
    if struct.unpack_from('>HH', command_queue) != (commands, commands) or struct.unpack('>II', counters) != (count, commands):
        raise ValueError('Commands were repeated, lost or left pending')
    return {'rows':len(rows), 'events':count, 'commands':commands, 'held_right_and_fire':True,
            'native_axis_and_fire_flag':True, 'acquisition_deadlines':True}
