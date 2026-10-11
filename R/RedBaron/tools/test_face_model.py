import random
import unittest
from face_model import original, fast

class FaceTests(unittest.TestCase):
    def test_empty_repeated_clipped_and_projected(self):
        rng = random.Random(34544)
        for _ in range(500):
            state = dict(flags=[rng.randrange(4) for _ in range(255)],
                         z=[rng.randrange(-32768, 32768) for _ in range(255)],
                         source=[rng.randrange(-32768, 32768) for _ in range(255)],
                         projected=[0]*255, scratch=17, count=99,
                         bound=rng.randrange(-32768, 32768), list=[88]*256)
            vertices = [rng.randrange(255) for _ in range(rng.randrange(21))] + [255]
            self.assertEqual(fast(vertices, state), original(vertices, state))
            self.assertEqual(fast([255], state), original([255], state))

class HeaderTests(unittest.TestCase):
    def test_three_sabotages(self):
        import struct
        from face_model import check_header
        good = b'RBFACE01' + struct.pack('>6I', 1, 100, 0, 80, 60, 20)
        self.assertEqual(check_header(good), 100)
        for bad in (b'BADMAGIC' + good[8:], b'RBFACE01' + struct.pack('>6I', 1, 0, 0, 80, 60, 20),
                    b'RBFACE01' + struct.pack('>6I', 1, 100, 1, 80, 60, 20)):
            with self.assertRaises(ValueError): check_header(bad)
