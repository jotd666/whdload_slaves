import struct
import unittest
from message_layout import expanded,expected


class MessageLayoutTests(unittest.TestCase):
    def test_erasure_copies_border_once(self):
        rect=struct.pack('>4h',93,178,128,14);scratch=struct.pack('>4h',90,175,134,20)
        events=[[0,178,1,1,14500,0,0,123],[26,26,3,2,1,2,2,123]]
        self.assertEqual(expanded(rect),scratch)
        self.assertEqual(expected(rect,scratch,events),rect)
        self.assertEqual(expected(rect,scratch,events+[[28,26,4,0,0,1,2,123]]),scratch)

    def test_native_word_wrap(self):
        self.assertEqual(expanded(struct.pack('>4H',0,2,65535,65534)),struct.pack('>4H',65533,65535,5,4))

    def test_reject_other_lifecycles_or_scratch(self):
        rect=struct.pack('>4H',10,10,10,10);scratch=expanded(rect)
        start=[0,178,1,1,15000,0,0,123];erase=[178,178,4,0,0,1,1,123]
        for events in ([],[start,start],[start,erase,erase],[start,[178,178,4,0,0,1,1,456]]):
            with self.assertRaises(ValueError):expected(rect,scratch,events)
        with self.assertRaises(ValueError):expected(rect,rect,[start])
        with self.assertRaises(ValueError):expanded(rect[:-1])
