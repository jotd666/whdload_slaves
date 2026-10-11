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
