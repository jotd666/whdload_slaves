# Red Baron open work

The accepted decisions and detailed requirements are in `performance-plan.md`,
especially §6. `verification.md` is the W0 evidence ledger; `profiling.md`
contains measured baselines. No performance optimization is enabled yet.

## W0 complete; W1 in progress

The final same-build A500-equivalent, A1200/14 MHz 68020 and cached 50 MHz
68030 event/steady baselines are complete. The acceptance ledger records the
four strict scene repeats, counter and gap checks, full dashboard census,
scoped game-time coupling test, patch framework and initial references.
W1a is now implemented for developer/VERIFY testing; its full measurement gates
are pending. The release mask remains zero. See `w1-verification.md` for evidence
and remaining W1a/W1b work.

## Implementation order after W0

1. **W1a:** exact table-driven dashboard mirror. Keep WaitBlit on entry, build
   the exhaustive word self-test and copied-input/live twins, then measure all
   required windows and machines. Declare/audit hook ranges and verify the off path.
2. **W1b:** approved pre-mirrored chip-RAM cache, with invalidation at
   `sim:303c6`, allocation-failure fallback, mask/descriptor checks and pixel twins.
3. **W2:** geometry G1–G9 in the plan's order. Each replacement needs a Python
   model checked against the original and a VERIFY twin covering its live flags,
   registers, outputs, uncommon inputs and relevant scenes.
4. **W5:** tear-free publication and a frame cap under the player switch.
   Measure P1's 68000 cost and choose P2's rate from evidence. Retain the
   observed raster/ownership distinction in the fast-CPU checks.
5. **W6 investigation alongside W1–W2:** extend `game-time.md` with force,
   ground-contact, collision, projectile and equal-wall-time experiments.
   Evaluate bounded/fixed simulation steps, the >400 shortcut, signed rounding,
   input cadence and per-frame counters. Obtain approval for the recommended
   design before implementing game-time changes.
6. **W4 and W7:** smaller drawing, world-step and instrument work only after
   measurement demonstrates value.

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
Empty performance-range audits remain pending until the first feature declares ranges.
Only verified bits may enter the release mask. Keep instruments VERIFY-only and
normal/developer builds free of their code and data. Recheck frame timing, ownership,
chip/slow memory pressure and cache conditions after code/layout changes.

Release packaging, installer/icon edits and publishing are separate from W0. Preserve
JOTD's history, document WHDLoad requirements and measured behavior, and keep each
coherent feature in a separate personal, unsigned commit without hooks or attribution.
