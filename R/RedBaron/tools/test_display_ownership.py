import unittest
from unittest.mock import patch
from types import SimpleNamespace
import display_ownership as d


class DisplayTests(unittest.TestCase):
    def test_early_publication_uses_previous_display(self):
        shown = [[0], [1], [0]]
        self.assertEqual(d.previous_display(shown, 1, 24), [0])
        self.assertEqual(d.previous_display(shown, 1, 104), [1])
        self.assertEqual(d.previous_display(shown, 0, 24), [])

    def test_no_dma_is_not_a_pass(self):
        # A correctly sized but empty DMA field must never establish tear freedom.
        trace = SimpleNamespace(fields=[SimpleNamespace(index=0, dma_size=58,
                                    dma=bytes(58*313*227))])
        with patch.object(d.barto, 'load', return_value=trace), \
             patch.object(d.frames, 'analyse', return_value={'swaps': []}):
            result = d.analyse('unused', 0, [0x10000, 0x20000])
        self.assertFalse(result['observable'])
        self.assertEqual(result['active_display_conflicts'], [])


if __name__ == '__main__':
    unittest.main()
