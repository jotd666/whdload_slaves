import unittest
from auxiliary_lists import state, equal


class AuxiliaryListTests(unittest.TestCase):
    def fixture(self, shift=0):
        raw = bytearray(0x6000)
        def put(at, value, n=4): raw[at:at+n] = value.to_bytes(n, 'big')
        for root, count, start, stride in ((0x57d4, 0x57de, 0x100, 16), (0x57d8, 0x57e0, 0x200, 12)):
            put(root, start+shift); put(count, 2, 2)
            put(start+shift, 0x400); raw[start+shift+stride-1] = 7
            # Second slot is inactive, but its tail remains part of the state.
            raw[start+shift+2*stride-1] = 9
        extents = [(0x100+shift-8, 40), (0x200+shift-8, 32)]
        return raw, extents, put

    def test_only_allocation_roots_may_relocate(self):
        a, e, _ = self.fixture(); b, f, _ = self.fixture(0x20)
        sa = state(lambda p,n: bytes(a[p:p+n]), 0, e)
        sb = state(lambda p,n: bytes(b[p:p+n]), 0, f)
        equal(sa, sb)
        self.assertNotEqual(sa['raw_roots'], sb['raw_roots'])
        self.assertEqual([r['active'] for r in sa['lists']], [1, 1])

    def test_owner_inactive_tail_and_controls_are_not_masked(self):
        for at in (0x103, 0x11f, 0x203, 0x217, 0x57e3):
            raw, e, _ = self.fixture(); read = lambda p,n: bytes(raw[p:p+n])
            before = state(read, 0, e); raw[at] ^= 1
            with self.assertRaises(ValueError): equal(before, state(read, 0, e))

    def test_rejects_missing_oversized_or_duplicate_allocation(self):
        for mode in ('missing', 'oversized', 'duplicate'):
            raw, e, _ = self.fixture()
            if mode == 'missing': e.pop()
            elif mode == 'oversized': e[0] = (e[0][0], e[0][1]+2)
            else: e.append(e[0])
            with self.assertRaises(ValueError): state(lambda p,n: bytes(raw[p:p+n]), 0, e)

    def test_empty_or_changed_count_needs_new_evidence(self):
        for count in (0, 1, 501):
            raw, e, put = self.fixture(); put(0x57de, count, 2)
            with self.assertRaises(ValueError): state(lambda p,n: bytes(raw[p:p+n]), 0, e)
