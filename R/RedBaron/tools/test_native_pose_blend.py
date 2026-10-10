import struct
import unittest
from native_pose_blend import blend
from pose_history import POSE


def row(pointer,valid,model,x,yaw):
    return struct.pack('>IHH',pointer,valid,model)+POSE.pack(x,-x,0,0,0,yaw)


class NativePoseBlendTests(unittest.TestCase):
    def test_wrapped_angle_negative_position_and_order_independent_match(self):
        current=row(32,1,2,101,6)+row(64,1,3,20,0)
        previous=row(64,1,3,0,0)+row(32,1,2,0,65530)
        data,blended,snapped=blend(current,previous,32768)
        self.assertEqual((blended,snapped),(2,0))
        self.assertEqual(POSE.unpack(data[8:26]),(50,-51,0,0,0,0))
        self.assertEqual(POSE.unpack(data[34:52]),(10,-10,0,0,0,0))

    def test_lifecycle_model_change_and_missing_previous_snap(self):
        current=b''.join(row(p,1,2,100,20) for p in (32,64,96))
        previous=row(32,0,2,0,0)+row(64,1,3,0,0)
        self.assertEqual(blend(current,previous,0),(current,0,3))
        with self.assertRaises(ValueError):blend(current+current,previous,0)
        with self.assertRaises(ValueError):blend(current[:-1],previous,0)


if __name__=='__main__':unittest.main()
