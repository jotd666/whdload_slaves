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

1. Identify and log player position, airspeed and heading at Time Scale 0, 40 and 60.
2. Inventory indirect clock reads and per-world-step/per-render-step counters.
3. Test forced dt 225/450/900/~2200, including the newly identified >400 paths, against
   smaller-step trajectory, ground-contact, bullet-hit, AI and collision references.
4. Compare equal-wall-time world state with and without a VERIFY rendering delay in the
   tracking regime, and equal-step state in the clamped regime.
5. Measure catch-up cost on the A500-equivalent machine and assess fractional accumulation.
6. Present the evidence, compatibility policy and recommended design for user approval.

Rendering optimizations may still accelerate the world on slow machines until that approved
work lands, as accepted in plan §6. Sound remains unchanged.
