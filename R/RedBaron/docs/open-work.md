# Red Baron open work

The authoritative remaining work is `completion-plan.md`, phases A–F in order.
Its approved decisions supersede the older next-work list below. A1 machine
configurations are implemented in `tools/completion_machines.py`: A500, 020,
030/50 with and without MMU, 040/25 and 060/50. The latter two use NOMMU
cores for timing and separate MMU configurations for functional checks.
A2 is complete on all six configurations, with stock and bundle results in the
single scoreboard at the top of `profiling.md`. It records event-free frame
cadence separately from whole-window event FPS and includes stage costs and
redraw markers. All captures use the same normal binary. The reusable
`completion_host_input.py` / `completion_lldb_input.py` tools deliver native
keyboard input through the host debugger; macOS accessibility is not used.
B1 is complete: the game pool grows to 704 KB behind bit 16 on supported
CPUs and sim v1, eliminating live chip spill. The minimum A500 flies; isolated
020–060 comparisons improve by 4.6–12.9%. All three builds, 431 host tests
and the 76-range hook audit pass. B2 is implemented and measured: instruction
caching adds 7.8% on 020 and 12.8% on 030 without MMU; disabled data caches
remain disabled. Checkpoint B is complete on all six configurations; the single scoreboard
contains the current normal-bundle rates and stage costs. C1 is dropped: its five measured CPU-class differences are all below 2%.
C2 is also dropped: its lifecycle twin passed, but all five CPU-class differences are below 2%.
C3 is implemented and enabled only on the 68000: its exact face-loop twin passes and the isolated pair gains 3.39%.
Checkpoint C is complete on all six normal-build configurations; current rates and stage costs are in the scoreboard.
D1 is complete: `game-time-plan.md` now uses the approved rate, command, transition and isolation gates; cross-CPU/full-state convergence is no longer a gate.
D2 is implemented in VERIFY and passes the two-quantum clock tests and dt=450 straight/banked helper twin. The scoreboard records scope; rate/capacity acceptance remains D5.
D3 is implemented in VERIFY: the 68000 bypass check passes with drawing retained.
D4 is complete: timing/input/render runtime compiles in all modes, while fixtures,
self-tests and logs remain VERIFY-only. Developer bit 13 selects it on 68000 and
020+ and forces tear-free publication plus a one-field cap. Modal return retains
the CPU-selected quantum. The discarded exponent helper remains VERIFY-only.
All three builds, 439 host tests, 79 hook ranges and both patch-reach audits pass.
D5 acceptance is postponed by the user (2026-10-11); phase E is next. The scoreboard records all six candidate rate
windows: 020–060 pass at Time Scale 40; A500 passes at 0 but drops time at 40.
A500 and 060 throttle taps and native pause/rebase pass. The user completed
short tap/hold/release tests on both: 060 handling was good; A500 input was
predictable but maximum-detail playability was poor (scoreboard). Remaining
catch-up input/transition checks and flight-outcome smoke tests remain open. The 060
30-minute emulated soak passes in one flight across two debugger reads;
the normal verified mask still excludes bit 13 until acceptance passes.
E1 is complete as a 040/060 stage-cost diagnostic; both rendering stages exceed
one field. E2's small gun-overlay cache is dropped: every CPU-class pair misses 2%.
The solid-script cache is also dropped after every CPU-class pair missed 2%.
Both runtime candidates are removed; reusable helpers remain VERIFY-only.
The next candidate is a persistent native gauge cache behind development bit 18,
on 020+ only. It reuses a gauge's existing buffer pixels only when its raw
inputs/context, native rectangle and bounded pixel guard match, with selective
replay of that gauge's drawing-state writes. Native forced/dirty redraws and
unsupported geometry use the original path. The seven-gauge native pixel/state twin passes;
the CPU-class timing batch is running. The 040 pair clears 2%; the 060 pair
does not. The normal verified mask excludes bit 18 until CPU selection is final.
The combined-copy coverage primitive is implemented as standalone assembly with
an independent truth-table model (489 host tests pass), including opaque black
and rejection of inversion or plane-dependent masks. It is not yet included in
the slave; native capture/context restoration and combined composition remain open.
CPU selection and view/map twins also remain open. Results are in the scoreboard. D5 remains postponed and E2–F remain
open; the earlier lists below are historical context, not the execution order.


