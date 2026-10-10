# Red Baron game-time investigation

Status: W6 analysis complete; the user authorized the [implementation plan](game-time-plan.md)
and added smooth 50 FPS on capable hardware. Implementation is in progress; no
player game-time change is enabled yet. The original investigation ledger below is retained;
new results and the proposed implementation contract follow it. VERIFY-only
experiments deliberately change clocks/initial conditions and are not player fixes.

The sections preceding “W6 decision evidence” retain the chronological W0–W5
ledger. Their then-open questions are superseded by the W6 results and explicit
remaining acceptance gates below; they are not claims that those gates passed.

## Clocks and observers

The existing CIA-B timer dispatch at `sim:2ffcc` increments lifetime ticks and advances the
countdown used by the main loop. The VERIFY step ring now records lifetime ticks, VBlanks,
elapsed argument, both dt values, F, Time Scale, world-step count and message countdown.
In the tested Time Scale 40 window it reports F=33 and world dt=450.

`sim:3d34` computes two clocks through `sim:3cee`: the player-selected F produces
`h3:04834`, and the secondary F at `h3:00718` produces `h3:04836`. The elapsed argument is
stored at `h3:0483a`. The scalar calculation clamps the quotient to [64,450]. This alone
does **not** describe every downstream integration operation.

## Additional coupling found during W0

The plan's shorthand description of `sim:3d68` as x·dt/256 is incomplete. Inspection of
`sim:3d70–3d92` shows a branch at **dt > 400**:

- dt <= 400: multiply the signed word input by dt and arithmetic-shift the result by eight.
- dt > 400: double the input with **word addition**, then sign-extend that word.
- The resulting long is bounded to [-32767,32767]. In the high-dt path, word overflow has
  already happened before this bound is applied.

`sim:3dba` makes the same dt>400 choice using the **secondary** clock. `sim:3e94` also has
a dt>400 word-doubling path. Raising the scalar clamp alone would therefore leave these
operations insensitive to any dt above 400. It would not establish frame-rate-independent
motion, while other timers would advance by the larger scalar dt.

For a simple non-overflowing example, input 100 yields 156 at dt=400 but 200 at dt=401
or 450 in `sim:3d68`. Two calls at dt=225 yield 87 each, not the same result as one call
at dt=450. This demonstrates why sub-stepping must be assessed as a game-time design
change, not assumed to reproduce one original large step exactly. These are instruction
semantics examples; they are not measured aircraft trajectories.

Consequently, the baseline's approximate “44% of nominal” scalar-dt ratio is not a proof
of the same ratio for airspeed, distance or every simulation subsystem. Establish nominal
speed from the required position/airspeed/heading measurements before choosing a design.

## Direct clock-reader inventory

The inspected relocated-code references identify these direct accesses:

| Reader | Clock | Operation |
| --- | --- | --- |
| `sim:3d68` | `h3:04834` | Signed scale; dt>400 word-doubling special case |
| `sim:3dba` | `h3:04836` | Secondary-clock version of that scale |
| `sim:3e0a` | `h3:04834` | Inverse scale, signed input shifted left eight then divided |
| `sim:3e2e` | `h3:04834` | Word countdown, limited decrement |
| `sim:3e4a` | `h3:04834` | Word accumulator, wrapping addition |
| `sim:3e5e` | `h3:04834` | Long countdown, clear and signal when expired |
| `sim:3e7e` | `h3:04834` | Long accumulator |
| `sim:3e94` | `h3:04834` | Scale with additional output; dt>400 special case |

Initializers at `sim:3cd0/3cd6` and stores at `sim:3d4e/3d5e` write the clocks. The static
inventory must still be checked for indirect references and all caller subtrees. It is
not yet a claim that every coupling is accounted for.

## Design direction to test, not authorization to implement

A fixed or bounded simulation tick with catch-up remains the leading hypothesis because
Time Compress already supports multiple world steps per rendered frame. It would separate
render cost from elapsed world time without relying on arbitrarily large integration steps.
However, the dt>400 shortcuts, integer truncation, input cadence, message timing and
secondary clock require explicit policies. A cap by itself does not solve these couplings.

Initial investigation checklist (historical; disposition below):

