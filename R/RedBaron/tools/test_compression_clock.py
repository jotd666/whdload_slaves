import copy
import unittest
from compression_clock import check_capture
from game_time_core import advance, limbs


class CompressionClockTests(unittest.TestCase):
    def records(self):
        credit = secondary = 0
        before, after = [], []
        for tick in range(150):
            flag = int(20 <= tick < 80)
            rate = 8 if flag else 1
            head = [(0xfffffff0 + tick) & 0xffffffff, 10 if tick < 70 else 33, flag, rate]
            before.append(head + limbs(credit) + [secondary, 0, 0])
            credit, secondary, due, service = advance(credit, secondary, head[1], rate)
            after.append(head + limbs(credit) + [secondary, due, service])
        return before, after

    def test_changes_wrap_and_multiple_world_ticks(self):
        before, after = self.records()
        result = check_capture(before, after)
        self.assertEqual(result['compressed_boundaries'], 60)
        self.assertEqual(result['service_ticks'], 60)
        self.assertTrue(any(row[9] > 1 for row in after))

    def test_corrupted_native_records(self):
        before, after = self.records()
        for column in range(11):
            bad = copy.deepcopy(after)
            bad[40][column] += 1
            with self.subTest(column=column), self.assertRaises(ValueError):
                check_capture(before, bad)
        bad = copy.deepcopy(before)
        bad[50][9] = 1
        with self.assertRaises(ValueError):
            check_capture(bad, after)


if __name__ == '__main__': unittest.main()
