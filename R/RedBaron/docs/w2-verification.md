# W2 geometry implementation

G1 core, G2, G3 32-bit misses and G4 are implemented in developer/VERIFY builds.
Combined CPU results and explicit low-value deferrals appear after the individual
implementation records below. The cached-CPU per-routine check rejects G1 there; verification of the
remaining G2/G3/G4 bundle now passes its combined check. Sound, game-time rules and deferred W1 work are unchanged; player
enablement remains a separate gate.

## G1 projection core

Developer/VERIFY CUSTOM2 bit 2 replaces `sim:38c82` for sim v1 only. The six-byte
hook covers the original MOVEM and first MOVE instruction; four current performance
ranges pass the static branch/relocation audit. Disabled bits leave original bytes.

The candidate retains the original magnitude normalization, unsigned word multiply
and divide, 32-bit overflow, shifts modulo 64, and complete d0/d1/a0/a1 results.
All other registers are preserved. A zero denominator replays the overwritten
prefix and continues in the original body, retaining its DIVU trap at the original
instruction. Zero numerators skip their own multiply/divide; a zero scale returns
zero results only after the denominator check. The common scale 128 uses its exact
normalized value and exponent directly. Other scales use the general normalizer.

Normalization is inline, with direct zero/short-shift cases and a 256-byte bit-length
table for the rest. A saved address register holds the shared table pointer until
the last normalization finishes. This avoids the 68000's short displacement limit
for indexed PC-relative addressing. The implementation has no per-call allocation.
The surrounding projection wrapper has not yet been folded into this core.

## Correctness evidence

`projection_model.py` retains the original loop, independent bit-length, byte-table
and current inline models. They match the saved 486 original calls. The host suite
checks bit-length/sign boundaries and 200,000 deterministic random magnitudes at
both widths. `check_projection_norm.c` enumerates every 32-bit magnitude at widths
15 and 16 against the original one-bit loops; its output is retained with the local
evidence. Assembly equivalence additionally depends on the CPU tests below.

VERIFY CUSTOM5 bit 10 enables the projection twin. It executes the copied original
and candidate from the same inputs, compares every d0–a6 register, and explicitly
checks restored SP. The reference was copied before patch installation and contains
no embedded game bytes in the repository. The routine's flags are dead at the
identified projection callers; they are not incorrectly required to match.

The installer runs 451 deterministic synthetic register cases: zeros, signed extrema,
each bit length and random full-width inputs. Zero-denominator behavior is covered
by the retained original continuation and the host trap model rather than deliberately
aborting the synthetic boot. Live twins then run on every projection call.

Both initial and revised A500-equivalent runs reach flight step 40 through the
native banking fixture: 451 synthetic and **8,569 live comparisons**, no mismatch.
The configuration is 512 KB chip plus 1.5 MB slow RAM, no fast RAM. Evidence is
`w2-g1-twins-a500` and `w2-g1-twins-a500-r2`. Timing boots disable the twin bit and
use the existing deferred-activation fixture to keep pre-flight setup identical.

## Measurement discipline

The initial helper-based candidate passed correctness but was rejected as an
optimization: the steady 3D pass averaged 2,446,680.5 main cycles OFF and
2,447,223.5 ON. Mean projection costs were 1,595.1 and 1,603.6 cycles respectively.
Banking alone showed a small change, insufficient to justify it. The first version
is retained only as evidence, not reported as a performance improvement.

The revised inline normalizer gives the following same-build A500-equivalent
complete-call main-cycle results (interrupts excluded):

| Window | Routine | OFF calls / mean | ON calls / mean |
| --- | --- | ---: | ---: |
| R-steady | projection | 1,270 / 1,595.1 | 1,282 / 1,435.8 |
| R-steady | complete 3D pass | 4 / 2,446,680.5 | 4 / 2,416,049.5 |
| R-bank | projection | 740 / 1,619.5 | 750 / 1,428.8 |
| R-bank | complete 3D pass | 3 / 2,310,012.0 | 3 / 2,269,088.0 |

