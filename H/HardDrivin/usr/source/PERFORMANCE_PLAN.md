# Hard Drivin' performance plan

The goal is smooth play from the A500 to an AGA 68040/68060 with Fast RAM. Up to
50 FPS is the aim where the hardware allows it. Game speed must be correct at any
frame rate. This plan is meant for an agent to follow step by step. It builds on
`PERFORMANCE.md`, which holds the current measurements, code offsets and evidence
limits. Follow AmigaXDev `docs/playbooks/new-game-playbook-jotd.md`, especially
section 0, together with `fixed-time-simulation.md` and
`simulation-and-presentation.md`.

Addresses are offsets into the SPS 0126 decompressed code (`$11a4e` bytes), the
same numbering as `_pl0_v1`. The second variant (`_pl0_v2`) keeps its original
behaviour until each change is ported and verified separately.

## Current status

Steps 1–3 are complete. See `GAME_TIME.md` for the matched-input coupling test,
clock defects, state/scaling inventory, provisional f0=6.25 (engineering range
4–8), and collision-inclusive 68000 capacity. Step 4 is in progress: gated elapsed-time physics, traffic,
contact and replay playback have partial validation. An experimental CPU-specific
dispatcher now consumes one full interval per 68000 frame and retains bounded
substeps on 68020+. Fixed-field replay recording and long-frame traffic progression now have focused
validation. GAME OVER now uses elapsed time, with A500/68020 pause and duration
checks. Attract route interpolation, scrolling and timeout also have gated
implementations with native-pose comparisons. The separate Phantom challenge
physics loop now has an experimental dispatcher and focused validation. Phantom
ghost recording now has fixed-field sampling and focused native/buffer checks.
Challenge-opponent playback now has elapsed interpolation and crossed finish
checks, including a live opponent finish. Post-race ghost playback now has elapsed
poses, duration and distance-derived pitch, with native-step, pause and slow-frame
checks. Phantom instruction scrolling and its camera transition now also use
elapsed time, with native-step, pause and slow-frame checks. The remaining audio
audit, large-step velocity safety and full acceptance are unfinished. A gated
long-step resistance limiter removes observed braking-induced reversals while
preserving slope rollback; maximum-delay handling remains unproven. The sound
caller inventory, replay skid-request correction and live off-road/skid/partial-contact
cadence checks are in AUDIO_TIMING.md.
See GAME_TIME.md;
the step-4 acceptance criteria remain open.

## Starting point

These starting facts are supplemented and corrected by the step-3 dynamic
checks in `GAME_TIME.md`; use its timing model for implementation.

- **Measured baseline:** the A500 attract window runs at 6.44 FPS, with 6–11 fields
  per frame. The CPU renders planar polygons directly into chip RAM. The VBL handler
  swaps buffers at most once per field, so 50 FPS is the natural ceiling.
- **Frame handshake:**
  - `$00740` spins until the VBL has consumed the previous frame.
  - `$00750` waits the same way, then sets the ready byte (`a4-$69ff`).
  - Every game loop calls `$00740` before drawing the back buffer and `$00750` to
    submit it.
- **Game loop:** the gameplay loop runs from `$10ed4` to `$10f5a`. Each pass calls,
  in order:

  | Code | Role |
  | --- | --- |
  | `$07c32` | Keyboard, gears and per-pass control ramps |
  | `$108a2` | Crash and replay camera |
  | `$0d960` | Camera setup; also writes the replay record (`$089d8`) |
  | `$0d40e` | Traffic route/speed updates |
  | `$0e49a`, `$0b0d6` | Scene preparation and transformation |
  | `$0cda4` | Player physics: `$0b35e`, `$0b662`, `$0b500`, `$0c854`/`$0c94e`/`$0ca14`, `$0baee`, `$0cab6` |
  | `$00740` | Wait for the back buffer |
  | `$0e706`, `$10008` | Background and scene drawing |
  | `$0f894` | Crash overlay |
  | `$1046e`, `$1058e`, `$10238` | Text and overlays |
  | `$0eb22` | Cockpit |
  | `$10020`, `$10b08` | Score drawing and instant replay |
  | `$00750` | Submit the frame |

