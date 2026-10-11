import struct
import unittest
from overlay_dependency_guard import matches, fixture, cases


class OverlayDependencyGuardTests(unittest.TestCase):
    def test_all_private_native_cases_against_model(self):
        for offset, value, result, reads in cases():
            data = fixture(); data[offset] = value
            with self.subTest(offset=offset, value=value):
                self.assertEqual(matches(lambda a,n: bytes(data[a-0x1000:a-0x1000+n]), 0x1000, 3), (bool(result), reads))

    def test_early_mismatch_never_reads_next_descriptor_or_resource(self):
        data = fixture(); data[48] ^= 1
        def read(a,n):
            self.assertFalse(a < 0x1020 and a+n > 0x1014, 'Second descriptor read after selector mismatch')
            self.assertNotEqual(a, 0x1034, 'Dependent resource read after selector mismatch')
            return bytes(data[a-0x1000:a-0x1000+n])
        self.assertEqual(matches(read, 0x1000, 3), (False, 1))

    def test_invalid_entry_never_reads_descriptor(self):
        data = fixture(); data[1] = 0
        def read(a,n):
            self.assertEqual((a,n), (0x1000,6))
            return bytes(data[:6])
        self.assertEqual(matches(read, 0x1000, 3), (False, 0))

    def test_maximum_count_and_odd_byte_addresses(self):
        data = bytearray(4096)
        struct.pack_into('>HHH', data, 0, 1, 3, 32)
        for i in range(32):
            struct.pack_into('>IIH', data, 8+i*12, 1001, 1003, 1)
        data[1001] = data[1003] = 90
        self.assertEqual(matches(lambda a,n: bytes(data[a:a+n]), 0, 3), (True, 32))
