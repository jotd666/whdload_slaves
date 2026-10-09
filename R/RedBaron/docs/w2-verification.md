# W2 geometry implementation

W2 is in progress. Sound, game-time rules and the deferred W1 work are unchanged.
Each candidate must show a worthwhile steady-flight saving before player enablement.

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
