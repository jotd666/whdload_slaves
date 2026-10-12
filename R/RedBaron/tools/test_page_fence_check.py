import copy
import unittest
from page_fence_check import check


class FenceEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.display = dict(observable=True, fields=12, unmapped_bitplane_fetches=0,
                            shown=[[i//3 % 2] for i in range(12)],
                            active_display_conflicts=[])
        self.raw = '\n'.join(f'PUB {i} 30000' for i in (1, 4, 7, 10))

    def test_observed_safe_turnover(self):
        result = check(self.display, self.raw, 12)
        self.assertEqual(result['page_turnovers'], 3)
        self.assertEqual(result['cadence']['interval_fields'], {'3': 3})

    def test_sabotaged_write_before_fence(self):
        self.display['active_display_conflicts'] = [dict(field=3, role=1)]
        with self.assertRaisesRegex(ValueError, 'Write'):
            check(self.display, self.raw, 12)

    def test_sabotaged_copper_pickup(self):
        with self.assertRaisesRegex(ValueError, 'pointer pickup'):
            check(self.display, self.raw.replace('30000', str(42 << 8)), 12, pickup_guard=True)
        self.display['shown'][4] = [0, 1]
        with self.assertRaisesRegex(ValueError, 'Mixed'):
            check(self.display, self.raw, 12)

    def test_partial_pointer_can_fetch_outside_both_pages(self):
        self.display['unmapped_bitplane_fetches'] = 1
        with self.assertRaisesRegex(ValueError, 'outside'):
            check(self.display, self.raw, 12)

    def test_sabotaged_pacing_cap(self):
        with self.assertRaisesRegex(ValueError, 'two-field'):
            check(self.display, self.raw.replace('PUB 4 ', 'PUB 2 '), 12)

    def test_empty_or_stationary_display_cannot_pass(self):
        for key, value in [('observable', False), ('shown', [[0]] * 12)]:
            display = copy.deepcopy(self.display); display[key] = value
            with self.assertRaises(ValueError):
                check(display, self.raw, 12)


if __name__ == '__main__':
    unittest.main()
