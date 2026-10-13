# Step 5 rendering work

Step 5 is in progress. Step 4's accepted clock/cost exceptions and deferred
P3/full-lap checks remain unchanged. All measurements below use the step-4
phase solver and sweep path, with a separate renderer switch so its disabled
arm retains the same simulation. No release default has changed.

## Candidate order and scope

The current A500 A trace spends 14.61% in the two word vertex rotations,
17.33% in polygon spans, 5.40% in clipping/bounds, 4.12% in background fill,
and 4.05% in edge setup/row generation. These are direct instruction ranges,
not inclusive shares to add to their callees. Attract and gameplay B have
different workloads. The existing code already has early clipping accept/reject
and unrolled longword CPU background stores. Replacing these by the same
techniques would not provide a gain.

The span census finds uniform solid patterns in 1,479/2,141 A polygons and
1,502/1,853 B polygons. Masked boundaries cost 5.93% / 4.72% of the respective
traces; unrolled solid interiors cost 2.78% / 3.69%. A replacement must price
its dispatch and preserve patterned fills before claiming the whole filler
share as available savings. Span work is not yet complete.

## Exact word rotation shortcuts

`HardDrivinRotation.s` replaces native Y/X rotations at $02a2e/$02a7a.
The general four-product arithmetic is unchanged. A zero coefficient skips
its two products; a quarter turn uses signed copies/negation without any
multiplication. The final X flag comes from the native last product's bit 30,
including the signed-word endpoint. Negative/zero counts, overlapping input
and output, word wrapping, stack and outgoing registers are preserved.

The pre-implementation A500 A trace has 21,763 zero-coefficient vertices out
of 35,163 input observations. A zero MULS costs at least 38 cycles on 68000;
quarter turns remove four products, against at most 32 cycles of negation/
X handling per vertex and a per-call dispatch. The general path adds at most
58 cycles per nonempty call, including the entry jump and word branches. Actual range costs and whole-window swaps are measured
separately; this static bound is not a performance result.

Validation completed:

- 6,000 native/Python-model/assembled comparisons cover signed random words,
  zero coefficients, arithmetic wrap, overlapping buffers, negative/zero
  counts, the complete guarded memory region, registers, stack and all CCR bits.
- The independent model matches 35,134 actual native A500 and 132,209 native
  A1200 vertex input/output pairs in retained traces.
- All 150 audited patch ranges have no external direct branch into their middle.
  The two rotation entry patches cover eight complete native instruction bytes.
- The ordinary build is byte-identical to its step-2 baseline; its fresh disabled
  capture passes every declared game patch range.
- A separate 68040 MMU-enabled run completes 500 fields with populated cockpit
  output and unchanged game code. Its 344 swaps are functional evidence only.
- All 18 completed 68000/020 matrix traces retain identical game-code bytes
  before and after the window. This is observed coverage, not a static proof
  about every unvisited code-writing path.

Each matrix interval is 500 PAL fields (10.015944 seconds). Values are swaps
with rotation off / on in the same build. Simulation remains enabled in both.

| Profile | Gameplay A | Gameplay B | Attract |
| --- | ---: | ---: | ---: |
| A500 | 39 / 41 | 58 / 59 | 67 / 72 |
| A500 + Fast | 40 / 42 | 60 / 60 | 69 / 73 |
| A1200/020 | 150 / 159 | 222 / 222 | 231 / 237 |
| 030/50 | 251 / 251 | 323 / 325 | 349 / 349 |
| 040/25 | matrix running | matrix running | matrix running |
| 040/40 | 244 / 247 | 276 / 278 | 297 / 306 |
| 060/50 | 246 / 248 | 273 / 274 | 300 / 309 |

These are whole-window observations, not an equal-scene or original-game net
speedup claim. Native clock observations and simulation/render cadence can
change the workload. The 68000/020 results use instruction traces; faster
profiles use the established independent swap counter because their routine
instruction timing is unavailable. The complete matrix and final selection
remain outstanding.

## Fast edge-array experiment

Code, globals, vertex data and patterns already use Fast RAM where available.
The two 200-word edge arrays share an 800-byte native Chip pool reservation.
Only the CPU reads/writes these arrays. The experiment allocates an additional
800 bytes of Fast RAM, retains the native pool reservation so later Chip
addresses stay unchanged, and substitutes the two edge pointers. Screens,
sprites, copper and blitter data stay in Chip RAM. Failure to allocate Fast RAM
leaves the original instructions installed. The ordinary path excludes 68000;
`VERIFY_RENDER_000_MEMORY` exists only to test that profile independently.

The initialization hook passes 224 register/stack/CCR cases. An initial A1200
variable-input A window gives 203/196 swaps by the independent counter and
200/196 by instruction trace. Do not mix those instruments or fixtures with
the constant-input matrix above. The trace edge-row cost per store drops from
11.29 to 8.17 cycles, but its total frame share is only 1.00% before the change;
the complete window does not improve. The option remains experimental and is
not selected for the rotation matrix. A500+Fast memory-placement measurement
and any broader promotion remain undone.

## Gates, cache and evidence

`VERIFY_RENDER` compiles the candidate module for SPS 0126 only. Developer-only
CUSTOM3 bit 0 selects the Fast edge-array experiment; bit 1 selects rotation
shortcuts on the 68000 instruction set and successors. These options are not
release configuration. The boot patch is followed by the existing final cache
flush. The existing slave already enables hardware instruction/data caches
where present; no new cache setting has been promoted.

Local evidence: `s5-rotation-contract.json`, `s5-memory-contract.json`,
`s5-rotation-branches.json`, `s5-normal-disabled`, `s5-rot-mmu-040`,
`s5-rot-v2-*` / `s5-rot-v2r-*`, and `s5-mem-020-*`. Each capture retains its
exact slave, listing, inputs and configuration. Completed traces are compressed
only after decompressed SHA-256 verification; only dead owned runtimes are
removed. Failed long Unix-socket-name attempts are not performance evidence.

Remaining work: complete/aggregate the machine matrix, select CPU paths,
complete the cache/code-write audit, evaluate the worthwhile span/edge/rotation,
background, blitter-wait and cockpit candidates, and perform required guarded
rendering comparisons for any pixel-loop replacement. Step 5 is not complete.
