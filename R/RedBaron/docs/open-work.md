# Red Baron open work

The user accepted measured performance on 2026-10-12 and requested completion
of release work. The completion plan remains authoritative with that amendment.

## Release status

No implementation or validation work remains for the accepted release.
F1 enables the normal verified bundle by default; F2 condenses the ledgers;
F3 passes on all six machine configurations, with final results in `profiling.md`
and the ReadMe. The normal verified mask is `0x71fff`, filtered by CPU.
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
blitter was not a test of a purpose-built Fast RAM renderer. The recommended
persistent-cockpit/span-renderer redesign is not implemented or part of the
accepted release. D5 remains postponed.
