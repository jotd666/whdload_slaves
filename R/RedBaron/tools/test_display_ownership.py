import struct
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

    def test_distinguish_writes_ahead_of_fetch(self):
        data = bytearray(58*313*227)
        for slot, kind in ((100*227, 5), (150*227, 6), (200*227, 5)):
            at = slot*58
            data[at+29] = kind
            struct.pack_into('<I', data, at+12, 0x10000)
        trace = SimpleNamespace(fields=[SimpleNamespace(index=0, dma_size=58, dma=data)])
        with patch.object(d.barto, 'load', return_value=trace), \
             patch.object(d.frames, 'analyse', return_value={'swaps': []}):
            result = d.analyse('unused', 0, [0x10000, 0x20000])
        self.assertTrue(result['observable'])
        self.assertEqual(len(result['active_display_conflicts']), 2)
        self.assertEqual(result['conflicts_fetched_later'], 1)


if __name__ == '__main__':
    unittest.main()
