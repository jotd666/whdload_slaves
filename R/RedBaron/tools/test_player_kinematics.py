import unittest
from player_kinematics import integrate, scaled_delta


class OriginalArithmeticTests(unittest.TestCase):
    def test_dt_discontinuity(self):
        self.assertEqual(scaled_delta(100, 400), 156)
        self.assertEqual(scaled_delta(100, 401), 200)
        self.assertEqual(scaled_delta(100, 450), 200)

    def test_high_dt_word_overflow_precedes_bound(self):
        self.assertEqual(scaled_delta(20000, 450), -25536)
        self.assertEqual(scaled_delta(-16384, 450), -32767)

    def test_signed_fraction_preserves_negative_rounding(self):
        self.assertEqual(integrate(0, 0, 100, 100, 0, 256, 220), (21, 496))
        self.assertEqual(integrate(0, 0, -100, -100, 0, 256, 220), (-22, -496))
        self.assertEqual(integrate(0, -1000, -100, -100, 0, 256, 220), (-23, -472))


if __name__ == '__main__':
    unittest.main()
