import copy
import struct
import unittest
from message_time import DURATION, remaining, legacy, shortened, check_capture


class MessageTimeTests(unittest.TestCase):
    def test_full_lifetime_and_priority_halfway(self):
        self.assertEqual(legacy(DURATION), 15000)
        self.assertEqual(legacy(89), 7500)
        self.assertLess(legacy(88), 7500)
        self.assertEqual(legacy(0), 1)  # pending-render sentinel

    def test_clock_wrap_and_expiry(self):
        start = 0xffffffd0
        end = (start + DURATION) & 0xffffffff
        for elapsed in range(300):
            self.assertEqual(remaining(end, (start + elapsed) & 0xffffffff),
                             max(0, DURATION - elapsed))

    def test_shortening_rounds_up_by_less_than_one_interval(self):
        for value in range(15001):
            intervals = shortened(value)
            self.assertGreaterEqual(intervals * 15000, value * DURATION)
            self.assertLess(intervals * 15000, value * DURATION + 15000)
        self.assertEqual(shortened(5000), 60)
        self.assertEqual(shortened(0), 0)

    def test_draws_do_not_spend_lifetime_or_hidden_steps_consume_dirty_buffers(self):
        for render_schedule in (set(), set(range(400)), {0, 200, 300}):
            end = 40 + DURATION
            dirty = 0
            pending = False
            expired = []
            for now in range(400):
                if now == end:
                    pending = True
                    dirty = 2
                    expired.append(now)
                if now in render_schedule:
                    dirty = max(0, dirty - 1)
                    if pending:
                        pending = False
                        dirty = 2  # native erasure publishes the clean background
            self.assertEqual(expired, [218])
            if not render_schedule:
                self.assertTrue(pending)
                self.assertEqual(dirty, 2)

    def capture(self):
        # Real combat messages may replace one another between fixture windows.
        events = [
            [0, 178, 1, 1, 15000, 0, 0, 1],
            [16, 194, 1, 1, 15000, 2, 2, 2],
            [32, 92, 2, 1, 5000, 2, 4, 2],
            [92, 92, 3, 2, 1, 2, 9, 2],
            [98, 92, 4, 0, 0, 1, 10, 2],
            [110, 288, 1, 1, 15000, 0, 11, 4],
            [140, 318, 1, 1, 15000, 2, 14, 5],
            [240, 418, 1, 1, 15000, 2, 24, 3],
            [418, 418, 3, 2, 1, 2, 41, 3],
            [420, 418, 4, 0, 0, 1, 42, 3],
            [480, 658, 1, 1, 15000, 0, 48, 1],
            [510, 570, 2, 1, 5000, 0, 51, 1],
            [570, 570, 3, 2, 1, 2, 57, 1],
            [580, 570, 4, 0, 0, 1, 58, 1],
        ]
        rows = [[1, 1, 1, legacy(177), 0, 0, 178, 1],
                [10, 92, 2, 1, 2, 9, 92, 2],
                [20, 160, 1, legacy(158), 0, 16, 318, 5],
                [70, 700, 0, 0, 0, 70, 570, 1]]
        erasures = [[98, 0, 2, 10, 1000, 2000], [420, 0, 2, 42, 2000, 1000],
                    [580, 0, 2, 58, 1000, 2000]]
        return events, rows, erasures

    def validate(self, events, rows, erasures):
        return check_capture(b''.join(struct.pack('>II4HII', *e) for e in events),
                             len(events), 0, rows, erasures, 179, [1, 2, 3])

    def test_native_combat_replacements_are_validated(self):
        result = self.validate(*self.capture())
        self.assertEqual(result['events'], 14)
        self.assertEqual(result['fixture_events'], 12)
        self.assertEqual(result['native_erasures'], 3)

    def test_replacement_before_next_paint_preserves_dirty_work(self):
        events, rows, erasures = self.capture()
        del events[9]  # The full message expires, but no render occurs before replacement.
        events[9][5] = 2  # Native replacement republishes the old rectangle.
        del erasures[1]
        result = self.validate(events, rows, erasures)
        self.assertEqual(result['pending_replacements'], 1)
        events[9][5] = 0
        with self.assertRaises(ValueError):
            self.validate(events, rows, erasures)

    def test_corruption_is_rejected(self):
        mutations = [
            (0, 0, 1, 179),   # incorrect full deadline
            (0, 2, 1, 91),    # incorrect shortening
            (0, 3, 0, 93),    # late expiry
            (0, 3, 5, 1),     # only one buffer dirtied
            (0, 4, 0, 91),    # premature cleanup
            (0, 6, 4, 10000), # malformed natural combat event
            (1, 0, 3, 15000), # timer still ages by frames
            (1, 3, 4, 1),     # final buffer remains dirty
            (2, 0, 2, 1),     # native erase skipped a buffer
        ]
        for collection, index, column, value in mutations:
            with self.subTest(mutation=(collection, index, column, value)):
                data = copy.deepcopy(self.capture())
                data[collection][index][column] = value
                with self.assertRaises(ValueError):
                    self.validate(*data)


if __name__ == '__main__': unittest.main()
