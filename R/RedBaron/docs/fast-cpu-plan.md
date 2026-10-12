# Fast-CPU frame profile and fix plan (2026-10-12)

This covers the 030/040/060 classes, which today sit at 16.67 FPS (three fields per
frame). It complements `rendering-analysis.md`. Its profile replaces the bracket
lower bounds there with exact per-instruction attribution.

## 1. How the profile was taken

**Exact profile.**
- Instrument: `aprof` FS-UAE, which counts emulated cycle units for every
  instruction, including Chip-bus wait units.
- CPU: cycle-exact 68EC030/50 on an OCS A500 chipset, 2 MB Chip + 8 MB Fast,
  CACR `0x2011` (instruction and data caches on).
- Build: VERIFY tape route with CUSTOM2 `0x1f0ffa`, the normal build's 030
  selection (bits 19 and 20 on).
- Window: 50 PAL fields after 500 warm-up fields, forward view, maximum detail.
- Tools: `tools/aprof_flight.py`, then `tools/aprof_flight_report.py`.
  Capture `tmp/prof/aprof-030n-1`.
- aprof refuses any MMU model, so the CPU is 68EC030. 040/060 cannot be profiled
  this way.
- The VERIFY artwork twin aborts on this route with "sparse artwork pixel/state
  mismatch". The profile build is a private source copy without those two calls;
  see step 0.

**Bus cross-check.**
- Barto DMA-slot traces of the **normal** build on 030/50 MMU (40 fields) and
  030 NOMMU, using `tmp/dev/tools/render_trace_case.py`.
- These record slot ownership only. The emulator logs no instructions on
  cached-CPU configurations.
- They show a strict three-field rhythm, per field:

| Field | Blitter | CPU Chip access | Free slots | Activity |
|---|---:|---:|---:|---|
| 1 | ≈43% | ≈15% | ≈12% | Bus saturated by blits |
| 2 | ≈1% | ≈27% | ≈41% | CPU Chip copies and compares |
| 3 | 0% | ≈6% | ≈64% | Fast-RAM work and the swap wait |

**Frame rate.** The VERIFY build runs at 13.0 FPS: 76.9 ms per frame, of which
66.7 ms is work. The normal build runs at 16.57 FPS. Use the *shares* and the
*per-routine causes* below. Absolute FPS comes from normal-build brackets
(`render_profile_case.py`), as before.

## 2. Where a frame goes (030/50, ms per frame, exact)

Chip-bus units are **50.7% of all CPU time**. Recognised blitter polls are
**18.6%**.

| Stage / cause | ms | Evidence |
|---|---:|---|
| **Publication: busy-wait for beam > line 244 after swap** | **10.2** | `sim:31536` loop reading VPOSR, 100% Chip; called through `pace_flight` |
| **Scene `sim:2c552` total** | **38.0** | |
| ├ Geometry, object setup, sort, clip (Fast RAM, CPU) | ≈15 | `3a902`, `39b42`, `3b41a`, `38c82`, `vertex_fast`, `clip_fast`, … |
| ├ Polygon coverage: edges and fix-ups in the compatibility kernel | 7.3 | `scene_compat_code`, 82 calls per frame, 0% Chip |
| ├ Direct raster: fill, merge, rectangles, lines | 6.5 | `scene_raster_code`, 26 packets per frame |
| └ **Viewport copy Fast→Chip, 24,000 bytes** | **7.0** | `scene_frame_copy32`, 96% Chip |
| **Forward overlay `sim:2c144`** (5 × 320×52 ABCD blits) | **6.3** | 6.8 ms polling at `sim:2c270` |
| **Gauge dispatch `sim:19ba6`** | **8.6** | `sim:30572` bitmap blits, 6.9 ms of it polling |
| **Instrument scripts `sim:15e96`** | **8.0** | `artwork_sparse_update` 6.8 ms, 76% Chip; front program 3.5 ms inclusive |
| World step `sim:01098` | 2.5 | |
| Other | ≈3 | |

