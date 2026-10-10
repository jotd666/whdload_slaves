import unittest
from overlay_snapshot import changed_pixels


class OverlaySnapshotTests(unittest.TestCase):
    def test_colour_bits_count_as_one_pixel(self):
        r=changed_pixels(bytes(4),bytes([0,1,0,1]),1,2,2)
        self.assertEqual(r,dict(changed_pixels=1,bounds=[7,1,7,1]))

    def test_unchanged_opaque_pixel_does_not_reveal_coverage(self):
        self.assertEqual(changed_pixels(b'\xff',b'\xff',1,1,1),dict(changed_pixels=0,bounds=None))

    def test_reject_bad_payload(self):
        with self.assertRaises(ValueError):changed_pixels(b'\0',b'\0\0',1,1,1)


if __name__=='__main__':unittest.main()
