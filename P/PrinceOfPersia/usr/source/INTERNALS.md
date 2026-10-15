# Prince of Persia: game internals (version 1)

Findings for the A500 performance plan (`PERFORMANCE_PLAN.md`, part B). Addresses are game
addresses in the slave's patch-list numbering (`g:$xxxxx` = runtime `reloc_base - $1000 +
$xxxxx`); bare `$xxxxx` below `$80000` is chip memory, which the game uses at fixed
addresses.

## B1 Screen buffers

The game draws into five 320×200×5 bitplane buffers. Each is 40,000 bytes: five planes of
`$1f40` bytes, one after another (`g:$19bca` loads the bitplane pointers of the copper list at
`$49ce8` from one address).

| Id | Buffer | Role |
|---|---|---|
| 0 | `$49fee` | The room background (table `g:$07d0a`) |
| 1 | `$53c2e` | Display buffer |
| 2 | `$5d86e` | Display buffer |
| 3 | `*$674b2` | The shown buffer: an alias for 1 or 2 |
| 4 | `*$674ba` | The draw target: an alias for 0, 1 or 2 |

- `g:$1c0f6(id)` returns a buffer's address, and `g:$1c0a0(id)` returns its real id (ids
  3 and 4 resolve through the shown id `$674ae` and the draw-target id `$674b6`).
- `g:$1bb94(id)` sets the draw target (`$674b6`, `$674ba`) and returns the old id. Id -3 means
  "the display buffer not shown", which `g:$094cc` selects at the start of each frame, after
  counting the frame in `$46e5e`.
- `g:$1bce6(id)` publishes: the buffer becomes the shown one (`$674ae`, `$674b2`), goes into
  `$49d1c`, and `$49d18` is set. The VBL handler (`g:$1a0c2`) counts `$49d14` down every
  field. When the count reaches 0 with `$49d18` set, it clears `$49d18`, reloads the count from
  `g:$07aba`, and points the copper list at `$49d1c`. The return value is the number of
  fields the frame took. `g:$094f8` publishes the draw target. The frame wait `g:$1bd46`
  spins until `$49d18` is clear.
- The shape blitter `g:$05686` (via `$674ba`) and every other drawing routine write to the
  current draw target.
- A debug flag `g:$07d16` (toggled by `g:$1bc44`, normally 0) makes `g:$1bb94` publish and
  wait at each target change.

**The gameplay frame** (`g:$0a800` loop):
1. `g:$094cc` makes the hidden display buffer the target.
2. Logic runs: `g:$0c0ac` reads the controls, then `g:$1249e` and `g:$1156a`.
3. `g:$0ba56` draws:
   1. With buffer 0 as the target, it draws layers 0 and 1 from SDLPoP's draw tables
      (B3, B5):
      - the wipe table `$489f8`: 8-byte records tagged with a layer, drawn by
        `draw_wipes` (`g:$116fa`) as `draw_rect` fills;
      - the back (0) and fore (1) tables, with their counts in `$47d64[table]`, drawn by
        `draw_table` (`g:$116a2`) → `draw_back_fore` (`g:$1173e`). These are room pieces that change, such as gates and
      loose floors. Nothing restores buffer 0 between frames, so these draws repaint their
      own area, and buffer 0 stays a clean picture of the room as it is now.
   2. The target goes back to the hidden display buffer.
   3. `g:$094e4` = `g:$1bd5e(0, 4)` copies buffer 0 onto it. This is the 40,000-byte copy:
      `g:$1975c` does it as A→D blits of `$1000` words.
   4. The mid table (table 3: the characters and other moving objects, `g:$116a2(3)` →
      `draw_mid` `g:$117c4`) is drawn on top. Then come the layer-1 wipes and the fore
      table again, so those pieces end up in front of the characters.
4. `g:$094f8` publishes, and `g:$0950c` waits for the swap.

**What reads the copy's destination:**
- The layer-3 and layer-1 shape blits read it as the cookie-cut background, through the
  blitter's C channel.
- Display DMA reads it after the swap.

The draw paths after the copy reach the buffer only through blits; this comes from reading
the code, and A4 checks it once C2 changes the copy. The copy is there to erase what that
buffer showed two frames earlier.
- When the room changes (`$470d2` set), the frame instead does:
  1. `g:$1bd9a(4, 0)` clears the hidden buffer.
  2. A publish and a wait.
  3. `g:$0aba0(0)` redraws the room into buffer 0 tile by tile.
- At level start, `g:$092f0` copies buffer 0 to both display buffers with `g:$1bd5e(0, 1)` and
  `g:$1bd5e(0, 2)`.

**For C2:**
- (a) The copy's readers are all blits that come after it, and the first CPU access to the
  hidden buffer is the next blit. So chaining the copy from the blitter interrupt and
  waiting before the next blit is enough.
- (b) What a frame has to restore is:
  - the rectangles the layer-3 and layer-1 blits drew into that buffer two frames earlier;
  - plus the rectangles that changed in buffer 0 since then (its layer-0 and layer-1 blits).

  Both pass through `g:$05686` with a known size, so the dirty rectangles can be tracked
  exactly. The room change still needs the full copy.

## B2 Blitter users

**Original starting and waiting.**
- Only two routines write `BLTSIZE`: `g:$053a2` (C-callable, size on the stack) and
  `g:$053d6` (assembler, size in d0, SR saved in `g:$053d4`).
- Both raise the IPL to 7 and set `$1a24`. They start the blit, then `STOP #$2000` until the
  level-3 handler's blitter branch (`g:$19fc4`) clears `$1a24`, and then restore SR.
