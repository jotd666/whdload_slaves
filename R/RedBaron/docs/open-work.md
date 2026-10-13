# Red Baron open work

The user accepted measured performance on 2026-10-12 and requested completion
of release work. On 2026-10-13 the user completed W6 release acceptance and
authorized normal-build availability, then default-On after successful real
A1200/68040/40 MHz/MMU testing. The completion plan includes those amendments.

## Open items

Refer to items by ID. FC items are detailed in `fast-cpu-plan.md`.

| ID | Item | State |
|---|---|---|
| FC0 | VERIFY artwork mismatch on the Barto 030 NOMMU route | Complete; native scratch-clear synchronization fixed |
| FC1 | Deferred page fence instead of the swap spin | Complete; enabled on 030/040/060 |
| FC2 | Overlay and cockpit foreground composited in Fast RAM | Complete; enabled on 030/040/060 |
| FC3 | Persistent gauges | Complete; 060, plus 030/040 with W6 after FC12 |
| FC4 | Span polygon rasteriser | Complete; 040/060, plus 030 with W6 after FC12 |
| FC5 | Smaller viewport copy | Re-evaluated in FC12; retained on 030 with W6, dropped on 040/060 |
| FC6 | Re-profile, W6 trial and geometry processing | Complete; W6 rate passes bounded trial, 50 FPS unmet; geometry extension dropped below 2% |
| R1 | Renderer installer rejects its persistent helper on a later load | Fixed; captured guard identified, same-session second mission and rendering pass |
| R2 | In-game clipped-sprite bounds abort while firing | Fixed; reserved prefix with strict guard, native replay and release flight checks pass |
| FC8 | W6 presentation scenery cache | Complete; enabled on 040/060 with Faster rendering + W6; +15.53% / +12.24% level-flight FPS |
| FC9 | Raster kernel `paint()` rewrite (per-plane constants, longword interiors, line bset/bclr) | Complete; enabled on 030/040/060; measurements in `profiling.md` |
| FC10 | Cockpit composition word lists (pre-clipped, opaque split, longwords) | Closed: dropped; below 2% on 030; regresses on 040/060 |
| FC11 | Bitmap/mask key comparisons replaced by resource generations | Complete; enabled on 030/040/060 |
| FC12 | Re-measure FC5/FC3/FC4 decisions with W6, not under the two-field cap | Complete; qualifying CPU paths enabled, other choices retained |
| FC7 | AGA 040/060 and real-hardware confirmation | Closed at user request; remaining checks skipped, no real 060 available; prior A1200/040 confirmation retained |
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
subsequent artwork and scene follow-ups are recorded separately in `profiling.md`. The normal verified mask is `0x1fff1fff`, filtered by CPU; FC8 and selective copying also require W6.
The single **Enhanced framerate (68020+Fast RAM)** checkbox enables the complete
rendering and timing bundle with CUSTOM2=1. Code defaults to Off (omitted/zero);
supplied icons and the installer enable it. CUSTOM3 is unused. Developer/VERIFY
retain individual CUSTOM2 bits. This policy supersedes earlier option mappings
and opt-in descriptions in the historical completion notes below.
The work is submitted upstream in PR #30.

## Postponed beyond this release

W6/D5 release acceptance is complete by user decision (2026-10-13). Consistent
game speed is part of the single player bundle. No further acceptance flight is
required. The documented A500 overload and controlled-fixture limits remain
operating limits, not release gates.

Earlier optional W1 cached-CPU extensions, G1/G3 refinements and G5–G9,
S2/S3-prime/S4–S8, broader sound/OS changes and overlay queueing remain deferred
unless a concrete issue justifies them. The completion plan's low-value or
regressing C/E candidates were dropped, not left as release blockers.

50 FPS is not a release claim. Normal-build consistent timing is enabled with Enhanced framerate and
subject to the documented CPU-capacity envelope.
Further renderer redesign requires a new scope. Historical ledgers remain in
Git; do not revive their superseded next-work lists.

## Fast-CPU frame profile and plan

