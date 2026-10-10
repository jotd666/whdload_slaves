"""Check observed W6 compression funding, independent of native limb arithmetic.

Rows: cursor, divisor, native compression flag, multiplier, four phase limbs,
secondary phase, world due, service due. Native gameplay policy is not modeled.
"""
from fractions import Fraction
from game_time_core import DENOMINATOR


def phase(row):
    return sum(value << shift for value, shift in zip(row[4:8], (96, 64, 32, 0)))


def check_capture(before, after):
    if len(before) != len(after) or len(before) < 100:
        raise ValueError('Need at least 100 complete funding boundaries')
    counts = {1: 0, 8: 0}
    worlds = services = transitions = 0
    for i, (pre, post) in enumerate(zip(before, after)):
        if len(pre) != 11 or len(post) != 11:
            raise ValueError('Invalid funding record')
        cursor, divisor, flag, multiplier = pre[:4]
        if not 10 <= divisor <= 80 or flag not in (0, 1):
            raise ValueError('Invalid native settings')
        if multiplier != (8 if flag else 1) or post[:4] != pre[:4]:
            raise ValueError('Compression rate changed during funding')
        if pre[9:] != [0, 0]:
            raise ValueError('Previous boundary not drained')
        credit = Fraction(phase(pre), DENOMINATOR) + Fraction(1024 * multiplier, divisor)
        due, remainder = divmod(credit, 225)
        service, secondary = divmod(pre[8] + 1024, 2560)
        if (Fraction(phase(post), DENOMINATOR), post[8], post[9], post[10]) != (remainder, secondary, due, service):
            raise ValueError('Incorrect phase, world funding or independent service funding')
        if i:
            old = after[i - 1]
            if (cursor - old[0]) & 0xffffffff != 1 or pre[4:9] != old[4:9]:
                raise ValueError('Lost CIA boundary or fractional phase')
            transitions += pre[3] != old[3]
        counts[multiplier] += 1
        worlds += due
        services += service
    if min(counts.values()) == 0 or transitions < 2:
        raise ValueError('Missing compression entry/exit coverage')
    return dict(boundaries=len(before), normal_boundaries=counts[1],
                compressed_boundaries=counts[8], transitions=transitions,
                world_ticks=int(worlds), service_ticks=services)
