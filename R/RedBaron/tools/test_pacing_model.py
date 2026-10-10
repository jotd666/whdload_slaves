import unittest
from pacing_model import ready, safe_line, schedule, MASK


class PacingTests(unittest.TestCase):
    def test_modular_deadline_against_unbounded_reference(self):
        for minimum in (1, 2):
            for previous in (0, 1, 255, 65535, MASK - 2, MASK - 1, MASK):
                for elapsed in range(1000):
                    self.assertEqual(ready((previous + elapsed) & MASK, previous, minimum), elapsed >= minimum)
        self.assertTrue(ready(0, None))

    def test_fast_and_slow_frames_do_not_accumulate_debt(self):
        self.assertEqual(schedule([0, 0, 1, 3, 50, 50, 55]), [0, 2, 4, 6, 50, 52, 55])
        self.assertEqual(schedule([5, 35, 65, 95]), [5, 35, 65, 95])
        self.assertEqual(schedule([0, 0, 1, 3, 50, 50, 55], 1), [0, 1, 2, 3, 50, 51, 55])

    def test_original_beam_wait_boundaries(self):
        self.assertEqual([n for n in range(312) if not safe_line(n)], list(range(41, 245)))

    def test_replayed_vbl_registers_and_flags(self):
        from pacing_model import vbl_replay
        for word, flags in ((0, 4), (1, 0), (0x8000, 8), (0xffff, 8)):
            for x in (0, 16):
                before = dict(a1=0xfffffff8, a3=0, a4=0, a5=0, a6=0,
                              d0=0xabcd1234, d1=99, sp=100, ps=0x230f | x)
                after = vbl_replay(before, [10, 20, 30, 40], word)
                self.assertEqual(after, dict(a1=8, a3=10, a4=20, a5=30, a6=40,
                                            d0=0xabcd0000 | word, d1=99, sp=100,
                                            ps=0x2300 | x | flags))
                self.assertEqual(before['a1'], 0xfffffff8)
