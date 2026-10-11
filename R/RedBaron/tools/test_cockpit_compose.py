import random
import unittest
from cockpit_compose import Layer, update


class CockpitCompositionTests(unittest.TestCase):
    pitch, rows, planes = 8, 6, 5
    size = pitch * rows

    def compose(self, target, layers, rect=None):
        update(target, layers, rect or (0, 0, self.pitch, self.rows),
               pitch=self.pitch, rows=self.rows, planes=self.planes)

    def expected(self, layers):
        # Independent back-to-front byte painter, including opaque black.
        out = bytearray(6 * self.size)
        for layer in layers:
            if layer is None:
                continue
            for i, mask in enumerate(layer.mask):
                out[5 * self.size + i] |= mask
                for plane in range(5):
                    j = plane * self.size + i
                    out[j] = (out[j] & ~mask) | (layer.pixels[j] & mask)
        return out

    def test_random_ordered_layers(self):
        rng = random.Random(19222)
        for count in (1, 7, 10):
            layers = [Layer(rng.randbytes(5*self.size), rng.randbytes(self.size))
                      for _ in range(count)]
            out = bytearray([0xa5] * (6*self.size))
            self.compose(out, layers)
            self.assertEqual(out, self.expected(layers))

    def test_moving_gauge_exposes_base_and_preserves_foreground(self):
        base = Layer(bytes([0x55] * (5*self.size)), bytes([255] * self.size))
        foreground_mask = bytearray(self.size)
        foreground_mask[18:22] = b'\x80\x01\x80\x01'
        foreground = Layer(bytes(5*self.size), bytes(foreground_mask))
        def gauge(start):
            mask = bytearray(self.size)
            mask[start:start+4] = bytes([255] * 4)
            return Layer(bytes([0xcc] * (5*self.size)), bytes(mask))
        out = self.expected([base, gauge(16), foreground])
        layers = [base, gauge(20), foreground]
        before = bytes(out)
        self.compose(out, layers, (0, 2, 8, 1))
        self.assertEqual(out, self.expected(layers))
        for plane in range(6):
            for i in range(self.size):
                if not 16 <= i < 24:
                    self.assertEqual(out[plane*self.size+i], before[plane*self.size+i])

    def test_removal_clears_colour_and_coverage(self):
        top = Layer(bytes([255] * (5*self.size)), bytes([255] * self.size))
        out = self.expected([None, top])
        self.compose(out, [None, None])
        self.assertEqual(out, bytes(6*self.size))

    def test_bad_rect_and_layer_leave_output_untouched(self):
        layer = Layer(bytes(5*self.size), bytes(self.size))
        for layers, rect in [([layer], (1, 0, 2, 1)), ([layer], (0, 5, 8, 2)),
                             ([Layer(b'', b'')], (0, 0, 8, 6))]:
            out = bytearray([0xa5] * (6*self.size))
            with self.assertRaises(ValueError):
                self.compose(out, layers, rect)
            self.assertEqual(out, bytes([0xa5] * (6*self.size)))


class NativeStaticLayerTests(unittest.TestCase):
    def test_full_and_clipped_native_cookie_cut(self):
        from cockpit_compose import native_static_layer
        rng = random.Random(0x2c144)
        source = rng.randbytes(5*2880)
        mask = rng.randbytes(8000)
        for bottom in (65, 88, 139, 159, 199):
            layer = native_static_layer(source, mask, 3520, 4628, 2880, bottom)
            self.assertIsNotNone(layer)
            background = rng.randbytes(40000)
            expected = bytearray(background)
            rows = 72 - (159-bottom if 75 <= bottom < 159 else 0)
            # Independent native blitter-style oracle with packed source pitch.
            for plane in range(5):
                for row in range(rows):
                    for byte in range(40):
                        src = row*40+byte
                        dst = plane*8000+3520+src
                        expected[dst] = ((background[dst] & ~mask[src])
                                         | (source[plane*2880+src] & mask[src]))
            actual = bytearray(background)
            for plane in range(5):
                for byte, coverage in enumerate(layer.mask):
                    dst = plane*8000+byte
                    actual[dst] = ((actual[dst] & ~coverage)
                                   | (layer.pixels[dst] & coverage))
            self.assertEqual(actual, expected)

    def test_opaque_black_and_source_rows_beyond_clip(self):
        from cockpit_compose import native_static_layer
        layer = native_static_layer(bytes(5*2880), bytes([255])*8000, 3520, 4628, 2880, 139)
        self.assertEqual(layer.pixels, bytes(40000))
        self.assertEqual(layer.mask[3520:5600], bytes([255])*2080)
        self.assertEqual(layer.mask[5600:], bytes(2400))

    def test_unsupported_layouts_fall_back(self):
        from cockpit_compose import native_static_layer
        for offset, size, stride, bottom in ((3521,4628,2880,159), (6000,4628,2880,159),
                                           (3520,4627,2880,159), (3520,4628,2840,159),
                                           (3520,4628,2880,75)):
            self.assertIsNone(native_static_layer(bytes(5*2880), bytes(8000),
                                                 offset,size,stride,bottom))
