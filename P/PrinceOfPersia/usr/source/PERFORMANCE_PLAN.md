# Prince of Persia: A500 performance plan

Goal: the game's intended speed on an A500, which is a frame every 4 PAL fields (12.5 fps).
The VBL countdown is reloaded from `g:$7aba` = 4, and the main loop waits for it at `g:$1bd46`.
Today, on the spikes route on `a500-1.5m`: 10.4 fps. 137 of 206 frames hit 4 fields, 60
overrun to 5–9, and the two room changes take 31 and 35 fields. The game advances one step
per frame, so an overrun frame is slow motion, not dropped frames.

Acceptance, on `a500-1.5m` (68000 7 MHz, 512 KB chip + 1.5 MB slow), PAL:

| Id | Criterion |
|---|---|
| G1 | ≥ 95% of gameplay frames on every benchmark route take the game's own frame time (4 fields, or 5 while the kid's sword is drawn; B4); none takes more than one field longer |
| G2 | Accepted by the user on 2026-10-15 at current performance; closed. The original ≤16-field target is waived for the remaining transitions. |
| G3 | Game state at every frame and every published frame's pixels are identical to the original, with the same frame-indexed input |
| G4 | No regression on A500 + fast RAM, A1200, 68030/040/060 (functional, caches on), NTSC |

Sizes per frame, steady running / spike death (fields): work 3.72 / 5.41; full-screen copy
0.79 / 0.82; layer draw 0.87 / 1.98 (tile draw `$1c29c` 0.76 / 1.72); logic `$1156a`
1.20 / 1.43 and `$0c0ac` 0.71 / 0.82; tile lookup `$107d0` 0.49 / 0.50; shape blitter
`$05686` 0.36 / 0.84 with 43 / 89 blits; STOP blitter waits 0.95 mean; interrupts 0.17 / 0.31.

## A. Measurement and safety net (no game change)

- **A1 Build.** `tools/build.sh` assembles the normal slave and a `VERIFY` variant into
  `tmp/build` with the shared vasm flags. Gate: the normal build is byte-identical to the
  shipped v4.4 slave (already true by hand).
  *Done.* `CHECK=1 tools/build.sh` builds both and compares the normal one with the shipped
  slave. `VERIFY` adds `PrinceOfPersiaVerify.s` (instruments, version 1 only, chained after
  `pl_v1`) and " (VERIFY)" in the name; the harness takes slave offsets from the vasm listing.
- **A2 Frame-indexed input.** An input tape in the VERIFY slave, indexed by gameplay step,
  replaces host keys. It is better than counted breakpoints: those are very slow on this stub,
  and only a tape gives other CPUs (G4) the same input on the same step.
  *Done.* `CUSTOM4=n` plays tape n:
  - **Steps:** a step is a control poll from gameplay (`g:$1942c` called through `g:$13de2`,
    once per frame). The title, intro and interludes poll in busy loops, as often as time
    allows, so they don't count. The joystick reader (`g:$1b8bc`) returns the tape's mask (1
    up, 2 down, 4 left, 8 right, 16 fire).
  - **Pauses and skips:** outside gameplay, `TAPE_SKIP` (or a level request) is fire, which
    skips the title. `TAPE_RESUME` is fire for the pause loop's button check (`g:$1958a`)
    only. It ends the pauses at the title and at step 1 without the controls seeing fire.
  - **Level requests:** `TAPE_LEVEL+n` writes n to `$47ab8`, as the level skip does.
  - **Live input:** a zero mask lets the game read the keyboard, so `tools/tape_from_route.py`
    can turn a live keypad session into tape entries.
  - **The spikes route** is tape 1 (`tape_spikes`), with no host input. It dies in the spike
    pit by step 274.
  - **Screenshots at chosen steps:** `verify_stop` and a breakpoint at `verify_stopped` stop
    the CPU at the start of a step. Use them outside traces only.

  Gate passed: two boots give identical screenshots at all 14 key-change steps from 2 to 300
  (`tools/tape_run.py`, `tools/sameshots.py`; numbered before steps were limited to
  gameplay, so one higher than now). The stub leaves the screenshots' last two
  columns unwritten, so those are ignored. Note for A4: `g:$1ba58` adds VHPOSR to the RNG seed
  `g:$7cb6` at level start and on fire, so the seed depends on timing.
