from fractions import Fraction
import random
import unittest
from game_time_core import DENOMINATOR, THRESHOLD, advance, vectors


class NativeClockCoreTests(unittest.TestCase):
    def test_every_native_case_against_rational_oracle(self):
        for quantum in (225, 450):
            for credit, secondary, divisor, multiplier, result in vectors(quantum):
                phase, sec, world, service = result
                expected = Fraction(credit*quantum, DENOMINATOR*225)+Fraction(1024*multiplier, divisor)
                self.assertEqual(world*quantum+Fraction(phase*quantum, DENOMINATOR*225), expected)
                self.assertEqual(secondary+1024, service*2560+sec)
                self.assertLess(phase, THRESHOLD)
                self.assertLessEqual(world, 4)

    def test_long_mixed_rate_sequence_preserves_fraction(self):
        rng = random.Random(604)
        credit = secondary = worlds = services = 0
        expected = Fraction(0)
        for _ in range(10000):
            divisor, multiplier = rng.randrange(10, 81), rng.choice((1, 8))
            credit, secondary, world, service = advance(credit, secondary, divisor, multiplier)
            worlds += world
            services += service
            expected += Fraction(1024*multiplier, divisor)
        self.assertEqual(worlds*225+Fraction(credit, DENOMINATOR), expected)
        self.assertEqual(services*2560+secondary, 10000*1024)

    def test_all_intermediates_fit_four_longs(self):
        biggest = THRESHOLD-1+(DENOMINATOR//10)*8192
        self.assertLess(biggest, 1 << 128)

    def test_invalid_phase_and_rate_rejected(self):
        for args in ((THRESHOLD,0,33,1),(0,2560,33,1),(0,0,9,1),(0,0,33,2)):
            with self.assertRaises(ValueError):
                advance(*args)


class CPUQuantumTests(unittest.TestCase):
    def test_both_quanta_keep_exact_funding(self):
        from fractions import Fraction
        from game_time_core import advance
        for quantum in (225, 450):
            phase = service = steps = 0
            expected = Fraction(0)
            for f, multiplier in [(33, 1)]*100 + [(80, 1)]*100 + [(10, 8)]*100:
                phase, service, due, _ = advance(phase, service, f, multiplier, quantum)
                steps += due
                expected += Fraction(1024*multiplier, f)
                self.assertEqual(steps*quantum + Fraction(phase*quantum, DENOMINATOR*225), expected)
