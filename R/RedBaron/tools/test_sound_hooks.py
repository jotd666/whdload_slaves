import tempfile
import unittest
from pathlib import Path
from hook_ranges import ranges


class SoundHookTests(unittest.TestCase):
    def test_domains_and_file_offset_translation(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp)
            (source/'hooks.s').write_text('; PERF_RANGE sim:00c50 10 bit=10\n; PERF_RANGE sound:00c50 10 bit=12\n')
            self.assertEqual(ranges(source)[0][:3], (0xc50, 0xc5a, 10))
            self.assertEqual(ranges(source, 'sound')[0][:3], (0xc28, 0xc32, 12))

    def test_overlap_is_per_executable(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp)
            (source/'hooks.s').write_text('; PERF_RANGE sound:00c50 10 bit=12\n; PERF_RANGE sound:00c52 6 bit=13\n')
            with self.assertRaises(ValueError):
                ranges(source, 'sound')