1. Use the verified position/velocity/heading observations and elapsed-time reference below; extend them to the force and contact tests.
2. Inventory indirect clock reads and per-world-step/per-render-step counters.
3. Test forced dt 225/450/900/~2200, including the newly identified >400 paths, against
   smaller-step trajectory, ground-contact, bullet-hit, AI and collision references.
4. Compare equal-wall-time world state with and without a VERIFY rendering delay in the
   tracking regime, and equal-step state in the clamped regime.
5. Measure catch-up cost on the A500-equivalent machine and assess fractional accumulation.
6. Present the evidence, compatibility policy and recommended design for user approval.

Rendering optimizations may still accelerate the world on slow machines until that approved
work lands, as accepted in plan §6. Sound remains unchanged.

## First slowed-drawing coupling test

One identical VERIFY binary was booted twice with CUSTOM5=0 and CUSTOM5=1. Bit 0
installs a delay at the first flight step only, leaving menu timing identical. The
whole six-byte JMP at `sim:015b2` is checked against its expected relocated target
`sim:2c552`, then replaced by a wrapper that preserves register inputs, SP and X.
Three stable beam wraps add two whole fields plus an initial partial field before
tail-calling the original renderer. This is instrumentation, not a game-time fix.

Both complete h3 snapshots were byte-identical at step 1. At step 20, exactly two
bytes differed, without needing pointer normalization:

| Field | Original drawing | Slowed drawing | Evidence |
| --- | ---: | ---: | --- |
| `h3:0483a` elapsed argument | 112 | 124 | Written at `sim:3d58` |
| `h3:03f5a` timer timestamp | 8,908 | 8,914 | Timer object passed at `sim:2abce`, `sim:2ad8a`, `sim:2b476`; `sim:2976c` copies lifetime CIA ticks to its first longword |

The duration word following that timestamp remained 5. `sim:2972c` tests such timers
against lifetime CIA ticks. This is a real clock-dependent timer, so it must not be
silently discarded as arbitrary noise. Its effect over longer windows still needs
to be established. Every other byte in the complete h3 allocation matched at step 20,
and both time-step variables remained 450 throughout the 19 intervals.

The delayed run accumulated 46 additional VBlanks and 55 additional CIA ticks. A
different-step comparison correctly reports differences, providing a negative control
for the comparison tool. h3 equality does not establish equality of separately
allocated objects addressed by its pointers; the player-object/time-scale study and
longer coupling runs remain required before recommending the final timing design.

## Player trajectory already retained by the game

The player pointer is `h3:04578`. The world loop passes it at `sim:010fc` through
`sim:01102` to `sim:15128`. That routine increments `h3:067c6`, wrapping at 100,
and copies the player's three position longwords (object bytes 8–19) into the
12-byte slots at `h3:067cc`. It also copies three orientation words (object bytes
20–25) into the six-byte slots at `h3:06c7c`. This gives a trajectory observer
without adding work to the emulated frame loop. Physical distance units and the
compass convention still require calibration; do not label raw values as metres,
feet, or degrees yet.

`player_history.py` decodes this ring from a complete h3 snapshot. The caller must
request only initialized slots. The retained step-20 snapshots from the slowed-
drawing experiment contain the same **20 successive positions and orientations**,
including the step-1 position independently retained in the earlier snapshot:

| Checkpoint | Raw position triplet | Raw orientation triplet |
| --- | --- | --- |
| Step 1 | 75,970; 323,520; 43,939 | 192; 0; −26,624 |
| Step 20 | 81,883; 314,679; 44,678 | 192; 0; −26,624 |

The history indices are 39 and 58. This extends the earlier h3 comparison from an
uninterpreted byte match to a checked player trajectory in the clamped regime:
slower drawing changes elapsed wall time but leaves those positions unchanged at
equal steps. It does not prove equality of every heap object, establish nominal
world speed, or replace the Time Scale 0/40/60 and collision experiments. The velocity observer is now verified in the later section below.

## Time Scale fixtures and first trajectory measurements

`tools/time_scale_fixture.py` copies the installation and changes only the first
big-endian word of `data/SIMPREFS.PRF`. `sim:47c8/47ce` loads the preference block
and `sim:480e` copies that word to `h3:03d56`. The source installation stays at
40; the test copies contain 0 and 60. Only file byte 1 differs in each copy.
The remaining preferences and the sim executable are unchanged. Each fixture
retains the original/modified preference hashes and sim hash.

