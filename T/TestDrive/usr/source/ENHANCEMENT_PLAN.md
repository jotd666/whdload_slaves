# Test Drive: enhancement plan

Goal: bring Test Drive (1987, Distinctive Software / Accolade) to parity with the Test Drive
II slave in this repository (`T/TestDrive2/usr/source`):

- an always-on fix that flushes the caches after the overlay manager rewrites its stubs;
- an optional "Enhanced framerate" option (`CUSTOM2`). Game time runs on a fixed simulation
  period, independently of drawing (25 Hz on a 68020 or better). It retains blitter
  priority, suppresses unused blitter interrupts and draws the road and cars at
  fractional positions;
- the original crash screens, acknowledgement and penalties kept in enhanced mode, as in
  Test Drive II after PR #24. A field-timed recovery exists only as a VERIFY instrument;
- fixes for any original display bugs found along the way (Test Drive II's intro DDFSTOP
  fix is the model);
- `CUSTOM2=0` preserves original gameplay, apart from documented always-on fixes.

The method is AmigaXDev `docs/playbooks/new-game-playbook-jotd.md`. Its §12 "ready to improve"
gate comes before gameplay enhancements; VERIFY-only measurement fixtures establish that gate. Generic lessons go back to AmigaXDev `docs/`.

## What carries over from Test Drive II, and what does not

Test Drive II is a later product from the same studio, and the two executables share their
design. Both are Aztec C `HUNK_OVERLAY` executables run on KickEmu Kickstart 1.3. Both have a
created `Road Drawer` task and `Ticks VBLInt` / `Sfx VBLInt` interrupt servers. Code is
`link a5` / a4-relative.

