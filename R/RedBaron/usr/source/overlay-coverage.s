; E2 combined-copy coverage extraction from two native opaque/preserve draws.
; Only use for destination-local bitwise drawing, never framebuffer shifts
; or copies between pixels/planes: endpoint draws cannot detect those.
; This standalone primitive is not yet included in the slave or installed.
; a0: native output drawn over zero (40000 bytes, five 8000-byte planes).
; a1: identical draw/input/context over all ones (same layout).
; a2: private 8000-byte mask destination, disjoint from both input buffers.
; Inputs/output must be allocated and even-aligned. No DMA is started here.
; d0=1 on success, 0 for inversion or plane-dependent coverage.
; All other registers are preserved. On failure, discard the partial mask.
;
; For a bit: (zero,one) 00/11 means opaque, 01 means preserve, 10 means
; invert and is rejected. The preserve bits must agree in all five planes.
; Unlike OR-of-colour-planes, this retains opaque black pixels.
overlay_coverage:
 movem.l d1-d7/a0-a4,-(sp)
 move.w #1999,d7
.word
 move.l a0,a3
 move.l a1,a4
 moveq #4,d6
 moveq #-1,d4
.plane
 move.l (a3),d1
 move.l (a4),d2
 move.l d2,d3
 not.l d3
 and.l d1,d3
 bne .bad
 eor.l d1,d2
 cmpi.w #4,d6
 bne .compare
 move.l d2,d4
 bra .next_plane
.compare
 cmp.l d4,d2
 bne .bad
.next_plane
 adda.l #8000,a3
 adda.l #8000,a4
 dbf d6,.plane
 not.l d4
 move.l d4,(a2)+
 addq.l #4,a0
 addq.l #4,a1
 dbf d7,.word
 moveq #1,d0
 bra .done
.bad
 moveq #0,d0
.done
 movem.l (sp)+,d1-d7/a0-a4
 rts
