# Hard Drivin' performance investigation

These findings apply to SPS 0126 and the rebuilt slave. Addresses are offsets
into the decompressed game code, not runtime addresses. Steps 1 and 2 establish
verification fixtures and baselines; step 3 establishes the time model in
[`GAME_TIME.md`](GAME_TIME.md); no performance optimization is enabled in
normal builds. Intro optimization remains deferred.

## Game-time findings

With constant native input, the A500, delayed A500, 020 and 040 produce identical
car state for 108 physics steps, including a crash, despite taking 222–1703 fields.
The ordinary field-indexed tape diverges because different steps consume its input
changes. The existing lap-clock BCD addition also consumes the incoming CPU X flag;
countdown and lap time are field-driven but not accurate real-time clocks.

The step-3 recommendation is f0=6.25 native steps/s for A500 compatibility, with a
4–8 engineering range and low confidence in historical intent. The full units,
writer/consumer inventory, scaling contract and calibration limits are in
[`GAME_TIME.md`](GAME_TIME.md). A complete ordinary controls+physics pair averages
71,673 cycles; the sampled vehicle collision costs 363,640 cycles including scene
rebuilding. Long native frames do not establish a safe larger physics timestep.

The "checkpoint" at A's field 1198 in earlier evidence is a recovery waypoint
change, not a time-bonus crossing. Retain that distinction when calibrating f0.

## Capture definition and machine matrix

All runs use PAL, PRELOAD, CUSTOM2=0, CUSTOM4=0, disabled host inputs and the
unchanged VERIFY_ATTRACT or VERIFY_DRIVE startup/input fixture. FPS is completed
conditional buffer swaps divided by emulated duration, never host elapsed time.
Warp affects collection throughput only. The 040/060 measurements use the NOMMU
cores, fixed requested frequency, real CPU speed and cycle-exact CPU/memory
settings; JIT is off. FS-UAE's fast-CPU timing is a model, not a prediction of the
ranking or speed of physical accelerator cards.

The attract anchor is `$10844`, after the initial eight-step cockpit dissolve.
Its 1,000 PAL fields last 20.031887 s, including the high-score overlay. Each
machine has two fresh boots with identical per-field complete globals/BSS,
32,000-byte front-buffer hashes and swap events. The original A500 pair also
matches every instruction, DMA record, screenshot and before/after memory byte.
The normal rebuild's stable image/pose sequence matches the shipped slave;
transient per-field state is not cycle-exact between those two slave builds.

Gameplay uses the frozen 97-record field-indexed mouse/key tape from race entry
`$10ed4`. Full swap/state windows remain A [1,1251), 25.039859 s, and B
[3000,5600), 52.082906 s. As requested, CPU/DMA gameplay samples are only
500 consecutive PAL fields (10.015944 s): A starts at race field 1, B at 4300.
The B sample spans the calibrated A500 jump, collision and start of replay.
A swap precedes the VBL input publication, so its interval label is one less
than the ensuing input field. Full-window FPS and short-sample costs must not
be mixed as if they covered the same duration.

Memory below is KiB: Chip / slow / Fast. Each result is **swaps / FPS**.

| Machine | Memory | Attract, 1000 fields | Gameplay A, 1250 fields | Gameplay B, 2600 fields |
| --- | --- | --- | --- | --- |
| A500 / 68000 | 512 / 1536 / 0 | 129 / 6.440 | 108 / 4.313 | 325 / 6.240 |
| A500 / 68000 + Fast | 512 / 0 / 2048 | 131 / 6.540 | 110 / 4.393 | 509 / 9.773 |
| A1200 / 68EC020 | 2048 / 0 / 4096 | 484 / 24.161 | 852 / 34.026 | 1070 / 20.544 |
| A1200 / 030/50 | 2048 / 0 / 4096 | 771 / 38.489 | 1104 / 44.090 | 2430 / 46.656 |
| A4000 / 040/25 | 2048 / 0 / 8192 + 8192 motherboard | 680 / 33.946 | 1094 / 43.690 | 2081 / 39.956 |
| A4000 / 040/40 | 2048 / 0 / 8192 + 8192 motherboard | 694 / 34.645 | 1096 / 43.770 | 2163 / 41.530 |
| A4000 / 060/50 | 2048 / 0 / 8192 + 8192 motherboard | 697 / 34.795 | 1096 / 43.770 | 1600 / 30.720 |

