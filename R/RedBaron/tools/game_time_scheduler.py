"""Executable W6 timing contract, independent of renderer and physics quantum.

This is the rational reference for the native scheduler, not installed game code.
CIA observations are unsigned 32-bit values with deltas below 2**31. Deadlines
are observed on the first integer CIA tick that reaches the rational deadline.
Input eligibility is acquisition_CIA_tick + 1, ordered by producer sequence.
This closes a same-tick IRQ race: an input arriving during execution cannot
retroactively change another world update already due at that CIA boundary.
"""
from collections import deque
from dataclasses import dataclass
from fractions import Fraction


def ceil(value):
    return -(-value.numerator // value.denominator)


def input_deadline(acquisition_tick):
    if acquisition_tick < 0:
        raise ValueError('Negative acquisition time')
    return acquisition_tick + 1


def elapsed32(previous, current):
    if not 0 <= previous < 2**32 or not 0 <= current < 2**32:
        raise ValueError('CIA counter outside unsigned 32-bit range')
    delta = (current - previous) & 0xffffffff
    if delta >= 2**31:
        raise ValueError('Ambiguous or backwards CIA observation')
    return delta


@dataclass(frozen=True)
class Tick:
    index: int
    deadline: int
    held: tuple
    commands: tuple


class InputQueue:
    """Bounded producer queue; overflow faults explicitly without evicting input.

    Key/button transitions and one-shot native commands are separate event kinds.
    Events remain timestamped while rendering or world catch-up delays consumption.
    """
    def __init__(self, capacity=256):
        if capacity < 1:
            raise ValueError('Positive input capacity required')
        self.capacity = capacity
        self.events = deque()
        self.held = {}
        self.last_stamp = -1
        self.consumed_through = -1
        self.high_water = 0
        self.overflow = False

    def push(self, timestamp, kind, key, value=None):
        if timestamp < self.last_stamp or timestamp <= self.consumed_through:
            raise ValueError('Input cannot be added to an already consumed interval')
        if kind not in ('held', 'command'):
            raise ValueError('Unknown input event kind')
        if len(self.events) == self.capacity:
            self.overflow = True
            raise OverflowError('Input queue full; do not continue with dropped input')
        self.events.append((timestamp, kind, key, value))
        self.last_stamp = timestamp
        self.high_water = max(self.high_water, len(self.events))

    def consume(self, deadline):
        if deadline < self.consumed_through:
            raise ValueError('Input deadline moved backwards')
        commands = []
        while self.events and self.events[0][0] <= deadline:
            _, kind, key, value = self.events.popleft()
            if kind == 'held':
                self.held[key] = value
            else:
                commands.append(key)
        self.consumed_through = deadline
        return tuple(sorted(self.held.items())), tuple(commands)

    def resume(self, now, held):
        self.events.clear()
        self.held = dict(held)
        self.last_stamp = now
        self.consumed_through = now


class Scheduler:
    """Independent world/service accrual with bounded work and retained debt.

    Pending deadlines model the native debt ledger, not a proposed per-tick heap
    allocation. A native implementation may use compressed rate segments instead.
    Rate changes happen at explicit observed boundaries after funding the old rate.
    """
    def __init__(self, now=0, divisor=33, quantum=225, input_capacity=256):
        if not 0 <= now < 2**32 or not 10 <= divisor <= 80 or quantum < 1:
            raise ValueError('Invalid clock configuration')
        self.last = now
        self.wall = 0
        self.active_time = 0
        self.divisor = divisor
        self.quantum = quantum
        self.multiplier = 1
        self.credit = Fraction(0)
        self.service_credit = Fraction(0)
        self.pending = deque()
        self.service_pending = deque()
        self.steps = 0
        self.service_steps = 0
        self.debt_high_water = 0
        self.paused = False
        self.input = InputQueue(input_capacity)

    @staticmethod
    def accrue(credit, rate, quantum, delta, start, pending):
        count = (credit + delta * rate) // quantum
        for i in range(1, count + 1):
            pending.append(start + ceil((i*quantum-credit)/rate))
        return credit + delta*rate - count*quantum

    def observe(self, now):
        delta = elapsed32(self.last, now)
        if not self.paused:
            self.credit = self.accrue(self.credit, Fraction(1024*self.multiplier, self.divisor),
                                      self.quantum, delta, self.wall, self.pending)
            self.service_credit = self.accrue(self.service_credit, Fraction(1024, 20),
                                              128, delta, self.wall, self.service_pending)
            self.active_time += delta
            self.debt_high_water = max(self.debt_high_water, len(self.pending))
        self.wall += delta
        self.last = now

    def change_rate(self, now, divisor=None, multiplier=None):
        if divisor is not None and not 10 <= divisor <= 80:
            raise ValueError('Unsupported Time Scale divisor')
        if multiplier is not None and multiplier not in (1, 8):
            raise ValueError('Unsupported compression request')
        self.observe(now)
        if divisor is not None:
            self.divisor = divisor
        if multiplier is not None:
            self.multiplier = multiplier
        # Fractional world credit remains in world units, independent of F.

    def pause(self, now):
        self.observe(now)
        self.paused = True

    def resume(self, now, held=()):
        if not self.paused:
            raise ValueError('Resume requires a paused clock')
        # Before pausing, the native loop must finish due world work through the
        # pause event. Replacing input state while debt remains would rewrite it.
        if self.pending or self.service_pending:
            raise ValueError('Drain pre-pause work before resuming input state')
        self.observe(now)
        self.input.resume(self.wall, held)
        self.paused = False

    def run(self, limit):
        if limit < 1:
            raise ValueError('Positive batch limit required')
        result = []
        while self.pending and len(result) < limit:
            deadline = self.pending.popleft()
            held, commands = self.input.consume(deadline)
            self.steps += 1
            result.append(Tick(self.steps, deadline, held, commands))
        return result

    def service(self, limit):
        if limit < 1:
            raise ValueError('Positive service batch limit required')
        result = []
        while self.service_pending and len(result) < limit:
            result.append(self.service_pending.popleft())
            self.service_steps += 1
        return result

    @property
    def may_render(self):
        return not self.pending and not self.service_pending and not self.paused