Three clean boots of the same 30,324-byte VERIFY text use the cached 50 MHz
68030 configuration documented in `profiling.md`: MMU explicitly enabled,
emulated data cache enabled, accurate CPU and blitter timing, no performance
bits, no bank input. The native route maximizes detail without changing Time Scale.
The ring independently confirms settings 0/40/60 and divisors 80/33/10.

Read-only breakpoints collect 35 player objects at flight steps 126–160. The
35 positions and orientations in each run match the game's own history exactly.
Each interval contains one world update. The summarizer rejects gaps, duplicate
ring records, clock reversals, changed settings and native-history mismatches.

| Time Scale | F | Elapsed PAL fields | CIA ticks | dt values observed | Path length, raw units | Raw units per 50 fields | Object word +f6 |
| ---: | ---: | ---: | ---: | --- | ---: | ---: | --- |
| 0 | 80 | 201 | 239 | 64, 89, 102, 115 | 3,335.940 | 829.836 | 1280 |
| 40 | 33 | 136 | 161 | 124, 155 | 5,401.245 | 1,985.752 | 1280 |
| 60 | 10 | 135 | 160 | 409, 450 | 19,078.014 | 7,065.931 | 1301, 1303 |

Path length sums successive three-dimensional position differences, rather than
using only the endpoint displacement. These are movement observations, not FPS
benchmarks: the short equal-step windows do not establish equal scene workload.
The retained object includes velocity candidates at +ca/+d0 and +f4/+fa.
`sim:183fa` scales the six words at physics-structure +36 through +40 into
+0c through +16 using `h3:072a6`; that structure begins at player object +be.
`sim:198a8` separately copies object +f6 to `h3:071b0`. This establishes the
field relationships, but physical airspeed units still need calibration.

At Time Scale 0 the dt floor is reached; at 60 every sampled dt takes the
word-doubling branch described above. Consequently the approximate inverse-F
relationship cannot by itself define physical nominal speed across these runs.
The CIA handler at `sim:2ffdc` subtracts **four** from the elapsed countdown
for each lifetime tick; one countdown unit must not be mistaken for one CIA tick.

Local evidence is retained under `w0-time-scale{0,40,60}-cached030` with the
player objects, first/last h3 snapshots and complete step ring. Reproduce each
summary with `tools/player_motion.py CAPTURE_DIRECTORY`. W0.6 remains open
until the timer coupling is classified. The later sections now provide that
classification and the verified velocity/elapsed-time reference; neither
authorizes a timing change.

## Verified velocity and position interpretation

The native forward-velocity word is player object +f6. `sim:198a8` copies it
to `h3:071b0`, and `sim:1a112` reads that value to position the cockpit
airspeed indication. It is distinct from the world-coordinate position delta.
The three native body-velocity words are at +f4/+f6/+f8; their rotated
world-velocity counterparts are at +fa/+fc/+fe.

`sim:183fa` converts all six words into +ca through +d4 using the factor
`h3:072a6` and the signed multiply/shift helper `sim:2c346` (via `sim:14b0e`).
The factor is 220 throughout the retained samples. For forward velocity 1280,
the converted word is floor(1280 × 220 / 1024) = **275**. All **630 converted
velocity words** in the 105 snapshots match this calculation. These are
verified internal velocity units; no conversion to mph or physical distance
units is asserted.

The airborne position path at `sim:1918a–19234` averages the old and new
world velocities with word arithmetic, adds the altitude-selected wind from
`h3:01c86`, and applies `sim:3d68`. `sim:18398` then multiplies by the same
factor, shifts by ten and carries a signed fractional remainder through
`sim:18364`. The player's three remainders are at object +100/+102/+104.
The retained wind is (0, −1, 0) in every altitude band.

`tools/player_kinematics.py` reproduces **all 306 coordinate updates and their
306 resulting fractional remainders exactly** across the three Time Scale
windows. It uses observed old/new velocity as input; it does not claim to
model aerodynamic forces, collisions or ground contact. This check also
confirms that a step-N observation's dt drives the update to step N+1.

