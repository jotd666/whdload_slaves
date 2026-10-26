; Fast solid spans in the contiguous four-plane staging bitmap.
; Each colour writer and the shared row loop fit the 020 instruction cache.
; No mutable code. The native span arrays and its empty-next-row quirk survive.
raster_solid_fast:
 movem.l a4-a6,-(sp)
 subq.l #8,sp
 move.w -$2c(a5),d5
 move.w d5,d0
 and.w #7,d0
 move.w d0,4(sp)
 subq.w #1,d5
 move.w d5,6(sp)
 move.w -$2e(a5),d6
 mulu #40,d6
 move.l $bfe(a4),a0
 adda.l d6,a0
 move.l a0,(sp)
 move.w -$2a(a5),d0
 and.w #15,d0
 add.w d0,d0
 lea raster_solid_fast_table(pc),a4
 move.w (a4,d0.w),d0
 adda.w d0,a4
 move.l -$36(a5),a0
 move.l -$32(a5),a6
 move.l a0,a5
 moveq #0,d4
 moveq #-1,d7
.row:
 move.w (a5)+,d0
 move.w (a6)+,d1
 cmp.w d0,d1
 blt .next
 bne .draw
 move.w 6(sp),d2
 eor.w d5,d2
 btst #0,d2
 bne .draw
 cmp.w 4(sp),d5
 blo .draw
 move.w (a5),d2
 cmp.w (a6),d2
 bgt .next
.draw:
 move.w d0,d2
 lsr.w #5,d2
 move.w d1,d3
 lsr.w #5,d3
 sub.w d2,d3
 lsl.w #2,d2
 move.l (sp),a0
 adda.w d2,a0
 lea 8000(a0),a1
 lea 8000(a1),a2
 lea 8000(a2),a3
 and.w #31,d0
 move.l d7,d2
 lsr.l d0,d2
 move.l d2,d0
 and.w #31,d1
 eor.w #31,d1
 move.l d7,d2
 lsl.l d1,d2
 move.l d2,d1
 jsr (a4)
.next:
 add.l #40,(sp)
 dbra d5,.row
 addq.l #8,sp
 movem.l (sp)+,a4-a6
 rts
raster_solid_fast_table:
 dc.w raster_solid_fast_0-raster_solid_fast_table,raster_solid_fast_1-raster_solid_fast_table,raster_solid_fast_2-raster_solid_fast_table,raster_solid_fast_3-raster_solid_fast_table,raster_solid_fast_4-raster_solid_fast_table,raster_solid_fast_5-raster_solid_fast_table,raster_solid_fast_6-raster_solid_fast_table,raster_solid_fast_7-raster_solid_fast_table,raster_solid_fast_8-raster_solid_fast_table,raster_solid_fast_9-raster_solid_fast_table,raster_solid_fast_10-raster_solid_fast_table,raster_solid_fast_11-raster_solid_fast_table,raster_solid_fast_12-raster_solid_fast_table,raster_solid_fast_13-raster_solid_fast_table,raster_solid_fast_14-raster_solid_fast_table,raster_solid_fast_15-raster_solid_fast_table
raster_solid_fast_0:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d4,(a0)+
 move.l d4,(a1)+
 move.l d4,(a2)+
 move.l d4,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 and.l d2,(a1)+
 and.l d2,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_fast_1:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d7,(a0)+
 move.l d4,(a1)+
 move.l d4,(a2)+
 move.l d4,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 and.l d2,(a1)+
 and.l d2,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_fast_2:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d4,(a0)+
 move.l d7,(a1)+
 move.l d4,(a2)+
 move.l d4,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 or.l d0,(a1)+
 and.l d2,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_fast_3:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d7,(a0)+
 move.l d7,(a1)+
 move.l d4,(a2)+
 move.l d4,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 or.l d0,(a1)+
 and.l d2,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_fast_4:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d4,(a0)+
 move.l d4,(a1)+
 move.l d7,(a2)+
 move.l d4,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 and.l d2,(a1)+
 or.l d0,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_fast_5:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d7,(a0)+
 move.l d4,(a1)+
 move.l d7,(a2)+
 move.l d4,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 and.l d2,(a1)+
 or.l d0,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_fast_6:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d4,(a0)+
 move.l d7,(a1)+
 move.l d7,(a2)+
 move.l d4,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 or.l d0,(a1)+
 or.l d0,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_fast_7:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d7,(a0)+
 move.l d7,(a1)+
 move.l d7,(a2)+
 move.l d4,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 or.l d0,(a1)+
 or.l d0,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_fast_8:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d4,(a0)+
 move.l d4,(a1)+
 move.l d4,(a2)+
 move.l d7,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 and.l d2,(a1)+
 and.l d2,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_fast_9:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d7,(a0)+
 move.l d4,(a1)+
 move.l d4,(a2)+
 move.l d7,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 and.l d2,(a1)+
 and.l d2,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_fast_10:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d4,(a0)+
 move.l d7,(a1)+
 move.l d4,(a2)+
 move.l d7,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 or.l d0,(a1)+
 and.l d2,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_fast_11:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d7,(a0)+
 move.l d7,(a1)+
 move.l d4,(a2)+
 move.l d7,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 or.l d0,(a1)+
 and.l d2,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_fast_12:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d4,(a0)+
 move.l d4,(a1)+
 move.l d7,(a2)+
 move.l d7,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 and.l d2,(a1)+
 or.l d0,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_fast_13:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d7,(a0)+
 move.l d4,(a1)+
 move.l d7,(a2)+
 move.l d7,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 and.l d2,(a1)+
 or.l d0,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_fast_14:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d4,(a0)+
 move.l d7,(a1)+
 move.l d7,(a2)+
 move.l d7,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 or.l d0,(a1)+
 or.l d0,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_fast_15:
 tst.w d3
 bne .multiple
 and.l d1,d0
 bra .boundary
.multiple:
 bsr .boundary
 subq.w #2,d3
 bmi .last
.middle:
 move.l d7,(a0)+
 move.l d7,(a1)+
 move.l d7,(a2)+
 move.l d7,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
.boundary:
 or.l d0,(a0)+
 or.l d0,(a1)+
 or.l d0,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_fast_end:
