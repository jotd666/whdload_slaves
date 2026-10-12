# Fast-CPU frame profile and fix plan (2026-10-12)

This covers the 030/040/060 classes, whose original profile sat at 16.67 FPS
(three fields per frame). Current results are in `profiling.md`. It complements `rendering-analysis.md`. Its profile replaces the bracket
lower bounds there with exact per-instruction attribution.

## 1. How the profile was taken

**Exact profile.**
- Instrument: `aprof` FS-UAE, which counts emulated cycle units for every
  instruction, including Chip-bus wait units.
- CPU: cycle-exact 68EC030/50 on an OCS A500 chipset, 2 MB Chip + 8 MB Fast,
  CACR `0x2011` (instruction cache on; data-cache enable bit 8 clear).
- Build: VERIFY tape route with CUSTOM2 `0x1f0ffa`, the normal build's 030
  selection (bits 19 and 20 on).
- Window: 50 PAL fields after 500 warm-up fields, forward view, maximum detail.
- Tools: `tools/aprof_flight.py`, then `tools/aprof_flight_report.py`.
  Capture `tmp/prof/aprof-030n-1`.
- aprof refuses any MMU model, so the CPU is 68EC030. 040/060 cannot be profiled
  this way.
- This historical profile used a private source copy without the artwork twins
  after a reported abort. FC0 below restores all checks; the current profiler
  refuses a capture unless selected twins pass.

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

Items are numbered FC0–FC7 (fast CPU); `open-work.md` refers to them by these IDs.

Each step follows the completion plan's §0 rules:
- one bit and one coherent commit per step;
- gated to 030/040/060 unless measured otherwise;
- one same-build A/B per CPU class, with normal-build stage brackets;
- an exact pixel/state twin for each changed primitive;
- drop the step if the gain is below 2%.

Re-run the aprof capture after each step to confirm the stall moved, not just the
FPS.

### FC0 — VERIFY artwork-twin abort: complete

The reproduced Barto failure was a real top-edge polygon pixel mismatch, not
allocation loss. The bit-20 native scratch clear now completes before returning
to CPU endpoint corrections. All artwork and scene twins pass on 030 NOMMU/MMU,
040 and 060, and the full-twin aprof capture completes. VERIFY snapshots use
reserved workspace; RAM requirements are unchanged. The profiler no longer
removes twins and rejects incomplete checks. Evidence and results are recorded
once, in `profiling.md`. Physical-hardware confirmation remains FC7.

### FC1 — deferred page fence instead of the swap spin: complete

Two buffers stay; no third Chip page.

**Cause.**
- `sim:314be` exchanges the page variables, then waits for a safe beam position
  **before** the copper-pointer stores at `sim:3154a`. The native early-blank
  path also accepts lines through 40. The original profile heading described
  that instruction ordering incorrectly.
- The old front page stays visible until the next vertical blank. The wait
  exists so the next frame cannot draw into a page that is still on screen.
- With bit 20, the next frame's scene is drawn in Fast RAM and does not touch
  that Chip page for many milliseconds. The spin protects nothing during that
  time.

**Fix.**
1. Make the swap return at once after writing the copper pointers.
2. Record the VBL count at which the swap becomes visible: the next blank, using
   the existing `pace_vbl` field counter.
3. Put a **fence** before the first write of the next frame to the new back Chip
   page. The fence waits only if that blank has not happened yet.
4. Audit every Chip-page writer between the swap and the end of the next frame's
   scene. Place the fence at the earliest of them:
   - native background and top-area restoration;
   - the bit-20 viewport copy;
   - cockpit composition;
   - messages;
   - any native fallback path for an unsupported layout.

   An unaudited path takes the fence at render entry, which reproduces today's
   behaviour.
5. Keep the P2 two-field minimum interval in `pace_flight` unchanged.
6. 000/010/020, and frames where bit 20 is not active, keep the original wait.

**Check.**
- A beam-sampled tear check of every published field.
- `publication_cadence.py`.
- View and firing transitions.
- A VERIFY counter of fence waits, which should be near zero on 030+ in forward
  flight.

**Disposition.** Implemented, measured and enabled in the normal CPU-gated
bundle. The final normal/VERIFY checks and exact profile pass; results are
recorded once in `profiling.md`. No third page or extra RAM is needed.

