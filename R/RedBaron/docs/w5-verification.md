# W5 display pacing

## Implemented contract

P1 is developer/VERIFY CUSTOM2 bit 8 (256). Its two-byte sim-v1 hook at
`sim:00b06` changes the flight swap argument from zero to one, selecting the
original beam wait. The original publication at `sim:3154a`, blitter wait,
framebuffer exchange and copper payload remain unchanged. No other callers
are altered by P1.

P2 is bit 9 (512). It replaces the two flight calls at `sim:00b08` with a
wrapper which waits until two field boundaries have elapsed since the preceding
actual publication, calls the original swap stub, records the publication field,
and tail-calls the original post-swap function. The first publication has no
prior deadline. Slow frames do not accumulate catch-up debt. Menus and other
swap callers are not capped. Bits remain independently selectable in developer
and VERIFY builds; the player bundle selects both.

A separate VBlank hook at `sim:2d34e` counts fields. It replays the displaced
MOVEM and MOVE exactly: a3/a4 are scratch only before being overwritten by the
original MOVEM. Address-register increment preserves X, and the original final
MOVE supplies NZVC. It neither accesses SR nor masks interrupts. The wrapper
preserves register inputs during its wait. Original swap arithmetic overwrites
the wait's flags; the original post-swap function begins with TST. Its outputs
are returned unchanged. Both original calls have no stack arguments.

The unsigned 32-bit elapsed-field subtraction handles counter wrap. Installation
resets the counter and first-publication state for each supported sim lifetime.
The existing VERIFY observer uses a different hook and remains independent.
All three performance ranges are byte-checked before installation; disabled
bits preserve their original bytes. Static whole-instruction, branch and
relocation audits pass for all thirteen sim performance ranges.

The two-field rule limits average publication to approximately 25 FPS on PAL
(24.9602 at the recorded 49.92041-field rate). It is not an exact 40 ms deadline
for every adjacent pair when beam phase changes. It leaves the original Time
Scale and dt rounding/clamps intact; low Time Scale settings and frame-rate-
independent world speed remain W6 work. NTSC pacing has not been measured.

## Verification fixtures

The independent host model checks modular deadlines against an unbounded
integer schedule, fast/slow arrivals, and the original beam-wait boundaries.
The 56 existing host checks and four pacing-model checks pass. A compiled VERIFY-only CUSTOM5 bit 17 fixture replaces
the 3D trampoline with RTS and initializes the field counter near wrap. It is
incompatible with the slowed-draw fixture and is never used for pixel or game
performance claims. The hook is installed before the cache flush.

The first cached-68030 compiled stress run records 40 publications, all at line
245, with all 39 intervals exactly two fields. Its production counter agrees
with the independent VBlank observer through unsigned wrap. Evidence:
`tmp/dev/tmp/prof/w5-030-768-stress/`. This preceded the final splash-label
layout change. All 336 bytes from the pacing installer through its state block
are byte-identical in the frozen candidate, including the compiled stress setup;
`tmp/dev/tmp/prof/w5-pacing-code-equivalence.json` records that comparison.

An earlier attempt to create the fixture through debugger memory writes did
not reliably change cached memory. It is rejected as verification evidence;
no performance comparison uses that workload. The compiled fixture avoids
that debugger/cache ambiguity.

## Measurements and completion audit

The same frozen VERIFY binary was used for each CPU's OFF/ON comparison:
`3e3ddb5ccacfbb072658847716dc8d3b9eba3c941ec2e5587af0086437e2eae3`.
Normal/developer/VERIFY text sizes are 10,034 / 10,250 / 87,726 bytes.
Normal SHA256 is
`5256542f87ec1c6d3eca174416560597a60e76e1cc785cd0fbf5e3efff3f0ba8`;
developer is
`01a00068d799b01c9b17a06bc7b2ce87acf88f22c23f870afd476d4e46a6adc3`.
Both exclude VERIFY logs and the fast-draw fixture.

