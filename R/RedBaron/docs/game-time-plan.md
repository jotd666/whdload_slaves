# W6 consistent game speed: implementation contract

The approved completion plan is authoritative. Its phase D replaces the earlier
cross-CPU full-state and small-quantum convergence gates. W6 remains outside the
player mask until D5 passes. `profiling.md` is the single results scoreboard;
`game-time.md` contains the investigation. Historical evidence stays in git.

## Approved design

- The 68000 uses the original game's 450-unit quantum and presents the latest
  world state, without pose capture or interpolation.
- The 020 and later CPUs use 225 units, with render-only interpolation between
  completed world states. Interpolation never feeds back into physics, AI,
  collision, weapons or RNG.
- Debt is capped at one second of world time. Excess time is dropped and
  counted in VERIFY. Overload slows gameplay gracefully; it must not enlarge
  the physics quantum or be reported as nominal speed.
- Faster rendering will be on by default at release, with icons unchanged.
  The larger game memory pool is approved. These decisions need no further vote.

The reference rate is the original unclamped proportional clock: each active
CIA interval funds `1024/F` primary units, multiplied by eight during Time
Compress. The lifetime counter is `sim:30006`. At Time Scale 40, F=33, so 225
units represent about 123 ms and 450 about 245 ms. These are game-clock units,
not an inferred real-world speed conversion. Retain native integration,
signed fractions and the original >400 helper path on the 68000.

## Acceptance gate (completion plan D1)

1. **Speed:** completed world time is within ±1% of nominal at equal active
   wall time whenever the measured workload fits the CPU, under ordinary,
   deliberately slowed and one-field render schedules. Report completed time,
   retained debt, dropped time and FPS separately; include the bounded update
   in progress when interpreting an observation boundary. An overloaded run
   is outside the nominal-speed envelope, not a passing rate measurement.
2. **Independence:** funding comes only from elapsed CIA time and timestamped
   rate changes. Render duration, swap waits and render count never alter how
   much time is funded. The independent host model already proves partition
   independence; do not repeat full-state studies.
3. **Commands:** each one-shot command is consumed once. Held controls apply
   to every catch-up update with their acquisition-time ordering preserved.
   Throttle changes remain ±20 per command.
4. **Transitions:** pause, menus and Preferences rebase the clock without
   catch-up. Mission exit during catch-up exits immediately. Exercise Time
   Compress entry and exit using the same bounded clock.
5. **Isolation:** CUSTOM2 off retains original sim-v1 bytes and behavior;
   other executable versions remain on their original paths. Instrumentation
   belongs only in VERIFY builds.

Byte-identical full state across CPU classes or quanta is **not** a release
gate. The measured 1.72% difference between the 225- and 100-unit banked
trajectories, and the documented h3, message and sound residuals, are accepted.
Reopen them only for a visible play-test problem. Do not grow
`w6-verification.md` or start another byte-equivalence/full-state study.

## Clock and input ownership

Use the exact rational phase with precomputed rates for the selected quantum.
Retain fractional credit across render and Time Scale boundaries; do not round
per frame, create short final physics steps, or derive deadlines from the end
of the previous render. Account explicitly for the approved overload drop.

Keep the complete original world-update ordering around `sim:01098`, including
world counters, command dispatch and mission-return handling. Repeating that
routine alone is insufficient. A render iteration may execute zero or multiple
world updates without repeating one-shot commands.

| Work | Owner |
|---|---|
| Aircraft, AI, projectiles, collision and world countdowns | Selected fixed world quantum; native arithmetic/order |
| Held controls and discrete commands | Acquisition timestamps; frozen tick snapshot and single-consumption command queue |
| Camera and automatic mission-menu services | Existing independent secondary service clock |
| Messages | Approved three seconds of active-flight real time |
| Buffer dirtiness and overlay erase | Actual rendering/publication, not hidden catch-up updates |
| Sound sequencing, playback and envelopes | Existing CIA/native sound behavior |
| Menus, Preferences, pause, mission load/exit | Suspend/rebase accrual and stale input ownership |
| Time Compress | Eightfold world-time request; bounded debt and measured capacity limits |

Input acquired during CIA interval N becomes eligible at boundary N+1. Updates
at the same boundary share the held snapshot. Queue overflow must be explicit;
rendering must not be the only opportunity to acquire input.

## Implementation and validation order

Follow completion-plan D2–D5, reusing the existing scheduler/input/service and
presentation modules. Select quantum once in `time_loop_install`, add the
bounded debt policy and VERIFY drop telemetry, and omit pose work on the 68000.
The native >400 path needs one same-dt stock comparison covering straight and
banked flight. No cross-quantum convergence study is required.

Separate player code from VERIFY fixtures, logs and self-tests. Do not promote
the discarded C1 exponent optimization. Bit 13 still forces W5 bits 8 and 9;
under W6 the cap is one PAL field and the beam-safe swap remains enabled.
Check branch reach with `audit_patch_reach.py` and leave the player mask gated
until acceptance passes.

D5 is the only full matrix in this phase:

- A500 steady/squadron at Time Scale 0 and 40; 020, 030 and 060 at 40.
- Report A500 Time Scale 60 as an envelope measurement if it exceeds capacity.
- Tap/hold during a long render, one-shot throttle, Time Compress, pause,
  Preferences and mission exit during catch-up.
- Landing, crash and one AI shoot-down on A500 and 060, plus a 30-minute soak.
- The user flies the A500 and 060 configurations to judge handling feel.

Use the per-feature validation budget in completion-plan §0. Record D5's world
rate/debt/drop and FPS results in the scoreboard, then promote and commit.

## Smooth 50 FPS

Smooth 50 FPS on capable hardware remains an approved requirement. Repeated
world states alone do not meet it: 020+ presentation interpolates positions
and wrap-aware angles while preserving discontinuities. Under W6, publication
may occur every PAL field without changing the world tick rate. Phase E owns
the scene/cockpit work and final per-field publication deadline check needed
to reach that rate on the 060; report slower CPU cadence honestly.
