import unittest
from overlay_abi import REGISTERS,SAVED,epilogue,registers


class OverlayAbiTests(unittest.TestCase):
    def fixture(self):
        values={name:100+i for i,name in enumerate(REGISTERS)}
        values.update(sp=64,a5=132,ps=16)
        data=bytearray(160)
        for i,name in enumerate(SAVED):data[64+4*i:68+4*i]=(1000+i).to_bytes(4,'big')
        data[132:136]=(9876).to_bytes(4,'big');data[136:140]=(5432).to_bytes(4,'big')
        return values,lambda at,n:bytes(data[at:at+n])

    def test_full_epilogue_preserves_unsaved_registers_and_flags(self):
        values,read=self.fixture();out=epilogue(read,values)
        for i,name in enumerate(SAVED):self.assertEqual(out[name],1000+i)
        self.assertEqual((out['a5'],out['sp'],out['pc']),(9876,140,5432))
        for name in set(REGISTERS)-set(SAVED)-{'a5','sp','pc'}:self.assertEqual(out[name],values[name])

    def test_reject_incomplete_stack_or_unexpected_frame(self):
        values,read=self.fixture()
        with self.assertRaises(ValueError):epilogue(lambda at,n:b'',values)
        values['a5']+=4
        with self.assertRaises(ValueError):epilogue(read,values)

    def test_require_all_registers_and_accept_sr_alias(self):
        values,_=self.fixture();self.assertEqual(registers({'values':values}),values)
        alias=dict(values);alias['sr']=alias.pop('ps')
        self.assertEqual(registers({'values':alias}),values)
        del alias['d4']
        with self.assertRaises(ValueError):registers({'values':alias})
