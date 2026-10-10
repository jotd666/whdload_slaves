# W3 exact-output sound work

Status: active, not yet complete or release-enabled. The user reopened W3 after
W2 with “Goal: finish W3”. Preserve sound data, timing, buffer sizes, service
ownership and register writes. B1–B6 remain separate decisions. Normal release
mask remains zero.

## Loader and observations

A VERIFY-only filename observer confirms that `amigasnd.drv` arrives through
`LoadSeg` twice during the automated startup route. The second code entry is
`sound:0028`; patch offsets within hunk 0 are file offsets minus `$28`.
Driver hooks must handle reloads and be gated by supported sim v1 activation.
Evidence: `tmp/dev/tmp/prof/w3-sequence-twin-a500/sound-headers.json`.
That boot reached flight, but its subsequent sequencer installer byte check
aborted: it is loader evidence only, not a passed optimization/twin run.

`tools/sound_events.py` extracts per-register ordered CPU writes, including
32-bit pointer writes, and per-channel AUDxDAT DMA fetches. It keeps repeated
writes and rejects unknown audio record layouts. It processes one uninterrupted
chunk; comparisons need matching service windows. A/B audio lists support the
local proofs but do not replace them. The original final 50-field baseline
chunk decodes to 6,728 AUD0 and 6,232 AUD1 sample fetches, with 59 volume writes
per active channel.

## S1 and S9 initial implementation

Developer/VERIFY CUSTOM2 bit 10 selects S1: four longword comparisons skip an
empty sixteen-byte volume queue. The nonempty branch replays the overwritten
prologue and enters the unchanged original body at `sim:34d2c`. The empty branch
preserves all registers; the caller does not consume its flags. CUSTOM5 bit 14
runs the original empty-queue body and verifies registers, queue bytes and the
unchanged index. It does not double-write audio hardware: this original path
makes no driver calls. The original copy is VERIFY-only.

Bit 11 selects S9: replace the six-byte call at `sim:34e06` with NOPs only after
checking its relocated target and the bare RTS at `sim:34e54`. JSR/RTS and NOPs
have identical observable registers and flags at this caller. The patch does
not remove an arbitrary callback. Static hook audit: nine sim ranges, zero
split-instruction, direct-target or relocation errors. Indirect entry review:
S1 retains the public routine entry; S9 is an internal direct call site.
The corrected A500 build reaches step 8 with 296 successful live queue twins
(index 0 observed), no mismatch. Evidence:
`tmp/dev/tmp/prof/w3-sequence-twin-a500-r2/`. The installer preserves the sim base
across `resload_Patch` before validating S9; the earlier guarded abort is fixed.
Normal/developer/VERIFY builds compile (9,342 / 9,494 / 65,886 text bytes).
Other-CPU twins and performance measurements are pending. No FPS gain is claimed.

## Models

`tools/sound_model.py` models the queue’s wrapping and two-call limit, including
retaining the second consumed entry’s index. Checks cover all 65,536 occupancy
patterns under rotation and all sixteen empty-queue start indices.

At each of the three volume divides, `sound:0c46/0c6c/0c90` mask both operands
to bytes before multiplication. Thus every numerator is at most 65,025.
`((n+1)*$1041)>>18` equals `n//63` for every numerator in that domain, exhaustively
checked. The original truncates intermediate quotients to bytes; the model
preserves that behavior and the zero/final-minimum cases. 100,000 seeded volume
input tuples agree between division and reciprocal models. Original-call replay
and live assembly twins are still required; these host results alone do not
verify an installed S3 optimization.

## S3 initial implementation

Developer/VERIFY CUSTOM2 bit 12 selects three in-place ten-byte replacements.
The loader matches the full driver filename and clears authorization on any
other executable load. Only supported sim v1 activation reauthorizes patches;
its driver reloads receive fresh byte checks. Before installation, each site’s
two operand masks, multiplication and original division sequence are checked.
Sound offsets in `PERF_RANGE` are file offsets; the audit tools translate them
to hunk-0 offsets. The three sound ranges pass the static hook audit.

All sound-code writes now use patch lists inside a nested Exec Disable/Enable
section, including cache flush before re-enabling interrupts. WHDLoad’s resload
API normally permits interrupts, so relying on the patch call alone would not
be sufficient for the deferred flight installer. The long VERIFY self-test runs
before this short installation section.

CUSTOM5 bit 15 runs all 65,026 valid numerators through original DIVU versus the
replacement in 68000 code, then performs the same quotient comparison at every
live division. It guards the numerator bound. Only the quotient word is live;
the following byte masks discard the division remainder, and the final VOL
writer uses the low word. Its channel shift overwrites X before return. No
memory or hardware operation is reordered or duplicated by this local twin.
A full driver-state shadow is unnecessary for these local arithmetic changes;
that stronger machinery remains a prerequisite for buffer/service rewrites.

The first A500 S3 twin run completed 65,026 synthetic and 1,812 live comparisons
by step 8. The final atomic-installer build repeated that result and completed 592 queue
twins at step 8. Evidence: `tmp/dev/tmp/prof/w3-div-twin-a500-r2/`; VERIFY SHA256
`bad57261d0593f51eb42c79dde6e53a9d15c0154d52d0831ec8edfc8f825469a`.
`tools/sound_calls.py` also replayed 118 complete original volume calls from the
last 50-field baseline chunk: 236 model comparisons, no mismatch. It discards
chunk-edge calls and reads operands after their original loads. These checks
preserve intermediate byte truncation and the original zero paths.

W3 S1/S9/S3 together use CUSTOM2=7168. Verification uses CUSTOM5=49664
(deferred activation plus queue/division twins). Cost runs use CUSTOM5=512,
without either per-call twin. Measurements and CPU selection remain pending.
