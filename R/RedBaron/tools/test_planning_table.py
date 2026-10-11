import unittest
from planning_table import table_state


class PlanningTableTests(unittest.TestCase):
    def fixture(self,root=1000):
        raw=bytearray(48);raw[:4]=(5000).to_bytes(4,'big');raw[36:40]=root.to_bytes(4,'big')
        return [raw,root,2,1,root+36,root+40,bytes(296),5000]

    def test_explicit_self_indices_relocate(self):
        self.assertEqual(table_state(*self.fixture()),table_state(*self.fixture(2000)))
        for pointer in (1001,1036,900):
            args=self.fixture();args[0][36:40]=pointer.to_bytes(4,'big')
            with self.assertRaises(ValueError):table_state(*args)

    def test_unused_and_final_record_bytes_stay_visible(self):
        args=self.fixture();before=table_state(*args);args[0][35]=1
        self.assertNotEqual(before,table_state(*args))
        args=self.fixture();args[6]=bytes(295)+b'x'
        self.assertNotEqual(before,table_state(*args))
        args=self.fixture();args[0][-4:]=(1012).to_bytes(4,'big')
        self.assertNotEqual(before,table_state(*args))

    def test_extent_cursor_and_record_ownership(self):
        for index,value in ((0,bytes(47)),(3,3),(4,1032),(5,1037),(5,1052),(6,bytes(295))):
            args=self.fixture();args[index]=value
            with self.assertRaises(ValueError):table_state(*args)
        args=self.fixture();args[0][:4]=(5001).to_bytes(4,'big')
        with self.assertRaises(ValueError):table_state(*args)