- **Things that advance once per rendered pass, with no elapsed-time factor:**
  - Physics `$0cda4`. For example, `$0b3a0` turns the steering wheel position into a
    per-call heading change.
  - Control ramps in `$07c32`, such as `a4-$66e4`, which moves by 2 per pass within 0–100.
  - The crash sequence: `a4-$69fa` is set to 25 and loses 1 per pass at `$10f08`.
  - The instant-replay ring: 90 records of 158 bytes from `a4-$4e6e`, written via
    `$0d960`. Playback at `$10bb6` steps one record per pass.
  - The attract route `$0d54c`.
  - The 35-pass GAME OVER loop at `$10f6a`.
- **Things driven by fields:**
  - The lap and countdown BCD clocks (`$02c4c`/`$02c8a`), called from the VBL.
    These are not accurate real-time clocks: the lap adder consumes incoming X
    and the shared divider changes countdown behaviour. See `GAME_TIME.md`.
  - Mouse and joystick input, which the VBL accumulates into absolute positions
    (`a4-$6a06` X, 0–639; `a4-$6a04` Y, 0–399).
- **Consequence:** the existing CUSTOM2 option is a speed limiter. It adds raster-line
  delays to every slave blitter wait because faster machines run the game faster.
  Smooth rendering without decoupling would make a 68040 unplayable.
- **Where the CPU time goes:**
  - Polygon rendering (`$0329a`): 20.2% self, 24.3% inclusive.
  - Vertex rotation (`$02a2e`, using `muls`): 7.9%.
  - Background fill (`$03a28`): 6.9%.
  - Clipping (`$03736`): 6.5%.
  - Edge setup (`$02da2`, which does a `divu` per edge): 4.2%.
  - `$02b74`: 4.1%.
  - Slave blitter wait: 2.7%.
  - The measured A500 workload is dominated by CPU rendering. Memory placement
    and blitter costs must still be measured; this is not a purely CPU-bound claim.

## Lessons carried over from the other projects

- **Find the ceiling first.** Run each fast CPU with an uncapped loop. Indianapolis
  500 and Test Drive II were capped by the chip bus and blitter at 25 FPS, no matter
  how fast the CPU was.
- **Put the rasterizer code in Fast RAM, not just the bitmap.** Powerdrome is the
  closest renderer to this one:

  | Machine | Native | Fast RAM |
  | --- | --- | --- |
  | 68EC020 | 15.7 FPS | 22.2 FPS |
  | 68040/25 | 17.9 FPS | 41.2 FPS |

  The same change made a 68000 with Fast RAM 17% slower, so gate it by CPU.
- **Gate every change by CPU and memory, and measure every machine.** Optimizations
  in Legends of Valour and Red Baron helped one CPU and slowed another. Keep the
  original code wherever a replacement does not measure better.
- **A fixed tick can starve the A500.**
  - Legends of Valour at 25 Hz fell from 3.3 to 1.2 FPS on the A500. Red Baron failed
    its capacity test.
  - Test Drive II's per-CPU tick period worked: the original period on the 68000 and
    a finer one on 68020+. Its rates were divided with fractional carries and
    corrected for coarse-Euler displacement.
- **Their Finest Hour's per-frame T** (fields per frame, with remainder carry) gave
  correct speed from the A500 to a 68030/50, at 50 FPS. This is the chosen design.
  Truncation at large T there was a measurable error (4,649 vs 4,715 units/s), so
  carry 16.16 fractions for positions and turn rates.
- **Interpolation adds latency; extrapolation overshoots.**
  - Interpolating presented poses gives bit-exact simulation but adds one tick of
    latency.
  - Extrapolation removes that latency but overshoots on sudden changes.
  - Indianapolis 500 extrapolated the camera while driving. Its demo-only checks had
    missed that the cockpit camera used a different path.
- **Audit everything a faster loop speeds up.** The Indianapolis 500 replay wipe kept
  its original wait. Here, replay length, crash duration and the GAME OVER timing
  are all counted in passes.
- **CPU fills versus the blitter:** on AGA, 32-bit CPU fills beat the blitter, but
  the blitter wins chip-to-chip copies. Red Baron's D-only sky/ground blits gained
  0.7% on the A500 and 7.5% on a 68030.
- **FS-UAE 68040/68060 timing:**
  - Use the `-NOMMU` CPU types with cycle-exact settings. The MMU core ignores
    frequency and chip timing.
  - Do a separate functional run with the MMU on.
  - Know the cache state behind every 68020/68030 figure.
  - Flush caches after every final executable write.

