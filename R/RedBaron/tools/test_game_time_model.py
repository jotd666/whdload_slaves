import random
import unittest
from game_time_model import fixed_ticks, tick_deadline, budget
from player_kinematics import scaled_delta


class GameTimePlanTests(unittest.TestCase):
    def test_render_partition_does_not_change_time(self):
        rng = random.Random(601)
        for divisor in (10, 33, 80):
            for total in (0, 1, 255, 65536, 1000000):
                cuts = sorted({0, total} | {rng.randrange(total+1) for _ in range(30)})
                chunks = [b-a for a, b in zip(cuts, cuts[1:])]
                self.assertEqual(fixed_ticks(chunks, divisor), fixed_ticks([total], divisor))
                count, credit = fixed_ticks(chunks, divisor)
                self.assertEqual(count*divisor*225+credit, total*1024)
                self.assertLess(credit, divisor*225)

    def test_fixed_deadlines_are_independent_of_render_arrival(self):
        for divisor in (10, 33, 80):
            for index in (1, 10, 10000):
                deadline = tick_deadline(index, divisor)
                first_integer_tick = -(-deadline.numerator // deadline.denominator)
                self.assertLess(fixed_ticks([first_integer_tick-1], divisor)[0], index)
                self.assertGreaterEqual(fixed_ticks([first_integer_tick], divisor)[0], index)

    def test_large_dt_does_not_increase_motion_proportionally(self):
        for velocity in (-1000, -100, 0, 100, 1000):
            self.assertEqual(scaled_delta(velocity, 450), scaled_delta(velocity, 900))
            self.assertEqual(scaled_delta(velocity, 450), scaled_delta(velocity, 2200))
        self.assertNotEqual(2*scaled_delta(100, 225), scaled_delta(100, 450))

    def test_budget_rejects_unsustainable_tick_rate(self):
        self.assertFalse(budget(59.2, 405, 59.11, quantum=100)['feasible'])
        self.assertTrue(budget(59.2, 405, 59.11, quantum=225)['feasible'])

    def test_invalid_elapsed_time_is_not_silently_dropped(self):
        with self.assertRaises(ValueError):
            fixed_ticks([10, -1])
