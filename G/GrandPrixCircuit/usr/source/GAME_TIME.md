# Grand Prix Circuit v1 game-time model

Phase 3 investigation, 2026-10-12. Applies only to the 94,708-byte executable.
Code addresses are hunk-0 offsets, not file offsets (add `$28` for the file).
Data addresses below are signed decimal offsets from a4 unless prefixed `$`.
This is a map of the original game and measurement instruments, not an implemented
higher-rate simulation. The step cadence is fixed, but starts and car collisions couple
gameplay to drawing; the original PAL lap clock runs slow. Phase 4 must settle gameplay
policy before any conversion.

## Clocks and ownership

The main program is single-task, but its simulation runs in an Exec VBL interrupt
server. The main task draws and handles modal UI. These contexts share live state;
the renderer is not read-only.

| Source / state | Writer and consumers | Native cadence and meaning |
|---|---|---|
| `-31790.l` | `$7734`; menu animation `$42b4/$433a`, pit `$61e6/$6324/$63fc/$662a/$66a6/$66ee` | Increments every native VBL, including pauses. VERIFY input uses this clock relative to `$707a`. |
| `-31736.w` | Pause/modal writers listed below; tested at `$7738` | Any nonzero value freezes active fields and simulation countdown. Native fields and audio continue. No catch-up debt is accumulated. |
| `-29930.w` | `$7742`, initialised to 100 at `$7488` | Active fields, not simulation steps. Wraps as a word. |
| `-29928.w`, `-29926.w` | Countdown at `$7746`, reload at `$774c/$7750`; period remains 6 | One step per six active VBLs. Hunk-1 offsets `$B16/$B18`. No boot speed benchmark sets this period. |
| `-29932.w`, `-29922.w`, `3730.w` | `$a76e` latches active fields; `$7118..7126` subtracts the previous latch | Elapsed active fields between draws. Computed **after** drawing; consumed by the following draw. Initialisation and interruptions can make it stale. |
| `4022.w`, `4020.w`, `4270.w` | `$1c84` initialises; `$1cb6` consumes render delta, changes light/sound phase and enables racing at `$1db8` | Start lights belong to drawing. Countdown starts at 400; thresholds 300, 235, 150, 65. Practice enables racing directly. Delayed drawing changes when player/AI may accelerate and lap time begins. |
| `-31424.w` | `$1dfc..1e30`, called by player update `$7864` | Actual current-lap ticks: +1 per simulation step while `4020 != 0` and finish flag `3728 == 0`. |
| `-31416.w`, `-31422.w`, `3754.w`, `3752.w` | Lap finaliser `$1e32`; finish-line traversal `$7976` | Completed-lap tick sum, lap number, last-lap display value, 50-step display hold. Renderer `$6eea/$6f12` formats the clock. |
| `4024.w` | Cleared `$704e/$7320`; incremented `$783a` except status 7 | Auxiliary simulation counter; **not** the displayed race/lap clock. No direct clock-display reader found. |
| `-31420.l`, `-31414.w`, `-31406.l`, `-31402.w`, `-31412.w`, `-31410.l` | `$1dfc/$1e32` | Speed samples, maximum speed, accumulated statistics and best-lap records. Sampling frequency matters even though these are not motion rates. |
| Pit elapsed time | Saves `-31790` at `$61e6`; divides elapsed fields by 6 through `$ddb4` | The earlier plan's “qualifying fields ×6” was incorrect: this is pit time, **division** by 6, then tenths formatting. |
| `4660.l` and channel state `4664...` | Audio VBL `$b126` | Independent per-field age counter; minimum two-field channel delay and per-field volume ramps. Not scaled with the simulation. |
| Song driver CIA-A timer A | All three songs have the same driver; file offsets `$6ea/$702` program high/low latch, `$6f0/$708` reload/start CRA; `$a44` installs timer-A handler via ciaa.resource | Music uses its own CIA clock. It does not feed the native `$772a` simulation server. Paula audio interrupts are separate again. |
| RNG seed `2002.l` | `$c11e`, beam read `$c12c` | Per call, not per step. Callers include menus, qualifying/grid setup and collision `$a69c`; drawing-dependent collision calls can change RNG history. `CUSTOM3` removes only the beam contribution. |

`$a938` formats its input as tenths (`/10`, then seconds/minutes `/60`). Thus
600 active PAL fields after the start gate give 100 lap ticks: 10 displayed
seconds over approximately 12 real seconds. At nominal 50 Hz the clock runs at
5/6 real time; a six-field period would give ten ticks/s at nominal 60 Hz. NTSC
was not measured here. Correcting the PAL clock is a gameplay change, not an
incidental consequence of raising the simulation rate.

