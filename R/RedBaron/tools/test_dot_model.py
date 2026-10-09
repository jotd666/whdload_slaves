import unittest
from dot_model import original,candidate,cases

class DotTest(unittest.TestCase):
    def test_synthetic_cases(self):
        for v,n in cases():self.assertEqual(candidate(v,n),original(v,n))
    def test_signed_extremes(self):
        self.assertEqual(candidate([0x80000000,0,0],[0xffff,0,0]),0x80000000)
        self.assertEqual(candidate([0xffffffff,0,0],[0x8000,0,0]),0x8000)
        self.assertEqual(candidate([0x7fffffff]*3,[0x7fff]*3),0x7ffe8003)

if __name__=='__main__':unittest.main()