These are 150 steady fields (separate 100/50 chunks) and 100 bank fields per
setting, with cut calls discarded. Projection averages fall 10.0% and 11.8%;
the complete 3D passes fall 1.25% and 1.77%. Call mixes differ at trace boundaries;
these modest scene-specific results are not an FPS claim or the full G1 target.
The step-8 complete h3 snapshots match byte-for-byte. All four disabled hook
ranges retain their original relocated bytes. All three build modes compile.

Evidence: `w2-g1-a500-{0,4}-r2`; VERIFY SHA-256:
`ebc937fe62b542a370ee12520a7099fe7d4cdc2a57da12b8d076db4b734e4d26`.
Wider CPU checks and projection-wrapper integration remain open. The normal
player mask remains zero. This is a verified development checkpoint, not release
promotion; further W2 work targets the larger geometry costs.

## G4 back-face dot product

Developer/VERIFY CUSTOM2 bit 5 replaces `sim:3b1fa`. Each signed word/long
product is computed with two unsigned word multiplies and a conditional low-long
negation. All sums wrap modulo 2³², just as the low long returned by the original
three 64-bit products. In particular, the result's sign is the low-long sign;
no full-width sign test or saturation is introduced.

The sole direct caller is `sim:38f9c` in the callback `sim:38eec`, installed by
`sim:3a456` in `h3:0a41e`. Its caller at `sim:3b46c` immediately tests d0 and then
overwrites scratch registers before use. d1/a0/a1 and return flags are dead;
d2–d7/a2–a6 and SP must be preserved. The hook covers whole LINK/MOVEM instructions
and has no incoming branch or relocation into its interior. It applies only to v1.

`dot_model.py` checks an independent signed sum against the candidate's split-word
arithmetic. Both match 421 complete original calls. Ten million deterministic
random dot products and 552 boundary/synthetic cases pass, including negative
normal components and the signed long minimum. VERIFY CUSTOM5 bit 11 runs the
relocated original and candidate, comparing d0, every preserved register and SP.
The original's absolute multiply calls remain unmodified. The A500-equivalent
flight reaches step 40 with 552 synthetic plus 1,896 live comparisons and no
mismatch. Synthetic tables live after observer code to keep PC-relative accesses
within the 68000's displacement range; they are absent from normal/developer builds.

Same-build A500-equivalent timing (150 steady fields, 100 bank fields):

| Window | Routine | OFF calls / mean main cycles | ON calls / mean main cycles |
| --- | --- | ---: | ---: |
| R-steady | dot product | 298 / 1,861.1 | 313 / 718.4 |
| R-steady | complete 3D pass | 4 / 2,446,701.5 | 4 / 2,378,798.5 |
| R-bank | dot product | 123 / 1,842.8 | 123 / 692.2 |
| R-bank | complete 3D pass | 3 / 2,308,462.0 | 3 / 2,254,382.0 |

The complete 3D-pass reductions are 2.78% and 2.34%; these short samples do not
establish an FPS improvement. Step-8 h3 snapshots differ only in timer timestamps
at `h3:03f5a` and `h3:03f60`, and elapsed time at `h3:0483a`. Both remain dt-clamped;
all other bytes match. The timestamps/elapsed input are expected to change when
rendering takes less wall time; this comparison is not used as the arithmetic proof.
All five disabled hook ranges retain original bytes. All three build modes compile;
37 host tests pass. Wider CPU checks remain open; the normal release mask stays zero.

Evidence: `w2-g4-twins-a500`, `w2-g4-a500-{0,32}`. VERIFY SHA-256:
`aa34be83f91045a8fbf3394459eff1a74cced3a1a1e1a69f8df9cf4644bdf73d`.

## G2 trivial screen clipping

Developer/VERIFY CUSTOM2 bit 3 replaces `sim:39ecc`. Empty inputs (n ≤ 1),
polygons uniformly outside one X boundary, and polygons uniformly inside X with
uniform Y codes use direct paths. Mixed cases and counts beyond the 20-entry
buffers use the unchanged original body. The inherited-high-word upper-bound
comparison is retained, including unusual signed bounds.

