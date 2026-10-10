# W6 consistent game speed: proposed implementation

**Implementation authorized; in progress.** The user approved W6 and added
smooth 50 FPS on capable hardware as an acceptance requirement. `game-time.md` contains the investigation and measured limits.
The current player build keeps its original clocks and physics until the gates pass.

## Additional accepted requirement: independent simulation and 50 FPS

Achieved render FPS must not determine gameplay speed. W6 retains fixed world
ticks and adds render interpolation between consecutive world states. On capable
PAL hardware its publication cap becomes one field (50 FPS), preserving the safe
swap. On slower hardware drawing yields to due simulation work. Repeated states
alone do not satisfy the smooth-50-FPS requirement. Interpolation must never feed
positions, angles or intermediate objects back into physics, collision, AI or RNG.

The presentation implementation must audit every state mutation in the native
render/camera path, interpolate positions and wrap-aware angles for active objects
and camera consistently, and preserve discontinuities such as spawn/despawn, view
changes and teleport/mission transitions. It must retain the original world state
byte-for-byte after drawing. Measure visual cadence and input latency separately
from simulation tick rate. All earlier acceptance gates still apply.

## Primary acceptance invariant: gameplay speed

The user's explicit requirement is consistent gameplay (simulation speed)
regardless of achieved rendering frame rate. Smooth 50 FPS is an additional
presentation requirement; achieving it does not establish timing correctness.

With identical initial world state, Time Scale/compression transitions and
acquisition-timestamped controls, changing only the render schedule must preserve:

- The complete simulation state and ordered gameplay events at equal world tick
  IDs, including aircraft, AI, weapons, projectiles, collisions and RNG state.
- The number of due world ticks at equal active-flight elapsed time, including
  both fractional credit and outstanding debt. Render duration and publication
  waits must never change how much simulation time is funded.
- Sustained execution of the funded tick rate within the measured CPU capacity
  envelope. Correct accounting with growing debt is insufficient to claim that
  gameplay is running at the correct real-time speed.

Use deliberately delayed, ordinary, uncapped/no-render and one-field render
schedules for the state comparison. For wall-time measurements, report completed
world ticks, outstanding debt and rendered FPS separately, and account for the
bounded update in progress at the observation boundary. Include fast hardware
with render-only iterations between world updates and slow hardware with several
world updates between renders. Never infer simulation speed from swap count.

## Recommendation

Use a **fixed primary simulation step of 225**, funded by the existing CIA
lifetime clock, and run as many due world updates as necessary before drawing.
Keep all original force/integration arithmetic, including signed fractions;
do not raise the 450 clamp or rewrite the >400 helpers. With the switch off,
all original sim-v1 bytes and behavior must remain intact.

The intended speed is the original **unclamped proportional clock**, not the
slow machine's current clamped behavior and not an assumed real-world mph
conversion. A CIA tick earns 1024/F primary units. At Time Scale 40, F=33;
225 units correspond to approximately 123 ms, or 8.15 world updates/second.
This quantum differs by 0.40% in travelled distance from the 100-unit short
straight-flight reference, whereas 450 differs by 13.22%. It avoids the
original discontinuity above 400. It is an initial implementation choice
supported by that scoped evidence, not a claim of convergence for all combat.

A smaller 100-unit quantum requires roughly 18.34 world updates/second at
Time Scale 40. The retained A500 world cost alone exceeds that time budget.
225 leaves room for drawing at the normal setting. Rendering faster than the
world tick rate must interpolate for the accepted 50 FPS target. Interpolation
adds up to one simulation interval of presentation latency: approximately 297 ms
at Time Scale 0 (3.36 world ticks/second) and 123 ms at Time Scale 40. Input acquisition and camera service remain more frequent, but cannot
make the physics react before its next tick. Evaluate that responsiveness before
release; if unacceptable, revise the quantum/visual interpolation design with
fresh cost and trajectory evidence rather than hiding the tradeoff.

## Exact clock contract

For a constant divisor F, keep an integer remainder:

```
credit += elapsed_CIA_ticks * 1024
while credit >= F * 225:
    consume one timestamped input interval
    run one complete world update with primary_dt = 225
    credit -= F * 225
```

Use the lifetime counter at `sim:30006`, with unsigned wrap handling, rather
than the saturating countdown at `sim:3015c`. Do not derive new deadlines from
the time the previous render completed. Do not discard a fractional remainder,
round independently per frame, use the previous frame's duration as this tick's
duration, or create a tiny final substep merely to consume the remainder.
The host model proves partition independence of this accounting; it does not
prove an eventual 68000 implementation's overflow/atomicity handling.

