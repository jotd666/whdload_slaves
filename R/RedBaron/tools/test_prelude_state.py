import unittest
from prelude_state import validate


class PreludeStateTests(unittest.TestCase):
    def fixture(self):
        return dict(active=0,count=51,clocks=[225,225]),[dict(tick=0,active=1,count=51,clocks=[341,450]),dict(tick=1,active=1,count=51,clocks=[225,64])]

    def test_handoff_allows_scheduler_secondary_clock(self):
        before,rows=self.fixture();validate(before,rows)

    def test_reject_missing_or_active_prelude(self):
        for field,value in [('active',1),('count',0),('clocks',[225,450])]:
            before,rows=self.fixture();before[field]=value
            with self.assertRaises(ValueError):validate(before,rows)

    def test_reject_later_fixture_write_or_bad_boundary(self):
        for field,value in [('count',52),('active',0),('tick',2),('clocks',[450,64])]:
            before,rows=self.fixture();rows[1][field]=value
            with self.assertRaises(ValueError):validate(before,rows)
        before,rows=self.fixture()
        with self.assertRaises(ValueError):validate(before,[])
