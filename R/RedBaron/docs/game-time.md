# Red Baron game-time investigation

Status: W6 investigation in progress. No game-time change is implemented or approved.
A final design recommendation requires the trajectory, collision and coupling experiments
specified in `performance-plan.md`. The notes below distinguish inspected code from tests
that still need to be run.

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

Before a final recommendation:

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
until the timer coupling is resolved. The velocity interpretation and elapsed-time
reference are established below; neither study authorizes any timing change.

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