| Machine / common swap window | OFF fields / FPS | P1+P2 fields / FPS | FPS cost |
| --- | ---: | ---: | ---: |
| A500-equivalent, 140–240 | 2,905 / 1.7184 | 2,926 / 1.7061 | 0.72% |
| 68020, 80–400 | 2,596 / 6.1535 | 2,661 / 6.0032 | 2.44% |
| Cached 68030/50, 120–780 | 2,585 / 12.7456 | 2,650 / 12.4330 | 2.45% |

A500 P1 alone takes 2,921 fields / 1.7090 FPS: 0.55% cost, or 0.16
additional field per frame. This supports keeping P1 on all measured CPUs.
The two-field cap is retained: the independent fast-frame fixture demonstrates
its approximately 25 FPS ceiling and wrap behavior. Ordinary game windows are
below the ceiling. Pacing does not fix the game's frame-dependent world speed.

Each rate census exceeds 2,000 fields. Uncached short traces record 250 fields
in 100/100/50 chunks with two explicitly omitted joins; cached runs use separate
20-field DMA samples, without instruction-cycle claims. All selected/disabled
byte audits pass; sampled display ownership has zero active-display conflicts.
The A500 P1 entry/start/end state is identical to OFF; P1+P2 differs only in
elapsed time at the final boundary. Faster CPUs have variable dt and divergent
trajectories, explicitly retained rather than treated as correctness twins.
See `profiling.md` for cycle costs, event counts and all evidence directories.

Production-order combined feature checks (without deferred installation) pass
on A500 steady, 68020 banking and cached 68030 dense scenes through step 40.
They use masks 8127, 8127 and 4026 respectively. The dense cached check records
178,474 framebuffer writes with zero active-display conflicts. Evidence:
`tmp/dev/tmp/prof/w5-bundle-{a500-steady,020-bank,030-dense}/`.
These are functional regressions; they do not supersede earlier feature twins
or claim that deferred W1 measurements have been completed.

Live checks of the VBlank hook match all data/address registers, stack, return
PC and counter increment against the independent displaced-instruction model.
GDB's packed SR is stale on the cached configuration: a control using an original
known-zero MOVE still reports Z clear. Consequently live CCR equality is not
claimed. Flag correctness follows the replayed instructions and the host model,
including X. The initial failed SR-only check and its control are retained in
`tmp/dev/tmp/prof/w5-030-768/`.

The initial A500 boot using a previous build's load base missed the first-flight
checkpoint and is rejected. Larger slaves can change their allocation address;
accepted runs use a directly observed per-build/per-machine anchor. The accepted
fresh baseline is `tmp/dev/tmp/prof/w5-a500-0-r2/`.

## Player selection

Normal CUSTOM2=1 selects the verified W1–W5 bundle: 8127 on A500/68020 and
4026 on 68030/040/060, retaining original mirror/projection/volume division on
those later CPUs. The 040/060 exclusions are conservative policy, not measured
040/060 performance claims. CUSTOM2=0 or absent keeps all performance hooks off.
Developer/VERIFY masks remain individually selectable.

The existing default remains off and supplied icons are unchanged. The user's
final default/icon preferences remain open; preserving existing behavior is not
a new release decision. WHDLoad 17+ and sim v1 are required for these patches.
Normal option-selection checks are recorded separately from the combined VERIFY
flight regressions; no normal-build input tape is present.

All seven normal-build option checks pass: A500 with absent/zero/one and
68020/68030 with zero/one. Evidence is retained under
`tmp/dev/tmp/prof/w5-player-{machine}-{option}/`. These checks inspect the
initialized option/mask; production-order gameplay is covered by the separate
combined VERIFY boots above. The full host suite passes all 60 checks.

W5 is complete. W6 investigation and approval of a world-speed design remain
separate; neither Time Scale nor the dt formula was changed by W5.
