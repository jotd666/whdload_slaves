; CPU rasterizer for the Fast-RAM viewport.
RASTER_BYTES = 32000
raster_init:
 movem.l d0-d1/a0-a1/a6,-(sp)
 move.l perf_game(pc),d0
 add.l #$2c6dc,d0
 lea raster_solid_continue(pc),a0
 move.l d0,(a0)
 move.l perf_game(pc),d0
 add.l #$2bf62,d0
 lea raster_two_continue(pc),a0
 move.l d0,(a0)
 move.l perf_game(pc),d0
 add.l #$339ce,d0
 lea raster_line_continue(pc),a0
 move.l d0,(a0)
 move.l perf_game(pc),d0
 add.l #$ab86,d0
 lea raster_frame_continue(pc),a0
 move.l d0,(a0)
 move.l perf_game(pc),d0
 add.l #$2cdd2,d0
 lea raster_degenerate_continue(pc),a0
 move.l d0,(a0)
 move.l perf_game(pc),d0
 add.l #$32248,d0
 lea raster_bitmap_continue(pc),a0
 move.l d0,(a0)
 move.l perf_game(pc),d0
 add.l #$323a2,d0
 lea raster_bitmap_done(pc),a0
 move.l d0,(a0)
 lea raster_buffer(pc),a0
 clr.l (a0)
 move.l _custom2(pc),d0
 and.l #3,d0
 beq .done
 move.l perf_attnflags(pc),d0
 btst #1,d0
 beq .done
 move.l 4.w,a6
 move.l perf_game(pc),a1
 bsr raster_fast_memory
 beq .done
 move.l #RASTER_BYTES,d0
 moveq #MEMF_FAST,d1
 jsr _LVOAllocMem(a6)
 lea raster_buffer(pc),a0
 move.l d0,(a0)
 beq .done
 move.l d0,a1
 bsr raster_fast_memory
 bne .done
 move.l raster_buffer(pc),a1
 move.l #RASTER_BYTES,d0
 jsr _LVOFreeMem(a6)
 lea raster_buffer(pc),a0
 clr.l (a0)
.done:
 movem.l (sp)+,d0-d1/a0-a1/a6
 rts
; Reject slow expansion even if KickEmu describes it as MEMF_FAST.
raster_fast_memory:
 cmpa.l #$c00000,a1
 blo .type
 cmpa.l #$e00000,a1
 blo .reject
.type:
 jsr _LVOTypeOfMem(a6)
 and.l #MEMF_FAST,d0
 rts
.reject:
 moveq #0,d0
 rts
raster_patch:
 movem.l d0-a2,-(sp)
 move.l raster_buffer(pc),d0
 beq .done
 move.l _custom2(pc),d0
 and.l #3,d0
 beq .done
 lea pl_raster(pc),a0
 move.l perf_game(pc),a1
 move.l _resload(pc),a2
 jsr resload_Patch(a2)
.done:
 movem.l (sp)+,d0-a2
 rts
pl_raster:
 PL_START
 PL_PSS $7140,raster_present_prepare,2 ; PERF_RANGE h0:07140 8 bit=1
 PL_PSS $21228,raster_bg_enter,2 ; PERF_RANGE h0:21228 8 bit=1
 PL_P $21ba8,raster_bg_exit ; PERF_RANGE h0:21ba8 6 bit=1
 PL_PSS $347b0,raster_bg_rect,34 ; PERF_RANGE h0:347b0 40 bit=1
 PL_P $32242,raster_bg_bitmap ; PERF_RANGE h0:32242 6 bit=1
 PL_P $323a6,raster_bg_bitmap_end ; PERF_RANGE h0:323a6 6 bit=1
 ; Existing W1 hook ranges already declared in performance.s.
 PL_PS $ab86,raster_draw_enter
 PL_P $aed0,raster_draw_exit
 PL_P $3980e,raster_own_blitter
 PL_P $39800,perf_disown_blitter
 PL_P $2c6d6,raster_solid ; PERF_RANGE h0:2c6d6 6 bit=1
 PL_P $2bf5c,raster_two ; PERF_RANGE h0:2bf5c 6 bit=1
 PL_PS $2cd44,raster_solid_end ; PERF_RANGE h0:2cd44 6 bit=1
 PL_P $2c632,raster_two_end ; PERF_RANGE h0:2c632 6 bit=1
 PL_P $2cdca,raster_degenerate ; PERF_RANGE h0:2cdca 8 bit=1
 PL_NOP $2cdd0,2
 PL_P $339c4,raster_line_hook ; PERF_RANGE h0:339c4 10 bit=1
 PL_NOP $339ca,4
 PL_P $33aa8,raster_line_end ; PERF_RANGE h0:33aa8 6 bit=1
 PL_END
