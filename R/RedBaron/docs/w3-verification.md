# W3 exact-output sound work

Status: complete with the explicit low-value deferrals below. S1, S3 and S9
are implemented and verified; S2/S3′/S4–S8 are not implemented. Sound data,
224-byte buffers, service ownership, repeated register writes and tick/envelope
timing remain unchanged. B1–B6 remain separate decisions. Normal player
release enablement is still gated on W5/release work; its mask remains zero.

## Loader and observations

A VERIFY-only filename observer confirms that `amigasnd.drv` arrives through
`LoadSeg` twice during the automated startup route. The second code entry is
`sound:0028`; patch offsets within hunk 0 are file offsets minus `$28`.
Driver hooks must handle reloads and be gated by supported sim v1 activation.
Evidence: the final `sound-headers.json` in
`tmp/dev/tmp/prof/w3-div-twin-a500-r2/`, also confirmed on 68020 and 68030.

`tools/sound_events.py` extracts per-register ordered CPU writes, including
32-bit pointer writes, and per-channel AUDxDAT DMA fetches. It keeps repeated
writes and rejects unknown audio record layouts. It processes one uninterrupted
chunk; comparisons need matching service windows. A/B audio lists support the
local proofs but do not replace them. The original final 50-field baseline
chunk decodes to 6,728 AUD0 and 6,232 AUD1 sample fetches, with 59 volume writes
per active channel.

## S1 and S9

Developer/VERIFY CUSTOM2 bit 10 selects S1: four longword comparisons skip an
empty sixteen-byte volume queue. The nonempty branch replays the overwritten
prologue and enters the unchanged original body at `sim:34d2c`. The empty branch
preserves all registers; the caller at `sim:34e30` does not consume its flags. CUSTOM5 bit 14
runs the original empty-queue body and verifies registers, queue bytes and the
unchanged index. It does not double-write audio hardware: this original path
makes no driver calls. The original copy is VERIFY-only.

Bit 11 selects S9: replace the six-byte call at `sim:34e06` with NOPs only after
checking its relocated target and the bare RTS at `sim:34e54`. JSR/RTS and NOPs
have identical observable registers and flags at this caller. The patch does
not remove an arbitrary callback. Static hook audit: nine sim ranges, zero
split-instruction, direct-target or relocation errors. Indirect entry review:
S1 retains the public routine entry; S9 is an internal direct call site.
The installer preserves the sim base across patch installation, with interrupts
disabled for each patch/flush operation. Final CPU twins and measurements follow.

## Models

`tools/sound_model.py` models the queue’s wrapping and two-call limit, including
retaining the second consumed entry’s index. Checks cover all 65,536 occupancy
patterns under rotation and all sixteen empty-queue start indices.

At each of the three volume divides, `sound:0c46/0c6c/0c90` mask both operands
to bytes before multiplication. Thus every numerator is at most 65,025.
`((n+1)*$1041)>>18` equals `n//63` for every numerator in that domain, exhaustively
checked. The original truncates intermediate quotients to bytes; the model
preserves that behavior and the zero/final-minimum cases. 100,000 seeded volume
input tuples agree between division and reciprocal models. The original-call replay
and live assembly twins below separately check the actual machine-code behavior.

## S3

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
without either per-call twin. On cached 68030 use CUSTOM2=3072 (S1/S9);
normal selection retains original S3 on 030 and conservatively on unmeasured
040/060. Developer/VERIFY builds continue to accept explicit bit 12.

## Frozen-build CPU twins and measurements

The final atomic-installer build passes on all three machines:

| CPU | Queue twins | Exhaustive divide twins | Live divide twins |
|---|---:|---:|---:|
| A500-equivalent | 592 | 65,026 | 1,812 |
| 14 MHz 68020 | 137 | 65,026 | 498 |
| Cached 50 MHz 68030 | 42 | 65,026 | 240 |

All counts are at flight step 8. Evidence:
`tmp/dev/tmp/prof/w3-div-twin-a500-r2/`, `w3-div-twin-020/`, and
`w3-div-twin-030/` under the same profile directory. The executable hash matches
across these runs. There are 53 passing host checks.