**Reading:**
- About **36 ms of each frame is the CPU stalled on Chip RAM or the blitter**:
  - 10.2 beam wait
  - 6.8 overlay wait
  - 6.9 gauge-blit waits
  - 7.0 viewport copy
  - about 5 sparse-artwork Chip reads
- Real computation (geometry, rasterisation, world) is about 30 ms. It runs from
  Fast RAM and will scale with a faster CPU. The stalls will not.
- The P2 cap holds publication to at most 25 FPS (two fields). A frame that
  overruns two fields waits for the next safe line, so it lands on three.
- **Reaching 25 FPS needs about 40 ms of work with no beam wait**, which is
  about 27 ms less than today. 50 FPS additionally needs W6 (bit 13, one-field
  cap) and a 20 ms frame.

## 3. Fix plan, largest bottleneck first

Each step follows the completion plan's §0 rules:
- one bit and one coherent commit per step;
- gated to 030/040/060 unless measured otherwise;
- one same-build A/B per CPU class, with normal-build stage brackets;
- an exact pixel/state twin for each changed primitive;
- drop the step if the gain is below 2%.

Re-run the aprof capture after each step to confirm the stall moved, not just the
FPS.

### Step 0 — resolve the artwork-twin abort (a correctness check, not speed)

The VERIFY artwork twin aborts on the 030 NOMMU tape route. The same message
covers an AllocMem failure of its 80,000-byte snapshot (`artwork-cache.s`, the
`beq artwork_bad` after AllocMem).

1. Give the two causes separate messages.
2. Rerun `aprof_flight.py` without the private copy. (The script's source copy
   becomes unnecessary once this is fixed.)
3. If it is a real pixel or state mismatch, fix bit 19 before anything below.
   It ships on 030.

### Step 1 — triple-buffered publication: −10 ms

**Cause.** `sim:314be` swaps the copper bitplane pointers, then busy-waits until
the beam passes line 244. The old front page stays visible until the next
vertical blank, so the next frame cannot draw into it.

**Fix.**
1. Allocate a third Chip page, 40,000 bytes, on 030+ only. There is enough Chip
   at the approved 2 MB minimum.
2. Rotate draw → pending → shown. A copper or VBL hook makes "pending" visible at
   the next blank.
3. The swap returns immediately unless both other pages are still pending. Keep
   the P2 minimum interval, but implement it as "do not queue more than one
   pending page" instead of a beam spin.
4. The native swap exchanges two page pointers (`sim:314c0`–`314d0`) and keeps per-page
   dashboard and gauge state. Map the third page onto the native "other page"
   slot, and invalidate per-page caches when a page is reused out of order.

**Check.**
- A beam-sampled tear check of every published field.
- `publication_cadence.py`.
- Both existing view and firing transitions.

**Expected.** The swap wait disappears from the profile. 16.67 FPS becomes about
20 FPS on its own, with 2- and 3-field frames alternating; steps 2–5 bring it to
a steady 25.

### Step 2 — overlay and cockpit foreground composited in Fast RAM: −12 to −14 ms

**Cause.**
- The forward overlay is five 4-channel blits per frame, and the CPU waits on
  them for 6.8 ms. They are the bulk of field 1's blitter load.
- The static foreground programs 2–4 then read and compare up to 1,024 covered
  words × 5 planes on the Chip page, about 6.8 ms.

**Fix.** While bit 20 owns the viewport in Fast RAM:
1. Before the single viewport copy, apply the overlay and the viewport-row part
   of programs 2–4 to the Fast buffer.
2. Use precomputed opaque-word lists (mask, five colours) built from the native
   output once per resource, as bit 19 already does.

Then neither the overlay blit nor the Chip reads happen. Rows below the viewport,
the dashboard, need a per-page "artwork valid" flag:
- Repair them only after a view change, message, resource reload or page reuse
  (the step 1 invalidation hooks).
- Never compare them against Chip.

**Check.**
- Exact pixel twins against the native overlay and programs 2–4 on both pages.
- Firing artwork and all four views.
- The map toggle.

Firing artwork and non-forward views stay native.

### Step 3 — persistent gauges: −6 to −8 ms