The same input tape does **not** produce the same route on every CPU. Native
physics and controls still run once per rendering pass: faster profiles collide,
replay and reach other scenes at different fields. For example, A500 B has the
validated jump and complete 90-record replay, whereas A500 + Fast B has no replay.
These are repeatable fixed-input baselines, not equal-scene renderer speedups.

## Step 4 diagnostics: performance gate still fails

A 2026-10-12 per-frame profile of the integrated phase build separates the cost of the
CUSTOM1 code from scene workload. The overhead is 16.64 ms per frame in window A and
14.98 ms in window B, which would lose 5.99% and 10.92% FPS at an equal scene. Most of
window B's 31% loss comes from the enabled car rendering twice as many polygons per
frame (28.8 against 14.0). The breakdown, the 3.78 ms budget and the reduction plan are
in [`STEP4_COST_PLAN.md`](STEP4_COST_PLAN.md).

The current experimental build uses separate CPU timing policies, one full
physics/scene pass per A500 frame, and the grounded drivetrain reference with
exact batching, combined position integration and root/power reuse. These remain
development gates; normal builds are unchanged.

A fresh-boot constant-input window captures 500 consecutive PAL fields
(10.0159435 seconds) after race-loop entry. The exact same compiled slave runs
with CUSTOM1 off/on; VERIFY_STEPINPUT holds the accelerator continuously.
Frame counts come from front-buffer changes at VBL, with physics and render calls
independently counted.

| Current diagnostic window | Buffer swaps | FPS | Mean frame time | Physics calls | Render calls |
| --- | ---: | ---: | ---: | ---: | ---: |
| CUSTOM1 off, original behavior | 38 | 3.794 | 263.58 ms | 38 | 38 |
| CUSTOM1 on, current reference | 34 | 3.395 | 294.59 ms | 35 | 35 |

Captures: `s4-power-constant-off` and `s4-power-constant-on`, using
`s4-power-constant.slave`. The off run passes all 150 inactive-range checks.
`s4-power-constant-repeat` reproduces the complete swap schedule, all 501
recorded game-state snapshots and physics records byte-for-byte.
FPS drops 10.53%; the maximum permitted drop is 3%. At this baseline that requires
at least 3.680 FPS (at least 37 swaps in this fixed window). The enabled run has
394 engine calls and 32 pitch publications, each unique to its outer pass.

The original run has no crash or replay fields. The enabled run reaches seven
crash fields at the end and no replay: elapsed simulation advances farther and
changes the scene/event workload. Therefore this is not an isolated measurement
of arithmetic overhead, and does not replace the frozen gameplay A/B baselines.
Full cross-machine handling and performance acceptance remain open.

The separate hold26 fixture gives 35 swaps for the current reference versus 37
for an earlier gated solver, not the original game. Its accelerator-release
threshold overshoots to 29 on A500 while reaching 26 on 68020, so those runs must not
be described as identical-throttle cross-machine tests.

### Projection experiments and the cheaper solver

A new 500-field constant-accelerator comparison includes the current manual,
skid, airborne and landing-audio extensions. The uncached reference still
produces 34 swaps. Two exact projection experiments also produce 34:

- A two-entry cache, cleared on every outer physics pass, avoids 422 native
  projections and computes 389 misses. It passes 3840 assembled 68000 cases,
  including long results and condition flags, but adds no completed frame.
- A level/cardinal-heading shortcut passes 4800 assembled 68000 cases (400 fast
  cases, 4400 general fallbacks), including signed-word wrap and condition flags.
  It also adds no completed frame.

Both experiments were removed from the source. Their patches, binaries and
captures remain local evidence, not accepted optimizations. The cache run has
two crash fields near the window end; the control and cardinal runs each have
seven. Equal swap counts do not establish equal trajectories or an isolated
instruction-cost comparison. Captures are `s4-vector-control`,
`s4-vector-enabled` and `s4-cardinal-enabled`; the same-slave original control
`s4-vector-original` has 38 swaps and no crash fields. Its complete retained
capture was reanalysed after correcting a verifier that had mistaken inactive
drivetrain counters for active pitch serials.

The cheaper once-per-frame drivetrain policy, without the optional reference
recurrence, gives 37 swaps (3.694110 FPS, 270.701176 ms/frame), 38 full physics/render
passes and 21 crash fields in `s4-single-constant-current`. Its 2.63% short-window
FPS loss is inside 3%, but the changed scene/event workload and unresolved
cross-machine integration accuracy prevent treating it as step-4 acceptance.
The next solver work must address that accuracy/cost tradeoff; neither tested
projection shortcut closed the reference solver's performance gap.