The accepted decisions and detailed requirements are in `performance-plan.md`,
especially §6. `verification.md` is the W0 evidence ledger; `profiling.md`
contains measured baselines. W5 completes the opt-in Faster rendering player
bundle. Existing default-off behavior and icon tooltypes are unchanged.

## W0 complete; W1 core implemented, further work deferred

On the user's instruction, W1 work stops here to prioritize the main geometry
cost. The exact table mirror and chip mirror cache are implemented and committed.
The models, exhaustive CPU word test, synthetic/live mirror twins, pixel twins,
allocation-failure and lifecycle probes pass. The fallback-invalidation regression
is fixed. All three build modes compile and 35 host checks pass.

The nine primary machine/option cases, six corrected-build scene twin boots,
A500/68020 warm-event traces and their bank/dense matrices are complete. Corrected
68030 bank captures are complete; the dense matrix was stopped during its first
case. Completed evidence is retained; incomplete captures are not results.
`profiling.md` records measured costs and rates with their scope and build hashes.

For development, CUSTOM2=3 selects W1a+W1b; CUSTOM2=2 selects only the cache.
The cached 68030 table mirror is slower than the original, so the normal selection
policy excludes it on 030/040/060. W5 supplies normal player selection and its
option checks; developer/VERIFY builds retain individual options.

### Deferred W1 follow-up

- Finish the cached 68030 dense-scene measurements and saved display/hook audit.
- Run the prepared independent cached-68030 cache-only timing/full-flight twin
  check. Earlier cache-only checks passed on the continuity configuration; do not
  label the unrun cached-CPU extension as passed.
- Finish the return-flag contract write-up for the cached draw's caller chain.
- Further clipping/lifecycle or timing refinements only if a concrete issue calls
  for them; the large existing evidence set is retained.

## W2 complete with low-value refinements deferred

G1 projection core, G2 trivial clipping, G3 32-bit vertex misses and G4 dot are
implemented, modeled and verified. Combined twins and the final steady/event/
bank/dense cost matrix are complete on A500, 68020 and cached 68030. The steady
bundle gains 5.97% FPS on A500 and 5.54% on 68020. Cached gains are small; retain
original G1 there because it regresses. Use developer/VERIFY CUSTOM2=60 on
A500/68020 and 56 on cached 68030. W5 includes this CPU policy in the player bundle.

Remaining G1/G3 refinements and G5–G9 are explicitly deferred under the plan's
3%-of-frame gate. `w2-verification.md` records their cost assessment, all current
measurements and the completion audit. They are not claimed implemented.
Drawing is the larger measured bottleneck on the cached machine.

## W3 complete with low-value candidates deferred

S1 queue, S3 bounded volume division and S9 no-op call removal are implemented.
Models, three-CPU twins, hook audits, sound logs and same-build measurements pass.
Observed FPS gains are 1.93% on A500 and 0.46% on 68020; cached 68030 has no
established FPS gain. Use developer/VERIFY CUSTOM2=7168 on A500/68020 and 3072
on cached 68030, where original S3 is retained. These are W3-only selections.

S2/S3′/S4–S8 are explicitly deferred under the plan’s size threshold, not claimed
implemented. B1–B6 remain separate behavior/OS decisions. `w3-verification.md`
records the scope, proof and evidence. W5 includes these selections in the player bundle.

## W4 complete; overlay queueing deferred

D1 aligned D-only fills are implemented behind developer/VERIFY CUSTOM2=128.
Models, three-CPU pixel twins and byte/display audits pass. Measured W4-only
FPS gains are 0.66% on A500, 3.47% on 68020 and 7.47% on cached 68030.
Retain D1 on all three measured CPUs. `w4-verification.md` records completion
and measurement limits. W5 includes D1 in the player bundle. Overlay queueing
is explicitly later-only; doubled waits and BLTPRI remain unchanged.

## W5 complete

P1 uses the original safe beam wait and P2 enforces a two-field flight cap
(approximately 25 FPS PAL). P1 alone costs 0.55% FPS on A500; combined W5 costs
0.72%, 2.44% and 2.45% on A500, 68020 and cached 68030 respectively.
Models, independent wrap/cap stress, selected/disabled byte audits, display
samples and three-CPU combined flight checks pass. All seven normal player
option checks pass. `w5-verification.md` records the evidence and its limits.

Normal CUSTOM2=1 selects 8127 on A500/68020 and 4026 on 68030/040/060;
CUSTOM2=0 or absent disables all performance patches. Default and icons stay
as they were while the release preferences below remain open.

## Next work

`completion-plan.md` is the authoritative step-by-step plan for finishing
this work; it supersedes the items below where they differ.

1. **W6 implementation in progress:** analysis is complete in `game-time.md`;
   the approved plan is `game-time-plan.md`, now including smooth 50 FPS on
   capable hardware and gameplay speed independent of achieved FPS. It uses 225-unit
   world ticks with independent rendering, timestamped input and retained time
   debt. Controlled combat/AI convergence and actual catch-up capacity are gates
   of implementation, not completed tests. VERIFY now has a fixed-step loop,
   atomic modal-clock handoff, timestamped keyboard/mouse/joystick ownership,
   timed services and render interpolation. These implementations remain
   experimental: complete state/consumer coverage, physics/combat convergence,
   sustained scene capacity, physical-input latency and actual smooth 50 FPS
   are not accepted. A current 20-second cached-68030 event/replay run averages
   10.2 FPS with exact funding and outstanding work below 1.824 updates;
   this is finite scenario capacity evidence, not the minimum-machine or
   all-scene gate. The A500 four-versus-four run **fails capacity**: 99 updates
   complete against 163.288 funded in 20 seconds, with no rendering and
   monotonically rising window-end debt. Supporting this machine/scene needs
   world-loop optimization before W6 can pass; a conserved ledger is insufficient.
   A 68EC020 + 8 MiB fast-RAM squadron run recovers after its opening event
   burst and averages 2.35 FPS while completing 162 of 163.288 newly funded
   updates over 20 seconds. Its 440 ms maximum completion gap and remaining
   matrix prevent declaring a release minimum from this sample alone.
   An accelerated-emulation probe also sustains its finite world-update load
   but publishes at 12.15 FPS, still failing every-field cadence. No actual
   smooth-50-FPS configuration has passed. Publication cadence now has an
   explicit per-field checker; changing pixels/interpolation remain separate.
   Two warmed 250-field stage captures put native drawing near 3.87 fields,
   with both scene and cockpit spans individually above one field. Publication
   averages only 0.21–0.36 fields; weakening the cap cannot supply 50 FPS here.
   Scene/cockpit work or a demonstrated capable configuration is still needed.
   See `w6-verification.md`. Player timing remains unchanged.
2. **W7:** later world-step and instrument improvements. W4 overlay queueing
   remains explicitly deferred.

## Decisions still required before release

- Default state of the single Faster rendering splash switch.
- Whether supplied icons explicitly enable that switch.
- W6 must pass its implementation gates, including simulation independence and
  smooth 50 FPS on capable hardware; see `w6-verification.md`.

Chip RAM for W1b is approved. W3’s selected exact-output changes are complete; B1–B6 remain separate decisions.
Until an approved W6 implementation lands, faster frames accelerating the world on
slow machines is an accepted intermediate behavior. Keep Time Scale unchanged in
ordinary development fixtures; 0/60 copies are investigation inputs only.

## Per-feature and release gates

Use one binary with option changes for comparisons; all patches remain sim v1 only.
Each feature needs original-byte checks, whole-instruction/branch/relocation audits,
CUSTOM-off verification, its model/twin checks and the plan's measurement protocol.
The thirteen sim and three sound performance ranges pass the static hook audit.
Only verified bits may enter the release mask. Keep instruments VERIFY-only and
normal/developer builds free of their code and data. Recheck frame timing, ownership,
chip/slow memory pressure and cache conditions after code/layout changes.

Release packaging, installer/icon edits and publishing are separate from W0. Preserve
JOTD's history, document WHDLoad requirements and measured behavior, and keep each
coherent feature in a separate personal, unsigned commit without hooks or attribution.