- **A3 Frame-time counter (VERIFY).** The slave hooks the frame-wait entry and exit and the VBL
  handler, and keeps a per-frame log in slave memory: fields per frame, work in beam
  positions, and the blit count. gdb reads it once at the end, with no stop inside the window.
  Gate: on the baseline its period histogram equals `tools/frames.py`'s exactly.
  *Done.* The VERIFY slave replaces the frame wait `g:$1bd46` with a copy (`verify_wait`) and
  counts VERTB and blitter interrupts. Time is in raster lines (fields × 313 + VPOS).
  - **Log format:** each wait exit appends (step, period, work, blits) to `verify_log`, which
    has 2048 entries.
  - **Tools:** `profile_run.py` saves the block as `verify.bin` and marks the VERIFY wait and
    poll. `tools/frame_log.py` summarises the log.
  - **Gate passed:** `tools/check_frame_log.py`, on the spikes tape traced for 1700 fields,
    matched all 304 frames that lie inside one chunk to the field. `frames.py` miscounts frames
    that cross a chunk boundary, because a field runs untraced between chunks, so the log is
    the reference from now on.
  - **First figures (tape 1, from boot):** periods of 4 × 191, 5 × 46, 6 × 51, 7–10 × 12. The
    room changes at steps 124 and 244 take 32 and 36 fields; the level start takes 57.
  - **Hooks change timing:** the tape's screenshots stay the same apart from the torch flames.
    Those come from the RNG, whose seed takes VHPOSR (A4).
- **A4 Faithfulness probes (VERIFY).** At each frame-wait end, hash the game state: kid and
  guard character records, level and room buffers, timer, RNG, and the sound request queue
  once B1 has located them. At each display swap (`g:$1a0e6`, the buffer in `$49d1c`), hash the
  published frame's bitplanes. Write both to a slave ring buffer and dump it at the end. Gate:
  two baseline runs match; a deliberate one-byte sabotage, such as skipping one shape blit,
  is detected.
  *Done, revised in A5.* The hashes are taken by the harness (`tools/state_run.py`). At every
  step's frame-wait exit (`verify_wait_stopped`) it stops the emulator, reads memory, and
  hashes the frame shown and the state.
  - **Why not in the slave:** the first version hashed in the slave with interrupts off, and
    took about 60 fields per frame. The game behaves differently with frames that long, so
    those hashes measured a perturbed game.
  - **State hash:** chip `$1000`–`$80000` plus the image's data parts (`g:$1000`–`$5320`,
    `g:$1f7d0`–`$47800`).
  - **Excluded from the state hash** (`EXCLUDE`):
    - the stack below `$1000`;
    - the VBL countdown and swap at `$49d10`–`$49d1f`;
    - the two display buffers at `$53c2e`–`$674ad`;
    - the image's code;
    - real-time sound state: `$47420`–`$4743f`, the driver's channel records at
      `$49dc0`–`$49e3f`, and the channel table at `g:$7080`–`$70bf`.
  B7 below documents the current driver exclusions, including the MIDI track and synth
  records; those are asynchronous sound state, not game timers.
  - **Entropy pinned:** VERIFY adds 0 instead of VHPOSR to the RNG seed in `g:$1ba58`.
    `g:$19610` only waits for line 0 during hardware init.
  - **Probes**, selected by bits of `CUSTOM5`:
    - 1: work delay, one extra VBL at each step's start, before the frame is published;
    - 2: one extra VBL after publishing;
    - 4: skip one `g:$53d6` blit at step 150. The hook is patched in only with this bit
      (`PL_IFC5X`), because it costs 2 fields per room change.
  - **Tools:** `tools/hash_cmp.py` compares two runs step by step.

  Gate, spikes tape, steps 1–350:
  - **Two boots:** equal.
  - **Sabotage:** detected at step 150 in both hashes. It also changes the state again from
    step 289, so the effect of the missing blit persists.
  - **Delay after publishing:** equal.
  - **Work delay: not equal.** The game keeps real-time state, see B7. On tapes 1 and 5 only
    the state differs, never the pixels: the timer records at `$46ea6`–`$46eec` during the
    level-start message (steps 11–48), and the pre-shifted kid shapes at `$26400` and
    `$32000`, which are filled at other times. On tapes 3 and 4 the pixels differ too.
    Without a time pin, G3 cannot be bit-identical when frame times differ. B7 below
    now supplies the gameplay sound-completion pin; these were the unpinned results.
