# Grand Prix Circuit — performance plan

Goal: give GPC the Test Drive II treatment under one `CUSTOM2` "Enhanced framerate" option:
a higher simulation rate on 68020+, smooth (sub-unit) road and car drawing and blitter
priority, with the original game one option away. Method: AmigaXDev
`docs/playbooks/new-game-playbook-jotd.md`. Reference implementation: `T/TestDrive2/usr/source/`
in this fork (offsets do not carry over) and the standalone Test Drive 2 project (harness,
tools, docs). The local harness lives in the worktree's ignored `tmp/dev/`.

## Decisions

- `CUSTOM2` "Enhanced framerate" bundles every performance change; `CUSTOM2=0` is the original.
- Pure bug fixes (the swap tearing fix) are always on, like TD2's DDFSTOP fix.
- **Performance only.** What the player experiences stays original: handling, AI, lap and
  race times, crashes, spins, pit stops, penalties and messages. No TD2-style recovery change.
  Every simulation change must be shown equivalent to the original (Phase 6 checks).
- Simulation period: 6 fields on 68000/010 (the original), 2 on 68020+. Go to 1 on 68020+
  only if measurements show the game can actually reach 50 fps there and the step cost fits.
- Only v1.0 (the 94 708-byte executable) is supported; other versions keep JOTD's patches.

Addresses below are hunk-0 offsets of `data/GrandPrixCircuit` (file offset = hunk + $28),
the slave's patch numbering. Static analysis is supplemented by the Phase 0/1 runtime checks below.

## What we know (static analysis and Phase 0/1 validation)

- Executable: 94 708 bytes, Aztec C small-data (a4 = hunk1 + $7FFE), hunks CODE $E544,
  DATA $8918, BSS $4. `HUNK_OVERLAY` with an empty table. The linked overlay manager starts at h0:d42c
  (alternate entry d43e; stub writer d4a2), not d414. It is inactive in the supplied v1:
  all 139 hunk-1 jump stubs are already direct jumps, no relocated pointer targets the
  manager, and entry/write breakpoints plus a full-table hardware watchpoint stayed silent
  through startup, car presentations and two attract races. No stub rewrites were observed.
- Shared with TD2 (byte-identical or operand-masked identical): RNG `c11e` (VHPOSR at `c12c`,
  seed 2002(a4)), shape blitter `c7f4`, line drawer `cfd2`, 4-plane span fill `8864`, movem
  clear `ce1e`, VBL/audio server `b126`, sound driver (song1..3), protection `b2f4`.
- **Not shared:** the race engine is a ~18 KB hand-written asm block at h0:6854–af3c. There
  are no TD2 offsets to reuse for simulation, projection, swap or road rows.
- **Different architecture:** GPC is single-task. The simulation runs inside the VBL interrupt
  server "Ticks VBLInt" (AddIntServer at h0:40e, code h0:772a): every field it bumps -31790(a4);
  unless paused (-31736), it bumps -29930, counts down -29928 from the period word -29926
  (= 6, data hunk $B18, never written), then steps: `776a`, `jsr -32514(a4)` → `a288` (AI),
  `782e` (player), `8010`.
  Consequence: game time is probably *already* independent of drawing speed. The TD2 work that
  matters here is the higher step rate, smooth drawing and display fixes, not decoupling.
- Main loop h0:7094–7264 → `729a`: `a58c`, latch `a6ea` (copies car tables, -30016→-30010,
  -30012→-30006, -29930→-29932; not interrupt-safe), `a77c`, `9a48`, road `818c`, `906a`,
  `6dc4`, `6ae0`, `6a28`, swap `a8ee` (→ h0:372, LoadView at h0:39e; no WaitTOF, then `cf04`
  retargets drawing to the buffer just shown → probable tearing on fast CPUs).
- Player track position: segment pointer -30016, 8-bit in-segment fraction low byte of
  -30012 (h0:7e2c–7e46). The analogue of TD2's camera fraction F.
- Road renderer: per-scanline span lists, 110 rows (loop end h0:8508), stripe phase from the
  latched integer camera at h0:84b2.
