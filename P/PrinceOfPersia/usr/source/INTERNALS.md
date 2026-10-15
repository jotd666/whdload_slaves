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
   1. With buffer 0 as the target, it draws layers 0 and 1 from two draw lists: `$489f8`
      (8-byte records tagged with a layer, via `g:$116fa`) and `$47d64[layer]` (via
      `g:$116a2` → `g:$1173e`). These are room pieces that change, such as gates and
      loose floors. Nothing restores buffer 0 between frames, so these draws repaint their
      own area, and buffer 0 stays a clean picture of the room as it is now.
   2. The target goes back to the hidden display buffer.
   3. `g:$094e4` = `g:$1bd5e(0, 4)` copies buffer 0 onto it. This is the 40,000-byte copy:
      `g:$1975c` does it as A→D blits of `$1000` words.
   4. Layer 3 (the characters, `g:$116a2(3)` → `g:$117c4`) is drawn on top, then layer 1
      again, so those pieces end up in front of the characters.
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

**Starting and waiting.**
- Only two routines write `BLTSIZE`: `g:$053a2` (C-callable, size on the stack) and
  `g:$053d6` (assembler, size in d0, SR saved in `g:$053d4`).
- Both raise the IPL to 7 and set `$1a24`. They start the blit, then `STOP #$2000` until the
  level-3 handler's blitter branch (`g:$19fc4`) clears `$1a24`, and then restore SR.
- Every blit is therefore finished before the CPU runs on. The blitter interrupt is enabled
  (`INTENA` `$a068` at `g:$19eca`) only for this.
- The game has no `btst #6,$dff002` busy waits; the slave's commented-out `blitter_1` and
  `blitter_2` are the only ones.

**Routines that set up blits:**

| Routine | Called from | Start | Blits | Destination |
|---|---|---|---|---|
| `g:$05432` | shape draw `g:$1cb94` | `$053d6` | 6 at `$054b4`–`$05536`: the shape's planes (pointers `$67528`–`$6753c`) into scratch at `$1a28 + n×$7f0` | `$1000`–`$4fff` |
| `g:$05686` | shape draw `g:$1cb94` | `$053d6` | 5 per shape at `$0585e`–`$058fe` (one per plane, `$674ba` as C and D), or 10 at `$05982`–`$05ab8` | draw target |
| `g:$1975c` | `g:$1bd5e`, `g:$1bf76` | `$053a2` | A→D copy in `$1000`-word blits at `$197c0`/`$197dc`/`$197ea` | buffer by id |
| `g:$19802` | `g:$1bd9a`, `g:$1bf76` | `$053a2` | D-only clear or fill at `$19852`/`$1986e`/`$1987c` | buffer by id |
| `g:$19894` | rectangle copy `g:$1be18` ← `g:$09560` | `$053a2` | between buffers | buffer by id |
| `g:$199e0` | image draw `g:$1bec8` (room tiles, 12 callers) | `$053a2` | per plane at `$19b22`/`$19b4e` | buffer by id, mostly 0 |
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