- Every blit is therefore finished before the CPU runs on. The blitter interrupt is enabled
  (`INTENA` `$a068` at `g:$19eca`) only for this.
- The game has no `btst #6,$dff002` busy waits; the slave's commented-out `blitter_1` and
  `blitter_2` are the only ones.

**C1 polling implementation.** With optimisations enabled, both start routines poll
`DMACONR` until completion and acknowledge `INTF_BLIT` twice. The assembler entry
preserves all registers and SR. Interrupt setup excludes `INTF_BLIT`, and the partial
screen copy leaves it disabled. The original `$1a24` handshake is unused. Every blit
still finishes before returning, including the final plane: all register writes, image
flips, scratch CPU copies and display swaps retain their original ordering, so no new
wait sites are needed. Overlapping the final plane with the next shape remains a possible
separate optimisation.

The optional VERIFY sabotage hook can still resume at `$053dc`, using the SR saved at
`$053d4`; that continuation enters the polling start. The frame log's `blits` field counts
interrupt acknowledgements, not starts, and is no longer a blit count with C1 enabled.
Use DMA traces for counts. The whole level-3 handler can still acknowledge a request if
a VBL arrives at blit completion, but the blit does not generate its own CPU interrupt.

**Routines that set up blits:**

| Routine | Called from | Start | Blits | Destination |
|---|---|---|---|---|
| `g:$05432` | shape draw `g:$1cb94` | `$053d6` | 6 at `$054b4`–`$05536`: the shape's planes (pointers `$67528`–`$6753c`) into scratch at `$1a28 + n×$7f0` | `$1000`–`$4fff` |
| `g:$05686` | shape draw `g:$1cb94` | `$053d6` | 5 per shape at `$0585e`–`$058fe` (one per plane, `$674ba` as C and D), or 10 at `$05982`–`$05ab8` | draw target |
| `g:$1975c` | `g:$1bd5e`, `g:$1bf76` | `$053a2` | A→D copy in `$1000`-word blits at `$197c0`/`$197dc`/`$197ea` | buffer by id |
| `g:$19802` | `g:$1bd9a`, `g:$1bf76` | `$053a2` | D-only clear or fill at `$19852`/`$1986e`/`$1987c` | buffer by id |
| `g:$19894` | rectangle copy `g:$1be18` ← `g:$09560` | `$053a2` | between buffers | buffer by id |
| `g:$199e0` | `draw_rect` `g:$1bec8` (12 callers: wipes, room clears) | `$053a2` | rectangle fill per plane at `$19b22`/`$19b4e` | buffer by id, mostly 0 |
| `g:$1960c` | start-up `g:$195f8` | `$053a2` | the first clear | |

**CPU accesses to blit memory.** `tools/blit_touch.py` reads raw traces (`tools/trace_at.py`,
VERIFY tapes). For each blit, it gathers the words its D channel wrote and its A, B and C
channels read, from the DMA records. It then looks for CPU data accesses between the blit's
start and the next one: any access to the blit's D, and writes to its sources.

| Window | Fields | Blits | Hazards |
|---|---|---|---|
| Tape 1 step 120, running | 10 | 199 | 0 |
| Tape 1 step 122, room change | 45 | 1137 | 0 |
| Tape 1 step 268, spike death | 30 | 646 | 0 |
| Tape 3 step 100, guard fight | 20 | 264 | 0 |
| Tape 4 step 60, palace | 20 | 360 | 0 |
| Tape 4 step 58, room change | 50 | 1612 | 0 |

The CPU never reads or writes the three screen buffers. Its chip accesses are the stack
below `$1000`, the game data at `$40000`–`$7ffff` outside the buffers, and the kid shape tables at
`$20000`–`$3ffff`. The CPU writes those tables, but never while a blit that reads them is
pending. So for C1, a wait is needed only before the next blitter register write and before
the display swap. The register writes start right after the call to `$053a2`/`$053d6`
returns.

**C1's ceiling.** The same traces give each blit's length and the CPU time until the next
blit starts. Deferring the wait saves min(length, CPU time) per blit, ignoring bus
contention. Most blits come in runs of 5 or 10 plane blits with little CPU work between
them, so:
- The blitter is busy 0.13–0.22 of each field.
- A deferred wait saves at most 0.04–0.07 fields per field, which is 0.16–0.28 per 4-field
  frame, plus the per-blit interrupt and wake-up cost.

That is below the plan's 0.3–0.5. C1 gains more only if the blits are reordered to overlap
real work, as C5 proposes.

## B3 Tile lookup

**What the code is.** The game logic and drawing are the DOS version's C code, compiled for
the 68000. `g:$107d0` matches SDLPoP's `get_tile_to_draw` line for line, and its callers
match `seg008.c`, so SDLPoP's names apply:

| Address | SDLPoP | Address | SDLPoP |
|---|---|---|---|
| `g:$107d0` | `get_tile_to_draw` | `$47b18` | `drawn_room` |
| `g:$108c6` | `load_curr_and_left_tile` | `$47b1c`, `$47b24` | `room_L`, `room_A` |
| `g:$1099a` | `load_rowbelow` | `$47b28`, `$47b34` | `room_B`, `room_BL` |
| `g:$10942` | `load_leftroom` | `$49a16`, `$49a1a` | `drawn_row`, `drawn_col` |
| `g:$11b96` | `get_room_address` | `$47b60`/`$47b62` | `curr_tile`, `curr_modifier` |
| `g:$11584` | `draw_room` | `$47b64`/`$47b66` | `tile_left`, `modifier_left` |
| `g:$0f730` | `draw_tile` | `$49a02` | `row_below_left_[10]` |
| `g:$0f838` | `draw_tile_aboveroom` | `$499fc` | `leftroom_[3]` |
| `g:$0e514` | `get_doorlink_timer` | `$49a94`, `$49a98` | `curr_room_tiles`, `curr_room_modif` |

**`g:$107d0(room, column, row, *tiletype, *modifier, tile_room0)`:**
- **Arguments:** six longs on the stack. The result is returned in d0 and stored through
  the two pointers.
- **Normal case:** `tilepos = g:$0718a[row] + column`, where the table holds 0, 10, 20.
  - `*tiletype = curr_room_tiles[tilepos] & $1f`
  - `*modifier = curr_room_modif[tilepos]`
- **Column -1:** reads the left room's cached column, `leftroom_[row]` (`$499fc`, filled by
  `g:$10942`).
- **Room 0:** returns `tile_room0` with modifier 0.
- **Plates:** a closer (6) whose door-link timer is above 1 becomes stuck (5). An opener
  (15) in the same state becomes floor (1) with modifier 0. The timer is
  `doorlink2_ad[modifier] & $1f`, read through `$49aa0`.
- **Room argument:** used only to test for room 0. The two array pointers come from the last
  `g:$11b96(room)`: `$470de + (room-1)×30` and `$473ae + (room-1)×30`, the level's
  24-room tile and modifier arrays.
- **Side effects:** none besides the two output bytes. It reads the level arrays, `$499fc`,
  the door-link table, and the row table `g:$0718a`.

**Callers.** `draw_room` (`g:$11584`, from `g:$1156a`) runs every frame in this port. In the
DOS game it runs only on a full redraw. Each run:
- Visits the room's 30 tiles and the 10 of the bottom row of the room above.
- For each, calls `load_curr_and_left_tile` (2 lookups: the tile and its left neighbour),
  then `draw_tile` or `draw_tile_aboveroom`, which queue pieces on the draw lists that
  `g:$0ba56` blits (B1).
- Per row, `load_rowbelow` adds 10 lookups, and `load_leftroom` adds 3 twice.

That is 40 × 2 + 4 × 10 + 2 × 3 = 126 lookups per frame; the profile counts 128.7.
`g:$10610` (`g:$105b6`) makes the rest.

**Cost per frame** (spikes route profile, own time):

| Routine | Fields |
|---|---|
| `g:$107d0` | 0.49 |
| `g:$108c6` | 0.17 |
| `g:$11b96` | 0.14 (57.6 calls) |
| `g:$1099a` | 0.06 |

**For C3:**
- Half of `load_curr_and_left_tile`'s lookups repeat work: `tile_left` at column c is
  column c-1's `curr_tile`, except at column 0.
- `get_room_address` recomputes two pointers that change only with the room.
- An assembler `get_tile_to_draw` with register arguments, called from patched `g:$108c6`
  and `g:$1099a`, can produce exactly the same bytes. Reusing the previous column's result
  roughly halves the lookups as well.

## B4 Overrun frames

`tools/frame_profile.py` traces a VERIFY tape and splits the trace into frames at the
frame-wait exit. Per frame it keeps the period, the work and every routine's inclusive time.
The runs cover tapes 1, 3, 4 and 5 from step 2: 1450, 1900, 2000 and 1300 fields.

**The game's own frame time.**
- Each frame, the loop calls `g:$1bc60` with 12, or 10 when the kid's sword is drawn
  (`Kid.sword`, `$479bc` = 2). The call is at `g:$0a82a`.
- `g:$1bc60` sets `g:$07aba = int(50 / fps + 0.5)`, which is 4 or 5 fields. These are
  SDLPoP's `base_speed` and `fight_speed`.
- So a frame is on time at 5 fields while the sword is out. On tape 3 that is from step 91
  to the end; tapes 1, 4 and 5 stay at 4.

**Level start.** On a later level, the first 52 steps run inside `g:$0ae38`, with its own
frame loop at `g:$0b882`. This covers the level-start message.
- These frames take 5–10 fields; their work averages 5.7.
- `g:$1b666`, the palette fade, takes 2.6–2.75 fields per frame. It computes the colours with
  the soft-float library (`g:$1efac`, `g:$1ed12`, `g:$1f0ca`; 0.7–0.8 fields).
- The rest is an ordinary gameplay frame.

**Gameplay frames.** Inclusive fields per frame, on-time frames against late ones:

| Tape | On time | Late | Work | Draw tables `$116a2` | Shapes `$1c29c` | of which blits `$05686` | Logic `$1156a` | Copy `$094e4` | Interrupts |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 197 | 101 | 3.56 → 4.90 | 0.69 → 1.73 | 0.61 → 1.52 | 0.32 → 0.78 | 1.19 → 1.32 | 0.80 → 0.88 | 0.20 → 0.38 |
| 3, sword out (target 5) | 172 | 40 | | 0.99 → 2.55 | 0.85 → 2.20 | 0.49 → 1.03 | | | |
| 3, before the sword (target 4) | 28 | 8 | | | | | | | |
| 4 | 107 | 138 | 3.58 → 5.13 | 0.70 → 1.85 | 0.61 → 1.62 | 0.33 → 0.79 | 1.14 → 1.43 | 0.77 → 0.89 | 0.18 → 0.36 |
| 5 | 315 | 8 | 3.38 → 3.98 | 0.52 → 1.37 | 0.45 → 1.19 | | 0.97 → 1.66 (`draw_room`) | | |

**What grows** is the drawing of the back and fore tables: `draw_table(0)` and
`draw_table(1)` (`g:$1173e`), then the image draw `g:$11904` → `g:$1c29c` → `g:$1cb94`
→ `g:$05686`.
- These redraw animated and changed tiles, with their wipes: loose floors, spikes, gates, the
  spike death, the room's edge.
- The draw grows by 1.0–1.5 fields; about 40% of that is shape blits and their STOP waits.
- In the guard fight, the mid table (`g:$117c4`, the two characters) grows as well, by about
  0.4.
- Logic grows 0.1–0.3. The guard's AI accounts for the growth on tape 3: `g:$11fcc`,
  `g:$12bea`, `g:$0c248`.
- The full-screen copy is the same in every frame. It grows only by the interrupts that land
  inside it, and the interrupts grow with the extra field.

**For C:**
- A late frame does 1.3–1.6 fields more work than an on-time one, and an on-time frame
  leaves only about 0.45 fields spare.
- C5 (the draw path) is where late frames can be fixed. C2 and C3 take a fixed 0.5–0.8 off
  every frame, which makes the room C5 needs.
- The palette fade is a separate fix for the level-start frames.

## B5 Room change

The room-change frame takes the `$470d2` branch of the frame loop. The measurements are
from raw traces (`tools/trace_at.py`) at tape 1 step 122 and tape 4 step 58, timed by the PCs
of the call sites.

| Part | Tape 1 | Tape 4 |
|---|---|---|
| Frame logic up to the room check | 1.1 | 1.3 |
| `g:$1bd9a(4, 0)`: clear the hidden buffer | 0.9 | 0.8 |
| Publish that blank buffer and wait for it | 2.0 | 1.8 |
| **`g:$0aba0`, redraw_screen:** | 29.0 | 37.7 |
| — palace colours (`g:$0c6e0`, levels flagged in `g:$06350`) and `draw_rect(rect_top)` clearing buffer 0's room area (`g:$1bec8`) | ~1 | 1.2 |
| — `g:$0f3e2`, redraw_room: `draw_room` in full-redraw mode (`g:$064c4` = 1, `g:$0f5e4`), with every tile's nine `draw_tile` parts queued (`g:$0f6be`), plus `g:$1249e`, `g:$132f0`, `g:$0e47e` | 4.9 | 5.0 |
| — `g:$0bafa`, `draw_tables` into buffer 0: wipes 0, back, mid, wipes 1, fore | 19.0 | 25.9 |
| — the ordinary frame: logic (`g:$1249e`, `g:$1156a`), then `g:$0ba56` | 4.0 | 5.6 |
| **Whole frame** | 33 | 42 |

All figures are in fields.

The screen stays blank for the whole redraw: that blank buffer is what is shown.

**Where `draw_tables` goes.** Tape 1 window, image draw `g:$1c29c`, 20.2 fields inclusive:

| Routine | Share | What it does |
|---|---|---|
| `g:$05686` | 44% | Shape blits; STOP waits in `g:$053d6` are 34% |
| `g:$1c694` → `g:$1c802`, `g:$1dd14` | 13% | Image table lookup |
| `g:$1c29c` own | 9% | |
| `g:$1c8d6` | 7% | Clip test |
| `g:$1ce74` | 6.5% | Plane source pointers `$67528`–`$6753c`: per plane, the image data or the blank plane at `$49c8`, from the plane mask `$67509` |
| `g:$1cc8c` | 5.7% | Clip setup |
| `g:$05432` | 4% | The six scratch blits |

**No loading or decompression.** The room change reads no disk and calls no unpacker: the
level is already in memory. All of it is drawing (draw tables 66%) and building the tables
(17%).

**For C6:**
- Most of the target is in `draw_tables`. Of that, two thirds is the CPU's per-shape work:
  clipping, the table lookup, choosing the plane pointers, and setting up five plane blits
  per shape. The
  other third is blitter waits.
- A full-room path can set up once per tile rather than per piece, so C5's setup removal
  applies to it directly.
- C1 helps the waits only a little (B6).
- The blank-screen publish and wait (2 fields) is visible behaviour and stays.
- To reach 16 fields, `draw_tables` has to go from 19–26 fields to about 8–14, and
  redraw_room's 5 fields have to shrink as well.

### C6 first pass: room-transition implementation

The C1/C3/C5 replacements already run under `$0aba0`. A new matched tape-1 profile
(start at step 120, 100 fields, PAL A500) shows the first room frame:

| Part, inclusive fields | Before C6 | After |
|---|---:|---:|
| Whole frame | 27.00 | 24.00 |
| `$0aba0`, redraw_screen | 26.54 | 23.31 |
| `$0bafa`, draw_tables | 16.39 | 14.33 |
| `$0f3e2`, redraw_room | 4.92 | 4.50 |
| `$05686`, shape blitter including dirty tracking | 8.03 | 6.67 |
| `$053d6`, blit start/wait | 5.02 | 4.79 |
| `$199e0`, rectangle fill | 1.93 | 1.16 |
| `$1b948`, random | 1.36 | 1.13 |

These are nested totals and must not be added. The full-room dirty marker removes
per-shape span work only while `$0aba0` calls `$0bafa`: buffer 0 is the drawing target
there, and both display buffers are already wholly dirty. Ordinary frame tracking
resumes before `$0ba56`. No draw is omitted and the blank-screen publish/wait remains.

Full-width fills (`x=0`, width 320, stride 20 words, height 1–1024) use D-only DMA,
minterm zero or one; the original uses old-plane reads even though no partial edge
requires them. Other rectangles retain the original implementation. Synchronous waits
still finish each blit and clear BLIT requests; no new outstanding-blit hazards arise.

The two table append routines share register code while preserving all table bytes,
counts, return values and overflow diagnostics. The RNG still advances
`seed = seed * 0x343fd + 0x269ec3` modulo 2^32 and returns the upper word modulo
`max+1` (or the upper word for max 65535). Two multiplies and word additions replace
three multiplies; power-of-two ranges use a mask. Unusual ranges retain the original.
The table renderer also supplies its already-looked-up first image to the shared draw
core. It still remaps the table/id, decodes the header, clips, flips, updates scratch
state and draws chained images normally; out-of-range cases retain get_frame's checks.

Incremental tape-1 timings: dirty marking/full-width fills gave 25/28 fields;
table construction/RNG gave 25/27; first-image reuse gave 24/26. An unshifted shape
DMA specialization was pixel-correct but made the second transition's work about
0.26 fields slower than the first stage, so it was removed.

Final A4 uses the same build with opt 16 and opt 0, under B7's pin, with no added
hash exclusions. All state and pixel comparisons pass:

| Tape | Steps | Matching digest |
|---|---|---|
| 1 | 1–350 | fb50a430cecc |
| 3 | 1–300 | c9744de68615 |
| 4 | 1–300 | f3f71cce713c |
| 5 | 1–360 | 39d7092fa1dd |

The sabotage negative control (tape 1, opt 4, 160 steps) still detects exactly step
150 in both state and pixels, with no earlier differences. Tape 3 with opt 1
(work delay) also matches opt 0 for all 300 steps, digest `c9744de68615`.

G2 is still open: room changes are 24/26 fields on tape 1, 17 on tape 3, and
34/30/23 on tape 4. The remaining first-transition costs include 14.33 fields in
full-room draw_tables (6.67 in shape blits), 4.50 building the room tables, and
2.37 in the ordinary draw/copy pass. There is no proof that another full-room pass
or layer can be dropped without changing pixels/state. G1 and the D1 machine matrix
also remain open.

### C6 rectangle batching and scoped blitter priority

The first pass's palace trace (tape 4, from step 56 over 100 fields) exposed
9.70 inclusive fields in `$1bec8`: about 8.60 of that in its five per-plane `$199e0`
calls. The new `fast_draw_rect` validates the rectangle and buffer selector, marks
its span once (or skips marking buffer 0 during the already-dirty full-room draw),
and sets the common blitter geometry once. It keeps five plane blits in order.

With A DMA disabled and BLTADAT set to all ones, first/last word masks provide the
rectangle's coverage. Minterm `$0a` computes `C & ~A` for a clear; `$fa` computes
`C | A` for a set. Only C/D DMA is needed, including the one-word case where both
masks apply. For exactly 320 pixels, D-only constants remain sufficient. Spanning
20 words alone is not enough: rectangles starting or ending inside the edge words
must retain their masks. Invalid selectors/rectangles retain the original diagnostics.

BLITHOG is enabled only around `$0aba0`'s full-room `$0bafa` call and restored to its
incoming value afterward. Each blit still completes synchronously and clears INTREQ;
this changes bus arbitration during polling, without introducing pending blits at
CPU accesses or display swaps. Display and audio DMA remain enabled. The D1 machine
matrix remains necessary for the usual hardware/timing checks.

| Inclusive profile, fields | First pass | Batched rectangles + priority |
|---|---:|---:|
| Palace redraw_screen | 32.70 | 26.13 |
| Palace draw_tables | 22.81 | 15.51 |
| Palace rectangle fills | 9.70 | 2.63 |
| Dungeon redraw_screen | 23.31 | 22.46 |
| Dungeon draw_tables | 14.33 | 13.70 |

The traced palace frame rounds to 33 fields before and 27 afterward; the A3 whole-run
baseline rounds the earlier frame to 34, so compare like capture methods. The route
A3 results are in the plan. Intermediate tests separated the changes: single-pass
fills alone reduced the longest palace transition to 32 fields; batching geometry
and dirty tracking reduced it to 27. Priority then reduced dungeon transitions from
24/26 to 23/25, while the palace's rounded transition periods stayed 27/23/21.

Final same-build opt 16/0 A4 comparisons, with no added exclusions:

