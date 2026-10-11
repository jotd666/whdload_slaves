import unittest
from sound_slot_state import slot_state


class SoundSlotTests(unittest.TestCase):
    def fixture(self,address=1000,source=2000):
        raw=bytearray(384)
        for at,value in ((12,address+366),(362,source),(366,source+3)):
            raw[at:at+4]=value.to_bytes(4,'big')
        return [raw,address,[(source,b'\0\1xy')]]

    def test_explicit_bindings_and_counter_visibility(self):
        self.assertEqual(slot_state(*self.fixture()),slot_state(*self.fixture(3000,4000)))
        args=self.fixture();args[0][345]=1
        self.assertNotEqual(slot_state(*args),slot_state(*self.fixture()))
        self.assertEqual(slot_state(*args)['counter'],1)

    def test_bad_source_data_and_self_pointers_fail(self):
        for at in (12,362,366):
            args=self.fixture();args[0][at+3]^=1
            with self.assertRaises(ValueError):slot_state(*args)
        args=self.fixture();args[0][374]=1
        with self.assertRaises(ValueError):slot_state(*args)
        args=self.fixture();args[2]=[(2000,b'\0\xff')]
        with self.assertRaises(ValueError):slot_state(*args)

    def test_inactive_slots_and_final_bytes_remain_visible(self):
        args=self.fixture();args[0][362:370]=bytes(8)
        before=slot_state(*args);self.assertIsNone(before['source_index'])
        args[0][-1]=1;self.assertNotEqual(before,slot_state(*args))
        args[0]=args[0][:-1]
        with self.assertRaises(ValueError):slot_state(*args)