## Step 1: harness for the full machine matrix and for real gameplay

1. **Prove the rebuild matches the shipped slave.** Build the unmodified source with
   `tmp/dev/tools/build.sh` and compare it with the shipped slave on the attract
   window, comparing state per field, not just screenshots. If they differ, control
   the load address (pad the original to the same size) before attributing anything.
   Record the result in `tmp/dev/docs/internals.md`.
2. **Add a `VERIFY_DRIVE` input tape.** It drives the native menus into a race, then
   replays a fixed input history. Use mouse X/Y positions written to `a4-$6a06`/
   `a4-$6a04` at VBL, plus keys through the `$01212` reader. The tape is indexed by
   field and stays deterministic under any frame rate. Keep it VERIFY-only, as with
   `VERIFY_ATTRACT`.
3. **Define two gameplay windows from the tape:**
   - A straight run to the first checkpoint.
   - A route through the loop or jump plus a crash, so it exercises collisions, the
     crash countdown and the instant replay.
4. **Add a `VERIFY` slowed-drawing switch** (CUSTOM4), for example N extra fields of
   delay in `$00750`. This is the coupling-test instrument.
5. **Generalise `capture_demo.py` and `count_demo_swaps.py`** with named machine
   profiles:
   - A500: 68000, 512K chip and 1.5M slow (the current setup).
   - A500 with 2 MB Fast RAM.
   - A1200: 68EC020 with 4 MB Fast RAM, caches as the slave sets them.
   - A1200 with a 68030/50 and Fast RAM.
   - A4000: 68040-NOMMU at 25 MHz, then 40 MHz.
   - 68060-NOMMU at 50 MHz.

   Use instruction traces on 68000/68020. Use breakpoint swap counting (`SWAP_ONLY`)
   above that, with `SERVE_WAIT` adjusted. Recalibrate the anchor for each memory
   layout. Never compare absolute addresses.
6. **Add a per-field state snapshot.** Take it at VBL entry, plus one at each
   physics-step exit (`$0cda4` return). Cover the car pose (`a4-$6710..`, `a4-$66bc..`),
   velocities, gear and controls, clocks, the replay pointer `a4-$16e2`, the crash
   counter and the RNG. Port Their Finest Hour's generic `compare_state.py`, not
   Test Drive II's.
7. **Port `check_disabled.py`.** It reads `PERF_RANGE` comments from this source and
   checks the original bytes at every gated range against the pristine executable.

Commit: only source changes (VERIFY fixtures, `PERF_RANGE` comments) go to Git.
Tools stay in ignored `tmp/dev/tools`.

## Step 2: baselines

1. **For every machine profile, capture:**
   - The attract window: 1,000 fields, two fresh boots, identical.
   - Both gameplay windows for swap/state measurements. For CPU/DMA profiling,
     use a 500-field (10.016-second) sample within each: A starts at race field 1;
     B starts at field 4300, covering the A500 jump/crash and start of replay.

   Record FPS from swap counts, self and inclusive routine shares, blitter-wait cost,
   DMA slot shares, the `$00740`/`$00750` spin time, and the time spent in `$0cda4`
   alone, in cycles per completed call.
2. **Run the ceiling tests on the fastest profile.** First run as normal. Then run
   with an instant blitter, and with the polygon filler made a no-op (VERIFY only).
   This separates CPU-bound, chip-bus-bound and blitter-bound frames.
3. **Record where everything is placed** for every memory profile: code hunk, globals,
   the edge arrays behind `a4-$69dc`/`a4-$69e0`, the patterns behind `a4-$69e4`, and
   the screens.
4. **Record the existing slave's cache state** (`CACHE` is defined). Note which caches
   are active for each CPU, from the WHDLoad log.
5. **Update `PERFORMANCE.md`** in place with the table (machine → FPS, top routines).

## Step 3: game-time model (complete; no gameplay changes)

1. **Coupling test.** Run gameplay window A with the same tape on the A500, the A500
   with CUSTOM4 delay, the 68020 and the 68040. Compare state per completed physics
   step and per elapsed field. A field-indexed tape delivers different inputs per
   step at different FPS: compare inputs actually consumed before attributing
   divergence to hidden time sources. Use VERIFY_STEPINPUT for the separate
   matched-input control; compare known pointers relative to their hunks.
   Full findings and equality scope are in `GAME_TIME.md`.