An all-inside polygon still populates both temporary arrays. A Y rejection after
an inside X pass retains those temporary coordinates/count and clears only the
source count. Empty/X-rejected polygons leave array storage untouched. Every path
leaves `sim:39d4c` holding the Y bounds. The sole caller at `sim:3b55e` immediately
calls `sim:3b398`, which replaces the scratch registers before their next use;
d0/d1/a0/a1 and flags are dead. All d2–d7/a2–a6 and SP are preserved.

`clip_model.py` compares an edge-walking reference with uniform-outcode predicates.
It matches 1,888 original pass classifications and 100,000 random polygons of
0–8 vertices around arbitrary signed bounds. Mixed-edge interpolation is delegated
to the original in both the patch and model, not replaced by an approximate formula.
VERIFY CUSTOM5 bit 12 compares the entire 324-byte source/temporary allocation,
working bounds, preserved registers and SP after original and candidate runs.
The reference wrapper is copied before patching and retains its original core calls.

The A500 test reaches step 40 with **105 synthetic and 4,187 live comparisons**,
no mismatch. Synthetic constant polygons cover counts 0/1/2/8/20, inside and both
outside boundaries on each axis, negative/cross-sign bounds, and signed extrema.
Live calls cover mixed-edge fallback. Synthetic case tables now follow observer
code and use position-independent long offsets; they remain VERIFY-only.

| Window | Routine | OFF calls / mean main cycles | ON calls / mean main cycles |
| --- | --- | ---: | ---: |
| R-steady | clipping | 585 / 1,942.3 | 589 / 1,570.3 |
| R-steady | complete 3D pass | 4 / 2,446,701.5 | 4 / 2,401,021.5 |
| R-bank | clipping | 358 / 2,418.1 | 369 / 2,108.2 |
| R-bank | complete 3D pass | 3 / 2,308,462.0 | 3 / 2,266,218.0 |

These same-build 150/100-field samples reduce whole-pass costs by 1.87%/1.83%.
The timing analyzer recognizes **both** the candidate RTS and original fallback
RTS; it does not omit the slower mixed cases. All costs exclude interrupts and
cut calls. Step-8 h3 differs only in `h3:0483a` elapsed time; every other byte
matches. Six disabled ranges retain original bytes, all three builds compile,
and 41 host checks pass. G7's earlier all-behind rejection is not implemented yet.
Wider CPU checks and player promotion remain open; the release mask stays zero.

Evidence: `w2-g2-twins-a500`, `w2-g2-a500-{0,8}`. VERIFY SHA-256:
`c096035c12917791a2444ce3b63b40597337b67d2e2f1af952479cf58e0e67fc`.

## G3 vertex cache-miss transform

Developer/VERIFY CUSTOM2 bit 4 targets the miss at `sim:38e02`, fusing the
32-bit wrapper's `sim:3afbe` transform and object translation. The original cache
hit at `sim:38dcc` remains untouched. A single MOVEM.W loads the signed vector;
the shift count is computed once, and a zero-z path omits three products. Results
still use signed word multiplies, low-long addition before ASR, and shift counts
modulo 64. Matrix types 0 and 1 retain their special behavior. The original source
scratch, transformed scratch, cached coordinates and flag are all written.
The separate 16-bit path is not changed.

The Python reference and candidate models match 2,014 complete original type-2
transforms. Inputs are recovered from observed matrix operands and products; an
all-zero matrix column's unobservable coordinate is represented as zero. No
inference is made about type 0/1 coverage in that trace. The 200,000 random host
cases and CPU synthetic cases cover all matrix types and arbitrary word shift
counts, including signed overflow and the zero-coordinate paths.

VERIFY CUSTOM5 bit 13 compares the relocated original wrapper and fused path,
restoring the selected vertex state between them. It compares the flag, both
scratch areas, all three cached results, d2–d7/a2–a6 and SP. d0/d1/a0/a1 are scratch
at the wrapper's callers; the face loop's next operations read the vertex flag
and overwrite its condition codes. The synthetic cases cover indices 0/127/254,
208 combinations of matrices, source vectors, type and scale, and translations
that exercise long overflow. On A500, 208 synthetic plus 8,729 live comparisons
through step 40 pass.

