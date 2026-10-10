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

    def test_reject_uncommitted_transaction_at_either_endpoint(self):
        for endpoint in (0,1):
            for transaction in (1,2,3):
                with self.subTest(endpoint=endpoint,transaction=transaction):
                    rows=[self.state(0,0,0),self.state(30,30,4)]
                    rows[endpoint]['transaction']=transaction
                    with self.assertRaisesRegex(ValueError,'uncommitted clock transaction'):
                        interval(*rows)

    def test_committed_marker_preserves_legacy_result(self):
        rows=[self.state(0,0,0),self.state(30,30,4)]
        expected=interval(*rows)
        for row in rows:row['transaction']=0
        self.assertEqual(interval(*rows),expected)