### Current simpler policy in both frozen gameplay windows

The all-timing build with the traffic companion bounds fix, without the optional
drivetrain reference, was run on the original field-indexed VERIFY_DRIVE tape.
The off/on pair uses the same compiled slave. Each capture retains all 5600
fields, complete native data/BSS, front-buffer images and independent
swap/physics/replay observations. Fresh repeats of both modes match all5600
complete state snapshots and front-buffer images, all events and both window
totals exactly (`s4-traffic-fixed-tape-off/on-repeat`).

| Window | Original swaps / FPS | Enabled swaps / FPS | FPS change | Original / enabled physics calls | Original / enabled replay iterations |
|---|---:|---:|---:|---:|---:|
| A, fields 1..1250 | 108 /4.313123 | 115 /4.592678 | +6.48% | 108 /116 | 0 /0 |
| B, fields 3000..5599 | 376 /7.219259 | 258 /4.953641 | -31.38% | 376 /250 | 0 /7 |

Window B fails the literal 3% FPS gate: it requires at least 365 swaps
(7.002681 FPS before integer rounding), versus 258 measured. Window A passes
the count threshold but does not preserve the original trajectory. These are
measurements of the regular integrated policy; the optional reference solver's
34-versus38 short diagnostic is a separate experiment.

The workload differs substantially. Original B has no crash or replay fields;
enabled B has196 crash fields and73 replay fields. Original A ends near
(31719,200,24912), while enabled A ends near the starting area at
(26542,2,25057). Window B begins and ends near different recovery locations, with driving and
recovery between those endpoints.
Thus neither B's deficit nor A's gain isolates solver instruction cost. This
input tape was calibrated for the native frame-coupled route; changing simulation
timing changes where its field-indexed steering acts.

The first enabled recovery is now traced directly. The native off-road-timeout
site `$105f4` is reached at field904 with the road flag clear, velocity71,
lap-clock BCD `$1444` and deadline `$1434`. Recovery begins at field905, resets
the car toward (26542,0,25057), and its flag clears at field970. No abort or
replay-exit trigger is reached in this1250-field observation. The return toward
the start is therefore an explicit native recovery, not evidence by itself of
an arithmetic teleport. This does not establish why the changed trajectory went
off-road, or validate equal-time handling. Native BCD clock defects remain.

Evidence: `s4-traffic-fixed-tape-off/on`, `s4-traffic-fixed-tape.slave`, their
`window-comparison.json` and `recovery-analysis.json`, and
`s4-traffic-fixed-recovery/recovery-triggers.json`. These supersede the pre-fix
`s4-single-tape-off/on` performance figures for this policy. Reclassifying the
window as a performance pass would hide the workload and handling differences.
Full handling, equal-time comparison and final performance acceptance remain open.

### Ten-second cost breakdown inside corrected window B

`s4-b-cost-off/on` profile500 complete PAL fields beginning at race field4000,
using the same byte-identical build as the corrected full-window captures. Both
cars move through different scenes in this interval; neither has a crash or
replay flag set. This is cost attribution, not an equal-scene benchmark.

The traces reproduce every independently recorded swap at the corresponding
500 boundaries (81 original,57 enabled), and their full native data/BSS at the
pre-trace boundary matches the independent captures exactly. Instruction-time
coverage exceeds99.99998%. Mean frame times are123.654 and175.718ms respectively.
This subwindow's29.63% FPS loss is distinct from full window B's31.38% loss.

| Complete routine, excluding interrupts | Original mean ms | Enabled mean ms | Increase ms |
|---|---:|---:|---:|
| Player physics `$0cda4` | 6.526 | 8.844 | 2.318 |
| Camera and replay recording `$0d960` | 0.943 | 6.072 | 5.129 |
| Traffic `$0d40e` | 6.325 | 11.789 | 5.464 |
| Scene preparation `$0e49a` | 12.810 | 14.844 | 2.034 |
| Scene transformation `$0b0d6` | 27.910 | 45.914 | 18.004 |
| Background `$0e706` | 18.240 | 20.930 | 2.690 |
| Scene drawing `$10008` | 28.004 | 44.458 | 16.454 |

