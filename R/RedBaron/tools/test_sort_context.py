import unittest
from unittest.mock import patch
from types import SimpleNamespace
from sort_context import Audit,original_contract


class SortContextTests(unittest.TestCase):
    def test_completed_owner_uses_current_pointer(self):
        a=Audit();r=[0]*16;r[10]=0x1000
        a.feed(0xe470,r);a.feed(0xe498,r)
        for _ in range(3):
            a.feed(0xe448,r);r[8]=0x1000;a.feed(0xe44e,r)
        a.feed(0xe4fa,r)
        self.assertEqual(a.calls,[dict(pointer=0x1000,reads=3,pending=False)])

    def test_reject_stale_pointer(self):
        a=Audit();r=[0]*16;r[10]=0x1000;r[8]=0x2000
        a.feed(0xe470,r);a.feed(0xe498,r);a.feed(0xe448,r)
        with self.assertRaisesRegex(ValueError,'current context'):a.feed(0xe44e,r)

    def test_reject_read_before_initialization(self):
        a=Audit();r=[0]*16;a.feed(0xe470,r)
        with self.assertRaisesRegex(ValueError,'before context'):a.feed(0xe448,r)

    def test_incomplete_and_leading_calls_do_not_count(self):
        a=Audit();r=[0]*16;a.feed(0xe448,r);a.feed(0xe4fa,r)
        a.feed(0xe470,r);a.feed(0xe498,r)
        self.assertEqual(a.calls,[]);self.assertEqual(a.leading_reads,1)

    def test_nested_owner_is_rejected(self):
        a=Audit();r=[0]*16;a.feed(0xe470,r)
        with self.assertRaisesRegex(ValueError,'Nested'):a.feed(0xe470,r)

    def test_original_contract_rejects_extra_reference_and_changed_code(self):
        code=bytearray(0xe4fc)
        for at,h in {0xe448:'207900004e1a',0xe498:'23ca00004e1a',
                     0xe49e:'487aff8870013f003f07486dff6a4eba00b0',
                     0xe44e:'2030180090b02800',0xe4fa:'4e75'}.items():
            block=bytes.fromhex(h);code[at:at+len(block)]=block
        hunk=SimpleNamespace(data=code,relocations=[(0xe44a,3),(0xe49a,3)])
        with patch('sort_context.read_hunks',return_value=[hunk]):
            self.assertEqual(original_contract(b'fixture')['context'],'h3:04e1a')
            code[0xe44e]^=1
            with self.assertRaisesRegex(ValueError,'Changed'):original_contract(b'fixture')
            code[0xe44e]^=1
            code[0:4]=(0x4e1b).to_bytes(4,'big');hunk.relocations.append((0,3))
            with self.assertRaisesRegex(ValueError,'Unclassified'):original_contract(b'fixture')