There is an additional rounding quirk: `sim:18398` combines an arithmetic
right shift of a negative product with a negative remainder. For a product
of −22,000, the integer contribution is −22 and the remainder is −496.
Truncating division would instead give −21; substituting that would change
the trajectory. The host regression checks retain this behavior and the
dt=400/401 discontinuity and word overflow.

### Nominal elapsed-time reference

A useful reference for W6 is the unbounded elapsed-time coefficient of the
existing clock: four countdown units per CIA tick imply **1024/F dt units
per CIA tick**. In the proportional branch, this gives forward motion of
`native_forward × factor / 1024 × 4/F` position units per CIA tick, before
wind, turns and integer effects. One PAL CIA tick is approximately 1/59.11 s.
Thus the reference specifies a wall-time rate in the game's own verified
units without assuming physical units or mistaking the clamp for elapsed time.

| Time Scale | Nominal forward units/CIA tick | Measured path units/CIA tick |
| ---: | ---: | ---: |
| 0 | 13.750 | 13.958 |
| 40 | 33.333 | 33.548 |
| 60 | 111.805–111.977 | 119.238 |

Forward motion and three-dimensional ground path are different quantities;
these columns are not exact speedup ratios. Wind, orientation, per-step
rounding, the dt floor and the >400 shortcut all remain explicit in the
exact position model. At Time Scale 60, all sampled steps take the shortcut,
so dt=409 and dt=450 both multiply their input by two. At Time Scale 40 the
samples use the proportional branch. This is why the earlier scalar “44%”
statement cannot define nominal physical speed for all subsystems.

Use this elapsed-time reference when evaluating a future bounded/fixed-step
design, while preserving and testing the original integration quirks as
separate compatibility choices. This defines the reference to investigate;
it does not approve a timing change or replace W6's collision/force tests.
Reproduce the checks with `tools/player_kinematics.py CAPTURE_DIRECTORY`.

## Timestamp coupling classification for the step-locked test

The differing `h3:03f5a` longword is a timer-start timestamp, not an RNG
seed or a physics clock. An audit of every relocation in the supported sim
executable finds exactly three references into its six-byte timer object:

| Reference | Callee | Effect |
| --- | --- | --- |
| `sim:2abce` | `sim:29760` | Store lifetime CIA ticks and the requested duration |
| `sim:2ad8a` | `sim:29760` | Same setter |
| `sim:2b476` | `sim:2977e` | Clear duration and store lifetime ticks minus one |

Both callees are leaf routines. They write through the supplied pointer,
restore their saved address register, and do not retain or return the timer
pointer. The callers discard or replace the argument after the call. The
neighboring `h3:03f44` and `h3:03f50` references are null-terminated strings
ending before this timer, not bases of a timer array.

The poller `sim:2972c` has one direct caller and one absolute jump stub at
`sim:20c22`. All five direct callers of that stub and the direct caller pass
other timer objects: `h3:03f60`, `03f66`, `03f6c`, `03f72`, `03f78` and
`03f7e`, respectively. None passes `h3:03f5a`. The complete relocation/direct
call audit and the leaf-body inspection therefore classify the observed
difference as **clock-dependent timestamp bookkeeping with no consumer in
the inspected sim v1 timer paths**. No physics or RNG feedback was found
through this timer. Retained evidence: `timer-reference-audit.json` in the
local game-time analysis directory, against the original sim hash recorded
in `profiling.md`.

This resolves the specific W0 coupling observed at step 20: the raw h3
comparison still correctly reports the timestamp and previous elapsed
argument, while all other h3 bytes and all 20 native player-history entries
match. No bytes are silently masked by `compare_h3.py`. This supports the
scoped clamped-regime test; it does not establish equality of arbitrary
heap objects, every mission, or the unclamped tracking regime. Those broader
W6 tests remain required before a timing design is approved.

An attempted debugger read-watchpoint experiment is excluded. It stopped
inconsistently after a positive control and did not reach its requested
checkpoint reliably. It supplies no consumer-coverage evidence; the result
above comes from the original executable audit and the retained state test.

## W1 evidence from identical native starting states