The clock scan covers every pristine file, including startup/accolade and all
three songs, all CIA timer latches/control/interrupt/TOD addresses, beam registers,
resource names and `timer.device`. Hits were inspected as code, rather than treating
binary constants as executed accesses. The main executable's absolute CIA access
is joystick/fire input; its beam read is RNG. The song CIA clock is real and must
not be mistaken for the race clock. Exec AddIntServer installs `$772a` for VERTB;
trace counts establish its field cadence. DOS Delay is also used in UI/service
animations; the inherited `$174` delay hook remains unchanged. No additional
CIA/OS time source was found feeding race physics. This is not a proof about
unavailable executable versions.

## State and rate inventory

The step is `$776a` → `$a288` → `$782e` → `$8010`. The common completion point is
`$7762`, before register restoration and RTS. Player movement integrates old speed
before input and acceleration; AI runs before the player. Preserve that ordering
when testing a smaller timestep.

| State / writer | What advances | Treatment required if the step period changes |
|---|---|---|
| Player segment `-30016.l`, fraction low byte of `-30012.w`, `$7e2c` | Adds `(speed >> 7) + ((speed >> 7) >> 1)` in fraction units; carries traversed segments to `-20654` | Scale travel per time with private fractional carry. Preserve every crossed-segment event. Speed `-29944.w` is Q8.8; do not rescale speed thresholds. |
| `$795c..7b3a` segment walker | Lap line `-29936`, road/curve state `-29516/-29526`, yaw and lateral movement, wrap/lap distance `-30004` | Mostly per-distance work: do not multiply it by update frequency or scale impulses per crossed segment. Preserve traversal ordering and distance thresholds. |
| Steering `$6854..69ea` | Human input force (`176 * input`), feedback, steering integration `-29528`; clamps force ±2560 and angle ±3712 | Scale integrated changes, retain state limits; force/feedback must be converted together. Attract substitutes `-2*curve` and clears yaw, so it does not validate human steering. |
| Steering relaxation `$6910..6920` | `yaw -= yaw >> 4`; `steering -= steering >> 3`, conditionally while moving on a straight | Requires time-equivalent relaxation, fractional precision and the same conditions. It is not two constants to divide blindly. |
| Segment-conditioned spin `$6874..68a2`, skid `$79ce..7a4e` | ±7680 yaw when the “crossed a segment” flag is set; curvature/grip tests, speed loss capped at 512 per traversed segment | Distinguish a per-step test of a segment flag from the segment loop itself. Preserve event/threshold semantics; test several segments crossed in one native step. |
| Speed/RPM `$7e66..7fcc`, `$77c0/$77e0`, `$806a` | Braking by car parameter `-23742`; torque minus drag integrated into Q8.8 speed; free RPM −400 or `+1150 + RPM/16`, an additional +40 branch | Additive rates need elapsed-time scaling/carry; state-derived RPM, torque lookup, minimum/maximum RPM and gear ratios remain magnitudes. Nonlinear RPM growth needs equivalent evolution, not simple constant division. |
| Gear state `-29818/-29820/-29814/-29812`, lever `-29810/-29808` → target `-29806/-29804`, `$7c04..7e26/$7e7c` | Gear decisions, lever motion by 12, completion, clutch shock, wheelspin duration `-30022` | Retain the original six-field decision/gear cadence unless separately justified. The shift shock changes speed by −5 or +18 integer units once; it is an impulse, not a per-second rate. |
| Thermal `$776a` | Heat `-20718 += 3718` above threshold; overheat sets status 3/inhibit and subtracts 768 speed per step | Heat gain and coast-down rates need scaling. Cooling `$77b0` subtracts **d0**, which `$774c` has just loaded with the period: it already removes one heat unit per active field. Preserve this dataflow; do not scale that term twice. The intervening d4 calculation does not supply the subtraction. Preserve engine thresholds. |
| Post-step `$8010` | Inhibited/crashed deceleration 1280; collision yaw adds `-29968`; skid deceleration 1536 until speed <30 | Scale ongoing decay/rotation, retain thresholds and entry impulses. Collision animation phase `-29970/-29972` advances in AI at six-field cadence. |
| Damage `$7fce`, barrier `$7b8e` | Condition `3708`, brake/grip parameters; barrier sets zero speed/condition and status 4 | Distance/contact events, not unconditionally per-tick rates. Preserve per-event damage and fatal transitions. |
| Player animation/inactivity `$782e/$786c` | Phase `-2014 += 8`; no-input counter `-20716` reaches 2000; wheelspin duration decremented `$7b44` | Keep animation/timeout duration at the original cadence, distinct from motion. Input decoding and edge-triggered gear/UI commands must not repeat more often accidentally. |
| AI positions `6+4*i`, fractions `46+2*i`, speed `-34+2*i`, `$a2c4..a2e2` | Ten slots, slot 0 represents player and nine are opponents. AI speed is Q8.8 **segments per native tick**, unlike player speed's unit conversion | Scale integrated position, not target/max speed values. Wrap updates lap distance `-134+4*i` per event. |
| AI speed `$a20e` | Lookup acceleration indexed by speed, difficulty and per-car personality; target `106/126+2*i`, deceleration capped at 16 | Scale acceleration/deceleration with carry, preserve target magnitudes. Do not accelerate personality sampling. |
| AI lane `$a09a/$a12a` | Lateral `-14+2*i` approaches target `86+2*i` by `66+2*i` (usually 80); cooldown `-154+2*i` | Scale lateral integration; keep 30-step cooldown and lane decisions on native cadence. Avoidance can reduce a speed target by a quarter; repeated decisions change behaviour. |
| AI sorting/gaps `$a3b8/$a43e/$a464` | Order `226+2*rank`, gaps `146+4*rank`, close-gap position correction | Derived ordering is not a rate. The one-segment correction and lane-choice events are discrete and must not be multiplied by new tick frequency. |
| Lap/statistics `$1dfc/$1e32` | Tick count, speed sum, last-lap hold, maximum/best records | Retain original time and sampling units unless Phase 4 explicitly chooses real-time clock correction. Do not multiply averages or shorten display holds. |
| Renderer `$6a28/$99fa` | Gear-display timer `-29956 -= 3730`; overheat smoke phase `-842 += 3730`, reset to 48 at ≥96 | Already elapsed-field driven, with draw-boundary latency and truncation. Leave out of physics-rate scaling. |

