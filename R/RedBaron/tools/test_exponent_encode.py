import random
import unittest
from exponent_encode import original,candidate,cases


class ExponentEncodeTests(unittest.TestCase):
    def test_boundaries_and_all_condition_codes(self):
        for value,d2,expected in cases():
            for ccr in range(32):
                self.assertEqual(candidate(value,d2,ccr),original(value,d2,ccr))
                self.assertEqual(candidate(value,d2,ccr)[0],expected)

    def test_preserves_upper_output_and_original_d2_flag_semantics(self):
        self.assertEqual(original(0,0x80000000,31),(0,0,0x80000000,24))
        self.assertEqual(original(0,0,31),(0,0,0,20))
        self.assertEqual(original(0x12345678,0,31),(0x67801c23,0,0,4))
        self.assertEqual(original(0x80000000,1,31),(0x1f00,0,1,0))

    def test_full_word_and_reproducible_longword_sweep(self):
        for value in range(65536):
            self.assertEqual(candidate(value,0xffffffff,31),original(value,0xffffffff,31))
        rng=random.Random(0x6813)
        for _ in range(10000):
            v,d2,ccr=rng.getrandbits(32),rng.getrandbits(32),rng.randrange(32)
            self.assertEqual(candidate(v,d2,ccr),original(v,d2,ccr))
