import unittest
from camera_pose import identity,owner


class CameraPoseTests(unittest.TestCase):
    def setUp(self):
        self.ram=bytearray(0xbd0c)
        self.read=lambda p,n:bytes(self.ram[p:p+n])
        self.put(0x8d72,0x1000)
        self.put(0x67ae,0x2000)

    def put(self,p,v,n=4):self.ram[p:p+n]=v.to_bytes(n,'big')

    def test_cockpit_ignores_stale_external_target(self):
        self.assertEqual(identity(self.read,0),(0x1000,0,0x1000))
        self.assertEqual(owner(self.read,0,0x40000,0x1000,0,0x1000),(0x1000,False))

    def test_attached_family_requires_native_callback_and_private_camera(self):
        self.put(0x8d72,0x677a);self.put(0x1a70,0x55666)
        for view in range(1,6):
            self.put(0x6712,view,2)
            self.assertEqual(owner(self.read,0,0x40000,0x677a,view,0x2000),(0x2000,True))
        self.put(0x1a70,0x555ce)
        with self.assertRaisesRegex(ValueError,'pose-copy'):owner(self.read,0,0x40000,0x677a,5,0x2000)

    def test_target_switch_is_an_identity_change(self):
        self.put(0x6712,1,2);self.put(0x8d72,0x677a);self.put(0x1a70,0x55666)
        previous=identity(self.read,0);self.put(0x67ae,0x3000)
        self.assertNotEqual(identity(self.read,0),previous)
        with self.assertRaisesRegex(ValueError,'identity'):owner(self.read,0,0x40000,*previous)

    def test_free_camera_remains_outside_attached_family(self):
        self.put(0x6712,24,2);self.put(0x8d72,0x677a);self.put(0x1a70,0x55666)
        with self.assertRaisesRegex(ValueError,'pose-copy'):owner(self.read,0,0x40000,*identity(self.read,0))
