import random
import unittest
from fill_model import blit, minterm, pixel_reference, setup

class FillModelTests(unittest.TestCase):
    def test_every_horizontal_rectangle(self):
        rng=random.Random(0xd1)
        row=[rng.randrange(65536) for _ in range(20)]
        for x in range(320):
            for width in range(1,321-x):
                for colour in (0,1):
                    expected=pixel_reference(row,x,width,colour)
                    self.assertEqual(blit(row,x,width,colour,candidate=False),expected,(x,width,colour))
                    self.assertEqual(blit(row,x,width,colour,candidate=True),expected,(x,width,colour))
    def test_gate_is_exact_word_alignment(self):
        for x in range(320):
            for width in range(1,321-x):
                first,last,_=setup(x,width)
                self.assertEqual(first==last==65535, x%16==0 and width%16==0)
    def test_disabled_c_is_irrelevant_for_every_c_word(self):
        for c in range(65536):
            self.assertEqual(minterm(65535,0,c,0xfa),65535)
            self.assertEqual(minterm(65535,65535,c,0x0a),0)

if __name__=='__main__':unittest.main()
