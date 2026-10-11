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
run catch-up substeps or remove CUSTOM2. Normal builds exclude the entire module.

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
claim yet about scaled menu/replay durations or input latching for substeps.

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
  Position is still unscaled, so this is steering arithmetic evidence only.
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
changes; nonlinear handling acceptance remains open. It does not yet incorporate
fractional longitudinal velocity in the native trigonometric projection. Crash
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

Remaining work includes the actual simulation dispatcher, fractional projection,
live small-T contact validation,
held-input handling, traffic/contact policies, replay/Phantom and other
presentation timelines, performance and cross-machine acceptance, and the
required human laps. The BCD clock defect versus lap-time acceptance conflict
remains unresolved; the implementation currently preserves the native clocks.
