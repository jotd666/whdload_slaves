# Red Baron open work

The user accepted measured performance on 2026-10-12 and requested completion
of release work. On 2026-10-13 the user completed W6 release acceptance and
authorized its normal-build opt-in. The completion plan includes those amendments.

## Open items

Refer to items by ID. FC items are detailed in `fast-cpu-plan.md`.

| ID | Item | State |
|---|---|---|
| FC0 | VERIFY artwork mismatch on the Barto 030 NOMMU route | Complete; native scratch-clear synchronization fixed |
| FC1 | Deferred page fence instead of the swap spin | Complete; enabled on 030/040/060 |
| FC2 | Overlay and cockpit foreground composited in Fast RAM | Complete; enabled on 030/040/060 |
| FC3 | Persistent gauges | Complete; enabled on 060; other classes retain prior paths |
| FC4 | Span polygon rasteriser | Complete; enabled on 040/060; 030 retains its prior path |
| FC5 | Smaller viewport copy | Closed: dropped; less than 2% gain on every measured CPU class |
| FC6 | Re-profile, W6 trial and geometry processing | Complete; W6 rate passes bounded trial, 50 FPS unmet; geometry extension dropped below 2% |
| R1 | Renderer installer rejects its persistent helper on a later load | Fixed; captured guard identified, same-session second mission and rendering pass |
| R2 | In-game clipped-sprite bounds abort while firing | Fixed; reserved prefix with strict guard, native replay and release flight checks pass |
| FC8 | W6 presentation scenery cache | Complete; enabled on 040/060 with Faster rendering + W6; +15.53% / +12.24% level-flight FPS |
| FC9 | Raster kernel `paint()` rewrite (per-plane constants, longword interiors, line bset/bclr) | Complete; enabled on 030/040/060; measurements in `profiling.md` |
| FC10 | Cockpit composition word lists (pre-clipped, opaque split, longwords) | Closed: dropped; below 2% on 030; regresses on 040/060 |
| FC11 | Bitmap/mask key comparisons replaced by resource generations | Complete; enabled on 030/040/060 |
| FC12 | Re-measure FC5/FC3/FC4 decisions with W6, not under the two-field cap | Planned |
| FC7 | AGA 040/060 and real-hardware confirmation | Real A1200/040 at 40 MHz works with W6 enabled (user report); 060 and DMA/timing confirmation remain |
| D5a | W6 catch-up input check | Complete: native tap/hold/release during catch-up on A500 and 060 |
| D5b | W6 Time Compress and mission-exit transitions | Complete: native compression and modal checks; A500 catch-up mission exit |
| D5c | W6 A500 Time Scale 60 | Complete: measured overload envelope |
| D5d | W6 landing and combat outcome integration | Automated coverage complete; controlled fixtures, including tracked A500 target |
| G5–G9, S2/S3′/S4–S8 | Low-value geometry and sound candidates | Deferred unless a concrete issue justifies them |

## Release status

The accepted release work is complete. The subsequently captured R1 renderer
installation abort is fixed and verified across a same-session mission reload.
R2, the separately captured firing abort, is fixed with native replay and
bounded normal-build flight validation.
F1 enables the normal verified bundle by default; F2 condenses the ledgers;
The original F3 passed on all six machine configurations; its results and the
subsequent artwork and scene follow-ups are recorded separately in `profiling.md`. The normal verified mask is `0xfff1fff`, filtered by CPU; FC8 also requires W6.
Normal CUSTOM3 bit 0 independently enables Consistent game speed (Off by default).
Normal CUSTOM2=0 is On and 1 is Off; developer/VERIFY values remain bit masks,
where zero disables patches. The normal build is in the local build directory.
Nothing has been pushed; publication requires a separate explicit request.

## Postponed beyond this release

W6/D5 release acceptance is complete by user decision (2026-10-13). The normal
build exposes Consistent game speed as an independent opt-in (`CUSTOM3=1`);
it is not part of the default Faster rendering mask. No further acceptance
flight is required. The measured A500 overload and the controlled-fixture
limits in `profiling.md` remain documented operating limits, not release gates.

Earlier optional W1 cached-CPU extensions, G1/G3 refinements and G5–G9,
S2/S3-prime/S4–S8, broader sound/OS changes and overlay queueing remain deferred
unless a concrete issue justifies them. The completion plan's low-value or
regressing C/E candidates were dropped, not left as release blockers.

50 FPS is not a release claim. Normal-build consistent timing is opt-in and
subject to the documented CPU-capacity envelope.
Further renderer redesign requires a new scope. Historical ledgers remain in
Git; do not revive their superseded next-work lists.

## Fast-CPU frame profile and plan

`fast-cpu-plan.md` has the exact 030 frame attribution (aprof) and the ordered
fix plan for the former 16.67 FPS plateau. Its §5 profiles 040/060 with W6
(18.3/19.6 FPS) and plans FC8–FC12 toward 25 FPS with Consistent game speed. FC0–FC4 are complete; FC5 was evaluated and dropped below the measurement
threshold. FC6, FC8 and FC9 are complete; FC12 is next, with FC7 hardware measurements still open.

**FC0 is complete:** native scratch-clear synchronization fixes the top-edge
artwork mismatch. Full artwork/scene twins pass on 030 NOMMU/MMU, 040 and 060;
the final aprof capture passes with all checks restored. VERIFY snapshots fit
the existing reservation, so RAM requirements are unchanged. See `profiling.md`.

## Completed: deferred display-page reuse