## Drawing and modal exceptions

- `$a58c` is called before the render latch at `$729a`. It examines car gaps and
  lateral separation, then **writes live game state**: `$a60c` moves the player back
  one segment, `$a610` subtracts 768 speed, and subsequent code uses latched speed
  (`-194` and opponent entries) and skill to apply condition loss, crash/inhibit,
  collision partner and random spin. Collision frequency and the age of its inputs
  depend on drawing. It cannot safely be described as a pure frame preparation call.
- The latch `$a6ea` copies live fields and car arrays without excluding the VBL.
  A draw can therefore combine data from two completed ticks. This is separate
  from the buffer-ownership problem behind the reported blinking buildings.
- Start-light changes occur only inside dashboard drawing (`$6ddc` → `$1cb6`).
  Elapsed-field deltas do not make the threshold event instantaneous. A very large
  delta can even reach the `countdown <= 0` return before the go-state branch;
  that is a static edge case, not a tested normal-frame outcome.
- Ctrl-P is recognised in the native keyboard path at `$78be`, which sets pause
  to −1. The current interrupt finishes; later native VBLs skip the step. The main
  loop sees the flag at `$7094`, displays the message and blocks in native key
  input (`$70f6`), then clears it at `$70fa`. No deferred world ticks are repaid.
- Pit eligibility is checked by the main loop: pit flag `-1864`, zero speed and
  lateral position <−1306. `$720e` sets pause; `$7226` enters `$5f5e`. Pit entry
  `$5f62` writes 1, service/menu `$61e2` clears it, exit `$66e8` sets 1 again,
  and race return `$7250` clears it. Thus “the pit is paused” is incorrect:
  simulation runs during the native service interval. Pit displays use live fields
  even while physics is paused. Repair amounts are event-based; animation uses
  native input/Delay and draw work. Entry/exit and message latency can depend on CPU.
- Crash/overheat/spin do not globally stop the VBL step. They use the rates above
  until main-loop terminal processing sees speed zero and writes pause at `$71e4`.
  Status 7/finish flag `3728` freezes lap time while the car coasts; presentation,
  sounds and exit wait remain in the main task. There is no TD2-style recovery
  replacement in this phase.

The exception inventory is based on all direct writers of these counters/flags,
call-site analysis and the recorded windows. It is not a claim that the short
attract fixture completes a lap, enters a pit, tests human handling or exercises
every crash/spin branch. Those behavioural checks remain mandatory before Phase 6
can claim equivalence.

## Coupling measurements

