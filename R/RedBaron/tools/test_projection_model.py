"""Reference arithmetic tests; not a substitute for original-call or twin checks."""
import random
import unittest
from projection_model import norm_loop, norm_bl, p38c82, shift, check_calls


class ProjectionTests(unittest.TestCase):
    def test_normalization_strata(self):
        rng = random.Random(0x38c82)
        values = {0, 0xffffffff, 0x80000000}
        for bit in range(33):
            values.update(v for v in ((1 << bit) + d for d in (-2,-1,0,1,2))
                          if 0 <= v <= 0xffffffff)
        values.update(rng.getrandbits(32) for _ in range(200000))
        for width in (15,16):
            for value in values:
                self.assertEqual(norm_loop(value,width), norm_bl(value,width))

    def test_shifts_and_traps(self):
        self.assertEqual(shift(3,32),0)
        self.assertEqual(shift(3,64),3)
        self.assertEqual(shift(3,-64),3)
        self.assertEqual(shift(3,-1),1)
        with self.assertRaises(ZeroDivisionError):
            p38c82(1,1,0,1)
        with self.assertRaises(ValueError):
            check_calls([])

    def test_signs_zero_and_checker_rejection(self):
        self.assertEqual(p38c82(100,0,200,128), (64,0,44,72))
        self.assertEqual(p38c82((-100)&0xffffffff,0,200,128)[0],(-64)&0xffffffff)
        self.assertEqual(p38c82(0,0,200,128)[:2],(0,0))
        with self.assertRaises(ValueError):
            check_calls([dict(inputs=[100,0,200,128],outputs=[65,0,44,72])])


if __name__ == '__main__':
    unittest.main()