Bit 21 replaces the full flight beam spin with a next-VBlank page-reuse fence
on 030/040/060 private-scene frames. A short copper-pickup guard prevents partial
pointer publication. Redraws, native fallbacks and modal boundaries fence before
writing; the two-field cap and RAM requirements are unchanged. The normal
bundle enables it. Same-build comparisons, final normal timings, native twins,
view/firing transitions, beam checks and exact profiling are in `profiling.md`.
FC12 is the next renderer step; W6/D5 is now accepted as an opt-in; see Release status above.

## Completed: Fast-RAM cockpit composition

Bit 22 composes the forward overlay and static artwork into the private viewport
before its single copy to Chip RAM, on 030/040/060. Outside-viewport artwork
persists per page with redraw, view, message, resource, modal and page-reuse
invalidation. Firing and unsupported frames retain the existing path; gauges
are handled separately by FC3. Native twins, transition checks, all three CPU timing pairs,
final normal-default checks and the exact profile pass. The normal bundle
includes FC2; memory requirements and the two-field cap are unchanged. All
results and manual profiling instructions are in `profiling.md`.

## Completed: selective gauge updates

Bit 23 enables clipped CPU background restores and per-page unchanged-gauge
reuse on 060. Native needle callbacks remain. Reuse requires exact native keys,
stable bounds, no invalidating event and proof that the current scene/static
artwork cannot overwrite those pixels. The new background cache uses Fast RAM
with native fallback; memory requirements are unchanged. The 020 regresses;
030/040 FPS differences are below the plan's threshold, so their player paths
remain unchanged. Developer/VERIFY selection on 030/040 is retained for native
checks and exact profiling. All measurements, final hashes and the limited
changing-input route coverage are in `profiling.md`.

## Completed: direct convex polygon spans

Bit 24 removes scratch clear, edge compatibility, fill and merge for supported
convex polygons. It paints exact native-rounded planar spans in the private
Fast-RAM viewport and retains the existing outline path. Clipping, non-convex,
repeated-vertex, degenerate, oversized and alternating-fill cases keep the
existing renderer. The row table reuses reserved space; RAM requirements are
unchanged. Native triangle/quad/larger-polygon twins and host models pass.
The normal bundle enables 040/060; the 030 FPS difference is below 2%, so its
player path is retained. Final normal checks, all timing pairs and the exact
profile are recorded only in `profiling.md`. FC5 and the FC6 geometry extension were dropped; FC12 is next.

## Post-release rendering investigation

The requested 030/040/060 reprofile is complete; see `rendering-analysis.md` and
the new section of `profiling.md`. It identifies repeated cockpit scripts,
per-plane drawing and explicit waits, and documents why the discarded software
blitter was not a test of a purpose-built Fast RAM renderer. The sparse static
artwork and direct scene follow-ups below are implemented. FC2 now composes the overlay/static foreground with the scene viewport;
persistent gauges and direct convex spans are complete as FC3/FC4. FC12 is next; W6/D5 is now accepted as an opt-in; see Release status above.

## Completed: selective static cockpit artwork repairs

User-authorized after the rendering investigation. Bit 19 now enables sparse,
pixel-guarded repairs for forward static programs 2–4 under Faster rendering on
030/040/060. Unchanged covered pixels are not written; transparent pixels are
never touched. Native artwork is retained on 000/010/020 because pixel checking
regressed or provided no gain on the measured slow CPUs. The reserved renderer
workspace is reused, plus an 8 KB Chip mask; minimum RAM is unchanged.

All six CPU timings and bounded native/view/firing validation are in
`profiling.md`. Native firing scripts, instruments and other views keep their
existing draw order. FC2 now handles the combined viewport and outside-viewport static persistence;
narrower gauge updates remain FC3. W6/D5 is now accepted as an opt-in; see Release status above.

## Completed: scene drawing structure

Faster rendering selects bit 20 on measured 030/040/060 classes. Supported scene
viewports are owned by Fast RAM: direct five-plane rectangles/lines, one polygon
coverage traversal for colour, specialized scratch clear/fill, no inbound page
or scratch copy, and one outbound viewport copy. Native clipping remains, and
unsupported camera/layouts retain native drawing. The reserved workspace is reused;
RAM requirements are unchanged. 000/010/020 retain the native renderer.

The first candidate's polygon overhead cancelled its rectangle saving; direct
scratch loops fixed that regression. CPU comparisons, native primitive twins,
banked flight, view/firing checks and final normal-build checks are recorded in
`profiling.md`. FC2 now handles cockpit composition, and FC4 replaces the
common convex polygon pipeline on 040/060. FC12 is the next renderer step.
W6/D5 is now accepted as an opt-in; see Release status above.

## Completed: FC6 profile, W6 trial and geometry evaluation

Both user-selected branches are complete. The bounded 040/060 W6 trial keeps
simulation time on target within endpoint uncertainty, with no dropped debt,
but does not reach 50 FPS. The register-held face-loop extension passes native
correctness checks and is dropped because neither CPU clears the 2% threshold.
The normal release is unchanged. `profiling.md` holds all results and manual
W6 trial instructions. W6/D5 is now accepted as an opt-in; FC7 hardware confirmation remains.

## Completed: W6 presentation scenery cache

FC8 bit 25 restores native scenery-cache reuse on 040/060 while preserving a
separate simulation copy. It is selected automatically when Faster rendering
and Consistent game speed are both enabled. The optional 77,480-byte Fast
allocation falls back to the previous path if unavailable; minimum RAM is
unchanged. Native cache/restoration checks, deliberate stale-world tests,
existing rendering twins, host tests and paired W6 timing pass. The newly
exposed publication-tail margin is corrected. Results and manual reproduction
are in `profiling.md`; FC12 and hardware timing remain open.