| Window | Routine | OFF calls / mean main cycles | ON calls / mean main cycles |
| --- | --- | ---: | ---: |
| R-steady | vertex wrapper (hits included) | 1,955 / 1,109.2 | 2,025 / 936.4 |
| R-steady | complete 3D pass | 4 / 2,446,701.5 | 4 / 2,382,304.5 |
| R-bank | vertex wrapper (hits included) | 1,068 / 1,226.5 | 1,112 / 998.4 |
| R-bank | complete 3D pass | 3 / 2,308,462.0 | 3 / 2,244,320.0 |

These are the same 150/100-field same-build A500 windows, not FPS measurements.
Whole-pass savings are 2.63%/2.78%. Costs include the untouched cache hits and
recognize both hit/miss return paths. Step-8 h3 differs only in elapsed time at
`h3:0483a`. Seven disabled hook ranges retain original bytes, all three build
modes compile and 44 host checks pass. The main implementation adds no allocation;
its miss path saves 32 bytes of registers. Wider CPU/combined checks remain open.

Evidence: `w2-g3-twins-a500`, `w2-g3-a500-{0,16}`. VERIFY SHA-256:
`1456f8d5b84cf787f3429b7ae6580fcc88ce94903d604bbb3d339610f85853b3`.

## Combined W2 checks on three CPUs

The current frozen VERIFY build enables G1 core, G2, G3 32-bit misses and G4
with CUSTOM2=60. Six independent boots reach step 40 with all four twins active:
A500-equivalent, 14 MHz 68EC020 and cached 50 MHz 68030, each in R-bank and
R-dense. Each boot additionally executes the 451/552/105/208 synthetic cases
for projection/dot/clipping/vertex respectively. All comparisons pass.

| CPU / scene | Live projection | Live dot | Live clipping | Live vertex |
| --- | ---: | ---: | ---: | ---: |
| A500 / bank | 8,569 | 1,896 | 4,187 | 8,729 |
| A500 / dense | 7,038 | 837 | 2,273 | 4,780 |
| 68020 / bank | 8,223 | 1,682 | 4,378 | 8,719 |
| 68020 / dense | 7,026 | 867 | 2,624 | 4,699 |
| 68030 / bank | 8,841 | 1,743 | 4,346 | 9,114 |
| 68030 / dense | 6,801 | 858 | 2,169 | 4,526 |

The 68030 uses MMU and modeled instruction/data caches. Both paint observers
record CACR $2111, with no missed first-draw observations. Their potential
old-display writes are diagnostics, not proof of visible tearing; twin overhead
also makes these unsuitable as performance samples. W5 remains open.
Evidence: `w2-combined-twins-{a500,020,030}-{bank,dense}`.

### Combined A500 timing and state

Separate fresh boots use the same binary, CUSTOM2=0 or 60, CUSTOM5=512 (deferred
activation only), native maximum detail and unchanged Time Scale. No twins or
scripted bank run in these timing windows. At swaps 40–140, 100 intervals take
2,716 fields OFF and 2,563 ON: **1.8380 → 1.9477 FPS (+5.97%)** at 49.92041 Hz.
Both windows exceed 2,000 fields; their dashboard census contains only swaps,
and dt remains clamped at 450 throughout.

Equal-step h3 snapshots at steps 8, 40 and 141 differ only in the timer-start
longword at `h3:03f5a` and elapsed word at `h3:0483a`. Every other byte in the
captured h3 allocation matches. These comparisons support behavioral continuity;
correctness of the replacements comes from the models and twins above.

The separate 150-field cost samples contain four complete 3D passes each:
**2,446,701.5 → 2,236,693.0 main cycles/pass (−8.58%)**. All four routine means
improve; interrupts and calls cut by capture boundaries are excluded. Both short
captures in each setting have observable display ownership and zero detected
active-display conflicts. This is a bounded observation, not a tear-free claim.
All seven disabled ranges retain original relocated bytes with CUSTOM2=0; with
60, the three unselected W1 ranges retain them. Evidence:
`w2-combined-a500-{0,60}`. The rate, state and cost evidence all use SHA-256
`1456f8d5b84cf787f3429b7ae6580fcc88ce94903d604bbb3d339610f85853b3`.

