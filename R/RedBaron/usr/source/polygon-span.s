; FC4: direct convex spans, retaining native clipping/fallback and outlines.
; PERF_RANGE sim:2f312 6 bit=24
polygon_span_install:
 movem.l d0-a6,-(sp)
 move.l #$2f312,d0
 moveq #6,d1
 lea .bytes(pc),a0
 lea .check(pc),a4
.check
 adda.l #perf_check_bytes-.check,a4
 jsr (a4)
 lea polygon_span_original+8(pc),a0
 move.l a1,d0
 addi.l #$2f318,d0
 move.l d0,(a0)
 lea polygon_span_done+2(pc),a0
 move.l a1,d0
 addi.l #$2f54e,d0
 move.l d0,(a0)
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 jsr resload_FlushCache(a2)
 movem.l (sp)+,d0-a6
 rts
.bytes: dc.w $3806,$0244,$0001
.patch
 PL_START
 PL_P $2f312,polygon_span
 PL_END
polygon_span:
 movem.l d0-a6,-(sp)
 move.w scene_frame_active(pc),d0
 beq polygon_span_fallback
 ; Native alternating-colour polygons still need their scratch mask.
 move.l scene_primitive_sim(pc),a6
 adda.l #$30000,a6
 tst.w -$39c(a6) ; sim:2fc64, secondary fill colour
 bne polygon_span_fallback
 lea scene_packet(pc),a0
 move.l #3,(a0)
 move.l scene_frame_buffer(pc),4(a0)
 move.l a4,8(a0)
 moveq #0,d0
 move.w d7,d0
 addq.l #1,d0
 move.l d0,12(a0)
 move.l scene_frame_storage(pc),d0
 addi.l #PERF_SCENE_SPAN_ROWS,d0
 move.l d0,16(a0)
 move.l scene_frame_h3(pc),a6
 adda.l #$8000,a6
 moveq #0,d0
 move.w $1d50(a6),d0
 move.l d0,28(a0)
 moveq #0,d0
 move.l d0,32(a0)
 move.l #319,36(a0)
 move.l d0,40(a0)
 move.l #199,44(a0)
 tst.w $1d46(a6)
 beq .bounds_ready
 lea $1d48(a6),a1
 lea 32(a0),a2
 moveq #3,d1
.bounds
 move.w (a1)+,d0
 ext.l d0
 move.l d0,(a2)+
 dbf d1,.bounds
.bounds_ready
 IFD VERIFY
 lea scene_packet(pc),a0
 lea polygon_span_packet(pc),a1
 moveq #11,d0
.save_packet
 move.l (a0)+,(a1)+
 dbf d0,.save_packet
 bsr scene_twin_before
 ENDC
 pea scene_packet(pc)
 lea .kernel(pc),a0
.kernel
 adda.l #scene_raster_selected-.kernel,a0
 move.l (a0),a0
 jsr (a0)
 addq.l #4,sp
 tst.l d0
 beq .painted
 IFD VERIFY
 bsr scene_twin_cancel
 ENDC
 bra polygon_span_fallback
.painted
 IFD VERIFY
 lea polygon_span_outline(pc),a0
 move.w #1,(a0)
 ENDC
 ; Keep the original clipped direct-line outline, once per edge.
 move.l scene_frame_h3(pc),a6
 adda.l #$8000,a6
 move.w $1d52(a6),d5
 cmp.w $1d50(a6),d5
 beq .outlined
 move.l scene_packet+8(pc),a4
 move.l scene_packet+12(pc),d7
 subq.w #1,d7
.outline
 movem.w (a4),d0-d3
 addq.l #4,a4
 move.l scene_primitive_sim(pc),a0
 adda.l #$2ea28,a0
 jsr (a0)
 dbf d7,.outline
.outlined
 IFD VERIFY
 lea polygon_span_outline(pc),a0
 clr.w (a0)
 ; Direct lines use scene_packet too; restore the polygon description.
 lea polygon_span_packet(pc),a0
 lea scene_packet(pc),a1
 moveq #11,d0
.restore_packet
 move.l (a0)+,(a1)+
 dbf d0,.restore_packet
 bsr scene_twin_after
 ENDC
 movem.l (sp)+,d0-a6
polygon_span_done:
 jmp $0.l
polygon_span_fallback
 movem.l (sp)+,d0-a6
polygon_span_original:
 move.w d6,d4
 andi.w #1,d4
 jmp $0.l
 IFD VERIFY
polygon_span_outline: dc.w 0
polygon_span_packet: dcb.l 12,0
 ENDC