The W1 controlled-start fixture leaves the native menu/preferences path unchanged
and activates rendering patches after the first flight checkpoint. Complete h3
entry snapshots match across CUSTOM2=0, 1 and 3 on each measured CPU. On the
68020, OFF and cache-on still match at step 8; at steps 17–20 their dt histories
are 450 and 341 respectively, and step-20 h3 snapshots differ in 733 bytes.

The cached 68030 censuses reach flight-loop exit at steps 699 (OFF), 817 (table
mirror) and 1,007 (cache). These results demonstrate why equal-step whole-mission
FPS and event counts cannot isolate rendering cost in the variable-step regime.
They do not diagnose every cause of the divergent later mission states, nor prove
a W6 design. Rendering twins remain the correctness evidence. Time Scale stays
40 and the game-time implementation remains unchanged pending the requested design
investigation and approval. The primary W1 evidence and build hash are recorded
in `profiling.md`.

## W6 decision evidence: clock ownership

The original-executable relocation inventory contains **16 references** to
`h3:04834..0483b`: initialization, the two clock stores, the elapsed store,
F setup/read, and the eight helper readers listed above. All **13 relocated
code pointers** to those helpers are absolute JMP stubs. The direct/stub call
inventory is:

| Helper | Candidate call sites |
| --- | ---: |
| `sim:03d68` primary signed scaling | 69 |
| `sim:03dba` secondary signed scaling | 10 |
| `sim:03e0a` inverse scaling | 4 |
| `sim:03e2e` word countdown | 25 |
| `sim:03e4a` word accumulator | 6 |
| `sim:03e5e` long countdown | 7 |
| `sim:03e7e` long accumulator | 1 |
| `sim:03e94` scaling with auxiliary output | 3 |

`game_time_inventory.py` retains every site and its stub destination. It scans
instruction encodings and relocation metadata; arbitrary computed aliases are
not formally excluded. Inspection finds no clock-address escape through the
listed operands or non-stub pointer to a clock helper. This is a supported
sim-v1 inventory, not a proof about unknown versions or arbitrary memory aliases.

**Correction to the initial plan:** the statement “only the world step reads dt;
rendering never reads dt” was too strong. `sim:00ae2`, inside the render routine,
uses the primary word-countdown helper for `h3:045ba`. Secondary scaling is used
by the main-loop command/repeat path at `sim:21b6e`, by camera controls at
`sim:1577e/157c6/157d4/15860/15872/1588a/1589a`, and by the effect transitions
at `sim:05a82/05b0c`. The secondary clock is therefore a separate real-time
service domain, not a second physics dt that can simply be set equal to the
primary quantum. Repeating only `sim:01098` would miss these couplings.

The audited frame/step distinctions relevant to the loop split are:

| Site / state | Current update | Required ownership |
| --- | --- | --- |
| `sim:21d2c/21d34` | One input poll and command pass per outer frame | Timestamped events and held state, independent of renders |
| `sim:012c8/012d6 → 011ca` | Throttle ±20 per command | Preserve one-shot command semantics |
| `sim:0124c`, `h3:045ae` | Unjam-retry countdown reduced by primary dt; reload 1000 | World tick, with original expiry quantization |
| `sim:0131e/01324` | Native world counters increment | World tick |
| `sim:21e10`, `h3:03254` | Outer world-frame count increments | World tick, including catch-up |
| `sim:15128` | Player history index/position/orientation | World tick |
| `sim:0060c`, `h3:04588` | Decrement buffer refresh count | Actual render/buffer publication |
| `sim:0069a`, `h3:06716` | Decrement dashboard redraw count | Actual render/buffer publication |
| `sim:007cc`, `h3:045b8` | Top-text erase count | Actual renders after expiry |
| `sim:0084e`, `h3:04820` | Message life minus 500 per render | Explicit time policy; proposed three active-flight seconds |
| `sim:21e98`, `h3:07856` | Render-request countdown | Render domain; do not consume it in every hidden substep |
| `sim:21f40` | End-of-flight delay reduced by primary dt | Simulation/death-transition service, independent of skipped draws |
| `sim:11d22`, `11e14`, `11f4e` | Per-world-call object age/cyclic emitter counters | Keep per world tick; not per render |

