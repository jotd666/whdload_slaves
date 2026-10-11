"""Bounded W6 debt in primary units, including unprocessed CIA funding.

1800 units are four 68000/eight 020+ quanta, just below one nominal second
at Time Scale 40. Preserve exact phase; use a conservative bound only to
choose which overdue updates to drop. F changes in the player occur at
rebased modal boundaries. Compression changes at an owned world boundary.
"""
import struct
from game_time_core import THRESHOLD
LIMIT = 1800

def phase_upper(phase, quantum):
    if quantum not in (225, 450) or not 0 <= phase < THRESHOLD:
        raise ValueError('Invalid phase or quantum')
    high = THRESHOLD >> 112
    assert high == 0x057d
    return min(quantum, ((phase >> 112) + 1)*quantum//high + 1)

def drop_due(phase, due, remaining_cia, divisor, multiplier=1, quantum=225):
    if not 10 <= divisor <= 80 or multiplier not in (1, 8) or remaining_cia < 0:
        raise ValueError('Invalid debt inputs')
    if not due:
        return False
    if remaining_cia > 160:
        return True
    room = LIMIT - phase_upper(phase, quantum) - due*quantum
    return remaining_cia*1024*multiplier > room*divisor

def check_quantum_twin(data):
    if len(data) != 28 or data[:8] != b'RBTQ4501':
        raise ValueError('Invalid quantum twin header')
    version, calls, straight, banked, mismatch = struct.unpack('>5I', data[8:])
    if version != 1 or not straight or not banked or calls != straight+banked or mismatch:
        raise ValueError('Failed or incomplete quantum twin')
    return dict(calls=calls, straight=straight, banked=banked)
