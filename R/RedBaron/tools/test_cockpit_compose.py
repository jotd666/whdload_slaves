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


class NativeGaugeLayerTests(unittest.TestCase):
    def test_resource_background_and_exact_needle_edges(self):
        from cockpit_compose import native_gauge_layer
        # Deliberately unrelated scene: it must not leak outside the needle.
        frame = bytes([255])*40000
        layer = native_gauge_layer(bytes(5*4*3), bytes([255,255,255,255,0,0])*3,
                                   32, 3, 5, 100, frame, (9,101,3,1))
        self.assertIsNotNone(layer)
        for plane in range(5):
            for y in range(200):
                for x in range(320):
                    bit = 128 >> (x % 8)
                    self.assertEqual(bool(layer.pixels[plane*8000+y*40+x//8] & bit),
                                     y == 101 and 9 <= x < 12)
        self.assertEqual(sum(byte.bit_count() for byte in layer.mask), 32*3)

    def test_random_shifted_resource_pixels(self):
        from cockpit_compose import native_gauge_layer
        rng = random.Random(0x19de0)
        for x in (0, 1, 7, 15, 16, 288):
            source = rng.randbytes(5*4*3)
            layer = native_gauge_layer(source, bytes([255,255,255,255,0,0])*3,
                                       32,3,x,100,bytes(40000),(x+3,101,5,1))
            for plane in range(5):
                for y in range(3):
                    for col in range(32):
                        expected = bool(source[plane*12+y*4+col//8] & (128 >> (col%8)))
                        if y == 1 and 3 <= col < 8:
                            expected = False
                        self.assertEqual(bool(layer.pixels[plane*8000+(100+y)*40+(x+col)//8]
                                              & (128 >> ((x+col)%8))), expected)

    def test_holes_padding_and_outside_rectangle_reject(self):
        from cockpit_compose import native_gauge_layer
        source, frame = bytes(5*4), bytes(40000)
        for mask, rect in ((bytes([255,254,255,255,0,0]),(0,0,32,1)),
                           (bytes([255,255,255,255,0,1]),(0,0,1,1)),
                           (bytes([255,255,255,255,0,0]),(31,0,2,1))):
            self.assertIsNone(native_gauge_layer(source,mask,32,1,0,0,frame,rect))


class PackedGaugeStorageTests(unittest.TestCase):
    def test_bounded_pitch_round_trip_for_shifted_gauges(self):
        from cockpit_compose import native_gauge_layer
        for x, width, height in ((1,64,64),(7,48,64),(15,64,64),(255,64,64),
                                 (288,32,64),(112,96,15),(113,96,15)):
            pitch = ((width+15)//16)*2
            layer = native_gauge_layer(bytes([0xa5])*(pitch*height*5),
                (bytes([255])*pitch+b'\0\0')*height, width,height,x,100,
                bytes([0x5a])*40000,(x+2,101,5,3))
            self.assertIsNotNone(layer)
            left = (x//16)*2
            rowbytes = ((x+pitch*8+15)//16)*2-left
            self.assertLessEqual(rowbytes*height,640)
            packed = bytearray(640*6)
            full = layer.pixels+layer.mask
            for plane in range(6):
                for row in range(height):
                    start=plane*8000+(100+row)*40+left
                    dest=plane*640+row*rowbytes
                    packed[dest:dest+rowbytes]=full[start:start+rowbytes]
            expanded=bytearray(48000)
            for plane in range(6):
                for row in range(height):
                    src=plane*640+row*rowbytes
                    dest=plane*8000+(100+row)*40+left
                    expanded[dest:dest+rowbytes]=packed[src:src+rowbytes]
            self.assertEqual(expanded,full)

    def test_exact_output_alias_for_ordered_accumulation(self):
        rng=random.Random(19000)
        layers=[Layer(rng.randbytes(40000),rng.randbytes(8000)) for _ in range(3)]
        expected=bytearray(48000)
        update(expected,layers,(0,0,40,200))
        actual=bytearray(48000)
        update(actual,layers[:1],(0,0,40,200))
        for layer in layers[1:]:
            alias=Layer(memoryview(actual)[:40000],memoryview(actual)[40000:])
            update(actual,[alias,layer],(0,0,40,200))
        self.assertEqual(actual,expected)

    def test_oversized_packed_gauge_rejects(self):
        from cockpit_compose import native_gauge_layer
        self.assertIsNone(native_gauge_layer(bytes(12*64*5),
            (bytes([255])*12+b'\0\0')*64,96,64,1,100,bytes(40000),(2,101,2,2)))


class IncrementalCompositionTests(unittest.TestCase):
    def test_page_generation_and_moving_bounds(self):
        from cockpit_compose import dirty_bounds
        old = [(1,(2,10,4,4))]
        self.assertIsNone(dirty_bounds(old,old))
        self.assertEqual(dirty_bounds(old,[(2,(8,20,2,2))]),(2,10,8,12))
        self.assertEqual(dirty_bounds(old,old,valid=False),(0,0,40,200))
        # Same rectangle on another native page still needs rebuilding.
        self.assertEqual(dirty_bounds(old,[(3,old[0][1])]),old[0][1])

    def test_dirty_accumulation_matches_full_with_stale_scratch(self):
        from cockpit_compose import dirty_bounds, intersection
        rng = random.Random(19021)
        pitch,rows,size=12,10,120
        def layer(rect):
            image=rng.randbytes(size*5);mask=bytearray(size)
            x,y,w,h=rect
            for row in range(y,y+h):
                mask[row*pitch+x:row*pitch+x+w]=rng.randbytes(w)
            return Layer(image,bytes(mask))
        base=layer((0,0,pitch,rows));foreground=layer((2,1,8,8))
        rects=[(0,1,6,5),(4,3,6,5),(8,0,4,4)]
        gauges=[layer(r) for r in rects]
        tags=[(i+1,r) for i,r in enumerate(rects)]
        actual=bytearray(6*size)
        update(actual,[base,*gauges,foreground],(0,0,pitch,rows),pitch=pitch,rows=rows)
        for serial in range(4,34):
            i=serial%3;old=tags[:]
            rects[i]=(2*(serial%4),serial%5,4,5)
            gauges[i]=layer(rects[i]);tags[i]=(serial,rects[i])
            dirty=dirty_bounds(old,tags,pitch=pitch,rows=rows)
            update(actual,[base],dirty,pitch=pitch,rows=rows)
            # Scratch deliberately contains unrelated data outside the gauge.
            scratch=bytearray(rng.randbytes(size*6))
            for gauge,rect in zip(gauges,rects):
                clip=intersection(dirty,rect)
                if clip is None:
                    continue
                x,y,w,h=rect;full=gauge.pixels+gauge.mask
                for plane in range(6):
                    for row in range(y,y+h):
                        start=plane*size+row*pitch+x
                        scratch[start:start+w]=full[start:start+w]
                alias=Layer(memoryview(actual)[:size*5],memoryview(actual)[size*5:])
                expanded=Layer(memoryview(scratch)[:size*5],memoryview(scratch)[size*5:])
                update(actual,[alias,expanded],clip,pitch=pitch,rows=rows)
            alias=Layer(memoryview(actual)[:size*5],memoryview(actual)[size*5:])
            update(actual,[alias,foreground],dirty,pitch=pitch,rows=rows)
            expected=bytearray(6*size)
            update(expected,[base,*gauges,foreground],(0,0,pitch,rows),pitch=pitch,rows=rows)
            self.assertEqual(actual,expected)


class GaugeFixedPointTests(unittest.TestCase):
    def test_opaque_black_and_every_plane_must_match(self):
        from cockpit_compose import gauge_pixels_match
        mask=bytearray(8000);mask[5010]=0x81
        layer=Layer(bytes(40000),bytes(mask))
        frame=bytearray(40000)
        self.assertTrue(gauge_pixels_match(frame,layer))
        for plane in range(5):
            frame[plane*8000+5010]=0x80
            self.assertFalse(gauge_pixels_match(frame,layer))
            frame[plane*8000+5010]=0
        # Unowned scene bits must not reject an otherwise exact gauge.
        frame[5010]=0x7e;frame[30000]=255
        self.assertTrue(gauge_pixels_match(frame,layer))