The final row is also a naming correction: the `sim:11c2c` loops include
particle/effect emitters. Calling all eight observed objects “AI” does not
establish their type. Aircraft AI, weapons and effects must retain the original
world-update ordering; pointer reachability matters when comparing their heap
state. The implementation plan makes full active-object comparisons a gate.

## W6 forced-step flight experiment

A single VERIFY build, SHA256
`c96a8c5d6f56b2ac1fd1552cef4eea18c49d4c6ca51afd7ea142521e2d051859`
(text 87,818 bytes), runs the native entry route with no performance bits,
Time Scale 40 and maximum detail on the retained cached 68030/50 configuration.
CUSTOM4 writes **only the primary dt** at each genuine flight input checkpoint,
before its original world update. It accepts 100, 225, 450, 900 or 2200; zero
observes the unmodified clocks. No original clock routine is patched, secondary
time is left original, and Time Compress is off. Every recorded primary dt
matches its requested value; the world counter advances once per interval.

All five initial player objects match. Complete entry h3 differs only in the
explicitly forced word `h3:04834`; no other difference is hidden. This is a
step-size experiment, not a comparison of normal mission speed or CPU FPS.
Evidence: `tmp/dev/tmp/prof/w6-force-{100,225,450,900,2200}/`.

| Equal primary-time budget | dt | World updates | Travelled distance, raw | Difference from small-step reference |
| ---: | ---: | ---: | ---: | ---: |
| 9,900 | 100 | 99 | 10,752.652 | reference |
| 9,900 | 225 | 44 | 10,709.508 | −0.40% |
| 9,900 | 450 | 22 | 12,174.442 | +13.22% |
| 9,900 | 900 | 11 | 6,096.522 | −43.30% |
| 8,800 | 100 | 88 | 9,558.701 | reference |
| 8,800 | 2200 | 4 | 2,220.228 | −76.77% |

Orientation remains the same in these unbanked windows. At budget 9,900 the
native forward-velocity words are 1280, 1279, 1281 and 1283 respectively. The
100/225 endpoint separation is 63.914 raw units; the path percentage is not a
claim of exact trajectory equality. At the common 19,800 budget, dt 225/450/
900/2200 travel 21,406.119 / 24,320.318 / 12,174.442 / 4,990.105 raw units.
The >400 motion shortcut is directly visible: doubling nominal dt from 450 to
900 nearly halves travelled distance for the same accumulated nominal time.

The original airborne integration model verifies **786 coordinate/remainder
updates** and **1,602 velocity conversions** in the retained reference windows.
These checks use observed velocities; they do not claim to model aerodynamic
forces or establish collision convergence. A longer dt=100 capture reaches a
non-integrating player state at step 165: position and velocity stop advancing
while object flags/view fields change. The airborne model correctly rejects
that interval. The full raw capture is retained, but it is not used as the
small-step trajectory reference. No failing coordinate was silently masked.

This is enough to reject “raise the scalar clamp” and “use a large final catch-up
step.” It supports testing 225 as a fixed quantum; it does not approve a new
physics implementation or claim that every quantum below 400 is equivalent.

## W6 equal-wall-time rendering-delay experiment

The same 87,818-byte build was booted with normal and deliberately slower
rendering. CUSTOM4 is zero; the original clocks run throughout. Complete entry
h3 and the first player object are byte-identical. Each run retains 100 player
checkpoints and the independent CIA/VBlank step log.

- Normal: 457 PAL fields / 541 CIA ticks; primary dt 124–372.
- Slow draw: 724 fields / 858 ticks; primary dt 248–434.
- Neither hits the scalar floor 64 or clamp 450. The slow run has one early
  dt=434 at step 2, so it does exercise the separate >400 motion shortcut.

There are **12 exact common elapsed-CIA boundaries**, including entry; no
trajectory interpolation is used. All eleven later common boundaries differ
in player position, by 31.718–83.048 raw units. For example, after 497 CIA ticks,
normal has reached frame 91 and slow frame 57; their position separation is
83.048. This is a scoped failure of render-rate independence in the scalar
tracking regime, including the early shortcut and per-step integer rounding.
It is not a claim that every difference is caused by the one-frame lag alone.

