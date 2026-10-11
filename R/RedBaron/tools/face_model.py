"""G5 vertex-loop orchestration; transform/project math stays in native callbacks."""
from copy import deepcopy

def original(vertices, state):
    state = deepcopy(state)
    state['count'] = 0
    behind = False
    calls = []
    for vertex in vertices:
        if vertex == 255:
            break
        transform(vertex, state, calls)
        if state['flags'][vertex] != 2:
            if state['z'][vertex] < state['bound']:
                state['flags'][vertex] = 3
                behind = True
            else:
                state['flags'][vertex] = 2
                project(vertex, state, calls)
        index = state['count']
        state['count'] = (index + 1) & 65535
        state['list'][index] = vertex
    return state, behind, calls

def fast(vertices, state):
    state = deepcopy(state)
    state['count'] = 0
    flags, bound, output = state['flags'], state['bound'], state['list']
    count = 0
    behind = False
    calls = []
    for vertex in vertices:
        if vertex == 255:
            break
        transform(vertex, state, calls)
        if flags[vertex] != 2:
            if state['z'][vertex] < bound:
                flags[vertex] = 3
                behind = True
            else:
                flags[vertex] = 2
                project(vertex, state, calls)
        output[count] = vertex
        count = (count + 1) & 65535
        state['count'] = count
    return state, behind, calls

def transform(vertex, state, calls):
    calls.append(('transform', vertex, state['count']))
    if not state['flags'][vertex]:
        state['flags'][vertex] = 1
        state['z'][vertex] = state['source'][vertex]
        state['scratch'] = vertex

def project(vertex, state, calls):
    calls.append(('project', vertex, state['count']))
    state['projected'][vertex] = state['z'][vertex] // 3
    state['scratch'] = -vertex

def check_header(data):
    import struct
    if len(data) != 32 or data[:8] != b'RBFACE01':
        raise ValueError('invalid face twin header')
    version, calls, mismatch, fast_calls, hits, misses = struct.unpack('>6I', data[8:])
    if version != 1 or not calls or mismatch or not fast_calls or not hits or not misses:
        raise ValueError('incomplete or failed face twin')
    return calls
