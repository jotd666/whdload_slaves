"""Ownership model for native attached camera poses (sim v1)."""

def identity(read,h3):
    camera=int.from_bytes(read(h3+0x8d72,4),'big')
    view=int.from_bytes(read(h3+0x6712,2),'big')
    target=camera if view==0 else int.from_bytes(read(h3+0x67ae,4),'big')
    return camera,view,target


def owner(read,h3,sim,camera,view,target):
    if identity(read,h3)!=(camera,view,target):
        raise ValueError('Camera identity changed after world capture')
    if view==0:return camera,False
    callback=int.from_bytes(read(h3+0x1a70,4),'big')
    if not 1<=view<=5 or callback!=sim+0x15666 or camera!=h3+0x677a:
        raise ValueError('Camera is not a verified attached pose-copy view')
    return target,True
