import copy
import unittest
from game_time_core import DENOMINATOR, THRESHOLD, limbs
from field_capacity import check


class FieldCapacityTests(unittest.TestCase):
    def sample(self):
        def state(field,cia,draws):
            ticks,credit=divmod(cia*(DENOMINATOR//33)*1024,THRESHOLD)
            return dict(field=field,cia=cia,cursor=cia,started=ticks,completed=ticks,due=0,
                        draws=draws,active=1,paused=0,divisor=33,
                        **{f'phase{i}':n for i,n in enumerate(limbs(credit))})
        return dict(sha256='fixture',windows=[dict(before=state(0,0,0),after=state(250,297,2),
                    publications=[dict(field=100,beam=245<<8),dict(field=200,beam=10<<8)],events={})])

    def test_actual_publications_and_exact_field_duration(self):
        result=check(self.sample())['windows'][0]
        self.assertEqual(result['publication_fps'],.4)
        self.assertEqual(result['elapsed_fields'],250)
        self.assertTrue(result['exact_funding'])

    def test_reject_invalid_census(self):
        for change in ('field','beam','count'):
            data=copy.deepcopy(self.sample());w=data['windows'][0]
            if change=='field':w['after']['field']=251
            elif change=='beam':w['publications'][0]['beam']=100<<8
            else:w['after']['draws']=9
            with self.subTest(change=change),self.assertRaises(ValueError):check(data)