The native kernel now uses a common denominator LCM(10..80) and a four-long
world phase. Advance one unprocessed CIA tick at a time and execute its due world
updates before advancing again. Each F has an exact precomputed increment; no
phase rounding occurs when F changes. Unprocessed CIA ticks remain debt, so a
large elapsed interval is not multiplied into a bounded phase accumulator.
The largest single-tick intermediate, including 8× compression, fits 128 bits. A tick runs when its
rational deadline has been reached, with at most one CIA-tick observation
latency. Game tick IDs and input assignment must use that same convention.
A change of Time Scale closes the old interval using its old F and begins the
new interval using the new F; convert residual credit as rational world time,
rather than reinterpreting the old F-scaled numerator under the new F.

The main loop at `sim:21d0a` needs restructuring. Repeating `sim:01098` alone
is insufficient: world counters, command dispatch, weapon/unjam/death timing and
mission-return flags also live around it. Process mission exit immediately
when any substep requests it. A render iteration may run zero, one or several
world updates; it must never repeat one-shot commands to fill those updates.
The legacy Time Compress clock overwrite at `sim:00eca` must be bypassed only
inside the new timing mode.

## Clock and input ownership

| Work | Proposed clock/policy |
| --- | --- |
| Aircraft, AI, projectiles, collision/ground queries, world countdowns | One original update per 225-unit world tick; preserve original ordering and per-tick rounding |
| Weapons and unjamming | Preserve native weapon readiness accumulators (increment capped at 85; player resets to 171 after firing), ammunition and jam rules on world ticks. The separate 1000-unit unjam-retry countdown keeps its original expiry quantization. Do not invent a firing cooldown or compensate timer overshoot |
| Held stick/rudder/fire | Timestamp changes at input acquisition and apply them to their simulation tick, including every catch-up tick. Never retroactively apply a newly pressed key to old debt |
| Throttle and other discrete commands | Consume each native key event once; preserve ±20 per command and existing preset values. Key repeat must use clock deadlines, not render count |
| Secondary F=20 clock | Separate real-time service accumulator. Use 128-unit service ticks (about 23.65 Hz PAL), below the >400 shortcut; preserve its own remainder. Extract timed camera/repeat work rather than calling the whole command dispatcher repeatedly |
| Message lifetime | Propose three seconds of active-flight real time, independent of Time Scale and FPS. This replaces the ambiguous 30-render-frame lifetime and is an explicitly approved behavior choice |
| Two-buffer dirtiness, overlay erase and view redraw counters | Remain render/publication counters. A timeout marks both buffers dirty; it must not consume both redraws while running hidden world ticks |
| Native history and world-cycle selectors | Advance on world ticks. They must not count repeated rendered frames |
| Sound | Keep CIA sequencing, sample playback, buffers and envelopes unchanged. Service existing sound control even when rendering is skipped; audit event delivery without adding synthetic elapsed time or reopening W3 behavior changes |
| Menus, Preferences, pause, mission load/exit | Suspend simulation accrual and rebase its lifetime timestamp on resume. No catch-up for time spent in menus; reset per-mission credit and queued stale input |
| Time Compress | Propose an explicit 8× virtual-time request using the same bounded ticks, with rendering skipped as necessary. It is a requested rate, not a promise when CPU capacity is insufficient; this replaces the old CPU-dependent fast-forward behavior under the approved design |

W5's safe publication stays in the render phase. Under W6 its cap becomes one
PAL field; outside W6 it retains the existing two-field policy. Waiting for
publication contributes real elapsed time to the next scheduler observation;
it does not become an extra simulation tick by itself. Sound and the secondary
service clock are real-time domains, not multiplied by Time Scale/Time Compress.
Input acquired during CIA interval N is eligible at boundary N+1. Freeze that
boundary's input before executing any of its world updates; a late IRQ must not
change a second compressed update at the same boundary. This adds at most one
CIA interval of acquisition latency and makes the ordering independent of CPU
speed. The bounded queue faults explicitly on overflow rather than evicting old
events. An input queue must have VERIFY telemetry;
silently dropping old events or polling only after a long render is unacceptable.

## Capacity limit and overload policy

No algorithm can run a 59 ms world update 27 times per wall-clock second.
Using the retained W5-only A500 costs, 225-unit world ticks occupy approximately
20% of the CPU budget at Time Scale 0, 48% at 40, and **159% at 60 before any
rendering**. These are budget projections, not measured performance of a new
scheduler or the full W1–W5 bundle. The highest setting therefore needs world
optimization, a separately justified coarser quantum, or a faster machine.