- **A5 Benchmark routes.** Besides the spikes route, add (a) the first guard fight in level 1,
  (b) a busy later level reached with the level-skip trainer option (CUSTOM1 bit 2), and
  (c) a stretch of standing still, the floor case. Record each route's baseline A3 histogram
  and A4 hashes in `INTERNALS.md`.
  *Done*, as VERIFY tapes (`CUSTOM4`). Steps count only gameplay polls (`g:$13de2`): the title,
  intro and interludes poll in busy loops at whatever rate time allows. Later levels come from
  the tape's `TAPE_LEVEL+n`, which writes the level-skip request `$47ab8` itself. Baselines are
  recorded in this plan instead.

  | Tape | Route | Through step |
  |---|---|---|
  | 1 | spikes (level 1) | 274 dies, 350 |
  | 3 | level 2's first guard: run left from step 45 to 84, then fire, fire, up every 10 steps; fight from step 90, the kid dies at about step 218 | 290 |
  | 4 | level 4 (palace): right from step 45 to 100, then left to 200, past an arcade guard, three room changes | 290 |
  | 5 | idle in level 1's first room | 360 |

  (a) uses level 2's guard, not level 1's: level 1's is far into the level, while level 2's is
  one room from the start.

  A3 baseline, steps 2–300, on `a500-1.5m` (`tools/timing_run.py`, `tools/frame_log.py`).
  Tapes 3 and 4 include the interlude and the level load, logged at steps 10–11:

  | Tape | Frames | Period histogram (fields × frames) | Mean period / work | Work > 4 |
  |---|---|---|---|---|
  | 1 | 301 | 4×200 5×46 6×42 7–10×11, room changes 32, 36 | 4.79 / 4.29 | 101 |
  | 3 | 355 | 4×57 5×227 6×23 7–11×46, load 23, 45 | 5.55 / 4.99 | 270 |
  | 4 | 357 | 4×151 5×109 6×20 7×48 9–10×24, load/room changes 23–42 | 5.62 / 5.03 | 177 |
  | 5 | 299 | 4×296 5×1 6×2 | 4.02 / 3.45 | 3 |

  A4 baseline hash digests (`tools/hash_cmp.py`, unchanged VERIFY build): tape 1
  `343c39cbd12a`, 3 `6d5be796a068`, 4 `c111c939510d`, 5 `3808b037eb1d`. These historical,
  unpinned digests guard timing-neutral changes only. Use the same-build pinned comparisons and new digests in B7 for optimisation gates.
  - The VERIFY hooks add a little time (frame wait copy, VBL and blitter interrupt
    counters). The shipped slave's keypad-route profile (`tmp/prof-a500`) remains the
    absolute reference.
  - The guard fight is the worst route: only 16% of its frames make 4 fields.

## B. Understanding (documented in `INTERNALS.md`; no game change)

- **B1 Buffers.** Name the screen buffers behind `$674b2`, `$674ba` and `$49d1c` and the
  buffer-id lookup `g:$1c0f6`. Establish what `g:$1bd5e` copies (40,000 bytes, called from
  draw at `g:$0baca` after layers 0 and 1), from where to where, and which later code reads
  the destination.
  *Done* (`INTERNALS.md` B1). Buffer 0 (`$49fee`) is the room background, and 1 and 2
  (`$53c2e`, `$5d86e`) are the display pair. `$674b2` is the shown one and `$674ba` the draw
  target. `$49d1c` is the buffer the VBL handler will show next. Each frame draws layers 0
  and 1 into buffer 0, copies buffer 0 over the hidden display buffer (`g:$1bd5e(0, 4)`),
  then draws the characters and layer 1 on top. Only blits read the copy's destination
  before the publish. For C2(b), the dirty rectangles are the shape blits of two frames
  earlier plus buffer 0's own changes.
- **B2 Blitter users.** List every routine that writes blitter registers or waits for the
  blitter: `$053a2`, `$053d6`, the `$1a24` flag, `btst #6,$dff002`, `BLTSIZE` writes. For
  each, record whether the CPU touches a blit's source or destination before the next blit
  starts.
  *Done* (`INTERNALS.md` B2). `g:$053a2` and `g:$053d6` are the only `BLTSIZE` writers, and
  both STOP until the blitter interrupt clears `$1a24`. Seven routines set blits up. In
  4,218 traced blits on four routes, including two room changes, the CPU never touched a
  blit's destination, or wrote its sources, before the next blit started. So C1 needs a wait
  only before blitter register writes and the swap. The same traces bound C1's own gain at
  0.16–0.28 fields per frame plus the per-blit interrupt cost, because plane blits run back
  to back.
- **B3 Tile lookup.** `g:$107d0` (C, stack arguments, about 127 calls per frame): its inputs,
  outputs and side effects, the tables it reads (`$499fc`, `g:$7b18a`, `$49a94/98`), and its
  two callers, `$108c6` and `$1099a`.
  *Done* (`INTERNALS.md` B3). It is SDLPoP's `get_tile_to_draw`: the logic and drawing are
  the DOS C code, so SDLPoP's names apply, and the section maps the routines and variables.
  Its only side effects are the two output bytes. The callers are `draw_room` (`g:$11584`),
  which this port runs every frame over 40 tiles, `load_curr_and_left_tile` and
  `load_rowbelow`, giving 126 lookups per frame. Half of them repeat the previous column's
  lookup.
- **B4 Overrun frames.** Give `profile_run.py` per-frame call trees, split at the frame marks.
  Compare 4-field frames with 5–9-field frames on every route, and list what grows: in the
  death, layer and tile draw double and the shape blits rise from 43 to 89.
  *Done* (`INTERNALS.md` B4, `tools/frame_profile.py`). Two corrections:
  - The game's frame time is 5 fields while the kid's sword is drawn (`g:$1bc60`, SDLPoP's
    `fight_speed`). On tape 3 that is from step 91, so most of the guard route is on time:
    172 of 212 sword-out frames make 5 fields. G1 now says so.
  - Tapes 3 and 4 open with 52 level-start frames (`g:$0ae38`). There the palette fade
    `g:$1b666` takes 2.6–2.75 fields per frame in soft float.

  In late gameplay frames, what grows is drawing the back and fore tables, by 1.0–1.5
  fields: `g:$1173e` → `g:$1c29c` → `g:$05686`. Logic grows by only 0.1–0.3, and the copy
  stays the same.
