import random
import unittest
from sound_model import queue_original, queue_fast, divide63, volume


class SoundModelTests(unittest.TestCase):
    def test_every_division_numerator(self):
        for n in range(65026):
            self.assertEqual(divide63(n), n // 63)
        with self.assertRaises(ValueError):
            divide63(65535)

    def test_queue_wrap_and_two_call_limit(self):
        queue = [255] * 16
        queue[15], queue[0], queue[1] = 3, 4, 5
        remaining, index, calls = queue_original(queue, 14)
        self.assertEqual(calls, [(15, 3), (0, 4)])
        self.assertEqual(index, 0)
        self.assertEqual(remaining[1], 5)

    def test_all_queue_occupancy_patterns(self):
        for mask in range(65536):
            queue = [i if mask & (1 << i) else 255 for i in range(16)]
            # Rotation invariance covers every start index for each pattern.
            self.assertEqual(queue_fast(queue, 0), queue_original(queue, 0))
        for index in range(16):
            self.assertEqual(queue_fast([255]*16, index), ([255]*16, index, []))

    def test_volume_truncation_and_zero_paths(self):
        rng = random.Random(3)
        for _ in range(100000):
            args = [rng.randrange(256) for _ in range(3)] + [rng.randrange(65536), rng.randrange(2)]
            self.assertEqual(volume(*args), volume(*args, divide=divide63))
        self.assertEqual(volume(0, 255, 255, 65535), 0)
        self.assertEqual(volume(63, 63, 63, 16), 64)