- Rebuilt slave (1.1-beta): interface 17, kick13, own LoadSeg; the 94,708-byte executable
  selects `resload_PatchSeg`, other sizes retain JOTD's `resload_Patch` path. The lists
  keep the original busy loop `PL_PS $174`, protection skips, 68010 `move sr`, and song
  INTREQ/DMACON patches. Empty `slv_config` reserves the structure without advertising an
  unimplemented option. `CUSTOM2` currently has no effect. The vasm Makefile builds normal
  and VERIFY outputs separately; VERIFY adds only a discovery record, no game hooks.

## Plan

Each phase ends with a check. Do not start patches before Phase 4 is done (playbook §12).

### Phase 0 — Harness (complete)
1. Copy TD2's `amiga/run.sh`, `run-a1200.sh`, `run-68030.sh` into `tmp/dev/amiga/`, adapted
   like Red Baron/Hard Drivin' (`GAME`, `SLAVE_NAME=GrandPrixCircuit.Slave`, resolve `SLAVE`
   paths absolutely, kick13 images into DH0:devs/Kickstarts, `HARNESS_ROOT`).
2. `tmp/dev/tools/build.sh`: vasm build of `$GAME_SOURCE` into `tmp/build/` (normal and
   `-DVERIFY`), from WHDLoad 20.0 includes/KickEmu, like Red Baron's.
3. Tools: `gpc.py` (rename of the gdb `Server` wrapper), `_amigaxdev.py`, `td2_report.py` →
   `gpc_report.py` (hunk sizes, path, kick13), `frames.py`/`swap_fields.py` (new marker:
   swap at h0:372/39e), `profile_demo.sh` + `ingame.py` (new in-race pixel test),
   `fixed_window.sh` (new anchor), `state_fields.py`, `state_writers.py`, TFH's whole-hunk
   `compare_state.py`, `audit_simulation.py`, `check_disabled.py`, `check_units.py`. Skip
   TD2-specific ones (`task_state`, `state_watch`, `subunit_*`, `sideways_*`).
4. `docs/development.md`, `docs/internals.md` (seeded from "What we know").
   **Check:** shipped slave boots to the title/attract demo on the A500 profile; pristine
   manifest unchanged; `git status` clean.

### Phase 1 — Rebuild and modernise the slave (complete; no game patch changes)
1. Build the unmodified source; fix only what vasm 1.9 needs. Compare behaviour with the
   shipped slave (byte-compare if the shipped one came from the same source).
