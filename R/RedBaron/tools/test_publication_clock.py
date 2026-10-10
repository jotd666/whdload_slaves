import copy
import unittest
from game_time_core import DENOMINATOR, THRESHOLD, limbs
from publication_clock import check


class PublicationClockTests(unittest.TestCase):
    def sample(self):
        rows=[]
        for i in range(20):
            ticks,credit=divmod(i*DENOMINATOR//33*1024,THRESHOLD)
            row=dict(field=(0xfffffff8+i)&0xffffffff,beam=10<<8,cia=100+i,cursor=100+i,
                     mask=8960,active=1,due=0,steps=ticks,divisor=33)
            row.update({f'phase{j}':v for j,v in enumerate(limbs(credit))})
            rows.append(row)
        return dict(sha256='fixture',rows=rows)

    def test_wrap_and_render_only_intervals(self):
        r=check(self.sample(),1)
        self.assertTrue(r['counter_wrapped'])
        self.assertEqual(r['exact_clock_intervals'],19)
        self.assertGreater(r['repeated_world_tick_pairs'],0)

    def test_reject_lost_tick_credit_and_unsafe_publication(self):
        for field,value in [('steps',99),('phase3',0),('field',0xfffffff8),('beam',100<<8),('mask',8192)]:
            with self.subTest(field=field):
                data=copy.deepcopy(self.sample());data['rows'][1][field]=value
                with self.assertRaises(ValueError):check(data,1)

    def test_two_field_policy_rejects_one_field(self):
        with self.assertRaises(ValueError):check(self.sample(),2)
