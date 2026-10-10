import unittest
import struct
from copy import deepcopy
from mouse_replay import FIXTURE, accumulate, control, delta, vectors, check_capture


class MouseTests(unittest.TestCase):
    def test_all_counter_pairs_wrap_like_native_byte_subtract(self):
        for old in range(256):
            for new in range(256):
                expected = (new - old) % 256
                if expected >= 128: expected -= 256
                self.assertEqual(delta(old, new), expected)

    def test_every_normal_position_and_signed_delta(self):
        for limit in (199, 319):
            for position in range(limit + 1):
                for movement in range(-128, 128):
                    self.assertEqual(accumulate(position, movement, limit),
                                     max(0, min(limit, position + movement)))

    def test_native_word_overflow_is_not_unbounded_addition(self):
        self.assertEqual(accumulate(0x7fff, 1, 0xffff), 0)
        self.assertEqual(accumulate(0xffff, 1, 319), 0)
        self.assertEqual(accumulate(0x8000, -1, 0xffff), 0x7fff)
        self.assertEqual(len(list(vectors())), 264)

    def test_reset_at_world_boundary_not_at_render(self):
        # Two acquisitions before one world tick, with arbitrary drawing between.
        x, y = 160, 100
        for dx, dy in ((1, 0), (2, -1)):
            x, y = accumulate(x, dx, 319), accumulate(y, dy, 199)
        self.assertEqual((x, y), (163, 99))
        self.assertEqual((control(x, 160), control(y, 100)), ((4, True), (0, True)))
        x, y = 160, 100  # Native reset when either pre-dead-zone displacement exists.
        self.assertEqual((control(x, 160), control(y, 100)), ((0, False), (0, False)))


class MouseEvidenceTests(unittest.TestCase):
    def evidence(self):
        queue = bytearray(4112)
        struct.pack_into('>4H', queue, 0, 12, 12, 0, 3)
        acquisitions = bytearray()
        for i, (threshold, dx, dy) in enumerate(FIXTURE):
            acquisitions += struct.pack('>IIhhHH', threshold + 100, 100, dx, dy, 319, 199)
            struct.pack_into('>IHhhHHH', queue, 16 + i * 16,
                             threshold + 1, 0x201, dx, dy, 319, 199, 0)
        x, y = 160, 100
        at = resets = 0
        rows, posts = [], []
        for tick, cursor in enumerate((5, 11, 19, 21, 27, 29, 35, 43, 51, 59, 67, 74)):
            while at < 12 and FIXTURE[at][0] < cursor:
                _, dx, dy = FIXTURE[at]
                x, y = accumulate(x, dx, 319), accumulate(y, dy, 199)
                at += 1
            rows.append([tick, cursor, cursor + 20, x, y, x, y])
            cx, mx = control(x, 160)
            cy, my = control(y, 100)
            if mx or my:
                x, y = 160, 100
                resets += 1
            posts.append([tick, cx, cy, x, y, resets])
            if mx or my: resets += 1
        return [queue, acquisitions, struct.pack('>III', 12, 12, resets),
                rows, posts, 100, bytes(8), 264]

    def test_valid_capture(self):
        self.assertEqual(check_capture(*self.evidence())['events'], 12)

    def test_wrong_input_control_reset_deadline_and_overflow_rejected(self):
        for mutation in ('input', 'control', 'reset', 'counter', 'deadline',
                         'overflow', 'acquisition', 'missing_post', 'keyboard'):
            with self.subTest(mutation=mutation):
                args = deepcopy(self.evidence())
                if mutation == 'input': args[3][0][3] += 1
                elif mutation == 'control': args[4][0][1] += 1
                elif mutation == 'reset': args[4][0][3] += 1
                elif mutation == 'counter': args[4][0][5] = 0
                elif mutation == 'deadline': struct.pack_into('>I', args[0], 16, 4)
                elif mutation == 'overflow': struct.pack_into('>H', args[0], 4, 1)
                elif mutation == 'acquisition': struct.pack_into('>h', args[1], 8, 2)
                elif mutation == 'missing_post': args[4].pop()
                elif mutation == 'keyboard': args[6] = struct.pack('>II', 1, 1)
                with self.assertRaises(ValueError): check_capture(*args)


if __name__ == '__main__': unittest.main()
