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
All three modes build successfully, and 33 host tests pass. The initial paired
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

## Lifecycle probe and first measurement build

CUSTOM5 bit 8 runs a one-shot lifecycle probe after the first successful cache
lookup. Private allocations form a minimal valid bitmap set; the probe enters
the game's patched `sim:303c6` and checks that the cache and set-table slot clear.
It then rebuilds the real entry, replaces its descriptor key with a private clone,
and switches back. A small private bitmap enters `sim:30408` with a vertical
request, completely outside a temporarily bounded clip rectangle. This confirms
vertical invalidation through the real draw path without changing framebuffer
pixels. The original clip state is restored, private allocations are freed and
the real cache is rebuilt. A completion counter is written only after all checks.

`w1-final-twins` combines CUSTOM2=3 with CUSTOM5=352 (bits 5, 6 and 8). It reaches
flight exit at step 371 with **65,536 word checks, 64 synthetic mirror twins,
720 live mirror twins, five cache-build twins, 63 exact pixel twins and one
completed lifecycle probe**. These include pre-flight/UI work. The detailed
census begins at step 20 and reaches the actual flight exit with every subsequent
step retained; its counts include reference execution and are not performance
measurements or a full-flight main-path event census.

The first measurement build used VERIFY SHA-256
`158247428d5de8b4bbe907bae3760a2c6c0e65ad7f3fcb37d8fc87b16883ba03`.
Both installers explicitly flush instruction/data caches after initializing their
runtime continuation stubs and applying patches. Keep bits 5–8 off for timing.
Further code changes require reconsidering the retained same-build comparisons.

## Identical setup for controlled flight measurements

The initial A500 pair (`w1-matrix-a500-0` and `w1-matrix-a500-1`) differs
in 1,490 h3 bytes at step 8 even though both recorded flight histories have
clamped dt=450. Fresh captures taken before the first flight checkpoint resumes
(`w1-entry-control-fixed-0` and `w1-entry-control-fixed-1`) already differ
in 3,039 bytes. The patches affect pre-flight/UI timing, so these runs do not
establish equivalent starting states. They remain exploratory captures, separate
from the controlled measurement matrix. This does not supersede the copied-original
mirror and framebuffer twins.

VERIFY CUSTOM5 bit 9 (512) defers installation until the first recorded flight
checkpoint. All CUSTOM2 settings execute the same original pre-flight path and
the same word self-test. The checkpoint precedes activation; the next input call
runs with the selected patches installed. Activation preserves registers, checks
the hook bytes and flushes caches through the existing installers. Its pending
sim pointer can only be armed by the supported v1 loader. Normal and DEVELOPER
builds retain installation at load time.

Use this bit consistently across the controlled OFF/ON matrix. It is a measurement
fixture, not a game-time change. The one-time installation cost belongs to the
opening interval and must not be attributed to a completed mirror call. The new
VERIFY image supersedes the first frozen build for same-build comparisons;
OFF/W1a/W1a+W1b entry and step-8 h3 snapshots now match all 48,396 bytes exactly, with no
normalization or exclusions. Every recorded dt remains 450. All three OFF hook
ranges retain their original relocated bytes. Evidence is `w1-deferred-entry-{0,1,3}`
and `w1-deferred-step-control-0`. The new VERIFY text is 34,332 bytes, SHA-256
`99c490efbde1b312d42c77ffeb3b7d348cacb6364b402fa9d15803765485d313`.
The W1b run has an active 13,668-byte dashboard cache at step 8, confirming activation.
The complete performance matrix remains in progress.

## Completed controlled A500 and 68020 primary cases

The OFF, W1a and W1a+W1b primary cases are complete on both machines, using
VERIFY SHA-256 `99c490efbde1b312d42c77ffeb3b7d348cacb6364b402fa9d15803765485d313`.
All six boot configurations and binaries are retained. Each case includes an
opening event trace, a step-8 steady trace, equal-step h3 snapshots and a separate
fresh-boot census beginning at the exact flight checkpoint. The census has no
initial screenshot gap and reaches the guarded flight exit with every step retained.

All three A500 step-8 snapshots match exactly. All three 68020 entry snapshots
match exactly; OFF and cache-on still match at step 8. The 68020 later enters
different dt histories: at steps 17–20 OFF has dt=450, while cache-on has 341.
Its step-20 h3 snapshots differ in 733 bytes. This is not a clamped equal-state
comparison, and those differences are not substituted for twin correctness checks.

The OFF retained snapshots pass all three disabled-range checks on both machines;
W1a-only snapshots pass both cache-hook checks. All primary event/steady DMA chunks
on these two machines have observable blitter writes and zero active-display
write conflicts. These window-scoped findings do not make a universal tear-free
claim. Current costs, rates and the lower observed 68020 cache-on steady rate are
recorded in `profiling.md`.

## Fallback invalidation regression and correction