Same VERIFY binary and field-indexed joystick tape, beam contribution to RNG disabled,
PAL, normal six-field period, `CUSTOM2=0`. Each arm starts at the first race-loop entry
and records 720 successive native VBL boundaries. The A500 is 68000/512 KB chip/1.5 MB
slow; expanded A1200 is 68EC020/2 MB chip/4 MB fast, observed CACR=0. All six windows
have **120 steps, no paused fields, and period 6 throughout**.

| Fixture / machine | Publications | First observed go field | Lap ticks at field 720 | Player segment relative to track origin |
|---|---:|---:|---:|---:|
| Solo attract, A500 | 71 | 310 | 68 | 83 |
| Solo attract, A500, slow draw | 41 | 327 | 65 | 78 |
| Solo attract, A1200 | 180 | 305 | 69 | 84 |
| Traffic fixture, A500 | 66 | 315 | 67 | 82 |
| Traffic fixture, A500, slow draw | 39 | 321 | 66 | 81 |
| Traffic fixture, A1200 | 169 | 304 | 69 | 85 |

These are publication counts over a window **including the start lights**, not
replacement steady-driving fps baselines. Phase 2's 5.6402 / 14.5226 / 24.6747 fps
(A500 / expanded A1200 / 68030 at 25 MHz) remain the baseline measurements.

For A500 normal/slow traffic the simulation phase, active fields, raw decoded joystick
and auxiliary tick counter agree; the first race-running difference is observed at
field 315, then lap time, speed and all nine AI speed/fraction values differ at field
319. At field 720 speed is 33571 versus 33074 (Q8.8), lap time 67 versus 66 ticks.
Matching **lap ticks 1..66**, instead of elapsed fields, gives identical decoded player
motion, condition, heat, RNG, and all ten slots' segment/fraction/speed/lateral/cooldown
values. This window's motion difference follows the shifted start gate. It does not
establish that later collisions are drawing-independent.

Independent snapshots at the common step-completion point `$7762` confirm the same
result: at completed step 54 (native field 319) A500 normal has lap tick 1 and speed 352,
while slow draw still has lap tick 0 and speed 0. The 120 completed-step samples have
identical native fields, countdown, auxiliary tick count and raw joystick values across
that pair. Thus this difference is not an observation halfway through a VBL update.

The whole allocated data hunk does not match across drawing rates; render state and
latched values differ even before the start gate. The reports retain all differing
offsets. The decoded comparison explicitly names its quantities and normalises code/data
pointers and player/AI track positions; it does not hide arbitrary byte ranges. The CPU
comparison also starts with a different pre-race active-field/countdown phase, so it is
not an identical-initial-state human-handling test. The equal-phase A500 slow-draw pair
is the cleaner causal test.

`CUSTOM4` waits for eight observed native VBL transitions before replaying the two
original calls at `$729a/$729e`. It is absent when off, uses no STOP, host sleep or game
state writes, preserves registers/X, and skips the pre-race draw before the first race
anchor. `CUSTOM1` supplies a fixed permutation of car IDs 0..9 at `3732..3750` and enables
opponents before native `$9f24` grid initialisation. Native code then builds and advances
all car state. This is explicitly an **artificial attract-with-traffic fixture**, not a
UI-entered championship or proof of human steering equivalence. All nine opponents move
forward in accepted captures. The unmodified attract fixture has no active opponents.

An initial traffic fixture set only the opponent flag, leaving the qualifying grid-order
table zeroed. That initialised player slot 0 ten times; repeated collision corrections
pushed the player backwards, as the user observed. Those runs were rejected, never used
for the AI price below. The corrected harness checks the permutation and populated car
slots before recording; traces also require nine opponent-update calls per priced step.
An initial delay fixture also affected pre-race drawing; final comparisons use the
race-gated delay. Only `accepted-*` evidence below represents the final instruments.

## Native step price and Phase 4 input

100-field traces after 600 warm-up fields, with the corrected traffic fixture and no
slow-draw delay. Sum actual instruction cycle records from `$772a` through the return at
`$7768`, including callees and contention. This is **native VBL callback time**, not the
entire hardware interrupt: Exec/KickEmu dispatch and unrelated sound/blitter IRQ service
remain additional costs. All 100 callbacks are present in each trace; there is no callback
reentry. Each stepped callback executes nine `$a09a` opponent updates.

| Machine | Priced steps | Step cycles min / mean / max | Non-step callback mean | AI portion mean | Player portion mean |
|---|---:|---:|---:|---:|---:|
| A500 68000 | 16 | 31,112 / 32,305 / 33,898 | 371 | 25,823 | 5,744 |
| Expanded A1200 68EC020, CACR=0 | 17 | 16,563 / 16,921 / 17,285 | 251 | 13,631 | 2,859 |

