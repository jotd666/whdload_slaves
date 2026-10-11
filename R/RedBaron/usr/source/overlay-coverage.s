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

; Fold a later layer into a private combined cache, in native draw order.
; a0=source image (40000), a1=source mask (8000), a2=combined image (40000),
; a3=combined mask (8000). Five planes, stride8000; all buffers even-aligned.
; Source and destination allocations are disjoint; destinations start cleared
; before the first layer. No DMA or game framebuffer access. Caller owns bounds.
; On return the destination represents both layers with one shared mask.
; All registers preserved; CCR volatile. Only the cache-fill path calls this.
; Opaque black overwrites earlier colour; transparent source bytes do not.
overlay_combine:
 movem.l d0-d5/a0-a5,-(sp)
 move.w #1999,d4
.word
 move.l (a1)+,d0
 beq .transparent
 or.l d0,(a3)
 move.l a0,a4
 move.l a2,a5
 moveq #4,d3
 cmpi.l #-1,d0
 beq .opaque
 move.l d0,d1
 not.l d1
.partial
 move.l (a4),d2
 and.l d0,d2
 move.l (a5),d5
 and.l d1,d5
 or.l d5,d2
 move.l d2,(a5)
 adda.l #8000,a4
 adda.l #8000,a5
 dbf d3,.partial
 bra .transparent
.opaque
 move.l (a4),(a5)
 adda.l #8000,a4
 adda.l #8000,a5
 dbf d3,.opaque
.transparent
 addq.l #4,a0
 addq.l #4,a2
 addq.l #4,a3
 dbf d4,.word
 movem.l (sp)+,d0-d5/a0-a5
 rts
