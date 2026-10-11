import unittest
from native_timer import arm, expire, elapsed, observations


class NativeTimerTests(unittest.TestCase):
    def test_unsigned_clock_wrap_and_word_delay(self):
        self.assertEqual(arm(0xffffffff,0x10001),(0xffffffff,1))
        self.assertEqual(expire(0),(0xffffffff,0))
        self.assertEqual(elapsed(0,0xffffffff,1),0)
        self.assertEqual(elapsed(1,0xffffffff,1),1)
        self.assertEqual(elapsed(10,10,0),0)
        self.assertEqual(elapsed(10,10,100,False),1)

    def test_observed_stores_and_interrupt_uncertainty(self):
        events=[('ARM_BEFORE',[1,100,0,0,65538]),('ARM_AFTER',[1,100,100,2,65538]),
                ('EXPIRE_BEFORE',[2,0,100,0,3]),('EXPIRE_AFTER',[2,0,0xffffffff,0,3]),
                ('ARM_BEFORE',[3,200,0,0,5]),('ARM_AFTER',[3,201,201,5,5])]
        rows=observations(events)
        self.assertEqual([r['verified'] for r in rows],[True,True,False])
        self.assertIn('unverified',rows[-1]['reason'])

    def test_reject_corrupt_or_incomplete_pairs(self):
        before=('ARM_BEFORE',[1,100,0,0,2]); after=('ARM_AFTER',[1,100,100,2,2])
        for events in [[],[before],[after],[before,before,after],
                       [before,('ARM_AFTER',[2,100,100,2,2])],
                       [before,('ARM_AFTER',[1,100,99,2,2])],
                       [before,('EXPIRE_AFTER',[1,100,100,2,2])],
                       [before,('ARM_AFTER',[1,101,101,2,2])]]:
            with self.assertRaises(ValueError): observations(events)
