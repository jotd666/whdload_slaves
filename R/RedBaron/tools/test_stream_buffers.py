import unittest
from stream_buffers import inactive_state,stable


class StreamBufferTests(unittest.TestCase):
    def fixture(self):
        ram=bytearray(40000)
        for at,n in ((0x77b0,1000),(0x77b4,1000),(0x77b8,3000),(0x77bc,1000)):
            ram[at:at+4]=n.to_bytes(4,'big')
        return ram,[(992,1008),(2992,1008)]

    def test_complete_buffers_and_initial_differences_preserved(self):
        ram,extents=self.fixture();ram[1999]=7
        state=inactive_state(lambda a,n:ram[a:a+n],0,extents)
        self.assertEqual(state[0][-1],7);self.assertEqual(len(state[1]),1000)
        stable(state,state)
        with self.assertRaises(ValueError):stable(state,[bytes(1000),bytes(1000)])

    def test_active_handle_or_descriptor_rejected(self):
        for at in (0x7795,0x77af,0x78c9,0x78f3):
            ram,extents=self.fixture();ram[at]=1
            with self.assertRaises(ValueError):inactive_state(lambda a,n:ram[a:a+n],0,extents)

    def test_extent_size_and_short_reads_rejected(self):
        ram,extents=self.fixture()
        with self.assertRaises(ValueError):inactive_state(lambda a,n:ram[a:a+n],0,extents[:1])
        ram[0x77b7]=1
        with self.assertRaises(ValueError):inactive_state(lambda a,n:ram[a:a+n],0,extents)
        with self.assertRaises(ValueError):inactive_state(lambda a,n:b'',0,extents)
