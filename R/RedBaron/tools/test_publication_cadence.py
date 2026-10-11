import unittest
from publication_cadence import cadence


class PublicationCadenceTests(unittest.TestCase):
    def pubs(self, start, offsets):
        return [dict(field=(start + i) & 0xffffffff) for i in offsets]

    def test_one_publication_at_every_field_including_wrap(self):
        for start in (100, 0xfffffffe):
            r = cadence(start, 250, self.pubs(start, range(1, 251)))
            self.assertTrue(r['every_field_published'])
            self.assertEqual(r['interval_fields'], {'1': 249})
            self.assertEqual(r['missing_field_offsets'], [])

    def test_average_count_cannot_hide_missing_final_field(self):
        r = cadence(10, 250, self.pubs(10, range(250)))
        self.assertEqual(r['publications'], 250)
        self.assertFalse(r['every_field_published'])
        self.assertEqual(r['missing_field_offsets'], [250])

    def test_internal_and_leading_gaps_retained(self):
        r = cadence(10, 250, self.pubs(10, [2, 3, 5, 250]))
        self.assertEqual(r['covered_field_deadlines'], 4)
        self.assertIn(1, r['missing_field_offsets'])
        self.assertIn(4, r['missing_field_offsets'])
        self.assertEqual(r['interval_fields'], {'1': 1, '2': 1, '245': 1})

    def test_duplicate_cross_window_boundary_or_reordering_fails(self):
        for offsets in ([249, 250, 250, 251], [250, 249], [501]):
            with self.assertRaises(ValueError):
                cadence(0, 500, self.pubs(0, offsets))

    def test_empty_publications_are_failure_not_vacuous_success(self):
        r = cadence(0, 250, [])
        self.assertFalse(r['every_field_published'])
        self.assertEqual(len(r['missing_field_offsets']), 250)