Evidence: `tmp/dev/tmp/prof/w6-tracking-{normal,slow}/`. The committed
`game_time_report.py` validates shared starting state, forced-clock boundaries,
reference models and common-clock comparisons. The earlier W0 clamped-regime
experiment remains valid: equal steps can match while equal wall times do not.

## Ground contact, weapons and collision probes

A second VERIFY fixture adds a one-time low-altitude descent (CUSTOM5 bit 18)
which sets the player's initial vertical position to 512 and downward velocity
to −1024, with matching converted velocity/fraction fields. Bit 19 instead
holds the native fire key. These are synthetic investigation inputs, never
normal mission or performance samples. All cases in this section use SHA256
`15b5d3a76f9319e244f421f04bfe147f65a5d1e99f42e542d93df3d892254000`
(text 87,894 bytes), cached 68030/50, Time Scale 40 and maximum details.

Each ground run reaches one native impact-handler return at `sim:193a2`
through step 11. The logged vertical position is before subsequent ground
correction. All five report native damage-class byte 2 at that event, and all
reach vertical position 50 with that byte cleared by step 11.

| Forced dt | Impact step | Accumulated primary units | Pre-correction vertical position | World vertical velocity |
| ---: | ---: | ---: | ---: | ---: |
| 100 | 6 | 600 | 30 | −900 |
| 225 | 3 | 675 | −22 | −881 |
| 450 | 2 | 900 | −270 | −822 |
| 900 | 2 | 1800 | −270 | −822 |
| 2200 | 2 | 4400 | −270 | −822 |

Evidence: `tmp/dev/tmp/prof/w6-ground-{100,225,450,900,2200}/`.
The extra attempted ground-entry breakpoint logged no events and is not used
as evidence. This is one synthetic impact, not a landing-quality tolerance or
proof of aircraft-to-aircraft collision convergence. It shows that a larger
scalar can consume much more nominal time without changing the contact step.

**Weapon correction:** `h3:045ae` is an unjam-attempt retry timer, not a firing
cooldown. The command-12 path at `sim:01228..01292` decrements it, makes a
probabilistic retry and emits native unjam messages. Actual weapon readiness
is updated at `sim:12194`: scaled increments are capped at 85, then added to
each weapon accumulator. Firing at `sim:1246c` requires readiness above 255;
`sim:12520..12530` resets it to 171 for the player and zero for NPCs. With an
85 increment a player weapon is ready on the next update. Preserve those
rules on world ticks; changing render cadence must not invent a new cooldown.

Two held-fire probes log 40 world updates, including original projectile
movement and collision query results. The first projectile's allocation is
tracked only until its lifetime rises again, which identifies slot reuse.

| Forced dt | Player-owned queries | NPC-owned queries | First projectile observed moves | Scaled distance per move | First projectile path, raw |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 225 | 627 | 10 | 22 | 1307 | 28,753.663 |
| 900 | 185 | 4 | 5 | 2976 | 14,879.830 |

The first projectile's lifetime falls from 4775 to 50 in the 225 case and
4100 to 500 in the 900 case. Its native speed word is 1488 in both. Scaling
at `sim:12866` uses the >400 shortcut, whereas lifetime at `sim:128ee` consumes
the full scalar. The larger step therefore yields about **48.25% less observed
travel before expiry**. Player projectiles begin on successive updates, also
refuting the earlier claim of one shot every three frames.

There are no player-owned hit returns in these windows. The 900 run contains
one NPC-owned hit return at step 19; the 225 run has none. This exercises a
native positive collision result, but different world histories do not prove
collision or AI correctness. The original query is not point-only: it receives
the old position and travel distance, and `sim:11020..1102c` tests an along-ray
component against that distance. Preserve this segment-query behavior. A
controlled hit/near-miss, moving-target, aircraft-collision and AI/RNG matrix
remains required before accepting an implemented scheduler.

Evidence: `tmp/dev/tmp/prof/w6-fire-{225,900}/`. No performance or gameplay
balance claim is made from these synthetic probes.

## Capacity and final recommendation

The retained W5-only A500 trace has seven complete world calls: mean **420,212
inclusive cycles**, range 372,298–458,310, or approximately **59.24 ms** at
7,093,790 CPU cycles/second. Its 100-interval census spans 2,926 PAL fields,
about 586.13 ms per frame, leaving an estimated 526.90 ms of other frame work.
This combines a short routine-cost sample with that census; scene variation,
catch-up ordering and the full W1–W5 bundle require fresh measurements later.