raster_line_hook:
 dc.w $42e7 ; MOVE CCR,-(sp), 020-gated
 movem.l d0-a6,-(sp)
 lea raster_line_data(pc),a0
 movem.l d0-d3,(a0)
 move.w d7,16(a0)
 lea raster_kind(pc),a0
 move.w #2,(a0)
 bsr raster_before
 move.w raster_taken(pc),d0
 bne .drawn
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 move.l raster_line_continue(pc),-(sp)
 lea $c1e(a4),a0
 move.b $18(a0),$220f(a4)
 rts
.drawn:
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 movem.l (sp)+,d4-d7/a2-a3
 rts
raster_line_end:
 bsr raster_after
 movem.l (sp)+,d4-d7/a2-a3
 rts
raster_solid:
 dc.w $42e7 ; MOVE CCR,-(sp), 68010+; path is 020-gated
 movem.l d0-a6,-(sp)
 lea raster_kind(pc),a0
 clr.w (a0)
 bsr raster_before
 move.w raster_taken(pc),d0
 bne .drawn
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 move.l raster_solid_continue(pc),-(sp)
 move.w -$2c(a5),d5
 tst.w d5
 rts
.drawn:
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 bclr #0,-$3a3a(a4)
 unlk a5
 movem.l (sp)+,d4-d7/a2-a4/a6
 rts
raster_two:
 dc.w $42e7 ; MOVE CCR,-(sp), 68010+; path is 020-gated
 movem.l d0-a6,-(sp)
 lea raster_kind(pc),a0
 move.w #1,(a0)
 bsr raster_before
 move.w raster_taken(pc),d0
 bne .drawn
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 move.l raster_two_continue(pc),-(sp)
 move.w -$2c(a5),d2
 tst.w d2
 rts
.drawn:
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 unlk a5
 movem.l (sp)+,d4-d7/a2-a4/a6
 rts
raster_before:
 lea raster_taken(pc),a0
 clr.w (a0)
 move.w raster_active(pc),d0
 bne raster_fail
 cmp.w #40,$cd4(a4)
 bne .done
 cmp.w #200,$cd6(a4)
 bne .done
 cmp.b #4,$bfb(a4)
 bne .done
 cmp.b #15,$c36(a4)
 bne .done
 move.w raster_kind(pc),d0
 cmp.w #2,d0
 beq .copy_start
 tst.w -$2c(a5)
 ble .done
 move.w -$2e(a5),d0
 bmi .done
 add.w -$2c(a5),d0
 cmp.w #200,d0
 bhi .done
 .copy_start:
 bsr raster_bg_seed
 ; Complete previous native DMA before taking the same-input copy.
 btst #6,$dff002
.wait:
 btst #6,$dff002
 bne .wait
 move.w raster_kind(pc),d0
 cmp.w #2,d0
 beq .direct_line
 bsr raster_spans
 bra .direct_done
.direct_line:
 bsr raster_line
.direct_done:
 lea raster_taken(pc),a0
 move.w #1,(a0)
 rts
 lea raster_planes(pc),a2
 lea $bfe(a4),a3
 move.l raster_buffer(pc),a1
 moveq #3,d1
.copy_plane:
 move.l (a3),(a2)+
 move.l (a3),a0
 move.l a1,(a3)+
 move.w #1999,d0
.copy:
 move.l (a0)+,(a1)+
 dbra d0,.copy
 dbra d1,.copy_plane
 move.w raster_kind(pc),d0
 cmp.w #2,d0
 beq .line
 bsr raster_spans
 bra .rendered
.line:
 bsr raster_line
.rendered:
 lea raster_planes(pc),a0
 lea $bfe(a4),a1
 moveq #3,d0
.restore:
 move.l (a0)+,(a1)+
 dbra d0,.restore
 lea raster_active(pc),a0
 move.w #1,(a0)
.done:
 bsr raster_frame_fallback
 rts
raster_solid_end:
 bsr raster_after
 bclr #0,-$3a3a(a4)
 rts
raster_two_end:
 bsr raster_after
 unlk a5
 movem.l (sp)+,d4-d7/a2-a4/a6
 rts
raster_after:
 dc.w $42e7 ; MOVE CCR,-(sp)
 movem.l d0-d2/a0-a2,-(sp)
 move.w raster_active(pc),d0
 beq .done
 btst #6,$dff002
.wait:
 btst #6,$dff002
 bne .wait
 lea raster_planes(pc),a2
 move.l raster_buffer(pc),a1
 moveq #3,d1
.plane:
 move.l (a2)+,a0
 move.w #1999,d0
