import unittest
from game_time_core import DENOMINATOR, THRESHOLD, limbs
from time_capacity import interval


class TimeCapacityTests(unittest.TestCase):
    def state(self,cursor,now,completed):
        steps,credit=divmod(cursor*DENOMINATOR//33*1024,THRESHOLD)
        return dict(active=1,paused=0,divisor=33,started=steps,completed=completed,due=0,
                    cia=now,cursor=cursor,field=now,draws=now//20,
                    **{f'phase{i}':n for i,n in enumerate(limbs(credit))})

    def test_completed_work_separate_from_retained_debt(self):
        a=self.state(0,0,0);b=self.state(30,60,3)
        r=interval(a,b)
        self.assertEqual(r['completed_world_ticks'],3)
        self.assertEqual(r['in_progress_after'],1)
        self.assertEqual(r['unprocessed_cia_after'],30)
        self.assertLess(r['completed_over_nominal'],.5)
        self.assertTrue(r['exact_funding'])

    def test_reject_dropped_credit(self):
        a=self.state(0,0,0);b=self.state(30,30,4);b['phase3']^=1
        with self.assertRaises(ValueError):interval(a,b)