- **B5 Room change.** Break `g:$0aba0` down: `$0bafa` full-room tile draw (50%), `$0f3e2`
  (13%), and the parts that are loading or decompression rather than drawing.
  *Done* (`INTERNALS.md` B5). There is no loading or decompression.
  - `g:$0aba0` (redraw_screen, 29–38 fields of a 33–42-field frame) splits into:
    - `g:$0bafa` `draw_tables` into buffer 0: 19–26 fields. Two thirds of that is per-shape
      CPU work (clipping, the image lookup, plane pointers, plane blit setup), and a third is
      STOP waits.
    - `g:$0f3e2` redraw_room, which queues every tile's pieces: 5 fields.
    - The ordinary frame: 4–5.6.
    - Clears: 1.
  - Before it, the frame clears and shows a blank buffer: 2.9 fields.

  This also corrects two labels: B1's "layers" are SDLPoP's back, mid, fore and wipe tables,
  and `g:$1bec8` is `draw_rect`.
- **B6 Bus budget.** From the DMA records, the free chip-bus slots per frame on the A500,
  with code running from slow RAM, which shares the chip bus. This is the ceiling on what
  overlapping blits with CPU work (C1, C2) can win.
  *Done* (`INTERNALS.md` B6, `tools/bus_budget.py`).
  - **Slot shares:** 23.5–28% free (0.94 fields per 4-field frame on the spikes route),
    CPU 32–35%, blitter 7–15%, bitplanes 28%.
  - **Inside a blit:** almost nothing is free.
  - **Blit beside the CPU:** it gets only the 29–31% of slots that are free while the CPU
    runs, which is 0.40–0.50 of its own speed.
  - **C1:** at most 0.11–0.20 fields per frame, plus about 0.1 of interrupt and wake-up
    cost.
  - **C2(a):** at most about 0.04, because only 0.07–0.09 fields of CPU work separate the
    copy from its first reader.
  - **C2(b):** up to the copy's 0.8 fields.
- **B7 Real-time state.** Pin the game's view of time in VERIFY so changes in frame time
  do not change the state or pixels at a given input step. Gate: an extra work VBL leaves
  every benchmark route's hashes equal.

  *Done*, gameplay sound-completion pin (`PrinceOfPersiaVerify.s`; details in
  `INTERNALS.md`, B7). Frame waits advance a virtual PAL clock by the game's own target
  (normally 4 fields, 5 with sword drawn). Sound completion is presented to gameplay on
  that clock; the audio/MIDI driver still runs in real time. Non-gameplay sound polls use
  the real driver state, because some interludes busy-wait without another frame wait.
  This fixes the unfinished pin's stall at tape 3 step 15. `CUSTOM5` bit 3 (value 8)
  disables the pin. Normal builds contain none of these hooks.

  Same build on `a500-1.5m`, state **and** published pixels at every step:

  | Tape | Steps | Work delay (0 vs 1) | Optimisations (0 vs 16) | Hash digest |
  |---|---|---|---|---|
  | 1, spikes | 1–350 | 0 differ | 0 differ | `22f46ef1e755` |
  | 3, guard | 1–300 | 0 differ | 0 differ | `11274513ab5e` |
  | 4, palace | 1–300 | 0 differ | 0 differ | `05dbbf82ed75` |
  | 5, idle | 1–360 | 0 differ | 0 differ | `6c344ed4545c` |

  Negative controls: without the pin, tape 3 opt 8 vs 9 differs at eight steps
  (293–300), including pixels at step 293. With the pin, the skipped-blit probe
  (opt 4 through step 160) differs only at step 150, in both state and pixels.

  Fresh A3 baselines with the pin and optimisations enabled (opt 0, 4000 fields,
  log steps 2–300):

  | Tape | Mean work (fields) | On target |
  |---|---|---|
  | 1 | 2.85 | 282/301 |
  | 3 | 3.66 | 302/355 |
  | 4 | 3.72 | 265/357 |
  | 5 | 2.08 | 299/299 |

  Tape 1 room changes remain 27/30 fields. These are pinned correctness-route
  baselines; earlier tape 3/4 timings used opt 8 and remain historical comparisons.

  The hashes exclude only the documented asynchronous driver/display state, stack and
  patched code; the sound request queue, shape caches and gameplay state remain checked.
  Sound durations are measured from real driver completion, not a synthetic audio engine:
  this establishes the B7 gate on the four PAL routes, not arbitrary duration boundaries
  or other machines. D1 and new-route gates remain required.

