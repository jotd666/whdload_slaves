import unittest
import tempfile
from pathlib import Path
from presentation_math import position, angle, phase_fraction, vectors, write_cases
from game_time_core import THRESHOLD


class PresentationMathTests(unittest.TestCase):
    def test_generated_vectors_match_source(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp)/'cases.i'
            write_cases(output)
            expected = Path(__file__).resolve().parents[1]/'usr/source/time-present-cases.i'
            self.assertEqual(output.read_bytes(), expected.read_bytes())

    def test_extreme_positions_and_rounding(self):
        self.assertEqual(position(-2147483648, 2147483647, 32768), -1)
        self.assertEqual(position(2147483647, -2147483648, 32768), -1)
        self.assertEqual(position(0, -1, 1), -1)
        for mode, old, new, fraction, value in vectors():
            if not mode:
                self.assertTrue(min(old,new) <= value <= max(old,new))
                if fraction == 0: self.assertEqual(value, old)
                if fraction == 65536: self.assertEqual(value, new)
                # Complementary weighted form, no endpoint subtraction.
                self.assertEqual(value, (old*(65536-fraction)+new*fraction)//65536)

    def test_angle_wrap_and_half_turn(self):
        self.assertEqual(angle(65530, 10, 32768), 2)
        self.assertEqual(angle(10, 65530, 32768), 2)
        self.assertEqual(angle(0, 32768, 32768), 49152)
        for delta in range(65536):
            self.assertEqual(angle(123, (123+delta)&65535, 65536), (123+delta)&65535)

    def test_phase_bounds_and_monotonicity(self):
        self.assertEqual(phase_fraction(0), 0)
        self.assertEqual(phase_fraction(THRESHOLD-1), 65535)
        last = -1
        for i in range(1001):
            value = phase_fraction((THRESHOLD-1)*i//1000)
            self.assertGreaterEqual(value, last)
            last = value
        with self.assertRaises(ValueError): phase_fraction(THRESHOLD)
        with self.assertRaises(ValueError): position(0, 1, 65537)
        with self.assertRaises(ValueError): angle(-1, 0, 0)


if __name__ == '__main__': unittest.main()
