"""Reader for FS-UAE/Barto `monitor profile` trace files.

Layout (little-endian uint32 unless noted):
  fields, nsections, section bases[nsections], stack bounds (16 bytes)
  ROM, Chip, Slow snapshots: size + bytes each
  base clock, cycle unit
  per field: custom regs (size+bytes), AGA colours (size+bytes),
             DMA records (recsize, count, bytes), resource records (recsize, count, bytes),
             cycles, idle, nwords, instruction words, screenshot (size, kind, bytes)
  instruction record: one or more words < 0xffff0000 (first = PC; the rest are the
  return addresses of the stub's own call-stack sampling), then 0xffffffff-cost,
  then 17 registers (d0-d7, a0-a7, sr).
"""
import struct
from dataclasses import dataclass, field


@dataclass
class Field:
    index: int
    custom: bytes
    dma_size: int
    dma: memoryview
    cycles: int
    idle: int
    insn_off: int
    insn_end: int
    shot_kind: int
    shot: bytes


@dataclass
class Trace:
    data: memoryview
    sections: list
    rom: bytes
    chip: bytes
    slow: bytes
    fields: list = field(default_factory=list)

    def instructions(self, f):
        """Yield (pc, cost, regs) for every record of field f; pc is None while the CPU is
        stopped (STOP) and 0x7fffffff for interrupt entry."""
        d, off, end = self.data, f.insn_off, f.insn_end
        u = struct.unpack_from
        regs = struct.Struct('<17I').unpack_from
        while off < end:
            pc = None
            while True:
                v = u('<I', d, off)[0]
                off += 4
                if v >= 0xffff0000:
                    break
                if pc is None:
                    pc = v
            cost = 0xffffffff - v
            r = regs(d, off)
            off += 68
            yield pc, cost, r


def load(path):
    data = memoryview(open(path, 'rb').read())
    off = 0

    def w():
        nonlocal off
        v = struct.unpack_from('<I', data, off)[0]
        off += 4
        return v

    def blob():
        nonlocal off
        n = w()
        b = bytes(data[off:off + n])
        off += n
        return b

    nfields = w()
    nsec = w()
    sections = [w() for _ in range(nsec)]
    off += 16
    rom, chip, slow = blob(), blob(), blob()
    w(), w()
    t = Trace(data, sections, rom, chip, slow)
    for i in range(nfields):
        custom = blob()
        blob()
        dsize, dcount = w(), w()
        dma = data[off:off + dsize * dcount]
        off += dsize * dcount
        rsize, rcount = w(), w()
        off += rsize * rcount
        cycles, idle, n = w(), w(), w()
        ioff = off
        off += 4 * n
        ssize, skind = w(), w()
        shot = bytes(data[off:off + ssize])
        off += ssize
        t.fields.append(Field(i, custom, dsize, dma, cycles, idle, ioff, ioff + 4 * n, skind, shot))
    assert off == len(data), (off, len(data))
    return t
