import unittest
from cockpit_raster import composite,cache_geometry,line_points


class CockpitRasterTests(unittest.TestCase):
    def test_mask_can_paint_zero_and_preserve_background(self):
        # One mask is shared by both planes, including opaque zero-colour bits.
        self.assertEqual(composite(bytes.fromhex('ffff1234'),bytes.fromhex('0000ffff'),bytes.fromhex('8001')),bytes.fromhex('7ffe9235'))

    def test_zero_mask_and_full_mask(self):
        self.assertEqual(composite(b'\x12\x34',b'\xab\xcd',b'\x00'),b'\x12\x34')
        self.assertEqual(composite(b'\x12\x34',b'\xab\xcd',b'\xff'),b'\xab\xcd')

    def test_word_aligned_cache_bounds(self):
        mask=bytearray(120);mask[41]=1;mask[83]=128
        self.assertEqual(cache_geometry(mask),dict(x=0,y=1,width=32,height=2,plane_bytes=8,image_bytes=40,mask_bytes=8,total_chip_bytes=48))

    def test_line_endpoint_and_direction(self):
        self.assertEqual(list(line_points(2,3,2,1)),[(2,3),(2,2),(2,1)])
        self.assertEqual(list(line_points(0,0,3,1)),[(0,0),(1,0),(2,1),(3,1)])

    def test_reject_bad_geometry(self):
        with self.assertRaises(ValueError):composite(b'\0',b'\0\0',b'\xff')
        with self.assertRaises(ValueError):cache_geometry(bytes(40))


if __name__=='__main__':unittest.main()
