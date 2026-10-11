import unittest
from completion_soak import check_segment


class SoakCheckTests(unittest.TestCase):
    def test_requested_vbl_stop(self):
        check_segment('0x1234 in ?? ()\nSOAK_SEGMENT_COMPLETE\n', 0x1234)
        check_segment('Breakpoint 7, 0x1234 in ?? ()\nSOAK_SEGMENT_COMPLETE\n', 0x1234)

    def test_fault_exit_and_missing_completion_rejected(self):
        for raw in ('0x9876 in ?? ()\nSOAK_SEGMENT_COMPLETE\n',
                    'FLIGHT_EXIT\n0x1234 in ?? ()\nSOAK_SEGMENT_COMPLETE\n',
                    '0x1234 in ?? ()\n'):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                check_segment(raw, 0x1234)
