import unittest
from overlay_blit_check import initial,expected


class OverlayBlitReferenceTests(unittest.TestCase):
    def test_lfsr_covers_all_nonzero_bytes(self):
        data=initial()
        self.assertEqual(data[:4],bytes.fromhex('5ab475ea'))
        self.assertEqual(set(data[:255]),set(range(1,256)))
        self.assertEqual(data[:255],data[255:510])

    def test_guards_and_source_immutable_in_both_geometries(self):
        before=initial()
        for case in (1,2):
            after=expected(case)
            self.assertEqual(after[:16],before[:16])
            self.assertEqual(after[40016:],before[40016:])
            self.assertNotEqual(after[16:40016],before[16:40016])


if __name__=='__main__':unittest.main()
