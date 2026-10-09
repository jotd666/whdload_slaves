# W1 dashboard mirror implementation and evidence

W1 is in progress. W1a is implemented behind developer/VERIFY CUSTOM2 bit 0;
W1b is not implemented yet. The release verified mask remains zero. Completion
requires the full measurement matrix and the cache-specific checks below.

## W1a contract

The six-byte hook at `sim:304d0` replaces two whole instructions. The sole
identified original caller is `sim:30420`; its `sim:30424` EORI replaces NZVC,
and X is dead before use. The replacement preserves d0–a6 and returns through
the existing caller. It uses 44 stack bytes, a private 40-byte row scratch area
and a generated 256-byte reversal table. Bitmap code is main-thread-only.

The entry performs the required double blitter-busy read/wait before clearing
any mask storage. Each rounded-width row is reversed bytewise through the table,
then copied back in reversed order and ORed into the mask. Extra mask words
remain zero. Nonzero padding bits are retained and reversed, matching the
original. Plane-size metadata is not used for traversal, just as in the original.
Widths 1–320, heights 1–200 and depths 4/5 use this path; other dimensions execute
the original prefix and continue at `sim:304d6`.

Before implementation, the loop cost was bounded at approximately 104 cycles
per word (two byte lookups, copy/OR and both DBF loops), plus row/plane setup,
mask clearing and the entry wait. For the 5,610 dashboard words this places the
CPU work around 0.6–0.7M cycles before interrupts and bus contention, compared
with the measured original's 1.85M. This is a design estimate, not a performance
result or a substitute for the three-machine measurements.

The installer checks all original hook bytes and runs only for sim v1. The
hook audit reports one complete range and no incoming branch/relocation into
its interior. CUSTOM2=0 retains the original relocated bytes in that range.
Normal and DEVELOPER builds omit the mirror verification marker and code.
All three modes build successfully, and 31 host tests pass. The initial paired
complete-call measurements are recorded in `profiling.md`; the matrix is pending.

## Correctness checks

The Python bit-loop and table models retain the W0 checks against the original.
The VERIFY installer executes all 65,536 word inputs on the emulated CPU,
comparing the table result with sixteen original LSR/ROXL pairs.

CUSTOM5 bit 5 enables copied-input twins. The original runs on an independently
allocated descriptor/planes/mask copy; the candidate runs on the real input.
Each call compares all planes, regenerated mask, descriptor fields and d0–a6.
The register snapshots and return path also depend on restored SP. Guard words
around the reference allocation detect out-of-bounds writes. Flags are dead at
the original caller and are not incorrectly required to match.

The same bit runs 64 deterministic synthetic CPU twins at install time, with
boundary and randomized widths/heights, four/five planes, arbitrary padding
bits and initially unrelated masks. These add guards around the candidate's
allocation too. They temporarily select the reference plane count and restore
it before returning to the loader. Both temporary allocations are freed.

The retained `w1a-synthetic-entry` run completed **65,536 word checks, 64 synthetic
twins and 758 live twins** through the maximum-detail first-flight checkpoint.
The preceding live-twin build also reached step 20 with 764 completed twins;
those counts include menu/UI callers, not just cockpit events. Evidence is
ignored locally. `tools/mirror_checks.py` reads the completed check record from
a retained RAM dump and rejects missing, partial or ambiguous records.

Diagnostics intentionally allocate memory and execute the original as well as
the replacement. Keep CUSTOM5 bit 5 off in all timing captures. The exhaustive
word test is outside flight timing. These tests establish correctness evidence;
A/B images or faster frame counts are not treated as correctness proofs.

## Remaining W1 gates

- Finish W1a off/on measurements across the required windows and all three CPUs,
  including event census, frame rate, complete routine costs and state checks.
- Implement W1b chip-cache allocation, key checks, descriptor substitution,
  game-mask normalization, vertical/set-free invalidation and allocation fallback.
- Compare each cache build with the original mirror and each cached draw with a
  shadow-framebuffer original-path draw, including clipping and descriptor state.
- Test allocation failure, freeing/reloading and both independent CUSTOM bits.
- Repeat hook/off-path checks for every added range, build all modes and promote
  only fully verified and measured bits to the single player switch.