.compare:
 move.l (a0)+,d2
 cmp.l (a1)+,d2
 bne raster_fail
 dbra d0,.compare
 dbra d1,.plane
 lea raster_passed(pc),a0
 addq.l #1,(a0)
 lea raster_active(pc),a0
 clr.w (a0)
.done:
 movem.l (sp)+,d0-d2/a0-a2
 move.w (sp)+,ccr
 rts
raster_fail:
 lea raster_failed(pc),a0
 addq.l #1,(a0)
 illegal

; Keep native clipping and edge tables. Render exactly its filled spans.
raster_spans:
 move.w raster_kind(pc),d0
 bne .generic
 btst #0,-$3a3a(a4)
 bne .generic
 move.w raster_frame_phase(pc),d0
 cmp.w #1,d0
 bne .generic
 bra raster_solid_fast
.generic:
 bra.w raster_quad
 move.l -$36(a5),a2
 move.l -$32(a5),a3
 lea $bfe(a4),a6
 moveq #0,d4
 move.w -$2c(a5),d5
 subq.w #1,d5
.row:
 lea raster_stipple_mask(pc),a0
 moveq #-1,d2
 move.l d2,(a0)
 move.w raster_kind(pc),d3
 bne .mask_ready
 btst #0,-$3a3a(a4)
 beq .mask_ready
 move.l -$3a38(a4),d2
 move.w -$2c(a5),d3
 subq.w #1,d3
 sub.w d4,d3
 btst #0,d3
 bne .mask_low
 swap d2
.mask_low:
 move.w d2,d3
 swap d2
 move.w d3,d2
 move.l d2,(a0)
.mask_ready:
 move.w d4,d3
 add.w d3,d3
 move.w (a2,d3.w),d0
 move.w (a3,d3.w),d1
 cmp.w d0,d1
 blt .next
 bne .draw
 move.w raster_kind(pc),d2
 bne .draw
 ; Preserve the native packed solid writer's empty-next-row quirk.
 btst #0,d4
 bne .draw
 move.w -$2c(a5),d2
 and.w #$fff8,d2
 cmp.w d2,d4
 bhs .draw
 move.w 2(a2,d3.w),d2
 cmp.w 2(a3,d3.w),d2
 bgt .next
.draw:
 moveq #0,d7
.plane:
 move.w -$2a(a5),d3
 moveq #-1,d2
 btst d7,d3
 bne .colour1
 moveq #0,d2
.colour1:
 move.w raster_kind(pc),d3
 beq .pattern_done
 move.w -$28(a5),d3
 btst d7,d3
 beq .second_zero
 tst.w d2
 bne .pattern_done
 bra .different
.second_zero:
 tst.w d2
 beq .pattern_done
.different:
 move.l -$26(a5),d3
 btst #0,d4
 bne .low
 swap d3
.low:
 tst.w d2
 bne .positive
 not.w d3
.positive:
 move.w d3,d2
 swap d2
 move.w d3,d2
.pattern_done:
 move.w d7,d3
 lsl.w #2,d3
 move.l (a6,d3.w),a0
 move.w d4,d3
 add.w -$2e(a5),d3
 mulu #40,d3
 adda.l d3,a0
 move.w d4,d3
 add.w d3,d3
 move.w (a2,d3.w),d0
 move.w (a3,d3.w),d1
 bsr raster_span
 addq.w #1,d7
 cmp.w #4,d7
 blo .plane
.next:
 addq.w #1,d4
 dbra d5,.row
 rts

; d0=left, d1=right inclusive, d2=32-bit repeated pattern, a0=row.
; Scratch d0-d3/a0-a1, preserve the outer loop's registers.
raster_span:
 move.w d0,d3
 lsr.w #5,d3
 lsl.w #2,d3
 adda.w d3,a0
 move.w d1,d3
 lsr.w #5,d3
 move.w d0,-(sp)
 lsr.w #5,d0
 sub.w d0,d3
 move.w (sp)+,d0
 move.w d3,-(sp)
 and.w #31,d0
 moveq #-1,d3
 lsr.l d0,d3
 move.l d3,a1
 and.w #31,d1
 moveq #31,d0
 sub.w d1,d0
 moveq #-1,d3
 lsl.l d0,d3
 move.w (sp)+,d0
 bne .multiple
 move.l a1,d1
 and.l d1,d3
 bra .last
.multiple:
 move.l d3,-(sp)
 move.l a1,d3
 and.l raster_stipple_mask(pc),d3
 move.l (a0),d1
 eor.l d2,d1
 and.l d3,d1
 eor.l d1,(a0)+
 subq.w #2,d0
 bmi .tail
 move.l raster_stipple_mask(pc),d3
 cmp.l #-1,d3
 beq .middle