## C. Optimisations

Each one is a slave patch for version 1 (UK; also used for 1b), switchable for A/B at first
and then always on. Each must pass A4 (G3, under B7's time pin) on all routes, and is kept
only if A3 shows a gain.
Expected gains are fields per frame of CPU time, before bus contention.

- **C1 Deferred blitter waits.** Replace "start the blit, then STOP until the blitter
  interrupt" in `$053a2` and `$053d6` with "wait for the previous blit before touching the
  blitter, start, return". Add a wait wherever B2 found the CPU touching blit memory, and before
  the display swap. Turn off the per-blit blitter interrupt. Expected 0.3–0.5 of the 0.95
  STOP fields, plus most of the per-blit interrupt cost. (B6: at most 0.11–0.20 plus about
  0.1 of interrupt cost, unless C5 reorders the work.)
  *Done*, synchronous polling (`PrinceOfPersiaFast.s`). Both `$053a2` and `$053d6`
  start the blit, poll completion and clear `INTREQ.BLIT` twice. Interrupt setup and the
  partial-copy exit leave `INTENA.BLIT` disabled. The `$053dc` continuation used by the
  VERIFY sabotage probe also polls. SR and the assembler entry's registers are preserved.
  The last plane still finishes before return: no pending blit reaches another register
  write, in-place flip, scratch CPU copy or display swap. Deferring that final wait remains
  a separate possible optimisation; this step removes the interrupt cost.

  | Tape | Work (mean fields) | On target |
  |---|---|---|
  | 1 | 2.98 → 2.85 | 273 → 282 of 301 |
  | 3 | 3.79 → 3.65 | 298 → 302 of 355 |
  | 4 | 3.90 → 3.71 | 258 → 265 of 357 |

  Tape 1 room changes: 29/32 → 27/30 fields. A4: 0 differ on tape 1 (300 steps) and
  tape 5 (360), same build, opt 16 vs 0. Timing uses opt 0 for tape 1 and opt 8 for
  tapes 3 and 4. The frame log's `blits` field now counts only incidental BLIT acknowledgements
  during other level-3 interrupts; use DMA traces to count blits. G1/G2 are not yet met;
  B7 now passes its stated PAL route gate; the D1 machine matrix remains open.

  Late profile, tape 1 step 250 over 300 fields: `$11904` falls from 1.21/3.15 to
  1.04/2.78 inclusive fields per on-time/5–9-field frame; `$053d6` from 0.54/1.31 to
  0.38/0.95; the whole level-3 handler from 0.33/0.60 to 0.14/0.09. The faster run
  contains 53/13 frames in those groups versus 50/14 before, so these are descriptive
  profile means rather than matched-frame deltas. The sabotage probe (opt 4, 160 steps)
  still detects both state and pixel corruption at step 150, with no earlier differences.
- **C2 The full-screen copy.** Depending on B1:
  - (a) Chain its six `$1000`-word blits from the blitter interrupt, so the 40 KB copy runs
    behind the CPU until the first reader waits for it. Expected 0.3–0.5. (B6: at most
    about 0.04.)
  - (b) Copy only the regions that changed, or skip the copy when its source is unchanged.
    Expected up to 0.7.

  Pick (b) only if B1 shows the dirty regions are cheap to track exactly.

  *Done*, (b) (`PrinceOfPersiaFast.s`). Each display buffer keeps 25 eight-line bands with a
  span of word columns that may differ from buffer 0. The shape blitter (`$05686`, once per
  shape from its geometry variables), the rectangle fill and copy (`$199e0`, `$19894`), the
  clear (`$19802`), the copy (`$1975c`) and the picture draw (`$1bf76`) mark what they write;
  the gameplay copy (`$094e4`) then blits only the dirty bands, polling instead of the STOP
  wait. Copies outside the gameplay frame dirty everything first. Same builds, off and on
  (tapes 3 and 4 without B7's pin):
  - tape 1: work 4.04 → 3.45 fields mean, 232 → 239 of 301 on target (from 200 with neither);
  - tape 3: work 5.00 → 4.19 with C3, 278 → 293 of 355 on target;
  - tape 4: work 5.04 → 4.37 with C3, 178 → 239 of 357 on target;
  - A4 identical on tapes 1 (300 steps) and 5 (360 steps) with C3;
  - the room change got 1–2 fields slower (33 and 36 → 34 and 38), from marking every
    redraw shape; C6 deals with it.
- **C3 Tile lookup in assembler.** Register arguments and the same results as `$107d0`,
  called from patched `$108c6` and `$1099a`. Expected 0.49 → about 0.15.

  *Done* (`PrinceOfPersiaFast.s`). `get_tile_to_draw` (`$107d0`) is an assembler core with
  register arguments behind a stack-argument entry for its other callers;
  `load_curr_and_left_tile` (`$108c6`) calls the core directly; `get_room_address` (`$11b96`)
  is rewritten too. Reusing the previous column's tile as `tile_left` is left out for now: it
  needs proof that nothing between columns changes the room arrays. Tape 1, same build with `CUSTOM5` bit 4 (`OPT_ORIGINAL`) off and on:
  - work 4.30 → 4.04 fields mean (median 3.74 → 3.49);
  - 200 → 232 of 301 frames on target;
  - A4 identical over 300 steps (state and pixels).
- **C4 Logic hot spots.** Rewrite the self-time leaders of `$1156a` (`$11584`, `$108c6`,
  `$0f730`) and `$0c0ac` (`$14e8c`, `$12bea`), in the order B4 ranks them by growth in overrun
  frames. Compiled-C overhead (`link`, `movem`, reloaded stack arguments) is the target; the
  algorithms stay.

  *Done*, first part (`PrinceOfPersiaFast.s`):
  - `load_leftroom` (`$10942`) and `load_rowbelow` (`$1099a`) in assembler on C3's core;
  - in `check_collisions` (`$14e8c`), `get_right_wall_xpos` (`$14fe6`) follows
    `get_left_wall_xpos` with the same arguments and only register code between, so it reuses
    that call's `get_tile` (`$12bea`) result instead of repeating it (`wall_type` writes
    nothing).

  With C2 and C3, tapes 3 and 4 without the pin:

  | Tape | Work (mean fields) | On target |
  |---|---|---|
  | 1 | 3.45 → 3.20 | 239 → 260 of 301 |
  | 3 | 4.19 → 4.00 | 293 → 295 of 355 |
  | 4 | 4.37 → 4.17 | 239 → 250 of 357 |

  A4 is identical on tapes 1 and 5. Left for later: `get_tile` itself and `draw_tile`'s
  counter tests (about 0.04).
- **C5 Draw path.** In `$11904` → `$1c29c` → `$1cb94` → `$05686`, remove repeated per-shape
  setup. Batch shape blits so C1's deferred wait overlaps the next shape's setup. Expected:
  most of the death frames' extra 1 field.

  *Done*, first part (`PrinceOfPersiaFast.s`): the shape library's C routines between the
  image draw and the blitter routine, in assembler with the same memory writes and results:
  - the kid's image remap (`$0be6c`, a table lookup instead of a range chain), the image
    address (`$1dd9a`, `$1dd14`), the header decode (`$1c802`) and the table index (`$1c694`);
  - the tag parser (`$1c29c`), with the tables whose images go on in a second or third table;
  - the clip (`$1c8d6`) and the draw (`$1cb94` with `$1cc8c`, `$1cdba`, `$1ce74`). The in-place
    image flip (`$055ca`, `$0562c`), the scratch copy (`$05432`), tag 6 (`$055a6`) and the shape
    blitter (`$05686`) are still the original code.

  With C2–C4, tapes 3 and 4 without the pin:

  | Tape | Work (mean fields) | On target |
  |---|---|---|
  | 1 | 3.20 → 3.02 | 260 → 273 of 301 |
  | 3 | 4.00 → 3.82 | 295 → 298 of 355 |
  | 4 | 4.17 → 3.94 | 250 → 257 of 357 |

  The room change on tape 1 went from 34 and 38 to 30 and 33 fields. A4 is identical on
  tapes 1 and 5.

  *Done*, register-argument entry: `$11904` now sets the common drawing modes directly
  and calls the shared `fast_draw_shape_core` with table, image and position in registers.
  The general tag-list entry remains for other callers; unusual modes retain the original
  diagnostics. A4: 0 differ on tape 1 (300 steps) and tape 5 (360), same build, opt 16 vs 0.

  | Tape | Work (mean fields) | On target |
  |---|---|---|
  | 1 | 3.02 → 2.99 | 273 → 273 of 301 |
  | 3 | 3.82 → 3.80 | 298 → 298 of 355 |
  | 4 | 3.94 → 3.90 | 257 → 258 of 357 |

  Tape 1's room changes are 29 and 32 fields. Tapes 3 and 4 use opt 8 (no time pin).
  The pre-change late profile (step 250, 300 fields) measured `$11904` at 1.25 / 3.24
  inclusive fields in on-time / 5–9-field frames; `$053d6` at 0.55 / 1.30 and the whole
  level-3 interrupt handler at 0.33 / 0.60 (including VBL, not just blits).

  *Done*, direct calls: the shared core calls `fast_clip` and `fast_draw` directly,
  removing the game-entry jumps and relocation-base setup. A4: 0 differ on tape 1 (300)
  and tape 5 (360), same build, opt 16 vs 0. Mean work: tape 1 2.988 → 2.984 fields,
  tape 3 3.800 → 3.795, tape 4 3.901 → 3.897. On-target counts remain 273/301,
  298/355 and 258/357; tape 1 room changes remain 29 and 32 fields.
  C5 is complete; the remaining blit-start work belongs to C1.
- **C6 Room change.** Apply C1, C3 and C5 to `$0aba0`, then deal with what B5 shows is left,
  such as redundant clears or a double full-room draw. Target G2.

  *Done*, first pass (`PrinceOfPersiaFast.s`): C1/C3/C5 already cover the room path;
  the remaining measured overhead is reduced by marking both display buffers dirty once
  around the full-room `draw_tables`, filling full-width rectangles with D-only DMA,
  rewriting the back/foreground table append routines (`$10c9a`, `$10d52`), simplifying
  the unchanged RNG (`$1b948`), and reusing `$11904`'s first image lookup in the draw core.
  The blank-screen publish/wait and every room layer remain. All blits stay synchronous.

  | Tape | Work (mean fields), before → after | On target, before → after |
  |---|---|---|
  | 1 | 2.854 → 2.797 | 282 → 283 of 301 |
  | 3 | 3.658 → 3.61 | 302 → 302 of 355 |
  | 4 | 3.716 → 3.640 | 265 → 265 of 357 |
  | 5 | 2.077 → 2.07 | 299 → 299 of 299 |

  Room transitions: tape 1 steps 123/243, 27/30 → **24/26 fields**; tape 3 step 64,
  19 → **17**; tape 4 steps 59/104/149, 37/33/26 → **34/30/23**. Step 15's interlude
  and level-start frames are separate. A3 uses 4000 fields, steps 2–300, opt 0 on all
  routes under B7's pin. A4, same final build opt 16 vs 0: **0 differ** on tapes
  1 (350 steps), 3 (300), 4 (300), and 5 (360). Tape 3 opt 0 vs 1 also has 0 differ;
  the opt 4 sabotage probe still detects only step 150 (state and pixels).

  The first room's profile falls from 26.54 to 23.31 fields in `$0aba0`, with
  `draw_tables` 16.39 → 14.33 and `redraw_room` 4.92 → 4.50. An unshifted-shape
  experiment removing redundant source DMA passed A4 but increased work; it was removed.
  **C6/G2 remains open:** none of the measured transitions yet reaches 16 fields.
  The full-room shape drawing and table construction need further work; no redundant
  full-room pass has been established safe to remove. See `INTERNALS.md` for the profile.
  *Done*, rectangle batching: `$1bec8` now validates, marks and sets up a rectangle
  once for its five planes. A constant A input plus edge masks clears or sets a partial
  rectangle with one C/D blit per plane, replacing the old source reads and the second
  pass for set bits. True full-width fills remain D-only. During the synchronous
  full-room `draw_tables` call, BLITHOG gives the blitter priority over the polling CPU;
  the previous priority bit is restored on return. No waits are deferred.

  | Tape | Work (mean fields), first pass → now | On target, first pass → now |
  |---|---|---|
  | 1 | 2.797 → 2.772 | 283 → 286 of 301 |
  | 3 | 3.61 → 3.595 | 302 → 302 of 355 |
  | 4 | 3.640 → 3.562 | 265 → 266 of 357 |
  | 5 | 2.07 → 2.065 | 299 → 299 of 299 |

  Room changes are now **23/25 fields** on tape 1, **17** on tape 3, and
  **27/23/21** on tape 4. All four same-build opt 16 vs 0 A4 gates still show 0 differ
  (350/300/300/360 steps), and tape 3 opt 1 matches opt 0 for 300 steps.
  A3 remains opt 0, 4000 fields, steps 2–300. The palace
  transition's rectangle-fill profile falls from 9.70 to 2.63 fields. Nine direct
  emulator edge-mask tests also pass against a per-pixel oracle. C6/G2 remains open;
  these gains do not yet meet the 16-field limit. D1 remains unvalidated.

  *Done*, table-entry decoding: `$1173e` decodes back/foreground entries directly
  into the register interface shared with `$11904`, preserving signed coordinates,
  mode writeback and the original fallback. The draw core is entered by a tail call.

  | Tape | Work (mean fields), before → now | On target, before → now |
  |---|---|---|
  | 1 | 2.772 → 2.759 | 286 → 286 of 301 |
  | 3 | 3.595 → 3.588 | 302 → 302 of 355 |
  | 4 | 3.562 → 3.546 | 266 → 267 of 357 |
  | 5 | 2.065 → 2.061 | 299 → 299 of 299 |

  Transitions: tape 1 **23/25 fields**, tape 3 **16**, tape 4 **26/23/20**.
  Tape 3 now meets G2; C6/G2 remains open on tapes 1 and 4. Same-build opt 16/0
  A4 comparisons show **0 differ** for 350/300/300/360 steps. Tape 3 opt 1 matches
  opt 0; sabotage still differs only at step 150, in state and pixels. A3 uses
  4000 fields, steps 2–300, opt 0. The palace `draw_tables` profile falls from
  15.51 to 15.19 fields. Mask-only and deferred-setup direct-image experiments were
  removed because they provided no net timing benefit. D1 remains unvalidated.

  *Accepted stopping point (2026-10-15):* the user accepts G2 at current
  performance and closes further room-change optimisation. The last recorded
  transition periods are 23/25 fields on tape 1, 16 on tape 3, and 26/23/20 on
  tape 4. The original 16-field target remains unmet on tapes 1 and 4; acceptance
  waives that remaining target rather than claiming a new timing result. C6 and
  G2 are closed. Earlier open-status notes above describe intermediate results.

- **C7 Gate after each step.** Run all A5 routes for A3 and A4 and the C-step's own profile,
  and record the result in `INTERNALS.md`. Stop when G1 and G2 hold; don't optimise past
  the goal.

### G1 gameplay acceptance

*Done.* The C2/C3/C4/C5 follow-up in `PrinceOfPersiaFast.s` reaches G1 on all four
PAL `a500-1.5m` routes. It reuses eligible foreground setup, avoids unchanged
foreground blits and inactive tile lookups, tracks dirty word runs in 16-line
bands, gives synchronous frame blits priority, and reduces collision, image,
flip and character-copy overhead. All patches remain version-1-only and opt 16
turns them off. No last-plane wait is deferred.

A3 uses 4000 fields, opt 0 with B7's pin. Gameplay windows are steps 2–300 on
1/5 and 16–300 on 3/4 (after the requested level/interlude); room-transition
steps 123/243, 64, and 59/104/149 respectively belong to G2. Both log entries
at each transition step are excluded. These same windows are used below for
the C6 stopping-point baseline and the final build.

| Tape | Gameplay mean work, before → after (fields) | On target, before → after | Final on target | Worst excess over own target |
|---|---|---|---|---|
| 1, spikes | 2.627 → 1.877 | 284 → 293 of 297 | 98.7% | 1 field |
| 3, guard | 3.189 → 2.433 | 259 → 271 of 284 | 95.4% | 1 field |
| 4, palace | 2.981 → 2.187 | 222 → 282 of 282 | 100% | 0 |
| 5, climb | 2.061 → 1.523 | 299 → 299 of 299 | 100% | 0 |

The final spike-death maximum is 4.981 fields of work (step 270), within the
five-field ceiling. A4, same final build opt 16 versus 0: **0 differ** on all
four routes, for 350/300/300/360 steps. Tape 3 opt 1 also matches opt 0 for
300 steps. Tape 1 opt 4 differs only at step 150, in state and pixels, over
175 steps. No hash exclusions or game frame targets changed. `INTERNALS.md`
records implementation constraints, profiles and matching digests.

G1 is complete. G2 is accepted by the user at the C6 stopping point and closed;
D1 is complete under the agreed scope recorded below; D2–D4 remain open. The G1/G2
acceptance is for the pinned PAL benchmark routes; real hardware remains a separate gate.

## D. Validation and release

- **D1 Machine matrix (G4).** `a500-1.5m`, A500 + 1 MB fast RAM, `a1200`, `a1200-fast`, and
  `a1200-030`/`-040`/`-060` with the CACHE options. Deferred blitter waits must not race with
  data caches on chip memory. Also NTSC: 15 fps, so a budget of 3.33 PAL-field-equivalents per
  frame; report it separately.

  **Done (2026-10-15):** the user narrowed the remaining acceptance to 68040 and
  68060: if both pass, D1 is complete. Both passed with the unchanged G1 slave.
  With WHDLoad `CACHE` (instruction cache enabled), each CPU passed all four A4
  routes: tapes 1/3/4/5 over 350/300/300/360 steps, comparing the same build with
  CUSTOM5=16 against 0. All 2,620 frame comparisons had zero state/pixel differences.
  Separate unpinned, optimised `DCACHE` runs passed all four routes for 4,000
  emulated fields each on both CPUs, also enabling `BRANCHCACHE` on the 060.
  Cache registers were audited and final screenshots inspected. These additional
  runs are functional checks, not A4 hash comparisons or hardware timing results.
  Earlier full A4 runs also passed on A500-1.5m and stock A1200. The remaining
  original matrix cells, including 030 and NTSC, are outside the agreed closure;
  no validation is claimed for them. D1 is closed; D2–D4 remain open. See
  `INTERNALS.md` for digests, cache settings and emulator constraints.
- **D2 Other versions.** Versions 2 (US), 3 (German) and 4 (French) have different offsets
  (the slave's patch lists show a regular shift). They need the user's disk images to find
  and verify their offsets. Until then, keep the patches version-1-only.
- **D3 Real hardware.** A real A500 with 1.5 MB, plus an accelerated machine if one is
  available, run by the user.
- **D4 Release.** Slave 4.5 with ReadMe history, the default-on decision recorded (no
  option needed if G3 holds), and a contribution to JOTD following the playbook's §13.
