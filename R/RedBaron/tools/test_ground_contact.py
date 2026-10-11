import unittest
from ground_contact import grade, observed


class GroundContactTests(unittest.TestCase):
    def value(self, **changes):
        args=dict(angle0=0,angle1=0,horizontal=0,vertical=0,prior=0,
                  hlimit=100,vlimit=50,angle_limit=100,upper_angle=100,lower_angle=-100)
        args.update(changes)
        return grade(**args)

    def test_horizontal_and_angle_thresholds(self):
        self.assertEqual(self.value(horizontal=100),0)
        self.assertEqual(self.value(horizontal=101),3)
        for speed,expected in [(50,1),(51,2),(100,2),(101,3)]:
            self.assertEqual(self.value(angle0=101,horizontal=speed),expected)
        self.assertEqual(self.value(angle0=-101),1)
        self.assertEqual(self.value(angle1=-101),1)
        self.assertEqual(self.value(angle1=-32768,angle_limit=32767),0)

    def test_vertical_thresholds_and_existing_damage(self):
        for speed,expected in [(-50,0),(-51,1),(-100,1),(-101,2),(-200,2),(-201,3)]:
            self.assertEqual(self.value(vertical=speed),expected)
        self.assertEqual(self.value(vertical=-51,prior=3),3)
        self.assertEqual(self.value(prior=-1),255)

    def test_word_arithmetic(self):
        self.assertEqual(self.value(vertical=-32768),0)  # NEG.W wraps
        self.assertEqual(self.value(vertical=-21000,vlimit=20000),3)
        self.assertEqual(self.value(angle0=101,horizontal=-2,hlimit=-3),1)
        with self.assertRaises(ValueError):self.value(vertical=32768)

    def test_native_observation_requires_complete_matching_call(self):
        args=[0,0,0,-101,0,100,50,100,100,-100]
        frame=dict(contacts=[[3,*args]],impacts=[[3,2,-22,-101,2]])
        self.assertEqual(observed([frame])[0]['grade'],2)
        with self.assertRaises(ValueError):observed([])
        for end in ([3,2,-22,-101,1],[4,2,-22,-101,2]):
            with self.assertRaises(ValueError):observed([dict(contacts=[[3,*args]],impacts=[end])])
        with self.assertRaises(ValueError):observed([dict(contacts=[[3,*args]],impacts=[])])


if __name__ == '__main__':unittest.main()
