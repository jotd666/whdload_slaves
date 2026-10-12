import unittest
from audit_hooks import audit
from hunks import Hunk

class DeviceLiteralAuditTests(unittest.TestCase):
    def test_exact_device_literal_is_not_a_branch(self):
        data=bytearray(0x2e820)
        data[0x2e7a6:0x2e7b3]=b'input.device\0'
        listing=' 2e7ac: 6465 bcc.s 0x2e813\n 2e810: 41f9 00df f000 lea 0xdff000,a0\n'
        span=[(0x2e810,0x2e816,19,'fast-frame.s',1)]
        self.assertEqual(audit([Hunk(0x3e9,len(data),bytes(data))],span,listing),[])
        # Changed bytes must not hide a genuine incoming branch.
        data[0x2e7a6]=0
        self.assertTrue(audit([Hunk(0x3e9,len(data),bytes(data))],span,listing))

if __name__ == '__main__':
    unittest.main()
