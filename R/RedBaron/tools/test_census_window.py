import unittest
from census_window import summarize


class CensusWindowTests(unittest.TestCase):
    def fixture(self):
        return dict(segment_complete=True,
                    events=[dict(kind='mirror', step=10),
                            *[dict(kind='swap', step=s, vbl=(s-10)*1000,
                                   ticks=(s-10)*1182) for s in range(10, 13)]],
                    records=[dict(step=s, dt=450) for s in range(10, 13)])

    def test_boundaries_and_threshold(self):
        result = summarize(self.fixture(), 10, 12, 50)
        self.assertEqual(result['completed_intervals'], 2)
        self.assertEqual(result['fps'], 0.05)
        self.assertTrue(result['meets_2000_fields'])
        self.assertTrue(result['mirror_free'])  # Work before starting swap excluded.

    def test_event_inside_and_short_window(self):
        data = self.fixture()
        data['events'].append(dict(kind='mirror', step=11))
        result = summarize(data, 10, 11)
        self.assertFalse(result['mirror_free'])
        self.assertFalse(result['meets_2000_fields'])

    def test_incomplete_or_missing_or_duplicate(self):
        for mode in ('partial', 'missing_swap', 'duplicate', 'missing_step'):
            with self.subTest(mode=mode):
                data = self.fixture()
                if mode == 'partial': data['segment_complete'] = False
                if mode == 'missing_swap': del data['events'][2]
                if mode == 'duplicate': data['events'].append(data['events'][-1])
                if mode == 'missing_step': del data['records'][1]
                with self.assertRaises(ValueError): summarize(data, 10, 12)


if __name__ == '__main__':
    unittest.main()
