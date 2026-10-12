"""Validate bounded native FC4 polygon results; timings are separate."""
import struct

def check(data):
    if len(data)!=20:raise ValueError('Truncated scene twin result')
    mask,armed,count,a,b=struct.unpack('>5I',data)
    if mask!=63 or armed or count!=6 or a or b:
        raise ValueError(f'Incomplete or failed primitive twins: {mask:x}, {armed}, {count}, {a:x}, {b:x}')
    return dict(primitive_checks=6,polygon_types=['triangle','quadrilateral','larger convex'])