Review found that unsupported orientation bits and failed cache eligibility tests
could continue through the original mirror path while retaining a cache entry.
That path can mutate the game bitmap, so a later eligible draw must not reuse the
old mirrored copy. Both exits now use the existing conservative invalidation path.
Only a nonvertical, same-orientation fallback can retain the entry.

The lifecycle fixture accepts assembler-only `VERIFY_CACHE_PROBE_FLAGS` and
`VERIFY_CACHE_PROBE_RESULT` constants. Defaults are 1/1 (the existing vertical
probe) and emit exactly the same bytes. A 6/2 build sends an unsupported request
through the actual draw hook; a 2/2 build exercises the small-bitmap eligibility
failure. Private bitmap storage and clipping keep these probes off the visible
framebuffer. The verifier requires invalidation before rebuilding the real entry.

`w1-fallback-extra-before` reproduces the old failure, stopping before Abort with
an allocated cache, four completed build twins and no lifecycle completion.
After correction, `w1-fallback-extra-after` and `w1-fallback-small-after` both
reach step 2 with five build twins, one pixel twin and a completed lifecycle
probe. The unsupported-flags run also retains 65,536 word checks, 64 synthetic
mirror twins and seven live mirror twins on A500-equivalent memory.

The corrected default VERIFY SHA-256 is
`5c0918ccbccb27ad301478873e1aeab8398f057211b2749ce7d16fe949f23475`.
Its size and layout are unchanged: only two conditional-branch displacement bytes
differ from the primary measurement build. The retained A500 cache-on traces
observe the unsupported-flags branch 110 times and the failed-lookup branch once;
the 68020 counts are 123 and one. Neither branch is taken. This audit uses the
preceding AND/TST data operands because UAE's stored SR can contain stale lazy
condition flags. There is no instruction-level audit claim for the cached 68030.
Keep the primary measurements attributed to their retained build; remaining scene
and whole-call timing runs use the corrected image.

All 33 host checks and the three-range hook audit pass after correction. Normal
and developer text sizes remain 7,198 and 7,370 bytes.

## Corrected-build scene twins on all three machines

All six native bank/dense routes reach gameplay step 40 in flight with the
corrected default VERIFY image. Each boot passes all 65,536 word checks,
64 synthetic mirror cases and the complete lifecycle probe. Counts below include
reference execution; they are correctness coverage, not event/performance counts.

| Machine | Scene | Live mirror twins | Cache-build twins | Pixel twins |
| --- | --- | ---: | ---: | ---: |
| a500 | bank | 6 | 5 | 1 |
| a500 | dense | 6 | 5 | 1 |
| 020 | bank | 14 | 5 | 9 |
| 020 | dense | 11 | 5 | 1 |
| 030 | bank | 6 | 5 | 1 |
| 030 | dense | 6 | 5 | 1 |

Evidence is `w1-scene-twins-{a500,020,030}-{bank,dense}`. The A500 runs use
512 KB chip and 1.5 MB slow RAM with no fast RAM. The bank and rear-view screenshots
were retained; the A500 shots were visually checked. The 68020 dense run has
invalidated the cache by step 40 while still completing all checks.

The cached 68030 runs additionally enable the optional first-fill diagnostic,
only for correctness/cache-policy verification. Both read actual CACR `0x2111`,
with instruction/data cache policy enabled, MMU requested and emulator data-cache
modeling enabled. Each retains 38 first-fill records with no missed publication;
14 bank and four dense records flag potentially active old-display fills. These
instrumented records are not performance measurements or proof of visible tearing.
The diagnostic stays off in timing runs.

## Cached-CPU selection and timing validation

Read-only whole-call clocks show the cached 68030 table mirror taking 23.157 ms
against 17.486 ms for the original. The normal player selection therefore clears
bit 0 on 68030/040/060, retaining the original in-place path. The 040/060 are
conservative exclusions, not measured results. Bit 1 remains independently
selectable and builds its private copy with the table routine. Developer and
VERIFY builds retain explicit masks without this policy filter.

All 35 host tests pass, including conservative rejection of ambiguous horizontal
counter-boundary samples. All three modes compile: normal text 7,214 bytes,
developer 7,370 and VERIFY 34,332. The normal-only selection change leaves the
corrected VERIFY image byte-for-byte unchanged. The release verified mask is
still zero pending final scene/cached-CPU gates. Costs and exclusions are in
`profiling.md`.

## Remaining W1 gates

- Finish off/on measurements across the required windows and all three CPUs,
  including event census, frame rate, complete routine costs and state checks.
- Check the frozen build on A500-equivalent memory and cached CPUs, with the
  documented cache policy; the forced-failure and lifecycle probes have passed
  on the continuity machine.
- Extend cache-build/pixel twins through the required scenes and full event census;
  the initial step-20 checks do not establish coverage of every clipping case.
- Repeat hook/off-path checks for the final build, build all modes and promote
  only fully verified and measured bits to the single player switch.