**Original expectation.**
- The 10.2 ms spin moves to the fence, where it is mostly absorbed by Fast-RAM
  scene work.
- Alone, this lets frames that finish their work within 40 ms publish every two
  fields. FC2–FC5 bring the remaining work under that.

**FC1 writer coverage.** The implementation uses bit 21 with bit 20 and pacing as
mandatory dependencies, gated to 030/040/060. The native copper MOVEM remains
at sim:3154a. Its wrapper samples the field counter after all stores and records
a next-field deadline; an interrupt during publication can postpone reuse,
never release it prematurely. Only the flight swap may bypass the beam spin.
The native copper WAITs at lines 42/44 are checked at installation. Publications
inside lines 41–43 wait until line 44, preventing a pointer update from crossing
the copper pickup; all other beam positions may publish immediately.

The sim:00574 entry permits overlap only for unchanged forward flight with no
full-screen replacement, forced redraw or background-restore request. All other
entries fence immediately. The forward prelude prepares objects/camera state;
its hardware drawing primitives are additionally fenced at their custom-base
selection. Private-scene rejection fences before native drawing; accepted
scenes fence at their outbound viewport copy. The subsequent overlay, dashboard,
instruments and messages therefore inherit a writable page. The VERIFY native
scene snapshot also fences before touching the Chip destination.

Menu, controls, preferences, pause, map, object-list overflow error and flight-exit
boundaries fence before
their first display operation, including the map called after publication.
Their veneers validate whole displaced instructions and relocated operands;
the map's short BSR is re-emitted as an absolute call. Frames without a private
scene and non-flight swaps keep the native beam wait. No new Chip page or RAM
reservation is required. Timing and acceptance results belong in `profiling.md`.

### FC2 — overlay and cockpit foreground in Fast RAM (complete)

Bit 22 requires bits 19–21 and selects the measured 030/040/060 classes. The
normal Faster rendering bundle enables it. `cockpit-fast.s` composes the forward
overlay and static programs 2–4 before the existing single viewport copy. The
overlay list caches the exact native cookie-cut operands; the foreground reuses
bit 19's native-output word lists. Empty/opaque/partial masks retain their exact
meaning, including opaque black. The lists occupy existing reserved Fast RAM;
no extra allocation or minimum-RAM change is needed.

All three exact artwork keys are checked under the clip that `sim:15e68` will
install. Unsupported descriptors, cache misses, firing, exceptional foreground
scripts and top-background restoration retain the previous native/sparse path.
The native calls later replay drawing state in their original order. In the
measured forward layout, static words outside the viewport are above it rather
than in the lower dashboard; these persist independently on both screen pages.
Page identity, viewport changes, render-entry redraw/view flags, resource
lifetime hooks, the message boundary at `sim:00830` and modal fences invalidate
page validity. Repairs never compare destination pixels; partial words use the
necessary read-modify-write, and opaque words only write. Gauges are unchanged.

Native overlay/programs 2–4 pixel twins pass on both pages, alongside the existing
artwork/state and scene twins. A bounded VERIFY check confirms the final cockpit
ordering and outside-viewport pixels once per page after invalidation. Four-view
and hardware-key firing transitions pass. All CPU timing pairs and final normal
checks pass; measurements and reproduction commands are in `profiling.md`.

Map-toggle check dropped: this game has no in-flight map command; the campaign
map is outside flight rendering and its modal fence invalidates cached pages.

### FC3 — persistent gauges (complete; 060 player default)

Bit 23 shares the bit-18 native dispatcher keys and resource lifetime hooks.
Each gauge/page retains its exact raw input/context key, stable needle bounds
and selective drawing-state result. Eligible hits replay that state and skip
the background/needle work without reading the old Chip pixels. Eligibility
requires FC2 composition and a bound below both the current viewport and the
last covered word of every static artwork list; unsupported layouts redraw.
Redraw, view, fullscreen, top text, message, firing, exceptional foreground,
modal and resource events invalidate retained entries.

Changed gauges use screen-aligned background colour/mask words in Fast RAM.
The CPU copies only native clipped coverage, preserving opaque black and
uncovered edge bits, before the unchanged native needle callback. The existing
blitter is waited before CPU writes; unsupported geometry/orientation and
allocation failures retain native drawing. No minimum-RAM increase is needed.
The new hooks are sim:19ba6 and sim:19d98; sim v1 only.

