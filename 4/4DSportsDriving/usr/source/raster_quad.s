; Four-plane spans: compute endpoints once and keep plane patterns in registers.
; Workspace: edges 0/4, byte row 8, row index 10, height 12, remaining 14,
; plane bases 16..31, even/odd row fills 32..63, stipple words 64/66, flags 68.
raster_quad:
 move.l a4,-(sp)
 lea -80(sp),sp
 move.l sp,a6
 move.l -$36(a5),(a6)
 move.l -$32(a5),4(a6)
 move.w -$2e(a5),d0
 mulu #40,d0
 move.w d0,8(a6)
 clr.w 10(a6)
 move.w -$2c(a5),d0
 move.w d0,12(a6)
 subq.w #1,d0
 move.w d0,14(a6)
 movem.l $bfe(a4),d0-d3
 movem.l d0-d3,16(a6)
 clr.w 68(a6)
 moveq #-1,d0
 move.l d0,64(a6)
 move.w raster_kind(pc),d0
 bne .colours
 move.w #1,68(a6)
 btst #0,-$3a3a(a4)
 beq .colours
 or.w #2,68(a6)
 move.l -$3a38(a4),d0
 btst #0,13(a6)
 bne .stipple
 swap d0
.stipple:
 move.l d0,64(a6)
.colours:
 lea .merge_generic(pc),a0
 move.w raster_kind(pc),d0
 bne .writer_ready
 move.w -$2a(a5),d0
 and.w #15,d0
 add.w d0,d0
 lea raster_solid_writers(pc),a0
 move.w (a0,d0.w),d0
 adda.w d0,a0
.writer_ready:
 move.l a0,72(a6)
 lea 32(a6),a0
 lea 48(a6),a1
 moveq #0,d7
.colour:
 move.w -$2a(a5),d3
 moveq #-1,d0
 btst d7,d3
 bne .c1
 moveq #0,d0
.c1:
 move.w raster_kind(pc),d2
 beq .same
 move.w -$28(a5),d3
 moveq #-1,d1
 btst d7,d3
 bne .c2
 moveq #0,d1
.c2:
 cmp.l d0,d1
 beq .same
 move.l -$26(a5),d2
 tst.l d0
 bne .pattern
 not.l d2
.pattern:
 move.w d2,d1
 swap d1
 move.w d2,d1
 swap d2
 move.w d2,d0
 swap d0
 move.w d2,d0
 bra .store
.same:
 move.l d0,d1
.store:
 move.l d0,(a0)+
 move.l d1,(a1)+
 addq.w #1,d7
 cmp.w #4,d7
 blo .colour
.row:
 move.l (a6),a0
 move.l 4(a6),a1
 move.w (a0)+,d0
 move.w (a1)+,d1
 move.l a0,(a6)
 move.l a1,4(a6)
 cmp.w d0,d1
 blt .next
 bne .draw
 btst #0,69(a6)
 beq .draw
 btst #0,11(a6)
 bne .draw
 move.w 12(a6),d2
 and.w #$fff8,d2
 cmp.w 10(a6),d2
 bls .draw
 move.w (a0),d2
 cmp.w (a1),d2
 bgt .next
.draw:
 lea 32(a6),a4
 btst #0,11(a6)
 beq .fills
 lea 48(a6),a4
.fills:
 movem.l (a4),d4-d7
 move.w d0,d2
 lsr.w #5,d2
 lsl.w #2,d2
 add.w 8(a6),d2
 movem.l 16(a6),a0-a3
 adda.w d2,a0
 adda.w d2,a1
 adda.w d2,a2
 adda.w d2,a3
 move.w d1,d3
 lsr.w #5,d3
 move.l d0,a4
 lsr.w #5,d0
 sub.w d0,d3
 move.w a4,d0
 and.w #31,d0
 moveq #-1,d2
 lsr.l d0,d2
 move.l d2,d0
 and.w #31,d1
 eor.w #31,d1
 moveq #-1,d2
 lsl.l d1,d2
 move.l d2,d1
 movea.w #-1,a4
 btst #1,69(a6)
 beq .mask_ready
 move.w 10(a6),d2
 and.w #1,d2
 add.w d2,d2
 move.w 64(a6,d2.w),d2
 move.w d2,a4
 swap d2
 move.w a4,d2
 move.l d2,a4
 and.l d2,d0
 and.l d2,d1
