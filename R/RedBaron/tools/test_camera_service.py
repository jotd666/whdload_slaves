import copy
import unittest
from camera_service import free_rotation, check_capture


class CameraServiceTests(unittest.TestCase):
    def test_word_shift_and_orientation_wrap(self):
        self.assertEqual(free_rotation(65530, 10, 1, 1), (58, 65482))
        self.assertEqual(free_rotation(10, 65530, -1, -1), (65482, 58))
        self.assertEqual(free_rotation(0, 0, 256, 256), (49152, 16384))

    def evidence(self):
        before, after = [], []
        phase = count = 0
        pitch, yaw = 65530, 10
        for now in range(1, 251):
            phase += 1024
            if phase < 2560:
                continue
            phase -= 2560
            count += 1
            # Three-pixel X movement yields camera control +1. Commands stay queued.
            row = [now, count, now // 7, phase, 2, 1, 1, 450,
                   170, 95, 163, 100, pitch, yaw, 24, 0]
            before.append(row)
            pitch, yaw = free_rotation(pitch, yaw, 1, 0)
            after.append(row[:10] + [160, 100, pitch, yaw, 24, 0, 0, 0, 1, 0, count, count])
        return before, after

    def test_native_fixture_may_begin_after_initial_cockpit_services(self):
        before, after = self.evidence()
        # Add one earlier funded boundary before the first main-task fixture call.
        first = before[0].copy()
        first[0:4] = [0, 0, 0, 0]
        first[10:12] = [160, 100]
        first[14] = 0
        initial_post = first + [0, 0, 0, 0, 1, 0]
        for row in after:
            row[20] += 1
        result = check_capture([first] + before, [initial_post] + after)
        self.assertEqual(result['services'], 101)
        self.assertEqual(result['free_camera_updates'], 100)

    def test_full_capture_and_corruption(self):
        before, after = self.evidence()
        self.assertEqual(check_capture(before, after)['services'], 100)
        for column in (0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21):
            bad = copy.deepcopy(after)
            bad[40][column] += 1
            with self.subTest(column=column), self.assertRaises(ValueError):
                check_capture(before, bad)


if __name__ == '__main__': unittest.main()