### Combined 68020 timing

The 14 MHz 68EC020 pair uses the same binary and options as the A500 comparison,
with the documented A1200 configuration. Swaps 80–400 span 320 intervals:
2,591 fields OFF and 2,455 ON, or **6.1654 → 6.5069 FPS (+5.54%)**. Both windows
exceed 2,000 fields and contain no dashboard events. Unlike A500, dt varies below
450; equal step numbers do not imply identical world states, so this is an observed
run-rate improvement, not an isolated instruction-speed ratio.

| Routine | OFF mean main cycles | ON mean main cycles |
| --- | ---: | ---: |
| Whole 3D pass (5 complete calls each) | 1,541,652.2 | 1,457,992.4 |
| Projection core | 740.8 | 656.5 |
| Dot product | 965.6 | 377.0 |
| Clipping, including fallback | 1,017.7 | 779.5 |
| Vertex wrapper, including cache hits | 589.2 | 477.0 |

The 40-field cost samples show a 5.43% whole-pass reduction. Both samples have
observable display ownership and no detected active-display conflicts; all
unselected hook ranges retain original bytes. Evidence:
`w2-combined-020-{0,60}`, same frozen SHA-256 as above.

## Remaining candidate assessment

Plan §3.8 explicitly skips changes estimated below 3% of a frame unless free.
The combined-ON A500 capture has four complete main-context frame intervals,
measured from one `sim:2c552` entry to the next, averaging **3,175,654 cycles**.
Thus the current screening threshold is about **95,270 main cycles/frame**.
This is a screening budget, not a claim that a candidate achieves its estimate.
Existing models/twins remain required before any deferred code is implemented.

An instruction histogram restricted to complete 3D passes in the retained
same-build captures gives these remaining routine costs. Self costs exclude
callees; they are ceilings on savings within those instructions, not achievable
speedups. Captures contain four A500 and five 68020 complete passes.

| Remaining area | A500 own cycles/pass | 68020 own cycles/pass | Disposition |
| --- | ---: | ---: | --- |
| G1 wrapper `sim:38e9c` | 59,823.5 | 27,434.4 | Defer folding: even deleting the whole wrapper is below the A500 gate |
| G5 face hub `sim:3b41a` | 223,099.5 | 126,232.2 | Defer proposed register rewrite: plan estimate 70–85k saved, not the entire hub cost; moderate verification risk |
| G6 setup `sim:3b0f6` | 42,069.0 | 21,628.0 | Defer pure inlining; 470.25 A500 calls/pass save only about 16k nominal BSR/RTS cycles, before memory effects |
| G8 LOD `sim:3a518` | 72,814.5 | 38,137.2 | Defer register rewrite |
| G8 object dispatch `sim:3a902` | 65,773.0 | 58,557.8 | Defer register rewrite; combined G8 estimate remains 40–80k, not deletion of both routines |
| G9 flag clear `sim:3a8b4` | 15,425.0 | 11,537.4 | Defer: even deleting the entire routine is below the gate |

G3's unmodified 16-bit cache wrapper appears zero times in the A500 steady
sample and eight times/pass in the 68020 sample. Other callers still use the
16-bit transform (25/20 calls per pass respectively). The plan's ~20k saving
for that extension does not justify a separate replacement/twin lifecycle now.
This is scene-dependent coverage, not a claim that the 16-bit path is unused.

G7 remains unimplemented. The original census found 39 all-behind faces/frame
and about 789 cycles per empty near-plane call; the plan estimated ~35k additional
saving. G2 already makes the later empty screen clip cheaper. Earlier rejection
needs face-loop tracking and preserved scratch side effects, so it is not a free
extra branch. Defer under the same gate.

G1 retains the common k=128 path and exact general normalization. Generalized
power-of-two specializations, wrapper folding, additional register-save tuning
and CPU-specific arithmetic variants are deferred. The cached-68030 breakdown
puts all four measured geometry categories together at only 11.95% of its 3D
pass; drawing is the larger target there.