**Cause.** `sim:19ba6` restores each gauge's old bounds from a background bitmap
and redraws the needle on every frame. It uses 4-channel blits that the CPU
waits on (`sim:30572`, 6.9 ms of polling).

**Fix.**
1. For each page and each gauge, key on the native gauge input values. Bit 18
   already reads them (`instrument-values.s`).
2. Skip a gauge whose key equals the one last drawn on that page.
3. For a changed gauge, restore its bounds with a CPU copy from a Fast-RAM
   background, then run the native needle callback.
4. Invalidate everything on the step 1/2 events.

Bit 18 is gated to 020/040 today, because its composition design lost on
030/060. This step skips unchanged work outright, so measure it on all four
classes.

**Check.**
- Exact twins per gauge.
- A held-throttle and turn route in which every gauge changes.
- Both pages after a page reuse.

### Step 4 — span polygon rasteriser: −8 to −10 ms

**Cause.** A native polygon goes through several passes:
1. Clear a one-plane scratch.
2. Draw every edge in blitter line mode, with clip fix-ups.
3. Fill the scratch in blitter fill mode.
4. Merge the scratch into five planes.
5. Optionally draw outlines (`sim:2f292`–`2f552`).

Bit 20 runs passes 1, 3 and 4 directly, but edges still go through the
compatibility kernel (7.3 ms) and the scratch still exists.

**Fix.**
1. Walk the clipped vertex list once.
2. Build left and right edge x per row, using the native line-mode rasterisation
   rule so coverage stays bit-exact.
3. Write final colours as planar spans: left mask, solid interior words (five
   stores per 16 pixels), right mask.

That removes the scratch clear, the edge kernel, the fill and the merge. Keep
outlines (`sim:2ea28`) through the existing direct line.

**Check.**
- A host model against `tools/fast_blitter_model.c` over randomized and recorded
  polygons, including clipped, degenerate and one-pixel cases.
- A native twin per polygon type.

### Step 5 — smaller viewport copy: −2 to −5 ms (scene dependent)

**Cause.** The whole 320×120 five-plane viewport (24,000 bytes) is written to
Chip every frame: 7.0 ms on OCS, 96% Chip.

**Fix.**
1. Keep one Fast shadow of each Chip page's viewport (24 KB each).
2. Compare the new Fast frame with the shadow of the page being drawn, and write
   only differing longword runs.

In level flight the sky and ground rows rarely change between frames on the same
page.

**Check.** Measure in level flight and in a hard turn (the worst case). Drop the
step if the turn regresses by 2% or more. Per-page shadows depend on step 1's
page identity.

### Step 6 — re-profile, then decide on geometry or 50 FPS

After steps 1–5, the projected 030 frame is about 30–35 ms of mostly Fast-RAM
computation. That is 25 FPS, capped by P2.

**Next decision.** Either:
- reduce geometry (about 15 ms on 030: object setup `39b42`, `3a902`, the face
  loop `3b41a`, transforms; aprof names the hot loops); or
- with the user, turn on W6 (bit 13, one-field cap, fixed world tick) on
  040/060 and measure toward 50 FPS.

D5 is still postponed, so a W6 change is a user decision.

### Step 7 — AGA and 040/060 confirmation

Capture a Barto DMA trace of the 060 and 040 configurations (AGA, 32-bit Chip)
before and after steps 1–5. The emulator's 040/060 timing is not a hardware model
(`rendering-analysis.md`). If a real accelerator is available, confirm the result
there before any 50 FPS claim.

## 4. Projected budget (030/50, VERIFY-relative ms per frame)

| | Now | After steps 1–5 |
|---|---:|---:|
| Swap wait | 10.2 | 0 |
| Overlay + foreground artwork | 13–14 | ≈1 |
| Gauges | 8.6 | ≈1–2 typical |
| Polygon coverage + raster | 13.8 | ≈4 |
| Viewport copy | 7.0 | 2–5 |
| Geometry, world, other | ≈21 | ≈21 |
| **Total** | **≈77** | **≈30–35** |

These are projections from the measured costs, not results. Confirm every row with
the normal-build brackets and a fresh aprof capture.
