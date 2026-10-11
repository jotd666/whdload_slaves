import unittest
from instrument_pixels import Region, capture, matches, region


class InstrumentPixelsTests(unittest.TestCase):
    def test_native_inclusive_clip_and_word_padding(self):
        self.assertEqual(region((112, 143, 20, 15), (1, 1)), Region(12, 142, 6, 19))
        self.assertEqual(region((0, 0, 15, 1), (0, 0)), Region(0, 0, 2, 2))
        self.assertEqual(region((0, 0, 16, 1), (0, 0)), Region(0, 0, 4, 2))

    def test_wrap_and_out_of_screen_use_native_fallback(self):
        for rect, padding in [((0, 0, 20, 20), (1, 0)),
                              ((310, 190, 10, 10), (0, 0)),
                              ((32767, 20, 2, 2), (0, 0)),
                              ((20, 20, 0, 1), (0, 0)),
                              ((20, 20, 2, 2), (-1, 0)),
                              ((0, 0, 100, 20), (0, 0)),
                              ((0, 0, 20, 49), (0, 0))]:
            self.assertIsNone(region(rect, padding))

    def test_all_planes_rows_and_edges_are_guarded(self):
        screen = bytearray((i * 37 + i // 8000) & 255 for i in range(40000))
        for area in (Region(0, 0, 8, 48), Region(32, 152, 8, 48), Region(38, 199, 2, 1)):
            saved = capture(screen, area)
            self.assertTrue(matches(screen, area, saved))
            expected = b''.join(bytes(screen[p*8000+y*40+area.left:
                                             p*8000+y*40+area.left+area.row_bytes])
                                for p in range(5)
                                for y in range(area.top, area.top+area.rows))
            self.assertEqual(saved, expected)
            for p in range(5):
                for offset in (p*8000+area.top*40+area.left,
                               p*8000+(area.top+area.rows-1)*40+area.left+area.row_bytes-1):
                    screen[offset] ^= 1
                    self.assertFalse(matches(screen, area, saved))
                    screen[offset] ^= 1

    def test_unrelated_screen_changes_do_not_invalidate(self):
        screen = bytearray(40000)
        area = Region(10, 140, 6, 20)
        saved = capture(screen, area)
        screen[0] = screen[-1] = screen[140*40+9] = screen[140*40+16] = 255
        self.assertTrue(matches(screen, area, saved))
        self.assertFalse(matches(screen, area, saved[:-1]))

    def test_descriptor_validation_precedes_screen_access(self):
        for area in (Region(1, 0, 2, 1), Region(40, 0, 2, 1), Region(0, 0, 0, 1),
                     Region(0, 0, 3, 1), Region(0, 0, 10, 1), Region(0, 0, 2, 49),
                     Region(0, 199, 2, 2), Region(38, 0, 4, 1)):
            self.assertFalse(area.valid())
            with self.assertRaises(ValueError):
                area.offsets()


if __name__ == '__main__':
    unittest.main()
