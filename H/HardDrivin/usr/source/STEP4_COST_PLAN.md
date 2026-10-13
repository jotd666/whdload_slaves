# Step 4 cost profile and closure plan

This plan finishes step 4 of `PERFORMANCE_PLAN.md`. It starts from a fresh profile of the
current integrated build, measured on 2026-10-12. It names the bottlenecks, sets numeric
targets and gives an ordered list of work items. Each item has an exit criterion. Step IDs
are `P` (performance), `C` (closure) and `D` (decisions for the user).

**Current status: P1, P2, P4, P5, P6 and P7 complete; P3 deferred.** P4 retains its
explicit helper-budget exception. P5's acceptance build met its unchanged
0.300 ms/frame target at 0.247 / 0.292 ms/frame. P6 optimizes the remaining
physics arithmetic bottleneck: matched-operand long division is about 29% cheaper.
The user accepted the P6 A500 B-window overhead of **5.740 ms/frame for now**
(2026-10-13), superseding its 3.78 ms blocking limit for that measured build.
P6 A measured 3.084 ms/frame. The current closure build, including collision
sweeps, last measured **8.405 / 6.866 ms/frame** after removing redundant neutral
steering work within a frame. A and B exceed their respective 8.070 / 5.740 ms
limits by **0.335 / 1.126 ms**. The earlier exception is not extended.
C1 is complete, C2–C5 remain open and C6 is deferred. Historical P7 A1200 net
phase overhead is 0.283 / 0.576 ms/frame (0.47% / 1.23%); it is not a measurement
of this latest full closure build.

## 1. Measurement

**Build.** The build is `build_reference.sh` plus `VERIFY_DRIVETRAIN_PHASE`. That is all
step-4 gates, the drivetrain reference, and the incremental phase solver, as of `d94d739`.

| Slave | Input fixture |
|---|---|
| `cprof-phase.slave` | `VERIFY_STEPINPUT`, constant accelerator |
| `cprof-tape.slave` | Frozen `VERIFY_DRIVE` tape |

Each slave runs with CUSTOM1=0 and with CUSTOM1=1. The CPU is an A500 68000, profiled with
the direct profiler emulator.

**Windows.** Each window is 500 PAL fields (10.016 s):

| Window | Starts at | Input |
|---|---|---|
| A | Race field 1 | Constant accelerator |
| B | Race field 4000 | The tape, after the full preceding tape |

**Runs.** The captures are `cprof-off`, `cprof-on`, `cprof-b-off` and `cprof-b-on`.

**Analyzer.** `tmp/dev/tools/frame_budget.py RUN...` produces the numbers below.
- It averages only complete swap intervals.
- Every main-context instruction goes to the gameplay-loop call site executed last
  (`$10ec8..$10f5e`). Slave hooks patched into the loop therefore count against the phase
  they replace.
- The slave/listing symbols split cycles further by owner.
- Interrupt context is separate.
- Native routine entries are counted by PC. This catches the engine, which the phase
  solver enters with push/`rts`.

The summary is `tmp/prof/cprof-overhead.json`, and each run has its own `frame-budget.json`.

`$10f28` is the dispatcher hook. With CUSTOM1 on, that bucket holds the wait and the
background drawing together.

### Per-frame results (ms per complete frame)

| | A off | A on | B off | B on |
|---|---:|---:|---:|---:|
| Mean frame time | 260.96 | 263.20 | 122.19 | 180.65 |
| Polygons filled per frame | 57.8 | 55.6 | 14.0 | 28.8 |
| Native engine entries per frame | 1.00 | 2.53 | 1.00 | 2.36 |
| Traffic `$0d40e` | 6.10 | 12.46 | 6.34 | 11.83 |
| Physics `$0cda4` | 9.70 | 15.67 | 6.50 | 12.61 |
| Camera + replay record `$0d960` | 0.92 | 4.81 | 0.94 | 3.84 |
| Controls + loop hooks | 0.17 | 0.56 | 0.15 | 0.60 |
| Scene transform `$0b0d6` | 82.10 | 78.28 | 28.01 | 46.30 |
| Scene draw `$10008` | 106.01 | 94.42 | 27.92 | 46.55 |

The CUSTOM1 overhead is the difference in the simulation phases (controls, `$108a2`,
camera/record, traffic, physics and the loop hooks). Timing slave code that runs elsewhere
is added on top. Rendering code is unchanged by CUSTOM1 and is excluded.

| Window | Overhead per frame | Share of original frame | Equal-scene FPS loss | 3% budget |
|---|---:|---:|---:|---:|
| A | 16.64 ms | 6.38% | 5.99% | 8.07 ms |
| B | 14.98 ms | 12.26% | 10.92% | **3.78 ms** |

The budget is the overhead allowed for at most 3% FPS loss: x ≤ frame × (1/0.97 − 1), or
3.093% of the original frame.

### Where the overhead goes (A / B, ms per frame)

| Component | A | B | Main symbols (A ms/frame) |
|---|---:|---:|---|
| Traffic hooks | 6.36 | 5.49 | `_traffic_slot` 1.62, `_traffic_phase_delta_wide` 1.10, `_traffic_phase_step` 0.97, `_traffic_speed_step` 0.92, wrappers 0.80, `_traffic_route_walk` 0.36, `_traffic_turn_min` 0.11 |
| Physics | 5.96 | 6.11 | Extra native engine runs plus the game's math hunk ≈2.0. Slave ≈3.9: `_phase_*` 1.74, `_time_*` 0.81, `_projection_*` 0.40, `_motion_*` 0.37, `_drivetrain_*` 0.29, `_contact_*` 0.28 |
| Replay record | 3.89 | 2.90 | `_record_lerp_unsigned` 1.62, `_record_angle_word` 0.78, `_record_interpolate` 0.33, `_record_unsigned_word` 0.30, `_record_lerp_signed` 0.22, `_record_copy` 0.19 |
| Controls, dispatcher, hooks | 0.42 | 0.48 | `hook10ed4` 0.15, controls 0.17 |

## 2. Findings

1. **The literal FPS comparison mostly measures scene workload, not timing cost.**
   - In window B the enabled run is 31% slower overall. Of that, 10.9% is overhead. The
     rest comes from a different trajectory: the enabled car fills 28.8 polygons per
     frame against the original's 14.0.
   - In window A the enabled run is only 0.86% slower, even with 16.6 ms of overhead,
     because its scene happens to be lighter.
   - A swap-count gate on diverging trajectories cannot pass or fail on cost alone. This
     is why the gate has looked impossible to close.
2. **The overhead is almost constant per frame, about 15–17 ms on the A500.** The
   tightest budget measured is 3.78 ms, in window B's fast original frames. The overhead
   must shrink by a factor of 4.4 or more. No single item is enough; traffic, physics and
   the recorder all have to shrink.
3. **Traffic always takes the wide path on the 68000.**
   - A500 frames are longer than 8 fields, so every car runs the "long step" arithmetic
     every frame:
     - `_traffic_turn_min`
     - `_traffic_phase_delta_wide`, with two `divu #768`
     - `divs #6`
     - the route walk
     - in `_traffic_speed_step`, the terminal-speed `divu`/`mulu` and a `divs #8`
   - `_traffic_slot` runs a `mulu #46` and a `divu #46` on every hook call, roughly three
     times per car.
   - Each wrapper saves 8 registers with `movem`.
   - Native traffic itself costs about 6.2 ms per frame. The hooks double it.
4. **The engine runs 2.36–2.53 times per frame instead of once.**
   - The incremental phase solver runs the native engine for every frame segment.
     Phases started per frame are about 1.65 in A (13.2 fields per frame) and about 1.13
     in B (9.0 fields per frame).
   - The rest is the ongoing phase being re-evaluated at the start of each frame.
   - Each extra run costs about 1.35 ms in game code plus about 0.45 ms in the game's
     math hunk.
5. **The slave physics helpers cost about 3.6–3.9 ms per frame, spread over roughly 40
   routines.** The cost comes from:
   - general 32-bit arithmetic helpers (`_time_multiply_fields`, `_time_product_s32_u16`,
     `_time_scale_word`, `_time_split_q16`);
   - computing per-frame values again in every hook;
   - full `movem.l d0-d7/a0-a6` saves in the hooks;
   - the phase forecast projection running once per segment.