.mask_ready:
 move.l a4,76(a6)
 move.l 72(a6),a4
 tst.w d3
 bne .multiple
 and.l d1,d0
 bsr .merge
 bra .next
.multiple:
 bsr .merge
 subq.w #2,d3
 bmi .last
 move.l 76(a6),d2
 cmp.l #-1,d2
 beq .middle
 move.l d2,d0
.masked_middle:
 bsr .merge
 dbra d3,.masked_middle
 bra .last
.middle:
 move.l d4,(a0)+
 move.l d5,(a1)+
 move.l d6,(a2)+
 move.l d7,(a3)+
 dbra d3,.middle
.last:
 move.l d1,d0
 bsr .merge
.next:
 add.w #40,8(a6)
 addq.w #1,10(a6)
 subq.w #1,14(a6)
 bpl .row
 lea 80(sp),sp
 move.l (sp)+,a4
 rts
.merge:
 jmp (a4)
.merge_generic:
 move.l (a0),d2
 eor.l d4,d2
 and.l d0,d2
 eor.l d2,(a0)+
 move.l (a1),d2
 eor.l d5,d2
 and.l d0,d2
 eor.l d2,(a1)+
 move.l (a2),d2
 eor.l d6,d2
 and.l d0,d2
 eor.l d2,(a2)+
 move.l (a3),d2
 eor.l d7,d2
 and.l d0,d2
 eor.l d2,(a3)+
 rts

; Static colour writers: only one is hot for a solid polygon.
raster_solid_writers:
 dc.w raster_solid_0-raster_solid_writers,raster_solid_1-raster_solid_writers,raster_solid_2-raster_solid_writers,raster_solid_3-raster_solid_writers,raster_solid_4-raster_solid_writers,raster_solid_5-raster_solid_writers,raster_solid_6-raster_solid_writers,raster_solid_7-raster_solid_writers,raster_solid_8-raster_solid_writers,raster_solid_9-raster_solid_writers,raster_solid_10-raster_solid_writers,raster_solid_11-raster_solid_writers,raster_solid_12-raster_solid_writers,raster_solid_13-raster_solid_writers,raster_solid_14-raster_solid_writers,raster_solid_15-raster_solid_writers
raster_solid_0:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 and.l d2,(a1)+
 and.l d2,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_1:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 and.l d2,(a1)+
 and.l d2,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_2:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 or.l d0,(a1)+
 and.l d2,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_3:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 or.l d0,(a1)+
 and.l d2,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_4:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 and.l d2,(a1)+
 or.l d0,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_5:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 and.l d2,(a1)+
 or.l d0,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_6:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 or.l d0,(a1)+
 or.l d0,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_7:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 or.l d0,(a1)+
 or.l d0,(a2)+
 and.l d2,(a3)+
 rts
raster_solid_8:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 and.l d2,(a1)+
 and.l d2,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_9:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 and.l d2,(a1)+
 and.l d2,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_10:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 or.l d0,(a1)+
 and.l d2,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_11:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 or.l d0,(a1)+
 and.l d2,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_12:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 and.l d2,(a1)+
 or.l d0,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_13:
 move.l d0,d2
 not.l d2
 or.l d0,(a0)+
 and.l d2,(a1)+
 or.l d0,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_14:
 move.l d0,d2
 not.l d2
 and.l d2,(a0)+
 or.l d0,(a1)+
 or.l d0,(a2)+
 or.l d0,(a3)+
 rts
raster_solid_15:
 or.l d0,(a0)+
 or.l d0,(a1)+
 or.l d0,(a2)+
 or.l d0,(a3)+
 rts
