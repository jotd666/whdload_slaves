; Direct five-plane primitives, internal feature bit 20, scene ownership only.
scene_primitives_install:
 movem.l d0-a6,-(sp)
 move.l a1,a5
 ; raster kernels changes no additional game bytes. Bit 26 selects the private kernel;
 ; bit 20 alone retains the previous implementation in the same binary.
 lea .old_kernel(pc),a0
.old_kernel
 adda.l #scene_raster_code-.old_kernel,a0
 lea .mask(pc),a3
.mask
 adda.l #perf_mask-.mask,a3
 btst #2,(a3)
 beq .kernel_ready
 lea .fast_kernel(pc),a0
.fast_kernel
 adda.l #scene_raster_fast_code-.fast_kernel,a0
.kernel_ready
 lea scene_raster_selected(pc),a3
 move.l a0,(a3)
 move.l a1,a4
 adda.l #$30000,a4
 lea scene_primitive_sim(pc),a0
 move.l a1,(a0)
 ; Validate complete instruction prefixes, including relocated data operands.
 cmpi.w #$48a7,-$32a(a4)
 bne scene_frame_bad
 cmpi.w #$f000,-$328(a4)
 bne scene_frame_bad
 cmpi.w #$4a79,-$326(a4)
 bne scene_frame_bad
 move.l scene_frame_h3(pc),d0
 addi.l #$9d54,d0
 cmp.l -$324(a4),d0
 bne scene_frame_bad
 cmpi.l #$2c3c7352,-$146a(a4)
 bne scene_frame_bad
 cmpi.w #$6140,-$1466(a4)
 bne scene_frame_bad
 cmpi.w #$2039,-$b7c(a4)
 bne scene_frame_bad
 lea scene_poly_original(pc),a0
 move.l -$b7c(a4),(a0)
 move.w -$b78(a4),4(a0)
 move.l a5,d0
 addi.l #$2eb9c,d0
 lea scene_line_original+8(pc),a0
 move.l d0,(a0)
 move.l a5,d0
 addi.l #$2ec98,d0
 lea scene_line_done+2(pc),a0
 move.l d0,(a0)
 move.l a5,d0
 addi.l #$2fce0,d0
 lea scene_rect_original+2(pc),a0
 move.l d0,(a0)
 move.l a5,d0
 addi.l #$2fd9e,d0
 lea scene_rect_done+2(pc),a0
 move.l d0,(a0)
 move.l a5,d0
 addi.l #$2f48a,d0
 lea scene_poly_original+8(pc),a0
 move.l d0,(a0)
 move.l a5,d0
 addi.l #$2f510,d0
 lea scene_poly_done+2(pc),a0
 move.l d0,(a0)
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 movem.l (sp)+,d0-a6
 rts
.patch
 PL_START
 PL_P $2eb96,scene_line
 PL_P $2fcd6,scene_rect
 PL_NOP $2fcdc,4
 PL_P $2f484,scene_poly
 PL_END

; Input coordinates already passed native clipping. Packet arguments are longs.
scene_packet_coords:
 lea scene_packet(pc),a0
 move.l scene_frame_buffer(pc),4(a0)
 ext.l d0
 ext.l d1
 ext.l d2
 ext.l d3
 move.l d0,12(a0)
 move.l d1,16(a0)
 move.l d2,20(a0)
 move.l d3,24(a0)
 move.l scene_frame_h3(pc),a6
 adda.l #$8000,a6
 moveq #0,d0
 move.w $1d50(a6),d0
 move.l d0,28(a0)
 rts
scene_packet_call:
 pea scene_packet(pc)
 move.l scene_raster_selected(pc),a0
 jsr (a0)
 addq.l #4,sp
 tst.l d0
 bne scene_frame_bad
 rts

scene_line:
 movem.l d0-a6,-(sp)
 move.w scene_frame_active(pc),d4
 beq scene_line_native
 bsr scene_packet_coords
 move.l #1,(a0)
 moveq #0,d0
 move.w $1d52(a6),d0
 move.l d0,28(a0)
 bsr scene_packet_call
 movem.l (sp)+,d0-a6
scene_line_done:
 jmp $0.l
scene_line_native
 movem.l (sp)+,d0-a6
scene_line_original:
 move.l #$73526140,d6
 jmp $0.l

scene_rect:
 movem.w d0-d3,-(sp) ; native rectangle's saved clipped dimensions
 movem.l d0-a6,-(sp)
 move.w scene_frame_active(pc),d4
 beq scene_rect_native
 move.l scene_frame_h3(pc),a6
 adda.l #$8000,a6
 tst.w $1d54(a6)
 beq scene_rect_native
 bsr scene_packet_coords
 clr.l (a0)
 bsr scene_packet_call
 movem.l (sp)+,d0-a6
 move.l a0,-(sp)
 move.l scene_frame_h3(pc),a0
 adda.l #$8000,a0
 move.w $1d50(a0),d5
 move.l (sp)+,a0
scene_rect_done:
 jmp $0.l
scene_rect_native
 movem.l (sp)+,d0-a6
 move.l a0,-(sp)
 move.l scene_frame_h3(pc),a0
 adda.l #$8000,a0
 tst.w $1d54(a0)
 move.l (sp)+,a0
scene_rect_original:
 jmp $0.l

scene_poly:
 movem.l d0-a6,-(sp)
 move.w scene_frame_active(pc),d4
 beq scene_poly_native
 move.l scene_primitive_sim(pc),a6
 adda.l #$30000,a6
 lea scene_packet(pc),a0
 move.l #2,(a0)
 move.l scene_frame_buffer(pc),d0
 move.l d0,4(a0)
 addi.l #40000,d0
 move.l d0,8(a0)
 move.l -$972(a6),d1
 sub.l d0,d1
 move.l d1,12(a0)
 moveq #0,d0
 move.w -$976(a6),d0
 move.l d0,d1
 andi.l #63,d0
 move.l d0,16(a0)
 lsr.l #6,d1
 move.l d1,20(a0)
 move.l scene_frame_h3(pc),a6
 adda.l #$8000,a6
 moveq #0,d0
 move.w $1d50(a6),d0
 move.l d0,28(a0)
 bsr scene_packet_call
 movem.l (sp)+,d0-a6
scene_poly_done:
 jmp $0.l
scene_poly_native
 movem.l (sp)+,d0-a6
scene_poly_original:
 dc.w 0,0,0 ; relocated native move.l into d0
 jmp $0.l
scene_primitive_sim: dc.l 0
scene_packet: dcb.l 12,0

scene_raster_selected: dc.l 0
