"""Set the player checkbox in classic/NewIcon/ColorIcon files, preserving artwork."""
from pathlib import Path
import struct
import sys


def enable(data):
    assert data[:4] == bytes.fromhex('e3100001')
    u32 = lambda off: struct.unpack_from('>I', data, off)[0]
    assert u32(66) == 0, 'Only game/project icons are supported'
    at = 78
    for pointer in (22, 26):
        if u32(pointer):
            while True:
                width, height, depth = struct.unpack_from('>HHH', data, at + 4)
                following = u32(at + 16)
                at += 20 + ((width + 15) // 16) * 2 * height * depth
                if not following:
                    break
    if u32(50):
        at += 4 + u32(at)
    assert u32(54), 'Expected an existing tooltype array'
    start = at
    count = u32(at) // 4 - 1
    assert 0 <= count <= 10000
    at += 4
    strings = []
    for _ in range(count):
        size = u32(at)
        value = data[at + 4:at + 4 + size]
        assert len(value) == size and value.endswith(b'\0')
        strings.append(value)
        at += 4 + size
    # NewIcon image strings and trailing ColorIcon chunks remain byte-for-byte.
    strings = [s for s in strings if not s.upper().startswith((b'CUSTOM2=', b'CUSTOM3='))]
    strings.insert(0, b'CUSTOM2=1\0')
    table = struct.pack('>I', (len(strings) + 1) * 4)
    table += b''.join(struct.pack('>I', len(s)) + s for s in strings)
    return data[:start] + table + data[at:]


if __name__ == '__main__':
    for name in sys.argv[1:]:
        p = Path(name)
        result = enable(p.read_bytes())
        assert enable(result) == result
        p.write_bytes(result)
        print(p.name, 'CUSTOM2=1')
