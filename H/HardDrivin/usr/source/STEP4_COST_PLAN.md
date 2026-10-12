# Step 4 cost profile and closure plan

This plan finishes step 4 of `PERFORMANCE_PLAN.md`. It starts from a fresh profile of the
current integrated build, measured on 2026-10-12. It names the bottlenecks, sets numeric
targets and gives an ordered list of work items. Each item has an exit criterion. Step IDs
are `P` (performance), `C` (closure) and `D` (decisions for the user).

**Current status: P1 and P2 complete; P3 deferred; P4 in progress.** Traffic meets its 0.8 ms/frame budget.
Replay-recording overhead is now 0.281 ms/frame in A and 0.249 ms/frame in B,
both below 0.3 ms. P3 E1 has been evaluated and fails its entry-rate limits; its
candidate is retained only in the ignored harness. The P4 helper checkpoint below
reduces costs to 1.995 / 2.415 ms per frame, still above 1.4 in both windows.
P3's unmet limits, P4, the combined G1 gate and step-4 closure remain open.
The runtime contains P2 plus the verified P4 helper reductions.

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

### P4 Slave physics helpers: target ≤ 1.4 ms per frame (now ≈3.9 / ≈3.7)

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
   - Slave physics symbols total at most 1.4 ms per frame in both windows.
   - The game-code part of physics is at most 1.0 ms per frame above the original after
     P3.

#### P4 checkpoint: exact helper reductions, budget still failing

The 2026-10-12 checkpoint uses `p4-check-a.slave` / `p4-check-b.slave`
with matched `p4-check-{a,b}-{off,on}` ten-second captures. Every capture
retains its actual slave and listing. The exact physics-owner totals include
small symbols omitted from the analyzer's display table.

| Metric, ms per complete frame | A | B |
|---|---:|---:|
| Slave physics, accepted P2 | 3.812752 | 3.405057 |
| Slave physics, P4 checkpoint | **1.995237** | **2.415216** |
| P4 limit | 1.400000 | 1.400000 |
| Remaining excess | **0.595237** | **1.015216** |
| Native physics, matched original | 9.703325 | 6.380050 |
| Native physics, P4 checkpoint | 11.547031 | 8.032314 |
| Native excess (P3-dependent limit: 1.0) | 1.843705 | 1.652265 |

Both P4 numeric conditions remain unmet; deferring P3 does not waive either
limit. The new per-frame constant preparation costs another 0.046290 / 0.038951
ms outside the physics bucket and must count toward G1. No original-game FPS
acceptance is claimed; B still follows a different scene from CUSTOM1-off.

Implemented changes:

- A keyed per-frame block stores n, 8+n, 8-n, Q16 T and the existing rounded
  retention/contact coefficients. Decay/contact hooks reuse coefficients only
  for an exactly matching interval; native n8 and partial phase segments retain
  their own coefficients. Simple small additions remain local where a guarded
  memory lookup would cost more.
- Exact zero/native-step shortcuts, bounded angle normalization with the full
  long fallback, bounded throttle-ramp arithmetic and cheaper signed Q16 splits.
  Grounded zero fall/drift and zero movement axes skip arithmetic while retaining
  companion state. Range assumptions are documented alongside each shortcut.
- Phase interpolation uses bounded addition chains and does not calculate an
  unused RPM forecast. Position scaling uses exact small-integer shift/add forms.
  Native RPM/gear conversion results are reused with a complete key, and later
  segments reuse globals already published by the preceding native tail.
- Projection retains native word rounding, uses exact flat/cardinal paths and
  cheaper extraction of the consumed product bits. Publication reuses the integer
  vector already produced by native B500 and projects only its neighbor when
  needed. Prologues preserve only the registers used by their helpers; the power
  wrapper keeps one save across two audited native `$2950` calls.

Unchanged yaw/pitch alone is **not** a valid projection reuse key: the native
`v + floor(v/2)` step and subsequent word-rounded products also depend on velocity.
For example, velocities 1 and 2 produce magnitudes 1 and 3 with identical angles.
The checkpoint therefore removes duplicate work without substituting one segment's
vector for another velocity. P3 engine evaluation and physics cadence are unchanged.

Verification of this checkpoint:

- 162,003 actual-68000 old/new helper cases, including signed extremes, projection
  edge paths, companion state, full register preservation where required, native
  power calls, and valid phase invariants.
- All 65,536 field intervals plus the initial sentinel: 65,537 constant blocks,
  196,611 cached coefficients, 196,608 equal/different-key table results and 306
  contact responses. Native oracle checks cover 128 endpoints / 1,440 partitions.
- Live pristine-engine oracles: motion 17, braking 46, steering 9, off-road 29;
  skid prefixes 43 returns on A500 and 189 on 020. Skid checks stop at the first
  unsupported airborne input (fields 515 / 575); they do not validate full flight.
- 108 native-step car states match. CUSTOM1-off passes all 163 ranges; branch
  entry audit passes 141 ranges. Normal, DRIVE and ATTRACT slaves are byte-identical
  to their step-2 baselines. All builds, captures and private checkers stay ignored.

The remaining work is the P4 cost gap, not a missing acceptance label. Further
changes must retain the same exact recurrence, input tape and native side effects;
P3 remains deferred and neither a looser budget nor a lower physics cadence is used.

### P5 Remaining hooks: target ≤ 0.3 ms per frame (now 0.42 / 0.48)

Fold the field-count read in `hook10ed4`, the controls latch and the dispatcher's
begin/take/after work into the per-frame block. No deeper change is expected.

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

### P7 68020 check

After P1–P5, profile the same build on `a1200-020` in both windows, using swap counts plus
an instruction trace where the backend supports it. Report the overhead per frame against
its own original frame time. The 68020 runs physics every frame, so per-frame overhead
matters for the 50 FPS goal in step 5. This is reported, not gated.

## 5. Closure of step 4

Do these after G1 passes. They are the remaining acceptance items of `PERFORMANCE_PLAN.md`
step 4.7, made concrete.

- **C1, solver coverage.**
  - Extend the phase path to airborne flight and landing, then manual gears. This
    continues the work after `d94d739`.
  - After this, only crash, recovery and replay may fall back to the reference solver.
  - Count the fallback frames per window and report them. The target is under 2% of
    driving frames.
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
- **C4, extreme T.**
  - Run collisions, the loop and the jump on the slowed A500 (largest T) and on the
    68060 (smallest T).
  - There must be no tunnelling and no missed checkpoint. The sweep counters must show
    any long-frame crossing.
- **C5, gates.** G1 passes in both windows; G2 is reported; `check_disabled.py` passes; the
  normal build is byte-identical.
- **C6, human laps.** A person drives a full lap on the A500 and one on the 68040 profile,
  and confirms the handling. This step belongs to the user.

## 6. Decisions for the user

- **D1:** Accept G1 (cost overhead at equal scene, at most 3.093% of the original frame
  time per window) as the measurable form of the 3% A500 gate, with G2 reported only?
- **D2:** Allow replay records stamped at the frame where an 8-field boundary is crossed
  (R1), instead of records resampled to exact 8-field instants?
- **D3:** If E1 isn't enough, allow the 68000 to latch engine input once per native-length
  phase (E2)?
- **D4:** Still open from earlier work: preserve the native BCD lap clock, defects
  included, or fix it to elapsed time?

On 2026-10-12 the user accepted the recommended defaults. These decisions are now fixed:

- **D1, accepted.** G1 is the pass/fail form of the 3% A500 gate. G2 is reported only.
- **D2, R2 first.** Keep the fixed-field format and make it cheaper. If G1 still fails in
  window B after P1–P6 and the recorder is the largest remaining item, switch to R1. R1 is
  allowed for that case without asking again.
- **D3, E1 only.** Use exact memoisation. E2 is allowed only under the same condition: G1
  still fails in window B after P1–P6, and engine runs are the largest remaining item.
- **D4, preserve.** Keep the native BCD lap clock, defects included.

## 7. Working rules for this plan

- Work in the order P1 → P5, then C1 → C6, with P3 deferred by the user and P4 next.
  Deferral does not pass an item. Each item ends when its exit numbers and
  checks pass. Commit each item on its own.
- Do not add validation dimensions beyond those listed for the item. Put new questions in
  section 6 instead of blocking on them.
- Run all profiles from one slave with CUSTOM1=0 and CUSTOM1=1, using distinct
  `HD_INSTANCE` values. Rebuild the listing with the slave every time.
