# W4 solid rectangle fills

## Contract and scope

D1 is developer/VERIFY CUSTOM2 bit 7 (128), installed only by the sim v1
performance installer. Normal player enablement remains zero pending W5/release.
The ten original bytes at `sim:2fd2c` are checked before replacing the initial
BLTCON0 value and custom-register base setup. With bit 7 off they remain intact.
No clipping, plane loop, pointer, pitch, BLTSIZE, wait or BLTPRI policy changes.

The original solid rectangle routine `sim:2fc68` computes two A edge masks in d7,
sets BLTADAT to all ones and uses unshifted A with BLTCON1=0. The per-plane
minterms FA/0A implement `(A & colour) | (~A & C)`. When **both masks are ffff**,
A is all ones for every word and C is irrelevant. D1 changes the initial control
word from 03fa to 01fa, disabling C DMA. The original loop still chooses the
set/clear minterm from the colour. Any masked edge retains C+D, including a
single word carrying both masks. This also safely covers aligned narrow spans,
not just the full-width sky/ground calls at `sim:2cddc` and `sim:2cf90`.

Before implementation, the straight 68000 instruction budget was 20 cycles for
the displaced MOVE/LEA versus about 94 for the aligned detour and 88 for the
masked detour, including absolute JSR, two NOPs and RTS: **74/68 added cycles per
rectangle**, independent of its plane count and area, before contention.
Each optimized destination word removes one chip read. This is the small/simple
exception to the plan's 3% threshold, not a promised frame-rate improvement.
The production module adds 96 text bytes to the previous normal/developer build.

The setup's temporary flags are dead before subsequent original setup writes;
X is unchanged. d4's high word is retained. The eventual C pointer/data latch
is allowed to differ: following C-using primitives either fetch C or explicitly
supply BLTCDAT (`sim:2ed1e`, `sim:2fb8c`, `sim:2fc22`, `sim:2fc46`). No code
reads these write-only custom registers as game state. Destination pixels,
remaining registers and the original asynchronous last-plane behavior remain
unchanged in production. Doubled `btst` waits remain intact.

## Independent model and live pixel twin

`tools/fill_model.py` evaluates the actual minterm truth table, separately from
its per-pixel reference. Tests cover all 51,360 horizontal rectangles of a
320-pixel row, both colours, varying background words and masked single-word
edges. Every possible stale 16-bit C value is tested for the D-only minterms.
The full host suite has 56 passing tests; the static sim audit has ten whole
instruction ranges and no direct branch/relocation into a hook interior.

VERIFY CUSTOM5 bit 16 enables the pixel twin, only alongside D1. It hooks
`sim:2fd8a`, after the existing wait and before the plane's BLTSIZE write:

1. Save every affected destination word.
2. Run the original C+D blit and wait for completion; save its output.
3. Restore the exact input words, reset the original pointers and launch the
   selected D-only or masked C+D blit.
4. Wait and compare every output word with the original hardware output.

Thus this is a same-input hardware pixel twin, not a screenshot A/B comparison.
Masked edge bits are compared too. Bounds are explicit: 1–20 words, 1–256 lines,
nonnegative modulo calculated from the original pitch at `h3:09d42`. Invalid
bounds or unequal pixels abort. Two VERIFY-only 10 KiB buffers hold input/output;
no production allocation is added. Counters at `RBFILL01` record total, D-only,
masked and compared words. Do not combine this mode with CUSTOM5 bit 3's paint
observer: it owns the same hook. Twin timings are never performance evidence.

An initial verifier run stopped on its bounds guard because the pitch observer
used an unnormalized live-disassembly address. The hunk relocation established
`h3:09d42`; that instrumentation-only error was corrected before accepted runs.

Accepted VERIFY build SHA256:
`18395ab2cc6fc1271b6b9e56919bf98c2fe8e3ea886f8e7bbd76a2354ef33241`.
Through step 40, same-input hardware comparisons pass on all three machines:

| CPU / route | Plane twins | D-only | Masked | Compared words |
|---|---:|---:|---:|---:|
| A500 / steady | 2,545 | 395 | 2,150 | 673,375 |
| 68020 / bank | 2,390 | 230 | 2,160 | 456,925 |
| Cached 68030 / dense | 610 | 395 | 215 | 794,970 |

Evidence: `tmp/dev/tmp/prof/w4-twin-{a500,020,030}-r2/`. Each stores the
matched slave/listing, entry metadata, bounded debugger log and counter header.
Normal/developer/VERIFY text sizes are 9,752 / 9,900 / 87,286 bytes.
Performance measurements use separate fresh boots with the pixel twin disabled.
