"""Synthetic checker tests: no copyrighted game data or emulator needed."""
import struct,unittest
from hunks import read_hunks
from check_disabled import check
from audit_hooks import audit
from compare_h3 import compare

pack=lambda *words:struct.pack('>'+str(len(words))+'I',*words)
# Two hunks; a relocated pointer in code targets hunk 1 offset 4.
ORIGINAL=pack(0x3f3,0,2,0,1,2,2,0x3e9,2,4,0x4e714e75,
              0x3ec,1,1,0,0,0x3f2,0x3ea,2,0,0,0x3f2)

class CheckerTests(unittest.TestCase):
    def memory(self):
        mem=bytearray(0x110)
        mem[0:4]=pack(0x200//4)
        mem[4:12]=pack(0x208,0x4e714e75)
        def read(addr,size):
            at=addr-0x100
            if not 0<=at<=len(mem)-size:raise ValueError('Missing region')
            return bytes(mem[at:at+size])
        return mem,read
    def test_relocated_original_and_changed_operand(self):
        mem,read=self.memory();spans=[(0,6,0,'fixture.s',1)]
        self.assertEqual(check(ORIGINAL,0x104,read,spans),[0x104,0x204])
        mem[7]^=1
        with self.assertRaisesRegex(ValueError,'changed'):check(ORIGINAL,0x104,read,spans)
    def test_missing_bank_rejected(self):
        _,read=self.memory()
        with self.assertRaises(ValueError):check(ORIGINAL,0x1000,read,[(0,6,0,'fixture.s',1)])
    def test_unknown_record_rejected(self):
        with self.assertRaises(ValueError):read_hunks(ORIGINAL[:-4]+pack(0x1234))
    def test_hook_instruction_split_and_incoming_branch(self):
        listing=' 0: 6000 0006 bra.w 0x8\n 4: 4eb9 0000 0010 jsr 0x10\n a: 4e75 rts\n'
        errs=audit([],[(4,8,0,'fixture.s',1)],listing)
        self.assertTrue(any('ends inside' in e for e in errs))
        errs=audit([],[(4,10,0,'fixture.s',1)],listing)
        self.assertTrue(any('branch' in e for e in errs))
    def test_relocation_into_hook_rejected(self):
        h=read_hunks(ORIGINAL);h[0].relocations=[(0,0)]
        errs=audit(h,[(2,8,0,'fixture.s',1)],' 2: 4e71 nop\n 4: 4e71 nop\n 6: 4e75 rts\n')
        self.assertTrue(any('relocation' in e for e in errs))
class StateTests(unittest.TestCase):
    def test_pointer_candidates_do_not_hide_other_state(self):
        a=bytearray(0xbd0c);b=bytearray(a)
        ma=dict(sim=0x100000,h3=0x150000);mb=dict(sim=0x200000,h3=0x250000)
        a[10:14]=pack(ma['sim']+42);b[10:14]=pack(mb['sim']+42)
        r=compare(a,b,ma,mb)
        self.assertFalse(r['strict_equal'])
        self.assertTrue(r['equal_after_pointer_candidates'])
        self.assertEqual(len(r['pointer_candidates']),1)
        b[20]=1
        self.assertEqual(compare(a,b,ma,mb)['unexplained_bytes'],1)
    def test_wrong_snapshot_size_rejected(self):
        with self.assertRaises(ValueError):compare(bytes(100),bytes(100),{}, {})
if __name__=='__main__':unittest.main()
