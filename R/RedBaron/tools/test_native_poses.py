import struct
import unittest
from native_poses import records, invalidate


class NativePoseTests(unittest.TestCase):
    def test_exact_layout_and_address_invalidation(self):
        memory=bytearray(256)
        memory[34:36]=b'\x12\x34'
        memory[40:58]=bytes(range(18))
        read=lambda a,n:bytes(memory[a:a+n])
        first=struct.pack('>IHH',32,1,0x1234)+bytes(range(18))
        second=struct.pack('>IHH',64,1,0)+bytes(18)
        saved=records(read,[32,64])
        self.assertEqual(saved,[first,second])
        self.assertEqual(invalidate(saved,[32,32,96]),[first[:4]+bytes(2)+first[6:],second])
        self.assertEqual(saved,[first,second])
        with self.assertRaises(ValueError):invalidate([bytes(25)],[])


if __name__ == '__main__':unittest.main()