2. **Inventory everything that runs once per pass.** Cover the subtree of `$0cda4`,
   `$07c32`, `$108a2`, `$0d40e`, `$10020`, `$10b08`, `$0f894`, the crash and replay
   counters, the GAME OVER and other menu loops, the attract route, the sound triggers
   (`$008ae`/`$007d0`) and the engine pitch. For each, record:
   - Its state and units.
   - Every writer and consumer.
   - Whether it integrates (velocity, acceleration, retention or decay, slew limit,
     derivative) or is a discrete counter.

   Use the table in `simulation-and-presentation.md`. Keep the list in
   `tmp/dev/docs/open-work.md`.
3. **Derive the reference rate f0** at which the original handling is "correct".
   Use independent evidence:
   - The speedometer reading compared with track distance per second of emulated time.
   - The checkpoint time allowances compared with course length at the speeds a
     player reaches.
   - The A500 FPS measured in the gameplay windows.
   - The CUSTOM2 values that existing ReadMe and users recommend for faster machines.

   Report f0 with a confidence range. Step 3 recommends 6.25 native steps/s for
   A500 compatibility, range 4–8 with low confidence in historical intent. World
   scale and defective native clocks prevent a unique physical calibration; do
   not present the recommendation as a recovered author constant.
4. **Measure the cost of a physics step** (`$0cda4` plus `$07c32`) in 68000 cycles,
   in ordinary driving and in collisions. This bounds the cost of substeps on long
   A500 frames.
5. **Design decision (made by the user): scale each step by the actual frame time**,
   in the style of Their Finest Hour. The game keeps one simulation step per rendered
   frame. Each step advances by T = fields elapsed since the previous step × f0 / 50,
   measured in native steps. T = 1 reproduces the original step. Record the units and
   writers inventory from 3.2 with the scaling rule chosen for each entry in
   `open-work.md` before writing code.

## Step 4: frame-time-scaled simulation (gated, CUSTOM1)

1. **Elapsed-time source.** Extend the VBL handler at `$00044` with a slave hook that
   counts fields while the gameplay loop is active. At the start of each pass, take
   the fields consumed since the previous pass and convert them to T in 16.16 fixed
   point, carrying the rounding remainder from frame to frame. Keep the existing BCD
   clocks untouched. Exclude pause, menus and loading so time does not build up there.
2. **Bound T.**
   - Use separate CPU policies. On the 68000, run one elapsed-time-scaled physics
     update per rendered gameplay frame. Consume the full elapsed interval rather
     than dropping time or adding intermediate full scene/physics passes. This
     requires validating T greater than one, widening arithmetic and extending
     decay/event/replay handling beyond the current eight-field limit. Native A500
     frame duration alone does not prove those larger integration steps safe.
   - On 68020 and above, run physics on every gameplay frame and render as fast
     as possible, allowing 50 FPS gameplay. At one PAL field per frame, T=1/8;
     the 6.25 Hz native reference is a scaling unit, not an update-rate cap.
     Start with T_max=1 native step: only when a frame exceeds eight elapsed
     fields, run bounded substeps without drawing between them. Price their full
     cost, including vehicle collision and scene rebuild, and validate contact
     before increasing T_max. Do not wait for a full native step before updating.
   - VERIFY_DISPATCH_CPU selects the experimental separate policies. Initial
     A500/68020 runtime checks pass, but large-step gameplay correctness and
     the full performance acceptance remain unproven.
   - Report substep counts and any discarded time in VERIFY. Do not discard time
     silently.
3. **Scale every integrated quantity by T**, following the table in
   `simulation-and-presentation.md`:
   - Velocity and position increments, and the steering heading change at `$0b3a0`,
     multiply by T.
   - Any explicit acceleration × step² term multiplies by T².
   - Retention or decay factors r per step become r^T. Use a Q16 table or a
     log/exp approximation validated against exact values; scaling the gain linearly
     is only an approximation.
   - Slew limits and control ramps in `$07c32` (such as the ±2 per pass at
     `a4-$66e4`) scale their rate, keeping saturation.
   - Derivatives taken from consecutive samples divide by T.
   - Keep force laws, thresholds and collision magnitudes unscaled. Separate
     collision impulses (unscaled, once per event) from continuous contact forces
     (scaled) and from position correction.
   - Small T at 50 FPS (roughly f0/50 of a native step) can erase word-sized
     increments. Keep wider shadow state or remainders for each scaled accumulator,
     and keep them consistent across every writer, including reset, crash recovery
     and replay.
   - Check the integrator: with Euler updates, many small steps do not give the same
     displacement as one large step. Apply the (T−1)/2·Δv correction where the
     original order requires it, and decide whether the target is the original
     handling or the finer-integrated model.
   - Audit the AI and traffic cars, the RNG, sounds and the engine pitch separately.
     Calling the RNG once per frame changes its sequence per second; decide whether
     that matters for each consumer.