Using the recorded field budgets (142,101.9 and 284,203.6 CPU cycles), project the native
callback share as `(step + (period−1)*nonstep) / (period*field_budget)`:

| Machine | Period 6 mean / sampled-max | Period 2 mean / sampled-max | Period 1 mean / sampled-max |
|---|---:|---:|---:|
| A500 | 4.01% / 4.20% | 11.50% / 12.06% | 22.73% / 23.85% |
| Expanded A1200 | 1.07% / 1.09% | 3.02% / 3.09% | 5.95% / 6.08% |

“Sampled-max” uses the maximum step and non-step callback in this window; it is not a
worst-case deadline guarantee. These projections repeat the measured native work and do
not include future scaling helpers, altered decision cadence or all driving situations.
The proposed periods 6/2 have room in this measured simulation budget. Period 1 is not
ruled out by the sampled 020 simulation cost, but **50 rendered fps is not established**:
the same populated-traffic traces publish at 5.0 / 13.02 fps between first/last swaps,
and even Phase 2's faster 68030/25 baseline is 24.67 fps. No period or cache change has
been made. Solo Phase 2 step means were only 4,426 / 2,756 cycles; treating those as a
full-race simulation price would have badly understated AI work.

Phase 4 must choose what “original gameplay” means for the slow PAL clock and
CPU/drawing-dependent starts/collisions before Phase 6 changes their scheduling. Preserve
native modal boundaries and rate/event distinctions above. A higher-rate human-handling,
crash/spin, full-lap and pit acceptance matrix is still needed when there is an actual
implementation to compare. The blinking horizon/buffer issue remains Phase 5.

## Reproducibility and scope

The ignored harness contains tools, original inputs, retained slaves, metadata, full RAM
at window boundaries, VBL snapshots, traces and debugger transcripts. No game bytes or
SDK material is committed. Evidence root: `tmp/dev/tmp/phase3/`.

- `accepted-{a500-control,a500-slow,a1200-control,a500-traffic,a500-traffic-slow,a1200-traffic}`:
  720-field data snapshots and step/publication counts. `summary.json` and
  `accepted-{solo-slow,solo-cpu,traffic-slow,traffic-cpu}.json` retain decoded results and
  all whole-data differences. `accepted-traffic-race-tick-alignment.json` names every
  quantity in the 66 matched race-tick comparison.
- `accepted-a500-traffic-repeat` / `accepted-repeat.json`: a fresh boot matches all
  720 complete allocated-data snapshots and all step/publication counts exactly.
- `accepted-ticks-{a500-0,a500-1,a1200}`: 120 common-exit snapshots each;
  `accepted-completed-ticks-{slow,cpu}.json` records the full comparison.
- `accepted-cost-{a500,a1200}`: original 100-field Barto trace, before/after RAM, screenshots,
  publication report, `step-cost.json` with every priced callback and component costs.
- `clock-scan.json`, `native.dis`, song disassemblies: local, original-file-derived audit
  evidence. `REJECTED.txt` identifies superseded captures and why they cannot be quoted.
- The data hunk's `$8918` file payload is **not** its complete runtime size: the hunk header
  allocates `$9364`, and native startup clears the `$A4C` tail. Capture/comparison tools now
  include that tail. Negative controls reject a changed BSS race flag and truncation.
  Earlier Phase 2 full RAM dumps retained the tail, so the two-boot comparisons were
  rerun over the corrected extent: A500 and A1200 still match at both boundaries and in
  every instruction/register/cycle record, DMA record and active pixel.

The normal slave remains SHA-256
`e7d4b1361817ede24db993d8d19969ac11887352d6e8b45e2c628391a15d908d`, byte-identical to
Phase 1. The final VERIFY instrument binary is
`7af8f2f025632252c316c1ef6aa0991b254165edc2fac2d6a14784d41b01d0ed`.
All new source hooks are within `IFD VERIFY`; `CUSTOM2` still has no effect.

Both vasm targets build successfully. `check_phase3.py` verifies all original immutable
code, the existing JOTD patches and 139 jump stubs after restoring only the exact enabled
VERIFY spans; a corrupted swap instruction fails its negative control. Normal/slow/traffic
combinations and both CPUs pass. The eight-span boundary/branch audit passes. All 55
pristine files retain their manifest hashes. No Phase 4 decision or Phase 5/6 patch is
included in this commit.