| Time Scale / F | Proposed 225-unit world ticks/s | World-only utilization | Projected render FPS with retained other costs |
| --- | ---: | ---: | ---: |
| 0 / 80 | 3.363 | 19.9% | 1.52 |
| 40 / 33 | 8.153 | 48.3% | 0.98 |
| 60 / 10 | 26.904 | 159.4% | Unsustainable even without rendering |

These are **budget projections, not new scheduler benchmarks**. At the default
setting, a 100-unit quantum alone projects about 108.7% world utilization.
A500 capacity rules out claiming that arbitrary catch-up can always maintain
nominal speed. Retain debt, skip rendering when behind, service input/audio
between bounded batches, and report the supported CPU/Time Scale envelope.
W7 becomes a prerequisite if the default-setting capacity gate fails.

The recommendation is the [fixed-step implementation proposal](game-time-plan.md):
225-unit original world updates, exact CIA credit/remainder, explicit input and
service clocks, and no large residual step. It provides a reproducible simulation
sequence independent of how renders partition elapsed time. At low Time Scale,
its coarse tick cadence is an explicit responsiveness/visual tradeoff that must
be evaluated. Variable bounded steps were not selected: they still vary rounding,
weapon/AI opportunities and event order with frame partition. Fixing those would
require per-state fractional accounting and a much broader semantic rewrite.
Raising the clamp is rejected by both static helper semantics and live probes.

The analysis is complete at the level needed to approve or revise this prototype
plan. It does **not** establish full combat convergence, bank/stall accuracy,
heap-state equivalence or sustained catch-up performance of code that does not
yet exist. Those are explicit implementation gates; a failure may require changing
the quantum or doing W7 first. The later W6 request authorizes implementation, including the added 50 FPS
requirement. The experiments above remain evidence for the design, not proof
of its eventual implementation.

## Reproduction and validation

Committed analysis tools operate on the retained local evidence:

```sh
python3 R/RedBaron/tools/game_time_report.py tmp/dev/tmp/prof --out tmp/dev/tmp/game-time/w6-results.json
python3 R/RedBaron/tools/game_time_inventory.py tmp/dev/tmp/game/RedBaron_v2.1/RedBaron/data/sim --out tmp/dev/tmp/game-time/w6-inventory.json
python3 -m unittest discover -s R/RedBaron/tools -p 'test_*.py'
```

For a new live experiment, use the existing local harness from `tmp/dev` after
loading `amiga/env.sh`. Its ignored helpers and retained game installation are
local prerequisites; they are not a distributable game fixture. Use one capture
at a time, verify the running emulator belongs to this harness before quitting
it, and keep hands off mouse/keyboard during the route and capture.

```sh
source amiga/env.sh
python3 tools/w6_boot_current.py 030 0 tmp/prof/w6-manual-225 --dt 225
python3 tools/w6_players.py --end 89 --out tmp/prof/w6-manual-225/players
python3 tools/redbaron.py quit
```

Use a fresh output directory per case. CUSTOM4 zero observes native clocks;
100/225/450/900/2200 force only primary dt. `--slow` selects the existing VERIFY
draw delay. `--probe ground` or `--probe fire` selects the explicit synthetic
fixture, collected by local `w6_ground.py` or `w6_projectiles.py`. Read those
collectors' help before use. The current-build helper records its hash and
calibrates its own anchor; compare cases from the same binary. Its added probe
branches mean it is not the earlier frozen straight-flight binary. Neither
forced clocks nor synthetic initial states are valid FPS workloads.


Final validation: all **65 host tests pass**; the static audits report **13 sim
and three sound ranges, zero errors** (with their documented indirect-target
limits). All three build modes compile. Normal SHA256
`5256542f87ec1c6d3eca174416560597a60e76e1cc785cd0fbf5e3efff3f0ba8`
and developer SHA256
`01a00068d799b01c9b17a06bc7b2ce87acf88f22c23f870afd476d4e46a6adc3`
are byte-identical to W5. Only VERIFY contains the experimental clock/fixture
code. The owned emulator was shut down after the final capture.