2. Move to the TD2 slave skeleton: slv_Version 17, `slv_config`, `resload_PatchSeg` with a
   size/CRC-checked v1 list (others fall back to JOTD's), `IFD VERIFY` blocks; replace the
   stale `Makefile` with the vasm build used by the TD2 directory.
3. Runtime checks: overlay manager never rewrites a stub (watchpoint on the jump table /
   h0:d4a2); protection stays bypassed; music fixes intact.
   **Check:** new slave plays identically with `CUSTOM2=0`; `check_disabled.py` sees original bytes.

#### Phase 0/1 results and evidence

- The existing `grandprixcircuit` worktree was clean before the source changes; all harness
  files remain ignored under `tmp/dev`. The retained preinstalled archive has 55 files,
  all still matching `tmp/archives/GrandPrixCircuit_v1.0_0008.files.json`. No game bytes,
  SDK, generated slave or capture is committed.
- `tmp/dev/tools/build.sh` delegates to the authoritative source Makefile; `VERIFY=1`
  selects the separate VERIFY output. Direct `make -C G/GrandPrixCircuit/usr/source`
  works too. Dependencies: vasm 1.9, official WHDLoad 20.0 headers/KickEmu, NDK LVO
  includes via generated guarded wrappers. The sole original-source assembler fix was
  `blk.l` to `dcb.l`. The pre-modernisation build is retained as
  `tmp/dev/tmp/build/GrandPrixCircuit-unmodified.slave`.
- Shipped 1.0, baseline rebuild, modern normal and modern VERIFY all reach the opening
  screens and automatic driving demo with `CUSTOM2=0` on the A500 profile (68000,
  512 KB chip, 1.5 MB slow, no fast RAM; PAL). The normal build was also checked on
  A1200/68EC020 (2 MB chip, 4 MB fast). WHDLoad 20.0 and 19.2 both passed the A500 run.
  WHDLoad 17 itself and real hardware were not available for this check.
- `check_disabled.py` undoes hunk relocations and checks 58,642 original code bytes on
  68000 (58,628 on 68020), plus the six existing JOTD patches (thirteen on 68020), and
  all 139 relocated jump stubs. Only named native mutable slots are excluded: startup
  h0:0008–0017, audio state fields b220–b223/b228–b22b and native runtime storage
  b6ea–b6ed. Corruptions at 039e, 772a and 818c each caused a failure. The existing
  delay/protection hook boundary audit found no errors.
- The three song files have identical driver code. Live checks confirm all three INTREQ
  fixes and eleven DMACON hooks. Baseline-rebuild and modern helper bytes match; the
  shipped BASM build uses shorter branches/other equivalent encodings, so whole-slave
  byte identity is neither expected nor claimed.
- The active opening-screen pixels match exactly between shipped, baseline rebuild and
  VERIFY. Demo driving is visibly functional in all arms. This is code/patch equivalence
  and functional startup/demo coverage, not per-field state equality: RNG pinning and
  repeatable gameplay windows belong to Phase 2. The whole-data comparator rejects
  changed/truncated inputs and distinguishes the two recorded demo states (1,154 bytes).
- Overlay evidence: read-only breakpoints at h0:d42c/d43e/d4a2, armed before h0:0018,
  and a hardware watch over h1:0000–0341 (834 bytes) had no hits. Entry and race snapshots
  match the relocated pristine table. A watch of the same size over the native VBL field
  counter caught its write, validating the debugger mechanism. For this executable the
  manager is dormant; there are no runtime overlay stub replacements to accommodate.
  Other executable versions are not available and are not covered by this conclusion.
- Local reproducible checks: `tools/validate_boot.py`, `check_inputs.py`,
  `check_disabled.py`, `check_music.py`, `check_units.py`, `audit_simulation.py`.
  Evidence under `tmp/dev/tmp/validation/{shipped,unmodified,modern,verify,a1200,whd19}`:
  exact slave/hash, debugger transcripts, entry/title/race RAM and screenshots; summary
  `tmp/dev/tmp/validation/checks.txt`. Commands and coverage limits are in local
  `tmp/dev/docs/development.md` and `internals.md`.
- Prepared GPC report/state tools and candidate capture wrappers. The candidate swap
  marker is h0:039e, VBL entry 772a and first race-loop anchor 7094. These have **not**
  been validated as performance instruments. No FPS baseline, RNG patch, input tape,
  simulation patch, renderer patch or Phase 2 measurement has been started.

### Phase 2 — Measurement setup (not started; playbook §5–§8)
1. Trace the confirmed attract demo or a scripted race start; name every hot region
   with `gpc_report.py`.
2. Fixed reproducible window: VERIFY `CUSTOM3` removes VHPOSR from the RNG (`c12c`, same patch
   as TD2 `PL_W`); anchor at race start; `CUSTOM5` joystick tape (TD2's `verify_read_joydat`
   idea, at GPC's joystick read).
3. Validate the frame counter (full trace vs `SWAP_ONLY` at the LoadView swap).
4. Baseline fps on A500 (512 chip + 1.5 MB slow), A1200 (68EC020), 68030/25.

### Phase 3 — Game-time model (playbook §9, `fixed-time-simulation.md`)
1. Map every time source: -31790, -29930/-29928/-29926, 3730(a4) render deltas, race/lap
   clock (4024(a4)? qualifying uses -31790×6 at h0:6624–6700), sound, RNG.
2. Coupling test: CUSTOM4 slow drawing — does race time, lap time and AI progress stay the
   same? Expected yes (VBL sim); find the exceptions (crash/spin recovery, pit stops,
   start lights, anything in the main loop instead of the VBL).
3. State map of the step: player (`782e`→`786c`/`7e2c`/`7e66`/`795c`), AI `a288`, `776a`,
   `8010`. List every rate that must scale with the step period.
4. Price the step: interrupt time per step on 68000 and 68020 (decides period per CPU).

### Phase 4 — Review point
Present baseline numbers, the time model and the step price. Confirm periods 6/2 fit, and
whether 50 fps (period 1) is reachable on any 68020+ configuration. If Phase 3 finds
CPU-dependent player-visible behaviour, report it: fixing it would change gameplay, so it
is out of scope unless decided otherwise.

### Phase 5 — Cheap wins (blitter under CUSTOM2, tearing fix always on)
1. Blitter priority + blitter-IRQ suppression (`render.s` `render_interrupt_option`, as-is).
2. Swap tearing: wait for the new view to be live before drawing into the old one
   (WaitTOF/beam wait after LoadView at h0:39e) — the GPC analogue of JOTD's `set_copper`.
   Always on (outside CUSTOM2); first confirm the tearing in a 68020/030 capture, then show
   it gone and the A500 rate unchanged.
   **Check:** fixed-window A/B, two boots per arm, ±0.15 fps noise floor.

### Phase 6 — Higher simulation rate
1. Period word -29926 (and the initial -29928) → `sim_p` per CPU (6 on 68000/010, 2 on
   68020+; 1 only after Phase 4 shows 50 fps is reachable), set in a `sim_configure` like
   TD2's (AttnFlags before PatchSeg).
2. Port TD2's `simulation.s` helpers unchanged: `sim_scale_long` (divide by `sim_n` with a
   private fractional carry), Euler correction, force reference, `sim_relax` n-th roots.
   Apply them to each rate found in Phase 3 (player, 10 AI cars at `a2c4..`, clock).
3. Keep discrete counters at the original 6-field cadence (TD2 rule: gears, timers, AI
   decisions), and race/lap clocks in real PAL time.
4. Interrupt-safe latch: guard `a6ea` (Disable or double-read) so a step never lands mid-copy.
5. Crashes, spins, pit stops and penalties keep their original logic and timing; only their
   per-step rates are scaled, so they cost the same game time as in the original.
6. VERIFY: assertions on the helpers (reuse `simulation-verify.s` structure), scripted tape,
   forced events; handling table (same tape, period 6 vs 2: lap times and positions within
   a stated tolerance); `compare_state --assert-core` between same-period machines;
   `check_disabled.py` proves `CUSTOM2=0` leaves the original bytes.

### Phase 7 — Sub-unit rendering
1. Camera fraction: latch -30006 low byte (and the step phase -29932 vs -29930 for
   interpolation between steps, if the step rate stays below the frame rate).
2. Road: feed the fraction into the row projection and the stripe phase at h0:84b2.
3. Cars: interpolate each AI car's 16-bit position (with its byte carry) toward the next.
4. Heading/curve/scenery offsets: as TD2's walker and mountains, if GPC's road has them.
5. Budget: at most ~3% of A500 cycles (TD2 measured 2–2.9%); zero-fraction oracle must be
   byte-identical to CUSTOM2=0 drawing.

### Phase 8 — Hardware, release, upstream
1. Real/MMU runs (68040 with MMU, JIT off), oldest and newest WHDLoad.
2. ReadMe history, `DECL_VERSION`, icon tooltype `CUSTOM2=1`, slv_config entry.
3. Adapt `package_release.py`; focused commits on `grandprixcircuit`; PR via Vesuri.
4. Generic lessons (interrupt-driven simulation, LoadView swap marker) → AmigaXDev docs.

## Open questions
- Attract demo confirmed; Phase 2 must establish its repeatable capture window.
- Race/lap clock location and whether it already runs in real time.
- Does anything (crash, spin, pit) block the VBL step or depend on CPU speed?
- Overlay question resolved for the supplied v1: dormant manager, no stub rewrites (Phase 1 evidence above).