`fast-cpu-plan.md` has the exact 030 frame attribution (aprof) and the ordered
fix plan for the former 16.67 FPS plateau. Its §5 profiles 040/060 with W6
(18.3/19.6 FPS) and plans FC8–FC12 toward 25 FPS with Consistent game speed. FC0–FC4, FC6, FC8, FC9, FC11 and FC12 are complete. FC12 revises the original
FC5 drop on 030 with W6; FC10 remains dropped. FC7 is closed at user request.
No active FC steps remain.

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
FC12 is complete; W6/D5 is now accepted as an opt-in; see Release status above.

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
reuse on 060, and on 030/040 when W6 is enabled (FC12). Native needle callbacks remain. Reuse requires exact native keys,
stable bounds, no invalidating event and proof that the current scene/static
artwork cannot overwrite those pixels. The new background cache uses Fast RAM
with native fallback; memory requirements are unchanged. The 020 regresses. The original capped 030/040 FPS differences were below the
threshold; FC12 retains their prior paths only when W6 is off. Developer/VERIFY selection on 030/040 is retained for native
checks and exact profiling. All measurements, final hashes and the limited
changing-input route coverage are in `profiling.md`.

## Completed: direct convex polygon spans

Bit 24 removes scratch clear, edge compatibility, fill and merge for supported
convex polygons. It paints exact native-rounded planar spans in the private
Fast-RAM viewport and retains the existing outline path. Clipping, non-convex,
repeated-vertex, degenerate, oversized and alternating-fill cases keep the
existing renderer. The row table reuses reserved space; RAM requirements are
unchanged. Native triangle/quad/larger-polygon twins and host models pass.
The normal bundle enables 040/060 and, after FC12, 030 with W6. The original
capped 030 comparison remains the W6-off policy. Final normal checks, all timing pairs and the exact
profile are recorded only in `profiling.md`. FC5 was re-evaluated in FC12; the FC6 geometry extension was dropped; FC12 is complete.

## Post-release rendering investigation

The requested 030/040/060 reprofile is complete; see `rendering-analysis.md` and
the new section of `profiling.md`. It identifies repeated cockpit scripts,
per-plane drawing and explicit waits, and documents why the discarded software
blitter was not a test of a purpose-built Fast RAM renderer. The sparse static
artwork and direct scene follow-ups below are implemented. FC2 now composes the overlay/static foreground with the scene viewport;
persistent gauges and direct convex spans are complete as FC3/FC4. FC12 is complete; W6/D5 is now accepted as an opt-in; see Release status above.

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
common convex polygon pipeline on 040/060. FC12 is complete.
W6/D5 is now accepted as an opt-in; see Release status above.

## Completed: FC6 profile, W6 trial and geometry evaluation

Both user-selected branches are complete. The bounded 040/060 W6 trial keeps
simulation time on target within endpoint uncertainty, with no dropped debt,
but does not reach 50 FPS. The register-held face-loop extension passes native
correctness checks and is dropped because neither CPU clears the 2% threshold.
The normal release is unchanged. `profiling.md` holds all results and manual
W6 trial instructions. W6/D5 is now accepted as an opt-in; FC7 is closed at user request.

## Completed: W6 presentation scenery cache

FC8 bit 25 restores native scenery-cache reuse on 040/060 while preserving a
separate simulation copy. It is selected automatically when Faster rendering
and Consistent game speed are both enabled. The optional 77,480-byte Fast
allocation falls back to the previous path if unavailable; minimum RAM is
unchanged. Native cache/restoration checks, deliberate stale-world tests,
existing rendering twins, host tests and paired W6 timing pass. The newly
exposed publication-tail margin is corrected. Results and manual reproduction
are in `profiling.md`; FC12 is complete; no active FC steps remain.

## Completed: FC12 W6 policy remeasurement

With Faster rendering and Consistent game speed enabled, 030 selects persistent
gauges, direct convex spans and selective viewport copying; 040 additionally
selects persistent gauges. Selective copying regresses on 040/060, so they keep
the full copy. The 030 copy uses an optional 48,000-byte Fast allocation before
the game heap, reused across missions, with full-copy fallback on allocation
failure. W6-off and stock-CPU policies are unchanged. All results and final
release checks are in `profiling.md`. No active FC steps remain.

## Completed: dead experiment cleanup

Removed the uncalled VERIFY overlay compositor and its exclusive host model/tests,
the unincluded native coverage extractor, and the rejected private matrix
candidate with its dormant build/install wiring. Shared coverage and matrix
reference models remain in active tests and trace analysis. Active VERIFY
observers, exponent checks and CPU-specific renderer alternatives remain.
Normal and developer binaries are unchanged; no performance claim is added.