The completed A500 same-build pair gains 1.93% FPS in swaps 140–240, with the
same message event and final game state outside clocks. Its 250-field routine
samples reduce mean sequencer cost by 21.4%. `profiling.md` contains current
numbers, state-comparison qualifications, chunk gaps and hook-byte checks.
The 68020 pair gains 0.46% in its observed event-free window. Cached 68030
has no established FPS gain: the full bundle ties OFF at 2,118 fields; the
reduced selection takes 2,117. The one-field difference is not a robust FPS gain.

Cached whole-call beam clocks at steps 8–59 show the queue mean falling from
3.466 to 1.738 microseconds and sequencer mean from 53.373 to 51.420 microseconds
with S1/S9. These are inclusive wall times before RTS, not CPU-cycle counts.
S3’s full-bundle volume mean changes only from 4.694 to 4.621 microseconds;
input/world histories and beam quantization do not establish a material benefit.
Keep the original division on cached CPUs. The unchanged reduced-bundle volume
mean is 4.686 microseconds. See `profiling.md` for counts and qualifications.

All three cached settings have identical **per-register ordered Paula/control
writes and per-channel AUDxDAT fetch values** in their separate 20-field DMA
observations, including all four channels. These observations support the local
proofs; they are not a claim that arbitrary wall-time-aligned game recordings
must match after a frame-rate change. Slow-CPU captures have differing start
phases and world-update timing and are not used for audio-list equality.

Final builds: normal 9,656, developer 9,804, VERIFY 66,270 text bytes. Normal and
developer binaries omit VERIFY markers. Nine sim and three sound ranges pass
static audits. OFF ranges retain original relocated bytes on all three CPUs;
selected ranges match assembled S1/S9/S3 bytes. The reduced cached setting also
retains all three original sound ranges. `tmp/dev/tmp/prof/w3-cached-audits.json`
records the cached checks. No extra runtime allocation is introduced.

Performance claims are scoped to the recorded windows and voice mixes. These
changes do not alter rendering, swapping, buffering, sample data, or game-time
logic. Full scene integration and normal player enablement remain release gates.

## Remaining-candidate assessment

Apply plan §3.8 to the individual remaining candidates. The numbers below are
the original plan’s estimates from its observed workload, **not measured gains**.
They are too small to justify the required stateful rewrites in this pass.
They do not bound every possible four-voice workload.

| Candidate | Estimated frame share saved | Disposition |
|---|---:|---|
| S2 interrupt-specific register saves | 0.59% | Deferred: split note-on/L4 contracts and nested-interrupt verification |
| S3′ per-voice result memoization | 0.9% before S3 | Alternative deferred: extra state/keys, less incremental benefit after S3 |
| S4 cached per-channel pointers | 0.45% | Deferred: table readers, reload/lifetime and buffer-state proof |
| S5 direct function-16 call | 0.3% | Deferred: dispatcher register/flag and driver-lifetime contracts |
| S6 MOVEM sample copies | 0.27% | Deferred: copy ordering, buffer boundaries and DMA-state verification |
| S7 delayed pointer arithmetic | 0.25% | Deferred: another sequencer control-flow replacement |
| S8 reduced stub/envelope saves | 0.39% | Deferred: per-entry register liveness and interrupt nesting |

S2/S4/S5/S6/S7/S8 sum to 2.25% in that original estimate, before interactions.
S1 and S9 instead keep the pending-work and driver paths original; S3 replaces
three equal-size arithmetic sequences without new runtime state. Those small,
local changes have a much narrower proof and implementation burden. No S2–S8
buffer/service speedup is claimed beyond the implemented S3. Revisit the deferred
items if a new workload demonstrates a materially larger cost, especially sustained
four-voice playback. W3’s full shadow-driver/buffer framework belongs to that work.

B1–B6 are not selected: retain OS interrupt dispatch, 224-byte buffers, software
sample streaming, repeated volume writes and the original tick/envelope timing.
Changing those behaviors is a separate decision under the plan.
