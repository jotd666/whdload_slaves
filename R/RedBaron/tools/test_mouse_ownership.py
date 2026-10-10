import copy
import itertools
import unittest
from mouse_ownership import CENTER, advance, vectors, check_camera_capture


class MouseOwnershipTests(unittest.TestCase):
    def test_each_reset_preserves_the_other_owner(self):
        state = advance((CENTER, CENTER), (0, 17, -9, 319, 199))
        self.assertEqual(advance(state, (1, 0, 0, 0, 0)), (CENTER, (177, 91)))
        self.assertEqual(advance(state, (2, 0, 0, 0, 0)), ((177, 91), CENTER))

    def test_camera_reset_schedule_cannot_change_flight_input(self):
        operations = [(0, 127, -128, 319, 199), (0, -128, 127, 319, 199),
                      (1, 0, 0, 0, 0), (0, 27, 38, 319, 199)]
        for camera_resets in itertools.product((False, True), repeat=len(operations)):
            reference = actual = (CENTER, CENTER)
            for operation, reset in zip(operations, camera_resets):
                reference = advance(reference, operation)
                if reset:
                    actual = advance(actual, (2, 0, 0, 0, 0))
                actual = advance(actual, operation)
                self.assertEqual(actual[0], reference[0])

    def test_world_reset_schedule_cannot_change_camera_input(self):
        for rows in itertools.permutations([(0, 127, 127, 319, 199),
                                           (0, -128, -128, 319, 199),
                                           (1, 0, 0, 0, 0), (2, 0, 0, 0, 0)]):
            actual = reference = (CENTER, CENTER)
            for operation in rows:
                actual = advance(actual, operation)
                if operation[0] != 1:
                    reference = advance(reference, operation)
                self.assertEqual(actual[1], reference[1])

    def test_native_vectors_have_distinct_owners_and_both_limits(self):
        rows = list(vectors())
        self.assertEqual(len(rows), 192)
        self.assertTrue(any(row[5:7] != row[7:9] for row in rows))
        for offset, limit in ((5, 319), (6, 199), (7, 319), (8, 199)):
            values = {row[offset] for row in rows}
            self.assertIn(0, values)
            self.assertIn(limit, values)

    def test_camera_capture_rejects_cross_owner_changes(self):
        rows = [[1, 4, 10, 170, 95, 170, 95], [2, 11, 15, 160, 100, 160, 100]]
        posts = [[1, 19, -9, 160, 100, 1], [2, 0, 0, 160, 100, 2]]
        cameras = [[1, 4, -3, 160, 100, 160, 100, 2]]
        self.assertEqual(check_camera_capture(rows, posts, cameras, 192)['ownership_vectors'], 192)
        for column in (0, 1, 2, 3, 4, 5, 6, 7):
            corrupt = copy.deepcopy(cameras)
            corrupt[0][column] += 1
            with self.subTest(column=column), self.assertRaises(ValueError):
                check_camera_capture(rows, posts, corrupt, 192)
        with self.assertRaises(ValueError):
            check_camera_capture(rows, posts, cameras, 191)


if __name__ == '__main__': unittest.main()