Player physics completes82 calls in the original trace and56 in the enabled
trace; the native engine and position routines likewise complete82 versus56.
The one-pass policy is not repeatedly running the player engine between frames.
Counts differ from swaps because partial frames straddle trace boundaries.
Only complete entry-to-return calls contribute to the means above.

Complete scene-drawing calls invoke the polygon filler953 times across82 original
calls (11.62 per scene), versus1394 across56 enabled calls (24.89 per scene).
Thus much more polygon work is actually requested per enabled scene. Scene
transformation and drawing account for substantially larger per-call increases
than player physics. Camera/history and traffic are also material costs; this
is not a claim that all overhead belongs to rendering, nor that code arithmetic
alone explains differences between two trajectories. Routine costs can nest and
must not be treated as a disjoint accounting of the entire frame.

`complete-phase-costs.json` identifies the main stack context and verifies every
completed physics return at `$10f28`. This excludes complete interrupt execution,
including firmware prologues/epilogues that simple interrupt-marker tracking can
miss. The physics analyzers now use that same context separation. Evidence also
includes `window-metrics.json`, `solver-costs.json`, independent window checks,
per-field fingerprints and verified compressed traces. The original3% gate and
cross-machine handling requirements remain unchanged.

### Scene preparation inside simulation substeps

The matching 500-field `s4-dispatch-cost-off` / `s4-dispatch-cost-on` instruction
traces reproduce the independently captured swap schedules exactly. Recorded
cycle coverage is above 99.99998%. Attribution uses each capture's live game
addresses and the exact slave listing, including the new hooks.

| Inclusive routine cost | Original behavior | Elapsed dispatcher before filtering |
| --- | ---: | ---: |
| Scene preparation `$0b0d6` | 31.71% | 52.33% |
| Physics `$0cda4` | 3.67% | 7.48% |
| Polygon drawing `$10008` | 40.21% | 14.18% |

Percentages are shares of the whole window; drawing occupies a smaller share
because fewer frames are drawn. Scene preparation runs for every bounded physics
step and includes transforming/projecting distant objects for drawing. This is
separate from the physics wrapper's cost and explains why its earlier capacity
estimate was insufficient for the complete dispatcher.

`VERIFY_TIME_SCENE_CULL` now experimentally omits the native non-clipping object
path on intermediate substeps. Near-object/contact preparation, terrain, traffic,
visibility and the final substep remain complete. See GAME_TIME.md for the
same-state contact comparison and its limits.

The guarded candidate, `s4-scene-window-guard`, produces 23 swaps in 500 fields:
2.296 FPS, 435.48 ms mean frame time, 73 physics returns and 24 render calls (the
last render has not yet published at the window boundary). This is more than the
unfiltered dispatcher's 15 swaps, but remains below the original 38. The final
16 fields are in crash mode; the earlier windows do not crash. Therefore these
are protocol-level diagnostic results with different scene progression, not an
isolated equal-scene speedup or a passed 3% acceptance gate.

## Rendering and memory placement

The display is 320 × 200 with four separate bitplanes, 16 colours, 40 bytes per
scanline and 8,000 bytes per plane. Two 32,000-byte planar screen images are
used. The CPU writes planar pixels directly; this path has no chunky buffer or
chunky-to-planar conversion. It performs vertex rotation, clipping, edge setup,
masked boundary words, unrolled span stores and patterned fills at `$0329a`.
Background fill `$03a28` also uses CPU stores. The blitter assists bitmap copies,
including plane-by-plane rectangular copies at `$01566`; polygon fill is CPU code.

The VBL handler `$00044` tests the ready byte through `a4-$703e`. Only the
conditional exchange at `$000b4`–`$000be` publishes a newly rendered frame.
Hardware bitplane-pointer writes at `$000e0` occur even without a swap.
On the fast profiles, read-only changes of the front-buffer pointer at successive
VBLs count those exchanges. That method reproduces every explicit swap-breakpoint
event on the independently checked 68000/020 runs.

Placement is read from loaded hunks and live pointers at the cockpit anchor.
Globals include CPU working vertex data; edge arrays are the pointers through
`a4-$69dc`/`a4-$69e0`, patterns through `a4-$69e4`, and screens through
`a4-$6a0e`/`a4-$6a12`. Slow RAM is not true Fast RAM.