4. **Input.** One step per frame means `$07c32` and the VBL-accumulated mouse positions
   are read once per step, as now. Substeps inside one long frame use the same input.
   Make key-driven events (gear changes, abort, pause) fire once, not once per
   substep.
5. **Convert per-pass counters to elapsed time.** The crash countdown, the GAME OVER
   and other menu passes, the instant-replay ring and its playback, and the attract
   route must keep their original A500 durations in emulated time.
   - Record replay entries with their T (or at a fixed field interval), size the ring
     by duration rather than by 90 frames, and play back by elapsed time,
     interpolating between entries.
   - The attract route's per-pass phase (`$0d54c`, phase /10) advances by T.
6. **Remove the need for CUSTOM2 when CUSTOM1 is on.** Leave CUSTOM2 working, and
   unchanged, when CUSTOM1 is off.
7. **Validate.**
   - VERIFY forcing T = 1 every pass must give bit-identical per-step state to the
     original on the driving tape. This proves the scaling code changes nothing at
     the native step.
   - Compare equal elapsed fields across the A500, CUSTOM4-slowed drawing, the 68020
     and the 68040: car position, speed and heading must agree within a tolerance
     derived from the units audit, and lap and checkpoint times within one frame.
   - Measure distance per second at constant throttle on the straight, and braking
     distance from a fixed speed, on every machine.
     Speed-triggered flat braking is now measured on all seven profiles plus
     slowed A500 drawing. The zero-throttle speed100 comparison retains sampling
     bounds; it does not yet establish the acceptance tolerance or higher-speed
     agreement. The near-stop backward-displacement defect has a gated correction
     with final A500/020 operand-level validation; full handling and final-build
     machine coverage remain open. See GAME_TIME.md.
     Constant-throttle straight motion is measured on all seven profiles and
     slowed A500 drawing. The slowed run overshoots the requested throttle by one;
     it is not an equal-input comparison. The same-throttle A500/fast-CPU speed
     difference is traced to gear-transition overshoot and a native zero-net-force
     interval. Its correction and units-derived handling tolerance remain open.
   - Exercise collisions, the loop and the jump at both T extremes; check for
     tunnelling and missed checkpoints.
   - Measure the A500's FPS: it must not drop by more than 3% against the baseline.
   - `check_disabled.py` passes with CUSTOM1 off.
   - A person drives a full lap on the A500 and on the 68040 profile and confirms the
     handling feels the same.

## Step 5: rendering performance

Order the candidates by measured share on each machine. Skip anything worth under 3%
of a frame unless it is free. Bound each candidate's cost by summing instruction
cycles before writing it. Every replacement needs:

- A Python model of the original, checked against the original's own calls.
- A VERIFY pixel twin of the replaced inner loop, run into a guarded shadow bitmap and
  comparing all planes and the surviving registers and flags.
- A CPU gate.
- A `PERF_RANGE`.

1. **Memory placement (68020+ with Fast RAM).**
   - Confirm the code hunk, globals and vertex arrays land in Fast RAM.
   - Force CPU-only working buffers into Fast RAM with an AllocMem filter, as in Their
     Finest Hour: the edge arrays behind `a4-$69dc`/`a4-$69e0` and the patterns behind
     `a4-$69e4`.
   - Keep screens, sprites and anything the blitter reads in chip RAM.
   - Measure on the A500 with Fast RAM separately. Powerdrome lost 17% there.
2. **Caches and self-modifying code.**
   - Audit every code write, including the `_smc_gfx1`/`_smc_txt1` replacements and the
     dbf-delay stubs at `$1000+`.
   - Ensure `resload_FlushCache` follows every final write.
   - Verify on an MMU-enabled 68040 functional run.
   - Measure FPS with the slave's `CACHE` setting, and with `DCACHE` where that is
     allowed.
