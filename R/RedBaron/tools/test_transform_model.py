import unittest
from transform_model import original,candidate,cases

class TransformTest(unittest.TestCase):
    def test_all_synthetic_cases(self):
        for idx,v,m,kind,scale in cases():self.assertEqual(original(v,m,kind,scale),candidate(v,m,kind,scale))
    def test_zero_and_overflow(self):
        self.assertEqual(original([0x8000]*3,[0x8000]*9,2,14),[0xc0000000]*3)
        self.assertEqual(candidate([0x8000]*3,[0x8000]*9,2,14),[0xc0000000]*3)
        self.assertEqual(candidate([0xffff,1,2],[0]*9,0,64),[0xffffffff,1,2])
    def test_type_one_retains_unrotated_z(self):
        self.assertEqual(candidate([1,2,3],[0]*9,1,7),[0,0,384])

if __name__=='__main__':unittest.main()