| Machine | Code | Globals/BSS | Edge arrays | Patterns | Screens |
| --- | --- | --- | --- | --- | --- |
| A500 / 68000 | slow | slow/slow | chip/chip | slow | chip/chip |
| A500 / 68000 + Fast | fast | fast/fast | chip/chip | fast | chip/chip |
| A1200 / 68EC020 | fast | fast/fast | chip/chip | fast | chip/chip |
| A1200 / 030/50 | fast | fast/fast | chip/chip | fast | chip/chip |
| A4000 / 040/25 | fast | fast/fast | chip/chip | fast | chip/chip |
| A4000 / 040/40 | fast | fast/fast | chip/chip | fast | chip/chip |
| A4000 / 060/50 | fast | fast/fast | chip/chip | fast | chip/chip |

The edge arrays remain in Chip RAM even when code, globals and patterns land in
Fast RAM. A4000 profiles have an additional motherboard Fast bank, but these
observed allocations use their configured Zorro-II Fast bank. Sprite data in the
original A500 inspection is also Chip RAM. This is an observed layout, not an
assertion about every allocation or object throughout a run.

## Routine costs

Instruction timing is validated for 68000 and 68EC020. The current backend does
not provide validated instruction timing for 030/040/060: their routine, wait and
physics-cycle costs are **unavailable**, rather than zero. Those profiles still
have independent full-window swap counts and DMA samples. Do not rank their
unmeasured CPU routines by copying the A500 percentages.

Shares below use the entire sampled window as denominator. Self attribution
excludes callees; inclusive attribution includes their traced descendants, so
inclusive rows overlap and must not be added. Call-target-aware attribution uses
the exact live slave layout. Routine shares are boundary-reconstruction estimates;
the leaf blitter-wait row instead uses its exact source-delimited instruction range.
Top self routines are listed in descending order;
parenthesized values are self/inclusive percentages for that same routine.

| Machine | Sample | Top routines: self/inclusive % |
| --- | --- | --- |
| A500 / 68000 | attract | `$0329a` (20.15/24.31); `$02a2e` (7.94/7.96); `$03a28` (6.85/6.85); `$03736` (6.45/30.82) |
| A500 / 68000 | A | `$0329a` (17.09/21.36); `$02a2e` (13.38/13.39); `$03736` (5.84/27.27); `$0a194` (5.72/8.99) |
| A500 / 68000 | B | `$0329a` (13.33/16.73); `$02a2e` (9.42/9.43); `$03a28` (6.55/6.56); `$03736` (5.16/21.95) |
| A500 / 68000 + Fast | attract | `$0329a` (20.46/24.71); `$02a2e` (7.97/7.99); `$03a28` (6.95/6.95); `$03736` (6.43/31.20) |
| A500 / 68000 + Fast | A | `$0329a` (17.10/21.40); `$02a2e` (13.47/13.49); `$03736` (5.75/27.22); `$0a194` (5.75/9.02) |
| A500 / 68000 + Fast | B | `$0329a` (18.08/21.12); `$03a28` (7.50/7.50); `$03736` (5.51/26.68); `$02a2e` (5.39/5.40) |
| A1200 / 68EC020 | attract | `$0329a` (28.37/31.78); `$03a28` (7.50/7.50); `$00740` (7.02/7.03); `$02a2e` (5.97/6.00) |
| A1200 / 68EC020 | A | `$0329a` (22.93/25.57); `$02a2e` (7.02/7.04); slave blitter check/wait (6.09/6.09); `$03a28` (5.92/5.92) |
| A1200 / 68EC020 | B | `$0329a` (24.77/27.88); slave blitter check/wait (6.85/6.85); `$03a28` (6.28/6.29); `$02a2e` (5.92/5.95) |

`$0329a` is polygon edges/spans; `$02a2e` vertex rotation; `$03a28` background
fill; `$03736` polygon bounds/clipping. Full retained reports include 40 self and
inclusive entries, calls and cycle counts. Cross-machine differences include
changed scenes and iteration counts, not only faster execution of the same work.

The following percentages are exact instruction-range costs. Blitter-check/wait
includes checking and polling overhead, not just stalled cycles. `$00740` waits
for the previous ready byte to clear; `$00750` calls it and sets the new ready
byte. Its own column excludes the `$00740` callee. Publication waiting is negligible
on the 68000, but costs 7.02% in the 020 attract sample and 3.82% in 020 A;
the faster loop sometimes reaches the handshake before the next VBL consumes
the previous frame.