Full and clipped background twins cover all seven gauges on both pages, and
unchanged pixel/state twins cover every gauge/page. The native keyboard route
covers views, firing, held throttle and opposing turns. An all-seven-changing
flight is dropped from this bounded fixture: two inputs remain constant;
per-input key mutation tests and all native page twins remain. The final exact
capture passes the tightened current-artwork extent proof.

The required four-class timing matrix is complete. Only 060 clears the plan's
FPS threshold, so only 060 gets bit 23 in the normal default bundle. 020 is
excluded after regression; 030/040 retain their prior player paths. Explicit
030/040 developer/VERIFY masks remain available for common-code checks and the
exact profiler. The final normal check passes. Results and hashes are recorded
once in `profiling.md`. The expected saving in the original proposal was an
estimate; use the measured ledger instead.

### FC4 — span polygon rasteriser (complete; 040/060 player default)

Bit 24 replaces scratch clear, compatibility edges, fill and five-plane merge
for convex 3–32-vertex polygons already inside the clip rectangle. The native
line-mode tie rule produces row extents; final planar spans preserve all
coverage and existing differently-coloured outlines through sim:2ea28.
Repeated vertices, non-convex or degenerate shapes, clipping, larger lists and
alternating-colour fills retain the existing exact path. The 800-byte row table
uses an existing Fast-RAM workspace gap; RAM requirements do not increase.

The normal bundle selects 040/060. The 030 FPS result is below 2%, so its normal
path is unchanged; explicit developer/VERIFY selection remains for the native
checks and profiler. The hook at sim:2f312 is installed only for sim v1 with
bit 24 and private-scene support. Original bytes remain when it is disabled.

Randomized, thin, degenerate, clipped-boundary and recorded host cases run
against the native blitter model. Bounded native full-polygon twins cover
triangles, quadrilaterals and larger convex polygons, including their outlines.
All measurements, final artifacts and validation are recorded in `profiling.md`.
Fallback expansion is dropped from this step: compatibility is no longer a
leading cost, and the fallback preserves native coverage.

### FC5 — smaller viewport copy: dropped

The per-page Fast-shadow candidate passed exact pixel checks but gained less
than 2% level-flight FPS on every measured CPU class, so it is dropped under
completion-plan §0. Hard-turn windows passed the regression limit. The original
full viewport copy and RAM requirement remain; `profiling.md` records the
frozen-build comparisons and the corrected 060 allocation trial.

### FC6 — retained-renderer profile, W6 trial and geometry: complete

The user approved both follow-ups on 2026-10-12. The retained-renderer exact
profile and the bounded 040/060 W6 trial are complete. World-time rate stays
within one tick of target with no dropped time; the measured workload does
not reach one-field presentation. W6 remains developer-only and D5 postponed.

The existing exact sim:3b4cc register-held face loop was extended experimentally
to 040/060 and checked with its host model and native twin. Both frozen-build
W6 timing pairs were below 2%, so the extension is dropped. The 68000 path,
normal player mask and RAM requirements remain unchanged. Measurements and
reproduction instructions are recorded once in `profiling.md`.

C1/C2 remain dropped; smaller G6/G8/G9 work remains deferred. This result does
not rule out a different geometry design, nor does emulator timing establish
physical 040/060 throughput. Do not claim 50 FPS from these results.

### FC7 — AGA and 040/060 confirmation

Capture a Barto DMA trace of the 060 and 040 configurations (AGA, 32-bit Chip)
before and after FC1–FC5. The emulator's 040/060 timing is not a hardware model
(`rendering-analysis.md`). If a real accelerator is available, confirm the result
there before any 50 FPS claim.

## 4. Projected budget (030/50, VERIFY-relative ms per frame)

| | Now | After FC1–FC5 |
|---|---:|---:|
| Swap wait | 10.2 | ≈0 (fence) |
| Overlay + foreground artwork | 13–14 | ≈1 |
| Gauges | 8.6 | ≈1–2 typical |
| Polygon coverage + raster | 13.8 | ≈4 |
| Viewport copy | 7.0 | 2–5 |
| Geometry, world, other | ≈21 | ≈21 |
| **Total** | **≈77** | **≈30–35** |

These are projections from the measured costs, not results. Confirm every row with
the normal-build brackets and a fresh aprof capture.
