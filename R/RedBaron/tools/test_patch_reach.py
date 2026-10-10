import unittest
from audit_patch_reach import audit


class PatchReachTests(unittest.TestCase):
    def listing(self,target,encoded):
        return f''' 1: PL_START
00:00001000 0003 1M dc.w PLCMD_PS
00:00001002 00002000 2M dc.l $2000
00:00001006 {encoded:04X} 3M dc.w destination-.patchlist
 2: PL_END
00:00001008 0000 1M dc.w PLCMD_END
destination 00:{target:08X}
'''

    def test_negative_and_positive_signed_limits(self):
        for delta in (-4096,0,32767):
            self.assertEqual(audit(self.listing(4096+delta,delta&65535)),(1,[]))

    def test_unsigned_word_that_assembles_but_points_outside(self):
        self.assertTrue(audit(self.listing(4096+32768,32768))[1])

    def test_mismatched_encoding(self):
        self.assertTrue(audit(self.listing(4098,3))[1])
