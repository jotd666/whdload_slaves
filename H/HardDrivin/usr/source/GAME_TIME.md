# Hard Drivin' game-time model

Step 3 findings for SPS 0126. Normal gameplay remains unchanged. The proposed
reference is **f0 = 6.25 native steps/s**, with a **4–8 steps/s engineering range**
and low confidence in any single historically "correct" rate. This is an A500
compatibility calibration, not a recovered author constant or a statistical
confidence interval. The car's updates are frame-coupled; the native clocks have
separate timing defects. A single physically correct rate is not identifiable
from the available speedometer, geometry and timer evidence.

Code addresses below are offsets from the decompressed code hunk. `G($xxxx)`
means the signed 16-bit displacement from a4, e.g. G($991c) = a4-$66e4. It is
not a code address. All captures, full direct-reference indexes and tools remain
in ignored `tmp/dev/`. The current implementation inventory, including its
writer/consumer index, is also in `tmp/dev/docs/open-work.md`.

## Coupling experiment

The unchanged field-indexed VERIFY_DRIVE tape was run from native race entry
on four profiles, using the same VERIFY_DRIVE + VERIFY_SLOW binary. Snapshots
cover all allocated globals/BSS at controls entry/return, physics entry/return,
and AFTER-input VBL publication. The stop boundary is race field 1251; the
initial partial field is retained, including the 040's physics return at field 0.

| Profile | Completed physics calls | First car-state divergence from A500, zero-based step |
| --- | ---: | ---: |
| A500 | 108 | Reference |
| A500, CUSTOM4=4 | 75 | 9 |
| 68EC020 | 842 | 12 |
| 68040/25 | 1094 | 12 |

The delayed A500 consumes X=440 at physics step 9 while the ordinary A500 still
consumes X=480. At step 12 the A500 consumes X=440 while both faster profiles
still consume X=480. Heading, projected displacement and position then differ.
This is an input-domain difference, not evidence of an extra clock inside car
integration. Per-field car state diverges at fields 84, 3 and 1 respectively.
Buttons are a word at G($95f6), not the high byte alone; native controls clears
this latch. VBL can also change steering between controls and physics entry.

`VERIFY_STEPINPUT`, which requires VERIFY_DRIVE, supplies constant native
X=320, Y=200 and button 4 after race entry, reasserting the button at the controls
hook. VBL publishes the same values. It changes no pose, speed, gear, collision,
clock or RNG state. All four profiles use the identical diagnostic binary.

| Profile | Fields through physics return 107 | Car-state comparisons |
| --- | ---: | --- |
| A500 | 1326 | Reference, 108 steps |
| A500, CUSTOM4=4 | 1703 | All 108 identical |
| 68EC020 | 354 | All 108 identical |
| 68040/25 | 222 | All 108 identical |

Equality covers G($98f6)..G($9951): integer and fractional position, velocity,
contact/brake/drift state, throttle, RPM, MPH, gear and angles. Only the known
gear-table pointer G($9940) is normalized to its data-hunk offset. Every other
byte in that range is compared unmasked. The sequence includes 25 crash-state
returns. The RNG longword remains zero. Clocks differ from the first completed
step. This is strong evidence for frame-coupled car dynamics under matched
inputs; it is not a claim that every byte of global, traffic-object, framebuffer
or replay memory matches across CPUs, or that later clock-driven mode changes
cannot affect the car.

Evidence: `tmp/prof/s3-coupling-*`, `s3-stepinput-*`, `step3-comparison.json`,
`step3-coupling.json`, `step3-validation.json`. The earlier `s3-constant-*`
experiment is explicitly invalid: the debugger accepted memory writes without
applying them. None of its supposed constant-input results is used.

## Time sources and clock defects

- VBL `$00044` runs `$02c4c` and `$02c8a` while G($95ed) is enabled. These update
  the lap clock G($9790) and remaining time G($9798), in packed BCD
  minutes/seconds/hundredths. Pause, replay and mode transitions toggle the gate.
- The lap-clock `ABCD` at `$02c72` consumes the incoming CPU X flag. `CLR.W d0`
  at `$02c70` does not clear X. The preceding tests and moves preserve it too.
  Thus the instruction interrupted by VBL affects the increment. The A500 A
  trace reaches this instruction 500 times, with X clear 376 times and set 124
  times. This is a real timing dependency, not snapshot noise.
- The two clock routines share G($9040). The lap routine resets it when it reaches
  3; the following countdown routine increments it. In the normal paired path,
  the countdown therefore does not take its own `>=3` increment-of-2 branch.
  Its ADDQ clears X for this small positive counter, so the countdown normally
  loses one hundredth per field: about 0.4992 displayed seconds per emulated
  second. In native A, fields 1..1250 move 1:45.98 to 1:33.49. Lap time reaches
  19.76 at field 1250, with a phase-dependent rate rather than an exact clock.
- Countdown expiry G($979c), start countdown `$1046e`, off-road deadline G($add8)
  (`$0b172`, `$105e8`) and lap/Phantom qualification read these clocks. They are
  genuine routes by which field timing eventually changes gameplay per step.
- Input accumulation is VBL-driven. Keyboard events, button latches and mouse
  positions must be sampled consistently once per outer simulation pass.
- Sound playback uses Paula DMA periods and VBL-driven channel setup counters;
  neither needs a physics-step scale.
  Frame publication and CUSTOM2/CUSTOM4 waits change the interval between passes.

Step 4 must use a new elapsed-field counter, never these BCD values, for T.
The plan explicitly preserves the old BCD clocks; repairing them is a separate
behaviour change. T=1 compatibility alone cannot guarantee identical lap times
when instruction timing changes. Comparisons must report this limitation.

## Reference-rate evidence

The native longitudinal speed word is G($9928). In ordinary non-skidding motion,
`$0b500` projects approximately 1.5 times this value into the longword position;
word/world coordinates are longword position divided by 8. The speedometer is
approximately 0.28 times that speed, mediated by integer gears and RPM slew.
Therefore displacement is approximately **0.66964 world units per MPH per
native step**. The moving A500 A samples measure 0.67313; 020 samples measure
0.67075. This corroborates the units and frame coupling, not a metres conversion.

If one world unit represents s metres, physical MPH would require
`f0 * s = 0.66758`. No inspected game data or manual fixes s. For example, f0=6.25
would imply s≈0.1068 m. That implication is not evidence that the world actually
uses that scale. Assuming realistic gravity for the native airborne increment
of 5 would instead suggest about 23.5 steps/s; that adds an unsupported realism
assumption and conflicts with preserving the A500 experience. The handling is
an arcade model, not a dimensional calibration standard.

The road data provides further relative constraints:

| Measurement | Native value |
| --- | ---: |
| Speed-road centreline, including closure | 75,886.05 world units |
| Stunt branch, first to last stored node | 48,970.31 world units |
| Speed-road start-line node to other timed marker | 52,791.04 world units |
| Initial remaining time | 1:45.99 BCD |
| Base checkpoint and lap additions | 34 BCD seconds each, before difficulty deductions |

The stunt branch is not a closed independent lap; it joins the speed road. Do
not add an artificial straight closure. The 34-second addition is about 68.1
emulated seconds under the native countdown. Covering the long speed-road leg
within that addition needs about 5.8–7.7 steps/s at average indicated speeds of
200–150 MPH, before difficulty deductions. Slower averages require a higher
rate. The first leg benefits from the much larger initial allowance. These are
feasibility bounds with assumed averages, not a measurement of expert lap speed.
The field-1198 "checkpoint" in earlier fixture notes is a **recovery waypoint**
(G($adcc) advances), not a 34-second time-bonus crossing; A's remaining time does
not jump there. It cannot independently calibrate race speed.

The measured A500 A rate is 4.313 FPS; B is 6.240 including replay; attract is
6.440 with a canned route. Constant input reaches 60 MPH at step 20 and 100 at
step 47 on every tested CPU. Choosing 6.25 steps/s stays near ordinary A500
presentation rates and gives an exact nominal eight-PAL-field native step.
It inevitably speeds the heavier 4.3 FPS scenes and stabilizes lighter ones.
The 4–8 range reflects scene variation and checkpoint feasibility, not proof of
historical intent. Preserve f0 as one named, adjustable calibration constant;
6.25 is the initial implementation recommendation, subject to the step-4
playability tests, not an invitation to choose different rates for each CPU.

