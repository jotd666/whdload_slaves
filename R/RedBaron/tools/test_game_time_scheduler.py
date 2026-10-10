import random
import unittest
from fractions import Fraction
from game_time_scheduler import InputQueue, Scheduler, elapsed32, input_deadline


class SchedulerTests(unittest.TestCase):
    def test_producer_boundary_excludes_late_same_tick_input(self):
        s = Scheduler(divisor=10)
        s.change_rate(0, multiplier=8)
        s.observe(1)
        s.input.push(input_deadline(1), 'held', 'fire', 1)
        self.assertTrue(all(not t.held for t in s.run(10)))
        s.observe(2)
        self.assertTrue(all(t.held == (('fire', 1),) for t in s.run(10)))

    def test_unsigned_wrap_and_ambiguous_jump(self):
        self.assertEqual(elapsed32(0xfffffff0, 0x10), 32)
        for old, new in ((10, 9), (0, 0x80000000), (-1, 0)):
            with self.assertRaises(ValueError):
                elapsed32(old, new)

    def test_deadlines_inputs_and_remainder_ignore_render_partition(self):
        rng = random.Random(602)
        for quantum in (64, 100, 225):
            for divisor in (10, 33, 80):
                cases = []
                for cuts in ([1000], sorted({*range(1, 1001, 7), 1000}),
                             sorted({rng.randrange(1, 1000) for _ in range(100)} | {1000})):
                    s = Scheduler(divisor=divisor, quantum=quantum)
                    for stamp, kind, key, val in ((20, 'held', 'right', 1),
                            (35, 'command', 'throttle+', None), (40, 'command', 'throttle+', None),
                            (70, 'held', 'right', 0), (900, 'held', 'fire', 1)):
                        s.input.push(stamp, kind, key, val)
                    rows, services = [], []
                    for cut in cuts:
                        s.observe(cut)
                        rows += s.run(10000)
                        services += s.service(10000)
                    cases.append((rows, services, s.credit, s.service_credit))
                self.assertEqual(cases[0], cases[1])
                self.assertEqual(cases[0], cases[2])
                self.assertEqual(sum(len(t.commands) for t in cases[0][0]), 2)

    def test_new_input_does_not_change_old_debt(self):
        s = Scheduler()
        s.observe(100)
        s.input.push(80, 'held', 'right', 1)
        rows = s.run(100)
        self.assertTrue(all(not t.held for t in rows if t.deadline < 80))
        self.assertTrue(all(t.held == (('right', 1),) for t in rows if t.deadline >= 80))

    def test_bounded_batches_keep_debt_and_suppress_render(self):
        s = Scheduler()
        s.observe(1000)
        due = len(s.pending)
        self.assertFalse(s.may_render)
        self.assertEqual(len(s.run(4)), 4)
        self.assertEqual(len(s.pending), due-4)
        while s.pending:
            s.run(4)
        self.assertFalse(s.may_render)  # Real-time services also owe work.
        s.service(1000)
        self.assertTrue(s.may_render)
        self.assertEqual(s.steps, due)

    def test_rate_changes_preserve_exact_world_fraction(self):
        s = Scheduler()
        s.observe(1)
        old = s.credit
        s.change_rate(1, divisor=80)
        self.assertEqual(s.credit, old)
        s.change_rate(3, multiplier=8)
        s.observe(8)
        total = Fraction(1024, 33)+2*Fraction(1024, 80)+5*Fraction(8192, 80)
        self.assertEqual(len(s.pending)*225+s.credit, total)
        self.assertEqual(len(s.service_pending)*128+s.service_credit, 8*Fraction(1024, 20))

    def test_pause_rebases_time_preserving_fraction_and_held_state(self):
        s = Scheduler(now=0xfffffff0)
        s.pause(0xfffffff5)
        credit = s.credit
        s.run(100)
        s.service(100)
        s.resume(0x100, held=(('right', 0),))
        self.assertEqual(s.credit, credit)
        self.assertEqual(s.active_time, 5)
        s.observe(0x105)
        self.assertEqual(s.active_time, 10)
        self.assertEqual(len(s.pending)*225+s.credit, Fraction(10*1024, 33))
        self.assertEqual(s.run(100)[0].held, (('right', 0),))

    def test_resume_cannot_rewrite_unconsumed_input_history(self):
        s = Scheduler()
        s.pause(100)
        with self.assertRaises(ValueError):
            s.resume(200)

    def test_input_overflow_and_late_events_fail_without_eviction(self):
        q = InputQueue(2)
        q.push(1, 'command', 'a')
        q.push(2, 'command', 'b')
        with self.assertRaises(OverflowError):
            q.push(3, 'command', 'c')
        self.assertTrue(q.overflow)
        self.assertEqual(q.consume(3)[1], ('a', 'b'))
        with self.assertRaises(ValueError):
            q.push(2, 'held', 'right', 1)

    def test_same_deadline_compressed_ticks_do_not_repeat_commands(self):
        s = Scheduler(divisor=10)
        s.change_rate(0, multiplier=8)
        s.input.push(1, 'command', 'throttle+')
        s.observe(1)
        rows = s.run(10)
        self.assertEqual(len(rows), 3)
        self.assertEqual([r.deadline for r in rows], [1, 1, 1])
        self.assertEqual([r.commands for r in rows], [('throttle+',), (), ()])


if __name__ == '__main__':
    unittest.main()
