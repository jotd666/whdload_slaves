"""Independent W6 rate timeline evidence check, using exact rational credit."""
from fractions import Fraction
import struct
from game_time_core import DENOMINATOR


def due(now, deadline):
    return ((now - deadline) & 0xffffffff) < 2**31


def check_capture(initial, initial_queue, queue, log, count, rows, native_test):
    def require(condition, message):
        if not condition:
            raise ValueError(message)
    require(native_test == 1, 'Native rate queue test did not complete')
    head, tail, overflow, high, final_f, last_f = struct.unpack_from('>6H', queue)
    require((count, head, tail, overflow, final_f, last_f) == (3, 3, 3, 0, 33, 33)
            and 1 <= high <= 3, 'Rate queue missing events, overflowing or unfinished')
    credit = Fraction(int.from_bytes(initial[:16], 'big'), DENOMINATOR)
    secondary = int.from_bytes(initial[16:18], 'big')
    cursor = int.from_bytes(initial[20:24], 'big')
    steps = int.from_bytes(initial[28:32], 'big')
    services = int.from_bytes(initial[26:28], 'big')
    paused = int.from_bytes(initial[44:48], 'big')
    divisor = struct.unpack_from('>H', initial_queue, 8)[0]
    require(10 <= divisor <= 80 and 0 <= credit < 225 and
            initial_queue[:8] == bytes(8), 'Unusable initial rate/clock state')
    events = []
    publication_debts = []
    for i, expected_f in enumerate((10, 80, 33)):
        wall, excluded, at, deadline, new_f, effective_f, active = struct.unpack_from('>4I2HI', log, i * 24)
        require(new_f == expected_f and active == 1 and excluded == paused,
                f'Unexpected native rate publication {i}')
        require(deadline == ((wall - excluded + 1) & 0xffffffff),
                f'Rate publication has retroactive deadline {i}')
        require(struct.unpack_from('>IHH', queue, 12 + i * 8) == (deadline, new_f, 0),
                f'Queue does not match native rate publication {i}')
        publication_debts.append((wall - at) & 0xffffffff)
        events.append((deadline, new_f))
    require(rows and max(publication_debts) > 0, 'No rate change with retained debt')
    event = 0
    old_debt_rows = 0
    for row in rows:
        tick, observed, observed_paused, live_f, native_f, sec, svc, p0, p1, p2, p3, now = row
        require(observed_paused == paused, 'Unexpected modal time in active-rate fixture')
        distance = (observed - cursor) & 0xffffffff
        require(distance < 10000, 'Clock cursor moved backwards or capture has a large gap')
        for _ in range(distance):
            cursor = (cursor + 1) & 0xffffffff
            active_cursor = (cursor - paused) & 0xffffffff
            while event < len(events) and due(active_cursor, events[event][0]):
                divisor = events[event][1]
                event += 1
            credit += Fraction(1024, divisor)
            earned, credit = divmod(credit, 225)
            steps += int(earned)
            service, secondary = divmod(secondary + 1024, 2560)
            services = (services + service) & 0xffff
        phase = (p0 << 96) | (p1 << 64) | (p2 << 32) | p3
        require((tick, live_f, sec, svc) == (steps, divisor, secondary, services),
                f'Wrong scheduled ticks/rate/service phase at world tick {tick}')
        require(Fraction(phase, DENOMINATOR) == credit,
                f'Wrong fractional world phase at world tick {tick}')
        if native_f != live_f:
            old_debt_rows += 1
    require(event == 3 and old_debt_rows > 0, 'Old-debt rate isolation was not exercised')
    return dict(rate_changes=count, rows=len(rows), exact_world_phase=True,
                exact_secondary_phase=True, native_queue_test=True,
                old_debt_rows=old_debt_rows, publication_debts=publication_debts,
                queue_high_water=high)
