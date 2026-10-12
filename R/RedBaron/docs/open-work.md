# Red Baron open work

The user accepted measured performance on 2026-10-12 and requested completion
of release work. The completion plan remains authoritative with that amendment.

## Required for this release

- F2: finish documentation condensation and commit it.
- F3: final builds, host tests, hook/reach audits, explicit disabled-byte check,
  and normal-build scoreboard refresh on all six machine configurations; commit.
- Replace the ReadMe's pending results with the final measured summary.

F1 is committed: Faster rendering defaults On, normal CUSTOM2=0 is On and 1 is
Off. Developer/VERIFY values remain bit masks; zero disables their patches.
The verified mask is `0x71fff` with CPU filtering. No push is authorized.

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