3. **Polygon span filler `$0329a` with edge setup `$02da2`.**
   - Rewrite the span writer as asm in the style of Powerdrome and Indianapolis 500:
     straight-line scanline loops, long stores on aligned interiors, and per-colour
     plane routines that skip planes whose bit is constant.
   - Replace the per-edge `divu` with a reciprocal table on the 68000, and with
     `divs.l`/`divu.l` on 68020+ wherever the bits match.
   - Keep the patterned-fill path exact.
4. **Vertex rotation `$02a2e`/`$02a7a` and `$02b74`/`$02bde`.** Write 68000 register-
   resident versions. On 68020+, use `muls.l` and drop the paired 16×16 work only where
   the results are bit-identical, as Their Finest Hour does.
5. **Clipping and bounds `$03736`** (30.8% inclusive): an early trivial-accept and
   reject path, verified against the model.
6. **Background fill `$03a28`.**
   - On OCS/ECS, try an asynchronous D-only blitter fill of the sky/ground bands while
     the CPU transforms the scene, with a barrier at the first CPU write.
   - On AGA, try 32-bit CPU stores.
   - Keep whichever measures better on each machine.
7. **Blitter waits.** Replace the slave's `_blitwait` polling with a tight
   `btst #14,dmaconr` wait when CUSTOM2 is zero. Check for blits the game waits on
   needlessly, especially the cockpit and text blits in `$0eb22` and `$01566`.
8. **Cockpit and overlays (`$0eb22`, `$0e49a`).** Redraw static cockpit parts only
   when they change, if the double buffering allows it. Track a dirty flag per buffer.
9. **After each optimization:**
   - Run an A/B with the same build, option off against option on, on every machine
     profile, in the attract and gameplay windows.
   - Judge routine changes by cycles per completed call, and FPS by swap counts.
   - With step 4 in place, game speed no longer depends on FPS, so the windows cover
     the same scene on every machine; recheck this before trusting a comparison.

## Step 6: release integration

1. **Options (WHDLoad 17+, approved by the user):** raise `WHDL_REQVER` and
   `slv_Version` to 17 and add an `slv_config` with CUSTOM1 (frame-time-scaled
   simulation and the performance patches, on by default once validated) and
   CUSTOM2 (the existing speed delay, unchanged). Keep developer switches unlisted.
   Update the ReadMe requirement in the same commit, and test on WHDLoad 17 and 20.
2. **Choose code paths at patch time** from `WHDLTAG_ATTNFLAGS_GET` and the Fast RAM
   placement. The A500 runs only the variants measured as faster there.
3. **Final matrix:**
   - Rerun every machine profile.
   - Rerun the MMU functional run on the 68040.
   - Rerun `check_disabled.py`.
   - Run the gameplay tapes, including crash, replay, GAME OVER and high-score entry.
   - Have a person play a full run on the A500 and on the 68040 profile.
4. **Update `PERFORMANCE.md`** (current numbers and design) and the ReadMe options in
   place.

## Commits

Make one commit per coherent step, staging explicit paths under `H/HardDrivin/`.
Follow `AGENTS.md`:

- Author and committer: Vesa Halttunen.
- No signing, no hooks, no attribution trailers.
- Check identities first.

Never commit game bytes, traces, dumps, screenshots, built slaves or tools from
`tmp/`. Make no performance claim without a measurement from the matching instrument.

## Expected outcome (targets, not measurements)

| Machine | Target |
| --- | --- |
| A500 | Correct speed; 10–30% more FPS from the renderer work |
| A1200/020 with Fast RAM | 15–25 FPS |
| 68030/50 | About 25–40 FPS |
| 68040/68060 with Fast RAM | 40–50 FPS, unless the ceiling run in step 2 shows a chip-bus limit |

Step 2 measures native, frame-coupled attract rates of 6.44/6.54 FPS on the
two A500 profiles, 24.16 on the 020, 38.49 on the 030, and 33.95–34.79 on the
040/060 profiles. The matched 030 ceiling reaches 49.87 FPS with polygons omitted.
These are references for the remaining work, not proof that the correct-speed
targets above are achieved. See PERFORMANCE.md for gameplay rates, changed-route
limits and unavailable fast-core instruction/blitter-slot measurements.
