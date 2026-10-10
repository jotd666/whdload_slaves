#!/usr/bin/env python3
"""W3 reference arithmetic and the sim:34d26 queue state machine.

Queue entries use 255 as empty; at most two driver calls occur per service.
The second consumed entry retains its index until the next service.
"""


def queue_original(queue, index):
    if len(queue) != 16 or not 0 <= index < 16 or any(not 0 <= x < 256 for x in queue):
        raise ValueError('Expected sixteen bytes and an index in 0..15')
    queue = list(queue)
    start, calls = index, []
    while True:
        if queue[index] != 255:
            calls.append((index, queue[index]))
            queue[index] = 255
            if len(calls) == 2:
                break
        index = (index + 1) % 16
        if index == start:
            break
    return queue, index, calls


def queue_fast(queue, index):
    if len(queue) != 16 or not 0 <= index < 16 or any(not 0 <= x < 256 for x in queue):
        raise ValueError('Expected sixteen bytes and an index in 0..15')
    if all(value == 255 for value in queue):
        return list(queue), index, []
    return queue_original(queue, index)


def divide63(n):
    if not 0 <= n <= 65025:
        raise ValueError('Operand must be the product of two unsigned bytes')
    return ((n + 1) * 0x1041) >> 18


def volume(channel, envelope, expression, master, enabled=True, divide=lambda n: n // 63):
    """sound:0c10 low-byte result, including intermediate byte truncation.

Master is the original 16-bit value; its shifted low byte participates.
Do not replace the pipeline with a single algebraic product.
"""
    master = (master << 2) & 255
    value = envelope
    if channel == 0:
        value = 0
    elif value:
        value = divide(channel * value)
        if expression == 0:
            value = 0
        else:
            value = divide(expression * (value & 255))
            if master == 0:
                value = 0
            else:
                value = divide(master * (value & 255))
                if (value & 255) == 0:
                    value = (value + 1) & 65535
    return (value & 255) if enabled else 0