.masked_middle:
 move.l (a0),d1
 eor.l d2,d1
 and.l d3,d1
 eor.l d1,(a0)+
 dbra d0,.masked_middle
 bra .tail
.middle:
 move.l d2,(a0)+
 dbra d0,.middle
.tail:
 move.l (sp)+,d3
.last:
 and.l raster_stipple_mask(pc),d3
 move.l (a0),d1
 eor.l d2,d1
 and.l d3,d1
 eor.l d1,(a0)
 rts
 even
raster_marker: dc.b '4DSPANTW'
raster_passed: dc.l 0
raster_failed: dc.l 0
raster_active: dc.w 0
raster_kind: dc.w 0
raster_buffer: dc.l 0
raster_planes: dcb.l 4,0
raster_solid_continue: dc.l 0
raster_two_continue: dc.l 0

raster_line_continue: dc.l 0
raster_line_data: dcb.l 4,0
 dc.w 0
raster_line_xmajor: dc.w 0
raster_line:
 lea raster_line_data(pc),a0
 movem.l (a0),d0-d3
 moveq #1,d4
 move.l d4,a2
 move.l d4,a3
 sub.w d0,d2
 bpl .dx
 neg.w d2
 moveq #-1,d4
 move.l d4,a2
.dx:
 sub.w d1,d3
 bpl .dy
 neg.w d3
 moveq #-1,d4
 move.l d4,a3
.dy:
 lea raster_line_xmajor(pc),a0
 clr.w (a0)
 cmp.w d3,d2
 blo .ymajor
 move.w #1,(a0)
 exg d2,d3
.ymajor:
 move.w d3,d7
 move.w d3,d4
 add.w d4,d4
 move.w d2,d5
 add.w d5,d5
 move.w d5,d6
 sub.w d3,d6
.pixel:
 move.w d1,d2
 mulu #40,d2
 move.w d0,d3
 lsr.w #3,d3
 add.w d3,d2
 move.w d0,d3
 not.w d3
 lea $bfe(a4),a0
 move.w raster_line_data+16(pc),-(sp)
 move.w #3,-(sp)
.plane:
 move.l (a0)+,a1
 lsr.w 2(sp)
 bcc .clear
 bset d3,(a1,d2.w)
 bra .next_plane
.clear:
 bclr d3,(a1,d2.w)
.next_plane:
 subq.w #1,(sp)
 bpl .plane
 addq.l #4,sp
 tst.w d6
 bmi .major
 move.w raster_line_xmajor(pc),d2
 beq .minor_x
 add.w a3,d1
 bra .minor_done
.minor_x:
 add.w a2,d0
.minor_done:
 sub.w d4,d6
.major:
 move.w raster_line_xmajor(pc),d2
 beq .major_y
 add.w a2,d0
 bra .major_done
.major_y:
 add.w a3,d1
.major_done:
 add.w d5,d6
 dbra d7,.pixel
 rts

raster_taken: dc.w 0

 even
raster_stipple_mask: dc.l -1

 include "raster_frame.s"

raster_degenerate_continue: dc.l 0
; Native clipped degenerate-polygon descriptor. It otherwise acquires the
; blitter before taking its own line/dot path, bypassing the usual line core.
raster_degenerate:
 dc.w $42e7
 movem.l d0-a6,-(sp)
 move.w raster_background(pc),d0
 beq .bg_done
 bsr raster_frame_fallback
.bg_done:
 move.l 66(sp),a0
 tst.b $13(a0)
 bne .empty
 moveq #0,d4
 move.b $12(a0),d4
 cmp.w #9,d4
 bhi .empty
 movem.w (a0),d0-d3
 move.w $10(a0),d7
 cmp.w #9,d4
 bne .rounded
 move.w d0,d2
 move.w d1,d3
 bra .ready
.rounded:
 cmp.w #6,d4
 blo .ready
 bne .round_y
 move.w 8(a0),d4
 add.w #$8000,d4
 bcc .ready
 addq.w #1,d0
 bra .ready
.round_y:
 move.w 10(a0),d4
 add.w #$8000,d4
 bcc .ready
 addq.w #1,d1
.ready:
 lea raster_line_data(pc),a0
 movem.l d0-d3,(a0)
 move.w d7,16(a0)
 lea raster_kind(pc),a0
 move.w #2,(a0)
 bsr raster_before
 move.w raster_taken(pc),d0
 beq .original
.empty:
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 rts
.original:
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 jsr -$7950(a4)
 move.l 4(sp),a0
 move.l raster_degenerate_continue(pc),-(sp)
 rts

 include "raster_quad.s"

 include "raster_solid.s"

 include "raster_background.s"

 include "raster_present.s"
