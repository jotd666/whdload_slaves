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
