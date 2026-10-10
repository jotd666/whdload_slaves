; Fractional position kernels; not yet connected to live geometry.
; Collect the exact discarded Q14 remainder of each native matrix dot product.
; A0 three signed vector words; A1 nine column-major signed matrix words;
; A2 three long accumulators. Preserve all registers; CCR unspecified.
; Negative products use floor remainders too: low14 bits are nonnegative.
sim_centroid_collect:
 movem.l d0-d4/a2-a3,-(sp)
 movea.l a1,a3
 moveq #2,d4
.axis:
 move.w (a0),d0
 muls (a3),d0
 move.w 2(a0),d1
 muls 6(a3),d1
 add.l d1,d0
 move.w 4(a0),d1
 muls 12(a3),d1
 add.l d1,d0
 and.l #$3fff,d0
 add.l d0,(a2)+
 addq.l #2,a3
 dbra d4,.axis
 movem.l (sp)+,d0-d4/a2-a3
 rts

; D0.L signed sum of four integer wheel coordinates; D1.L sum of discarded
; Q14 projection remainders (0..8*16383); A0 unsigned Q16 position carry.
; Return D0.L floor((sum*16384 + projection + oldcarry)/65536), and save
; the unsigned remainder. Preserve D1-D3/A0; CCR unspecified.
; Avoid sum*16384 overflow by splitting the signed quarter and its remainder.
sim_centroid_average:
 movem.l d1-d3,-(sp)
 move.l d0,d2
 and.l #3,d2
 lsl.l #8,d2
 lsl.l #6,d2
 add.l d1,d2
 moveq #0,d3
 move.w (a0),d3
 add.l d3,d2
 move.w d2,(a0)
 swap d2
 and.l #$ffff,d2
 asr.l #2,d0
 add.l d2,d0
 movem.l (sp)+,d1-d3
 rts
