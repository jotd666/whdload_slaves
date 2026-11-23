; Collect reconstruction fractions only at50Hz; native collision coordinates
; remain integer. Scratch is overwritten at every C270 car update, before the
; first wheel projection, and is never used across simulation boundaries.
sim_centroid_begin:
 move.l a2,-(sp)
 lea sim_centroid_scratch(pc),a2
 clr.l (a2)+
 clr.l (a2)+
 clr.l (a2)
 move.l (sp)+,a2
 rts

sim_centroid_project:
 cmp.w #50,-$15fa(a4)
 bne .native
 movem.l d4/a2,-(sp)
 moveq #0,d4
 addx.w d4,d4
 move.w d4,-(sp)
 lea sim_centroid_scratch(pc),a2
 bsr sim_centroid_collect
 move.w (sp)+,d4
 lsr.w #1,d4              ; preserve incoming X for the native transform
 movem.l (sp)+,d4/a2
.native:
 jmp -$7bd8(a4)

sim_centroid_build:
 bsr sim_centroid_project
 bsr sim_tilt_collect
 movea.w -$46(a5),a0      ; displaced C524
 rts
sim_centroid_suspension:
 bsr sim_centroid_project
 movea.w -$52(a5),a0      ; displaced D2F4
 rts

; Replace D346..D388: the same four-wheel sums and native fallback average.
; D0 retains the final Z result; preserve all other registers.
sim_centroid_body:
 movem.l d1-d2/a0-a3,-(sp)
 lea -$85e(a4),a0
 cmpa.l 8(a5),a0
 lea sim_a4000_private+132(pc),a0
 bne .player
 addq.l #6,a0
.player:
 lea -$b2(a5),a1
 lea sim_centroid_scratch(pc),a2
 lea $b9c(a4),a3
 moveq #2,d2
.axis:
 move.l (a1),d0
 add.l 12(a1),d0
 add.l 24(a1),d0
 add.l 36(a1),d0
 cmp.w #50,-$15fa(a4)
 bne .native
 move.l (a2),d1
 bsr sim_centroid_average
 bra .store
.native:
 asr.l #2,d0
.store:
 move.l d0,(a3)+
 addq.l #4,a1
 addq.l #4,a2
 addq.l #2,a0
 dbra d2,.axis
 movem.l (sp)+,d1-d2/a0-a3
 rts

; Discard only the coordinate carry whose native position was clamped.
; D0 axis byte offset0/2/4. Preserve registers and X; following native code
; overwrites NZVC before consuming them at all five patch sites.
sim_centroid_clear_axis:
 cmp.w #50,-$15fa(a4)
 bne .done
 move.l a0,-(sp)
 lea -$85e(a4),a0
 cmpa.l 8(a5),a0
 lea sim_a4000_private+132(pc),a0
 bne .player
 addq.l #6,a0
.player:
 adda.l d0,a0
 clr.w (a0)
 move.l (sp)+,a0
.done:
 rts
sim_centroid_floor:
 tst.l $ba0(a4)
 bge .done
 clr.l $ba0(a4)
 move.l d0,-(sp)
 moveq #2,d0
 bsr sim_centroid_clear_axis
 move.l (sp)+,d0
.done:
 rts
sim_centroid_xmax:
 move.l #$1df0ff,$b9c(a4)
 bra sim_centroid_clear_x
sim_centroid_xmin:
 move.l #$f00,$b9c(a4)
sim_centroid_clear_x:
 move.l d0,-(sp)
 moveq #0,d0
 bsr sim_centroid_clear_axis
 move.l (sp)+,d0
 rts
sim_centroid_zmax:
 move.l #$1df0ff,$ba4(a4)
 bra sim_centroid_clear_z
sim_centroid_zmin:
 move.l #$f00,$ba4(a4)
sim_centroid_clear_z:
 move.l d0,-(sp)
 moveq #4,d0
 bsr sim_centroid_clear_axis
 move.l (sp)+,d0
 rts
 even
sim_centroid_scratch: dcb.l 3,0
