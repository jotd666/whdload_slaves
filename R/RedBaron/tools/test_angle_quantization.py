import unittest
from angle_quantization import pitch,atan


class AngleQuantizationTests(unittest.TestCase):
    def test_pitch_discards_five_matrix_bits_before_table_lookup(self):
        table=list(range(513))
        for value in range(32,64):self.assertEqual(pitch(value,table),16)
        self.assertEqual(pitch(64,table),32)
        self.assertEqual(pitch(-63,table),-16)
        with self.assertRaises(ValueError):pitch(16385,table)

    def test_atan_cardinals_diagonals_and_wrap(self):
        table=[0]*512
        for x,y,expected in ((0,0,0),(1,0,0),(0,1,16384),(-1,0,-32768),
                             (0,-1,-16384),(1,1,8192),(-1,1,24576),
                             (-1,-1,-24576),(1,-1,-8192)):
            self.assertEqual(atan(x,y,table),expected)

    def test_atan_ratio_lookup_and_quadrant_reflection(self):
        table=list(range(512))
        self.assertEqual(atan(4,1,table),128*16)
        self.assertEqual(atan(1,4,table),(1024-128)*16)
        self.assertEqual(atan(-4,1,table),(2048-128)*16)
        self.assertEqual(atan(4,-1,table),-128*16)
        with self.assertRaises(ValueError):atan(-32768,1,table)
