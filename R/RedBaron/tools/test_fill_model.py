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

class CpuFillTests(unittest.TestCase):
    def test_all_horizontal_edges_and_long_alignment(self):
        from fill_model import cpu_plane
        rng=random.Random(0xe3)
        for base in (0,2):
            data=rng.randbytes(44)
            row=[int.from_bytes(data[base+i:base+i+2],'big') for i in range(0,40,2)]
            for x in range(320):
                for width in range(1,321-x):
                    first,last,words=setup(x,width)
                    for colour in (0,1):
                        actual,longs=cpu_plane(data,base+(x//16)*2,words,1,first,last,colour)
                        expected=bytearray(data)
                        expected[base:base+40]=b''.join(v.to_bytes(2,'big') for v in pixel_reference(row,x,width,colour))
                        self.assertEqual(actual,expected,(base,x,width,colour))
                        self.assertTrue(all(at%4==0 for at in longs))

    def test_multiple_rows_preserve_gaps_and_guards(self):
        from fill_model import cpu_plane
        rng=random.Random(0x2fd8a)
        for rows in (1,2,17,200):
            for x,width in ((0,320),(1,1),(15,2),(16,304),(17,207),(319,1)):
                for colour in (0,1):
                    data=rng.randbytes(40*(rows+2));first,last,words=setup(x,width)
                    actual,_=cpu_plane(data,40+(x//16)*2,words,rows,first,last,colour)
                    expected=bytearray(data)
                    for y in range(1,rows+1):
                        row=[int.from_bytes(data[y*40+i:y*40+i+2],'big') for i in range(0,40,2)]
                        expected[y*40:(y+1)*40]=b''.join(v.to_bytes(2,'big') for v in pixel_reference(row,x,width,colour))
                    self.assertEqual(actual,expected)

    def test_unsupported_dimensions_fall_back(self):
        from fill_model import cpu_plane
        for offset,w,h,pitch in ((1,20,1,40),(0,0,1,40),(0,21,1,40),(0,20,201,40),(0,20,1,80)):
            self.assertIsNone(cpu_plane(bytes(10000),offset,w,h,65535,65535,1,pitch))


if __name__ == '__main__':
    unittest.main()
