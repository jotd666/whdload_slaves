"""FC8 journal model and fail-closed native evidence reader.

A cache entry is (address, original bytes, presentation bytes). Native undo
journals can repeat stores: the first world value and final presentation value
must survive deduplication. This model does not model terrain selection.
"""
import struct


def coalesce(journal, memory):
    entries = {}
    for address, original in journal:
        if len(original) not in (1, 2):
            raise ValueError('invalid terrain write width')
        key = address, len(original)
        if key not in entries:
            entries[key] = (address, original, bytes(memory[address:address+len(original)]))
    return list(entries.values())


def matches(entries, memory):
    return all(bytes(memory[a:a+len(old)]) == old for a, old, new in entries)


def install(entries, memory):
    undo = []
    for address, old, new in entries:
        undo.append((address, bytes(memory[address:address+len(new)])))
        memory[address:address+len(new)] = new
    return undo


def restore(journal, memory):
    for address, old in reversed(journal):
        memory[address:address+len(old)] = old


def check(raw):
    if len(raw) != 16:
        raise ValueError('expected four native FC8 counters')
    hits, misses, sabotages, restored = struct.unpack('>4I', raw)
    if hits < 2 or misses < 1 or sabotages != 3 or restored < hits:
        raise ValueError('incomplete FC8 native checks')
    return dict(installs=hits, misses=misses, sabotages=sabotages, restored=restored)
