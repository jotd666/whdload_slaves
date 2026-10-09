# Red Baron verification groundwork

The work order and acceptance requirements are in `performance-plan.md`. Performance
patches are not yet installed. This document records the observer ABI and current W0
validation; it does not mark the complete W0 gate as passed.

## VERIFY observers

The existing flight-input hook records one entry after incrementing the game-step counter,
when the scripted menu/preferences route is complete. The additional VBlank hook replaces
one complete LEA at `sim:2d348`; it reconstructs the original LEA, counts VBlanks and restores
SR. The callback runs in supervisor interrupt context. Both instruments are VERIFY-only
and apply only to the existing supported v1 patch list.

The live `RBSTEPS1` header contains seven longwords after its eight-byte signature:
version, record stride, capacity, committed count, ring pointer, h3 base, sim base.
A VBlank-count longword follows. Pointers initialize only in the live slave. The ring
has 256 entries, each 44 bytes. It overwrites the oldest entry on wrap. The committed
count advances only after all fields of the new record have been written.

| Record byte offset | Type | Meaning |
| --- | --- | --- |
| 0 | long | Flight step |
| 4 | long | Lifetime CIA ticks, `sim:30006` |
| 8 | long | Beam-position register pair |
| 12 | long | Display-buffer pointer, `h3:09d66` |
| 16 | word | Previous elapsed-time argument, `h3:0483a` |
| 18 | word | World dt, `h3:04834` |
| 20 | word | Secondary dt, `h3:04836` |
| 22 | word | Time-scale divisor F, `h3:04838` |
| 24 | word | Time Scale, `h3:03d56` |
| 26 | word | View redraw counter, `h3:06716` |
| 28 | word | Zero-extended **byte** dirty counter, `h3:0711c` |
| 30 | word | Top-text redraw counter, `h3:045b8` |
| 32 | long | World/frame counter, `h3:03254` |
| 36 | word | Message countdown, `h3:04820` |
| 38 | word | Reserved, zero |
| 40 | long | VBlank count |

The message-dirty variable is byte-sized: reading a word also includes an unrelated
adjacent byte. The other listed counters retain their original widths.

## Checks completed

- A VERIFY build reaches the accepted maximum-detail flight checkpoint with observers.
- The record reports Time Scale 40, F=33 and dt=450 in the measured slow-machine window.
- Eleven read-only breakpoints at `sim:3154a` agreed with the subsequent step records in
  both VBlank and CIA-tick counts, for steps 2–12.
- A single 100-field trace starting after step 12 contained four copper-list updates and
  four subsequent step-log advances. Their VBlank intervals agreed (23, 26 and 24 fields).
- The normal slave remains byte-identical to the pre-observer build and contains neither
  observer marker. This proves exclusion of instrumentation, **not** equivalence with the
  shipped 2.1 slave; W0.1 is still a separate required check.
- Normal, DEVELOPER and VERIFY builds have separate local outputs. Assembly listings can
  be retained with captures.

Two fresh boots of the same VERIFY build produced identical instruction records, DMA
records and screenshots for all 100 recorded fields at the initial flight checkpoint.
This covers the initial event window; the steady, bank and dense windows and exact
same-window three-way comparison remain required before W0.3/W0.4 are complete. The observer adds code and RAM;
performance measurements must consistently use the same instrumentation build.

## Capture continuity

The VBlank observer confirms that this Barto build advances through an unrecorded interval
when starting a profile command. At consecutive capture boundaries, this is one whole field:

| Requested recorded fields | VBlank advance |
| ---: | ---: |
| 20 | 21 |
| 10 | 11 |
| 10 | 11 |
| 1 | 2 |
| 1 | 2 |
| 1 | 2 |

The initial interval depends on the starting beam position: an arbitrary mid-field
checkpoint need not produce an extra complete VBlank count. Completed captures followed
by another capture have the reproducible one-field gap. Consecutive binary files are
therefore **not a continuous instruction stream**. Reset reconstructed call stacks at
each join and exclude incomplete calls from per-call cost comparisons.

Local tools now mark joins explicitly. Cycle captures default to a single window of at
most 100 fields. Longer frame-rate and event runs use the ring and swap breakpoints rather
than joining instruction captures. No game-time implementation or sound change is included.

## Deterministic mouse input

Disabling emulator joystick/mouse input did not neutralize the hardware mouse counters.
Two fresh boots initially produced identical screenshots but different instruction and
DMA data. The first differing instruction was the mouse-counter read at `sim:2d354`;
its returned value changed the interrupt's mouse deltas.

VERIFY therefore replaces that complete six-byte read with `move.w #0,d1` and a NOP.
It applies only to sim v1 and preserves the destination width and condition-code effects
of the original read. With this change the two 100-field captures matched exactly,
without filtering differing records. Normal and DEVELOPER builds retain the original
mouse read. This is a test-input control, not a rendering optimization.

## Shipped/rebuilt opening comparison

The unmodified rebuilt slave and shipped 2.1 slave both reach the main menu without
the keyboard tape. Each run starts from reset with a read-only breakpoint armed at
`ps:15b3a`, advances to its 1001st crossing, then records 100 PAL fields.

The visible 640×400 menu pixels match exactly. All 40,000 bytes fetched by bitplane
DMA in the last two fields also match. Raw screenshots differ outside the game image,
so their file hashes alone are not an equivalence test.

The post-capture chip dumps differ in 2,011 bytes: 647 in the low-memory page (including
exception vectors that point into the differently assembled slave/KickEmu), 31 outside
the displayed bitplanes, and 1,333 in a separate region with sample-like contents. None
of these bytes were fetched by bitplane DMA in the final two fields. The latter two
regions still need definitive ownership/phase classification before closing W0.1.
This is a matching visible opening checkpoint, not a claim of full chip-RAM equality.