These are explicit low-value deferrals under the plan, **not claims that G5–G9
or the remaining G1/G3 extensions have been implemented or verified**. Revisit
with a concrete new scene/profile or a larger combined design that clears the
threshold. Evidence: `candidate-budget.json` in the combined-ON A500/68020
captures, plus the original `geometry/out-ilevel-*`, `out-kids.txt`,
`out-392a4.txt` and the disassembly of `sim:3b0f6`.

## Cached 68030 combined result

The same frozen binary completes the OFF/ON window at swaps 120–660. The
original request to reach step 701 ended at mission exit at step 683; that
unfinished request is retained as `w2-combined-030-0`, not counted as completed.
A fresh OFF boot (`w2-combined-030-0-r2`) stops at step 661, and ON
(`w2-combined-030-60`) uses the same endpoint. Both reach it successfully.

| Setting | Fields / intervals | Observed FPS | Dashboard census |
| --- | ---: | ---: | --- |
| OFF | 2,104 / 540 | 12.8123 | 32 message calls, 14 dirty calls, 32 mirrors, 48 rejected draws |
| W2 ON | 2,101 / 540 | 12.8306 | No dashboard events |

**This is not evidence of a steady-flight FPS gain.** Both windows meet the
2,000-field requirement, but their world histories diverge with non-clamped dt.
The OFF endpoint screenshot is the red death-screen transition; ON remains in
flight. The complete census and endpoint images are retained rather than
silently excluding the less favorable history. The repeated OFF window exactly
reproduces the original completed 120–660 census (2,104 fields and the same
listed event counts).

The separate early-flight entry-to-RTS clocks at steps 8–15 contain seven
phase-safe complete 3D passes per setting: **49.4958 → 48.9081 ms/pass (−1.19%)**.
These are inclusive wall times, including interrupts and chip-bus waiting, not
main CPU cycles. This modest local saving is consistent with drawing dominating
on the cached machine. The per-routine check below identifies a G1 regression hidden by this
bundle result; use the CPU-specific disposition below.

The 20-field DMA captures in both settings have observable display ownership
and no detected active-display conflicts. Unselected hook bytes remain original
(seven ranges OFF, three W1 ranges with W2 ON). These short checks are not a
universal tear-free guarantee; W5 remains separate. The binary hash is unchanged
from the combined A500/68020 checks above.

### Cached-CPU per-routine check: retain original G1

Six early-flight iterations per fresh boot (steps 8–13) compare the same frozen
VERIFY binary with CUSTOM2=0 and 60. Return endpoints include the fast and
fallback paths, and only phase-safe whole calls enter the summaries.

| Routine | OFF calls / mean µs | ON calls / mean µs |
| --- | ---: | ---: |
| Projection wrapper | 924 / 7.8100 | 924 / 9.3131 |
| Dot | 243 / 10.4908 | 255 / 2.8039 |
| Screen clip, fallback included | 613 / 9.1894 | 631 / 7.1994 |
| Vertex cache wrapper, hits included | 1,925 / 8.1114 | 1,966 / 6.7108 |

G1 **regresses on this cached 68030**: the projection median also rises from
7.6123 to 9.0220 µs, so the higher mean is not merely an interrupt outlier.
The other three routine medians improve. These are inclusive wall times with
phase exclusions and differing call mixes, not main-cycle measurements.
Evidence: `w2-math-030-{0,60}`.

The normal player selection now removes G1 bit 2 on 68030, and conservatively
on unmeasured 68040/68060, alongside its existing W1a exclusion. The release
mask is still zero; this defines the policy for later promotion rather than
silently enabling the switch. DEVELOPER/VERIFY deliberately retain explicit
bits for reproduction. Use CUSTOM2=56 for the candidate cached-CPU W2 bundle
(G2/G3/G4, original G1); its combined result follows below. A500/68020 retain 60.
The normal build compiles to 9,094 text bytes. The conditional policy change
does not change the frozen VERIFY binary.

### Reduced cached-CPU bundle

