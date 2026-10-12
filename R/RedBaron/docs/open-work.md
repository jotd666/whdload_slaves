# Red Baron open work

The user accepted measured performance on 2026-10-12 and requested completion
of release work. The completion plan remains authoritative with that amendment.

## Release status

No implementation or validation work remains for the accepted release.
F1 enables the normal verified bundle by default; F2 condenses the ledgers;
The original F3 passed on all six machine configurations; its results and the
subsequent artwork follow-up are recorded separately in `profiling.md`. The normal verified mask is `0xf1fff`, filtered by CPU.
Normal CUSTOM2=0 is On and 1 is Off; developer/VERIFY values remain bit masks,
where zero disables patches. The normal build is in the local build directory.
Nothing has been pushed; publication requires a separate explicit request.

## Postponed beyond this release

D5 remains postponed by the user. W6 bit 13 stays outside the normal mask.
Remaining checks: catch-up input, Time Compress/mission-exit transitions,
A500 Time Scale 60 and remaining landing/combat outcomes. Existing rate,
input, user-flight and soak evidence is summarized in `w6-verification.md`
and measured in `profiling.md`; no further user flight test is requested now.

Earlier optional W1 cached-CPU extensions, G1/G3 refinements and G5–G9,
S2/S3-prime/S4–S8, broader sound/OS changes and overlay queueing remain deferred
unless a concrete issue justifies them. The completion plan's low-value or
regressing C/E candidates were dropped, not left as release blockers.

50 FPS and frame-independent normal-build gameplay are not release claims.
Further renderer redesign requires a new scope. Historical ledgers remain in
Git; do not revive their superseded next-work lists.

## Post-release rendering investigation

The requested 030/040/060 reprofile is complete; see `rendering-analysis.md` and
the new section of `profiling.md`. It identifies repeated cockpit scripts,
per-plane drawing and explicit waits, and documents why the discarded software
blitter was not a test of a purpose-built Fast RAM renderer. The sparse static
artwork follow-up below is implemented. Full cockpit persistence and a span-renderer redesign
remain separate future work. D5 remains postponed.

## Completed: selective static cockpit artwork repairs

User-authorized after the rendering investigation. Bit 19 now enables sparse,
pixel-guarded repairs for forward static programs 2–4 under Faster rendering on
030/040/060. Unchanged covered pixels are not written; transparent pixels are
never touched. Native artwork is retained on 000/010/020 because pixel checking
regressed or provided no gain on the measured slow CPUs. The reserved renderer
workspace is reused, plus an 8 KB Chip mask; minimum RAM is unchanged.

All six CPU timings and bounded native/view/firing validation are in
`profiling.md`. Native firing scripts, instruments and other views keep their
existing draw order. Full cockpit persistence would additionally need scene
exclusion and narrower dashboard/instrument updates; those are not implemented
by this static-artwork fix. D5 remains postponed.

## Active: scene drawing structure

User-authorized follow-up. Developer/VERIFY bit 20 now contains a private Fast
RAM viewport candidate: direct five-plane rectangles and lines, one coverage
traversal for polygon colour, no inbound page/scratch copy, and one outbound
viewport publication. Native clipping and polygon coverage generation remain;
uncommon operations use a compatibility kernel. Three bounded native primitive
pixel twins pass on 060. Performance and transition validation are pending;
bit 20 is not in the normal verified mask. D5 remains postponed.