| Machine | Sample | Blitter check/wait % | $00740 % | $00750 own % |
| --- | --- | --- | --- | --- |
| A500 / 68000 | attract | 2.6573 | 0.0122 | 0.0072 |
| A500 / 68000 | A | 1.4589 | 0.0071 | 0.0041 |
| A500 / 68000 | B | 1.0933 | 0.0119 | 0.0069 |
| A500 / 68000 + Fast | attract | 2.7914 | 0.0122 | 0.0072 |
| A500 / 68000 + Fast | A | 1.5580 | 0.0072 | 0.0042 |
| A500 / 68000 + Fast | B | 3.0618 | 0.0131 | 0.0077 |
| A1200 / 68EC020 | attract | 5.7197 | 7.0242 | 0.0079 |
| A1200 / 68EC020 | A | 6.0935 | 3.8204 | 0.0069 |
| A1200 / 68EC020 | B | 6.8492 | 0.4192 | 0.0067 |

Physics measurements count only complete `$0cda4` entry-to-return calls and
exclude traced interrupt work. “Own” is the wrapper itself; “subtree” includes
its physics callees. The B samples mix driving, crash and replay phases, and
include native early-return calls; they are not isolated collision-cost tests.
Partial calls at trace edges are excluded. These are native
CPU cycles, not equivalent cycles normalized across CPU models. The attract
path makes no `$0cda4` calls. Controls `$07c32` are outside this measurement and
will be included in the step-3 simulation-capacity audit.

| Machine | Sample | Completed calls | Mean own cycles/call | Mean subtree cycles/call |
| --- | --- | --- | --- | --- |
| A500 / 68000 | A | 38 | 238.47 | 70706.05 |
| A500 / 68000 | B | 54 | 241.30 | 62957.56 |
| A500 / 68000 + Fast | A | 39 | 228.00 | 69288.15 |
| A500 / 68000 + Fast | B | 71 | 214.14 | 61852.62 |
| A1200 / 68EC020 | A | 220 | 163.52 | 18757.04 |
| A1200 / 68EC020 | B | 156 | 168.64 | 19870.54 |

## DMA activity

Values are percentages of all recorded DMA slots, not CPU-time percentages.
Each cell gives **bitplanes / blitter**; N/A means unavailable blitter slots.
The effective 030/040/060 configurations have `blitter_cycle_exact=false`, and
their traces contain no blitter slot records despite real blitter use. Do not
interpret those missing records as zero activity. The retained JSON includes CPU, free,
refresh, sprite and other slot categories as present. Attract uses 1,000 fields;
A and B use the 500-field samples defined above.

| Machine | Attract | A | B |
| --- | --- | --- | --- |
| A500 / 68000 | 22.52 / 1.61 | 22.52 / 0.89 | 22.52 / 0.63 |
| A500 / 68000 + Fast | 22.52 / 1.63 | 22.52 / 0.91 | 22.52 / 1.77 |
| A1200 / 68EC020 | 22.52 / 3.41 | 22.52 / 3.64 | 22.52 / 4.05 |
| A1200 / 030/50 | 22.52 / N/A | 22.52 / N/A | 22.52 / N/A |
| A4000 / 040/25 | 22.52 / N/A | 22.52 / N/A | 22.52 / N/A |
| A4000 / 040/40 | 22.52 / N/A | 22.52 / N/A | 22.52 / N/A |
| A4000 / 060/50 | 22.52 / N/A | 22.52 / N/A | 22.52 / N/A |

## Cache state

Separate VERIFY_CACHEAUDIT boots query the existing slave setup with zero change
masks immediately after its SetCPU call. WHDLoad FILELOG records attention flags,
SetCPU/SetCACR API state and hardware CACR, then the audit exits normally. Reading
CACR uses Supervisor only on 020+, so the 68000 never executes MOVEC. These boots
are not timing captures. The audit alone requires WHDLoad 18 for resload_Log;
normal builds retain their original requirement and cache policy.

All logs report setup `$00003b3a` and cache API `$00000101`. API state requests
I/D caches even on CPUs without those caches; hardware CACR distinguishes them.

| Machine | Logged hardware CACR | Active caches |
| --- | --- | --- |
| A500 / 68000 | `$00000000` | none (no hardware cache) |
| A500 / 68000 + Fast | `$00000000` | none (no hardware cache) |
| A1200 / 68EC020 | `$00000001` | I only |
| A1200 / 030/50 | `$00002111` | I + D |
| A4000 / 040/25 | `$80008000` | I + D |
| A4000 / 040/40 | `$80008000` | I + D |
| A4000 / 060/50 | `$a0808000` | I + D |

