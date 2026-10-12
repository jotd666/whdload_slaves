# Step 4 cost profile and closure plan

This plan finishes step 4 of `PERFORMANCE_PLAN.md`. It starts from a fresh profile of the
current integrated build, measured on 2026-10-12. It names the bottlenecks, sets numeric
targets and gives an ordered list of work items. Each item has an exit criterion. Step IDs
are `P` (performance), `C` (closure) and `D` (decisions for the user).

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

### P1 Traffic hooks: target ≤ 0.8 ms per frame (now 6.36 / 5.49)

1. **Slot lookup without multiply or divide.**
   - Lay out the companion table with the native 46-byte stride, so that
     slot = companion + (A0 − table). Alternatively, keep 16-byte slots and use an
     index table built once at allocation.
   - Keep the bounds and alignment rejection.
   - Expected: 1.62 → under 0.1 ms.
2. **Cache the terminal speed.**
   - Store ceil(target/accel)·accel·8 in the slot when it is initialised.
   - Also store the source bytes `21(a0)`/`22(a0)`, and recompute only if they change
     (two `cmp.b`).
   - This removes the `divu`/`mulu` from every `_traffic_speed_step` call.
3. **Steady-speed fast path.**
   - When the speed word is already at the cached terminal (or both speeds are equal) and
     no reversal residue is pending, the wide phase numerator reduces to a closed form:
     12·n·v8 + carry over 768.
   - Compute 12·n once per frame. Replace the `divu #768` with an exact reciprocal
     multiply or shift form, and check it exhaustively. The domain is
     v8 ∈ [−168, 168], n ∈ 1..255 and carry ∈ [−767, 767].
   - Its route-walk result must equal the wide path's.
   - The wide path stays for acceleration, deceleration and reversal frames only.
4. **Lighter wrappers.**
   - Save only the registers each path actually uses.
   - Read `_time_scalar_fields` once per frame into the per-frame block (see P4.1).
   - Skip the speed step outright when the speed is at terminal.
5. **Exit criteria.**
   - The traffic phase is at most 0.8 ms per frame above the original in both windows.
   - `check_traffic.py`, `check_traffic_math.py` and the 1440-record native comparison
     still pass.

### P2 Replay recording: target ≤ 0.3 ms per frame (now 3.89 / 2.90)

The recommended option, R1, needs decision D2.

1. **R1, stamped records.**
   - When a frame crosses one or more 8-field boundaries, write the native 158-byte
     record once, as the native `$89d8` copy does.
   - Store its elapsed-field stamp in a parallel 90-entry word array. Gameplay does no
     interpolation.
   - Playback interpolates between stamped neighbours by elapsed time, reusing the
     existing playback interpolation.
   - The ring still holds 90 records spaced at least 8 fields apart, so it covers at
     least the original 720 fields.
   - Collision replacement rewrites the current stamp.
2. **R2, fallback if D2 rejects R1.**
   - Keep the fixed-field format.
   - Compute the weight pair once per emitted record.
   - Interpolate only the pose and angle words, which need a table of word classes.
   - Sample and hold discrete words.
   - Expected: about 1.2 ms per frame, which does not by itself meet the B budget.
3. **Exit criteria.**
   - The record share of `$0d960` is at most 0.3 ms per frame above the original.
   - Replay playback passes `check_replay_playback.py` and `check_recording.py`, adapted
     to stamps.
   - One A500 and one 68020 crash replay are inspected visually.

### P3 Native engine runs: target ≤ phases started + 0.1 per frame (now 2.53 / 2.36)

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

### P5 Remaining hooks: target ≤ 0.3 ms per frame (now 0.42 / 0.48)

Fold the field-count read in `hook10ed4`, the controls latch and the dispatcher's
begin/take/after work into the per-frame block. No deeper change is expected.

### Budget after P1–P5 (ms per frame)

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

- Work in the order P1 → P5, then C1 → C6. Each item ends when its exit numbers and
  checks pass. Commit each item on its own.
- Do not add validation dimensions beyond those listed for the item. Put new questions in
  section 6 instead of blocking on them.
- Run all profiles from one slave with CUSTOM1=0 and CUSTOM1=1, using distinct
  `HD_INSTANCE` values. Rebuild the listing with the slave every time.
