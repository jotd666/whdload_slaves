import struct
import unittest
from copy import deepcopy
from fractions import Fraction
from game_time_core import DENOMINATOR
from rate_history import check_capture, due


class RateTests(unittest.TestCase):
    def test_unsigned_deadline_wrap(self):
        self.assertTrue(due(0, 0xffffffff))
        self.assertFalse(due(0xffffffff, 0))
        self.assertTrue(due(0, 0))

    def evidence(self):
        initial = bytearray(60)
        queue = bytearray(268)
        initial_queue = bytearray(268)
        struct.pack_into('>HH', initial_queue, 8, 33, 33)
        struct.pack_into('>6H', queue, 0, 3, 3, 0, 2, 33, 33)
        log = bytearray()
        events = ((11, 10), (21, 80), (31, 33))
        for i, (deadline, f) in enumerate(events):
            struct.pack_into('>IHH', queue, 12 + i * 8, deadline, f, 0)
            log += struct.pack('>4I2HI', deadline - 1, 0, deadline - 5, deadline, f, 33, 1)
        rows = []
        credit = Fraction(0)
        secondary = services = steps = 0
        divisor = 33
        for cursor in range(1, 65):
            for deadline, f in events:
                if cursor == deadline: divisor = f
            credit += Fraction(1024, divisor)
            earned, credit = divmod(credit, 225)
            service, secondary = divmod(secondary + 1024, 2560)
            services += service
            if earned:
                steps += int(earned)
                phase = int(credit * DENOMINATOR)
                rows.append([steps, cursor, 0, divisor, 10 if cursor < 11 else divisor,
                             secondary, services,
                             *[(phase >> shift) & 0xffffffff for shift in (96, 64, 32, 0)], cursor + 5])
        return [initial, initial_queue, queue, log, 3, rows, 1]

    def test_exact_rate_history(self):
        self.assertEqual(check_capture(*self.evidence())['rate_changes'], 3)

    def test_retroactive_rate_wrong_phase_lost_ticks_and_overflow_rejected(self):
        for mutation in ('rate', 'phase', 'tick', 'deadline', 'service', 'overflow'):
            with self.subTest(mutation=mutation):
                args = deepcopy(self.evidence())
                if mutation == 'rate': args[5][0][3] = 10
                elif mutation == 'phase': args[5][1][10] ^= 1
                elif mutation == 'tick': args[5][1][0] += 1
                elif mutation == 'service': args[5][1][6] += 1
                elif mutation == 'deadline': struct.pack_into('>I', args[2], 12, 10)
                elif mutation == 'overflow': struct.pack_into('>H', args[2], 4, 1)
                with self.assertRaises(ValueError): check_capture(*args)


if __name__ == '__main__': unittest.main()
