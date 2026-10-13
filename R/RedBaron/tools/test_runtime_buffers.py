import unittest
from presentation_state import buffer_address
from runtime_buffers import check_layout, live_address


class RuntimeBuffers(unittest.TestCase):
    def test_historical_and_pointer_captures(self):
        old=['00:00000100 00 1: time_model_buffer: dcb.b 32768,0']
        new=['00:00000100 00000000 1: time_model_buffer_ptr: dc.l 0']
        self.assertEqual(buffer_address(old,4096,'time_model_buffer',None),4352)
        read=lambda address,size: (0x200000).to_bytes(4,'big')
        self.assertEqual(buffer_address(new,4096,'time_model_buffer',read),0x200000)
        self.assertEqual(live_address(new,4096,'time_model_buffer',lambda cmd:'RUNTIME_BUFFER 2097152'),0x200000)
        for address in [0,1,0x200001]:
            with self.assertRaises(ValueError):
                buffer_address(new,4096,'time_model_buffer',lambda a,n:address.to_bytes(4,'big'))

    def test_observation_only(self):
        data=[0]*8
        data[6]=0x200000
        self.assertEqual(check_layout(data,False,False,True,True),[(0x200000,4112)])
        with self.assertRaises(ValueError):check_layout(data,False,False,False,True)
        data[0]=0x210000
        with self.assertRaises(ValueError):check_layout(data,False,False,True,True)

    def test_disabled_and_cpu_gate(self):
        self.assertEqual(check_layout([0]*8,False,False),[])
        data=[0x200000,0x203800,0x20b800,0,0,0,0x220000,0]
        self.assertEqual(sum(n for _,n in check_layout(data,True,False)),53216)
        with self.assertRaises(ValueError):check_layout(data,False,False)
        data[3:6]=[0x230000,0x2332c8,0x236590]
        self.assertEqual(sum(n for _,n in check_layout(data,True,True)),92216)
        with self.assertRaises(ValueError):check_layout(data,True,False)
        data[-1]=0x250000
        self.assertEqual(sum(n for _,n in check_layout(data,True,True)),169696)
        self.assertEqual(sum(n for _,n in check_layout(data,True,True,True)),172348)
        data[6]=data[0]
        with self.assertRaises(ValueError):check_layout(data,True,True)


if __name__=='__main__':unittest.main()