Both 68040 and 68060 also complete separate MMU-enabled 500-field gameplay
functional runs with cockpit output and disabled-range checks. Their timings
are excluded from the matrix because the MMU core does not model the requested
frequency and Chip timing in the same way.

## Rendering ceiling

The fastest measured attract profile is the 68030/50. VERIFY_CEILING builds a
matched control and VERIFY_NOPOLY bypass with equal size, placement and alignment.
They differ only in the two-byte patch value at `$0329a`: native `move.l a4,-(sp)`
versus `rts`, skipping the whole polygon filler before its side effects. The
instant-blitter run uses the same control binary. Other settings are identical.
The regular fixture gives 771 swaps; the matched control gives 772, so the
control, rather than the differently laid-out regular build, is the comparison.

| Case | Swaps / 1000 fields | FPS | Fields to 100th swap | Seconds to 100th swap |
| --- | --- | --- | --- | --- |
| control | 772 | 38.539 | 165 | 3.305261 |
| instant | 885 | 44.180 | 107 | 2.143412 |
| nopoly | 999 | 49.870 | 101 | 2.023221 |

Instant blits demonstrate a material blitter/bus-wait contribution. Removing CPU
polygon work reaches almost one swap per field with the normal blitter, showing
that no unavoidable 25-FPS publication cap exists here. This does not isolate
pure arithmetic from Chip stores: bypassing the filler removes both. Nor do the
two gains add; overlap, changed geometry and VBL quantization affect them.
The first-100-swap comparison limits the changed route workload, but the bypass
intentionally omits polygon output and is not a visual-equivalence test.

## Time model and next work

Attract `$1084e` calls the route/view update and renderer once per loop. The
route routine `$0d54c` increments `a4-$6b2c` once per call at `$0d8fe`, interpolates
phase/10, then advances its route pointer by `$14`. There is no elapsed-time
multiplier. Gameplay `$10ed4`–`$10f5a` similarly calls controls `$07c32`, camera
`$0d960`, physics `$0cda4`, drawing and submit `$00750` once per pass. Steering,
control ramps, crash countdown and the 90-entry replay are pass-based. Mouse
accumulation and clock/countdown routines `$02c4c`/`$02c8a` are VBL-driven.

Step 1's CUSTOM4=4 instrument reduces A500 A from 108 to 75 swaps and changes the
route with the same field-indexed input. Step 2 also demonstrates different routes
across CPUs. This supports the coupling diagnosis, but does not complete step 3:
per-step comparisons must account for the changed input sequence per step, audit
all writers/time sources, establish reference rate f0 and measure controls plus
physics before implementing frame-time scaling. Keep clocks and input semantics
explicit; independent functions are not independently scheduled simulation.

## Evidence and reproduction

Builds, input/game hashes, effective configurations, memory dumps, screenshots,
WHDLoad logs and traces remain under ignored `tmp/`, never in Git. Local evidence
is `tmp/dev/tmp/prof/step2-baselines.json`, `s2-<profile>-attract{1,2}` and `-drive`,
`s2-profile-<profile>-{A,B,attract}`, `s2-cache-<profile>`, `s2-ceiling-030-*`, and
`s2-mmu-*`. The accepted earlier A500 attract traces supply its CPU/DMA result.
The local development documentation specifies capture commands and retained hashes.

The 68020 B trace repeats exactly across all 500 fields: instructions, DMA,
screenshots, cycles and complete before/after memory. Its independent breakpoint
run has the same 202 swaps, but four swaps differ by one field. The 68020 attract
trace also repeats identically across all 1,000 fields and memory snapshots,
and totals 484 swaps with two one-field differences against the counter. This is a
cross-instrument timing uncertainty, not discarded evidence or a claim of
field-exact counter agreement; the 000 samples and 020 A agree field-for-field.

The local profiler copy changes only capture range/length controls, avoiding a
host-debugger attachment on each boot. Its first 100 A500 fields match the accepted
profiler's instructions, DMA, screenshots and cycles exactly. Per-field hashes and
losslessly compressed traces retain reviewable evidence. This is an instrument
change, not a game optimization. Normal, VERIFY_ATTRACT and VERIFY_DRIVE binaries
remain byte-identical after the new audit and ceiling fixtures; disabled patch
ranges are checked against pristine relocated game bytes.