| Tape | Steps | Matching digest |
|---|---|---|
| 1 | 1–350 | dea56a44be65 |
| 3 | 1–300 | fa5358de5de1 |
| 4 | 1–300 | 583960d4a4a2 |
| 5 | 1–360 | 669a2d2e2c31 |

Tape 3 with the added work delay (opt 1) matches opt 0 for all 300 steps as well,
digest `fa5358de5de1`; the scoped priority change does not break B7's route check.

An isolated emulator fixture calls this same `fast_draw_rect` from normal 68000
code and compares all 40,000 destination bytes against an independent per-pixel
oracle after each fill. All nine cases pass: full-screen clear/set, x=1..318 across
all 20 words, a two-word edge crossing, an aligned word, an inset single word,
bottom-right/top-left single pixels, and a large inset rectangle. Untouched pixels
are included in each comparison. The fixture and its build remain in the ignored
harness; the tested game build and its A4 exclusions are unchanged.

C6/G2 remains open. The remaining room-transition periods are 23/25 (tape 1),
17 (tape 3), and 27/23/21 (tape 4); none is at most 16. Full-room shape drawing and
room-table construction remain the next targets. G1 is also not complete: although
286/301 tape-1 frames are on target, some overruns still exceed one field.

### C6 table-entry decoding

`$1173e` now reads each eight-byte back/foreground record directly into the
register arguments of `fast_table_image_core`. This removes the intermediate
five-argument stack call and duplicate register saves around `$11904`. Byte x
components remain signed, y remains a signed word, and image/mode bytes remain
unsigned. The shared core receives a pointer to the writable mode argument, so
bit 7 is cleared in the same caller argument as before; the table record is never
modified. Unsupported table selectors and image modes retain the original paths.
The existing shape core, clipping, in-place flips, scratch copies and blits are
unchanged. The shared core tail-calls the shape core.

Tape 4's first room profile (step 56, 100 fields) changes from 27.00 to 26.00
fields overall, with `redraw_screen` 26.13 → 25.86 and `draw_tables` 15.51 → 15.19.
The old inclusive `$11904` figure is no longer directly comparable: most entries
now call the shared core without passing through that patched game entry.

Final A4, same build opt 16 versus 0, without new exclusions:

| Tape | Steps | Matching digest |
|---|---|---|
| 1 | 1–350 | 7084c9dbd4a0 |
| 3 | 1–300 | bb237507644d |
| 4 | 1–300 | 012bfa20aea2 |
| 5 | 1–360 | 195ef5d547f8 |

Tape 3 opt 1 also matches for 300 steps. Tape 1 opt 4 differs only at the deliberate
step-150 sabotage, in both state and pixels, over 175 steps. A3's exact mean work
is 2.759163/3.588381/3.545789/2.061440 fields for tapes 1/3/4/5, with
286/302/267/299 frames on target. Transition periods are 23/25, 16, and 26/23/20
fields on tapes 1, 3, and 4 respectively. Only tape 3 now meets G2; C6 remains open.

Two alternatives were measured and removed. A tag-8 mask-only renderer passed
A4 but gave no useful net gain. An aligned, unclipped direct-image path with
last-setup replay passed the first 100 palace steps but increased transition
periods to 28/24/22. Its eligibility checks and replay costs outweighed the saved
setup. An audit of 231 palace draw operations found only 22 shapes and five
rectangles whose changed bits were entirely overwritten later (including no-ops);
this is not enough evidence to remove any draw or reach G2 by that approach.

## B6 Bus budget

`tools/bus_budget.py` reads the DMA records of the B2 traces. Every slot (2 CPU cycles) has
an owner. On the A500 the code and data are in slow RAM, which sits on the chip bus, so
everything the CPU does costs chip slots.

| Window | Free | CPU | Blitter | Bitplanes | Refresh, audio, copper |
|---|---|---|---|---|---|
| Tape 1, running | 23.5% | 31.7% | 14.8% | 28.1% | 1.9% |
| Tape 1, spike death | 24.5% | 32.5% | 12.6% | 28.1% | 2.3% |
| Tape 3, guard fight | 24.3% | 32.4% | 13.3% | 28.1% | 1.9% |
| Tape 4, palace | 25.6% | 34.8% | 9.4% | 28.1% | 2.1% |
| Tape 1, room change | 26.7% | 33.7% | 9.7% | 28.1% | 1.8% |
| Tape 4, room change | 27.9% | 34.8% | 7.2% | 28.1% | 2.0% |

Per 4-field frame on the spikes route, that is 0.94 fields' worth of free slots.

