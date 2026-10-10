import struct
import unittest
from model_journal import decode, restore, CAPACITY


class ModelJournalTests(unittest.TestCase):
    def test_reverse_overlap_restores_original(self):
        memory = bytearray.fromhex('12345678')
        records = []
        for address, data in [(0, b'\xaa'), (0, b'\xbb\xcc'), (1, b'\xdd\xee')]:
            old = bytes(memory[address:address+len(data)])
            records.append(struct.pack('>I2sH', address, old, len(data)))
            memory[address:address+len(data)] = data
        def write(address, old): memory[address:address+len(old)] = old
        restore(write, decode(b''.join(records)))
        self.assertEqual(memory, bytes.fromhex('12345678'))

    def test_reject_malformed_and_excess_records(self):
        for data in [bytes(7), struct.pack('>I2sH', 0, b'ab', 3), bytes(8*(CAPACITY+1))]:
            with self.assertRaises(ValueError): decode(data)
        self.assertEqual(decode(b''), [])
        self.assertEqual(len(decode(struct.pack('>I2sH', 0, b'ab', 2)*CAPACITY)), CAPACITY)


if __name__ == '__main__': unittest.main()
