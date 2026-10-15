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