## Swap beam positions

The local `frames.py` now matches the actual 24 CPU word writes of the original
`movem.l d2-d7/a1-a6,(a0)` at `sim:3154a` against DMA addresses and data. It reports
first/last write beam slots; incomplete matches stay explicit. Summed instruction
cycles are no longer presented as exact beam positions. At the initial event checkpoint
of the reproducible 100-field capture, its one publication begins at line 14, horizontal
slot 139 and ends at slot 185 of the same line. This single publication is insufficient
to establish tear-free behaviour.

## Option and hook-check framework

All builds now declare WHDLoad interface 17 and a splash configuration. Release builds
show one Faster rendering switch; developer and VERIFY builds expose the individual
CUSTOM2 bits from the plan. The verified release mask is currently zero: this framework
installs no optimization. The default-on/off and icon policy remain user decisions.

`resload_Control` reads CUSTOM2 and CPU attention flags before loading the game, and
CUSTOM5 in VERIFY. The sim v1 version branch alone calls the performance installer.
The original v2/v3 patch lists are unchanged. VERIFY flight entry on the 68020 confirms
CUSTOM2=513, CUSTOM5=7, the matching developer mask, and the expected CPU flags.
Normal and developer outputs contain neither the tape nor step-ring marker.

`perf_check_bytes` provides the fail-message check for non-relocated hook bytes; each
future installer must invoke it before writing its range. Relocated operands require
checks computed from live hunk bases. The installer currently has no ranges.

The versioned tools alongside these docs provide:

- `check_disabled.py`: apply original HUNK_RELOC32 records using the live BPTR chain,
  then compare each declared PERF_RANGE with the corresponding memory dump.
- `audit_hooks.py`: check whole-instruction boundaries, direct incoming branches and
  relocation targets inside ranges. Indirect callers still require manual review.
- `test_checks.py`: synthetic acceptance and rejection cases without game data.

Both audit commands report PENDING when no performance ranges exist; an empty audit
is not counted as a pass. The parser has also read the original four-hunk sim fixture,
including all 8,686 code relocations and 541 data-hunk relocations. No game bytes are
embedded in the tools. The CUSTOM5 consumers and twin infrastructure remain unfinished.

## Slowed-drawing and state comparison

CUSTOM5 bit 0 is now a VERIFY-only slowed-drawing probe, installed at the first true
flight step. The hook is the complete JMP at `sim:015b2`, which serves the 3D call
at `sim:007b8`; the four-byte JSR at that call site cannot itself hold a six-byte hook.
The original opcode and relocated destination are checked before installation. Static
boundary/branch/relocation audit passed for the stub. The original renderer receives
its unchanged stack arguments through a tail call.

The off/on runs use the same retained binary, both reach flight, and stay clamped at
dt=450 through step 20. Entry h3 state matches exactly; step 20 differs only in the
elapsed argument and one CIA timer timestamp. See `game-time.md` for the explicit
values and limitations. Normal builds still exclude this probe.

`compare_h3.py` compares the full h3 allocation and separately reports candidate
relocated pointers into sim or h3. It never labels a normalized comparison as strict
byte equality. Seven synthetic checker tests now cover changed data, relocated pointer
candidates, invalid snapshot sizes, hook boundaries and incoming references.

The 68030 mission reached debriefing at flight step 314. The first 200-swap segment
contains only 745 PAL fields and is too short for the required long-window rate.
The interrupted subsequent segment includes UI swaps and is marked incomplete. The
local swap harness now arms an additional read-only breakpoint at `sim:21f4a`, the
flight-loop exit, and rejects a capture that did not reach its requested flight step.
That automatic exit stop still needs a fresh end-to-end mission run.

## Explicit straight and bank fixtures

Banking is now opt-in: CUSTOM5 bit 1 holds Right at steps 20–34 and releases it at
35. The local `reach_flight.py --bank` sets that bit while preserving other CUSTOM5
bits. The default fixture keeps Right released. This separates R-bank from the
long steady-flight setup; older captures explicitly described as mixed still include
the old unconditional bank. Both current routes reach their requested checkpoints.

The straight 50 MHz 68030 fixture subsequently completed a clean 800-swap window
over 2,613 fields. An earlier short segment was rejected after a debugger transport
error (`Invalid hex digit`), rather than treated as mission completion. The valid
window is separate and starts at the following flight-step checkpoint.

## Original-code and mirror-model references

VERIFY now copies the relocated original bodies at `sim:304d0` (162 bytes),
`sim:38c82` (330 bytes) and `sim:39df2` (218 bytes) before the performance installer
can modify them. No game bytes are embedded in source. All three live copies were
checked byte-for-byte against the original loaded bodies. Static examination found
no PC-relative reference outside each copied range; absolute data and callback
references continue to use the game context. Future twins must still isolate their
output buffers and callback state. The copies alone are not completed twins.

`mirror_model.py` has independent bit-loop and byte-table paths. Host tests cover
all 65,536 words with both initial low-bit states of the LSR/ROXL accumulator, and
4/5-plane bitmaps at width/height boundaries including nonzero padding bits. Masks
are regenerated as OR(planes) with a zero extra word on each row.

One complete live original call was stopped at entry and immediately before RTS: a
168×102 five-plane dashboard matched both the bitmap and mask model exactly. All
general registers and SP matched their entry values. SR changes in the original,
so it is recorded separately rather than incorrectly required to be preserved.
This validates the model against an original call; replacement assembly and live
replacement twins remain future gates.
