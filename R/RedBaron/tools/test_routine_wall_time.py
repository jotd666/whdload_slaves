import copy
import unittest
from routine_wall_time import summarize


class ClockTests(unittest.TestCase):
    def fixture(self):
        a=dict(step=8,vbl=100,line=300,hpos=10,sp=1000)
        b=dict(step=8,vbl=101,line=50,hpos=10,sp=1000)
        return dict(complete=True,vblank_phase=[dict(vbl=100,line=2),dict(vbl=101,line=5)],
                    calls=[dict(routine='world3d',entry=a,return_record=b)])

    def test_wrap_and_interrupt_inclusive_time(self):
        r=summarize(self.fixture(),8,8)
        self.assertAlmostEqual(r['summaries']['world3d']['mean_fields'],63/313)
        self.assertEqual(r['phase_safe_from_line'],6)

    def test_ambiguous_phase_remains_excluded(self):
        log=self.fixture()
        log['calls'].append(copy.deepcopy(log['calls'][0]))
        log['calls'][1]['entry']['line']=3
        r=summarize(log,8,8)
        self.assertEqual(len(r['accepted']),1)
        self.assertEqual(len(r['excluded']),1)

    def test_horizontal_wrap_is_not_guessed(self):
        log=self.fixture()
        log['calls'][0]['entry'].update(vbl=100,line=257,hpos=192)
        log['calls'][0]['return_record'].update(vbl=100,line=257,hpos=0)
        r=summarize(log,8,8)
        self.assertEqual(r['accepted'],[])
        self.assertEqual(r['excluded'][0]['reason'],'Ambiguous horizontal-counter boundary')

    def test_interior_negative_time_is_still_an_error(self):
        log=self.fixture()
        log['calls'][0]['entry'].update(vbl=100,line=250,hpos=100)
        log['calls'][0]['return_record'].update(vbl=100,line=249,hpos=200)
        with self.assertRaises(ValueError):summarize(log,8,8)

    def test_missing_phase_is_not_continuous(self):
        log=self.fixture();log['vblank_phase'][1]['vbl']=102
        with self.assertRaises(ValueError):summarize(log,8,8)


if __name__=='__main__':unittest.main()
