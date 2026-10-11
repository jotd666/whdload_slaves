import struct
import unittest
from instrument_values import key, VALUE_WORDS


class InstrumentValuesTests(unittest.TestCase):
    def setUp(self):
        self.mem = bytearray(0x20000)
        self.h3 = 0x1000
        self.aircraft = 0x18000
        self.put(0x4578, self.aircraft, 4)

    def put(self, offset, value, width=2):
        self.mem[self.h3+offset:self.h3+offset+width] = value.to_bytes(width, 'big')

    def read(self, address, size):
        self.assertGreaterEqual(address, self.h3)
        self.assertLessEqual(address + size, len(self.mem))
        return self.mem[address:address+size]

    def test_native_word_inputs_remain_raw(self):
        for gauge, offset in VALUE_WORDS.items():
            for value in (0, 1, 0x7fff, 0x8000, 0xffff):
                self.put(offset, value)
                self.assertEqual(key(self.read, self.h3, gauge),
                                 struct.pack('>HHII', gauge, 0, value, 0))

    def test_altitude_retains_full_long_not_clamped_or_quantized(self):
        for value in (0, 49, 50, 51, 0x7fffffff, 0x80000000, 0xffffffff):
            self.mem[self.aircraft+0x10:self.aircraft+0x14] = value.to_bytes(4, 'big')
            self.assertEqual(key(self.read, self.h3, 0), struct.pack('>HHII', 0, 0, value, 0))

    def test_fuel_both_native_branches_and_zero_denominator(self):
        self.mem[self.aircraft+0x86:self.aircraft+0x88] = bytes.fromhex('1234')
        for denominator in (0, 1, 0x8000, 0xffff):
            self.put(0x71d2, denominator)
            for mode in (0, 1, 0xffff):
                self.put(0x8d9e, mode)
                self.assertEqual(key(self.read, self.h3, 5), struct.pack(
                    '>HHII', 5, mode, 0x1234 if mode else denominator, denominator))

    def test_other_gauges_do_not_dirty_an_unchanged_value(self):
        for gauge, offset in VALUE_WORDS.items():
            initial = key(self.read, self.h3, gauge)
            self.put(offset, 0x1357)
            for other in VALUE_WORDS:
                if other != gauge:
                    self.assertEqual(key(self.read, self.h3, other), struct.pack('>HHII', other, 0, 0, 0))
            self.assertNotEqual(initial, key(self.read, self.h3, gauge))
            self.put(offset, 0)

    def test_missing_aircraft_only_rejects_branches_that_need_it(self):
        self.put(0x4578, 0, 4)
        self.assertIsNone(key(self.read, self.h3, 0))
        self.assertIsNotNone(key(self.read, self.h3, 5))
        self.put(0x8d9e, 1)
        self.assertIsNone(key(self.read, self.h3, 5))
        for gauge in VALUE_WORDS:
            self.assertIsNotNone(key(self.read, self.h3, gauge))

    def test_invalid_index_never_reads_game_memory(self):
        def forbidden(*args):
            self.fail('unexpected game-memory read')
        for gauge in (-1, 7, 65535):
            self.assertIsNone(key(forbidden, self.h3, gauge))


if __name__ == '__main__':
    unittest.main()
