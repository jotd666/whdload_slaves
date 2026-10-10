"""W6 planning models. These are not installed game-time patches.

The proposed world clock earns 1024 numerator units per CIA tick and spends
F * quantum per simulation step. Keeping the remainder removes frame partition
rounding. Arithmetic is unbounded here; an implementation must audit overflow.
"""
from fractions import Fraction


def fixed_ticks(chunks, divisor=33, quantum=225):
    if divisor <= 0 or quantum <= 0 or any(t < 0 for t in chunks):
        raise ValueError('Positive divisor/quantum and monotone elapsed time required')
    credit = ticks = 0
    for elapsed in chunks:
        credit += elapsed * 1024
        due, credit = divmod(credit, divisor * quantum)
        ticks += due
    return ticks, credit


def tick_deadline(index, divisor=33, quantum=225):
    if index < 1:
        raise ValueError('Simulation ticks are numbered from one')
    return Fraction(index * divisor * quantum, 1024)


def budget(world_ms, draw_ms, cia_hz, divisor=33, quantum=225):
    rate = cia_hz * 1024 / (divisor * quantum)
    utilization = rate * world_ms / 1000
    return dict(world_hz=rate, world_fraction=utilization,
                render_fps_ceiling=max(0, (1-utilization)*1000/draw_ms),
                feasible=utilization < 1,
                scope='Projection using retained routine costs; not measured scheduler FPS')
