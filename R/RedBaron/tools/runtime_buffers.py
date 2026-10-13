"""Resolve current runtime buffer cells and historical embedded capture symbols."""
import re
from presentation_state import symbol


def live_address(lines, base, name, command):
    try:
        cell = base + symbol(lines, name + '_ptr')
    except ValueError:
        return base + symbol(lines, name)
    reply = command(f'gdb printf "RUNTIME_BUFFER %u\\n", *(unsigned int*){cell:#x}')
    match = re.search(r'RUNTIME_BUFFER (\d+)', reply)
    if not match or not int(match[1]) or int(match[1]) & 1:
        raise ValueError('Unallocated or invalid buffer ' + name)
    return int(match[1])


NAMES = ('time_present_cache_buffer', 'time_model_buffer', 'time_present_list_buffer',
         'time_pose_current', 'time_pose_previous', 'time_blend_output',
         'time_input_observe_queue')


def check_layout(values, enabled, interpolated, verify=False, observe_only=False):
    """Check ownership, contiguous subregions, and absence on disabled paths."""
    if len(values) != 8:
        raise ValueError('Missing runtime buffer pointers')
    cache, model, listing, current, previous, blend, queue, scenery = values
    if not enabled:
        if observe_only and verify:
            if any(values[:6]) or scenery or not queue or queue & 7:
                raise ValueError('Invalid observation-only buffer layout')
            return [(queue,4112)]
        if any(values):
            raise ValueError('W6 disabled but buffers allocated')
        return []
    if model != cache+14336 or listing != model+32768:
        raise ValueError('Presentation buffer offsets differ')
    regions = [(cache, 49108 if verify else 49104), (queue, 4112)]
    if interpolated:
        if previous != current+13000 or blend != previous+13000:
            raise ValueError('Pose buffer offsets differ')
        regions.append((current, 39000))
    elif current or previous or blend:
        raise ValueError('68000 allocated interpolation buffers')
    if scenery:
        regions.append((scenery, 80128 if verify else 77480))
    for address, size in regions:
        if not address or address & 7 or address+size > 2**32:
            raise ValueError('Unallocated or unaligned Fast RAM region')
    regions.sort()
    if any(a+n > b for (a,n),(b,_) in zip(regions, regions[1:])):
        raise ValueError('Runtime regions overlap')
    return regions


def check_live(lines, base, command, enabled, interpolated, verify=False, observe_only=False):
    names = [name+'_ptr' for name in NAMES]+['time_scenery_storage']
    operands = ', '.join(f'*(unsigned int*){base+symbol(lines,n):#x}' for n in names)
    reply = command('gdb printf "BUFFER_LAYOUT '+' '.join(['%u']*8)+'\\n", '+operands)
    match = re.search(r'BUFFER_LAYOUT ([0-9 ]+)', reply)
    if not match:
        raise ValueError('Missing live buffer layout')
    values = list(map(int, match[1].split()))
    regions = check_layout(values, enabled, interpolated, verify, observe_only)
    return dict(pointers=dict(zip(names,values)), regions=regions,
                allocated_bytes=sum(n for _,n in regions), verify=verify)