6. **The recorder interpolates all 79 words of the 158-byte record at every crossed
   8-field boundary.** That is 1.6 records per frame on the A500. The equal-word shortcut
   already removed about 38%; the rest is the multiply/divide path for every word that
   changes.

## 3. Gate definition (decision D1)

The proposed measurable form of the step-4 rule ("the A500's FPS must not drop by more than
3%") has two parts. G1 decides pass or fail; G2 is reported only.

- **G1, the cost gate.**
  - Run one slave with CUSTOM1=0 and CUSTOM1=1 in windows A and B.
  - Measure the CUSTOM1 overhead with `frame_budget.py`, as defined in section 1.
  - The overhead must be at most 3.093% of the original mean frame time in each window:
    at most 8.07 ms in A and at most 3.78 ms in B.
  - **Temporary user exception, 2026-10-13:** accept the current B result of
    5.739547 ms/frame (rounded 5.740) from the P6 build `368853a`. This removes
    G1 as a blocker to step 5; retain the original target as a reference and
    continue reporting costs. It does not authorize further unmeasured regressions.
    Rendering gains must be measured together with the simulation changes before
    claiming a net win against the original.
  - Any new hook outside the listed simulation phases must appear as timing slave code. If
    it doesn't, the analyzer must be extended before G1 can pass.
- **G2, the end-to-end report.** Keep reporting literal swap counts and FPS for both
  windows, together with polygons per frame. When polygons per frame differ by more than
  5%, label the comparison "scene mismatch". It is not pass/fail evidence either way.

The user accepted this definition (D1). The literal criterion stays recorded in
`PERFORMANCE_PLAN.md`, and G1 is how it is measured.

## 4. Performance work, in order

Rules for every P item:
- Use CUSTOM1-gated code only. Normal, DRIVE and ATTRACT builds must stay byte-identical.
- Every rewrite must match the current behaviour bit-exactly. Prove it with an exhaustive
  or large private 68000 fixture, as the existing `check_*_math` tools do, plus the live
  checker for that module.
- After each item:
  - run the 108-state native check;
  - run `check_disabled.py` and `check_patch_branches.py`;
  - capture fresh A/B profiles (`capture_solver_profile.py`, then `frame_budget.py`);
  - commit, then record the new per-frame numbers in this file.

### P1 Traffic hooks: complete (target ≤ 0.8 ms per frame)

Fresh 500-field captures use `p1-final-a.slave` (constant accelerator) and
`p1-final-b.slave` (the frozen tape), each with CUSTOM1 off and on. The captures are
`p1-final-{a,b}-{off,on}`, with distinct `HD_INSTANCE` values and matching rebuilt
listings. B starts at race field 4000 after the full preceding tape. Each window is
10.015943522 seconds. `frame_budget.py` still averages only complete swap intervals.

| Traffic phase, ms/frame | A | B |
|---|---:|---:|
| Original, CUSTOM1 off | 6.097194 | 6.332588 |
| Optimized, CUSTOM1 on | 6.352858 | 6.366127 |
| **Overhead** | **0.255663** | **0.033539** |
| Limit | 0.8 | 0.8 |
| Result | **PASS** | **PASS** |

The implementation keeps the existing traffic integration and route semantics:

- Companions use the native 46-byte stride. An immutable byte map rejects unaligned
  records; an extent comparison rejects out-of-table addresses. Allocation is
  92 bytes per record including the map (1,104 bytes for the 12-car SPS table).
  The native world loop already proves its records are in range and aligned, so its
  calls use a cached address bias. Other callers retain the checked lookup. The
  companion pointer is retained in a four-byte extension of the native local frame.
- Terminal speed and its source bytes are cached. A cached direction/acceleration/
  target/terminal signature detects changes before taking the steady-speed path.
- For integral nonnegative terminal speed, nonnegative carry and 9–255 fields, the
  `/768` calculation reduces exactly to a multiply and `/128` shift. With carry
  `6*p+m`, the quotient is `(16*n*v+p)>>7`, the new `p` is the low seven bits, and
  `m` is unchanged. `16*n` and the eligible field range are computed once per world
  update. Acceleration, reversal, fractional speed and other field ranges retain
  the general arithmetic. Route walking remains at the original publication site;
  geometry still consumes the old phase.
- Hook wrappers use the native routine's scratch-register contract. Branches skip
  replaced instruction padding. These changes alone did not reach the target, so
  the seven existing traffic pose interpolations also lose their repeated stack
  arguments and math-helper trampolines. The MULS/DIVS operations, word overflow
  behavior and rounding remain identical. This shortcut is restricted to the
  world-loop caller; route generation and reset calls retain native interpolation.

Required correctness evidence passes:

- `check_traffic.py`: 1,440 native-step updates, 92 route crossings; another 1,440
  one-field updates, including 1,103 fractional updates.
- Full before/after native traffic records and poses: all 1,440 match the original
  reference after normalizing route pointers and verified actor identities only.
- `check_traffic_math.py`: 50 reversal cases plus initialization and zero-time checks.
- Integrated `check_traffic_wide.py`: 1,440 updates, 1,368 wide updates, 134 crossings
  and 12 capped/coasting updates; all match the independent model.
- Private actual-68000 old/new fixture: 44,000 arithmetic/route pairs, including
  8,495 prepared steady updates with persistent companions and changing intervals.
  Another 20,000 cases compare the complete pose hook and non-world fallback with
  pristine instructions, including signed-word extremes and DIVS overflow.
- Checked lookup/fallback fixture: 2,120 bounds/alignment/X cases and 3,840 native
  fallback pairs. The steady arithmetic reduction also matches exhaustively across
  4,173,312 combinations of speed, field count and nonnegative carry.
- All 108 native car states match. CUSTOM1-off checks pass all 162 declared ranges;
  the branch audit passes 140 ranges. Normal, DRIVE and ATTRACT builds remain
  byte-identical to the step-2 reference builds.

The local summary is `tmp/prof/p1-summary.json`; the retained traces include hashes,
field fingerprints and verified compressed archives. Harness tools and game bytes
remain under ignored `tmp/`.

G2 remains a report, not the P1 exit gate:

| | A off | A on | B off | B on |
|---|---:|---:|---:|---:|
| Swaps in the 500-field window | 38 | 38 | 83 | 58 |
| Complete intervals measured | 37 | 37 | 82 | 57 |
| Mean frame time (ms) | 260.96 | 256.62 | 119.95 | 174.66 |
| Polygons per complete frame | 57.76 | 55.43 | 13.78 | 29.12 |

**B is a scene mismatch**: polygon workload differs by more than 5%. Passing P1
closes only the traffic cost item; it does not close the combined G1 gate or step 4.

### P2 Replay recording: complete (target ≤ 0.3 ms per frame)

D2's R2 policy is retained: the native ring still contains 90 exact, fixed-field,
158-byte samples at eight-field intervals. R1's frame-stamped sampling is not used.
Gameplay retains the exact endpoint pairs and rational weights; resampling runs
before the first native replay reader at `$10b44`. The resolved ring is byte-for-byte
identical to eager interpolation. All words remain covered by their existing classes:
player U/U/S/angle/angle/angle/packed and twelve traffic U/S/U/angle/angle/angle;
only the packed high nibble is held from the left endpoint.

The implementation:

- Allocates 29,476 bytes once: 90 eight-byte descriptors and 91 pairs of 158-byte
  endpoints. All samples emitted by one transaction share its pair. A pair cannot
  be reused until at least 90 later emitting transactions have overwritten all
  descriptors that could reference it. Collision replacements reuse their pair
  and original descriptor position. Reset resolves old samples before clearing
  descriptors; a native, ineligible visit resolves pending history before writing
  and synchronizes cursors.
  Allocation failure retains eager interpolation.
- Swaps the two pose-buffer pointers instead of copying the previous pose. The
  native sampler's exact fields are copied directly; its twelve-car path is unrolled.
  Register-block copies retain endpoint pairs without repeated per-word arithmetic.
- Computes interpolation weights once per record and inlines the word classes.
  For denominator and absolute biased-word delta at most 255, directed Q16
  coefficients produce the exact rational floor; larger operands retain multiply/
  divide arithmetic. Equal angles still normalize and right endpoints copy verbatim.
  The Phantom recorder's shared scalar helpers retain their previous behavior.

This moves interpolation work to replay entry and uses additional memory; it does
not remove that work. The replay epoch starts after resolution, so the retained
history duration and playback clock are unchanged. Gameplay ring bytes are lazy
until a native consumer needs them; the live checker validates both the logical
pending ring at every transaction and the complete native ring at replay entry.

Fresh 500-field captures use matching slaves and listings, CUSTOM1 off/on, and
separate `HD_INSTANCE` values. A uses `p2-ready-a.slave`, constant accelerator, race
field 1; B uses `p2-ready-b.slave`, the full frozen tape through field 4000.
Captures are `p2-ready-{a,b}-{off,on}`. Each window is 10.015943522 seconds,
with only complete swap intervals averaged.

| Recorder share, ms/frame | A | B |
|---|---:|---:|
| Original native recording | 0.404396 | 0.440255 |
| Optimized recording | 0.684901 | 0.688903 |
| **Overhead** | **0.280504** | **0.248648** |
| Limit | 0.3 | 0.3 |
| Result | **PASS** | **PASS** |

The recorder share is all `_record*` work plus any native `$89d8` work; the native
share is zero in the enabled windows. The complete camera/record phase is
0.922886 → 1.290729 ms in A and 0.945090 → 1.204196 ms in B. Its other camera/event
work is excluded from this P2 component gate, but remains included in G1.

Required correctness evidence passes:

- Actual-68000 full-record comparison: 10,000 records / 790,000 words match both
  the previous implementation and the independent rational model, with register,
  stack and guard checks.
- Actual-68000 pending-history fixture: 10,000 individual records plus 2,000 shared
  transactions, 41,393 shared emissions, 500 replacement transactions and 95 full
  ring resolutions. All 4,060,047 words match, including wrap, more-than-a-ring
  intervals and allocation-failure fallback. Reset also preserves unresolved
  tail bytes and both possible incoming X flags.
- Native sampler comparison: 4,000 randomized states match pristine `$89d8`,
  including the twelve-car path and generic counts 0–12, with output guards.
- `check_recording.py`: A500 50 transactions, 78 emitted samples, 616 fields,
  77 fractional samples, 29 multiple-emission transactions (maximum three), and
  one collision replacing two samples. The 68020 has 191 transactions, 79 samples,
  628 fields, 55 fractional samples and one duplicate with no sample due. Every
  endpoint, logical ring, counter, write pointer and resolved native ring matches.
- `check_replay_playback.py`: A500 56 draws / 46 fractional draws for 78 records,
  exiting at age 625 against target 624; 68020 223 draws / 193 fractional draws
  for 79 records, exiting at 634 against target 632 (one final-draw overshoot). Both
  match every pose and consume 52 effect RNG calls. Audio checks and nine private interpolation records pass.
  Crash, early replay and later replay frames were visually inspected on both
  profiles; no visible corruption was found. These are not human handling laps.
- All 108 native car states match (`p2-ready-native`). CUSTOM1-off passes all
  163 declared ranges (`p2-ready-disabled`); the branch audit passes 141 ranges.
  Normal, DRIVE and ATTRACT builds remain byte-identical to the step-2 references.

The local summary is `tmp/prof/p2-summary.json`. Traces retain matching binary and
listing hashes, field fingerprints and verified compressed archives. Checkers,
game bytes, screenshots and other harness artifacts remain under ignored `tmp/`.

G2 remains a report:

| | A off | A on | B off | B on |
|---|---:|---:|---:|---:|
| Swaps in the window | 38 | 38 | 83 | 59 |
| Complete intervals | 37 | 37 | 82 | 58 |
| Mean frame time (ms) | 260.96 | 252.83 | 119.95 | 169.93 |
| Polygons per complete frame | 57.76 | 55.46 | 13.78 | 27.74 |

**B is a scene mismatch.** Passing P2 closes the recorder component budget only;
it does not close the combined G1 gate, change physics policy, or complete step 4.

### P3 Native engine runs: target ≤ phases started + 0.1 per frame (deferred)

1. **E1, exact memoisation (do first).**
   - Within one phase, if the anchor and every native engine input match the previous
     segment, reuse its endpoint instead of calling `$0b662` again. The inputs include
     throttle, brake, road/grass flags, turning flag, grade and pitch inputs, the skid flag
     and the contact mask.
   - First list every side effect of an engine call that the phase depends on, such as
     off-road throttle retention over `PH_DT`, pitch publication and audio. Apply those
     separately on a reuse.
   - Report the hit rate in both windows.
   - Expected: about 1.0 fewer run per frame under steady input, saving about 1.8 ms.
2. **E2, 68000-only latching per phase (only if E1's hit rate is below 70% in window B,
   and only after decision D3).**
   - The engine input is latched at each phase anchor and held to the end of the phase.
     This matches the native semantics of sampling once per native step.
   - The ongoing phase then never needs another engine run.
   - The 68020 and faster keep re-evaluating every frame.
3. **Exit criteria.**
   - Engine entries per frame are at most 1.75 in A and at most 1.25 in B.
   - `analyse_phase_*` all pass.
   - The 128-endpoint and 1440-partition oracles still pass (E2 needs a new oracle mode).

#### E1 evaluation: correctness passes, performance fails

The exact-memoisation candidate is **not retained in the runtime**. It passed the
checks below but does not meet P3's limits or offer the expected engine-cost saving.
The accepted P2 runtime has 2.432 / 1.879 engine entries per complete frame in A/B;
the plan's original 2.53 / 2.36 figures predate P1/P2.

Matched final runs are `p3-final-{a,b}-{off,on}`, each 500 PAL fields
(10.015943522 seconds). Each off/on pair uses an identical slave and listing:
`p3-check-a` uses constant accelerator, `p3-check-b` the frozen DRIVE tape.
Both start at the prescribed fields, including B's full preceding tape.
`p3-summary.json`, per-run `frame-budget.json` and `engine-cache.json` retain
full metrics. Probe runs precede a companion-state correction and are not final evidence.

| Metric | A | B |
|---|---:|---:|
| Engine entries / complete frame, candidate | 2.324324 | 1.982759 |
| P3 limit | ≤1.75 | ≤1.25 |
| P3 result | **FAIL** | **FAIL** |
| Cache hits / eligible segments, whole capture | 3 / 90 | 0 / 98 |
| Cache hit rate | 3.333% | 0% |
| Miss: new phase | 60 | 57 |
| Miss: changed throttle | 25 | 41 |
| Miss: changed pitch sine | 2 | 0 |
| Physics ms/frame, P2 → candidate | 15.487410 → 15.454362 | 10.985855 → 11.374694 |

Cache counts cover the whole capture, whereas frame metrics average only complete
swap intervals and also include engine calls through the fallback path. Do not
subtract the former directly from the latter. Phase starts must evaluate a new
anchor; changed throttle/pitch must miss under E1's exact-input rule. Thus the
assumed roughly one reusable evaluation per frame is absent from these windows.
B has no cache hits and its extra comparisons/bookkeeping are unproductive.

For G2 reporting only, CUSTOM1 off/on means are A 260.956033 / 252.293329 ms
(38 / 38 swaps; 57.756757 / 55.378378 polygons per complete frame), and
B 119.947041 / 169.925478 ms (83 / 59 swaps; 13.780488 / 27.689655 polygons).
**B is a scene mismatch.** These are the complete experimental stack against
CUSTOM1 off, not an isolated E1 FPS gain. No combined G1 or step-4 pass is claimed.

The candidate caches only the native `$0b678..$0b904` speed/RPM endpoint within
one phase. Its key includes both full Q16 anchors, gear, throttle, brake, contact
mask, skid, road, turning, grade-disable, engine-disable, automatic flag and
pitch sine. Gear-ratio/math tables are immutable; anchor preparation derives the
engine-speed input and clears scalar carries before every attempt.

Side effects were audited before reuse:

- Off-road throttle retention executes separately on every hit, with current
  throttle carry and `PH_DT`; these affect the decay side effect, not the already
  computed endpoint. The original signed >30 threshold remains intact.
- Native scalar LAST values are saved verbatim. RPM LAST can precede the native
  zero clamp, so reconstructing it from the clamped endpoint is not equivalent.
- `$0b904` onward runs every segment: fractional phase integration, automatic
  gear decisions only at phase completion, gear pointer updates, MPH and engine
  speed publication, brake clearing, and the existing final-segment audio gate.
- Position, spin decay and skid exit still run once per outer frame. Power/root
  memo tables are pure implementation caches; bypassed diagnostic hit counts
  are not gameplay side effects. Reset/new-phase paths cannot reuse a stale endpoint.

Verification of the final candidate:

- `check_p3_cache.py`: 6,000 actual-68000 comparisons against forced native
  evaluation, including 3,567 hits and 2,433 misses. All native globals, phase
  state, scalar companions, gear pointer, pitch/audio call count, preserved
  registers and stack match. Only the private audio body is replaced by a call
  counter; native pitch calculation and its gate execute unchanged.
- The existing 128 native endpoints and 1,440 input-partition comparisons pass.
- All five `analyse_phase_*` checkers pass: `p3-motion-a500` 17 steady-throttle
  returns, `p3-brake-a500` 46 braking returns, `p3-steer-a500` 9 steering returns,
  `p3-offroad-a500` 29 off-road-test returns, and `p3-skid-a500` / `p3-skid-020`
  43 / 188 grounded skid/slope returns. The skid checks stop explicitly at first
  unsupported airborne input, fields 519 / 574; they do not validate flight.
- `p3-native` matches all 108 reference states; `p3-disabled` passes 163 ranges;
  the branch audit passes 141 ranges. Normal, DRIVE and ATTRACT builds remain
  byte-identical to their established baselines.

**Deferred by the user.** Proceed to P4 without treating P3's limits as passed.
D3's conditional E2 authorization remains unchanged; input latching has not been
enabled. Revisit engine cost after the remaining performance phases. The candidate
source, binaries, checkers and verified compressed traces remain under ignored
`tmp/` for follow-up. Neither numeric limits nor physics policy have been relaxed.

### P4 Slave physics helpers: complete with the approved helper-budget exception

1. **Per-frame constant block.**
   - In `_time_outer`, compute these once per frame:
     - n, 8+n and 8−n;
     - T in Q16;
     - the Q16 retention coefficients from the existing tables (throttle r^T, spin,
       contact 1−0.75^T and 0.75^T).
   - Hooks read the block instead of calling `_time_scale_word`, `_time_split_q16` or
     `_time_multiply_fields`.
2. **Narrow the arithmetic.**
   - Replace the 32×16 helper calls with inline `mulu.w`/`muls.w` wherever the documented
     operand ranges fit 16 bits. Cite the range audit next to each change.
   - In `_time_normalize_angle`, use a bounded compare-and-subtract on 1440 instead of
     the general path.
3. **Run the projection once per frame.**
   - Compute `_phase_project` and `_projection_integer_components` once per frame instead
     of once per segment, whenever pitch and yaw are unchanged between segments.
4. **Lighter hook prologues.** Replace `movem.l d0-d7/a0-a6` with the registers each
   hook actually clobbers. The branch audit must still pass.
5. **Exit criteria.**
   - Original target: slave physics symbols total at most 1.4 ms per frame in both
     windows. The user explicitly accepted 1.494 / 1.616 ms; final 1.425 / 1.515 ms
     lies within that accepted exception. The original numeric target is not met.
   - The game-code part of physics is at most 1.0 ms per frame above the original after
     P3.

#### Final P4 result

The accepted helper work is unchanged. An additional native root optimization
closes the remaining native-physics limit without resuming P3 or changing cadence.
The original Newton iteration, initial guess and two-cycle termination are retained
exactly. When the divisor and quotient fit unsigned words, one DIVU replaces the
general long divider; a wider divisor or overflow falls back to the original
divider. Iterates stay in registers. The 96-byte body and eight NOP bytes replace
the original 104-byte routine at `$9564`; this reduces actual native work rather
than moving it into the slave cost bucket. Zero input, D1, saved registers and
final materialized flags match the original. Positive inputs yield positive
iteration divisors, so the fast path does not introduce division by zero.

Final matched profiles are `p4-native-root-{a,b}-{off,on}`. The paired audit checks
identical slave, listing, game and emulator hashes and configuration except CUSTOM1,
with the established 500-field windows at race fields 1 / 4000. All four traces
were compressed with decompressed SHA-256 verification before deleting raw copies.

| Metric, ms per complete frame | A | B |
|---|---:|---:|
| Slave helpers | **1.425257** | **1.515212** |
| User-accepted helper checkpoint | 1.494050 | 1.616246 |
| Native physics, matched disabled | 9.703691 | 6.494453 |
| Native physics, enabled | 10.403488 | 6.387204 |
| Native increase (limit +1.0 ms) | **+0.699797 — PASS** | **-0.107250 — PASS** |

A uses 37 / 38 complete disabled/enabled frames; B uses 83 / 54. The trajectories
still differ, so these measurements do not establish equal-scene FPS or pass G1.
Constant preparation outside physics remains part of the later G1 accounting.
The paired report and source fingerprints are in ignored
`p4-native-root-pair-summary.json`.

Additional final-build validation:

- 687,686 root comparisons against the actual original routine: every input from
  0 through 350,000, every unsigned-long square boundary with nearby values, and
  random unsigned longs. All data/address registers, stack and materialized flags
  match; the live replacement bytes match the verified candidate.
- 6,000 whole-engine, 1,200 full-frame and 300 native-physics comparisons pass
  with the root replacement, retaining the accepted helper checks below.
- Live motion 17, steering 9, off-road 29 and braking 46 checks pass
  (`p4-root-motion`, `p4-root-steer`, `p4-root-offroad`, `p4-root-brake`).
  Grounded skid prefixes pass 43 A500 / 190 68020 checks, stopping at the first
  unsupported airborne inputs at fields 515 / 573 (`p4-root-skid-a500` /
  `p4-root-skid-020`). Full-flight and independent terrain/contact validation
  remain outside these fixtures' scope.
- 108 native car states match (`p4-root-native`), all 164 disabled patch ranges
  pass (`p4-root-disabled`), and all 142 branch ranges pass. Normal, DRIVE and
  ATTRACT binaries remain identical to their step-2 baselines.

P4 is complete under the explicit helper-budget exception. P3 remains deferred;
this does not close G1 or the remaining step-4 work.

#### Accepted helper checkpoint before the native-root optimization

On 2026-10-12 the user explicitly accepted the remaining **0.094 / 0.216 ms**
helper-budget excess. This is a documented exception to the original 1.4 ms
helper target, not a claim that the target was met. It does not waive the native
physics limit, P3's limits or G1. A later direct-RPM-clamp experiment was discarded;
the accepted helper checkpoint is the validated `p4-motion-a` / `p4-motion-b`
build. The final native-root result above supersedes its remaining native gate.

The matched `p4-motion-{a,b}-{off,on}` profiles each cover 500 PAL fields, starting
at race fields 1 / 4000 with constant input / the frozen VERIFY_DRIVE tape.
The paired audit verifies identical slave, listing, game and emulator hashes and
identical configuration except CUSTOM1. Results and source fingerprints are in
the ignored `p4-motion-pair-summary.json`.

| Metric (ms per complete frame) | A | B |
|---|---:|---:|
| Slave physics, accepted P2 | 3.812752 | 3.405057 |
| Slave physics, accepted P4 helper result | **1.494050** | **1.616246** |
| Excess above original 1.4 ms target, accepted by user | 0.094050 | 0.216246 |
| Native physics, matched disabled | 9.703691 | 6.522713 |
| Native physics, enabled | 11.524498 | 7.159635 |
| Native increase (limit 1.0 ms) | **1.820807 — FAIL** | **0.636922 — PASS** |

Averages use 37 / 38 complete disabled/enabled frames in A and 82 / 55 in B.
Trajectories differ, so raw frame-time or swap-count differences are not equal-scene
FPS evidence. Constant preparation outside the physics bucket must also count
against G1. No overall FPS acceptance is claimed. All four traces are compressed;
decompressed SHA-256 was verified before deletion of raw copies.

Implemented changes:

- A keyed per-frame block stores n, 8+n, 8-n, Q16 T and the existing rounded
  retention/contact coefficients. Hooks reuse coefficients only for matching
  intervals; native n8 and partial segments retain their own coefficients.
- Exact zero/native-step shortcuts, bounded angle normalization with a full-long
  fallback, bounded throttle arithmetic and cheaper signed Q16 splits. Small
  signed rate scaling uses multiplication, shifts and signed remainder repair.
  Range assumptions are documented next to the shortcuts.
- Paired velocity/RPM interpolation and three unrolled position axes retain exact
  modular arithmetic and signed remainders. Native RPM/gear conversion is reused
  only with its complete key. Intermediate scalar companion stores are removed;
  final frame publication still produces their exact original values.
- A generated power table preserves both native conversions, including signed
  DIVS overflow. All four immutable gear ratios are validated before use;
  inactive or unexpected-ratio paths retain the original helper. Phase builds
  bypass the mostly-missing square-root memo wrapper; reference builds retain it.
- Projection preserves native word rounding and uses exact flat/cardinal paths.
  Publication reuses the integer vector from native B500 and computes only a
  needed neighbor. Register saves are removed only where the native caller
  discards them or the called helper already preserves them.

Unchanged yaw/pitch alone is not a valid projection reuse key: velocity affects
native rounding. Per-frame reuse measured by velocity alone has an optimistic
ceiling of only 5/51 calls in A and 20/186 in B, before lookup costs. No projection
cache, engine endpoint cache, input latching or physics-cadence change was added.

Verification of the accepted source:

- 162,003 assembled 68000 helper comparisons; 65,537 constant blocks,
  196,611 cached and 196,608 equal/different-key coefficients, 306 contact
  responses; native oracle coverage of 128 endpoints / 1,440 partitions.
- 4,096 guarded power-lookup cases: first use, ready, inactive and unexpected
  ratios. 6,000 engine cases, 1,200 full phase-frame cases, 300 angular-motion
  cases and 300 native-physics cases. Final scalar companions, native state,
  audio effects and required register outputs remain exact; only unused pure
  memo bookkeeping is excluded. Arbitrary angles are tested separately because
  full contact exceeded the harness bound in the original implementation.
- Current live pristine-engine oracles: motion 17 (`p4-current-motion`), steering
  9 (`p4-current-steer`), off-road 29 (`p4-current-offroad`), braking 46
  (`p4-prologue-brake`). Grounded skid prefixes pass 43 A500 / 189 68020 checks
  (`p4-prologue-skid-a500` / `p4-prologue-skid-020`), ending at the first
  unsupported airborne input, fields 514 / 572. These do not validate full
  flight, independent terrain/contact dynamics or whole trajectories.
- All 108 forced-native car states match (`p4-motion-native`); CUSTOM1-off
  passes all 163 declared ranges (`p4-motion-disabled`); branch audit passes
  141 ranges. Normal, DRIVE and ATTRACT builds remain byte-identical to their
  step-2 baselines. All executable bytes, fixtures and captures remain ignored.

At that checkpoint, A's native-physics increase was 0.821 ms above its separate
limit. The final native-root optimization above closes this remaining P4 gate.

### P5 Remaining hooks: complete

The unchanged target is at most 0.3 ms per complete frame in both windows.
Matched `p5-empty-{a,b}-{off,on}` captures use rebuilt slaves and listings, the
same emulator/game/configuration except CUSTOM1, 500 PAL fields (10.015944 s),
and the established field-1 constant-input / field-4000 frozen-tape windows.
`p5-empty-pair-summary.json` records hashes, component costs and frame counts.

| Remaining hooks, ms/frame | A | B |
|---|---:|---:|
| Measured overhead | **0.247402** | **0.292055** |
| Target | 0.300000 | 0.300000 |
| Headroom | 0.052598 | 0.007945 |
| Result | PASS | PASS |

This retains section 1's phase-difference metric: outer hook, loop body, controls,
recovery and replay/publication, plus timing-slave work outside the simulation
phases. The analyzer retains every owner bucket, including those below its
0.02 ms display threshold. B includes 0.044020 ms of off-road audio; both windows
include about 0.0218 ms of dispatcher work after physics. No costs were omitted
or reassigned to meet the target, and no timing or input windows were changed.

The complete cost gate remains open. Total simulation overhead is
3.230272 / 5.690624 ms/frame. B exceeds the plan's 3.78 ms and the 4.259357 ms
budget derived from this pair's original frame time. Physics helpers measure
1.455936 / 1.755018 ms; native-physics increases are 0.785030 / 2.999223 ms.
These current B figures do not reproduce P4's accepted figures. Late-window
recovery and trajectory are sensitive to frame timing, so these pairs do not
establish a same-state physics regression. Complete frames off/on are A 37/38,
B 72/59; raw frame means are A 260.956/248.290 ms and B 137.719/169.083 ms.
These are not equal-scene FPS comparisons. P6 must address the remaining cost;
P5 completion does not waive the physics or overall closure requirements.

Implemented without changing the time/input/cadence model:

- The common pre-68020 outer frame publishes elapsed interval, counters, scalar
  interval and event resets together. Bounded, forced-native and oversized paths
  retain the shared dispatcher; Phantom retains its preserving entry.
- Begin/take avoids nested saves. Latch and controls use native caller-scratch A0;
  zero-debt after-physics saves A0 only. Inactive recovery skips its no-op native
  prologue while retaining the presentation reset and condition flags.
- Common intervals 0–32 copy four exact precomputed constants into a compact
  cache. Wider intervals retain the original calculation; none is approximated.
- Throttle +/-2 ramps use equivalent Q16 arithmetic in native scratch registers.
  Empty crash countdowns and ordinary non-replay frames skip redundant calls.
  Off-road audio preserves cadence, counters, arguments and X with scratch registers.
- The native nearest-road recovery scan inlines its word absolute values and uses
  counted loops. Both road lists, height filtering, word overflow, first-tie
  selection, globals, registers and final flags remain exact. This reduces actual
  recovery work encountered by the timing-sensitive late window.

Validation passes:

- 24,000 assembled boundary cases cover both CPU policies, overflow, race exit,
  inactive paths, crash countdowns and replay return. Registers (except native
  caller-scratch A0 at controls/latch), stack, state, destinations and materialized
  CCR match.
- 65,537 constant blocks across every unsigned word; 196,611 cached and 196,608
  fallback coefficients; 306 contact responses.
- 151,072 throttle cases and 12,000 complete native controls/latch calls;
  16,000 off-road audio cases including wraparound and emit/skip.
- 12,003 complete native road-scan comparisons, including empty lists, ties,
  signed extremes and 65,535-entry lists. Installed profile code matches the
  tested routine plus padding.
- Final build: 108 forced-native states match, CUSTOM1-off passes 165 ranges,
  and the 143-range branch audit passes. Rebuilt A/B binaries match the captured
  slaves; normal, DRIVE and ATTRACT remain byte-identical to step-2 baselines.
- Final live 500-field A500/68020 policy checks preserve full/bounded intervals,
  physics/render counts and single engine-pitch publication.
- The preceding build's unchanged audio/control routines pass live A500/68020
  off-road sound checks and 29 steering/off-road state checks (14 off-road frames,
  15 decay segments). The final additional empty-countdown shortcut is covered
  by the final boundary, native-state and CPU-policy checks above.

Evidence remains under ignored `tmp/dev/`; completed profiles are SHA/decompression-
verified compressed archives. `p5-final-audit.json` records the final evidence and
source fingerprints. P5 is complete without a budget exception.

### Budget after P1–P5 (ms per frame; baseline before P1)

| Component | Now A / B | Target |
|---|---:|---:|
| Traffic | 6.36 / 5.49 | ≤ 0.8 |
| Physics, game part (extra engine runs) | ≈2.0 / ≈1.9 | ≤ 1.2 (A), ≤ 0.4 (B) |
| Physics, slave part | ≈3.9 / ≈3.7 | ≤ 1.4 |
| Replay record | 3.89 / 2.90 | ≤ 0.3 |
| Other hooks | 0.42 / 0.48 | ≤ 0.3 |
| **Total** | **16.64 / 14.98** | **≤ 4.0 (A, budget 8.07), ≤ 3.2 (B, budget 3.78)** |

If the total in B is still over 3.78 ms after P1–P5, profile again and treat the largest
remaining symbol as P6. Do not relax G1.

### P6 Remaining physics arithmetic: complete; G1 still open

Fresh `p6-base-{a,b}-{on,off}` profiles reproduce P5's final build and identify
physics as the largest remaining overhead: B 4.754241 ms/frame of the total
5.690624 ms/frame. Within physics, the unsigned long divider at `$122be` is the
largest individual arithmetic routine by self cost: 0.800366 ms/frame, ahead of
the root (0.617422), signed-word multiply (0.597434), and ratio helper (0.308128).
This is the P6 target; traffic's larger replacement symbol mostly represents
original traffic work and contributes only 0.376724 ms/frame net overhead.

The CUSTOM1-gated phase patch now replaces that divider with an exact equivalent:

- A short divisor and word-sized quotient use one `DIVU`; a larger quotient
  retains the native two-word division.
- A wide divisor is aligned to the dividend, then the restoring loop visits only
  the required quotient bits. The baseline B wide calls average 4.16 quotient bits
  rather than the native fixed 16 iterations.
- Quotient, remainder, preserved registers, stack and final condition flags stay
  exact. The native final wide-loop flags are reconstructed after loop bookkeeping.
  Engine inputs, phase sampling, update cadence and P3 deferral are unchanged.

Final paired captures are `p6-fast-{a,b}-{on,off}`, using 500 PAL fields and the
unchanged A/B anchors, fixtures and CUSTOM1 comparison. All frame accounting uses
complete swap intervals. The same build/listing/game/emulator/configuration is
verified within each pair. `p6-fast-pair-summary.json` retains exact values.

| Measured ms per complete frame | Baseline A | P6 A | Baseline B | P6 B |
|---|---:|---:|---:|---:|
| Physics phase | 11.943857 | 11.703468 | 8.500373 | 8.460343 |
| Total simulation overhead, existing accounting | 3.230272 | 3.083583 | 5.690624 | 5.739547 |
| G1 fixed budget | 8.070000 | 8.070000 | 3.780000 | 3.780000 |
| G1 result | PASS | PASS | OPEN | OPEN |

Complete divider-call comparisons separate the arithmetic saving from changed
trajectories. For common operand pairs, weighted by candidate call frequency:

| Physics divider calls | A | B |
|---|---:|---:|
| Identical operand pairs | 15 | 10 |
| Matched candidate calls / all candidate calls | 604 / 640 | 82 / 512 |
| Original cost for matched calls, ms | 34.157199 | 4.634006 |
| Optimized cost for matched calls, ms | 24.255581 | 3.294713 |
| Saving on matched calls | **28.99%** | **28.90%** |

These totals cover complete divider calls throughout the trace, exclude interrupt
execution, and include the new entry jump. B's matched subset is limited; it is not
an equal-scene whole-game speedup. Whole-trace physics divider costs are
36.176994 → 25.686974 ms in A and 47.221584 → 33.506771 ms in B, with different
operand distributions. `p6-divider-matched-cost.json` records the comparison.

The shared native divider also serves scene preparation/background work. The
existing conservative formula charges its new slave code there in full, without
subtracting the former native rendering work. No costs were excluded to make G1
pass. Current other-hook totals are 0.306802 / 0.342149 ms; these are not fresh
P5 passes. Likewise, moving native arithmetic into the slave changes the native/
slave split; it does not demonstrate new physics steps. The P4/P5 acceptance
records above refer to their respective committed builds.

Current raw frame means off/on are A 260.956 / 248.290 ms and B 137.719 / 165.348 ms;
complete frame counts are A 37/38 and B 72/59. Scene and contact work vary with the
trajectory. B's total measured overhead is slightly higher despite the exact
arithmetic improvement. P6 completion therefore does not claim G1 or step-4 closure,
and does not broaden the P4 exception. P7 below reports the 68020 result; D3's
conditional engine-latching option remains available under its stated conditions,
without treating deferred P3 as passed.

Validation: 172,440 actual-68000 original/replacement comparisons with nonzero
divisors, including quotient boundaries, wide divisors, both division paths, every
register, remainder, stack and materialized CCR. Both installed profile routines
match the tested 158-byte body. All 108 forced-native states match; CUSTOM1-off
passes 166 ranges, the branch audit passes 144 ranges, and normal/DRIVE/ATTRACT
builds remain byte-identical to step-2 baselines. Rebuilt profiled binaries match.
Evidence and SHA/decompression-verified traces remain under ignored `tmp/dev/`.

### P7 68020 check: complete (reported, not gated)

Measured 2026-10-13 on the `a1200-020` profile: PAL A1200/68EC020, 2 MiB Chip RAM,
4 MiB Fast RAM, no Slow RAM. The retained emulator configuration confirms real
CPU speed, multiplier 4, 24-bit addressing, and CPU/memory/blitter cycle-exact
execution. The backend supports instruction timing for this CPU.

`p7-a` and `p7-b` rebuild byte-identically to the P6 acceptance fixtures from
`368853a`; no game source changed for P7. Each uses the same slave with CUSTOM1=0
and CUSTOM1=1. Captures `p7-{a,b}-{off,on}` retain matching slave/listing, game,
emulator and configuration hashes within each pair. A uses constant accelerator
from field 1; B uses the frozen input tape from field 4000 after replaying its
preceding history. Each trace spans 500 PAL fields, **10.015943522 seconds**.

| A1200 measurement | A off | A on | B off | B on |
|---|---:|---:|---:|---:|
| Displayed frames (buffer swaps) | 164 | 150 | 214 | 222 |
| Whole-window displayed FPS | 16.374 | 14.976 | 21.366 | 22.165 |
| Complete swap intervals analyzed | 163 | 149 | 213 | 221 |
| Mean complete-frame time, ms | 60.833 | 66.280 | 46.835 | 45.140 |
| Polygons per complete frame | 49.472 | 56.013 | 31.207 | 28.045 |

FPS uses all swaps divided by the full window duration. Frame costs use only
complete swap intervals, so FPS is not exactly the reciprocal of that mean.
The differing polygon counts demonstrate changed scene workloads; literal FPS
changes are not isolated timing-code speedups or slowdowns.

| Net enabled-minus-original phase cost, ms/frame | A | B |
|---|---:|---:|
| Outer hook + loop + controls | 0.073820 | 0.073561 |
| Recovery `$108a2` | -0.172868 | -0.133803 |
| Replay/publication `$10f52` | -0.357289 | 0.001052 |
| Camera + recording | 0.053217 | 0.039037 |
| Traffic | 0.292612 | 0.297427 |
| Physics | 0.376263 | 0.274811 |
| Other timing-slave work outside those phases | 0.017549 | 0.023690 |
| **Total, existing accounting** | **0.283304** | **0.575775** |
| **Share of this profile's own original frame** | **0.4657%** | **1.2294%** |

This uses the existing simulation phase-difference formula and retains every
outside-phase slave bucket, including the shared native-equivalent divider.
The negative recovery/replay deltas are observed workload differences, not proof
that identical simulation work is that much cheaper. As an accounting sensitivity,
crediting no negative phase deltas gives **0.813461 / 0.709578 ms/frame**, or
**1.3372% / 1.5151%** of the respective original frame times. Neither figure is
an independently measured equal-scene FPS penalty or general handling acceptance.

The 68020 physics policy is unchanged: physics runs every rendered frame, with
bounded substeps for long frames. The measured enabled rates here are about
15 / 22 FPS, not 50 FPS. These net overhead figures correspond to 1.42% / 2.88%
of a 20 ms frame budget, but the current whole-frame costs are 66.28 / 45.14 ms;
P7 does not establish the step-5 50 FPS goal. It is a report, not a new gate, and
does not close the outstanding A500 G1 requirement or C3 simulation-speed checks.

All four traces pass duration, instruction coverage and swap-count checks;
coverage is above 99.99998%. Source/build fingerprints and paired configurations
are audited. Profiles are SHA/decompression-verified compressed archives; no raw
traces remain. Reports are `p7-summary.json`, each run's `frame-budget.json` and
`trace-check.json`, and `p7-final-audit.json`, under ignored `tmp/dev/`.

## 5. Closure of step 4

The P6 B-window result is accepted under the temporary exception above. The current
full closure build still exceeds the A-window limit. These remain acceptance
items of `PERFORMANCE_PLAN.md` step 4.7, made concrete.

- **C1, solver coverage — complete (2026-10-13).** Airborne flight, partial
  contact, landing, manual gears, neutral and signed rollback use the phase path.
  Native gravity/landing still run once per outer frame. Manual requests are
  consumed on the first engine segment; a changed gear restarts the phase from
  the integrated velocity and native converted RPM. Crash/recovery/replay retain
  their existing paths; invalid gear/RPM states and an inactive/zero-time dispatch
  remain defensive guards, not supported driving modes.
  - Final A500 windows A/B contain 39/58 complete driving frames and **0/0
    fallbacks (0% each)**, below 2%. Neither window contains a crash frame.
  - Independent native-engine and XYZ oracles pass 110/376/74 flight/landing
    returns on A500/68020/slowed A500 and 145/117 manual returns on A500/68020.
    Both manual captures cover gears 0–4 and all nine scheduled gear changes
    after the initial first-gear selection. A500 uses a controlled low-throttle
    fixture to complete the sequence before a collision; it is not the input tape.
  - Signed projection passes 20,000 private 68000 cases. Another 297 complete
    native-step engine/position comparisons include 135 rollback cases, neutral
    and zero/partial/full contact; all native car globals match.
  - Final `c1-final-native` matches all 108 reference states. CUSTOM1-off,
    branch safety and the ordinary build checks pass. Artifacts and harnesses
    remain ignored under `tmp/dev/`; summary: `c1-summary.json`.
  - Projection still quantizes the scalar fraction to Q6; flight/shift scalar
    state retains Q16. This is recorded quantization, not a full-trajectory or
    equal-time acceptance claim. C2–C5 remain separate.
- **C2, native step.** The forced T=1 108-state comparison and the 650-return
  controls-indexed comparison must still match. The second one is still subject to the
  BCD clock dependency (D4).
- **C3, equal elapsed time.**
  - Use the controlled-start fixtures (`INITIAL_THROTTLE`, braking from speed 100, and
    held steering).
  - Compare the A500, the slowed A500 (CUSTOM4=4), the 68020 and the 68040 at equal
    elapsed fields.
  - The tolerance is the bound from one A500 frame of input-sampling latency, computed
    from the recorded rates, plus the documented quantisation phases.
  - Lap and checkpoint times must agree within one frame.
  - **Progress, not C3 acceptance (2026-10-13):** controlled starts exposed an
    idle-phase dependency: the slowed A500 settled at speed 226 while the other
    three profiles settled at 228. A fully zero velocity/RPM state now restarts
    the response phase at zero; nonzero hidden fractions are preserved. All four
    profiles now settle at 228 in third gear. Their 343 flat-trajectory returns
    match the same one-field native-engine reference in fractional velocity,
    RPM, gear and absolute X after the independently observed throttle start.
    Start publication still differs by 14 consumed fields across the matrix;
    this is retained in the evidence, not declared equal wall-time behavior.
    Held steering and lap/checkpoint acceptance remain open.
  - **Braking component passed (2026-10-13):** the controlled fixture uses a speed-200
    brake trigger so throttle is zero before the descending speed-100 crossing.
    All 216 complete braking returns across the four profiles match the
    independent one-field native recurrence in fractional velocity, RPM, gear
    and absolute X. Comparing 0–164 fields after speed 100, the maximum velocity
    spread is 15 and distance spread is 5.875 world units. The measured ordinary
    A500 frame is at most 15 fields; recorded maximum rates give bounds of 45
    velocity units and 33.046875 world units. Charging a full field of crossing
    uncertainty to each profile still fits those bounds. The conservative
    stopping-time range is 157–163 fields (spread 6, below 15). These are
    braking-only results; they do not pass steering or overall C3.
  - **Steering startup corrected (2026-10-13):** native steering now uses the
    velocity/RPM anchor of each existing engine chunk. Roll, pitch, spin,
    contact and gravity retain their outer-frame work. The unchanged 550-field
    fixture has an eight-field steering delay on all four profiles; all 779
    recorded headings match its exact half-unit-per-field curve. Each profile
    now settles at speed 164 in third gear. Native-step and stop/restart checks
    pass. The controlled equal-time bounds below now pass; lap/checkpoint timing
    remains open, and final cost measurements are still required.
  - **Current-build controlled bounds passed (2026-10-13):** comparison uses
    consumed simulation fields, retaining measured throttle-publication offsets.
    Straight acceleration has maximum speed/position spreads 65.5/74.8125 versus
    bounds 75/80.15625 through the full flat response and settled plateau.
    Held steering covers all 0–539 common fields: speed/angle/position spreads
    65.5/7/73.913327 versus bounds 75/7.5/80.130890. An independent pristine-engine
    and native-trigonometry reconstruction matches every fractional XYZ/scalar
    return globally, without resetting pose each frame (775 active returns).
    Current-build braking passes again: spreads 11/3.083333 versus 45/33.046875,
    with conservative stop-time spread 5 fields versus a 15-field allowance.
    Lap/checkpoint timing remains unverified; these are simulation-trajectory
    checks, not equality of displayed poses at every video field.
- **C4, extreme T.**
  - Run collisions, the loop and the jump on the slowed A500 (largest T) and on the
    68060 (smallest T).
  - There must be no tunnelling and no missed checkpoint. The sweep counters must show
    any long-frame crossing.
  - **Targeted diagnostics (2026-10-13):** a native-traversable loop fixture now
    reproduces contact loss with timing enabled on both extreme profiles.
    Slowed-A500 wheel error exceeds the native pitch helper's 180-unit domain,
    causing zero correction. A private saturation experiment improves traversal
    but does not validate contact/exit behavior and is not in the game source.
    The jump blocker is a traffic vehicle; a clear lane gives collision-free
    takeoff on both profiles, but their landing states still differ at field 299.
    A fast-run out-of-domain rear-contact sample is now confirmed to erase its
    launch pitch rate. Privately retaining that rate improves peak height but
    still fails to reproduce the landing trajectory; no fix has been promoted.
    These are open failures, not C4 acceptance; details are in `GAME_TIME.md`.
  - Further diagnosis separates two causes: the current fast X360 fixture loses
    contact at field 259 as the car center crosses the road's side edge
    (115.6 units versus a 115.3-unit half-width). The slow failure is near the
    centerline and still has the invalid pitch input. Private road-angle and
    scaled-response combinations do not pass. X400 input reaches a waypoint
    but fails to exit cleanly; native speed-dependent steering halving must be
    considered when calibrating the fixture. An exact first-loss memory snapshot
    is retained for native terrain replay. These findings do not close C4.
  - A later centerline failure is now reproduced as rendering-dependent terrain
    selection: E94A becomes zero, so the native flat-ground query runs despite
    the road query finding contact. Optimized and pristine road arithmetic agree.
    An unbounded private selector completes both loop profiles, but is withdrawn
    because native road planes extend beyond their edges. A bounded prototype
    now honors the jump's `$0400` gap flag within one course list. Its helpers
    pass 5,000 geometry, 320 record-mask and 256 native-hook comparisons. Fast
    and slowed-A500 loops exit without a crash (two brief fast contact losses).
    The jump still fails: fast remains airborne at field 449; slow lands but
    records a crash. Course transitions, vertical support and wheel-edge behavior
    remain unverified. No terrain change is promoted. See `GAME_TIME.md` for
    exact scope and limitations; this is not C4 acceptance.
  - Exact-state jump replay identifies another render-dependent selection
    problem: at field 135 a type-39 object's nearly vertical end face becomes
    the supporting plane, producing wheel heights 525/525/-735/-735 and clearing
    the pitch rate. Its original end face is also unsuitable; the upward-facing
    top gives 6/6/9/9. Clipping distortion alone is not the cause. Supporting-face
    selection still needs a validated fix; no object exception is promoted.
    A private finite-face predicate passes 10,045 oracle comparisons. The saved
    top covers only one wheel, so substituting its infinite plane for every wheel
    is also insufficient. Direct native transformation of a cloned object now
    reproduces all five captured polygons. At the predicted physics pose, finite
    queries find only right-rear support; replaying contact with that support
    preserves the prior pitch rate. These are isolated-state checks. Per-wheel
    world-query integration and complete trajectory validation remain open.
    The private wrapper now runs in gameplay: the fast jump lands without a
    crash (peak 221.125, last airborne field 345); the slowed A500 still crashes
    (peak 229.125, last airborne field 332). Its invocation remains gated by the
    renderer's object flag, and overhead/road merging and cost are unvalidated.
    A subsequent native-physics capture explicitly records crash counter 25 at
    landing too. The slow crash alone is therefore not a regression; earlier
    no-crash expectations for this fixture were unsupported. The fast no-crash
    outcome remains a handling mismatch. Native penetration/impact thresholds
    and landing transition timing now guide the investigation. This is verified
    prototype progress, not a promoted fix or C4 completion.
  - **Landing gate implemented:** variable updates now apply the native fall-speed
    threshold (>50) at full/diagonal contact, removing the frame-dependent extra
    penetration requirement. Zero/eight/forced-native paths are preserved. The
    final source passes 1,568 cases (1,008 native-path comparisons), ordinary
    binary equality, 145 branch ranges and disabled patch checks. Both private
    jump profiles reproduce the native crash outcome. This closes that landing
    discrepancy only; terrain selection and C4 trajectory acceptance remain open.
    The last C5 measurements predate this change and need a final-source rerun.
- **C5, gates.** G1 passes or meets the explicitly accepted temporary exception; G2 is reported; `check_disabled.py` passes; the
  normal build is byte-identical.
  - **Current full-build measurement (2026-10-13):** fresh paired 500-field A500
    windows use the current phase solver and `VERIFY_TIME_SWEEP`. Before the
    eligibility change, net overhead was 10.953151 / 5.066073 ms/frame. The
    sweep now rejects inactive/non-solid scene entries before saving registers
    and filters world entries before calling the collision candidate routine.
    Eligible objects, counters, native priority and earliest-contact selection
    retain their existing behavior. This does not resume deferred P3.
  - Final pairs `c5-filter-{a,b}-{off,on}` measure **9.523709 / 3.914688 ms/frame**.
    A exceeds 8.070 by **1.453709 ms**; B is below the accepted 5.740 allowance.
    Sweep self cost is 3.486102 / 1.315067 ms/frame, versus 4.970903 / 1.932414
    before this change. Changed trajectories make these observations, not an
    isolated same-work speedup. B's disabled baseline itself changes with the
    build, consistent with the already-open native clock dependency.
  - G2: off/on swap counts are A 38/38 and B 63/58 in 10.015944 seconds; FPS is
    A 3.794/3.794 and B 6.290/5.791. Complete-frame means are A 260.956/256.625 ms
    and B 160.578/172.555 ms. Polygons/frame are A 57.757/55.000 and B
    36.548/29.333: B is a **scene mismatch**, not equal-scene FPS evidence.
  - All eight pre/post traces pass duration, swap-count and instruction-coverage
    checks (minimum coverage 99.99998%). Each pair retains matching slave,
    listing, game, emulator and configuration apart from CUSTOM1. All traces
    have SHA/decompression-verified compressed archives; raw copies are removed.
    Final CUSTOM1-off captures pass all 167 declared ranges with the appropriate
    input-fixture exclusions. The ordinary build is byte-identical to its
    baseline; all 145 branch ranges pass. Actual 68000 collision tests pass
    32 native-loop cases, 96 world-pool cases and 10,000 signed interpolations.
    Reports: `c5-current-summary.json`, `c5-filter-summary.json`, and per-capture
    `frame-budget.json`, `trace-check.json`, `disabled.json`. **C5 remains open.**
  - **Latest scan optimization:** `c5-scan-{a,b}-{off,on}` supersedes the
    preceding final pair. World scans prepare their radius and count once per
    pool; an early overflow subtracts the unvisited suffix from the counter.
    Scene misses reuse the exact native rotated point when object byte 34 says
    it was calculated. No collision approximation or engine-cadence change is
    introduced. Native-loop tests also exercise byte-34 misses; 20 iterator
    cases cover empty pools, early overflow and counter wraparound. The 10,000
    broad-phase cases retain all 1,395 exact contacts, with 88 safe rejections.
  - Latest G1 overhead is **8.923069 / 7.334501 ms/frame**: both windows fail,
    exceeding 8.070 / 5.740 by **0.853069 / 1.594501 ms**. Sweep self cost is
    3.012669 / 0.956033 ms/frame. B's changed disabled trajectory prevents
    attributing the total-overhead change solely to the optimized instructions.
    Do not select a cheaper baseline from another build to claim acceptance.
  - Latest G2 off/on swaps are A 38/38 and B 73/60; FPS is A 3.794/3.794 and
    B 7.288/5.990. Complete-frame means are A 260.956/255.542 ms and
    B 137.719/168.743 ms. Polygon means are A 57.757/54.838 and B 26.708/29.542.
    Both differ by more than 5% and are **scene mismatches**.
  - All four latest traces cover 500 fields (10.015944 seconds), with matching
    paired artifacts/configuration and instruction coverage above 99.99995%.
    Both disabled checks pass 167 ranges; the ordinary build remains identical
    and the branch audit passes 145 ranges. Native-loop, world-pool and signed
    interpolation checks pass. `c5-scan-summary.json` and each capture's reports
    retain the measurements. C2–C5 remain open; C6 remains deferred.
  - **Neutral steering follow-up:** after the first steering tail of a frame,
    centered input (native integer steering zero) needs no further tail calls
    if all three angles are normalized. Anchor MPH is still published for every
    engine segment. Non-centered input, out-of-range angles and the next outer
    frame retain normal processing. Engine cadence is unchanged; P3 stays deferred.
    A private consecutive-frame test exposed the need for the angle-range guard:
    native normalization corrects only one turn per call, so an unconditional
    skip would change exceptional-angle behavior. The guarded implementation
    matches the previous frame routine in 3,456 frame comparisons, including
    input changes, braking, reverse/zero motion, partial contact and angular rates.
    The captured executable also passes 297 pristine native eight-field checks
    (135 reverse cases). These tests do not replace C2–C4 acceptance.
  - The latest `c5-neutral-{a,b}-{off,on}` pairs measure G1 **8.405121 /
    6.865535 ms/frame**, exceeding the same limits by **0.335121 / 1.125535 ms**.
    Sweep self cost is 3.018079 / 0.881874 ms/frame. Compared with the preceding
    build, total overhead falls 0.517948 / 0.468967 ms/frame; trajectories still
    differ, so this is not an isolated equal-work measurement.
    G2 off/on FPS is A 3.794/3.794 and B 7.288/5.891 (swaps 38/38 and 73/59).
    Complete-frame means are A 260.956/255.542 and B 137.719/167.508 ms.
    Polygon means are A 57.757/54.919 and B 26.708/27.966, within the specified
    5% mismatch threshold. B's end-to-end regression remains reported.
  - Latest traces each pass 500-field duration and coverage checks (minimum
    99.99996%). Paired artifact/configuration checks, both 167-range disabled
    checks, the 145-range branch audit and ordinary binary identity all pass.
    Reports: `c5-neutral-summary.json`, `c5-neutral-steering-check.json`,
    `c5-neutral-native-frame.json`, plus per-capture reports. C5 remains open.
- **C6, human laps — deferred by the user (2026-10-13).** Full A500 and 68040
  laps remain an unperformed human acceptance check. They do not block the current
  step-4 automated closure; do not describe handling as human-validated.

## 6. Decisions for the user

- **D1:** Accept G1 (cost overhead at equal scene, at most 3.093% of the original frame
  time per window) as the measurable form of the 3% A500 gate, with G2 reported only?
- **D2:** Allow replay records stamped at the frame where an 8-field boundary is crossed
  (R1), instead of records resampled to exact 8-field instants?
- **D3:** If E1 isn't enough, allow the 68000 to latch engine input once per native-length
  phase (E2)?
- **D4:** Still open from earlier work: preserve the native BCD lap clock, defects
  included, or fix it to elapsed time?

On 2026-10-12 the user accepted the recommended defaults. The later G1 exception below supersedes its blocking cost limit:

- **D1, accepted with temporary exception.** G1 remains the cost measure and G2 the
  end-to-end report. On 2026-10-13 the user accepted 5.740 ms/frame in A500 B for
  now and directed work to move on to step 5. Do not pursue the accepted gap as
  a prerequisite or resume deferred P3 merely to close it.
- **D2, R2 first.** Keep the fixed-field format and make it cheaper. If G1 still fails in
  window B after P1–P6 and the recorder is the largest remaining item, switch to R1. R1 is
  allowed for that case without asking again.
- **D3, E1 only.** Use exact memoisation. E2 is allowed only under the same condition: G1
  still fails in window B after P1–P6, and engine runs are the largest remaining item.
- **D4, preserve.** Keep the native BCD lap clock, defects included.

## 7. Working rules for this plan

- P3 remains deferred; P1/P2/P4–P7 are complete, with the recorded exceptions.
  The user has now requested step-4 closure before step 5: complete C1–C5, with
  C6 test laps explicitly deferred. The accepted G1 overhead is settled; deferred
  P3 and C6 are not passes and do not block this automated closure.
  Deferral does not pass an item. Each item ends when its exit numbers and
  checks pass. Commit each item on its own.
- Do not add validation dimensions beyond those listed for the item. Put new questions in
  section 6 instead of blocking on them.
- Run all profiles from one slave with CUSTOM1=0 and CUSTOM1=1, using distinct
  `HD_INSTANCE` values. Rebuild the listing with the slave every time.
