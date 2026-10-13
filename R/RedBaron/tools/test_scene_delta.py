import random
import unittest
from scene_delta import Pages, check, check_pixels

class DeltaTests(unittest.TestCase):
    def test_pages_events_and_dirty_cockpit(self):
        rng = random.Random(25)
        model = Pages()
        source = bytearray(rng.randbytes(40000))
        targets = [bytearray(40000), bytearray(40000)]
        for frame in range(100):
            role = frame % 2
            if frame % 11 == 0:
                model.invalidate()
                targets[role][:] = rng.randbytes(40000)
            for _ in range(30):
                at = rng.randrange(40000)
                source[at] = rng.randrange(256)
            # All downstream cockpit writes must be overwritten next time.
            for p in range(5):
                targets[role][p*8000+3520:p*8000+4800] = rng.randbytes(1280)
            outside = [bytes(targets[role][p*8000+4800:(p+1)*8000]) for p in range(5)]
            model.copy(role, 100+role+(frame//23)*2, source, targets[role])
            check_pixels(source, targets[role])
            self.assertEqual(outside, [bytes(targets[role][p*8000+4800:(p+1)*8000]) for p in range(5)])

    def test_unchanged_and_all_changed(self):
        m = Pages();s = bytearray(40000);d = bytearray(40000)
        self.assertEqual(m.copy(0, 1, s, d), 6000)
        self.assertEqual(m.copy(0, 1, s, d), 1600)
        s[:] = b'\xff'*40000
        self.assertEqual(m.copy(0, 1, s, d), 6000)
        check_pixels(s, d)
        self.assertEqual(m.copy(0, 2, s, d), 6000)
        m.invalidate()
        self.assertEqual(m.copy(0, 2, s, d), 6000)

    def test_checker_sabotages(self):
        for at in (0, 3520, 36796):
            s = bytearray(40000);d = bytearray(s);d[at] = 1
            with self.assertRaises(ValueError):check_pixels(s, d)
        for data in (b'', b'\0'*4, b'\0\0\0\1'):
            with self.assertRaises(ValueError):check(data)
        self.assertEqual(check(b'\0\0\0\2')['exact_copies'], 2)

    def test_native_geometry_and_changes(self):
        m = Pages();s = bytearray(b'\xff'*40000);d = bytearray(40000)
        for top, height in ((21,119), (0,120), (30,110), (21,119)):
            self.assertEqual(m.copy(0,1,s,d,top,height), height*50)
            self.assertEqual(m.copy(0,1,s,d,top,height), (top+height-88)*50)
            check_pixels(s,d,top,height)
