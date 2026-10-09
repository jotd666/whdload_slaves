# W1 dashboard mirror implementation and evidence

W1 is in progress. W1a is implemented behind developer/VERIFY CUSTOM2 bit 0;
W1b is implemented behind bit 1. The release verified mask remains zero. Completion
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

## W1b contract and initial checks

The cache hook covers the six whole-instruction bytes at `sim:30412` and leaves
the alternate entry at `sim:3040a` intact. The set-free hook covers the complete
eight-byte prefix at `sim:303c6`, reconstructs that prefix and continues at
`sim:303ce`. All three W1 ranges pass the static instruction/branch/relocation
audit. Only sim v1 can install them.

One cache entry is keyed by the real descriptor, its plane/mask pointers,
width/height, plane size and current depth. Only nonvertical horizontal changes
with known orientation flags are eligible. Dimensions must be in the W1a domain,
plane size must equal rounded stride times height, and plane data must occupy at
least 4,096 bytes. Small UI images and unsupported descriptors take the original
path. A failed chip allocation also takes that path, using W1a only if bit 0 is on.

The entry allocates planes plus mask with MEMF_CHIP. It mirrors a copy, preserves
the game's planes/orientation and normalizes the game mask to OR(planes), matching
the original's first-mirror side effect. Every draw uses an 18-byte temporary
descriptor and the original clipped cookie-cut renderer at `sim:30572`, including
its output registers. A vertical request or any bitmap-set free drops the single
entry conservatively. Eviction/free waits for the blitter before releasing storage.

The initial live cache at step 20 is the 168×102 five-plane dashboard, occupying
**13,668 chip bytes**. Its planes and mask match the independent Python model,
the game mask equals OR(game planes), and the game descriptor remains orientation
zero. Evidence: `w1b-first-entry/cache-model.json`. This is correctness evidence,
not a timing comparison.

CUSTOM5 bit 6 adds a copied-original build twin and a pixel twin on every cached
draw. The pixel twin copies the current framebuffer, copies the original game
bitmap into chip RAM, executes the original orientation/draw path into the shadow
framebuffer, then executes the cached path into the real framebuffer. After both
blits finish it compares every framebuffer byte, checks the real descriptor and
allocation guards, and frees the temporary allocation.

Framebuffer bytes are never normalized. Two address-bearing output registers
require the original renderer's documented adjustment: `sim:3073c` loads the
framebuffer base into d0, while `sim:30792` replaces only its low word with the
plane count. At completed return, d0 retains the base's high word and a zero low
word. The final d1 address differs by the shadow/real buffer-base delta. Rejected
blits instead retain matching arguments. The twin accepts only these explicit
forms. The initial unadjusted diagnostic did not reach flight and is rejected;
it is not counted as a pixel pass.

The corrected `w1b-pixel-twin-fixed` run passed **one build twin and 57 exact
pixel twins through step 20** with CUSTOM2=3. `w1b-independent-entry` repeats
those counts with CUSTOM2=2: W1a is disabled and its six original hook bytes are
unchanged. Both use VERIFY SHA-256
`b7d9f7c7972ec2626f59a1f0683c855688adae845cdabc01dbfe4e82962c500b`.
Counts include pre-flight/UI rendering, not just the event-window calls.

CUSTOM5 bit 7 bypasses allocation through its failure branch. It is a VERIFY-only
fallback probe, not a player setting. Both `w1b-failalloc-fast` (CUSTOM2=3) and
`w1b-failalloc-original` (CUSTOM2=2) reach step 20 in flight with null cache storage
and zero cache build/draw counters. They exercise the shared failure return with
the fast and original mirror fallbacks respectively. Keep bits 5–7 off for
performance captures.
`check_disabled.py --custom2 MASK` checks only ranges whose developer bits are off,
so independent-option runs can verify the unselected hook as well as all-off runs.

## Remaining W1 gates

- Finish off/on measurements across the required windows and all three CPUs,
  including event census, frame rate, complete routine costs and state checks.
- Exercise freeing/reloading, vertical invalidation, repeated key changes and
  repeated cache reuse, retaining counters/state evidence. Both forced allocation
  failure choices already reach flight step 20; actual low-memory runs remain part
  of the A500-equivalent matrix.
- Extend cache-build/pixel twins through the required scenes and full event census;
  the initial step-20 checks do not establish coverage of every clipping case.
- Repeat hook/off-path checks for the final build, build all modes and promote
  only fully verified and measured bits to the single player switch.