The [original WHDLoad ReadMe](https://www.whdload.de/games/HardDrivin.html) says
CUSTOM2=0 is maximum/default and higher settings slow the game. It supplies no
numeric target FPS or recommended nonzero value. The inspected user-search
results supplied no reproducible machine/value calibration either. CUSTOM2
waits raster lines at each blitter wait, so a value cannot be converted to a
fixed simulation rate without measuring that scene. The
[publisher instructions transcript](https://www.lemonamiga.com/doc/hard-drivin/769)
gives stunt speed guidance and checkpoint bonuses, but no physical course length
or world-coordinate scale. Neither source supports inventing a precise f0.

## State, writers, consumers and scaling rules

One outer pass takes `T = elapsed_fields * f0 / 50` native steps. Use 16.16
accumulators and signed fractional carries. With f0=6.25, nominal T=fields/8.
Measured PAL is 49.9204 Hz; use the specified nominal-50 convention consistently
and report its 0.159% difference from emulated seconds. T=1 must take the original
integer arithmetic and operation order, including clamps and truncation.

The table names writer/consumer routine families; the local direct-reference
index enumerates individual instruction sites. Initial data loading and native
new-race resets apply to every row. State resets/copies below must also reset or
copy any new fractional companion state. G($98ea..$98ee) is camera position,
G($98f0..$98f4) the previous/render pose, G($98f6..$98fa) current world pose,
and G($98fc..$9904) the higher-precision longword pose. Do not mix these domains.

| State and units | Writers / consumers | Chosen rule |
| --- | --- | --- |
| Throttle G($991c), integer 0..100 | `$07c32` ±2/clamps; `$0b662` off-road retention; `$0b500` skid-exit reduction; collision, `$059xx`, `$108a2`, `$117xx` reset; engine/physics read | ±2T with carry; off-road retention `(7/8)^T` while the native >30 condition holds; skid-exit 7/8 once as a transition; reset/clamp clears remainder. |
| Buttons G($95f6), X/Y G($95fa/$95fc), key/gear requests G($95ff/$991d), brake G($9911) | VBL/input readers/reset vectors; `$07c32`, patched gear selectors; `$0b662` consumes/clears requests; replay checks buttons | Latch input once per outer pass; consume discrete key/gear/start/replay-skip once. Held throttle/brake applies to elapsed time. Do not replay one-shot input on substeps. |
| Longitudinal velocity G($9928), native speed units | `$0b8a6` integration; `$0bcc8/$0bda6` collision reset; `$059c6/$108d8/$10a88/$11804` reset; steering, motion, engine, collision and race exit read | Evaluate native force law from unscaled velocity; multiply the resulting acceleration increment by T. Preserve drag, gradient and braking laws, ±40/−35 native rate limits, then scale their increments. Do not multiply the squared-speed force-law input by T². |
| RPM G($992a), target speed G($9926), MPH G($992c) | `$0b662..$0baea`; initial/recovery/race resets; cockpit, audio, collisions and score read | RPM slew ±450T; MPH and target-speed conversions keep units. Automatic/manual gear changes and gear-ratio RPM correction happen once per threshold/event, including native shift damping. |
| Gear G($9936), auto flag G($993e), table pointer G($9940) | Initial/selection `$059xx/$06faa/$087fa`, `$0b95x/$0b9ax/$0ba72/$0ba86`, `$118xx`; engine and cockpit read | Discrete state, no scale. Normalize known pointers only for comparison. Check crossing of shift thresholds on each bounded substep. |
| Projected motion G($991e/$9920/$9922), long XYZ G($98fc/$9900/$9904), word XYZ G($98f6/$98f8/$98fa) | `$0b500` integrates; `$0baee/$0cab6` correct; `$059xx/$090xx`, `$108a2`, `$10b08`, `$1100c`, `$113xx/$115xx` initialize or restore; geometry/camera/replay read | Keep displacement-source values in native velocity units; integrate XYZ with T and signed carries. Recompute word pose from longs. Teleports, replay restores and geometry corrections are not rates. |
| Angles G($994a/$994c/$994e), base/previous angles G($9944/$9946/$9948), quarter-degrees modulo 1440 | `$0b194/$0b1d0/$0b35e`, contact `$0cab6`; initial `$090xx`, camera `$0d54c/$0d960`, recovery and replay/end sequences; transforms, geometry and replay read | Scale angular-rate/steering increments by T before rotation helpers. Keep absolute angle copies, wrapping and terrain constraints unscaled. Carry fractions separately per axis; wrap the integer-plus-fraction consistently. |
| Roll/pitch rates G($9914/$9916), spin G($991a), native angle units/step | `$0cab6` contact feedback, `$0b440` spin creation, `$0b638` spin decay; collision/new-race/recovery resets; `$0b35e` integrates | Integrate rates with T; spin retention `(9/10)^T`. Contact quarter-angle corrections are relaxation toward geometry: use gain `1-(3/4)^T`, preserve native T=1 arithmetic. Where storing half the applied correction as next-pass rate, divide the time-scaled correction by T before the native half factor. Contact mask 12 assigns a rate without immediate rotation; keep that native rate then integrate with T. |
| Fall velocity G($990e), long-position units/step | `$0cd82` +5; `$0ccc6` inverted-contact acceleration; `$0cc90/$0cccc/$108c0` clear; `$0b5f8` integrates; landing threshold `$0cc42` reads | Acceleration ×T and position decrement ×T in native order. Hard contact zeroing is a constraint. A landing impulse or contact projection is not multiplied by T. No new Verlet/gravity term is added silently. |
| Contact mask G($9910), wheel gaps G($947e..$9484), normals/trig workspaces | `$0c854/$0c94e/$0ca14`, `$0cab6`, `$0b268/$0b35e`; steering, engine and collision read | Recalculate from current geometry each substep; keep distances, thresholds and Q14 trig units. Penetration projection at `$0cbdc..$0cc2a` remains unscaled. |
| Crash drift G($9908/$990a/$990c), countdown G($9912), crash G($9606) | Object/barrier collisions `$0bc62/$0bd40/$0bf80`, hard landing `$0cc54`; `$0b500` drift and decrement; `$10f08/$116a0` crash decrement; initialization/recovery/replay clear | Collision impulse, separation and initial 25/30 values once per event. Advance countdown phases by elapsed native time with carries; integrate saved drift ×T at its decay envelope. Emit expiry exactly once when crossing zero, not by testing equality after a large decrement. |
| Recovery G($9605), phase G($8cec), route G($9586/$98e4) | Abort `$07c78`, off-road `$105f4`, replay exit `$10e92`; `$108a2` phases 0..8 and resets; `$0cda4` skips while recovering | Nine-stage native recovery becomes a timed interpolation phase, advancing by T. Ground target and `(8-phase)*32` height are positions. Complete once; reset all motion/angle remainders and resample input. |
| Engine-start phase G($adde), enabled G($addc), race G($addf) | `$07d94/$07d9a`; `$0db40/$0db4c` in camera preparation; `$088xx/$108xx/$117xx` reset; controls, traffic, replay and engine read | Advance start phase by native elapsed time; preserve threshold events at 6/7. Separate phase advancement from geometry rebuild; do not charge elapsed time twice. Preserve the ordered native side effects on the T=1 compatibility path. |
| Traffic records at G($af06), 46 bytes each: phase +16 /200, speed +23, slew +21, target +22, direction +20, route pointers +0/+4 | `$0cdf8` init, `$0ce70` via `$0d40e` advance, `$0d450/$0d496` reverse/reset, `$0bc4c` collision reversal; objects +8..+18 written there and replay; collision/scene/replay consume | Speed slew ×T and route-phase advance ×T with carry. Process every crossed route boundary and branch in order; never skip topology when T>1. Geometry interpolation remains absolute. Reset phase carries on route resets/replay exit. |
| Course progress G($adcc/$add0), checkpoint latch G($af30), wrong-way G($e930), difficulty G($add5), lap/Phantom result flags | `$07b8c/$0880c` reset waypoint pointers; `$0dbbe/$0dbee` advance; `$0dee8/$0e272` set direction; `$092c0/$0936a` latch crossings and award time; `$07612/$08798` choose difficulty; scene, recovery, overlays and qualification consume | Discrete geometry-driven transitions: process crossings in order on each bounded substep, once per crossing. Do not scale pointer strides, difficulty or bonus amounts by T. Preserve BCD comparisons and report their clock dependence. |
| Score G($9788), BCD points | Init `$06ac6`; camera `$0db1e..$0db2c` adds MPH>>4 via BCD helper; other score events; `$10020` draws | Time-integrate the per-pass score rate with carry; keep one-shot bonuses discrete. The draw routine itself has no timer to scale. Do not charge an extra interval for collision camera rebuild; preserve native T=1 score-event multiplicity. |
| Instant replay: G($e91e), 90×158-byte ring G($b192)..G($e91d) | `$0898c` init, `$089d8` record/advance, `$089b4` rewind on collision; `$10b08` playback, copying player/traffic/camera/pitch | Keep native-duration history: timestamp records or sample at f0, with interpolation when a variable step spans sample times. Playback advances a time cursor, not one stored frame per displayed frame. Preserve collision rewind and skip semantics; restore companion state on mode changes. |
| Phantom recording/playback: G($e922/$e92c) phases /6, G($e924/$e928) record pointers, 12-byte poses | `$08a9c` records, `$08b0e/$08c84` interpolate/advance; `$118xx` reset; `$1100c` post-race playback saves/restores cursors | Advance phase in native time, crossing all six-step sample boundaries. Keep angle wrap and absolute pose interpolation. Post-race camera/player motion is a separate presentation timeline; never run live car physics there. |
| Post-race Doppler pitch G($9602), previous distance local at a5-22, volume G($958e) | `$1100c`: `$1119c..$111c8` computes current minus previous distance, pitch `800-6*delta`, distance attenuation; `$007d0` consumes; `$1126e` restores volume | This is a genuine finite difference: divide distance delta by elapsed native presentation time before the pitch conversion. Preserve the T=1 branch and reset previous distance at entry. Absolute distance attenuation is unscaled. |
| Replay shake/animation: `$10b08` locals, frame index d4, 3-pass animation divider, last-26-record effect | `$10dd8..$10e16`, `$10e5a`; draw and sound consume; `$00a36` RNG called twice per effect | Time-based replay phase. Trigger each historical event once even if multiple frames are crossed; RNG advancement tied to historical replay events, not display frequency. |
| RNG G($903c), 32-bit state | Initial zero; sole direct mutation `$00a54` inside `$00a36`; two callers `$10db8/$10dc6` | Discrete event sequence, no T multiplier. Zero bypasses recurrence and stays zero in all measured captures. No hardware-time read was found in this recurrence. |
| Overlay lifetime G($af32), message G($e92e) | Checkpoint/lap `$092c0/$0936a`, Phantom result `$08c84`, off-road `$1058e`, main/Phantom crash loops, race reset; `$10246` decrements | Replace 40/60-pass duration with native-time phase; draw from current phase. Preserve one-shot message selection and expiry. |
| Attract route G($94d4), phase /10, pointers G($94d8/$94dc), fork flags and cached deltas G($94bc..$94d7) | `$0d54c` through `$0d960` writes route pose/angles; init from route table; draw/camera consume | Separate attract elapsed-time phase; increment by T, process route wraps/forks, interpolate geometry. No player physics is called. Never let repeated scene preparation advance it twice. |
| Attract duration 1000 passes, overlay scroll G($fb54), alternate-page flag G($9584) | `$107d6/$1088c` init/advance, `$10672/$10706` decrement scroll; `$10898` toggle; overlay draw reads | Timed presentation, using its own active epoch. Phase ×T; crossed toggle/exit once. Gameplay time does not accumulate during attract. |
| GAME OVER 35 passes, split-text motion capped at 20 | `$10f66..$10ff0` local phase; text renderer consumes | Independent presentation elapsed time; phase ×T, clamp position, exit once at 35. No live physics catch-up on returning to menus. |
| Other menus/transitions | Submit callers `$0540a/$05efa/$06040/$0630e/$06a1a/$06bf6/$06d1a/$06fba/$077a2/$0850a/$11252/$1147c/$11510/$115e0/$1189e` | Input-driven waits remain event-driven. Animate 200-pass credits, +3 scrolling, bounded waits, seven-pass end-camera and post-race playback on separate presentation time. Keep fade/dissolve sequence indices discrete but schedule their intervals; exclude menus/loading from gameplay T. Intro optimization stays deferred. |
| Audio events `$008ae`, pitch G($9602), channel-start G($8fc6), sample pointers/periods | Control start, gear/skid/crash/checkpoint/off-road/replay callers; `$0baea` computes RPM-derived pitch, replay `$10c14` restores, crash clears pitch and recovery stops audio; `$007d0` programs Paula, `$00840/$00864` stop | Keep pitch conversion and DMA sample periods unchanged. Latch transition sounds once; sustained sounds may update pitch once after simulation. Do not restart collision/start samples per substep or per rendered replay frame. |
| `$10020` score, `$0f894` cracked windscreen, cockpit/background/polygon drawing | Draw state reads and framebuffer/blitter writes; `$1046e/$1058e/$10238` also have time/state side effects listed above | Draw once per outer pass. No generic T multiplication in rasterizers. Move or gate the listed side effects separately; these calls are not all pure rendering. |
| Audio service pointer G($9006), channel records G($900a)+12*channel, setup counters G($9020/$902c/$9038) | `$008ae` selects service; `$00864` clears it; `$00760` sets record +10 to 2 with sample/period/volume; VBL `$002f8..$003d4` calls `$042ae` or decrements channel counters | Already field-driven: leave durations and Paula programming unchanged. These are hardware setup phases, not simulation counters. |
| Native clocks, pause and mode flags | VBL `$02c4c/$02c8a`; reset `$06aca/$08870/$09462/$104e0/$11740`; BCD allowance helpers at `$09354/$09452`; deadline `$0b172`; many mode gates | Preserve native BCD semantics under the existing plan. New field epoch resets on entry/resume/exit; no pause/replay/loading debt. Report lap-clock phase dependence independently from car-state comparisons. |

Scene setup `$0d960` is particularly important: it copies current pose into the
render/previous domains, records replay, accrues score and advances engine-start
state. `$0baee` can call it again after collision through `$0cde2..$0cdee`.
Scaling only `$0cda4` and `$07c32` would leave multiple simulation systems tied to
rendering and would duplicate side effects on collision substeps.

The steering, force and contact routines do not contain an ordinary
finite-difference velocity estimate that should automatically be divided by T.
Position differences in `$0baee` describe collision segments; leave their geometry
intact. Rate conversion is required specifically when a new time-scaled contact
correction is stored back as an angular rate. The geometry-selected contact and
collision policies must be tested at T<1 and T>1; the table is a design, not an
already-validated variable-step solver.

## 68000 capacity measurements

Each sample is 500 PAL fields (10.015944 s). A uses race field 1; B uses 4300;
an additional unchanged-tape sample uses field 1900 for the earlier vehicle
collision. All use the accepted A500/68000 slow-RAM profile. The extra sample's
83 swaps match the independent tape run field-for-field. Costs include complete
entry-through-RTS controls and physics calls, exclude interrupt work and partial
boundary calls, and pair each physics call with its preceding controls call.
They include native integer helpers, audio calls and collision-triggered scene
rebuilding, not only the wrapper instructions.

| Class | Complete pairs | Mean cycles | Maximum cycles |
| --- | ---: | ---: | ---: |
| A ordinary | 37 | 71,673 | 94,822 |
| B ordinary before jump | 8 | 74,280 | 77,500 |
| B airborne | 21 | 58,926 | 69,284 |
| B hard landing/crash initiation | 1 | 70,160 | 70,160 |
| B crash tail | 24 | 63,669 | 87,224 |
| Approach ordinary | 44 | 26,811 | 42,364 |
| Approach vehicle collision + scene rebuild | 1 | 363,640 | 363,640 |
| Approach crash tail | 24 | 8,052 | 8,130 |

Controls alone average 727 cycles in A and 531 in B. A's physics-only mean is
70,706 over 38 complete calls; its first call lacks a complete preceding controls
sample and is omitted from the pair table. The approach collision is 362,924
physics cycles plus 716 controls cycles, entering `$0bc62`, setting crash state
at `$0bce0`, and taking the scene-rebuild branch at `$0cde2`.

At 7,093,790 Hz, a typical 71,673-cycle pair costs 10.10 ms (0.50 PAL fields);
the measured collision costs **51.26 ms (2.56 fields)**. At f0=6.25, typical native
physics plus controls consumes about 6.3% of the CPU budget before rendering,
traffic or new fixed-point overhead; continuously paying the sampled collision
cost would consume 32%. One additional substep can therefore be cheap in ordinary
driving and expensive at contact. The measured maxima are sample maxima, not a
proof of worst-case execution time or stability for arbitrary T.

The old plan's "11 fields" refers to attract, not the longest gameplay frame.
The full A swap gaps are 9..15 fields; B is 1..12 including replay transitions.
At f0=6.25, 15 fields corresponds to T=1.875, but **the original always integrated
T=1 even on that frame**. A long native frame does not establish that T=1.875 is
safe. Start with a conservative native-step bound T<=1 and price any necessary
substeps; increase it only after contact/long-frame validation. No time may be
silently dropped. This corrects the plan's stability inference without changing
the user's one outer simulation update per rendered frame design.

Evidence: `step3-costs.json`, `s3-profile-a500-impact`, the existing step-2 A/B
traces, and `step3-validation.json`. Instruction timing on 030/040/060 remains
unvalidated; no cycle claim here uses those backends.

## Acceptance and next boundary

The normal, original VERIFY_DRIVE and VERIFY_ATTRACT builds remain byte-identical
to step 2. VERIFY_STEPINPUT without VERIFY_DRIVE fails assembly. Disabled
PERF_RANGE checks pass on all four controlled captures, including the optional
CUSTOM4 range. Normal SHA-256 is
`5811a0305be8836685b6303aae226845836c6c41e90e746c9a6bfebae226582e`.

Step 3 supplies a measured coupling model, an explicit low-confidence operating
reference, the complete timing/state inventory and rules, and ordinary/collision
capacity estimates. Step 4 still has to implement and validate the gated
variable-step arithmetic, fractional state, modal epochs, replay timeline,
contact policy and substep budget. No performance or gameplay patch is enabled
by this investigation.


## Step 4 implementation status

Step 4 remains incomplete. `HardDrivinTime.s` currently supplies an elapsed-field
observer and exact arithmetic helpers, compiled only with `VERIFY_TIME` and
installed only with CUSTOM1 nonzero on SPS 0126. VERIFY_TIME alone does **not** scale gameplay,
run catch-up substeps or remove CUSTOM2. The additional `VERIFY_TIME_DISPATCH`
gate now connects the live loop to bounded elapsed-time substeps (details below).
Normal builds exclude the entire module.

The VBL hook follows the native register saves at `$00050`. It counts while the
live-loop epoch is active and preserves incoming X before the native clock code.
The `$10ed4` boundary records elapsed fields and cumulative observed fields; its
published Q16.16 T is the first bounded step, at most 1. The cumulative counter
is observation, not consumed simulation time. A separate helper splits unsigned
field debt into at most eight fields plus the full remainder, including debts
larger than Q16.16 can represent. At the chosen f0, one field is exactly `$2000`
Q16.16, so conversion itself has no rounding loss.

Native pause and replay suspend this observer and resume its previous epoch.
Options-menu clock boundaries are hooked too, but their interactive transition
has not yet been exercised. Race exit disables the observer. This provides no
claim yet about scaled menu/replay durations. Input latching is implemented by
the separate dispatcher gate below.

Diagnostic evidence retained under ignored `tmp/dev/tmp/prof/`:

- `s4-clock-a500-1`: 35 passes, 456 observed fields; delayed `s4-clock-slow`:
  35 passes, 570 fields; `s4-clock-040`: 35 passes, 62 fields. Every pass's
  elapsed difference and Q16.16 conversion matches its captured counter.
- `s4-clock-pause`: decoded keyboard spaces enter and leave the real pause.
  25 passes span 416 fields, of which 328 are active; the 88 paused fields do
  not appear as debt in the next pass. This fixture changes input only.
- `s4-clock-replay-full`: the fixture releases buttons during crash/replay so
  playback can run. Across 6000 sampled fields, the final pass at field 5997
  records 5283 active fields, excluding 714. This is clock-suspension evidence,
  not proof of all 90 replay iterations or a validated replay time conversion.
- `s4-time-math-final`: 1215 68000 executions of signed increment scaling match
  an independent integer model, spanning word extrema, T=0..1 in eighths and
  every signed fractional carry -7..7. Eleven debt-splitting cases, including
  `$ffffffff` pending fields, preserve all remaining fields without overflow.
- `s4-clock-off-final`: CUSTOM1 off leaves all declared timing ranges pristine.
  Normal, VERIFY_DRIVE and VERIFY_ATTRACT builds remain byte-identical to the
  accepted step-2/3 binaries. The normal SHA-256 above remains valid.

The additional `VERIFY_TIME_SCALARS` development module now scales throttle ramps,
longitudinal acceleration and both RPM slew limits. `VERIFY_SCALAR_FIELDS` selects
its constant test interval (0..8 fields, default 8); the observer is not yet wired
to these updates. This deliberately incomplete build is an arithmetic experiment,
not frame-rate-independent gameplay. CUSTOM1 off installs neither module.

Throttle carries Q16 fractions through ramps and off-road `(7/8)^T` retention.
The nine-entry retention table is rounded to the nearest Q16 unit; multiplication
uses exact integer floor rounding. Its coefficient error is at most half a Q16
unit. T=1 uses the original integer multiply/shift and clears the decay fraction,
preserving the native truncation sequence. Small-T retention is therefore a finer
model between these integer steps; full handling equivalence remains to be tested.
The discrete skid-exit reduction stays unscaled and clears the fraction.

Velocity and RPM increments use exact eighth-unit signed remainders. RPM scales
the ±450 slew limit, saturating at the target, rather than scaling target error.
New-race, Phantom initialization, recovery, collision and throttle-reset writers
clear affected fractions. Shadow values invalidate fractions after other absolute
writers; RPM also checks gear changes, even if the integer RPM stays unchanged.

Scalar evidence (local capture names):

- `s4-scalars-final-{a500,slow,020,040}`: 108 car states per profile at T=1,
  compared with the original constant-input reference. Equality covers the same
  G($98f6)..G($9951) range and gear-pointer normalization as step 3. This is not
  the full field-indexed driving tape or a variable-T trajectory comparison.
- `s4-scalars-ramp-q16`: at T=1/8, captured native operands and results match
  the independent arithmetic model for 179 velocity, 111 upward-throttle,
  64 downward-throttle, one neutral RPM and 179 engaged RPM updates.
- `s4-retention-math`: 315 private-memory emulator calls cover all T values,
  five throttle values and seven positive/negative fractions against an
  independent integer model and high-precision coefficient calculation.
- `s4-time-math-q16`: the earlier 1215 eighth-unit and 11 debt cases still pass;
  an additional 441 cases cover signed Q16 integration across its supported
  rate range, all T values and boundary fractions.
- `s4-scalars-off`: with CUSTOM1 off, all scalar and timing PERF_RANGE sites
  retain their original relocated bytes. Normal, DRIVE and ATTRACT builds remain
  byte-identical; six invalid flag/range combinations fail assembly as intended.
- The first ramp fixture did not reset its counter at race entry and failed to
  exercise downward input. Its arithmetic results are not downward-coverage
  evidence; the final fixture resets at race entry and requires that coverage.

`VERIFY_TIME_MOTION` adds angular-rate, spin-retention and fall-acceleration
hooks, sharing the scalar module's constant diagnostic field count. The native
pitch/yaw rotation helpers also serve terrain corrections; their three rate-driven
call sites explicitly mark rate integration, while geometric callers remain
unscaled. Q16 angle carries survive the native ±1440 wrap. Hard contact, barrier
rate resets and the native roll-to-zero constraint explicitly clear the affected
fractions, including when the integer angle did not change. Mode transitions
reuse the scalar module's reset paths.

Spin uses a signed `(9/10)^T` Q16 table for smaller T and the native signed
multiply/divide sequence at T=1. Its fraction is cleared at the discrete skid
exit. Fall acceleration uses signed eighth-unit carries; ground constraints
clear them. Falling displacement and partial-contact relaxation/feedback are
scaled as described below.

Motion evidence:

- `s4-motion-final-{a500,slow,020,040}`: all 108 native-step car states per
  machine match the original constant-input reference. `s4-motion-turn-final`
  also matches 108 states from the unpatched X=400 steering reference. These
  captures have no airborne or nonzero-spin returns; they do not establish
  live jump, airborne or spinning-car equivalence.
- `s4-motion-math-final`: private-memory 68000 fixtures pass 135 angle cases
  (including wrap and absolute-write invalidation), 315 signed spin-retention
  cases and 81 fall-acceleration/carry/reset cases.
- `s4-motion-small/steering-check.json`: with X=400 and T=1/8, native steering
  is four quarter-degrees per native step. Steps 20..49 advance at the expected
  half-quarter-degree per update, within 0.5 quarter-degree integer quantization.
  That capture predates position scaling and is steering arithmetic evidence only.
- `s4-motion-off` verifies every new range remains pristine with CUSTOM1 off.
  Normal, DRIVE and ATTRACT builds remain unchanged.
- A direct-branch audit covers all scalar/motion ranges. An early hook placement
  overlapped shared contact targets `$0cd86` and `$0ccd0`; it was removed. The
  final hooks dispatch at `$0ccd4`, `$0cc8a` and `$0cca0`, preserving both targets.
  The stalled early `s4-motion-one-a500` capture is invalid and was stopped
  through its owned capture process. Early captures do not prove the final code.

Ordinary projected XYZ movement now uses signed 1/128-position remainders.
The jump hook at `$0b500` preserves the native LINK frame and snapshots the
previous projected velocity before recomputation. The `$0b578` hook integrates
`v*T + (1-T)*(v-u)/2`, where u and v are the old and new projected rates. This
preserves the native semi-implicit Euler displacement when constant acceleration
is subdivided. T=0 consumes no displacement. Long arithmetic avoids signed-word
division overflow at boundary velocities. Integer terrain translations retain
fractions; existing collision/recovery/mode resets clear them. The native word
positions are still recomputed from the resulting longs.

This is an implementation of the projected-vector correction, including steering
changes; nonlinear handling acceptance remains open. Fractional longitudinal velocity now has the projection extension described below. Crash
drift uses the separate timed envelope described below.

Position evidence:

- `s4-position-math`: 1323 private-memory 68000 cases cover both signed-word
  velocity extrema, all field counts and signed carry boundaries. Sixty exact
  rational subdivision cases independently check the constant-acceleration
  displacement identity. Earlier angle, spin and fall arithmetic checks pass.
- `s4-position-one`: 108 native-step car states match the original X=400 steering
  reference, including the existing crash sequence. This is still the limited
  constant-input comparison, not the full driving-tape acceptance gate.
- `s4-position-small-hooks`: 360 actual axis updates at T=1/8 match a model of
  the captured input operands; 210 results retain nonzero fractions. This proves
  the live hook arithmetic, not equal-time trajectories or contact stability.
- `s4-position-off`: CUSTOM1 off leaves every declared range pristine. The normal
  slave remains byte-identical to the baseline. The direct-branch audit passes
  all 34 scalar/motion ranges.

The `$0b5f2` hook now scales falling displacement, including the eighth-unit
fall-velocity fraction, into the same signed 1/128 Y-position remainder. Native
gravity updates velocity after position. Its correction is therefore
`-v*T + a*T*(1-T)/2`, using the acceleration sampled by the preceding contact pass.
The acceleration sample is consumed once; ground constraints, absolute-velocity
mismatches and mode resets clear it. Partial contact with no acceleration leaves
the next sample zero. All-T=1 retains the native integer sequence.

This delayed-acceleration choice requires jump and landing acceptance at small T.
The first airborne update has no prior airborne acceleration sample; the constant-
acceleration identity does not prove equivalence across that transition. The bias
can also create a fraction of upward displacement while velocity starts at zero;
that follows the original explicit-Euler model, rather than a new finer integrator.

Falling-position evidence:

- `s4-fall-position-math`: 405 68000 cases cover signed-word velocity extrema,
  velocity fractions, both acceleration signs and all field counts. The earlier
  1323 position, 135 angle, 315 spin and 81 fall-acceleration cases still pass.
  An independent exact-rational calculation checks 36 constant-acceleration
  subdivision identities for the explicit-Euler displacement.
- `s4-fall-live`: 400 actual falling-position calls on the driving tape match
  their captured operands, including 19 nonzero fall velocities. This run uses
  T=1; it is not small-T jump or contact acceptance.
- `s4-fall-position-one`: 108 native-step car states match the original X=400
  reference. `s4-fall-position-off` passes the disabled-range check, including
  the new falling-position range. The direct-branch audit passes all 35 ranges.

Crash drift now preserves the native 30-sample slowdown envelope in elapsed
fields. Each native sample lasts eight fields; its signed multiply/divide result
is retained exactly, and fractional updates integrate that rate with an eighth-
position carry. A bounded step crosses at most one sample boundary. This preserves
both the original total displacement and its rounding under subdivision, without
the backwards tail that a continuous Euler correction would introduce. This is
sampling of the crash envelope, not a fixed-tick replacement of the simulation.

The drift hook replaces `$0b596..$0b5f1`, leaving the shared `$0b5f2` target intact.
All four writers that start drift explicitly reset its companions, even when the
visible counter remains 30. Recovery, race and replay resets also clear them.
The visible counter is the ceiling of the remaining fields divided by eight.

The live and Phantom crash timers at `$10ef0` and `$11680` now consume elapsed
fields too: 25 native steps become 200 fields. Their four initialization writers
reset the timer even if its visible byte is unchanged. Crossing zero emits the
native replay request once; live mode clears the overlay, while Phantom mode
sets its original overlay lifetime and phase. The remainder of Phantom playback
is not yet converted, so this does not establish timed Phantom-mode equivalence.

Crash evidence:

- `s4-crash-math`: 56 complete drift sequences cover signed-word vector extrema
  and every nonzero field count. Final XYZ displacement, final carry, call count
  and rolling checksums of intermediate X positions/remaining fields match an
  independent field-by-field model. Eight crash timer sequences expire once;
  additional cases verify T=0 and a reset while the visible timer is still 25.
  Earlier position, angle, spin and falling arithmetic checks still pass.
- `s4-crash-one`: all 108 native-step car states match the original constant-input
  reference. The crash/drift counters, replay-request byte, overlay lifetime and
  Phantom phase also match at every return, including 25 nonzero crash states
  and one observed replay request. This is live-mode evidence; the Phantom
  expiry wrapper has not yet been exercised in its full native mode.
- `s4-crash-off`: all declared patch ranges remain pristine with CUSTOM1 off.
  The normal slave is byte-identical to the baseline. The direct-branch audit
  passes all 46 scalar/motion ranges.

`HardDrivinContact.s` now drives the partial-contact roll correction, pitch
correction and rear-wheel pitch feedback. It computes the Q16 correction with
`1-(3/4)^T` and the feedback gain `(1-(3/4)^T)/T` before integer quantization.
Both coefficient tables round to nearest Q16, with at most half a coefficient
LSB error. T=1 follows native signed quarter-angle division and arithmetic
half-rate rounding. T=0 preserves the prior feedback state.

Full Q16 roll and pitch rates accompany the native words. Roll integration and
the pitch-rate caller consume these fractions. Pitch uses the native roll cosine
with a wide Q16-by-Q14 product; at T=1 it retains the original integer projection
rounding. Smaller T preserves the projected fraction until angle accumulation.
The projection helper splits signed integer and unsigned fractional products on
the 68000, avoiding a 48-bit multiply and premature input rounding.

Every native angular-rate reset is covered by the existing race, collision,
recovery, Phantom and hard-contact reset paths. These clear the full companions,
including same-value word resets. Other word changes invalidate the companion.
The roll constraint also checks the full rate, so a nonzero fractional rate does
not trigger the native integer-zero snap prematurely.

Contact evidence:

- `s4-contact-math-full`: 162 response and 189 projection cases pass against
  independent high-precision/full-product models. It also executes the actual
  roll correction/rate consumer/reset in 45 private-state cases and the pitch
  correction/rate consumer/reset in 135 cases, across every T. A private cosine
  jump vector controls pitch projection without writing to game memory.
- `s4-contact-one`: 108 native-step car states match the original constant-input
  reference. `s4-contact-off` leaves every declared range pristine with CUSTOM1
  off. The normal slave remains byte-identical, and all 50 ranges pass the direct-
  branch audit. These are not full driving-tape or small-T handling acceptance.
- `s4-contact-tape-trace`: five actual native-T contact events (one front pitch,
  four rear pitch) produce the expected rates; this tape did not exercise the
  roll-contact hook. VERIFY_CONTACT_TRACE records consumed operands in private
  companion padding. Three debugger entry D0 readings had the opposite sign
  from the values actually consumed. The earlier `s4-contact-tape` register-based
  check is therefore not valid operand evidence; the recorded-input check passes.
  Recheck debugger-register-based operand evidence before relying on it for final
  acceptance. Memory snapshots and private arithmetic fixtures remain distinct.
- `s4-contact-integrated-math` is an invalid harness-start attempt: its instance
  name exceeded the local Unix socket path limit. The completed fixture uses a
  shorter owned instance name and a fresh output directory.

VERIFY_CONTACT_MATH and VERIFY_CONTACT_TRACE require MOTION. The private contact
fixture is separate from the growing motion fixture. Nonlinear partial-contact
handling at small T still needs live jump/loop/collision acceptance.

`HardDrivinProjection.s` now projects the signed eighth-unit longitudinal
velocity remainder through the native pitch and heading Q14 factors. The native
integer projection and its truncation stay intact; the extension adds only the
fractional velocity contribution. Thus an all-T=1 sequence with zero velocity
carry retains the original integer path exactly. This does not replace the
native odd-speed `v + (v >> 1)` rounding with a finer 1.5× integer-speed model.

The extension keeps current and previous Q16 projected fractions and applies the
same Euler correction as ordinary position. Separate Q16 position carries retain
its sub-unit contribution; the original 1/128 position/fall carries stay intact.
The final division rounds down at Q16 precision, losing less than 1/65536 of a
long-position unit per call. During skidding it holds the preceding projected
fraction, matching the native held vector. Native velocity-word changes invalidate
an unmatched speed fraction, and existing motion resets clear all companions.

Projection evidence:

- `s4-projection-math`: 60 projection cases cover all velocity remainders and
  signed/axis-aligned trig factors. 1323 Euler/carry cases match an independent
  integer model across all T and signed boundaries; reset clears all nine longs.
- `s4-projection-small`: at T=1/8, all 360 live axis updates match a model using
  captured memory operands. 200 updates have a nonzero projected fraction; the
  fractional path emits 11 absolute long-position units over the capture.
- `s4-projection-one`: all 108 native-step states match the original reference.
  `s4-projection-off` passes the disabled-range check, and the normal slave remains
  byte-identical. Existing motion diagnostic builds still assemble. The separate
  VERIFY_PROJECTION_MATH fixture requires MOTION.

`VERIFY_TIME_TRAFFIC` now scales traffic acceleration and route-phase progress
through `HardDrivinTraffic.s`. It requires TIME_SCALARS and CUSTOM1. Each native
46-byte record has a separately allocated 16-byte companion for speed/phase
remainders and reset state. The table-load hook allocates exactly the native
record count through Exec, releases the previous allocation on a later load,
and aborts with the existing allocation error if memory is unavailable. The
captured table has 12 records; the companion allocation has no fixed count limit.

The SPS0126 table uses acceleration 1..3 and target speeds 9..20. Native byte
acceleration can overshoot a target: +2 toward 9 settles at 10, and +3 toward 20
settles at 21. Fractional acceleration preserves that terminal value,
`ceil(target/acceleration)*acceleration`, derived from the zero-speed reset grid.
Collision reversal negates the full signed speed including its fraction. Route-
direction reversals remain native discrete changes and retain the phase fraction.

Phase integrates the new full speed with the same semi-implicit Euler correction
as the player. Short steps retain the signed 1/128 phase remainder and native
route-boundary code. Long steps add an exact sixth of that remainder unit and
walk every crossed segment, as described below. Native code still prepares cached
geometry. Phase remainders survive native ±200 wrapping. Initialization consumes its original one native step regardless
of gameplay T, while subsequent zero-time updates consume nothing. The native
pose interpolation still reads phase before its update; equal-time acceptance
must distinguish stored progress from the pose sampled for that pass.

Traffic evidence:

- `s4-traffic-native` versus `s4-traffic-reference`: all 1440 traffic records and
  their six-word poses match. Route pointers are normalized relative to the
  route base; object pointers are omitted while the corresponding poses are
  compared separately. The native run includes 92 route crossings.
- `s4-traffic-small`: all 1440 live T=1/8 updates match a model of captured memory
  operands, including 1103 fractional updates and five route crossings.
- `s4-traffic-math`: 50 private-memory reversal cases cover signed speed,
  signed fractions, stale-shadow invalidation and double reversal. Additional
  cases verify the unscaled initialization step and subsequent T=0 behavior.
  The live captures contain no velocity-reversal event, so they do not prove
  small-T traffic collision behavior or full route-direction transition handling.
- `s4-traffic-one`: 108 native-step player states still match. `s4-traffic-off`
  passes the disabled-range check; the normal slave remains byte-identical.
  All 56 scalar/motion/traffic ranges pass the direct-branch audit. Repeated
  table-load allocation cleanup has not yet been exercised interactively.

Remaining work includes live small-T contact validation,
held-input handling, traffic collision/transition acceptance, replay/Phantom and other
presentation timelines, performance and cross-machine acceptance, and the
required human laps. The BCD clock defect versus lap-time acceptance conflict
remains unresolved; the implementation currently preserves the native clocks.

## Overlay and recovery timing (development gate)

`VERIFY_TIME_PRESENTATION` requires TIME_SCALARS and CUSTOM1. Overlay starts of
40/60 native steps initialize an elapsed-field countdown, including same-value
restarts. Rendering publishes the ceiling of remaining fields/8 and saturates at
zero. Recovery initializes only once even when fractional updates leave its
native phase byte at zero. Height falls from 256 by four units per field, then
holds ground during fields 64..71; expiry occurs once at 72 fields. Recovery's
per-pass motion resets deliberately do not reset this separate timing state.

`HDPRES01` identifies two overlay words (remaining fields, last published count)
and two recovery words (age fields, active). Phantom crash expiry uses the same
overlay-start helper when the motion gate is compiled, avoiding overlapping
patches. Start helpers preserve X; the overlay update reproduces native SUBQ's
cleared X before loading the mode byte.

Evidence: `s4-presentation-long` and `s4-presentation-reference` match all 144
sampled player states through crash replay and recovery. Recovery flag/phase,
overlay count/mode and replay-request bytes also match at every sample; phases
0..8 are represented. This is the constant-input fixture, not the full driving
tape. `s4-presentation-math` executes the actual helpers on private state:
271 recovery transitions and 1125 overlay updates pass, covering T=0 through
T=1, initialization once, expiry once and the ground-height hold.
`s4-presentation-off` passes all disabled ranges. The normal build remains
byte-identical and the direct-branch audit passes 67 declared ranges.

Without VERIFY_TIME_DISPATCH these hooks consume diagnostic constant intervals.
The dispatcher supplies per-substep recovery time and per-frame overlay time,
shortened on an overlay restart to exclude preceding substeps. Live fractional
recovery/contact acceptance, replay duration and other presentation loops remain
unvalidated. Step 4 is still in progress.


## Live elapsed-time dispatcher (development gate)

`VERIFY_TIME_DISPATCH` requires the motion, traffic and presentation gates (and
therefore TIME_SCALARS/TIME). CUSTOM1 and the SPS0126 size check still control
installation. `HardDrivinDispatch.s` consumes the elapsed active fields captured
at `$10ed4`, in substeps of at most eight fields. It repeats crash countdown,
recovery, scene preparation, traffic and physics, then draws once. Work done
inside a frame becomes elapsed time for the next frame; no moving deadline is
chased within the current frame. A zero-field first pass uses T=0, without
inventing a bootstrap interval. Native unscaled discrete events can still run
in that pass; this is not yet full zero-time world-state invariance.

The first controls call runs native keyboard/gear/menu handling. A hook after
keyboard processing latches buttons and steering X. Later substeps apply only
the held continuous throttle ramps against live crash/timeout/start gates;
steering reads the held X instead of VBL-updated input. They do not clear new
VBL button events or call the keyboard/gear/menu handlers again. Pause/options
and replay retain the existing timing-epoch suspension. Their full input and
modal-transition acceptance still needs coverage beyond the captures below.

`HDDISP01` identifies the following private state: pending fields.l, consumed
fields.l, total substeps.l, frame substeps.l, frame elapsed fields.l, explicitly
discarded fields.l, active.b, first-controls.b, held buttons.w, held X.w,
installed.b, padding.b, overlay interval.l (36 bytes). Race exit cancels remaining
frame debt into the discarded counter. This cancellation path is not yet exercised
by the short live captures. While installed, the slave bypasses CUSTOM2's delay;
CUSTOM1 off or an unsupported executable leaves that behavior unchanged.

`VERIFY_DISPATCH_NATIVE` forces one eight-field step per outer pass solely for
compatibility testing. `s4-dispatch-native-final` matches all 144 sampled car
states from `s4-presentation-reference`, including crash replay and recovery.
This remains the constant-input fixture, not the required full driving tape.

Live captures verify each consumed interval is 0..8 fields, T is interval/8,
and pending plus consumed equals observed fields, with zero discarded time:

- `s4-dispatch-filtered`: 150 substeps across 37 outer frames, 1045 fields,
  maximum six substeps/frame, 37 live keyboard calls and 36 completed draws.
- `s4-dispatch-final`: the field-indexed driving tape, 250 substeps across 81
  frames, 1732 fields, maximum six substeps/frame, 81 live keyboard calls and
  80 completed draws. Every substep within a frame retains the same input.
- `s4-dispatch-ready`: final installed-version CUSTOM2 gate, 250 substeps across
  82 frames, 1732 fields, maximum six substeps, 82 live keyboard calls and 81
  completed draws. The tape exercises 13 distinct held button/steering pairs.

Captures stop after physics in the last frame, before its draw, hence one fewer
completed draw. Replay calls are counted separately by the suspended epoch.
The initial unfiltered input-count assertion included one replay controls call;
it was not evidence of repeated live input. The initial installer stack error
in `s4-dispatch-native`/`s4-dispatch-live` prevented gameplay; those runs are invalid
and their owned processes were stopped. Fixed runs use fresh capture directories.

`s4-dispatch-ready-off` verifies all disabled ranges, the normal slave is unchanged,
and the direct-branch audit passes 71 ranges. This establishes dispatcher
mechanics, not equal-time driving acceptance or a performance result. Checkpoint
side effects, timed replay/Phantom history and playback, attract
and menu timelines, zero-time/contact transitions, full forced-native tape,
multiple-machine handling/performance and the human laps remain required.


## Start and score cadence

The dispatcher now also installs `HardDrivinEvents.s`. Native start-phase
increments at `$db40` occur once per eight eligible elapsed fields. Phase 1
is still the discrete start-input event; phase 6 still enables throttle, and
phase 7 still ends the sequence. Carry survives smaller updates. Every native
phase reset/restart clears the companion, including same-value writes at new
race, recovery and Phantom entry.

Score updates at `$db1e` also occur once per eight eligible elapsed fields.
The actual native instructions and `$2c14` packed-decimal addition are retained.
In particular, the MPH shift supplies X, and the add routine's CLR does not clear
it; its input can contain nondecimal nibbles. Treating the operand as an ordinary
integer and fractionally adding it would silently change those semantics.
The chosen conversion samples the native score event at an eight-field cadence,
rather than inventing fractional BCD arithmetic. Native score/lap reset sites
clear score cadence carry; recovery pauses eligibility but retains that carry.
This does not alter the VBL-driven lap or remaining-time arithmetic.

Each slot holds a field remainder.w, charged-this-substep.b and padding.b;
`HDEVENT1` precedes the score slot and start slot (eight bytes total). A second
scene-preparation visit within one elapsed substep cannot charge either slot
again. The dispatcher clears charged flags when selecting the next substep.
Outside live simulation, existing native behavior is retained pending conversion
of the other timelines. VERIFY_DISPATCH_NATIVE executes every original visit,
including duplicates, so its comparison measures native behavior faithfully.

Evidence:

- `s4-events-native`: all 144 car states, four score bytes, start phase and
  throttle-enable flag match `s4-presentation-reference`, including recovery.
- `s4-events-live`: 121 eligible score visits produce 104 score events, and 14
  eligible start visits produce 12 phase events. All captured carries/phases
  match their elapsed intervals; 41 visits use fractional T. Score remains
  unchanged when no event is due. This does not independently validate each
  live BCD addition, which still executes the native routine.
- `s4-events-a1200`: on the 68020, 40 score visits produce 17 events and
  13 start visits produce six events. All 53 visits use fractional intervals
  and pass the same memory-based cadence checks.
- The same build executes 72 private cases spanning every remainder0..7 and
  interval0..8. Each case verifies its event/remainder, a duplicate visit with
  no additional time, and another visit after clearing the substep flag.
  The A500 live window has no duplicate eligible visits; duplicate coverage
  here is private-state evidence, not a live collision assertion.
- `s4-events-off` checks all inactive ranges. The normal binary remains identical;
  the direct-branch audit now covers 79 ranges.

Long intervals now produce `floor((carry+fields)/8)` events, retaining a
remainder0..7. The addition uses a longword, including fields65535 plus carry7.
Repeated scene visits still charge no additional time. Score repeats the native
packed-decimal routine once per due event, sampling the current speed for those
events. Start phases advance by the due count and saturate at seven; crossing
six in the same update still reaches the native throttle-enable branch.

The expanded `VERIFY_EVENTS_MATH` fixture covers 128 cadence cases (including
intervals9,15,16,255,32768,65528,65535), duplicates and the next update, plus
54 start-phase cases. In `s4-events-wide-count`, the A500 produces 278 actual
native score calls across 231 eligible visits, including 54 visits with multiple
calls. All counts equal the elapsed cadence; 18 start visits and two duplicate
visits also pass. The 68020 run `s4-events-wide-020` produces 124 native score
calls across 323 visits, plus 31 start visits and one duplicate. Its 354 combined
visits all use fractional intervals. These tests verify event count and phase,
not a new independent model of the native packed-decimal result.
Forced-native `s4-events-wide-native` matches the reference's 144 car states,
score values and start/throttle flags. `s4-events-wide-off` passes inactive patch
checks; the ordinary build remains byte-identical. Other per-pass timelines
remain open.

This closes the two identified D960 per-call counters. It does not close the
checkpoint/tunnelling audit, replay sampling/playback, Phantom, attract/menu
clocks, performance or full-tape/cross-machine/human acceptance.


## Replay playback clock and interpolation (development gate)

`VERIFY_TIME_REPLAY_TIMING` requires the dispatcher and CUSTOM1. It currently
converts playback, its effect animation/RNG and replay overlay lifetime. Add
`VERIFY_TIME_RECORD` for fixed-field recording, described below. Without that
additional gate, record generation still runs per eligible simulation call and
history duration remains frame-dependent.

A second VBL counter advances while gameplay timing is suspended for replay, but
freezes during native pause/options-menu handling. At native
playback entry `$10bb0`, the hook stores that counter, the oldest valid native
record pointer and the native valid-entry count. Playback age is the unsigned
field difference. Each frame selects age/8 and age%8, interpolates that record
and its successor, and lets the original camera, audio and rendering code consume
a scratch record. The final entry holds until the end of its eight-field interval.
The native button-abort check remains in the loop. Exit occurs after the first
completed draw that reaches count*8 fields, so overshoot is at most that draw's
elapsed interval. No gameplay debt accrues during this suspended epoch.

The 158-byte format is unchanged: player X,Z,Y, three angles, packed engine/flags,
then 12 traffic X,Y,Z/angle tuples. X/Z interpolate as unsigned words; height is
signed. Angles take the shortest arc modulo 1440. Engine pitch interpolates its
low 12 bits, retaining the older record's high flag bits until the next endpoint.
Weighted endpoint arithmetic avoids signed-difference overflow at word extrema.
Exact endpoints copy all 79 words verbatim, preserving native angle encodings.
`HDRPLAY1` precedes wall fields.l,start fields.l,age fields.l,oldest pointer.l,
valid count.w,paused.b,padding.b, last effect phase.w,target effect phase.w,
two cached RNG return longs, and the 158-byte scratch record (32-byte state).

VERIFY_DISPATCH_NATIVE advances the cursor by eight fields per completed draw,
retaining one original record per draw for compatibility checking. Normal elapsed
mode does not impose a replay FPS or a host-time wait. VBL timing preserves the
native interrupt CCR/X handling established by the earlier observer.

Evidence:

- `s4-replay-playback`: a complete A500 replay, 90 history entries and a 720-field
  target. It draws 87 frames (71 fractional) and exits at age725, five fields
  beyond the target within its final eight-field draw. Every rendered scratch
  word matches an independent interpolation model of the retained native ring.
- The build executes nine private full-record cases (711 words) covering both
  exact endpoints, seven fractional positions, unsigned coordinate and signed
  height extrema, angle wraparound/ties and packed engine flags.
- `s4-replay-native`: all 144 car states remain equal to the native reference
  through the constant-input crash/recovery window. This is not a full-playback
  comparison because that input can skip replay.
- `s4-replay-effects-020`: full 68020 playback draws 313 frames (273 fractional)
  for 90 entries and exits at exactly720 fields. All pose words and 100 effect
  sprite pointers pass; the native RNG is called exactly52 times.
- `s4-replay-effects-native`: the constant-input crash fixture yields77 valid
  entries. Forced-native playback draws all77 verbatim, exits at age616, executes
  26 effect frames and 52 RNG calls. This validates endpoint playback against
  its retained history, not a full unmodified-render pixel comparison.
- `s4-replay-pause-constant`: final A500 build, 85 entries,61 draws (51 fractional),
  target680 fields and exit681. An input-only SPACE pair holds native pause for
  40 VBL fields; the presentation clock is identical in all40 samples. All poses,
  19 effect sprite pointers and 52 RNG calls pass. End-of-replay images from the
  native and68020 runs were inspected for visible rendering corruption.
- `s4-replay-final-off` passes inactive-range verification. The normal build
  remains identical. The direct-branch audit includes85 ranges.

The separate recording gate below retains fixed eight-field spacing and handles
collision rewind/replacement. Both gates are required for a fixed-duration history.
The last-26-entry effect now selects its sprite from the elapsed record index.
Two native RNG calls are made per effect phase, cached across repeated draws;
skipped phases and an invisible final tail are consumed too. Thus a naturally
completed full effect uses52 native calls at every tested rendering rate. Abort
still avoids future events. Captured RNG seeds are zero, so this proves cadence
and native-call reuse, not a distribution test on nonzero seeds. The one-shot
sound remains native.

The initial68020 playback capture stalled after516 draws while the per-draw
animation could run outside its sprite table; it is invalid. The corrected
elapsed effect removes that counter walk and completes the faster-machine run.
Two field-indexed A500 input runs never reached the replay anchor after code
changes; they were stopped by their owned PIDs and are not validation evidence.
The constant-input fixture now honors VERIFY_TIME_REPLAY's button release at
controls calls as well as VBL, allowing a reproducible real crash/full replay.

Full native driving-tape and modal,
performance, machine-to-machine handling and human acceptance remain outstanding.

Replay overlays now consume the presentation-clock difference since playback
entry or their most recent restart/update. The clock is sampled once before
updating the previous timestamp, so a VBL between instructions is not lost.
Unsigned subtraction handles wraparound; intervals saturate at 65535 fields before
entering the word-sized countdown. A repeated update in the same field consumes
zero time. Forced-native verification retains eight fields per draw. Other
non-gameplay loops still use the old fallback and remain open work.

`s4-replay-overlay2-a500` passes nine private elapsed/countdown cases (including
wraparound, duplicate updates, zero and long intervals) and all 711 pose words.
Its full 85-entry replay draws 61 frames, exits at exactly 680 active fields, and
holds the presentation clock for 40 paused fields. All 52 RNG calls and 18 effect
sprite draws pass. `s4-replay-overlay2-native` preserves 77 endpoint frames,
616 virtual fields, 26 effect draws and 52 RNG calls; its private overlay cases
retain the native eight-field consumption. These captures do not establish a
live nonzero overlay's full lifetime during replay; the countdown evidence uses
private state and the same arithmetic helper. Native replay usually begins after
the crash overlay has expired.

The first overlay test fixture attempted privileged interrupt masking and failed
to reach gameplay. Those captures were stopped and excluded. The repaired fixture
uses a private clock slot, does not alter the live presentation counter, and does
not mask interrupts. The final CUSTOM1-off window passes inactive-range checks;
the ordinary build remains byte-identical to the baseline.


## Intermediate scene preparation (development gate)

`VERIFY_TIME_SCENE_CULL` requires DISPATCH and the usual CUSTOM1/SPS0126 gate.
It skips visible objects from the native `$0b09e` and `$0b10c` list loops only
when the dispatcher is active, more substeps remain, the race is still active,
and object byte34 is zero. Byte34 selects the non-clipping `$09aec` projection
path; objects taking `$0a194`, including its `$09b22` contact side effects, remain
fully processed. Terrain `$0b07a`, traffic and visibility also remain native.
The final substep, replay and presentation loops perform full preparation.
Race-exit passes retain full preparation because cancellation can make them the
last pass even when the dispatcher still holds pending fields.

The skipped pair is `$097dc` object/camera transformation followed by `$09aec`
projection. Its outputs are rendering vertices and object buffer pointers. The
near-object branch additionally extracts contact/obstacle flags consumed by
physics, so it cannot be omitted. Buffers may be compacted differently during
intermediate steps; consumers use each processed object's updated pointers.
`HDSCENE1` publishes two unsigned long counts of skipped visible objects, for
the auxiliary and main lists. Diagnostic increments preserve the native X flag.

`VERIFY_SCENE_TWIN` compares the candidate with full native preparation at the
same scene state. At `$0b142`, before the preparation tail, it calls the original
preparation with filtering disabled. The nested call returns before that tail,
so its audio/off-road events do not run twice. Read-only captures compare the
before/after states, and full reference buffers remain for physics. This fixture
is correctness evidence, not a performance build. `HDSCTWN1` publishes the nested
reference stage; the exact listing locates its two capture markers.

`s4-scene-twin2` passes 100 pairs, including 25 during crashes: all 10,900 object
metadata records, 211 near-object instances / 9,209 transformed vertices, the
three contact flags, player state, score/start state and replay write pointer
agree. It skips 981 visible main-list objects. No auxiliary-list object was
skipped in this capture, so that branch still lacks live skip coverage. The
comparison excludes lap clocks, which legitimately advance in VBL while the
reference preparation runs. An earlier comparison incorrectly included those
asynchronous clocks and failed; the retained data passed after correcting that
scope. The conservative race-exit bypass was added after this twin capture;
live race-exit cancellation coverage remains outstanding.

The 144-state forced-native car comparison passes with the installed scene gate;
it proves the normal one-step path, not general equal-time handling. Ordinary
build output remains unchanged, inactive ranges pass with CUSTOM1 off, and the
branch audit covers 88 ranges including the twin hook. The guarded 500-field
candidate improves the unfiltered dispatcher window from 15 to 23 swaps, but the
3% FPS-loss requirement is still not met. Full driving-tape equivalence,
loop/jump/contact at both T extremes, cross-machine handling and human acceptance
remain open. This development gate is not a completed renderer optimization.


## CPU policy and long-interval arithmetic (in progress)

The target policy is one full elapsed-time physics update per rendered gameplay
frame on the 68000. On 68020 and above, physics also runs on every frame while
rendering runs as fast as possible: a one-field frame uses T=1/8, allowing 50 FPS.
Only frames exceeding eight fields require additional bounded substeps on those
CPUs. The native 6.25 Hz reference defines the scaling unit, not an update-rate
limit. The current dispatcher still bounds every CPU to eight fields; the 68000
policy has not yet been connected or validated.

The shared `_time_scale_word` and `_time_scale_q16` helpers now accept unsigned
field counts through 65535 and return signed-long increments. Their existing
0..8-field arithmetic is retained. The long-interval word path avoids DIVS's
signed-word quotient limit. The Q16 path separates whole and fractional parts
before scaling, avoiding overflow of a full Q16 intermediate. Signed remainders
still use truncation toward zero. Q16 rate inputs retain their documented
magnitude limit of 16383; these helpers alone do not make their callers safe at
large T.

`VERIFY_TIME_MATH` includes a private `HDWIDE01` fixture: 300 cases across signed
rate extrema, field counts 0, 1, 7, 8, 9, 15, 31, 255, 32768 and 65535, and both
signs of the maximum permitted carry. The independent integer model passes these
cases, the existing 1215 eighth-step cases, 441 Q16 cases and 11 debt cases in
`s4-time-wide-fixed`. The 144 sampled car states in `s4-wide-native` match
`s4-presentation-reference` at forced T=1. This remains the constant-input car
fixture, not full driving-tape or world-state equivalence. The ordinary build is
byte-identical to the baseline.

Before accepting the experimental 68000 policy, complete the velocity-write
audit and full gameplay validation. Audit narrowing stores in callers as well as helper arithmetic. Large-T
contact, checkpoint and handling validation, and the A500 performance gate remain
required. No updated FPS claim follows from this arithmetic change.


### Decay and angular contact at longer intervals

`HardDrivinDecay.s`, included by TIME_SCALARS, supplies Q16 coefficients for
throttle retention (7/8), spin retention (9/10) and angular contact (3/4).
All 1929 stored word coefficients are independently rounded from the exponential
function. The lookup accepts unsigned field counts through 65535 and returns
65536 explicitly after the remaining fraction rounds to zero: field706 for
throttle, 895 for spin, and 328 for contact. This avoids wrapping table indices
or interpreting a full coefficient as a zero word. Existing T=1 integer paths
remain intact. Throttle and spin clear their fractional state at full loss.

For angular contact above eight fields, correction uses the rounded gain and
feedback uses rounded Gain/T. The feedback coefficient error is bounded by
0.5+4/fields Q16 units, less than one unit throughout that interval. Signed error
products and full-gain handling avoid signed-word multiplier overflow. This
extends the response helper only; subsequent rate integration and position
products still require a separate large-T audit.

Validation in `s4-decay-wide` compares all 1929 loaded table words with a
60-digit decimal model and executes 72 boundary lookups, including unsigned
32768 and 65535. `s4-retention-wide` and `s4-spin-wide` each pass 595 actual helper
cases covering signed carries and full-loss boundaries. The latter also passes
all existing motion arithmetic cases. `s4-contact-wide` passes 216 longer-interval
response cases plus the existing 162 response, 189 projection, 135 pitch and
45 roll cases. These private-state checks do not prove large-T road handling.

The 144 forced-native car states in `s4-decay-native` match the reference;
`s4-decay-off` passes disabled ranges, the branch audit passes, and the ordinary
build remains byte-identical. The current dispatcher still restricts gameplay
steps to eight fields on every CPU. Performance and the requested 68000 policy
remain unverified until the remaining integration work is complete.


### Ordinary position integration at longer intervals

For intervals above eight fields, ordinary position and its fractional
projection now use a signed 64-bit intermediate on the 68000. The shared
`_time_product_s32_u16` multiplies a signed long by an unsigned word without
68020 instructions. Final position increments remain signed longs. Shorter
intervals retain the existing arithmetic.

The integer numerator is `64*(v-u) + 8*fields*(v+u) + carry`, divided by128 with
truncation toward zero and a signed remainder. This is algebraically identical
to the existing Euler correction, but avoids overflow in the word factors and
32-bit intermediate at large intervals. The fractional projection computes
`floor((8*(v-u) + fields*(v+u))/16)` in Q16 before adding its retained fraction.
For the documented input bounds, both final results fit their existing types.
The live consumers add the returned integer increments to long positions.

`VERIFY_POSITION_WIDE_MATH` tests the actual helpers in private memory. Evidence
`s4-position-wide-final` passes 1029 integer position cases, 1029 fractional
projection cases and 54 signed-long multiplication cases, including unsigned
field counts32768/65535, velocity extrema, negative results and both signs of
fractional carry. `s4-projection-wide-regression` passes all60 projection and
1323 short-interval Euler cases. `s4-position-short-regression` passes the
existing motion suite, including1323 ordinary and405 falling position cases.
The ordinary build remains byte-identical.

These changes do not yet enable longer gameplay updates. Contact-rate
integration, narrowing writes, traffic route traversal and event
multiplicity still need their own audit and extensions. Algebraic equivalence
and arithmetic bounds do not establish collision or checkpoint correctness at
large T; that gameplay validation remains required before acceptance.


### Falling displacement at longer intervals

The falling-position helper now uses a signed 64-bit numerator above eight
fields. It evaluates `-n*(16*v+2*fraction)-a*n*(n-8)+carry` before dividing by128.
The numerator supports signed-word velocity and acceleration and unsigned-word
elapsed fields without intermediate overflow. The returned increment is the
low32 bits of the truncated quotient, matching the coordinate's native ADD.L
representation; the fractional remainder retains the sign of the full numerator,
even if the quotient wraps that coordinate range. Short intervals keep the
existing path.

Acceleration cannot be treated as a constant five: inverted contact computes
its sample at `$0cca6..$0ccc6` from the native speed-dependent function. The test
therefore includes the full signed-word acceleration extrema, both signs of
2340 and ordinary gravity cases. `VERIFY_FALL_WIDE_MATH` publishes private
`HDFPWID1` results; `s4-fall-wide-full` passes all2205 combinations of velocity,
velocity fraction, acceleration, elapsed fields and signed position carry.
`s4-fall-short-regression` passes the existing motion suite, including405 falling
position and81 falling-velocity cases. The ordinary build remains unchanged.

This proves the displacement calculation, not the safety of arbitrarily large
physical steps. The live fall-velocity word writes and the impact/landing paths
still require validation with the eventual 68000 dispatcher. Contact-rate
integration, angular/velocity narrowing, traffic, discrete events and replay
sampling remain unfinished for longer intervals.


### Control-ramp saturation at longer intervals

Throttle remains a native byte with limits0..100. For intervals above eight
fields, its helper now adds the full signed-long increment, clamps to those
limits, and only then stores the byte. The existing outward-fraction cancellation
and native caller checks remain. This prevents an increasing throttle from
wrapping negative before its upper-limit check, or decreasing throttle from
wrapping positive. The short-interval path is unchanged.

RPM scales its450-unit native slew limit and compares that full signed-long
increment with the signed target distance. A word comparison was insufficient
once the scaled limit exceeded32767; it could choose a wrapped increment instead
of reaching the target. Target-reaching updates still clear the fractional
remainder, and gear/current-value mismatch still invalidates stale fractions.

`VERIFY_RAMP_WIDE_MATH` calls the actual helpers on private globals. The retained
`s4-ramp-wide` evidence passes16 throttle cases and18 RPM cases, including both
directions, saturation, signed carries, intervals32768/65535, target crossing and
state/gear mismatch. `s4-ramp-native` matches all144 constant-input reference car
states at forced T=1, and the ordinary build remains byte-identical. This is not
full driving-tape or equal-elapsed-time acceptance. Contact-rate integration,
angular/velocity narrowing, traffic, multiple events and replay sampling still
precede enabling the requested 68000 update policy.


### Angular integration at longer intervals

Native yaw/pitch/roll normalization at `$0b44e..$0b4a2` adds or subtracts only one
1440-unit revolution. For intervals above eight fields, the ordinary angular-rate
helper now normalizes the full signed-long sum of current angle and increment
before publishing its word result. Returning the difference from the current
angle preserves the caller's native ADD.W interface. The signed Q16 fractional
remainder is retained independently. Short-interval behavior is unchanged.

Roll/pitch contact-rate integration similarly uses the full signed64 product of
the Q16 rate and elapsed fields. It divides by8, adds the previous fractional
carry, then extracts the whole increment and signed remainder. Only the complete
angle is reduced to[-720,720] before the word store; the integrated Q16 value is
never forced through a 32-bit intermediate. This avoids both Q16 overflow and
incorrect wrapping at65536 rather than at1440. The previous scale/add helpers
remain the short-interval path. Existing mismatch and native +/-1440 wrap rules
still determine when an old fraction is valid.

`VERIFY_ANGLE_WIDE_MATH` exercises the actual combined helpers on private state.
`s4-angle-wide` passes96 contact-rate cases,92 ordinary rate cases and19 full-long
normalization cases, including multiple revolutions, signed fractional carry,
unsigned65535 fields, stale-state invalidation and LONG_MIN/LONG_MAX. The fixture
input macro produces the same binary as its expanded data. `s4-angle-native`
matches all144 reference car states at forced T=1; the ordinary build is unchanged.
These checks establish arithmetic and native-step compatibility, not large-T
loop/jump/collision handling. The separate experimental CPU dispatcher permits
long 68000 steps; velocity writes and full gameplay validation still need attention.


### Traffic acceleration at longer intervals

Traffic acceleration now adds and clamps the full signed-long increment before
publishing the native speed byte. Its original terminal-speed grid remains
`ceil(target/acceleration)*acceleration`; an actor already above that limit is
not slowed by this helper. Initialization still consumes exactly one native
step, even when the current diagnostic interval is zero or very large.

`VERIFY_TRAFFIC_SPEED_MATH` executes18 private cases in `s4-traffic-speed-wide`,
covering unsigned32768/65535 fields, negative speeds/fractions, stale-state
invalidation, saturation, overspeed, zero acceleration and initialization.
`s4-traffic-speed-regression` passes the existing50 reversal cases and the
initialization/zero-time checks. The ordinary build remains unchanged.

Long-interval progression now uses a signed-long displacement and traverses all
200-unit boundaries in the computed displacement. The wide calculation applies when the interval exceeds
eight fields or a fractional coasting remainder survives from an earlier update.
For new/old speeds `v/u` in eighths and interval `n` fields, the uncapped numerator
is `n*(v+u)+8*(v-u)`, divided by128. When a long interval reaches its speed cap
partway through, it becomes `2*n*v-(v-u)^2/acceleration+8*(v-u)`. This integrates
acceleration up to the cap and coasting afterward while retaining the Euler bias.
The native T=1 expression remains unchanged.

SPS traffic acceleration is0..3; a denominator of768 represents the half/third
terms exactly. The existing companion at+6 retains its signed /128 remainder,
and+12 holds a signed -5..5 sub-remainder in /768 units. Reset and unexpected
phase writes clear both. Longword multiplication and two unsigned word divisions
avoid signed-word overflow in the displacement. Short steps consume any retained
sub-remainder consistently; no fractional time or movement is discarded.

The walker applies the native `$cf02..$cfe4` next-segment rules between crossings:
main-route wrap, both branch entrances and both alternate-route exits. It updates
the native pointers using the direction and invalidates the geometry cache for each crossing.
It preserves the native negative-progress rules as well. Acceleration and geometry
preparation are not repeated for intermediate segments. The final phase is0..199,
so the native single-wrap tail does nothing for these already-normalized updates.
Short updates without a sub-remainder continue through the original tail.

Evidence:

- `s4-traffic-phase-wide`: 504 cases agree with an independent rational integration
  model, including126 capped/coasting cases, signed carries, negative velocities
  and unsigned65535-field intervals. The largest absolute displacement is1,055,728
  phase units, beyond a signed word.
- `s4-traffic-route-fixed`: 96 synthetic route cases match the game's actual
  instruction ranges, copied into private verification storage. Cases cover both
  directions, main-route wrap, junction preferences and alternate-route exits,
  with up to nine crossings. The fixture supplies a JMP stub for the native
  multiply entry; an earlier fixture with a pointer there stalled and is excluded.
- `s4-traffic-route-live`: all1440 A500 updates agree with the memory-based model,
  including1428 wide updates,11 cap/coast transitions and136 route crossings.
- `s4-traffic-route-020`: all1440 updates agree on the short path, including1254
  fractional updates and34 crossings.
- `s4-traffic-route-slow`: adding255 rendering fields per frame produces144 checked
  updates, including114 that cross multiple segments (maximum four). All294
  crossings, speed/carry values and route pointers match the model.
- `s4-traffic-route-native`: all1440 before/after traffic records and their poses
  are byte-identical to `s4-traffic-reference`, including92 crossings. Its native
  phase arithmetic also passes the existing model.

An in-frame turnaround now splits route traversal at the minimum displacement.
For acceleration `a` and initial full speed `u`, the biased displacement before
capping is `(2*u*t+a*t*t+8*a*t)/128`. Its minimum is at `t=-u/a-4`, when that
point is inside a long interval. `_traffic_turn_min` computes the corresponding
integer displacement, including the original fractional carry; `_traffic_route_motion`
walks backward to that minimum, then forward to the final displacement. Only
the final integration remainder is retained. The native short-step path remains
unchanged. This preserves intermediate junction choices hidden by net movement.

For example, full speed -175, acceleration1 and410 fields reaching cap72 produce
zero final integer displacement but a -228-unit minimum. Starting at phase100
therefore crosses a boundary backward and then forward. The final route state
can differ from simply leaving the car in place, particularly at branch endpoints.
The walker retains the native route rules, including their reverse-travel behavior.

`s4-traffic-turn-final-math` passes768 displacement and minimum cases, including
135 cap/coast cases and46 nonzero minima. Cases include short-step compatibility,
near-zero reversals, signed carries and65535-field intervals. The prepared zero-net
trajectory above is among them. `s4-traffic-turn-final-route` matches native
instruction sequences for126 route cases, including30 backward/forward cases.
Six start with already-normalized edge pointers and zero net movement; all six
change route state under the ordered native crossings (three change the current
segment, while the others change the pending next pointer or route mode).

`s4-traffic-turn-live` passes all1440 live A500 updates, including1416 wide updates,
10 cap/coast transitions and136 crossings. This live run contains no in-frame
turnaround: turnaround evidence is the private arithmetic and native-instruction
comparison, not an observed player/traffic collision. `s4-traffic-turn-off` passes
inactive ranges; the ordinary slave is unchanged and all91 branch ranges pass.
Collision safety, rendered-pose equivalence at equal elapsed time and full
cross-machine handling/performance acceptance remain unproven.


### Experimental CPU-specific dispatch

`VERIFY_DISPATCH_CPU` (requires TIME_DISPATCH, still gated by CUSTOM1) queries
WHDLoad AttnFlags at installation. Pre-68020 CPUs consume the full frame interval
in one update; 68020+ retain the eight-field substep bound and update on every
rendered gameplay frame. Forced-native verification takes precedence. The
unsigned-word scalar interface accepts at most 65535 fields; larger intervals
fall back to bounded steps and increment a diagnostic counter, retaining time.
This guard is not acceptance of oversized frames under the one-update policy.
`HDCPUP01` exposes the query tag, flags, terminator, selected policy word, padding
word and oversized-fallback longword. Neither measured run used that fallback.

The initial 500-field (10.01594-second) constant-input diagnostic, before the
long-event extension above, produced:

| Run | Swaps | Physics calls | FPS | Mean frame ms |
| --- | ---: | ---: | ---: | ---: |
| s4-cpu-policy-off, A500 | 38 | 38 | 3.794 | 263.577 |
| s4-cpu-policy-a500, A500 | 39 | 39 | 3.894 | 256.819 |
| s4-cpu-policy-020, 68020 | 148 | 148 | 14.776 | 67.675 |

The A500 consumed 11..15 fields per noninitial update in one step. The 68020
consumed 2..5 fields, also one step per frame. These are diagnostic timings,
not the full gameplay baselines or proof of the 3% acceptance gate: simulation
progression differs, the 68020 window includes 22 crash fields, and long-frame
that build lacked complete traffic progression and replay recording. No 50 FPS
claim follows from
these runs. CPU selection and removal of extra A500 physics passes are verified.


### Integrated timing diagnostic

The integrated build at `d48ae05` enables scalar/motion/contact, traffic, CPU dispatch,
replay recording/playback, presentation timelines, attract, Phantom ghost paths,
instructions, off-road audio and long-step dissipation. Private math and synthetic
entry fixtures are excluded. The render-only intermediate scene-culling experiment
is not enabled. All runs use the same constant-input fixture and500 PAL fields
(10.01594 seconds); the off control is the same slave with CUSTOM1=0.

| Run | Swaps | Physics / render calls | FPS | Mean frame ms | Crash fields |
| --- | ---: | ---: | ---: | ---: | ---: |
| s4-all-current-off, A500 | 38 | 38 / 38 | 3.794 | 263.577 | 0 |
| s4-all-current-a500 | 37 | 38 / 38 | 3.694 | 270.701 | 21 |
| s4-all-current-020 | 148 | 149 / 149 | 14.776 | 67.675 | 27 |
| s4-all-current-040, 25 MHz | 240 | 241 / 241 | 23.962 | 41.733 | 22 |

The A500 draw interval is11..22 fields after the initial zero interval; the020
uses2..4 and the040 uses2..3. Every active frame uses exactly one physics step;
all oversized-fallback counters stay zero. Calls and swaps differ by one when a
submitted or in-progress frame crosses the window boundary. CUSTOM1-off passes
all144 declared patch ranges with only DRIVE and STEPINPUT enabled.

The A500 swap rate is2.63% below its control, but this does not close the3% gate:
the enabled runs reach a crash absent from the original window. These are neither
the established A/B gameplay windows nor identical-scene overhead measurements.
At field300 the enabled A500/020/040 have X27860/27871/27865 and speed317/317/316;
at field450 they have X29010/29093/29084 and speed373/368/368. VBL samples observe
the most recently completed updates at different phases, so these values require
frame-age-aware analysis before they can establish an equal-time tolerance.
The original still advances by rendered frames and is intentionally not an
equal-real-time trajectory reference. Full handling/performance acceptance remains open.


### Fixed-field replay recording (development gate)

`VERIFY_TIME_RECORD` requires TIME_REPLAY_TIMING and CUSTOM1. It installs
`HardDrivinRecord.s`, retaining the native 90-by-158-byte format but recording one
sample every eight eligible simulation fields. A full ring represents 720 fields
of playback at every rendering rate. The first eligible pose is sampled at age
zero. D960 observes the start of the physics step, so each consecutive visit
charges the previous step's elapsed fields. Missing eligible visits freeze this
history clock and establish a new pose endpoint rather than interpolate a gap.
The native ring reset also resets the companion state.

Each update captures the native player/traffic pose into private storage, then
interpolates every sample boundary covered by the interval. Position interpolation
uses unsigned X/Z and signed Y, angles take the shortest 1440-unit path, and the
engine's low 12 bits interpolate while high flags hold until the endpoint.
Endpoints copy verbatim. Weighted sums and unsigned division support intervals
through 65535 fields; biasing signed values by 32768 gives exact floor division
without signed multiply/divide overflow. This produces linear pose samples between
physics updates; it cannot reconstruct unsimulated contact within a long update.

The transaction remembers its original ring pointer, phase and previous pose.
A repeated scene visit at the same dispatcher step replaces all samples emitted
by that transaction. The collision rewind at `$89b4` therefore does not rewind
older history when no sample was due. Replacement does not accrue elapsed time
again. Counters distinguish newly emitted and replaced samples. `HDRECRD1` precedes
32 bytes of state, followed by previous/current 158-byte poses. The state contains
step stamp, original write pointer, eligible age, emitted and replaced longwords;
phase, saved phase, charged interval and next interval words; valid/new/first bytes
and padding. The regular build and forced-native dispatcher use native recording.

Evidence:

- `s4-record-wrap`: all 47 live A500 transactions match an independent model,
  including the complete ring and write pointer. Thirty transactions emit multiple
  samples (maximum three); one collision replaces two samples. There are 76 new
  samples over 606 eligible fields. Each captured endpoint is checked against the
  game's player globals and all 12 traffic object poses.
- Private fixtures check 36 full records for intervals 1..8 and 24 records at
  selected fractions of intervals 9, 15, 16, 255, 32768 and 65535. A separate
  transaction emits 91 samples starting at slot 88; all 90 final slots, counters,
  remainder and wrapped pointer match the model.
- `s4-record-wide-020`: 189 live transactions, 79 new samples over 631 fields,
  including one collision replacement; full ring, endpoints and pointer match.
  This run precedes extraction of the shared emission helper used by the wrap test.
- `s4-record-wide-native`: all 144 reference car states, full ring contents,
  relocated write pointers, score and start/throttle state agree at forced T=1.
  This constant-input fixture does not replace full driving-tape equivalence.
- `s4-record-playback`: A500 playback of 76 entries uses 54 draws, including 49
  interpolated draws. All poses match; a 40-field pause freezes the clock. Exit
  age is 616 fields versus the 608-field target (one final-draw overshoot).
- `s4-record-playback-020`: the final implementation plays 80 entries in 224 draws,
  including 200 interpolated draws and a 40-field pause. Exit age is 642 fields
  versus 640. Both playback runs consume 52 native effect RNG calls; every effect
  pose and the nine private overlay cases pass.
- `s4-record-off` passes inactive-range checks; the normal slave remains byte-for-
  byte identical and all 91 patch branch ranges pass.

These runs cover first entry, fractional and multiple emissions, collision
replacement, ring wrap and natural playback exit with pause. They do not yet
validate an eligibility gap, replay abort, every recovery/reset path or the full
cross-machine driving tape. The rendering/handling acceptance remains open.

The final recording runtime's `s4-record-cost` 500-field A500 diagnostic has
37 swaps and 37 physics calls: 3.694 FPS, 270.701 ms per frame. The original
constant-input control has 38 swaps (3.794 FPS, 263.577 ms). This is not final
performance acceptance or an isolated recording-cost measurement: the new run
includes 19 crash fields and also contains the long-event changes absent from
the earlier CPU-policy diagnostic. No oversized-interval fallback occurs.


### Velocity storage audit and controlled braking

The wide scaling helpers do not widen native velocity storage. Forward velocity
G($9928) is still written by ADD.W at `$b8a6`; falling velocity G($990e) is written
by ADD.W at `$ccc6` and ADDQ.W at `$cd82` (replaced by scaled hooks). All static
references in the decompressed disassembly were reviewed:

| State | Other direct writers | Relevant consumers |
| --- | --- | --- |
| G($9928), signed word | Zero at `$59c6`, `$bcc8`, `$bda6`, `$108d8`, `$10a88`, `$11804` | Steering `$b3b2`; velocity projection `$b512`; force/drag `$b6c0..$b840`; speed/RPM `$b8b2`; collision `$bc24`; race/Phantom checks |
| G($990e), signed word | Zero at `$cc90`, `$cccc`, `$108c0` | Height integration `$b5f2`; hard-landing threshold `$cc42` |

Existing initialization, collision, contact and recovery hooks clear the
fractional companions around those reset paths. This static list is not proof
against every possible indirect writer. Several consumers construct 1.5 times
the forward velocity in a word; widening only the integration store would not
make the rest of the native solver support arbitrary larger velocities.

`VERIFY_STEPINPUT_BRAKE=N` adds an input-only diagnostic to VERIFY_STEPINPUT.
It holds throttle until race field N, then holds both buttons (native braking).
VBL publication and controls entry use the same field-indexed input. It cannot
be combined with STEPINPUT_RAMP. No pose, velocity, gear or force is injected.
The existing builds are byte-identical when the new flag is absent.

The 800-field braking captures use N=250. Every observed velocity write matches
its captured rate, field interval and signed carry:

| Capture | Forward updates | Forward range | Maximum interval | Word overflows |
| --- | ---: | ---: | ---: | ---: |
| s4-brake-original, CUSTOM1 off | 66 | 0..191 | Native step | 0 |
| s4-brake-a500 | 61 | -8..282 | 16 fields | 0 |
| s4-brake-020 | 245 | -5..281 | 4 fields | 0 |

The A500 first consumes the brake at captured field262, versus250 on the 68020:
inputs are sampled per frame, so the slower renderer responds later. At field583
the A500 goes from27 to-8 with a12-field interval and rate-23. The recorded force
components are drag1, brake18, slope4 and drive0. It settles at-5. The 68020 reaches
zero at field578 and then also rolls back to-5 under the slope force. The original
stops on flat ground farther back, with slope0. Thus a blanket zero clamp would
remove real slope motion, and these different-scene captures do not isolate a
braking-force error or establish the braking-distance acceptance.

The full field-indexed tape capture `s4-velocity-tape` covers6000 fields with no
STEPINPUT override. It verifies588 forward updates (range0..327, intervals up to
19 fields) and20 falling updates (range4..28, intervals up to12 fields), with no
word overflow. All captured values and fractional companions match the model.
This is writer evidence, not proof that the complete world state follows the
original route or matches other machines at equal elapsed time.

The gated resistance correction below addresses a separately observed long-step
instability; native velocity storage remains unchanged. Safety for arbitrary
unsigned-word intervals is still unproven: for example, scaling rate40
from velocity0 over65535 fields produces327675 before a native word store, which
would wrap to-5. Falling rate5 produces40959 and would also wrap. Safe handling of
such intervals needs a solver/consumer policy, not merely a wider intermediate.
The ordinary slave and the existing CPU-policy runtime remain byte-identical
when the braking fixture is disabled.


### Speed-triggered braking measurement

`VERIFY_STEPINPUT_BRAKE_SPEED=N` requires STEPINPUT and excludes the field-based
BRAKE and RAMP fixtures. It accelerates with the ordinary native controls until
G($9928) reaches N, then latches both buttons through the stop. VBL and controls
publish that held input. The latch resets at the fixture's new race epoch; no
velocity, pose, gear, contact or clock is injected. The test reports threshold
overshoot instead of setting an exact starting velocity.

The integrated build uses N=180 and all current timing features. The capture
observes force-entry and physics-return states, native longitudinal position,
velocity, throttle, contact mask, fall velocity and input latch. Every run stops
twice, remains at Y=0 with unchanged Z and native heading360, stays on-road with
all four contact bits set throughout braking, and has nonnegative forward velocity.
CUSTOM4=4 is restricted to active gameplay using VERIFY_GAMEPLAY_SLOW.

Brake-onset speed alone is not a matched initial state. An initial comparison
from speed175 still contained different residual throttle values and is excluded
as a pure braking-force comparison. The retained comparison instead starts at
the downward crossing of speed100; all measured states from the bracketing
samples through the stop have zero throttle. Long positions are divided by8 to
report native world units. Distances are interpolated between the two samples
bracketing speed100; the raw sample bounds are retained below. They express
sampling uncertainty, not a derived gameplay acceptance tolerance.

| Profile | Actual brake-onset speed | Distance from speed100, estimate | Measured sample bounds |
| --- | ---: | ---: | --- |
| Original A500, CUSTOM1 off | 181 | 193.89 | 191.250..209.750 |
| A500 | 201 | 183.97 | 173.125..200.250 |
| A500 + Fast RAM | 202 | 184.08 | 173.125..200.500 |
| A500, CUSTOM4=4 | 185 | 188.18 | 167.750..203.500 |
| 68020 | 184 | 196.50 | 189.875..196.500 |
| 68030/50 | 180 | 198.25 | 193.625..198.250 |
| 68040/25 | 182 | 197.25 | 195.000..199.500 |
| 68040/40 | 181 | 199.25 | 194.750..199.250 |
| 68060/50 | 181 | 199.25 | 194.625..199.250 |

Captures are s4-speed-brake-original, -a500, -fast, -slow4, -020, -030, -040,
-04040 and -060. Each retains raw entry/return observations, configuration,
slave hash and braking.json; comparison.json is under the A500 run. The original
has no elapsed scaling and reaches the same low-speed stop later in wall time.
No equal-time comparison to its frame-coupled duration is claimed.

The fast-CPU estimates cluster at196.5..199.25 units. The two68000 estimates are
about184 units; the delayed68000 estimate is188.18. The coarse68000 sample bounds
still overlap the fast results, so this measurement alone neither proves precise
braking-distance agreement nor isolates the cause of the estimated difference.
It establishes repeatable flat, zero-throttle braking coverage on all seven
profiles and with slowed drawing. Higher-speed braking, fractional-state-aware
comparison and the units-derived acceptance tolerance remain open.

A stricter monotonic-position check exposed a defect in that build: the020,030 and
060 each move backward by one long-position unit (1/8 world unit) near the stop
while the native speed word remains1. The observed fields are472..473,466 and472
respectively. Wheel mask15, road contact, Y=0, Z and heading360 remain unchanged.
The velocity word never becomes negative. The exact before/after rows are retained
in comparison.json. The correction and focused validation are described below;
the sampling bounds were not used to waive this defect.

The initial analyzer incorrectly assumed straight-ahead heading0. Native race
initialization and every retained sample use heading360 for this straight. The
captures were rechecked with that verified heading, unchanged Z/Y, full contact
and road predicates; no game-state data were changed or omitted. Normal and
existing forced-native slaves remain byte-identical when the fixture is absent.
The original-control capture passes all146 disabled-range checks with only DRIVE
and STEPINPUT enabled; the125-range branch audit also passes.



### Constant-throttle straight measurement

`VERIFY_STEPINPUT_HOLD_THROTTLE=N` requires STEPINPUT and N in1..100, and
excludes the ramp and braking fixtures. It holds accelerator input until native
throttle reaches N, then latches neutral buttons at both VBL and controls entry.
The latch resets at new-race entry. It never writes throttle or dynamics. A coarse
update may overshoot N: use the observed plateau, not the requested threshold.

The threshold22 build holds native throttle22 on all seven machine profiles;
CUSTOM4=4 holds23 and is reported separately. Each fresh-boot capture retains500
fields. The comparison interval is race fields280..420 (2.804464 emulated seconds),
where every completed physics state has fixed throttle, neutral buttons, no brake,
full road contact, heading360, Y=0, fixed Z and zero falling speed. Contact globals
are temporary scratch during physics: VBL observations can see road0, so the
contact predicates use completed physics returns. Raw VBL observations are retained.
The initial always-accelerating trial did not have a constant throttle on the flat
road and is excluded from this measurement.

Distance endpoints are linearly interpolated between completed physics returns
bracketing the selected fields. Bounds use the raw surrounding positions and
express temporal sampling uncertainty, not an acceptance tolerance. Exact endpoint
samples can collapse those bounds without proving physical or integration accuracy.

| Profile | Held throttle | Native speed word range | Estimated distance (world units) | World units/s | Distance sampling bounds |
|---|---:|---:|---:|---:|---:|
| Original A500, CUSTOM1 off | 22 | 202..228 | 486.730 | 173.555 | 460.750..541.375 |
| A500 | 22 | 231..231 | 750.466 | 267.597 | 701.000..836.750 |
| A500 Fast RAM | 22 | 232..232 | 753.721 | 268.758 | 696.000..837.375 |
| A500, CUSTOM4=4 | 23 | 234..234 | 752.216 | 268.221 | 713.500..894.625 |
| 68020 | 22 | 225..225 | 742.000 | 264.578 | 723.625..755.125 |
| 68030/50 | 22 | 225..225 | 738.375 | 263.286 | 738.375..738.375 |
| 68040/25 | 22 | 225..225 | 738.250 | 263.241 | 733.000..743.500 |
| 68040/40 | 22 | 225..225 | 740.500 | 264.043 | 740.500..740.500 |
| 68060/50 | 22 | 225..225 | 738.375 | 263.286 | 738.375..738.375 |

Captures are `s4-throttle22-original`, `-a500`, `-fast`, `-slow4`, `-020`,
`-030`, `-040`, `-04040` and `-060`, with raw `motion.json` and derived
`constant-throttle.json`. A fresh A500 repeat matches all500 VBL and37 completed
physics observations exactly (`s4-throttle22-a500-repeat`). This verifies the
observed fields, not full-memory equivalence. Original frame-coupled motion is still accelerating in
this interval; its lower distance per second is not the target for elapsed-time
scaling. Constant throttle does not imply constant speed.

The held-throttle A500 speed231 versus fast-CPU225 is real in completed states.
Separate force captures (`s4-throttle-force-a500`,26 updates; `-020`,103 updates)
match every native force operand with the independent force model. A500 advances
223 to231 with carry7/8 using rate5 before automatic gear2 changes to3. The020
advances223 to225 with carry4/8. After the shift, both have power5940, drive8,
drag8 and net rate0, preserving the different incoming velocities. Before the
shift, power is8250 and gear2. This identifies a gear-transition overshoot followed
by a native zero-net-force interval; correcting projection alone cannot remove it.
A policy for changes of gear/force during long updates remains necessary, without
adding full physics or scene passes on68000. No handling acceptance is claimed.

The fixture-absent integrated slave and normal8392-byte text output remain
byte-identical. Invalid threshold/prerequisite/conflicting-input builds reject;
CUSTOM1-off passes146 range checks and the125-range branch audit passes.


### Automatic gear transitions within an elapsed interval

The complete engaged drivetrain is now independently modeled against live inputs
in `s4-drivetrain-a500` and `s4-drivetrain-020`. Captures stop at force integration,
after RPM slew, and after gear selection; they write no game state. All26 A500
and102 020 engaged updates match velocity/carry, power, net acceleration,
RPM/carry, last-RPM/gear companion state, and resulting gear. Both upshifts on each
machine match the native ratio conversion. Neutral updates are counted separately
and are not covered by this engaged model.

The native gear table at G($8cc4) contains numerator/denominator pairs:
neutral0/800, first7/800, second9/750, third10/600, fourth10/450. The drivetrain
uses sequential signed integer divisions, not a combined rational expression:

- Base power is `trunc(trunc(throttle*450/100)*denominator/numerator)`.
  Power is halved if skid is active or the difference between velocity and
  RPM-derived wheel speed exceeds10. The diagnostic runs have no skid.
- RPM target is `trunc(trunc(velocity*140/500)*denominator/numerator)`.
  The elapsed RPM slew is limited to450 per native step with retained fractions.
- After that update, automatic gears downshift below2000 RPM or upshift above5200
  RPM, at most one gear per native call. Gear bounds are1 and4.
- A shift converts RPM through the old ratio and then the new ratio, with an
  integer division at each stage. The following call invalidates the old RPM
  companion on the gear mismatch. G($9926) is derived from the converted RPM
  through the reverse ratio and500/140 conversion; it is not simply the previous
  velocity sample.

The second-gear RPM target first exceeds5200 at integer velocity225. However,
RPM slew can delay the actual shift, so velocity alone does not define the event.
At the observed second upshift, A500 starts at velocity223+1/8, RPM5166, with a
14-field interval and rate5. It ends at231+7/8 and RPM5333, then changes gear.
The020 starts at223+5/8 with the same RPM/rate and a3-field interval; it ends at
225+4/8 and RPM5250, then changes gear. Both shifts convert RPM to3780 because
of the native intermediate rounding.

An offline one-field drivetrain recurrence, holding throttle and flat-road inputs
fixed throughout each captured interval, gives these contrasting endpoints:

| Capture/update | Whole-interval velocity | One-field recurrence velocity | Recurrence shift field within interval |
|---|---:|---:|---:|
| A500 first upshift,15 fields | 194 | 183+6/8 | 2 |
| A500 second upshift,14 fields | 231+7/8 | 225+3/8 | 4 |
| 020 first upshift,4 fields | 168+3/8 | 170+6/8 | 4 |
| 020 second upshift,3 fields | 225+4/8 | 225+2/8 | 3 |

This recurrence is an isolated diagnostic, not a runtime implementation or a
whole-car reference. It recomputes wheel-speed mismatch, power, force, RPM and
gear without controls, collision, steering or scene passes. The first upshift also
changes materially; clipping only the second-gear endpoint is insufficient.
A production change must carry within-interval changes of acceleration into the
position integral, preserve zero-carry native-step equivalence, handle manual and
neutral cases, and bound cost at very long intervals. A per-field drivetrain loop
has not been accepted as the runtime policy or measured against the A500 FPS gate.
The retained `segment-audit.json` files record the exact matched inputs and both
endpoints. Large-interval solver and handling acceptance remain open.


### Runtime drivetrain reference (optional, not performance accepted)

`VERIFY_DRIVETRAIN_REFERENCE` adds an explicitly experimental reference path in
HardDrivinDrivetrain.s. It requires TIME_MOTION, TIME_DISPATCH and TIME_AUDIO and
is installed only with CUSTOM1. The regular integrated build does not enable it.
The hook at `$0cdb6` replaces the paired engine/position calls. Full-contact,
automatic driving in gears1..4, without crash, skid or falling velocity, consumes
nonzero intervals other than eight fields through one-field engine updates.
Each update retains native power, RPM and gear behavior and accumulates projected
position with the existing fractional/Euler helpers. The native position routine
then publishes word positions and runs its remaining housekeeping once, with the
full interval restored; it skips the already-accumulated displacement.

Other driving modes and zero/eight-field intervals retain the existing pair.
The eight-field case explicitly preserves native-step compatibility; this is not
a universally one-field integrator. Steering, input sampling, collision/contact
and scene work still run once per outer physics pass. Brake state is held across
inner engine updates. Engine pitch publication at `$0baca` is delayed until the
last inner update, preserving one publication per outer pass. This changes no
Paula or VBL playback timing. The interval is restored before returning to the
rest of physics; the outer dispatcher does not gain extra full physics passes.

The final A500 timing capture (`s4-drivetrain-final-timing`) confirms33 completed
physics passes and33 scene calls, one dispatcher step per frame,491 engine calls,
zero outstanding inner fields at the final observation, and30 pitch publications.
Every pitch publication belongs to a distinct outer pass and none occurs during
an intermediate inner update. Some initial passes have engine sound disabled.
No crash or replay fields occur in this500-field window.

| A500, held throttle26,500 PAL fields | Swaps | FPS | Mean frame ms |
|---|---:|---:|---:|
| Current solver, reference off (`s4-drivetrain-base-timing`) | 37 | 3.694 | 270.701 |
| Final drivetrain reference (`s4-drivetrain-final-timing`) | 32 | 3.195 | 312.998 |

This diagnostic costs13.51% in swap count relative to the current solver and is
not an acceptable candidate for the3% A500 budget. The initial version also ran
native position housekeeping at every inner update; removing that repeated work
increased completed physics passes from32 to33 but did not increase swaps in the
measured window. These are ten-second constant-throttle diagnostics, not the full
A/B acceptance windows; trajectories differ and cannot establish equal handling.
The required performance gate remains open, not waived.

The final runtime operands (`s4-drivetrain-final-operands`) match341 engaged
engine updates against the independent velocity/power/RPM/gear model. The final
braking run (`s4-drivetrain-fast-brake-final`) validates484 longitudinal position
updates against actual pre/post operands, with zero backward updates, zero stopped
velocity/projection companions and a held final position. Braking begins at180;
the zero-throttle100-to-stop distance estimate is196.875 world units with sampling
bounds178.125..209.375. This does not prove general collision or trajectory safety.

`s4-drivetrain-final-native` matches108 original-reference car states with held
steering639 and native T=1; the gear pointer is the sole relocation normalization.
`s4-drivetrain-final-off` passes148 declared inactive ranges. The127-range direct
branch audit includes both new sites. Normal output remains byte-identical to the
8392-byte-text baseline. The `HDDRIVE1` diagnostic payload records original and
remaining fields, held brake, active mode, engine-call count and outer-call count;
`HDDTICK1` supplies relative offsets for read-only inner position observations.

This reference deliberately exposes the cost of recomputing the drivetrain for
every field. Work remains to replace those repeated calculations with a cheaper
integration policy around force/gear changes, validate other driving modes and
very long intervals, and pass the full handling/performance matrix. It does not
resolve collision tunnelling or complete step4.


### Skipping unchanged drivetrain updates

`VERIFY_DRIVETRAIN_SETTLED` is a separate optional optimization of the runtime
reference and requires VERIFY_DRIVETRAIN_REFERENCE. Before an eligible one-field
engine call, it saves all16 bytes of scalar companion state plus native wheel
speed, velocity, RPM, MPH, gear, throttle and gear-request byte. If all28 bytes are
unchanged afterward, another call with the same held inputs would have the same
result. Terrain, steering and contact remain fixed during this outer pass.

The helper integrates position over the remaining unchanged interval in one call,
then performs the final one-field engine update so native engine pitch is still
published once. It does not drop elapsed fields, change rate values or assume that
an unchanged integer velocity implies an unchanged fractional velocity. A change
to any saved companion, RPM, gear or input prevents the skip. The native eight-field
compatibility case retains the existing pair. `HDFIXPT1` records skipped fields,
bulk position updates and the28-byte input snapshot.

In the repeatable500-field A500 throttle26 diagnostic, this optimization produces
34 swaps,3.394588 FPS and294.586574 ms per frame, versus32 swaps/3.194906 FPS for
the unoptimized reference and37 swaps/3.694110 FPS for the current solver without
the reference. It saves156 engine updates in14 bulk intervals and executes331
engine calls inside34 full physics/scene passes. All31 engine pitch publications
are unique to their outer pass; none occurs during an intermediate update. Final
remaining fields are zero. The fresh repeat reproduces the same swap fields and
counts. Captures are `s4-drivetrain-settled26-timing` and `-counters`.

The measured deficit relative to the current solver falls from13.51% to8.11%; it
still does not meet the3% performance budget. These remain the constant-throttle
diagnostic windows, not full A/B handling or performance acceptance.

`s4-drivetrain-settled-brake-checked` records six actual skips totaling54 fields.
For every skip, the28 saved engine-input bytes equal the live post-update bytes,
and the resulting longitudinal position and carry exactly match an independent
repetition of the corresponding one-field integrations. All474 observed position
updates also pass the displacement model, with zero backward motion, zero stopped
velocity/projection companions and a held final position. The earlier capture
without the additional input-snapshot logging gives the same braking result.
This validates the observed straight-line cases; it is not full-world equivalence.

`s4-drivetrain-settled-native` matches all108 native-reference car states, with
only gear-pointer relocation. CUSTOM1-off passes all148 range checks, the127-range
branch audit passes, and both normal output and the reference with this new flag
absent remain byte-identical. The next cost issue is engine evolution while state
is changing; no speculative skipping across force or gear changes is implemented.


### Batching fractional acceleration between integer boundaries

`VERIFY_DRIVETRAIN_FRACTION` optionally extends SETTLED. After a one-field engine
update, it permits only the velocity companion to differ: the other26 saved bytes
must match. The difference between the old and new eighth-velocity companions is
the field's rate. With unchanged native velocity, wheel speed, throttle, RPM and
gear, the native force inputs and RPM target remain constant. The helper limits
its batch so the velocity word cannot change and the companion cannot cross zero,
where interpolation switches to the other adjacent native vector. It preserves a
final engine call for pitch publication, just as the unchanged-state helper does.

The path excludes velocity magnitudes below2, where dissipation limiting could
make the fractional rate nonlinear, and magnitudes above21843, where the native
projection wraps. For the remaining values, one-field resistance cannot consume
the existing velocity: native drag is magnitude-clamped to velocity, braking is
no larger than velocity, and their sum is below the available eighth-unit magnitude.
The companion advances by rate times batched fields; the existing position helper
then integrates the linearly changing projected fraction. No integer-velocity,
RPM, gear or force threshold is skipped. `HDFRAC01` reports skipped fields, bulk
updates, the last rate and the currently active bulk interval (zero outside it).

Live operand validation compares every batch with independent single-field
position updates, including every intermediate projected fraction:

| Capture | Fractional batches | Batched fields | Observed rates |
|---|---:|---:|---|
| `s4-drivetrain-fraction-brake` | 20 | 28 | -3,-2,-1,+3 |
| `s4-drivetrain-fraction-accelerating` (A500) | 27 | 47 | +1,+2,+3 |
| `s4-drivetrain-fraction-020` | 49 | 60 | +1,+2 |

All engine inputs other than the velocity companion remain identical in these
checks, and every final longitudinal position/carry matches repeated field updates.
The braking capture additionally passes464 general position updates, with no reverse
motion and a held zero-velocity stop. Its five unchanged-state batches,53 fields,
also match the unchanged-state reference. These are observed longitudinal cases,
not full steering/collision equivalence.

The final500-field A500 timing capture (`s4-drivetrain-fraction26-final`) has34
swaps,3.394588 FPS,35 full physics/scene passes and266 engine calls. It skips147
unchanged engine fields in14 batches and78 fractional engine fields in34 batches.
All32 pitch publications are unique to their outer pass; both batching paths are
inactive at the final observation. Fewer engine calls did not produce another swap
in this window, so no additional FPS gain is claimed over SETTLED. The diagnostic
still trails the current solver's37 swaps and does not pass the3% budget.

Native-step comparison passes all108 reference car states; CUSTOM1-off passes148
ranges, the127-range branch audit passes, and normal output and the settled-only
build remain byte-identical when the new flag is absent. The optimization remains
optional within the experimental reference, not enabled in the regular solver.

### Instruction cost of the drivetrain reference

The matching A500 instruction captures `s4-profile-current` and
`s4-profile-fraction` each cover 500 PAL fields (10.015944 seconds), starting at
race entry with the same throttle-26 input fixture. Their 37 and 34 swaps match
independent runtime counts. Complete physics calls exclude interrupt execution;
child routine costs are inclusive and must not be added to their parent.

| Complete routine | Current solver calls / total ms | Fractional reference calls / total ms |
|---|---:|---:|
| Full physics | 37 / 450.896 | 35 / 1115.935 |
| Engine | 37 / 57.612 | 266 / 424.519 |
| Native position and housekeeping | 37 / 56.444 | 35 / 17.653 |
| Intermediate projected position | absent | 313 / 305.287 |

The additional engine calls and intermediate position work explain most of the
665 ms increase in complete physics time. Average engine cost is similar
(11,046 versus 11,321 A500 CPU cycles); its repeated invocation is the problem.
The reference's position helper averages 6,919 CPU cycles. Projection helpers
alone account for 197.399 ms of self time, versus 18.763 ms in the current solver.
This points to reducing repeated force evaluation and projected-position work,
while preserving gear transitions and fractional displacement, as the next target.

Trace instruction coverage is greater than 99.9999% in both samples. CPU-cycle
conversion uses the A500 CPU clock (header base clock divided by four); the
header's base clock itself is not the CPU clock. These are diagnostic comparisons
between two gated solvers, not original-game acceptance: their trajectories and
rendered scene workloads can differ, and the full A/B performance gate remains open.

### Combined position integration for reference field ticks

`VERIFY_DRIVETRAIN_POSITION` requires the drivetrain reference and replaces only
its intermediate position call. For a one-field tick, it combines integer and
fractional projected contributions before splitting into position and remainder:

```
Q16 displacement = 4096 * (9*v - 7*u)
                 + floor((9*q - 7*previous_q) / 16)
                 + 512 * integer_carry + fractional_carry
```

Here `v/u` are the current/previous native projected words, and `q/previous_q`
are their Q16 fractional corrections. This is the same arithmetic as the general
helper's two integrations and final carry merge, with one final truncation toward
zero. It preserves projection updates and clears the integer carry after merging.
All six projected words must be within [-16383,16383], bounding the largest
integer term below 2^30; the bounded fractional terms and remainders also fit.
Other intervals and wider vectors use the general helper. Native eight-field
steps continue through the original compatibility path.

The isolated assembled 68000 helper passes 2,024 signed arithmetic cases and 976
fallback cases, including the guard boundaries, opposing integer/fraction signs,
register preservation and stack balance. This microtest supplies projected Q
values directly; it does not test projection generation. Live captures additionally
validate the complete integration, including the actual projection update:

| Capture | Complete updates per axis | Nonzero X / Y / Z displacements |
|---|---:|---:|
| A500 throttle26 | 314 | 304 / 25 / 0 |
| A500 steering X400 | 356 | 346 / 0 / 323 |
| 68020 throttle26 | 473 | 436 / 53 / 0 |
| A500 braking | 461 | 427 / 0 / 0 |

Every axis matches the independent combined-displacement calculation. The braking
run has no backward movement, clears velocity/projection fractions at rest and
holds its final position. The capture waits for a pending position update to
finish at the observation boundary; these operand captures are not FPS windows.

The separate 500-field A500 timing run produces 35 swaps, 3.494429 FPS and
286.169814 ms per frame, compared with 34 swaps without combined integration
and 37 in the current solver control. It executes 35 full physics/scene passes,
267 engine calls and 32 pitch publications, each unique to its outer pass. The
5.41% frame-count deficit against the control still exceeds the diagnostic budget;
this does not establish the full original-game A/B acceptance requirement.
Native-step comparison matches all 108 reference car states; CUSTOM1-off passes
148 ranges, the 127-range branch audit passes, and normal and flag-absent binaries
remain unchanged. Full handling and performance acceptance remain open.

### Reusing identical engine square-root operands

`VERIFY_DRIVETRAIN_SQRT` requires the reference integrator and hooks the engine's
square-root call at `$0b856`. During inner reference ticks only, it caches the
complete 32-bit operand and native result. The native root function at `$09564`
uses only that operand and integer arithmetic; it has no game-state side effects.
A different operand always calls the original function and replaces the cache.
Native/full-step calls bypass the cache. Gear, force and velocity updates still
execute; no recurrence interval or threshold is skipped. The cache can persist
across frames and resets because its key contains the function's complete input.

The wrapper duplicates the native long argument for a miss/bypass, then removes
the displaced caller argument before returning to `$0b85c`. Live entry/return
checks verify both the root result and balanced stack at every observed call.
`HDSQRT01` stores operand/result longs, a valid word plus padding, and hit/miss longs.

| 500-field operand capture | Root calls | Cache hits | Cache misses |
|---|---:|---:|---:|
| A500 | 266 | 90 | 176 |
| 68020 | 394 | 205 | 189 |

Every result matches an independent reconstruction of the native iterative
integer algorithm; the hit totals also equal consecutive identical operands in
these runs. The separate A500 timing window remains 35 swaps / 3.494429 FPS,
with 35 full physics/scene passes, 267 engine calls and 32 pitch publications,
each unique to its outer pass. Reducing native root evaluations has not added a
swap in this diagnostic, so no further FPS gain is claimed. The general solver
and original-game performance acceptance remain unfinished. Native-step comparison
matches all 108 reference car states; CUSTOM1-off passes 149 ranges and the
128-range branch audit passes. Normal output and the position-optimized build
remain byte-identical when the cache flag is absent; missing its required
reference flag rejects assembly.

### Reusing throttle and ratio conversions

`VERIFY_DRIVETRAIN_POWER` requires the reference integrator. It replaces the
engaged-gear conversion block `$0b696..$0b6bf`, preserving both original
multiply/divide calls on a miss or outside inner reference ticks. Its complete
cache key contains the signed throttle byte and both words of the current gear
ratio, rather than just a gear number. A hit reproduces the intermediate D4 word,
final D0 result and local power word. Subsequent slip halving, drag, braking,
slope, RPM and gear decisions still execute normally. `HDPOWER1` stores the ratio
long, throttle/valid words, result long, intermediate/padding words and hit/miss
longs. There is no game-state input omitted from these two conversions.

| 500-field capture | Conversion calls | Cache hits | Cache misses | Uncached calls |
|---|---:|---:|---:|---:|
| A500 hold26 fixture | 263 | 252 | 10 | 1 |
| 68020 hold26 fixture | 396 | 366 | 29 | 1 |
| A500 constant accelerator | 394 | 361 | 32 | 1 |

All captured intermediate/final values match independent signed multiplication,
division and native word narrowing; entry/exit stack pointers agree. The constant
accelerator capture reaches throttle 100 and all four engaged ratio pairs. A
separate drivetrain capture matches 247 complete velocity/RPM/gear updates,
including two automatic shifts. Native-step comparison matches 108 reference car
states; CUSTOM1-off passes 150 ranges, the 129-range branch audit passes, and
normal output and the cache-absent build remain byte-identical. Missing the
required reference flag rejects assembly.

The hold26 A500 timing window still has 35 swaps. Its actual throttle plateaus
at 29, while the 68020 reaches 26: stopping the accelerator at a threshold can
overshoot on a long control update. This is a diagnostic fixture, not an
identical-throttle cross-machine comparison.

A fresh comparison instead holds constant accelerator input, using the same
compiled slave with CUSTOM1 off/on. Over 500 fields the original produces 38 swaps
(3.793951 FPS,263.577461 ms/frame); the enabled build produces 34
(3.394588 FPS,294.586574 ms/frame), a 10.53% FPS loss. It performs 35 full
physics/scene passes and 394 engine calls, with 32 pitch publications unique to
their outer pass. The original has no crash/replay fields; the enabled run reaches
seven crash fields at the end, with no replay. These trajectories impose different
workloads, so the count difference is not an isolated arithmetic cost. It still
does not pass the 3% performance requirement. See PERFORMANCE.md for the current
comparison and its distinction from the frozen gameplay A/B windows. A repeat
reproduces the swap schedule, all 501 game-state snapshots and physics records
byte-for-byte.

### Manual and neutral reference integration

`VERIFY_DRIVETRAIN_MANUAL` extends the optional reference integrator to grounded
manual driving and neutral (gears 0..4). Crash, skid, falling and partial-contact
eligibility restrictions remain. Zero/eight-field intervals retain the native
single-pair path. Each inner tick runs the native engaged or neutral RPM behavior;
neutral does not acquire a new drag/force law.

The native manual branch reads a keyboard gear request at G($991d) and a joystick
request at G($95ff). Those are events, not continuous force inputs. A hook at
`$0b9ba` allows their native handling on the first engine tick of an outer pass,
then bypasses manual selection on subsequent ticks while leaving both request
bytes untouched. Thus input arriving during the recurrence stays queued for the
next frame. Native/full-step calls retain their original branch behavior. Ratio
conversion, native downshift damping, neutral RPM preservation and request clearing
remain in the game's existing code. The batching helpers can still skip fixed
engine states because later inner ticks no longer consume manual events.

`VERIFY_STEPINPUT_MANUAL` is an input-only fixture requiring STEPINPUT. It selects
manual through the native menu and returns decoded keyboard keys through the
normal controls reader, without setting gear or automatic-mode state. Ten keys at
controls passes 1,11,...,91 select 1,2,3,4,2,neutral,1,4,neutral,1. These pass-indexed
inputs support native-step equivalence; they are not an equal-time input tape.
Requests queued during crash can take effect later, as in the native game.

| Live manual capture (108 outer returns) | Engine updates checked | Neutral RPM updates | Later manual visits deferred | Consumed shifts |
|---|---:|---:|---:|---:|
| A500 | 850 | 97 | 761 | 10 |
| 68020 | 359 | 66 | 251 | 10 |

All RPM updates, shift ratio conversions and damping match an independent model;
no outer pass consumes more than one request. All 108 native-step car snapshots
match the original manual fixture, including the ten shifts. A separate 1400-field
A500 capture validates 901 complete intermediate position updates on each axis
against the combined-displacement model (847 nonzero X and 186 nonzero Y moves).
It checks the reference ticks, not native crash drift or other fallback modes.

An isolated test of the assembled 68000 dispatch helper passes 1500 branch cases,
including 380 cases with nonzero queued requests deferred unchanged, with register
and stack preservation. CUSTOM1-off passes 151 ranges, the 130-range branch audit
passes, normal and flag-absent binaries remain unchanged, and both new flags
reject missing dependencies. These establish focused manual/neutral support;
full contact handling, equal-time comparisons and performance acceptance remain
open. The current original-versus-enabled performance table predates this optional
manual gate and makes no claim about its cost.

### Near-stop fractional projection and position correction

The retained operands isolated three interacting problems. At integer velocity1
with a -7/8 companion, the native rounded projected speed is1; projecting the
companion independently as -7/8 times1.5 yields a negative total. Resistance
could also leave a negative fractional velocity after the integer word reached
zero. Finally, separately truncating the integer and fractional position updates
could publish a negative one-unit displacement despite a positive combined sum.

The gated projection now interpolates adjacent native rounded velocity vectors,
using the signed eighth-velocity companion. Zero companion still produces zero
correction. Outside velocity[-21843,21843], it retains the previous bounded
fractional extension to avoid interpolation across native signed-word wrap.
That fallback does not establish the validity of extreme native velocities;
widened storage and consumer safety remain open. Inside the interpolation range,
the correction magnitude is at most114688 in Q16 position units.

The position wrapper combines both remainders and their whole-unit outputs before
publishing movement, retaining a single signed Q16 remainder per axis. Resistance
limiting now includes short intervals, while preserving zero-carry native steps.
Drive and slope can still legitimately move velocity through zero.

The final private projection fixture (`s4-projection-quant-math-final`) checks372
actual helper outputs against an independent integer model: near-zero velocities,
all eighth carries, four orientations, and signed-word boundary cases. The final
326-case dissipation fixture also passes. These fixtures use private fake globals.

Final integrated braking captures `s4-brake-projection-final-a500` and `-020`
check36 and146 longitudinal position updates respectively. Every update matches
the independently reconstructed combined displacement, none moves backward, and
both stopped states have zero velocity companion and projected velocity and hold
their final position. The final slowed-A500 capture (`-slow4`, four additional
fields per frame) passes the same checks for27 updates. Earlier merged-carry captures on030 and060 also passed
236 and235 updates; they precede only the final extreme-velocity guard and native
zero-carry bypass. They are supporting evidence, not final-build matrix coverage.

The final forced-native build matches all108 original-reference car states with
held steering639 (`s4-projection-native-final`, reference
`s4-skid-native-reference`; only the relocated gear pointer is normalized).
The125-range branch audit passes. The fresh CUSTOM1-off capture
`s4-projection-final-off` passes all146 declared ranges, and the normal8392-byte
text build remains byte-identical to the baseline. This is focused car-state compatibility, not
full driving-tape/world equivalence. Complete equal-time handling, collision
extremes, and comparable-scene performance acceptance remain open.


### Long-step drag and braking correction

`VERIFY_TIME_DISSIPATION` requires TIME_SCALARS and uses the existing velocity
hook. It now limits resistance on short intervals as well as long ones. A zero
interval, or an eight-field interval with zero incoming velocity carry, preserves
the original increment exactly, including native force-law quirks. `VERIFY_GAMEPLAY_SLOW` requires
SLOW and TIME and delays only active gameplay, allowing large-delay tests to
reach the driving scene without disrupting the menu input tape.

The uncapped linear resistance update is unstable even before storage overflows.
In `s4-velocity-long64`, braking on flat ground changes velocity31 to-173 over78
fields: drag1 and brake20 remove more velocity than exists. The next updates
reverse direction repeatedly. Across1800 fields the capture has23 forward writes,
six zero crossings and velocities-192..390, with no word overflow.

The correction limits the removal attributable to drag and braking to the old
velocity including its signed fractional carry. Drive and slope remain separate
and may legitimately move the car through zero. Effective resistance is inferred
from the force components and capped native net acceleration, bounded by the
original drag-plus-brake component. When resistance would consume the old velocity,
the remaining absolute velocity is the scaled external force contribution. Its
signed multiplication uses a wide intermediate before division by eight. This is
an explicit long-step force policy, not a proof of equivalence to fine integration.

The private `VERIFY_DISSIPATION_MATH` fixture calls the actual velocity wrapper
with326 cases covering both signs, slopes, native force caps, stale fractional
state and intervals0,1,7,8,9,16,79,255,65535. All outputs match the independent
integer model; the final all-interval policy activates the limiter in148 cases
(`s4-dissipation-all-intervals-final`). The earlier long-only policy activated130. Synthetic word extrema exercise
arithmetic only and do not establish physical validity of those velocities.

| Runtime capture | Forward writes | Limiter uses | Velocity range | Maximum fields | Zero crossings |
| --- | ---: | ---: | ---: | ---: | ---: |
| s4-dissipation-long64 | 23 | 1 | 0..390 | 79 | 0 |
| s4-dissipation-brake-a500 | 62 | 2 | -4..278 | 16 | 1 |
| s4-dissipation-moving255 | 9 | 4 | 0..1507 | 269 | 0 |

All captured forward writes match the model and have no word overflow. The ordinary
A500 run still rolls backward under slope3: velocity31 becomes-4 over12 fields
with drag1, brake20 and drive0. The maximum-delay run postpones braking until
field1200 so it actually moves; it also captures one falling write, rate5 over266
fields, yielding166 with remainder2. The earlier delay255 test with braking at
field250 stayed stationary and is not moving-car safety evidence.

`s4-dissipation-native-matched` matches all108 original-reference car-state
snapshots, G($98f6)..G($9951), with only the gear-table pointer relocated. This
is not full-world or full-tape equivalence. An initial replay-release fixture
comparison diverged at step82 because its crash inputs differed from the reference;
the identical fixture with and without the limiter matches all108 states and
field timestamps. The accepted original-reference run uses matching constant inputs.
CUSTOM1-off `s4-dissipation-off` passes all144 declared range checks with only
DRIVE and STEPINPUT enabled. The123-range direct-branch audit passes, and the
normal8392-byte-text slave remains byte-identical to the baseline.

The follow-up force audit reconstructs all9 long-delay and62 ordinary A500
force evaluations exactly from captured power, road/skid flags, slope and braking.
Drive is the native integer square root of `(3*max(v,0)/2)^2 + power`, minus
`3*max(v,0)/2`, including the native word arithmetic and square-root rounding.
Drag grows with speed; drive falls with speed. Holding the initial net rate over
an entire long frame therefore misses both changes. With captured power44192,
road contact and v=0, the269-field live update holds rate40 and reaches1345.
An offline recurrence that reevaluates the native law every eight fields with
those same frozen inputs reaches617 instead. A later frozen-input comparison
from v173 reaches345, against the live1507. This recurrence isolates nonlinear
force dependence; it is not a proposed extra-physics-pass implementation or a
whole-car reference, since controls, contact and terrain are held fixed.
The captures are s4-force-moving255 and s4-force-brake-a500, with force-audit.json.

The maximum-delay speed1507 is much greater than the ordinary run's278. Preventing
resistance-induced reversals therefore does not establish long-step handling,
collision/checkpoint safety, or agreement with shorter updates. External-force
integration, word consumers and falling motion still require a complete safety
policy. No full step-4 performance or handling acceptance follows from these tests.


## GAME OVER presentation clock

`VERIFY_TIME_TIMELINES` requires `VERIFY_TIME_REPLAY_TIMING` and remains behind
CUSTOM1 and the SPS 0126 guard. `HardDrivinTimeline.s` replaces the GAME OVER
35-rendered-pass counter with 280 eligible PAL fields (35 native steps). It uses
the replay wall counter because gameplay's counter stops at race exit. Native
pause/options hooks suspend this wall counter too.

The entry hook at `$10f62` establishes the epoch and retains both native clears.
The `$10f6a` hook calls native controls, samples elapsed time after any modal
pause, and then calls native scene preparation. The split-text phase is
`min(floor(age/8),35)`; the original renderer still caps its displacement at20.
The `$10fe6` hook exits after the first completed frame at age >=280 and clears
the timeline's active flag. Final-frame overshoot is retained explicitly; no
physics catch-up is performed in this loop. Long arithmetic prevents a delayed
frame from wrapping the native signed-word animation counter. The helper saves
X without reading the privileged status register, and the exit hook restores
the native counter increment's cleared X before supplying the comparison flags.

Overlay countdown selection recognizes this presentation epoch, consumes its
own elapsed interval once, and resets that interval if an overlay starts within
the loop. The observed GAME OVER runs did not call the overlay countdown, so
this selection has static coverage only; it is not claimed as live overlay
validation. Other presentation timelines remain unfinished.

`VERIFY_TIMELINE_PAUSE` is an input-only diagnostic requiring VERIFY_DRIVE and
TIME_TIMELINES. It supplies SPACE once after GAME OVER age24 and again40 input
fields later, exercising the actual pause loop without injecting mode or clock
state. Fresh boots follow the full native race to GAME OVER:

| Capture | CPU/policy | Rendered passes | Active elapsed fields | Paused fields |
| --- | --- | ---: | ---: | ---: |
| s4-gameover-pause-a500 | 68000 elapsed | 26 | 283 | 40 |
| s4-gameover-final-020 | 68020 elapsed | 98 | 280 | 40 |
| s4-gameover-native-final | 68000 forced native | 35 | 280 | 0 |

Each drawn phase and completed-frame counter matches the appropriate elapsed
or native rule. Both pause captures observe40 VBLs with an unchanged wall
counter. The last A500 frame starts at age272 and completes at283; the last
68020 frame starts at278 and completes at280. Forced-native mode retains the
original sequence0..34 and termination at35. These are timer/phase checks,
not framebuffer equivalence or full world-state acceptance.

The earlier `s4-gameover-a500` capture reached age282, but its first checker
incorrectly required the wall clock still to equal the sampled phase age after
scene preparation. That check was corrected to allow intervening fields; final
captures above use the corrected checker and final source. The additional final
A500 capture `s4-gameover-final-a500` was actually built with the pause fixture;
it predates explicit pause counting and is superseded by the dedicated pause
capture above.

`s4-gameover-off` passes all disabled patch ranges. The ordinary final slave is
byte-identical to the unmodified build; the direct-branch audit covers94 ranges
with no external branch into a replacement's interior. Runtime, captures and
local checker stay under ignored `tmp/`. Step4 remains incomplete: Phantom and
attract/menu timing, audio/derivatives, long-step safety, full tape and machine
comparisons, matched-workload performance, and human laps are still required.


## Attract route, scroll and timeout

`VERIFY_TIME_ATTRACT` requires TIME_TIMELINES and uses the same CUSTOM1/SPS0126
installation guard. `HardDrivinAttract.s` establishes a pause-aware wall epoch
at the first cockpit (`$10844`). The two preceding native route/scene setup
calls remain unchanged. It advances the visible route by one native phase per
8 eligible fields, so each ten-phase segment lasts80 fields. The1000-pass
sequence becomes8000 fields, followed by the remainder of the last drawn frame.
Gameplay physics is not called by this presentation path.

The route wrapper at `$0d574` consumes each interval once and walks every crossed
segment in order, applying the original main/alternate route bounds and fork
selection before each crossing. Cached route geometry is invalidated on a
crossing. The original geometry construction stays in place; the interpolation
block at `$0d832` uses the complete field fraction and signed long products.
Both text pages use `200-floor(age/8)` instead of decrementing their scroll
once per draw. Timeout and input-driven exit share cleanup and the native page
toggle. Before clearing the epoch, exit consumes the last outstanding route
interval, capped at8000 on timeout, so its fractional tail is not lost when the
next cycle performs its native setup calls.

Heading needs the cache writer at `$0d772`: it resets G($9946) to the current
segment's heading. Thus phases0..4 hold that segment angle, then phases5..9
interpolate toward the next segment. The elapsed path evaluates this directly
from route geometry, including fractional fields, with the native wrap rule.
It never depends on which intermediate frames happened to be drawn. An early
candidate incorrectly held the preceding segment's phase9 heading. Comparison
with original native-time poses exposed that error; those candidate captures
are superseded by the corrected runs below.

Outside an active epoch, the original interpolation block is executed from a
runtime copy with its internal relative branches intact, and the original
per-call route increment remains. No game bytes are committed: the copied
block is filled from the loaded game before the loader's final cache flush.
VERIFY_DISPATCH_NATIVE leaves the native interpolation, route increment and
scroll instructions unpatched and retains1000 rendered passes. Its additional
epoch hook preserves registers and X.

`VERIFY_ATTRACT_PAUSE` is a separate input-only fixture: SPACE after age24, then
SPACE40 raw VBLs later. It requires VERIFY_ATTRACT and TIME_ATTRACT and runs
through the actual native keyboard/pause path. Its independent VBL counter
continues while the presentation clock is paused.

Corrected camera evidence before the final exit-tail addition:

| Capture | Profile | Draws | Active fields | Paused fields | Fractional poses |
| --- | --- | ---: | ---: | ---: | ---: |
| s4-attract-correct-a500 | A500 | 1212 | 8005 | 40 | 1060 |
| s4-attract-correct-020 | 68020 | 4036 | 8000 | 40 | 3471 |

The checker independently models route crossings and interpolation from retained
route-table records and the native cached geometry. Both runs traverse100
segments and enter the alternate route. At624 shared elapsed-field timestamps,
their route, camera and scroll states agree exactly. At exact eight-field
boundaries,152 A500 poses and565 68020 poses match the original native run.
The forced-native final camera build `s4-attract-native-correct` matches all1000
original frames in route pointers (relative to their verified main/alternate
allocations), phase/fork flags, cached geometry, camera pose and scrolling.
Pointers must not be normalized to the globals hunk: these route tables are
separate allocations. The initial comparator made that mistake; re-reading the
retained table limits fixed the comparison without changing or masking values.

The final exit-tail implementation is additionally checked through the natural
second cycle in `s4-attract-endpoint-second`: page255,1667 draws,8003 active
fields,100 route crossings and the alternate-route exit. The fixture's40 paused
fields occurred in the first cycle, before this capture; they are excluded from
the shared clock. At exit the route has consumed exactly8000 fields, its phase
returns to the initial within-segment phase, the epoch is inactive and the page
flag toggles. This covers the second text page and the reset boundary.

The final 68020 run `s4-attract-endpoint-020` completes4043 draws in8000 active
fields and excludes40 paused fields. It verifies3557 fractional poses and486
exact native-grid poses, plus the same exit-tail and page-toggle invariants.

The long-frame run `s4-attract-slow80` adds80 fields to each frame submission.
It completes93 draws in8032 fields, with99 crossings before the final draw ends
and the remaining route interval consumed at exit. Seven frames cross two
segments; the independent route/pose model passes throughout, including the
alternate-route entry. The final route age is exactly8000, despite32 fields of
timeout overshoot. An earlier255-field-delay run timed out before reaching the
cockpit anchor; its owned processes were cleaned up and it supplies no evidence.

`s4-attract-endpoint-off` passes all disabled ranges, the ordinary build remains
byte-identical, and the direct-branch audit passes104 ranges. Captures, copied
runtime game bytes and checker tools remain under ignored `tmp/`.

These are attract camera/route/timer checks, not full gameplay acceptance or a
rendering performance claim. Attract audio and other side effects still belong
to the remaining sound audit. Phantom playback, other menu transitions, large-T
solver safety and the full step4 machine/handling/performance criteria remain.


## Phantom challenge dispatcher (partial implementation)

Phantom challenge gameplay uses a separate outer loop at `$11894` and physics
function at `$11664`, not the ordinary race's `$10ed4` loop. Its active flag is
G($e931), not G($add4). `VERIFY_TIME_PHANTOM` requires TIME_DISPATCH and installs
`HardDrivinPhantom.s` behind CUSTOM1/SPS0126. It starts and ends the elapsed epoch
at this loop's real boundaries, resetting scalar companions on entry. It calls
the same CPU-selected dispatcher: one full elapsed interval per68000 frame,
physics every frame on68020+, with bounded extra substeps for long frames.

The `$11668` controls hook handles keyboard/edge events once per outer frame;
subsequent substeps use the existing held-input ramps. The `$116bc` hook repeats
from inside the existing LINK frame, so it never recursively creates another
physics stack frame. If G($e931) clears, pending time is charged to the explicit
discard counter. The final pass draws once. The native caller at `$1189e`
submits once. Phantom's scene setup remains complete on intermediate steps:
the existing scene-cull gate requires the ordinary race flag, so no Phantom
culling or associated performance benefit is claimed.

Replay exclusion is shared through `_time_replay_call`: it suspends gameplay
field accumulation only when instant replay is requested and restores/reset
state afterward. The ordinary wrapper submits after calling it. The Phantom
wrapper preserves the native UNLK/RTS, leaving submission to its caller. Pause
and options already use the shared suspend/resume hooks.

The ordinary driving tape does not qualify for Phantom. `VERIFY_PHANTOM_ENTRY`
is therefore a separate synthetic integration fixture, requiring VERIFY_DRIVE.
It substitutes the native challenge initializer at `$11958`, supplies a SPACE
at the real instruction-page wait `$1151a`, and establishes the normal input-tape
epoch at the challenge's input reset `$1188c`. On completion it returns through
the native attract transition. The game itself initializes car, track, clocks
and challenge flags; debugger writes are not used. This fixture deliberately
bypasses qualification and is **not** the unmodified full driving-tape or
human-lap acceptance test.

Without the instruction-page key, the old menu tape could dismiss that page in
one build but miss it in another. The initial lightweight reference timed out
before its physics anchor; the same-layout off-reference was interrupted by its
verified owned PID and cleaned up. Neither supplies comparison evidence. The
corrected fixture provides these checks:

- `s4-phantom-reference-fixed` versus `s4-phantom-native-fixed`: all144 car
  states match, with only the known gear-table pointer normalized. Phantom
  phases, both cursors relative to their buffers, engine-start phase and
  challenge active/result flags also match at every step. This does not compare
  the full allocated ghost histories or every world-state byte.
- `s4-phantom-ordinary-native`: all144 ordinary-driving car states still match
  the existing native reference after the replay helper was shared. The short
  capture does not establish live replay or challenge-exit coverage.
- The earlier successful synthetic runtime windows `s4-phantom-live-a500` and
  `s4-phantom-live-020` cover500 fields each. A500 has52 physics calls/52 draws,
  consuming0 initially and8..12 fields thereafter, one update per frame. The
  68020 has196 physics calls/196 draws (195 swaps inside the sampled boundaries),
  consuming0 initially and2..4 fields thereafter. No oversized fallback occurs.
  These captures preceded only the instruction-page fixture correction; the
  dispatcher itself is unchanged. They are policy diagnostics, not matched-scene
  performance acceptance or proof of correctly timed ghost opponents.
- `s4-phantom-paused-slow`, with the corrected fixture on68020 and CUSTOM4=12,
  has53 physics calls/27 draws in500 fields. Its maximum is two substeps per
  frame, each at most8 fields. All500 adjacent VBL clock increments are checked.
  The input fixture requests pause after field100 and resume at200; the next
  controls pass consumes the first key at104, producing96 actual paused fields.
  Both elapsed clocks remain frozen throughout. The original checker wrongly
  expected100 paused fields; the retained capture was rechecked against the
  actual contiguous96-field interval and the unchanged clock increment rules.

`s4-phantom-off` passes disabled-range checks with only the declared input/entry
fixtures enabled. The ordinary slave remains byte-identical to the baseline,
and the direct-branch audit passes108 replacement ranges.

This gate is still experimental. The optional ghost recorder below consumes
elapsed fields. The optional challenge-opponent playback below also uses
elapsed fields. The optional post-race gate below converts the two-history
presentation. Instruction/camera timing is covered by TIME_INSTRUCTIONS below.
Qualification, challenge exit/debt, instant replay and full handling
comparisons remain acceptance work; this dispatcher result does not complete
step4.

## Phantom ghost recording (partial implementation)

`VERIFY_TIME_GHOST_RECORD` requires TIME_PHANTOM and TIME_RECORD and installs
`HardDrivinGhostRecord.s` behind CUSTOM1/SPS0126. It replaces the recorder entry
at `$08a9c` and extends the native challenge-history reset at `$11858`. The
12-byte record is unsigned X/Z, signed Y, then negated pitch/heading/roll.
The buffer has 300 records. As in the original, reaching capacity holds the
cursor at slot 299 and subsequent samples overwrite that last slot; it does not
wrap or write beyond the buffer.

Native recording increments its phase before checking for six calls, but reads
the pose before that call's physics update. With eight-field steps, its first
sample therefore represents field 40, followed by 88,136,... . The elapsed
recorder preserves that alignment and the 48-field period. It charges the
previous physics interval, interpolating every crossed sample between the
previous and current pre-physics poses. Unsigned positions and signed height
use wide weighted arithmetic; angles use the short path with a 1440-unit wrap.
An exact right endpoint is copied verbatim, preserving native word values.

The companion tracks the physics-step stamp, expected cursor, eligible age,
sample count, field phase and previous interval. Duplicate visits cannot charge
an interval twice. A nonconsecutive stamp refreshes the pose without advancing
recording time. A changed native cursor reseeds from the native phase, and a new
challenge clears the companion. These transition policies still require wider
live replay/re-entry coverage. The native entry remains available when the
elapsed dispatcher is inactive and under VERIFY_DISPATCH_NATIVE.

The native recorder leaves the CPU extend flag from its phase increment when
no sample is written, or from negating the roll when a sample is written. The
wrapper preserves that distinction: the native BCD clock's dependence on X
makes it relevant even though recording itself does not use the flag.

Focused checks retained under ignored `tmp/`:

- `s4-ghost-record-math-flags`: a private VERIFY_GHOST_RECORD_MATH boot fixture
  runs 1860 eight-field visits against the actual, still-unpatched native
  recorder using separate synthetic globals. Both full 3600-byte histories
  match, as do cursor, phase and X after every visit. It emits 310 samples,
  exercising saturation and repeated overwrites of the final slot. Synthetic
  poses are private fixture data, not injected gameplay state.
- The same fixture independently checks a 65535-field interval: 1365 samples,
  unsigned coordinate extremes, signed height extremes, wrapped angles and
  the final-slot overwrite rule. Every output word matches a rational model;
  all 2223 checked guard bytes remain intact. This proves recorder arithmetic,
  not that a physics integration step of that size is safe.
- `s4-ghost-record-final-020`: 160 live visits, 398 eligible fields, 8 samples,
  including 4 fractional samples. Every before/after 3600-byte history matches
  the independent model. `s4-ghost-record-final-a500` covers 160 visits and
  25 samples over 1231 eligible fields, including 23 fractional samples; every
  full history matches the model.
- `s4-ghost-record-long-final`: with the slow-drawing fixture enabled and
  CUSTOM4=64, the challenge exits naturally after 15 recorder visits. The
  captured 967 eligible fields emit 20 samples; 7 visits emit more than one.
  All sample words and untouched buffer bytes match. The earlier capture
  named `s4-ghost-record-slow` lacked VERIFY_SLOW and is not long-frame evidence.
- `s4-ghost-record-off` passes the inactive-range check with only declared
  input, synthetic-entry and slow-drawing fixtures enabled. The ordinary build
  remains byte-identical to the 8392-byte-text baseline, SHA256
  `5811a0305be8836685b6303aae226845836c6c41e90e746c9a6bfebae226582e`.
  The direct-branch audit passes 110 replacement ranges.

The recorder does not change playback. The optional opponent implementation
below converts `$08c84` during challenge gameplay. Post-race history rewind and
both post-race playback paths are covered by the separate optional post-race gate
below. No full challenge-speed, whole-world native equivalence, handling or FPS
acceptance is claimed here.


## Phantom opponent playback (partial implementation)

`VERIFY_TIME_GHOST_PLAYBACK` requires TIME_PHANTOM and installs
`HardDrivinGhostPlayback.s` behind CUSTOM1/SPS 0126. It replaces `$08c84` only
while the elapsed gameplay dispatcher is active and the native engine/start
phase permits the opponent to move. Inactive calls, post-race calls and
VERIFY_DISPATCH_NATIVE execute the original routine through its displaced
prologue. The challenge reset at `$11862` also clears the playback companion.

Each history segment represents 48 fields. The companion keeps the full field
phase while publishing the original byte phase divided by eight for other native
consumers. It renders the current pose, then advances by the current physics
interval for the next call, matching the original pre-physics ordering. A
repeated physics stamp cannot advance twice. An unexpected external cursor or
phase change reseeds from the native values. Pause/replay time is excluded by
the gameplay dispatcher, rather than being charged from a presentation clock.
Wider pause, resume and re-entry acceptance is still required.

Interpolation follows the actual `$08c84` rules, which differ from recording:
X/Z use an unsigned weighted mean; Y truncates the two signed weighted terms
separately before adding them; pitch adjusts only its left endpoint when the
native angular difference exceeds 720; heading and roll use straight signed
interpolation. Results at the six native phases match the original routine.
Weights and sums are widened for fractional field phases. The wrapper clears X
as the original routine's final phase/cursor increment does.

For long frames, every crossed native eight-field position is checked for the
opponent's finish, followed by the actual displayed pose. These are pose/finish
checks only, with no additional physics or scene passes. Once the shared native
finish flag is set, intermediate checks stop. The finish-box comparisons and
message/sound side effects execute a runtime copy of `$08de0..$08e52`; internal
branches exit through its appended RTS, and the install flushes caches after
executable writes. No game instruction bytes are embedded in the source.

The allocation holds 300 records, but the initial ghost generator at `$05a80`
stops before slot 299. The win-copy path fills slot 299 by repeating slot 298.
Playback therefore holds the final initialized record, slot 298 at field 14304,
and clamps its right interpolation endpoint there. The captured initial ghost's
unused slot contained `$2020` words; it must not be treated as a valid pose.
The initial ghost reaches the native eight-field finish test at field 10536,
well before this bound. Fast-frame tests may detect entry into the same finish
box between those native sample times.

Focused evidence retained under ignored `tmp/`:

- `s4-ghost-play-math-final`: six private endpoint pairs at all 48 field phases
  produce 288 poses matching an independent rational model. All 36 native-grid
  poses also match the actual unpatched `$08c84` routine. Cases include unsigned
  coordinate and signed height extremes, angular wrap and negative rounding.
- The same fixture crosses a finish box entirely between displayed poses.
  The copied native finish code sets the expected six globals and calls a
  private sound counter exactly once. It performs five checks across the two
  updates. A subsequent 65535-field interval clamps to slot 298; the held pose
  matches, despite a deliberately conflicting pitch in the unused next slot.
  Synthetic globals and the sound counter are private fixture data.
- `s4-ghost-play-a500`: 180 visits, 177 eligible updates, 1304 advanced fields,
  155 fractional poses and 141 intermediate finish checks all match the model.
  `s4-ghost-play-final-020`: 180 visits, 171 eligible updates, 462 fields,
  151 fractional poses and 38 intermediate checks also match.
- `s4-ghost-play-slow`, CUSTOM4=64 on A500: 15 visits before natural challenge
  exit, 14 eligible updates, 1047 fields, 12 fractional poses and 120 intermediate
  checks. All poses, phases, cursors and finish state match. The A500 and slow
  short captures preceded only the slot 299-to-slot 298 boundary correction;
  their observed positions are far below either bound.
- `s4-ghost-play-finish-020` uses the existing input-only brake fixture from
  field 0, with no gameplay-state injection. It reaches the real opponent finish
  after 4192 visits (4183 eligible), checking 3647 fractional poses and 781
  intermediate finish positions. The displayed pose at field 10532 triggers
  the native finish globals exactly once; the cursor then advances to 10535.
  Every captured opponent pose and cursor matches the retained-history model.
- `s4-ghost-play-finish-a500` uses the same brake fixture and reaches the real
  finish after 1119 visits (1116 eligible), with 984 fractional poses and 1185
  intermediate checks. Every pose and cursor matches the model. The finish is
  detected at ghost field 10533, one field later than the 68020 result, and
  the cursor advances to 10542. This compares opponent history progression,
  not full player handling or absolute race-clock equivalence.
- `s4-ghost-play-native`: all 144 car states match the original Phantom reference,
  with the known gear-table pointer normalized. Both relative ghost cursors,
  both native phases, engine-start phase and challenge active/result flags also
  match. This does not compare all heap actors or every world-state byte.
- `s4-ghost-play-off` passes all inactive ranges, including both new sites, with
  only declared input, entry and slow-drawing fixtures enabled. The ordinary
  build remains byte-identical to the 8392-byte-text baseline. The branch audit
  passes 112 replacement ranges.

This gate alone covers challenge-opponent playback. Without TIME_GHOST_POST,
the two calls in `$1100c` post-race presentation and its distance-derived audio
pitch remain native. No full challenge/re-entry, audio-timing, collision,
handling or FPS acceptance is claimed. Step 4 remains incomplete.


## Phantom post-race presentation (partial implementation)

`VERIFY_TIME_GHOST_POST` requires TIME_GHOST_RECORD and TIME_GHOST_PLAYBACK.
It installs `HardDrivinGhostPost.s` behind CUSTOM1/SPS0126. The native function
still saves both cursors, rewinds each by 30 records with a lower bound at its
buffer, and establishes the camera. The hook at `$1111c` starts a separate
presentation epoch; `$11122` selects both elapsed poses and the exit boundary;
`$111a0` scales the distance-derived pitch; `$11262` clears the epoch and restores
the two saved cursors. Gameplay has ended before the natural call, so this uses
the pause-aware RP_WALL clock rather than accumulating gameplay physics time.

The initial phase comes from the full recorder/opponent companion when its
cursor and published byte still match; otherwise it comes from the native byte
phase multiplied by eight. This keeps the fractional field phase on entering
replay. At each frame, history position is initial phase plus elapsed fields,
with 48 fields per record. Both actors use the native-compatible interpolation
already checked for opponent playback. The existing rewind and stop rules are
preserved: playback ends when either cursor reaches its saved cursor minus one
record. The duration is the smaller remaining interval, bounded below by zero.
It is at most 1392 fields and can be shorter depending on the starting phases
or how much history exists. The terminal interval is clamped to that boundary
before publishing final phases; no pose reads past the saved valid records.
The native saved-cursor restoration remains intact.

The camera code computes distance before `$111a0`. Its consecutive signed-word
distance difference formerly contributed six times that difference to G($9602)
every rendered pass. The new contribution is trunc(delta_distance*48/fields),
so it is still six times the native difference at eight fields per step. The
first frame retains the native startup comparison with distance 1000; a repeated
zero-field frame holds the preceding pitch. Two unsigned divisions compute the
signed result's low word without DIVS overflow on small intervals. The original
word-sized destination and subtraction wrap are retained. This validates the
pitch input arithmetic, not perceived sound quality or the remaining audio paths.

Post-race controls still run at `$11232`. The existing pause hooks freeze the
presentation clock during a modal pause. Post-race overlay interval selection
and restart bookkeeping are wired to this epoch too; the observed replays make
no overlay countdown calls and keep the visible count unchanged, so there is
no live post-race overlay-expiry claim.

VERIFY_DISPATCH_NATIVE exercises this implementation at eight fields per frame.
It also publishes the next phase after drawing, matching the original routine's
observable cursor/phase ordering. The ordinary elapsed path publishes the pose's
current phase and computes the next position from the next clock sample.

Focused checks retained under ignored `tmp/`:

- `s4-ghost-post-020`: naturally reached after the real opponent finish, with
  brake inputs held through the challenge. All 780 frames match both history
  pose models and all 780 derivative-pitch checks pass. Initial phases are
  4/25 fields, target duration 1367 fields, observed duration 1368, last pose at
  age 1366. Both full phases are carried in and both cursors restored.
- `s4-ghost-post-a500`: natural entry, 218 checked frames and pitch updates,
  initial phases 10/40, target 1352 fields, observed 1356, last pose at 1349. These
  durations differ from the 68020 because the histories enter replay at different
  phases; each is checked against its own native rewind/end boundaries.
- `s4-ghost-post-pause`: the input-only VERIFY_GHOST_POST_PAUSE fixture presses
  SPACE after presentation age 24 and resumes 40 input fields later. Exactly 40
  paused fields have one unchanged RP_WALL value. All 777 poses and pitch values
  still match; target 1368 fields, observed 1369, last pose at 1367. No pose or clock
  is injected by the fixture.
- `s4-ghost-post-slow64`: VERIFY_GHOST_POST_SLOW restricts the existing CUSTOM4
  drawing delay to this presentation epoch. With 64 extra fields per submission,
  the replay draws 21 checked frames, crosses multiple history records per frame,
  and exits after 1375 fields against its 1368-field target. Its final displayed
  pose is at 1309; cursor restoration and terminal phases still match. The default
  VERIFY_SLOW behaviour outside this additional fixture is unchanged.
- `s4-ghost-post-math`: 72 signed derivative cases cover word extremes, zero,
  positive/negative changes and intervals 1..65535. Another 384 cases cover every
  initial field phase and cursor crossings through the maximum replay age. All
  results match independent integer models.
- Natural native-step comparison attempts did not reach the post-race anchor.
  Inspections retained their active gameplay state; the reference cursor later
  moved backward, showing a challenge restart before the target. Those runs
  were stopped through their owned cleanup and are excluded from equivalence
  evidence. Their failure is not attributed to the post-race implementation.
- `VERIFY_GHOST_POST_ENTRY` is therefore a separate synthetic comparison fixture:
  after at least 48 records have been produced normally, it submits the frame,
  calls the actual `$1100c` function and returns through native challenge cleanup.
  It changes control flow, without supplying history, pose, velocity or finish
  flags. It deliberately bypasses the natural finish transition.
  `s4-ghost-post-reference-entry` versus `s4-ghost-post-native-entry` matches all
  170 frames and 341 frame/pitch/exit snapshots: both actor poses, relative cursors,
  phases, distance locals, pitch and overlay byte are identical. This is focused
  post-race T=1 evidence, not full driving-tape/world equivalence.
- `s4-ghost-post-off` passes all inactive ranges, including the four new sites.
  Its initial checker invocation named two fixture switches with no independent
  PERF_RANGE; rechecking the same retained capture with the recognized DRIVE,
  STEPINPUT and PHANTOM_ENTRY ranges passes. The ordinary build is byte-identical
  to the 8392-byte-text baseline; the branch audit passes 116 timing ranges.

Instruction-page scrolling and its seven-pass camera move are covered below.
The remaining sound and derivative audit, large-step physics safety, and full
machine/handling/performance acceptance remain open. These results do not
complete step 4.


## Phantom instruction page and camera transition

`VERIFY_TIME_INSTRUCTIONS` requires TIME_TIMELINES and installs
`HardDrivinInstructions.s` behind CUSTOM1/SPS0126. The instruction-page scroll
and its subsequent seven-pass camera move now use the pause-aware RP_WALL clock.
Each epoch starts at its first displayed pose, excluding prior setup work.
The scroll displays `18 + floor(3*min(age,232)/8)` pixels: this keeps the native
first position of 18 and the cap at 105, with three pixels per eight fields.
User input still dismisses the page. The separate camera epoch lasts 56 eligible
fields, preserving seven native steps at the chosen eight-field reference.

The camera uses the native pre-divided displacement words, rather than repeating
or undoing the original division. With `n=min(age+8,56)`, each axis is its initial
word minus `trunc(displacement*n/8)`, with native word wrap. Pitch advances by
`floor(n/8)` and heading by `-2*n`. Absolute interpolation prevents repeated
rounding from losing the seven-step endpoint. A final long frame consumes any
undrawn tail and refreshes the wider XYZ positions before returning to gameplay.
Forced VERIFY_DISPATCH_NATIVE advances the same implementation by eight fields
per displayed pose; it does not bypass the replacement code.

The input-only VERIFY_INSTRUCTIONS_HOLD fixture releases mouse buttons and
supplies the dismissal key after 300 input fields. It uses the existing synthetic
Phantom entry, so these checks do not establish qualification or a full driving
lap. VERIFY_INSTRUCTIONS_PAUSE additionally supplies SPACE after scroll age 24,
and again 40 input fields later. Neither fixture writes poses or simulation clocks.

Retained checks under ignored `tmp/`:

- `s4-instructions-020`: 300 scroll poses and 19 camera poses match the independent
  integer model; the camera lasts exactly 56 fields and reaches the native endpoint.
- `s4-instructions-a500`: 85 scroll poses and five camera poses match; the camera
  lasts 58 fields, including completion of its last drawn frame.
- `s4-instructions-slow64`: five scroll poses and one camera pose with CUSTOM4=64;
  the camera returns after 67 fields with the correct final word and wider positions.
  This explicitly covers a skipped final displayed pose.
- `s4-instructions-pause`: 261 scroll poses and 19 camera poses match. Exactly 40
  paused fields share one RP_WALL value. The subsequent camera lasts 58 fields.
- `s4-instructions-reference` versus `s4-instructions-native`: all 97 scroll,
  camera-before/after and exit snapshots match for the 15 compared values,
  excluding elapsed wall time. This includes all seven native camera poses,
  position words and wider positions, angles, locals and menu mode bytes.
  The original's observed seven-frame camera duration is 80 fields on this A500
  fixture; 56 is the chosen reference-duration target, not that measured duration.
- Independent clock cross-checks show each captured elapsed pose age equals
  RP_WALL minus the epoch start, allowing one field between sampling and the
  breakpoint on A500. The observed menu mode is ADDE=0, ADD7=0, attract=0.
  Native `$d960` only records instant replay when ADDE>5 and ADD7=0, so these
  accelerated menu frames do not add replay records.
- `s4-instructions-integrated-final`: with the current attract, replay, Phantom,
  ghost and CPU-dispatch gates together, 300 scroll poses and 20 camera poses
  pass the same model and final-state checks; camera duration is 59 fields.
  The initial combined capture failed before calibration because its local socket
  path was too long; its owned processes were closed and it is excluded. The
  successful run uses a shorter local instance name.
- The retained CUSTOM1-off capture passes all 142 declared ranges, including
  the five new timing sites and the inactive input fixture. The direct-branch
  audit passes 121 timing ranges. The ordinary build is byte-identical to the
  8392-byte-text baseline.

This closes the identified Phantom instruction/camera timing conversion. It
is not full step-4 acceptance: the remaining audio audit, large-step physics
safety, full native/equal-time handling and performance matrix, and human laps
are still required.


## Sound audit and replay request cadence

See AUDIO_TIMING.md for the native caller inventory, field-driven audio setup,
absolute RPM/pitch conversion and remaining repeated live-driving requests.
TIME_REPLAY_TIMING now consumes each recorded skid request once, including
crossed records and the final undrawn tail. Private history and live no-skid
replay checks pass; sample-start and listening acceptance remain open.

The optional TIME_AUDIO gate now gives live off-road requests an eight-field
wall-clock cadence with retained remainder. Actual sample starts and native-step
sound equivalence have focused validation; see AUDIO_TIMING.md. Other repeated
live sound callers remain open.
