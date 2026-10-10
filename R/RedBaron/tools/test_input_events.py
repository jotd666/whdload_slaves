import struct
import unittest
from input_events import decode, check_fixture


class InputEvidenceTests(unittest.TestCase):
    def fixture(self):
        queue = bytearray(4112)
        struct.pack_into('>4H', queue, 0, 2, 65534, 0, 4)
        log = bytearray()
        for i, (code, value) in enumerate(((78,1),(78,0),(64,1),(64,0))):
            stamp = (0xfffffffe+i) & 0xffffffff
            log += struct.pack('>IHH', stamp, code, value)
            struct.pack_into('>IHHII', queue, 16+((65534+i)&255)*16,
                             (stamp+1)&0xffffffff, code, value, 0, 0)
        return queue, log

    def test_fifo_and_acquisition_across_both_wraps(self):
        queue, log = self.fixture()
        result = check_fixture(queue, log)
        self.assertEqual([e['eligible'] for e in result['events']], [0xffffffff,0,1,2])

    def test_corrupt_header_or_wrong_deadline_is_rejected(self):
        queue, log = self.fixture()
        queue[16+254*16+3] ^= 1
        with self.assertRaises(ValueError):
            check_fixture(queue, log)
        struct.pack_into('>H', queue, 0, 1000)
        with self.assertRaises(ValueError):
            decode(queue)

    def test_overflow_is_not_silently_filtered(self):
        queue, log = self.fixture()
        struct.pack_into('>H', queue, 4, 1)
        self.assertTrue(decode(queue)['overflow'])
        with self.assertRaises(ValueError):
            check_fixture(queue, log)
