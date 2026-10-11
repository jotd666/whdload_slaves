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

## Starting point

These facts come from static analysis of the code. The dynamic checks in step 3
must confirm them before any design relies on them.

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
  | `$0d40e` | Not yet identified |
  | `$0e49a`, `$0b0d6` | Scene preparation and transformation |
  | `$0cda4` | Player physics: `$0b35e`, `$0b662`, `$0b500`, `$0c854`/`$0c94e`/`$0ca14`, `$0baee`, `$0cab6` |
  | `$00740` | Wait for the back buffer |
  | `$0e706`, `$10008` | Background and scene drawing |
  | `$0f894` | Crash overlay |
  | `$1046e`, `$1058e`, `$10238` | Text and overlays |
  | `$0eb22` | Cockpit |
  | `$10020`, `$10b08` | Late per-pass work |
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
- **Things that run in real time:**
  - The lap and countdown BCD clocks (`$02c4c`/`$02c8a`), called from the VBL.
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
  - On the A500, slow RAM shares the chip bus, so this machine is purely CPU-bound.

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
  correct speed from the A500 to a 68030/50, at 50 FPS.
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
   - Both gameplay windows.

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

## Step 3: game-time model (no gameplay changes yet)

1. **Coupling test.** Run gameplay window A with the same tape on the A500, the A500
   with CUSTOM4 delay, the 68020 and the 68040. Compare state per completed physics
   step and per elapsed field. Expect identical per-step state, with game speed
   proportional to FPS. Any divergence per step shows a hidden time source; find it.
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

   Report f0 with a confidence range.
4. **Measure the cost of a physics step** (`$0cda4` plus `$07c32`) in 68000 cycles,
   in ordinary driving and in collisions. This sets the A500 catch-up budget.
5. **Decision gate: ask the user.** Present the options with measured costs:
   - **A. Native step at a fixed period** P0 = 50/f0 fields on every CPU. Interpolate
     or extrapolate the camera pose in `$0d960` for presentation. This keeps handling
     bit-exact. Input is sampled at f0, with latency of up to one tick.
   - **B. Per-CPU period, Test Drive II style.**
     - The 68000 uses P0.
     - 68020+ uses P0/N substeps, with every integrated rate scaled by 1/N using
       fractional carries.
     - Coarse-Euler displacement is corrected, and decays use N-th roots.
     - Discrete counters keep their original cadence.
     - Handling is finer on fast machines, but a validated units audit is required.
   - **C. Per-frame T, Their Finest Hour style.** The native step scales by the
     fields elapsed. This is the most invasive to physics, and collisions get harder.

   The recommended default is A as the first deliverable, then B for 68020+ once A
   validates. A gives correct speed everywhere at low risk; B removes most of the
   latency on fast machines. Record the choice in `open-work.md`.

## Step 4: fixed-time simulation (gated, CUSTOM1)

Implement the chosen design. The steps below are for A; B extends 4.3 and 4.4.

1. **Field accumulator.** The VBL handler at `$00044` already runs each field; extend
   it with a slave hook that counts pending fields while the gameplay loop is active.
   Keep the existing BCD clocks untouched.
2. **Split the gameplay loop at `$10ed4`.**
   - Run the simulation block (`$07c32`, `$108a2`, `$0cda4`, the replay record, the
     crash counter) once per P0 consumed fields.
   - Then render once (`$0d960` camera, `$0e49a`/`$0b0d6`/`$0e706`/`$10008`/overlays/
     cockpit, `$00750`).
   - Run catch-up ticks without drawing. Cap the backlog and expose an overrun counter
     in VERIFY.
   - Change only whole instructions. Use `PL_P` where the replacement re-executes the
     original body, and audit every hook boundary.
3. **Input per tick.** `$07c32` reads keys through `$01212`. The VBL accumulates mouse
   positions. Snapshot the mouse/joystick absolute positions and the key events per
   field, and give each catch-up tick the input from its own field range. Do not
   re-read live input. Test gear keys, pause, quit and the menu paths.
4. **Presentation.** Snapshot the car pose at the physics exit. In `$0d960`, write only
   the camera copies, using α = pending fields / P0:
   - Interpolate in replay and attract.
   - Extrapolate while driving.
   - Wrap angles at 1440 units (720 is the half turn) by the shortest arc.
   - Snap on crash, reset and replay start.

   Keep authoritative state untouched.
5. **Other per-pass consumers.**
   - Convert the crash countdown, the GAME OVER/menu passes, the replay length and its
     playback rate, and the attract route to ticks or fields. Each must keep its
     original A500 duration in emulated time.
   - Record replay per tick and play it back per tick, with interpolated presentation.
6. **Remove the need for CUSTOM2 when CUSTOM1 is on.** Leave CUSTOM2 working, and
   unchanged, when CUSTOM1 is off.
7. **Validate.**
   - The tape gives identical per-tick state at A500 speed, at CUSTOM4-slowed speed and
     on the 68040 (matched completed ticks).
   - Report elapsed-field accounting for the same windows.
   - Lap times on the same tape agree across machines within one tick.
   - The A500's FPS does not drop by more than 3% against the baseline.
   - `check_disabled.py` passes with CUSTOM1 off.

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
   - Where the scene differs, use the scene-stable window, which is valid once step 4
     is in place.

## Step 6: release integration

1. **Options:** CUSTOM1 for fixed-time simulation and the performance patches, on by
   default once validated. CUSTOM2 stays as it was. Add `slv_config` only if the user
   accepts WHDLoad 17+, raising `slv_Version` and the ReadMe requirement together.
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

Revise these after step 2.