Recommended initial behavior: retain time debt, skip rendering while behind,
and service input/audio between bounded batches of world ticks. Never enlarge
a physics step or silently throw away elapsed time. Record debt/high-water marks
in VERIFY. If world work alone exceeds available CPU, the game necessarily
lags behind real time; do not claim universal nominal speed in that condition.
A release must state the measured supported CPU/Time Scale envelope. Persistent
overload at the default Time Scale is a release blocker, not a reason to hide
lost time. W7 world-loop work becomes a prerequisite if this gate fails.

At default Time Scale, the retained W5-only A500 costs project about **0.98 FPS**
when all non-world frame costs are retained, compared with 1.7061 FPS in that
particular old census. More useful world progress costs additional hidden
updates; a lower rendered FPS is possible. Measure the actual combined build
before presenting any user-facing performance claim. Do not optimize away
original collision/AI updates just to improve the frame-rate number.

## Implementation sequence after approval

1. **Contracts and observers.** Allocate a new CUSTOM bit for game timing; do
   not reuse W5 bit 9. Reserve it in the developer mask but leave it out of the
   player verified mask until all gates pass. Add VERIFY tick/debt/input logs,
   state extraction for every active aircraft/projectile, and explicit pause,
   menu, Time Scale and compression transitions. Byte-check every sim-v1 hook;
   retain the thirteen existing performance ranges unchanged when timing is off.
2. **Scheduler core and world-loop split.** Implement exact credit/deadlines,
   tick-indexed input and complete world updates without drawing. Preserve
   current native arithmetic; model and live-check accumulator wrap, overflow,
   zero-due frames, catch-up batches and mission exit during catch-up.
3. **Remaining timed services.** Separate the secondary-clock camera/repeat
   service and message/death timers from rendering. Keep dirty counters tied to
   actual buffer publications. Exercise Preferences/pause/restart and compression
   transitions before measuring speed.
4. **Correctness across render schedules.** On identical initial heap state and
   timestamped input, compare full world state at equal tick IDs across normal,
   deliberately slow, no-render and different CPU runs. Compare tick IDs/debt
   at equal wall time as a separate check. Pixel comparison is inappropriate
   between different world times; use existing render twins at the same state.
5. **Gameplay and cost acceptance.** Run the matrix below, then measure the
   full bundle on A500, 68020 and cached 68030 with the established same-build
   swap census. Update `profiling.md`. Promote the new bit only after passing;
   make one coherent commit per completed feature.

## Acceptance matrix and decision gates

- **Arithmetic:** exact scheduler model/twin, both clock remainders, counter
  wrap and large elapsed intervals; original signed-fraction model still passes.
- **Physics:** straight flight plus banking, stall/recovery, climb/descent,
  controlled landing and crash at Time Scale 0/40/60. Compare 225 to a smaller
  reference at equal world time; classify rounding separately from a changed
  contact/hit outcome. The current straight-flight 0.4% result is not a blanket
  tolerance for all states.
- **Combat/AI:** deterministic hit and near-miss geometry, crossing moving
  targets, projectile lifetime/range, aircraft collision, firing cadence, unjam retry, AI target
  choice and RNG advancement. A probe with zero hits cannot certify collision
  correctness. Preserve native swept/segment queries; do not assume point-only
  collision detection.
- **Presentation/input:** tap and hold controls during a long render; multiple
  queued commands; message replacement/expiry; both buffers clean after expiry;
  camera movement; pause/Preferences/mission transitions; Time Compress entry,
  exit and overload. One-shot commands must not repeat during catch-up.
- **Capacity:** default Time Scale must sustain nominal world speed on the
  claimed minimum machine in steady/event/bank/dense windows. Report tick-rate,
  debt, render FPS, input latency and complete world-update cost separately.
- **Release isolation:** normal/developer builds contain no experiment; timing
  off retains original bytes; sim v2/v3 retain existing behavior; W5 still caps
  only rendering; existing release defaults/icons remain a separate decision.

The user has authorized implementing this staged design, including the proposed
225-unit quantum, separate secondary service, three-second messages and defined
Time Compress request, and additionally requires smooth 50 FPS on capable hardware.
This does not waive the acceptance gates or authorize
publishing a release. A failed gate should change the recommendation openly,
not be normalized away in state comparisons.
