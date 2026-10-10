import unittest
from pose_history import History, POSE, registry


class PoseHistoryTests(unittest.TestCase):
    def setUp(self):
        self.memory = bytearray(65536)
        self.read = lambda p, n: bytes(self.memory[p:p+n])
        self.h = History()
        self.p = 0x100
        self.h.add(self.p)
        self.pose(0, 65530)
        self.h.capture(0, [self.p], self.read, ('cockpit', self.p))
        self.pose(100, 6)

    def pose(self, x, yaw):
        self.write(self.p+8, POSE.pack(x, -x, 0, 0, 0, yaw))

    def write(self, p, data): self.memory[p:p+len(data)] = data

    def capture(self): self.h.capture(1, [self.p], self.read, ('cockpit', self.p))

    def test_blend_restores_pose_and_preserves_unrelated_progress(self):
        self.capture()
        original = bytes(self.memory)
        with self.h.presentation(32768, self.read, self.write):
            self.assertEqual(POSE.unpack(self.read(self.p+8, 18)), (50, -50, 0, 0, 0, 0))
            self.memory[0x400] = 99
            with self.assertRaises(ValueError): self.h.remove(self.p)
            with self.assertRaises(ValueError): self.h.capture(2, [self.p], self.read, ('cockpit', self.p))
        self.assertEqual(self.read(self.p+8, 18), original[self.p+8:self.p+26])
        self.assertEqual(self.memory[0x400], 99)

    def test_exception_also_restores(self):
        self.capture()
        original = self.read(self.p+8, 18)
        with self.assertRaises(RuntimeError):
            with self.h.presentation(1234, self.read, self.write): raise RuntimeError('draw failure')
        self.assertEqual(self.read(self.p+8, 18), original)
        self.assertFalse(self.h.leased)

    def test_same_pointer_reuse_and_teleport_snap(self):
        for discontinuity in (lambda: (self.h.remove(self.p), self.h.add(self.p)),
                              lambda: self.h.discontinuity(self.p)):
            with self.subTest(discontinuity=discontinuity):
                discontinuity()
                tick = self.h.tick+1
                self.h.capture(tick, [self.p], self.read, ('cockpit', self.p))
                self.assertEqual(self.h.blended(0)[self.p], self.read(self.p+8, 18))

    def test_view_change_model_change_and_removed_pointer(self):
        self.h.capture(1, [self.p], self.read, ('external', self.p))
        self.assertEqual(self.h.blended(0)[self.p], self.read(self.p+8, 18))
        self.memory[self.p+3] = 1
        self.pose(200, 20)
        self.h.capture(2, [self.p], self.read, ('external', self.p))
        self.assertEqual(self.h.blended(0)[self.p], self.read(self.p+8, 18))
        self.h.remove(self.p)
        self.assertEqual(self.h.blended(32768), {})
        self.h.reset()
        self.assertEqual(self.h.current, {})

    def test_missing_event_tick_or_updated_camera_rejected(self):
        with self.assertRaises(ValueError): self.h.capture(2, [self.p], self.read, ('cockpit', self.p))
        with self.assertRaises(ValueError): self.h.capture(1, [], self.read, ('cockpit', self.p))
        self.capture()
        self.pose(101, 6)
        with self.assertRaises(ValueError):
            with self.h.presentation(100, self.read, self.write): pass

    def test_between_tick_view_change_and_tick_wrap(self):
        self.capture()
        self.h.view_change(('external', self.p))
        self.assertEqual(self.h.blended(32768), {})
        self.pose(200, 20)
        self.h.capture(2, [self.p], self.read, ('external', self.p))
        self.assertEqual(self.h.blended(0)[self.p], self.read(self.p+8, 18))
        self.h.reset()
        self.h.add(self.p)
        self.h.capture(0xffffffff, [self.p], self.read, ('external', self.p))
        self.h.capture(0, [self.p], self.read, ('external', self.p))
        self.assertEqual(self.h.tick, 0)

    def test_registry_validation_and_order_independence(self):
        self.write(0x859e, b'\x00\x02')
        self.write(0x85a0, (0x100).to_bytes(4, 'big')+(0x200).to_bytes(4, 'big'))
        self.assertEqual(registry(self.read, 0), [0x100, 0x200])
        self.h.add(0x200)
        self.h.capture(1, [0x200, self.p], self.read, ('cockpit', self.p))
        self.assertEqual(POSE.unpack(self.h.blended(32768)[self.p])[0], 50)
        self.write(0x85a4, (0x100).to_bytes(4, 'big'))
        with self.assertRaises(ValueError): registry(self.read, 0)
        self.write(0x859e, (501).to_bytes(2, 'big'))
        with self.assertRaises(ValueError): registry(self.read, 0)


if __name__ == '__main__': unittest.main()
