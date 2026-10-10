import unittest
from render_phase import dirty_after


class RenderPhaseTests(unittest.TestCase):
    def test_dirty_countdown_matches_signed_native_clamp(self):
        for value,expected in [(-32768,0),(-1,0),(0,0),(1,0),(2,1),(32767,32766)]:
            self.assertEqual(dirty_after(value),expected)
        with self.assertRaises(ValueError):dirty_after(32768)


if __name__=='__main__':unittest.main()
