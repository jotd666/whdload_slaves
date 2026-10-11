import unittest
from completion_cadence import summarize

class CadenceTest(unittest.TestCase):
    def trace(self):
        return ''.join(f'FIELD {i} 260\n' for i in range(1, 11)) + ''.join(f'PUB {i} 25604\n' for i in (2, 4, 6, 8))

    def test_clean(self):
        result = summarize(self.trace(), 10)
        self.assertEqual(result['clean_intervals'], 3)
        self.assertAlmostEqual(result['event_free_frame_fps'], 49.92041/2)

    def test_event_boundary_excludes_both_adjacent_frames(self):
        result = summarize(self.trace() + 'DASH dirty 4\n', 10)
        self.assertEqual(result['clean_intervals'], 1)

    def test_missing_field_rejected(self):
        with self.assertRaises(ValueError): summarize(self.trace().replace('FIELD 5 260\n', ''), 10)

    def test_flight_exit_rejected(self):
        with self.assertRaises(ValueError): summarize(self.trace() + 'FLIGHT_EXIT 10\n', 10)
