# Red Baron open work

The accepted decisions and detailed requirements are in `performance-plan.md`,
especially §6. `verification.md` is the W0 evidence ledger; `profiling.md`
contains measured baselines. No performance optimization is enabled in normal builds yet.

## W0 complete; W1 core implemented, further work deferred

On the user's instruction, W1 work stops here to prioritize the main geometry
cost. The exact table mirror and chip mirror cache are implemented and committed.
The models, exhaustive CPU word test, synthetic/live mirror twins, pixel twins,
allocation-failure and lifecycle probes pass. The fallback-invalidation regression
is fixed. All three build modes compile and 35 host checks pass.

The nine primary machine/option cases, six corrected-build scene twin boots,
A500/68020 warm-event traces and their bank/dense matrices are complete. Corrected
68030 bank captures are complete; the dense matrix was stopped during its first
case. Completed evidence is retained; incomplete captures are not results.
`profiling.md` records measured costs and rates with their scope and build hashes.

For development, CUSTOM2=3 selects W1a+W1b; CUSTOM2=2 selects only the cache.
The cached 68030 table mirror is slower than the original, so the normal selection
policy excludes it on 030/040/060. **The normal release mask remains zero:** player
switch enablement and its final normal-build checks are deferred. Existing defaults
and icons are unchanged. Developer/VERIFY builds retain individual options.

### Deferred W1 follow-up

- Finish the cached 68030 dense-scene measurements and saved display/hook audit.
- Run the prepared independent cached-68030 cache-only timing/full-flight twin
  check. Earlier cache-only checks passed on the continuity configuration; do not
  label the unrun cached-CPU extension as passed.
- Finish the return-flag contract write-up for the cached draw's caller chain.
- Promote verified bits into the player switch and check normal-build option
  selection when returning to W1. The prepared local promotion helper has not run.
- Further clipping/lifecycle or timing refinements only if a concrete issue calls
  for them; the large existing evidence set is retained.

## Next work

1. **W2 geometry**, continuing in the `sim:2c552` subtree. The G1 projection core
   and G4 dot product have verified developer checkpoints (CUSTOM2 bits 2 and 5);
   see `w2-verification.md`.
   Wrapper integration, wider CPU checks and G2/G3/G5–G9 remain open.
   Each change needs its original-checked Python model and VERIFY twin. This is
   the dominant steady-flight cost; W1 mainly removes dashboard-event stalls.
2. **W5:** tear-free publication and a frame cap under the player switch.
   Measure P1's 68000 cost and choose P2's rate from evidence.
3. **W6 investigation:** continue the game-time investigation and obtain approval
   before implementing a timing design.
4. **W4 and W7:** later measured drawing, world-step and instrument improvements.

## Decisions still required before release

- Default state of the single Faster rendering splash switch.
- Whether supplied icons explicitly enable that switch.
- The W6 timing design, after investigation and a concrete recommendation.
- The measured frame-cap rate and any material 68000 cost of tear-free swapping.

Chip RAM for W1b is approved. Sound work (W3, all S/B candidates) remains deferred.
Until an approved W6 implementation lands, faster frames accelerating the world on
slow machines is an accepted intermediate behavior. Keep Time Scale unchanged in
ordinary development fixtures; 0/60 copies are investigation inputs only.

## Per-feature and release gates

Use one binary with option changes for comparisons; all patches remain sim v1 only.
Each feature needs original-byte checks, whole-instruction/branch/relocation audits,
CUSTOM-off verification, its model/twin checks and the plan's measurement protocol.
The five current performance ranges pass the static hook audit.
Only verified bits may enter the release mask. Keep instruments VERIFY-only and
normal/developer builds free of their code and data. Recheck frame timing, ownership,
chip/slow memory pressure and cache conditions after code/layout changes.

Release packaging, installer/icon edits and publishing are separate from W0. Preserve
JOTD's history, document WHDLoad requirements and measured behavior, and keep each
coherent feature in a separate personal, unsigned commit without hooks or attribution.
