import tempfile
import unittest
from pathlib import Path
from render_mutations import Snapshot, spans, region, compare


class RenderMutationTests(unittest.TestCase):
    def test_ranges_preserve_all_changes(self):
        self.assertEqual(spans(b'abcdef', b'xbcyzz'), [(0, 1), (3, 6)])
        self.assertEqual(region(b'abc', b'abc')['changed_bytes'], 0)
        with self.assertRaises(ValueError): spans(b'a', b'ab')

    def test_snapshot_and_object_changes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            before = bytearray(0xd000)
            before[0x4578:0x457c] = (0xc000).to_bytes(4, 'big')
            before[0xc200] = 64
            before[0xc000] = 8
            after = before.copy()
            after[0xc008] = 1
            after[0xc202] = 2
            after[0xc028] = 4
            after[0x123] = 3
            (root/'a').write_bytes(before)
            (root/'b').write_bytes(after)
            a = Snapshot(root, [dict(base=0, size=len(before), file='a')])
            b = Snapshot(root, [dict(base=0, size=len(after), file='b')])
            result = compare(a, b, 0, [0xc000, 0xc200])
            self.assertEqual(result['ram'][0]['changed_bytes'], 4)
            self.assertEqual(result['h3']['changed_bytes'], 1)
            self.assertEqual(result['player']['changed_bytes'], 2)
            self.assertEqual([x['prefix']['changed_bytes'] for x in result['render_objects']], [1, 1])
            self.assertEqual(result['render_objects'][0]['projection_cache']['changed_bytes'], 1)
            self.assertFalse(result['player_pointer_changed'])
            with self.assertRaises(ValueError): a.read(0xcfff, 2)
            with self.assertRaises(ValueError): Snapshot(root, [dict(base=0, size=1, file='a')])
            with self.assertRaises(ValueError): Snapshot(root, [dict(base=0, size=len(before), file='a'), dict(base=1, size=len(after), file='b')])


if __name__ == '__main__': unittest.main()
