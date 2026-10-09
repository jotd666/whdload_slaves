import struct
import unittest
from mirror_checks import read_checks


class MirrorCheckRecords(unittest.TestCase):
    def test_complete_record_excludes_synthetic_from_live(self):
        preload = b'RBMIRR01'+struct.pack('>4I', 1, 0, 0, 0)
        live = b'RBMIRR01'+struct.pack('>4I', 1, 65536, 822, 64)
        self.assertEqual(read_checks(preload+live)['live_twins'], 758)
        with self.assertRaises(ValueError):
            read_checks(live+live)

    def test_partial_records_cannot_pass(self):
        for counts in ((1, 65535, 822, 64), (1, 65536, 822, 63),
                       (1, 65536, 63, 64), (2, 65536, 822, 64)):
            with self.assertRaises(ValueError):
                read_checks(b'RBMIRR01'+struct.pack('>4I', *counts))