**Inside a blit** (from the `BLTSIZE` write to the blit's last slot; 11–21% of all slots):
- Free slots: 0.3–0.7%, or 5–7% in the room-change tile draws, which are small.
- The blitter takes every slot the bitplanes leave.
- The CPU sits in STOP and uses no slots. If it ran, it would get only the slots the blitter
  yields: `BLTPRI` is off, so that is one slot after three denied cycles, and each one
  lengthens the blit.

**While the CPU runs outside blits:**
- The CPU uses 39–40% of all slots: one access per 4 cycles, minus the bitplane cycles.
- 29–31% of slots stay free.
- A blit left running in parallel gets only these free slots, so it runs at 0.40–0.50 of its
  own speed.

**Ceilings for C1 and C2:**
- **Contention changes the per-blit saving.** With the wait moved to the next blitter access,
  a blit saves min(its length, 0.40–0.50 × the CPU time until the next blit), not the
  uncontended min(length, gap) of B2.
  - Over the windows that is 0.11–0.20 fields per 4-field frame, plus the per-blit
    interrupt and STOP wake-up cost, which the profile puts at roughly 0.1.
  - This is C1's ceiling unless C5 reorders work so that real CPU work sits between plane
    blits.
- **C2(a), the copy chained behind the CPU:**
  - The 20,000-word A→D copy needs 40,000 blitter slots; running alone it takes about 0.8
    fields.
  - Beside the CPU it would take about 1.9 fields.
  - The CPU time between the copy and the next blit, the first one that reads its result,
    is only 0.07–0.09 fields, so the copy can hide behind at most about 0.04 fields of
    work.
  - Moving the copy earlier isn't possible: buffer 0 is final only after the frame's wipes
    and back and fore tables, and those depend on this frame's logic.
- **C2(b), copying less,** is the copy's real saving: up to its 0.8 fields per frame.

## B7 Gameplay time pin (VERIFY only)

After the existing RNG pin, the benchmark routes' remaining gameplay dependency on real
elapsed time is `check_sound_playing` (`g:$08106`). `play_next_sound` (`g:$081a0`) gates the
sound queue on it; the opening music holds the kid, and level/interlude code waits for it.
Faster or delayed frames otherwise observe a sound ending at different input steps.
The MIDI track records formerly described as game timers are driver state.

The earlier hypothesis about interrupt-posted gameplay events was incorrect: the calls
from the copper and unexpected CIA interrupt branches go to `g:$195b8`, the diagnostic
formatter, not `g:$1d5b8` or a gameplay event queue. The regular CIA-A timer-B callback
(`g:$1a6ac`) drives MIDI timing; VBL (`g:$1a0c2` → `$08f94`) updates synth envelopes, and
level 4 (`g:$1b1fe`) services sample playback. The level-6 CIA callbacks are generic timer
callbacks. The only direct beam-time reads found in game code are hardware startup and
the already-pinned RNG; the game countdown is stepped by gameplay, not a new wall clock.

`verify_snd_start` wraps `g:$0820c` and remembers the real start time. The interrupt wrappers
record the elapsed raster lines when the MIDI song and all four audio channels become
idle. An explicit game call of `stop_sounds` (`g:$080e2`) cancels the virtual sound at once;
a driver stop records its natural end. The driver keeps playing normally.

At each frame-wait exit, `verify_tick` adds `g:$7aba × 313` lines to a virtual clock. A sound
gets its virtual base at the first exit following its start; gameplay sound polls compare
the elapsed virtual time with the measured duration. An as-yet-unfinished real sound
remains playing virtually. The base avoids treating setup time within the starting frame
as a whole sound frame. This is intentionally a PAL test clock, not a replacement sound
engine or an assertion that every audio-phase boundary is invariant on every machine.

Non-gameplay polls return the driver's actual playing state. `verify_poll` already marks
whether its caller is the gameplay input loop; interludes do not advance the input tape.
This distinction is essential: tape 3's interlude at step 15 eventually waits in a tight
sound loop with no frame publication. The unfinished pin froze its virtual clock there
and never resumed gameplay. Both the guard and palace routes now complete with the pin.

The A4 state exclusions used by the harness are half-open ranges: stack below `$1000`,
saved interrupt SR `$1a22`–`$1a24`, MIDI player/tracks `$46e66`–`$46f42`, synth voices and
programs `$46f4e`–`$470ce`, sound state `$47420`–`$47440`, VBL/swap `$49d10`–`$49d20`,
channel records `$49dc0`–`$49e40`, display buffers `$53c2e`–`$674ae` (hashed separately),
image code `g:$5320`–`$1f7d0`, and the channel table `g:$7080`–`$70c0`. In particular,
`$46f42`–`$46f4e` (sound enable, queued sound, current sound) stays in the state hash, as do
both pre-shifted shape caches. No exclusions were widened to pass B7.

The frame log now has ten-byte entries `(step, period, work, blits, target)` so on-target
counts use each frame's actual target, including sword-out frames. `CUSTOM5=8` restores
real-time sound answers; `0` is pinned and optimised, `1` adds a work delay, and `16`
selects the original drawing path under the same pin. The all-route results and new
baseline digests are in `PERFORMANCE_PLAN.md`, B7. D1 must still test other CPUs and NTSC.

## C5 Register arguments in the draw path

`g:$11904` now decodes the common drawing modes straight into the shape library's tag
state and passes table, image and position in d2–d5 to `fast_draw_shape_core`. The tag-list
entry still serves other callers. Both entries use the same tag reset and draw core, which calls `fast_clip` and
`fast_draw` directly;
unused tag colour words retain their original values. The wrapper preserves the original
horizontal-flip adjustment, including clearing bit 7 in the caller's mode argument, and
falls back to the original diagnostics for unusual modes or multidimensional tables.

Before this change, tape 1 from step 250 over 300 traced fields had 50 on-time and 14
5–9-field frames. Inclusive time in `g:$11904` was 1.25 / 3.24 fields per frame in those
groups; `g:$053d6` was 0.55 / 1.30, and the whole level-3 handler was 0.33 / 0.60.
The handler figures include VBL work, not just blitter interrupts.

After completing C5, the same late window measured `g:$11904` at 1.21 / 3.15 fields
and `g:$053d6` at 0.54 / 1.31. With C1 polling, these became 1.04 / 2.78 and
0.38 / 0.95; the whole level-3 handler fell from 0.329 / 0.604 to 0.135 / 0.087.
The faster trace contains 53 on-time and 13 overrunning frames instead of 50 and 14,
so the group means are not a matched-frame comparison. Full-route timing and the
same-build A4 results are recorded in `PERFORMANCE_PLAN.md`, C1 and C5.


## G1 gameplay acceptance follow-up

The final C2/C3/C4/C5 follow-up meets G1 on the four pinned PAL A500 benchmark
routes. The gameplay windows and before/after counts are in `PERFORMANCE_PLAN.md`.
The complete A3 log window (steps 2–300, including transitions and interlude) has
mean work 2.005732/2.906385/2.829767/1.522989 fields and on-target counts
295/301, 314/355, 327/357 and 299/299 for tapes 1/3/4/5. The interlude holds the
input step at 14 and logs its own waits; it is not ordinary gameplay.

### Rendering and restore

- The ordinary frame wrapper (`$0ba56`) saves and restores DMAF_BLITHOG around
  synchronous draws. Polling waits still complete before any subsequent blitter
  register writes, CPU flips/copies or display swap; INTENA.BLIT stays disabled
  and the existing double INTREQ.BLIT acknowledgement remains.
- Each display buffer has 13 dirty bitsets, one bit per 16-pixel word column in a
  16-line band; the last band is clipped to line 199. Restore copies consecutive
  word runs, retaining clean gaps, and combines adjacent identical bands. A third
  table tracks background writes during the current frame. Four-line bands cost
  more in setup than they saved in DMA and were removed.
- The first foreground pass draws into the background, which is then restored
  into the display buffer. The second pass skips a blit only when intervening
  writes cannot overlap it. Image setup, scratch and flip side effects remain on
  the uncached path. Full-room rendering marks all buffers once.
- A 64-entry, four-way foreground cache retains the eight-byte table entry,
  20-byte clip state, eight-byte image header and 130-byte SHAPE state. Only
  single-part, unclipped chip images without a custom mask qualify, in the
  existing supported modes. Across frames, reuse is restricted to the terrain
  image arena (`$674be`–`$7ffff`), excluding the mutable preshift/scratch images.
  Full-room rendering clears it; pictures and background writes outside an
  ordinary frame invalidate it before the next frame. Header changes and mode-3
  colour changes miss. Restoring setup preserves unused tag-colour words.
- The expanded positive-shift path at `$05908` uses five masked copies instead
  of clear-plus-OR pairs. Ordinary image colour bits are covered by their mask;
  custom masks and the mask-disabled tag retain the original path. The shared
  blit entry remains instrumentable by VERIFY's deliberate sabotage hook.
- The unclipped/unflipped clipping case uses a short path. Image lookups accept
  registers, retain the kid-table remap for setup, and check multipart tables
  directly. `$7fc1a` continues only when reached from `$7fc0c`, as before.
  Resetting tags writes a zero register instead of CLR's 68000 memory read.
- One- and two-word horizontal flips flatten the plane/row loop and unroll byte
  swaps using the game's byte-reversal table. Zero two-word rows need no writes;
  other widths use the original routine. No large reversal table is allocated.

### Tile and collision work

`$108c6` bypasses inactive ordinary and above-room tile draws only at their two
known callers. It checks the original pending counters and always performs
column 9, preserving each row's final lookup globals and the top-row y globals.
The original loop's argument cleanup is preserved when bypassing the draw.

`$12bea` and `$12c7c` normalize collision coordinates horizontally, then
vertically, retaining every original global write and the room-zero wall result
without changing tilepos. `$14e8c` looks up each tile once and derives both wall
edges and collision flags. Reusing the loaded-room pointers removes redundant
room-address calculation. Collision image dimensions and ordinary y-to-row
coordinates have short paths with the original out-of-range fallback. The eight
fixed character-record transfer helpers copy their disjoint 18-byte records
with four longs and a word and retain the destination return value.

### Final evidence

Same final build, A4 opt 16 versus opt 0, with unchanged exclusions:

| Tape | Steps | Matching digest |
|---|---|---|
| 1 | 1–350 | 9e6a78bbce12 |
| 3 | 1–300 | eba440ce239b |
| 4 | 1–300 | 9f41ae5335df |
| 5 | 1–360 | a34a62a0d2f7 |

Tape 3 opt 1 matches for 300 steps. The opt-4 probe differs only at step 150
in both state and pixels, over 175 steps. A3 uses opt 0 and 4000 fields on each
route. Gameplay mean work is 1.876701/2.432592/2.187286/1.522989 fields;
maximum work is 4.980831/4.904153/3.814696/3.019169. No gameplay period exceeds
its own 4/5-field target by more than one field.

The final late-spikes profile (step 269, 12 fields) measures 4.981 fields for
the worst frame. Inclusive costs include shape blitting `$05686` 0.995,
blit start/wait `$053d6` 0.798, restore `$1975c` 0.289, foreground-cache entry
0.644 and table-image core 1.863. These overlap and must not be added.
The remaining work is below G1's ceiling, so optimisation stops here. G2 and
the D1 machine matrix remain outside this acceptance.
