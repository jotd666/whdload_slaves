import struct
import unittest
from overlay_cache_key import build, KEY_BYTES, EFFECTS
from overlay_dependency_guard import matches
from cockpit_raster import render
import test_cockpit_dependencies


class RuntimeOverlayKeyTests(unittest.TestCase):
    def fixture(self):
        return test_cockpit_dependencies.CockpitDependencyTests().fixture()

    def match(self, key, read):
        def memory(address, size):
            if address >= 0x40000:
                return key[address - 0x40000:address - 0x40000 + size]
            return read(address, size)
        return matches(memory, 0x40000, 3)[0]

    def test_pixel_model_inputs_invalidate_runtime_key(self):
        # Exercise independent renderer inputs, including script, colour mapping,
        # source data/mask, clipping, and the selected bitmap descriptor.
        for offset in (0xc004, 0x3ab7, 0x101d, 0xc200, 0xc300, 0x9d48, 0xc188):
            data, read = self.fixture()
            key = build(read, 0, 3, 0x40000)
            self.assertTrue(self.match(key, read))
            data[offset] ^= 1
            with self.subTest(offset=offset):
                self.assertFalse(self.match(key, read))

    def test_unchanged_pixels_ignore_output_pens_and_destination(self):
        data, read = self.fixture()
        key = build(read, 0, 3, 0x40000)
        before = render(read, 0, 3, bytes(40000))
        data[0x9d50:0x9d56] = bytes([17] * 6)
        struct.pack_into('>I', data, 0x9d72, 0x10000)
        self.assertEqual(before, render(read, 0, 3, bytes(40000)))
        self.assertTrue(self.match(key, read))
        self.assertEqual(len(key), KEY_BYTES)

    def test_changed_selector_prevents_read_of_old_resource(self):
        for selector, resource in ((0x7b5e, 0xc000), (0x3b06, 0xc100),
                                   (0xc100, 0xc180), (0xc180, 0xc200)):
            data, read = self.fixture()
            key = build(read, 0, 3, 0x40000)
            struct.pack_into('>I', data, selector, 0xffff0000)
            def guarded(address, size):
                self.assertFalse(address <= resource < address + size)
                return read(address, size)
            with self.subTest(selector=selector):
                self.assertFalse(self.match(key, guarded))

    def test_unsupported_or_unbounded_script_falls_back(self):
        for words in ((0xa0a4, 0, 0, 1, 1, 0xff0), (0xffff, 0xff0),
                      tuple([0x2002, 8, 8] * 86)):
            data, read = self.fixture()
            struct.pack_into('>' + 'H' * len(words), data, 0xc000, *words)
            with self.assertRaises(ValueError):
                build(read, 0, 3)

    def test_oversize_source_is_rejected_before_reading_data(self):
        data, read = self.fixture()
        struct.pack_into('>IIHHIH', data, 0xc180, 0x18000, 0x19000, 320, 200, 8000, 0)
        def guarded(address, size):
            self.assertLess(address, 0x18000)
            return read(address, size)
        with self.assertRaisesRegex(ValueError, 'capacity'):
            build(guarded, 0, 3)

    def test_write_mask_distinguishes_untouched_native_state(self):
        data, read = self.fixture()
        self.assertEqual(int.from_bytes(build(read, 0, 3)[EFFECTS:], 'big'), 15)
        words = (0x2002, 8, 8, 0xa104, 1, 1, 2, 2, 0xff0)
        struct.pack_into('>9H', data, 0xc000, *words)
        self.assertEqual(int.from_bytes(build(read, 0, 3)[EFFECTS:], 'big'), 17)
