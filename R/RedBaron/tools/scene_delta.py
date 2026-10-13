"""FC5 reference model and bounded native-copy checker."""
import struct

class Pages:
    def __init__(self):
        self.view = None
        self.pages = [None, None]
        self.shadows = [None, None]

    def invalidate(self):
        self.shadows = [None, None]

    def copy(self, role, identity, source, destination, top=0, height=120):
        assert len(source) == len(destination) == 40000 and role in (0, 1)
        assert 0 <= top < 88 < top+height <= 200 and 0 < height <= 120
        if self.view != (top, height):
            self.invalidate()
            self.view = (top, height)
        shadow = self.shadows[role] if self.pages[role] == identity else None
        packed = bytearray()
        writes = 0
        for plane in range(5):
            for offset in range(0, height*40, 4):
                at = plane * 8000 + top*40 + offset
                old = plane * height*40 + offset
                value = source[at:at+4]
                if shadow is None or offset + top*40 >= 3520 or value != shadow[old:old+4]:
                    destination[at:at+4] = value
                    writes += 1
                packed.extend(value)
        self.pages[role], self.shadows[role] = identity, packed
        return writes

def check_pixels(source, destination, top=0, height=120):
    if len(source) != 40000 or len(destination) != 40000:
        raise ValueError('Incomplete screen')
    if any(source[p*8000+top*40:p*8000+(top+height)*40] != destination[p*8000+top*40:p*8000+(top+height)*40] for p in range(5)):
        raise ValueError('Viewport differs from native full-copy output')

def check(data):
    if len(data) != 4 or struct.unpack('>I', data)[0] < 2:
        raise ValueError('Missing native viewport-copy checks')
    return dict(exact_copies=struct.unpack('>I', data)[0])