CUSTOM2=56 (G2/G3/G4, original projection) completes the same-build cached-68030
check in `w2-combined-030-56`. At the same five phase-safe early-flight steps
9–13, mean 3D-pass wall time is **48.8394 ms**, against **49.7041 ms** OFF and
49.0084 ms with all four bits. The reduced bundle is 1.74% below OFF in this
short sample; it is not a full-frame FPS claim. Mean routine times are 7.6591 µs
for the unchanged projection wrapper, 2.7998 µs dot, 7.3233 µs clip and
6.8291 µs vertex wrapper. The original projection bytes are independently
confirmed by the disabled-range check.

Swaps 120–660 take 2,089 fields for 540 intervals (12.9043 observed FPS), with
no dashboard events. As above, OFF's different combat/death history prevents a
clean FPS-speedup claim. The 20-field DMA sample has observable ownership and
zero detected conflicts; four unselected ranges retain original bytes. The
retained VERIFY binary hash remains unchanged. The CPU selection is therefore
60 for A500/68020 and 56 for cached 68030 in developer comparisons; unmeasured
040/060 player policy conservatively keeps original projection.

### Completion audit still open

The implemented paths have original-checked models, exhaustive/random host
checks as appropriate, synthetic/live twins, sim-v1-only byte-checked hooks and
CUSTOM-off evidence. Combined banking/dense twins pass on all three CPUs.
Steady timing and CPU-specific selection have now been measured on all three.
Per-feature A500 bank costs also exist in the earlier records.

The plan's full fixed-window **cost** matrix is not yet complete for the final
bundle: event/banking/dense costs across all CPUs still need a consolidated
same-build check. Existing short steady samples must not stand in for those
windows. This does not invalidate the scoped results above, but W2 is not yet
marked complete. Normal player enablement remains separate, with release mask
zero and switch/default/icon decisions unchanged.

## Final-bundle A500 scene costs

The frozen VERIFY binary is compared with CUSTOM2=0 and 60 in three additional
100-field windows. The bank route uses CUSTOM5=514: the initial event starts at
the first flight checkpoint, then the bank capture starts at step 24. The dense
route uses CUSTOM5=532 and starts at step 8. No arithmetic twins run during timing.
All means below exclude interrupts and incomplete calls.

| Window | Complete 3D calls OFF / ON | Main cycles/pass OFF → ON | Change |
| --- | ---: | ---: | ---: |
| Initial cockpit event | 2 / 2 | 2,977,060 → 2,722,202 | −8.56% |
| Banking | 3 / 4 | 2,308,462 → 2,107,929 | −8.69% |
| Dense | 2 / 2 | 2,526,126 → 2,410,896 | −4.56% |

The banking capture completes an extra pass with W2 ON; these are bounded sample
means with differing call mixes, not matched-frame speed ratios or FPS claims.
All four geometry routine means improve in each window. W1 remains disabled;
the initial event still includes two original dashboard mirrors per setting.

Per-face costs can be recovered from the same instruction traces. Here a face
is one complete `sim:3b43a`–`sim:3b5da` loop iteration that takes a point, line
or polygon emission branch at `sim:3b594`, `sim:3b5c8` or `sim:3b5d4`. Costs include
that iteration's callees, exclude interrupts, and discard iterations cut by a
chunk boundary. This is the face hub's scope, not every renderer in the game;
back-face and empty iterations are excluded from the emitted-face denominator.

| Window | Emitted faces OFF / ON | Mean main cycles/emitted face OFF → ON |
| --- | ---: | ---: |
| Event | 52 / 52 | 24,927.5 → 23,792.7 |
| Banking | 70 / 73 | 34,272.8 → 33,075.6 |
| Dense | 126 / 139 | 26,469.5 → 23,680.6 |

The different face mixes matter when interpreting these means. At the matching
bank step 24 and dense step 8, captured h3 memory differs only in the known
`h3:03f5a` timestamp and `h3:0483a` elapsed fields. Every short capture has
observable display ownership and no detected conflicts. The OFF/ON unselected
hook-byte checks pass (seven/three ranges). Evidence:
`w2-scene-a500-{bank,dense}-{0,60}`, including per-window `*-costs.json` and
`*-faces.json`; the slave hash remains the frozen value recorded above.
The remaining 68020/68030 scene pairs are still being collected.
