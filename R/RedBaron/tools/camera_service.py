"""Independent 128-unit free-camera arithmetic and native service evidence checks."""
from mouse_replay import control, signed


def free_rotation(pitch, yaw, x, y):
    # Native word shift precedes signed long multiply and arithmetic shift.
    dx = (signed(x << 7, 16) * 128) // 256
    dy = (signed(y << 7, 16) * 128) // 256
    dx = max(-32767, min(32767, dx))
    dy = max(-32767, min(32767, dy))
    return (pitch + dy) & 0xffff, (yaw - dx) & 0xffff


def check_capture(before, after):
    def require(condition, message):
        if not condition:
            raise ValueError(message)
    require(len(before) == len(after) and len(before) >= 100, 'Incomplete service observations')
    moving = queued = updates = 0
    entered_free = False
    for index, (pre, post) in enumerate(zip(before, after)):
        require(len(pre) == 16 and len(post) == 22, 'Wrong native record format')
        require(pre[:10] == post[:10], f'Service changed flight input, command FIFO or clock ({index})')
        require(pre[14:16] == post[14:16] and pre[15] == 0,
                'Camera mode changed during a service')
        mode = pre[14]
        require(mode == 24 or (mode == 0 and not entered_free),
                'Free-camera fixture left its selected mode')
        entered_free |= mode == 24
        require(post[10:12] == [160, 100], 'Camera sample was not consumed')
        require(post[16:18] == [0, 0], 'Fixture gained a command or unexpected button mode')
        expected = [control(pre[10], 160)[0] >> 2, control(pre[11], 100)[0] >> 2]
        require(post[18:20] == expected, f'Wrong native camera control ({index})')
        target = free_rotation(*pre[12:14], *expected) if mode == 24 else tuple(pre[12:14])
        require(tuple(post[12:14]) == target,
                f'Camera did not use exactly one 128-unit update ({index})')
        updates += int(mode == 24)
        require(post[20:22] == [index + 1, updates], 'Missing/extra camera dispatch')
        moving += int(any(expected))
        queued += int(pre[4] != pre[5])
    for pre, post in zip(after, after[1:]):
        elapsed = (post[0] - pre[0]) & 0xffffffff
        require(elapsed in (2, 3), 'Service missed a CIA funding boundary')
        require(post[1] == (pre[1] + 1) & 0xffff, 'Service funding count skipped or repeated')
        require(post[3] == pre[3] + elapsed * 1024 - 2560,
                'Secondary service remainder differs from exact clock accounting')
    require(moving and queued and updates >= 100, 'Fixture did not exercise motion and a nonempty command queue')
    return dict(services=len(after), free_camera_updates=updates, moving_services=moving, queued_command_services=queued,
                clock_deadlines=True, world_input_unchanged=True, command_fifo_unchanged=True,
                secondary_clock_restored=True, free_camera_arithmetic=True)
