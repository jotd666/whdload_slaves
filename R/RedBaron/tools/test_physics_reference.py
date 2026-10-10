import copy
import unittest
from physics_reference import trajectory,compare


class PhysicsReferenceTests(unittest.TestCase):
    def sample(self,dt,updates):
        rows=[dict(step=i+1,position=[i,0,0],orientation=[0,0,0],
                   held_key=dict(code=0x4e,value=1)) for i in range(updates+1)]
        records=[dict(step=i+1,dt=dt,F=33,time_scale=40) for i in range(updates+1)]
        return rows,records

    def test_equal_time_requires_different_update_counts(self):
        a=trajectory(*self.sample(225,4));b=trajectory(*self.sample(100,9))
        result=compare(a,b)
        self.assertEqual(result['candidate']['budget'],900)
        self.assertEqual(result['endpoint_separation'],5)
        with self.assertRaisesRegex(ValueError,'Unequal'):compare(a,trajectory(*self.sample(100,8)))

    def test_missing_or_released_control_rejected(self):
        rows,records=self.sample(100,9)
        for key in (None,dict(code=0x4e,value=0),dict(code=0x51,value=1)):
            altered=copy.deepcopy(rows);altered[4]['held_key']=key
            with self.assertRaisesRegex(ValueError,'Constant Right'):trajectory(altered,records)

    def test_nonconsecutive_or_variable_step_rejected(self):
        rows,records=self.sample(100,9)
        with self.assertRaisesRegex(ValueError,'Nonconsecutive'):trajectory(rows[:3]+rows[4:],records)
        records[4]['dt']=225
        with self.assertRaisesRegex(ValueError,'fixed proportional'):trajectory(rows,records)

    def test_orientation_difference_wraps_and_initial_pose_must_match(self):
        a=trajectory(*self.sample(225,4));b=trajectory(*self.sample(100,9))
        a['final_orientation']=[32767,0,0];b['final_orientation']=[-32768,0,0]
        self.assertEqual(compare(a,b)['orientation_difference'],[-1,0,0])
        b['initial_position']=[1,0,0]
        with self.assertRaisesRegex(ValueError,'starting pose'):compare(a,b)