| | Test Drive (`data/TD`) | Test Drive II (`data/duel` v1) |
|---|---|---|
| File size | 90 112 (one version, JOTD's decrypted executable) | 108 868 |
| Root code hunk | `$7C0C` | `$1156C` |
| Data hunk, file / allocated | `$1E94` / `$32A4` | `$3A38` / `$7A70` |
| Hunk-0 offset → file offset | + `$28` | + `$28` |

A byte match over 12-byte windows found about 3.8 KB of the 31.7 KB root hunk identical to
`duel`: the Aztec runtime, the overlay manager and some library glue. **The overlay stub
rewrites are byte-identical**: the unload rewrite is at `TD:0637E` (duel `0FE7E`) and the load
rewrite at `TD:06908` (duel `0FF0C`). Their exits, confirmed in memory, are `TD:06390`
(`movem.l (a7)+,a2-a3/a6; rts`) and `TD:06916` (`movem.l (a7)+,d0-d2/a0-a4; rts`), the same
instructions TD2's fix displaces at duel `0FE90` / `0FF1A`. The game engine does not byte-match: a4 offsets, the RNG and the
physics differ. Engine knowledge carries over **by structure** (which routine, which task,
which kind of variable), and every offset must be found again. Reuse the method, the tools
and the generic assembly; never reuse a `duel` offset without proving it in `TD`.

Known differences that change the design:

- No opponent car: you race the clock against traffic and the police radar, with gas-station
  stages, a score and a high-score table. TD2's opponent and demo-AI work becomes
  traffic/police/score work.
- Five selectable cars, each with its own data under `data/Cars`: the handling validation has
  to cover all of them, not one.
- The score and the high-score table depend on time and average speed. Clock fixes therefore
  change scores; the high-score file is written into the disposable `DH1:`.
- The slave gives only `$20000` of fast memory (`FASTMEMSIZE`). Private slave memory for caches
  (TD2's tangent cache is 4 KiB) must fit the slave or the existing memory sizes.
- NTSC stays open, as in TD2: validate PAL only and document the NTSC behaviour.
- Phase 5 confirms that drawing speed affects clutch release, collision geometry and later
  RNG consumption despite the five-field main loop. Phase 8 must remove these dependencies.
- Normal builds expose Enhanced framerate through CUSTOM2. VERIFY CUSTOM3 fixes the
  profiling window RNG; the root:$7AAA LoadView call is the validated frame marker.
- Source to copy from: the fork's `T/TestDrive2/usr/source` (it includes PR #24 and #25),
  not the standalone Test Drive 2 repository's `whdload/`. Diff the two before copying a
  routine.

Release numbering: all work after JOTD 1.4 belongs to **2.0b (13.10.2026)**.
References below to 1.5b–1.8b identify retained, unpublished development test
snapshots only; they are not separate releases. Their evidence and the deferred
hardware A/B binaries remain unchanged.

## Phase 1: local harness (complete; in `tmp/dev/`, never committed)

1. Runner/debug server: disposable per-launch game copy, worktree-owned emulator and
   debugger, shared environment defaults, pinned runtime inputs checked before use.
   `TD_SETUP=a500|a1200|a1200-030` reproduces TD2's reference settings (512 KiB chip +
   1536 KiB slow; expanded A1200 with 4 MiB fast; 68030/25 MHz). Shared `AMIGA_SETUP`
   presets remain available. Effective launch options are recorded before boot; buffered
   emulator logs are not used to guess RAM sizes at an early breakpoint.
2. Profiler: the installed FS-UAE hash and both setup writes/capture-command reads for
   its PC window are pinned and checked. A short A500 trace contains real instruction PCs.
3. Build: `tools/build.sh` checks the selected compiler/include trees and builds the
   authoritative source into `tmp/build/`; `VERIFY=1` selects the VERIFY output.
   The phase-1 normal variant is retained byte-identical to the 1.5b hardware handoff.
   Current 2.0b builds add phase-10 rendering to the phase-8 simulation and phase-9 optimization; historical
   VERIFY fixtures remain pinned with their captures. Bash wrappers work with macOS Bash 3.2.
4. Trace tools: `td_report.py` uses TD's root/data sizes, excludes the PRELOAD root copy
   and follows the loaded BPTR chain. `profile_demo.sh`, `ingame.py`, `frames.py`,
   `swap_fields.py` and `fixed_window.sh` are adapted. Captures retain the exact slave,
   launch settings, RAM and evidence. Fixed captures reject a moved anchor. Phase 4
   supplies the validated first-attract-race anchor, LoadView frame marker and
   overlay-aware reports. Explicit root anchors remain available for diagnostics.
   No TD2 game addresses are silently reused.
5. State tools: `state_fields.py`, `state_writers.py`, `state_report.py`, `state_watch.py`
   and `task_state.py` work on TD captures. The field sampler uses Ticks VBLInt at
   TD:$018BA and checks consecutive counters and a4/a1 against the data hunk. Task
   parsing finds Initial CLI and Road Drawer in a real dump. Writer attribution and
   a live watchpoint corroborate the VBL store.
6. Comparison: `compare_state.py` has a TD-only seven-variable seed map plus full data
   comparison. Two fresh A500 boots at the same VBL window match byte-for-byte across
   all $32A4 data bytes; a different scene differs. Negative controls detect a changed
   non-clock selector and a missing sample. **The full physics/score state map is
   documented in phase 5**, so this seed sampler is harness validation,
   not proof of gameplay determinism.
7. Later-phase `check_*`, simulation audits, sub-unit/sideways tools and the full release
   packager remain deliberately deferred until their features exist. The phase-1
   acceptance checker is `tools/check_harness.py`; the phase-6.1 A/B bundle is preserved.
8. Current local references: `docs/development.md`, `docs/testing.md`,
   `docs/internals.md` and `docs/open-work.md`. Commands and evidence are documented
   there; acceptance artifacts are under ignored `tmp/dev/tmp/phase1/`.

**Acceptance:** the shipped 1.3 and rebuilt 1.5b slaves boot through startup into the
A500 attract/driving sequence from copies of the same pristine drawer. Normal/VERIFY
builds pass, input hashes remain unchanged, and the delivered phase-6.1 fixed slave is
unchanged. The available public archives contain 1.3, not 1.4; the user accepted an
unmodified repository-1.4 rebuild for the separate A/B baseline. No unavailable
shipped-1.4 byte-equivalence claim is made. Phases 3 and 4 supply gameplay and
measurement validation; the phase-5 time model below now defines the simulation design.

## Phase 2: identify the game (complete)

1. Local `docs/internals.md` inventories the slave configuration, all 11 normal patch sites
   plus five VERIFY-only sites, keyboard interrupt and Exec trackdisk hooks. Original instructions,
   replacement behavior and unresolved observations are recorded.
2. Parsed all five hunks and both overlay nodes. The suffix from HUNK_OVERLAY at
   file `$9F2C` is 49,364 bytes including metadata; actual overlay code is 49,220
   bytes. Node 1 exports three entries from hunk 3; node 2 exports twenty from
   hunk 4. The data base is obtained through the loaded root's BPTR chain, and
   a4 is data-base + `$7FFE`.
3. Root and both overlays are disassembled. Confirmed: VBL servers, Road Drawer
   creation in hunk 4, WaitTOF, beam-mixed RNG, overlay manager, road traversal,
   horizontal blitter spans and five-plane shape blitter. Overlay addresses are
   hunk-qualified; 107 data JMP stubs resolve their calls into the root.
4. The presentation marker is validated in phase 4. Phase 10 maps TD's streamed
   16.16 road walker; TD2's 52-byte-row/8.8 representation does not apply.
   Some secondary renderer and CPU-span counterparts remain not found.
   Phase 3 visually confirms a rear-view mirror; phase 10 maps both views.
   Timing/state ownership is mapped in phase 5.

**Acceptance:** local `tools/identify_game.py` checks pinned inputs, all explicit
patch signatures/source coverage, hunk sizes, root JMP targets and both overlay
node/export lists. Evidence is under ignored `tmp/dev/tmp/phase2/`. Every requested
routine family has an evidenced TD location or an explicit not-found entry in
the local inventory. Performance measurements are recorded separately in phase 4.

## Phase 3: first boot and traces with PCs (complete)

1. Windowed real-speed PAL A500 boot, using rebuilt 1.5b and the disposable game
   drawer. All five cars were selected and driven through native keyboard events.
   Acceleration, shifting and steering were observed; read-only state corroborates
   the screenshots. Porsche wall-crash acknowledgement restores the intact cockpit.
2. A Ferrari first-stage route reached a radar pursuit, braking to zero speed,
   the speeding-ticket screen and return to driving. It then reached Don's
   Gas-O-Rama; fire continued to stage 2. No persistent visual defect was observed
   in the inspected startup, car/cockpit, crash/recovery, ticket or station screens.
   Partial draws and the station's scrolling text were checked against settled views.
3. `td.py serve` attached at reset within the stub's 20-second window. Startup and
   driving traces contain instruction PCs. The native-input diagnostic build's
   three-field driving trace contains 8,939 / 9,456 / 9,154 instruction PCs.
4. Leaving the game untouched repeats car introductions, a driving demo and the
   logo sequence. The local demo-capture wrapper documents that diagnostic route.
   A bounded native-keyboard helper also logs player routes, reading telemetry
   without writing game state. No host accessibility or window input is used.

**Acceptance:** local `docs/phase3.md` identifies the screenshots, state captures,
input logs, exact slave/configuration and pinned diagnostic emulator. Pristine
inputs and the phase-6.1 slave remain unchanged. The cockpit includes a working
rear-view mirror; attribution of the two renderer passes remains analysis work.
These are gameplay/trace checks, not a deterministic FPS benchmark. The frame
marker and fixed race window are validated in phase 4; the timing model is established in phase 5.

## Phase 4: frame counter, fixed window, baseline — complete

1. **Publication marker:** TD:$7AAA, the LoadView wrapper called by h3:$175E from
   Road Drawer h4:$C0E. The two Views alternate; every measured A500/A1200 publication
   is followed by the next field's bitplane DMA from the selected buffer. Screenshots
   confirm the displayed race. `frames.py` and `swap_fields.py` use this marker, and
   their 100-field patterns agree exactly. Menu LoadView calls are not gameplay FPS.
2. **Fixed window:** first h4:$F6 since reset, before the physics deadline copies the
   VBL counter, then 100 fields. This is the first attract race (stage 3), using the
   game's demo controls. Captures verify the anchor, mode, stage, car parameter and
   seed. `fixed_window.sh` defaults to the pinned fixture and rejects uncalibrated inputs.
3. **Necessary VERIFY fixture:** CUSTOM3 removes the RNG's beam operand, fixes its
   initial seed, and resets the seed at the demo-car selection call. Intro RNG call
   counts differ across CPUs, so removing the beam alone is insufficient. All three
   presets now start with Porsche index 0 and seed $1DC9. This small part of phase 7
   is implemented for measurement; no simulation or rendering enhancement is enabled.
4. **Two fresh boots per preset:** all $32A4 game-data bytes at both endpoints and every
   displayed game pixel match. A500/A1200 instruction PCs and cycle costs match in
   every field; trace and breakpoint frame counts agree. The 68030's breakpoint
   pattern repeats on two fresh boots. Local `docs/phase4.md` documents raw-record
   exceptions: a discarded INTREQR bit, screenshot edge padding, and unavailable
   68030 CPU/blitter timing. Whole raw-trace byte equality is not claimed.

| Preset | Presentations / 100 fields | FPS at nominal PAL 50 Hz | Blitter-wait routine | Blitter IRQ service |
|---|---:|---:|---:|---:|
| A500, 512 KiB chip + 1536 KiB slow | 8 | 4.0 | 21.16% | 11.36% |
| A1200/68EC020, 2 MiB chip + 4 MiB fast | 17 | 8.5 | 34.63% | 6.64% |
| A1200/68030 25 MHz, same RAM | 20 | 10.0 | unavailable | unavailable |

These are fixed-window baselines, not improvement claims or whole-race averages.
The 68030 backend emits no instruction records and has no validated CPU/blitter
cost model; its frame count is measured with read-only breakpoints. The local
frame-cost table includes span fill, projection, clears, interrupts, idle time
and DMA shares. The normal 1.5b build remains byte-identical to the hardware A/B slave;
CUSTOM3=0 leaves the original demo call and RNG instructions intact in VERIFY builds.

**Acceptance:** the measurement portion of playbook §12 is satisfied, with evidence
under ignored `tmp/dev/tmp/phase4/base-*` and reproducible commands in the local docs.
The phase-5 time model below completes the “ready to improve” analysis gate.
The traced vehicle and road calls are five fields apart on both CPUs in this window.
Phase 5 identifies why cross-CPU endpoint state differs and establishes the
clock/score/event model required before implementing enhanced simulation.

## Phase 5: the time model — complete

The local `docs/internals.md` now contains the time-source and state-writer tables;
`docs/phase5.md` contains field-indexed captures, instruction attribution, score formulas
and event evidence. The design below is revised for TD, not copied from TD2's constants.

- The priority-4 CLI runs vehicle integration at h4+$43B0/$3F26, road crossings at
  h4+$1C3A and traffic/police at h4+$14EA. Road Drawer is a separate priority -1 task.
  The period is **5 fields**, stored at race-frame -16(a5) by h4+$42. Deadline -12(a5)
  is initialized at $F6, waited at $16A..$190 and reset to current VBL at $192. There
  is no catch-up after an overrun. Root+$18BA increments the field clock -31782(a4).
- Race count -36(a5) starts at 1, then increments once per counted simulation tick;
  speed sum -44(a5) adds integer mph. Counting starts after first gear. The results
  divide count by **12**, yielding **5/6 nominal PAL time**. Average is speed sum/count;
  crash adds 240 count units, without speed, a 20-second penalty. Stage score is
  `M*1000000/max(N-B,100) + 100*max(100-(N-B),0)` with integer division, N=count,
  M=stage+4 and B the stage table value. It is not based on elapsed VBL time.
- Equal-field A500/A1200 captures confirm five-field ticks but disprove drawing
  independence. First gear is selected at sample 65 on both; clutch clears at 100 vs
  85, waiting for both rendered shifter buffers. Speed/position/RPM diverge at 85.
  Wall collision also consumes renderer-saved x (-22372(a4), h4+$B10/$1240/$127A).
  Renderer-written road widths and traffic collision origins/lane offsets also feed
  CLI decisions. Enhanced mode needs simulation-owned geometry and lane motion;
  original mode must preserve these behaviors.
- Crash animation/acknowledgement blocks the main loop. Natural Porsche crashes took
  37 vs 31 fields inside h4+$32D8 on A500/A1200; both applied exactly one +240 penalty.
  The count and speed sum froze through a 100-field acknowledgement wait. Drawing work
  adds CPU-dependent blocking time, independently of the explicit penalty. Radar uses
  five-field script counters; stopped ticks suppress vehicle integration while traffic,
  scripts and counted race time continue. The tested patrol stop held the vehicle for
  490 fields on both CPUs and released without acknowledgement input or a crash penalty.
  The original event paths remain part of the design.
- All 14 original direct RNG callers are mapped: root demo selection and stage commentary;
  h3 intro/car-selection waits; h4 road-crossing traffic/radar choices; and Road Drawer's
  high-speed windscreen effects. Later 100-field traces show 9 visual calls on A500 vs
  17 on A1200 plus one traffic call. CUSTOM3's current shared stream is insufficient
  for later cross-CPU windows; phase 7 must isolate visual consumption.
- PAL only is validated. The 12 ticks/second result conversion corresponds to 60 Hz / 5;
  NTSC timing and enhanced-mode clock conversion remain explicit unvalidated work.

The separate simulation process supports the overall design, but phase 8 needs rational
2/5 integration, original five-field script cadence and removal of the identified drawing
dependencies. The period-6 and integer-subdivision assumptions are rejected.

## Phase 6: always-on fixes (complete; hardware A/B deferred)

1. **Overlay cache flush: implementation and requested emulator smoke test complete.**
   Ported `overlay_unload_end` / `overlay_load_end` from TD2 commit `c4d0af5`,
   unconditionally using `PL_P $06390` / `PL_P $06916`. Each six-byte hook replaces
   `movem.l` plus `rts`; the helper flushes before restoring the original registers.
   Direct branch candidates into unload are `$062EC`, `$0630A`, `$06330`; into load
   `$0689E`, `$068DE`. All target the hook start; no word-aligned direct-branch candidate
   enters either interior. Indirect targets are not statically proven.

   The normal 1.5b build is unchanged by the VERIFY-only phase-4 instrumentation.
   `AMIGA_SETUP=a1200-040`: startup, driving demo and attract cycle passed, both helpers
   hit, and debugger checks confirmed return from `_flushcache`, restored registers,
   stack and return PC. MMU trace shows `TC=8000`; PAL, 25 MHz preset, 2 MB chip / 8 MB
   fast, JIT disabled, WHDLoad 20.0. Evidence and reproducible commands are in the local
   harness docs. The earlier emulation result described as “shipped 1.4” was actually 1.3.

   A/B slaves are under ignored `tmp/dev/dist/overlay-cache-ab/`: fixed 1.5b and the
   unmodified repository-1.4 rebuild, both built with the same pinned dependencies.
   No equivalence to an unavailable shipped 1.4 is claimed. Real A1200/68040 A/B testing
   is deferred at the user’s request and does not block phase-6 completion. Normal user quit passed on the same 68040 preset using the pinned native
   debugger-input emulator: keypad `*` returned WHDLoad to the AmigaDOS prompt before
   separate emulator shutdown. CACR was `$80008000`; this diagnostic build reports no
   data-cache emulation. FS-UAE success does not prove hardware cache coherency.
2. **Original display review complete; no additional patch warranted.** Phase 3 found no
   persistent defect in the inspected startup, five cockpits, crash/recovery, ticket or
   gas-station screens. Partial draws and phase-4 screenshot padding outside the game
   rectangle are not evidenced original display defects. There is therefore no affected
   scanline requiring a copper/register trace. This is bounded coverage, not a claim
   about every scene. Phase-5 drawing-dependent game state belongs to opt-in phase 8.
3. The source and ReadMe overlay history entry are committed; normal 1.5b and the 1.4
   A/B baseline remain byte-identical to the initial handoff. Local `phase6.md` records
   the acceptance evidence and normal-quit procedure. Hardware A/B remains a deferred
   follow-up; no hardware pass or release readiness is claimed.
   No push is requested. Any later evidenced display fix gets a separate commit.

## Phase 7: VERIFY scaffolding (complete)

`simulation-verify.s` and its configuration exist only under `-DVERIFY`. Normal 1.5b
remains byte-identical to the phase-6 handoff. The assertion protocol follows TD2,
with Test Drive-specific offsets, input decoding, event state and overlay lifetime.

1. **CUSTOM3:** fixed seed, beam removal and demo-selection reset remain. Four h4
   visual RNG calls use a private stream; the player-race anchor resets both streams.
   Later 1,400-field A500/A1200 demo captures record the same ordered two traffic draws
   and one radar draw despite different visual-stream consumption. This is bounded
   RNG evidence, not a claim that the original simulation is independent of drawing.
2. **CUSTOM4:** ten WaitTOF waits delay view publication only in an active player race.
   Both CPU presets retain the five-field simulation period and 259 counted updates
   over the 1,300-field test window while rendering fewer frames. The original clutch
   and saved collision position diverge under slow drawing, as expected negative controls.
3. **CUSTOM5:** bit 0 selects scripted player driving through `read_joydat`/`read_fire1`;
   bit 4 chooses straight acceleration/braking instead of a short steering tape.
   Bits 1/2 force one nonfatal crash/police pursuit at field thresholds 450/900.
   The original crash penalty, animation and ticket paths execute on both CPUs.
   Bit 3's zero-fraction oracle is supplied by phase 10; it is absent from the
   preserved phase-7 build.
4. **CUSTOM1 bit 1:** automatic acknowledgement after 100 fields in the crash wait.
   Early manual acknowledgement clears the private timer. With this bit clear, the
   original acknowledgement hook bytes remain and the crash fixture stays blocked.
5. **Assembly assertions:** 22 checks run before PatchSeg, exercising tape boundaries,
   the signed visual LCG and early-acknowledgement timer cleanup. `check_units.py`
   reads their completion/failure/first-failure state from captured RAM.
6. **Tools:** `audit_simulation.py` audits all 15 declared VERIFY ranges for boundaries,
   overlaps and direct incoming branch candidates (indirect targets are not proven).
   `check_disabled.py` verifies original or option-selected bytes and helper targets;
   all-zero VERIFY options leave all optional ranges original. VERIFY instruments
   intentionally have independent C1/C3/C4/C5 gates. Phase 8 adds C2 ranges
   and disabled checks. `verify_state.py --expect-equal`
   supplies the core-state equality gate; the original game's negative controls fail it.

Twelve fresh fixture captures, a confirmed h4 unload/reload, and deliberate checker
sabotages pass. Local `phase7.md`, `tmp/phase7/acceptance.json` and the evidence manifest
record commands, exact builds and limits. Historical phase-4/5 captures retain their
original VERIFY slave; the current build is a different fixture. No enhanced simulation
or fractional rendering is implemented by this phase.

## Phase 8: fixed-time simulation (`CUSTOM2`, complete; PAL emulator beta)

The implementation includes rational rates, PAL clock/speed integral, independent
shifter/decision cadence, traffic/police motion, simulation-owned geometry and visual
phases, and isolated RNG. The same-build five-car matrix passes all 20 short straight
and steering arms. Both real grip-clamp directions, native period-5 arithmetic,
normal/VERIFY option-off bytes, CPU budgets, cross-CPU/slow-drawing route comparisons,
natural crash/manual recovery, a natural police stop, and actual displayed stage
results with the next-stage reset pass. A real h4 unload/reload reapplies every patch.
The 1,600-field high-speed same-period demo matches all selected core states, five
gameplay RNG draws and a windscreen effect across A500/A1200 despite 129 versus
258 presentations. Automatic event recovery and normal-build C2-on smoke also pass.
Normal 1.6b and VERIFY assemble; the version-only change is byte-proven against the
functional test builds. Local `docs/phase8.md` records evidence and reproduction.

The 20-arm matrix covers five cars, both periods and straight/steering tapes over
1,300 fields each. Period-2 travel differs from period 5 by -0.045% to -1.338%;
peak-speed differences are at most 0.477 mph. This quantifies discretization and
decision-cadence differences, not whole-game bit identity. Native period-5 traces
verify 170 completed arithmetic calls against original rate/travel operations.
The observed main-loop work uses at most 10.64% / 8.91% of the A500/A1200 step
budget in the measured moving window; this is not a universal worst-case bound.
All 668 native assertions, declared-range audits and option-off byte checks pass.
Real A1200/68040 results remain deferred; NTSC remains unvalidated. Phases 9–10
supply rendering improvements; the player-facing option label is documented in phase 11.

Reuse TD2's architecture and tested arithmetic where its assumptions apply. Keep game-local
sources (`simulation.s`, `simulation-patches.i`) so each slave builds alone. TD's original
period is five fields; **do not copy integer `sim_n=6/sim_p` or six-field constants**.

1. Choose `sim_p=5` on 68000/010 and 2 on 68020+, subject to the measured CPU budget.
   Scale continuous changes by the rational `sim_p/5`, with a signed private remainder
   per accumulator. Five period-2 updates must compose to two original updates for a
   constant rate. Audit intermediate overflow and negative/near-zero cases. Relaxation
   requires retention `r^(sim_p/5)` with carries; TD2's integer n-th-root selection is
   insufficient. Derive and test the matching coarse-Euler displacement correction for
   this rational ratio, rather than applying a second scale to speed>>6 displacement.
2. Scale acceleration, braking, drag, steering, lane centring, traffic displacement and
   physical police motion. Leave road-segment loops, collision impulses, limits and
   thresholds unscaled. Keep gear decisions, shifter movement, police/radar counters and
   scripted decisions at the original five-field cadence, using an elapsed-field
   accumulator (period 2 does not divide 5). Separate gear/clutch progress from the
   renderer's two-buffer acknowledgements. Compute road-edge widths, current lateral
   position and traffic collision origins in the simulation; move lane-offset returns
   out of draw cadence. Changing only the wall-collision saved-x read is insufficient.
   Keep snapshots for drawing, and advance background/dashboard phases from simulation.
3. Use PAL elapsed-field quanta for the counted race clock and speed-weighted sum:
   12 legacy clock units per 50 fields, i.e. `6*sim_p/25` units per enhanced step with
   retained fractions. Preserve neutral-start exclusion, original blocking pauses and
   the explicit 240-unit crash penalty. Keep the stage score/reference tables in their
   documented clock units; test displayed time, average and score together.
4. Keep the original crash animation, acknowledgement and recovery path, including its
   CPU-dependent blocking duration. Radar stops suppress vehicle integration but keep
   script/traffic/counting active. Preserve these distinctions. Automatic recovery is
   VERIFY-only. Isolate visual RNG at a simulation-owned cadence and keep the gameplay
   stream free of beam/draw-rate input in enhanced mode.
5. Gate every gameplay change behind `PL_IFC2`; assertions for every arithmetic routine,
   hook-boundary/incoming-branch audits and disabled-byte checks are required.
6. Validate all five cars. Period-5 arithmetic must reproduce original rates/travel before
   intentional clock, RNG, clutch or collision changes intervene; label those divergences
   separately. Period 2 needs straight and route tapes and quantified handling differences.
   `check_timing.py` must prove PAL clock correctness, and the phase-7 state oracle must
   prove same-period core-state equality across CPUs/slow drawing outside the deliberately
   original blocking event intervals. Test event entry, one penalty, acknowledgement and
   recovery separately. NTSC remains open; no 50 Hz conversion may silently claim NTSC.

## Phase 9: blitter priority and interrupts (complete; PAL emulator beta)

`render.s` ports TD2's enable/restore helpers around the slave's program call,
behind CUSTOM2. TD's existing root:$434/$444 operand fixes already enable
BLTPRI during gameplay. The additional gain comes from disabling the unused
blitter-finished interrupt; the shape blitter polls BBUSY at root:$D44.
No additional game instructions are overwritten. The saved priority/interrupt
enables are restored on program return; WHDLoad handles its own quit/abort path.

The phase-4 profile identifies the five-plane shape-blitter waits at root:$10EC,
$115A/$117C/$119E/$11C0/$11D8 and blitter IRQ service at Kick-relative $D14/$D38,
handler $6DFA. No TD2 game offset was reused. VERIFY C1 bit 3 disables only
this optimization, leaving CUSTOM2 simulation enabled for a same-build A/B.

| PAL preset | Control FPS, two windows | Enabled FPS, two windows | Gain |
|---|---:|---:|---:|
| A500 | 4.05 / 4.05 | 4.70 / 4.80 | +0.65 / +0.75 |
| A1200/68EC020 | 7.45 / 7.55 | 8.30 / 8.35 | +0.85 / +0.80 |
| A1200/68030 25 MHz | 10.15 / 10.00 | 12.50 / 12.50 | +2.35 / +2.50 |

Each arm uses two 1,000-field windows from the same scripted player-race anchor;
FPS is breakpoint-counted LoadView publication at nominal PAL 50 Hz. These are
finite-window measurements, not whole-race averages. All gains exceed the
+0.15 FPS noise threshold. Selected gameplay state matches at the initial and
both end checkpoints. Hardware reads confirm priority enabled in both arms and
only BLIT removed from the interrupt-enable mask. All 668 assertions and the
existing hook/disabled-byte checks pass. The 68030 result is a frame count,
not an instruction-cycle claim.

Native helper-entry/return probes verify preserved registers and stack. Restore
is tested with an isolated immediate-program-return fixture whose helper bytes
are identical to the measured build; Control-C did not trigger the original
return path in a bounded probe, so no natural-return claim is made. Normal
1.7b C2-off/on smoke tests cover the final player build. Both builds assemble;
final version metadata is byte-proven against the measured candidate. Local
`docs/phase9.md` records commands, exact inputs/builds, evidence and limitations.
Real A1200/68040 testing remains deferred and NTSC unvalidated.

## Phase 10: sub-unit rendering (complete; PAL emulator beta)

TD's h4:$1114 main view and $11A2 rear-view mirror stream 40 / 30 road rows
through h4:$1A14. Native clip/plane probes establish their screen roles. Unlike
TD2, there are no 52-byte records or per-view gradient tables to convert: the
original camera/curve recurrence already carries fractions. Root:$2108 is an
interpolated 16.16 sine. Fractional arguments use that native interpolator;
repeated integer angles use an exact cache, without TD2's 8.8 tangent key.
No TD2 game offset or duplicate camera correction is used.

`render.s` and `render-patches.i`, behind CUSTOM2, supply the missing lateral
fractions, mirror camera prefix, full slope accumulator, camera-interpolated
crest limits, fractional traffic projection and atomically latched mountain
heading. The main lane anchor follows the scale of the first visible row, removing
the sideways jump at whole-segment camera crossings. Original near-car and horizon clipping
policies remain. The sine cache retains the last integer-angle result; rapidly
changing fractional arguments bypass cache bookkeeping. A flat-slope fast path skips work only with
a zero descriptor and accumulator.

VERIFY C1 bit 4 disables the new projection hooks for same-build comparisons.
C5 bit 3 provides the original-arithmetic zero oracle, bit 5 supplies isolated
camera/lane/traffic draw snapshots, and bit 6 runs 1,421 native renderer checks.
Normal builds omit these instruments. The local geometry, zero, crossing,
sideways, cost and frame-rate tools operate on native debugger captures.

The final 1.8b normal and VERIFY builds assemble. All 1,421 renderer assertions
and the existing 668 simulation assertions pass. The controlled VERIFY zero
oracle matches 40 main / 30 mirror rows, scanlines and queues byte-for-byte;
production C2 deliberately retains fractional slopes and fixes the native
exact-zero camera special case. Independent models cover positive/negative
slopes, bends and ten traffic projections. The held-lane integer crossing has
zero horizontal jump and at most one vertical pixel difference in the main
view; the mirror matches exactly. The mountain report checks 128 layer outputs
against the atomic interpolation model, without claiming every maximum step
is reduced at high camera speeds.

| PAL preset | Projection off FPS, two windows | Projection on FPS, two windows |
|---|---:|---:|
| A500 | 4.70 / 4.75 | 4.80 / 4.95 |
| A1200/68EC020 | 8.30 / 8.30 | 8.30 / 8.30 |
| A1200/68030 25 MHz | 12.50 / 12.50 | 12.50 / 12.50 |

Each same-build pair enables C2 simulation and uses two consecutive 1,000-field
windows. Selected gameplay state matches at the start and both endpoints.
A500 self-cycle cost is 2.875% / 2.877% in two 50-field moving-demo samples,
below the 3% budget; hook costs and displaced instructions are included.
These are finite PAL samples, not universal worst-case or whole-race bounds.
All 82 optional range declarations, bypassed-tail audits and disabled-byte
checks pass. Normal C2-off/on startup and 400-field attract smoke tests pass.

Local `docs/phase10.md` records commands, exact builds and evidence, including
which unchanged projection checks predate the final cache/flat-slope fast paths.
ReadMe history and build dependencies are updated. The preserved phase-6 A/B
pair is unchanged. Real A1200/68040 testing remains deferred; NTSC remains
unvalidated. Phase 11 records full release regression and packaging.

## Phase 11: regression, release and contribution — complete locally

Release 2.0b (13.10.2026) consolidates all enhancements since JOTD 1.4.
The local release regression passes. Real A1200/68040
play-testing remains deferred by the user. No push or PR is authorized; fork and
upstream publication remain a separate follow-up.

- Normal and VERIFY builds assemble; packaged source rebuilds byte-identically.
  The phase-11 assembly delta was the Enhanced framerate option label.
  Current 2.0b also corrects a camera-phase-dependent main-view lane seed.
  A full-cycle native regression replaces the earlier endpoint-only continuity
  check: at lane offsets +/-180 the isolated drift is 17.147 pixels before
  and less than 0.042 pixels after; centred-road scanlines are unchanged.
- All 84 display/optional patch ranges and direct incoming/bypassed-tail audits pass.
  C2-off retains original optional-patch bytes. Static audits do not prove
  indirect targets.
- 668 simulation and 1,421 renderer assertions pass. All 20 combinations of
  five cars, periods 2/5 and straight/steering inputs reproduce the accepted
  handling and PAL timing results. Cross-CPU route/demo and slow-drawing
  comparisons retain gameplay/RNG state. Forced crash/recovery and police-stop
  checks pass on A500 and A1200.
- The controlled VERIFY zero oracle matches 40 main/30 mirror road rows,
  scanlines and queues; downhill road/traffic and 128 mountain-layer outputs
  match their independent models. The zero oracle selects original arithmetic;
  it is not a claim that all production integral positions reproduce old output.
- Normal-build A500 renderer samples at the anchor and after 1,000/1,600 fields
  use 2.789%, 2.981% and 2.862% self cycles, below the 3% gate. Simulation work
  also remains within its period. These are finite samples, not worst-case bounds.
- Two 1,000-field controlled projection windows per arm pass on all three
  presets, with equal selected gameplay state and no FPS loss. Normal-build
  measurements below start with native demo car 0, stage 3, position 30, zero
  speed/gear and zero presentations, selected by read-only breakpoints.
  Later RNG and original/fixed-time trajectories can differ; this table does
  not isolate rendering cost. Initial unmatched-car captures are diagnostic only.

| PAL preset | C2 off FPS | C2 on FPS |
|---|---:|---:|
| A500 | 4.30 / 4.45 | 4.75 / 4.45 |
| A1200/68EC020 | 8.20 / 8.25 | 8.55 / 8.35 |
| A1200/68030 25 MHz | 11.10 / 11.85 | 12.50 / 12.50 |

WHDLoad 19.2 and 20.0 (the oldest/newest installed runtimes, as in TD2's
checklist) pass normal C2-off/on startup, 400-field attract driving and native
quit-key return to AmigaDOS. This does not claim WHDLoad 17.0 validation.

`slv_config` exposes `C2:B:Enhanced framerate;`. The installer Normal icon and
preinstalled launch icon enable `CUSTOM2=1`; the two optional GlowIcons retain
their original defaults. ReadMe documents the option, off path and PAL beta scope.
`Makefile_windows.mak` already includes all source dependencies.

Local `package_release.py` writes verified level-1 LH5 installer/preinstalled
archives to `tmp/dev/dist/2.0b/`, with explicit member/checksum manifests.
Only intended slave, ReadMe, Install script, icon and installer source members change.
ReadMe and Install use the WHDLoad 20 Install Template, retaining the Test Drive
file-copy layout, supplied executable, instructions, icons and original credits.
ReadMe has one concise, player-facing 2.0b history entry for all enhancements.
Actual Installer 43.3 script-flow checks pass with deterministic requester answers:
all three icons, both existing-drawer choices, missing required file and paths
containing spaces. Interactive requesters and disk-image mounting are not covered.
The packaged Makefile uses the shared AmigaXDev SDK; both variants rebuild exactly.
Archives and generated evidence remain ignored and local. The original 1.4/1.5b
hardware A/B bundle is unchanged. Local `docs/phase11.md` records reproduction,
exact builds and acceptance evidence. NTSC remains unvalidated.

The main-view near-plane transition now seeds the remaining lateral projection
from its actual scale (12288/5899 times lane * scale), once per view. The old
unit anchor admitted a different first row as the camera fraction changed,
causing periodic sideways jumps away from the centre. Native sweeps cover all
64 sampled camera phases on both sides and the centre; a separate model covers
all 65,536 fractions for seven signed lane positions. This isolates projection
drift from the original scanline raster rounding. Simulation and raster shifts
are unchanged. That flat-road correction used 2.980% A500 renderer cycles
including its shared arithmetic helper in the retained 50-field sample. Local
`docs/road-shift.md` records the regression and targeted checks. The current
downhill model matches 40 main / 30 mirror rows and ten traffic projections;
the original-arithmetic zero oracle also passes. A1200/68040 C2-off/on startup,
attract driving and native quit pass in emulation.

The remaining cornering discontinuity is corrected at h4:$7EAA. The near-plane
curve seed and bank displacement now retain the visible fraction of their
height span; banking is latched with the camera. Native same-position A/B
captures reduce a 13.675-pixel endpoint jump to 0.020 pixel, and a seven-pixel
road-scanline jump to zero. Independent models match all 40 native rows through
both bend directions, signed lanes/banks and a hill transition, and exhaust
65,536 fractions in six cases. The original-arithmetic zero oracle, 2,089
existing native assertions, hook/disabled-byte audits and A1200/68040 CACHE
startup/attract/quit checks pass. Simulation and collision state are unchanged.
Local `docs/corner-jump.md` records exact builds and reproduction.

The matched 100-field A500 sample uses 3.195% for renderer self/hook work,
shared lane arithmetic and the new bank-sine call, versus 3.019% for the prior
release; both complete nine main views. The former 3% finite-sample gate is
not passed in this window. The +0.175 percentage-point cost is accepted for
this correctness fix, rather than retaining the visible jump. These are
finite samples, not a whole-race bound; historical lower cost figures above
are not current universal claims. Hardware testing remains deferred.

The analogue rev counters now stop at their last numbered marks (Porsche/Lotus
7000, Ferrari 10000, Countach 9000 RPM), including with C2 disabled. This limits
display lookup only: engine RPM, damage threshold and over-rev event timing are
unchanged. The Corvette digital display keeps its original path. The per-car
selection and display hooks are h4:$82A2/$42A0; the common overlay exit installs
them before the cache flush and optional enhancement hooks. Local
`docs/rpm-needle.md` records neutral/in-gear reproduction, all five dashboards,
327680 native clamp cases and release C2-off/on startup, attract and quit checks.
The original dial artwork and drawing routine are unchanged.

Steering-key reversals no longer add an immediate visual road bend while the
wheel is centred. The h4:$7F94 hook captures the native direct-key lateral
impulse before wheel motion is added; `sim_bank_pose` excludes only that
impulse from the visual pose. Vehicle motion, grip, collisions, road curvature
and skid effects keep their existing paths. C2=0 retains original behaviour;
the VERIFY original-arithmetic drawing oracle also retains the native pose.
Local `docs/steer-reversal.md` records native keyboard reproduction and the
isolated visual regression. This remains part of 2.0b (13.10.2026).

Curvature rounding at h4:$7F5A now uses original five-field units before scaling
back to the current step with a private carry. Previously the two-field step
rounded gentle positive bends to zero and over-applied negative bends. Period
5 retains native arithmetic. Hands-off driving on a1200-040 reaches the first
wall at course position 824.9 after correction, versus 826.3 in the original
and 449.0 before correction; this is a finite route comparison, not exact
cross-period state equality. `docs/handling-collision.md` retains the evidence.

The common h4:$1AD4 correction restores the missing integer-word selection
after the close-traffic scale multiply. The old fractional word placed nearby
right-lane vehicles thousands of pixels outside the view while collision
checks remained active. A guest parked-truck fixture reproduces an empty-road
collision before the fix and a visible truck at the same collision afterward.
The fix covers both views and both C2 modes; collision limits are unchanged.
Native assertions cover all 16 road widths and signed screen-coordinate limits.
This is a projection arithmetic defect, not the address-carry issue found in
Grand Prix Circuit. The combined hook audit covers 87 ranges; normal C2-off/on
A1200/68040 startup, attract and quit pass. Both fixes remain in 2.0b.

The always-on opening-audio correction stops fast CPUs repeatedly acknowledging
Paula's final manual-output request after DMA is disabled. A stopped channel's
interrupt remains disabled until the existing two-VBL restart delay has elapsed;
the VBL tail clears stale requests, starts DMA and restores the appropriate
interrupts. Looping music/engine channels retain their interrupt masks. Hooks
are root:$2574/$2684/$26CA/$276A; the VBL mask snapshot is atomic against the
higher-priority audio handler. No song data, tempo or sample pitch is changed.
The unmodified 1.4 and pre-fix 2.0b both reproduce missed initial interrupts and
doubled one-shots on the emulated 68040. With instruction/data caches enabled,
all 59 one-shots in the corrected 1,000-field opening capture have exactly one
initial and one completion interrupt, with no negative-count interrupt loop.
68000/68020 startup, attract and native quit pass, as do both enhancement modes
on the 68040. Local `docs/audio-repeat.md` records the evidence and limitations.
The user confirms that the sample-repeat bug is fixed in the 2.0b release on
the a1200-040 emulator with caches and enhancements enabled. This remains part
of 2.0b (13.10.2026); real hardware testing stays deferred.

The 2.0b cleanup removes obsolete visual-RNG read hooks at h4:$1EEE/$1F00/
$1F10/$1F76 and their helpers: enhanced drawing always bypasses those spawning
and aging ranges, with visual state now advanced by `sim_visual_step`. The
original-game VERIFY hooks remain usable. Uncalled inherited fire-button code,
an unreachable disk-command check/version branch and an unused option tag are
also removed. No rejected experimental runtime switch is retained for these
paths; the active VERIFY fixtures and profiling boundary labels remain.
The remaining 88 patch ranges, 2,089 native assertions, cached 68040 startup/
driving/quit in both enhancement modes, and packaged-source rebuilds pass.

## Phase 12: lessons back to AmigaXDev

Record in AmigaXDev `docs/` what generalises: transferring an engine between games of one
studio by structure rather than offsets, and the overlay cache fix as a pattern for every
Aztec overlay executable. Update `docs/projects.md` with this branch.

## Open questions

- Does the unmodified repository-1.4 rebuild fail on real A1200/68040 hardware? Emulation cannot tell
  (phase 6.1).
- NTSC timing is unvalidated; phase-8 acceptance is PAL only.
- The intermittent post-crash steering-dot displacement report remains unconfirmed.
  The supplied Countach screenshot was reproduced exactly before a crash; four
  isolated crash/recovery tests restored the dot. No steering-dot fix is claimed.
  Local `docs/wheel-dot.md` retains the evidence and next checks.
