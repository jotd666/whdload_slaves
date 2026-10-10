"""Independent publication deadlines in PAL fields, including 32-bit wrap.

A frame may publish once at least two field boundaries have passed. This is
an average 25-field-pairs/s ceiling, not a promise of 40 ms between every pair
when publication phase changes. The game's beam wait supplies the safe phase.
W6 uses minimum=1 for a 50-publications/s ceiling; world funding is independent.
"""
MASK = (1 << 32) - 1


def ready(now, previous, minimum=2):
    return previous is None or ((now - previous) & MASK) >= minimum


def safe_line(line):
    return line <= 40 or line > 244


def schedule(arrivals, minimum=2):
    """Unbounded-integer reference: no catch-up debt after a slow frame."""
    previous = None
    result = []
    for arrival in arrivals:
        publication = arrival if previous is None else max(arrival, previous + minimum)
        result.append(publication)
        previous = publication
    return result


def vbl_replay(registers, loaded_addresses, word):
    """Original MOVEM.L (a1)+,a3-a6; MOVE.W (a1),d0 architectural result."""
    if len(loaded_addresses) != 4 or not 0 <= word <= 0xffff:
        raise ValueError('Require four address values and one word')
    result = dict(registers)
    for name, value in zip(('a3', 'a4', 'a5', 'a6' if 'a6' in result else 'fp'), loaded_addresses):
        result[name] = value
    result['a1'] = (result['a1'] + 16) & MASK
    result['d0'] = (result['d0'] & 0xffff0000) | word
    sr = 'ps' if 'ps' in result else 'sr'
    result[sr] = (result[sr] & ~15) | (8 if word & 0x8000 else 0) | (4 if word == 0 else 0)
    return result
