from fractions import Fraction
import random
import struct
import unittest
from game_time_core import THRESHOLD
from game_time_debt import LIMIT, phase_upper, drop_due, check_quantum_twin

class DebtTests(unittest.TestCase):
    def test_bound_and_small_rounding_reserve(self):
        rng = random.Random(1800)
        for quantum in (225, 450):
            for _ in range(10000):
                phase = rng.randrange(THRESHOLD)
                units = Fraction(phase*quantum, THRESHOLD)
                self.assertGreaterEqual(phase_upper(phase, quantum), units)
                self.assertLess(phase_upper(phase, quantum)-units, 2)
                divisor = rng.randrange(10, 81)
                multiplier = rng.choice([1, 8])
                remaining = rng.randrange(201)
                due = rng.randrange(1, 1+(820+quantum-1)//quantum)
                actual = units + due*quantum + Fraction(remaining*1024*multiplier, divisor)
                if drop_due(phase, due, remaining, divisor, multiplier, quantum):
                    self.assertGreater(actual, LIMIT-2)
                else:
                    self.assertLessEqual(actual, LIMIT)
    def test_normal_catchup_and_overload(self):
        for quantum in (225, 450):
            self.assertFalse(drop_due(0, 1, 20, 33, quantum=quantum))
            self.assertTrue(drop_due(0, 1, 200, 33, quantum=quantum))
            self.assertTrue(drop_due(0, 1, 20, 33, 8, quantum))
    def test_twin_sabotages(self):
        def pack(v): return b'RBTQ4501' + struct.pack('>5I', *v)
        self.assertEqual(check_quantum_twin(pack([1, 30, 20, 10, 0]))['calls'], 30)
        for values in ([1, 30, 20, 10, 1], [1, 30, 30, 0, 0], [1, 31, 20, 10, 0]):
            with self.assertRaises(ValueError): check_quantum_twin(pack(values))
