; Start staging before the native background. Full-row overwrites need no seed;
; before a partial/unsupported writer, seed only rows/planes still untouched.
raster_bg_enter:
 dc.w $42e7
 movem.l d0-a6,-(sp)
 lea raster_background(pc),a0
 move.w #1,(a0)
 lea raster_bg_valid(pc),a0
 moveq #99,d0
.clear:
 clr.w (a0)+
 dbra d0,.clear
 bsr raster_frame_enter
 move.w raster_frame_phase(pc),d0
 cmp.w #1,d0
 beq .stage_ready
 bsr raster_present_wait
.stage_ready:
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 clr.b $e42(a4)
 clr.w -$e(a5)
 rts
raster_bg_exit:
 dc.w $42e7
 movem.l d0-a6,-(sp)
 move.w raster_frame_phase(pc),d0
 cmp.w #1,d0
 bne .clear
 bsr raster_bg_seed
.clear:
 lea raster_background(pc),a0
 clr.w (a0)
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 move.w -$e(a5),d0
 unlk a5
 rts

; Complete only the as-yet-unwritten row/planes from the original chip bitmap.
; Preserves registers; called before all partial writers and fallback/copyout.
raster_bg_seed:
 movem.l d0-a6,-(sp)
 move.w raster_background(pc),d0
 beq .done
 move.w raster_frame_phase(pc),d0
 cmp.w #1,d0
 bne .done
 moveq #0,d4
 move.w raster_band_offset(pc),d4
 move.l d4,d0
 divu #40,d0
 lea raster_bg_valid(pc),a5
 adda.w d0,a5
 move.l raster_buffer(pc),a3
 adda.l d4,a3
 move.w raster_band_rows(pc),d0
 subq.w #1,d0
.row:
 move.b (a5),d1
 cmp.b #15,d1
 beq .next
 lea raster_frame_planes(pc),a2
 move.l a3,a1
 moveq #0,d2
.plane:
 move.l (a2)+,a0
 adda.w d4,a0
 btst d2,d1
 bne .skip
 moveq #9,d3
.copy:
 move.l (a0)+,(a1)+
 dbra d3,.copy
 suba.w #40,a1
 lea raster_bg_seeded(pc),a0
 addq.l #1,(a0)
.skip:
 adda.w #8000,a1
 addq.w #1,d2
 cmp.w #4,d2
 blo .plane
 move.b #15,(a5)
.next:
 addq.l #1,a5
 lea 40(a3),a3
 add.w #40,d4
 dbra d0,.row
.done:
 movem.l (sp)+,d0-a6
 rts
; d0=y, d1=height, d2=plane bits. The caller validated whole 40-byte rows.
raster_bg_mark:
 lea raster_bg_valid(pc),a0
 adda.w d0,a0
 subq.w #1,d1
.loop:
 or.b d2,(a0)+
 dbra d1,.loop
 rts

; Translate a pointer in the contiguous fast bitmap to its native chip plane.
; d0/d1/a1 are scratch. Other addresses are returned unchanged.
raster_bg_chip_pointer:
 move.l a0,d0
 sub.l raster_buffer(pc),d0
 cmp.l #32000,d0
 bhs .done
 divu #8000,d0
 move.w d0,d1
 and.l #$ffff,d1
 lsl.w #2,d1
 lea raster_frame_planes(pc),a1
 move.l (a1,d1.w),a0
 swap d0
 adda.w d0,a0
.done:
 rts

raster_bg_fast_planes:
 lea $bfe(a4),a0
 move.l raster_buffer(pc),d0
 moveq #3,d1
.loop:
 move.l d0,(a0)+
 add.l #8000,d0
 dbra d1,.loop
 rts

; Whole-row D-only clear. Partial rectangles first seed all untouched rows.
raster_bg_rect:
 dc.w $42e7
 movem.l d0-a6,-(sp)
 move.w raster_frame_phase(pc),d0
 cmp.w #1,d0
 bne .native
 move.l 32(sp),a0
 adda.w 6(sp),a0 ; incoming d1.w at low word of saved d1
 move.l a0,d0
 sub.l raster_buffer(pc),d0
 cmp.l #32000,d0
 bhs .fallback
 move.w 14(sp),d3
 and.w #63,d3
 cmp.w #20,d3
 bne .seed
 tst.w 2(sp) ; native destination modulo d0.w
 bne .seed
 divu #8000,d0
 moveq #1,d2
 lsl.w d0,d2
 swap d0
 and.l #$ffff,d0
 divu #40,d0
 move.l d0,d1
 swap d1
 tst.w d1
 bne .seed
 move.w 14(sp),d1
 lsr.w #6,d1
 beq .seed
 bsr raster_bg_mark
 bra .draw
.seed:
 bsr raster_bg_seed
.draw:
 movem.l (sp),d0-a6
 bsr perf_cpu_rect
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 adda.w d1,a0
 tst.w d3
 rts
.fallback:
 bsr raster_frame_fallback
 move.l 32(sp),a0
 bsr raster_bg_chip_pointer
 move.l a0,32(sp)
.native:
 ; Retain the 020-only rectangle optimization when this stage is inactive.
 move.l _custom2(pc),d0
 btst #0,d0
 beq .blitter
 move.l perf_attnflags(pc),d0
 btst #2,d0
 bne .blitter
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 bra perf_cpu_rect
.blitter:
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 adda.w d1,a0
 btst #6,$dff002
.wait:
 btst #6,$dff002
 bne .wait
 move.l a0,$dff054
 move.w d2,$dff040
 move.w d3,$dff058
 rts

; The common background copy has no mask or shift and complete 40-byte rows.
; Other bitmap operations keep the native path after a safe one-time flush.
raster_bg_bitmap:
 dc.w $42e7
 movem.l d0-a6,-(sp)
 move.w raster_frame_phase(pc),d0
 cmp.w #1,d0
 bne .native
 cmp.w #$bca,-$32ec(a4)
 bne .fallback
 move.l 36(sp),d0 ; incoming a1 mask
 bne .fallback
 tst.w 14(sp) ; incoming d3 shift
 bne .fallback
 move.w 6(sp),d0
 and.w #63,d0
 cmp.w #20,d0
 bne .fallback
 tst.w $21fc(a4) ; destination modulo
 bne .fallback
 tst.w $21fe(a4) ; source modulo
 bne .fallback
 moveq #0,d0
 move.w 10(sp),d0
 divu #40,d0
 move.l d0,d1
 swap d1
 tst.w d1
 bne .fallback
 move.w 6(sp),d1
 lsr.w #6,d1
 beq .fallback
 move.w d0,d2
 add.w d1,d2
 cmp.w #200,d2
 bhi .fallback
 ; All four planes must be supplied, either as constants or source groups.
 move.l 52(sp),a0 ; incoming a5 source descriptor
 move.b 12(a0),d2
 or.b 13(a0),d2
 lea 14(a0),a0
.groups:
 move.b (a0)+,d3
 beq .groups_done
 or.b d3,d2
 bra .groups
.groups_done:
 and.w #15,d2
 cmp.w #15,d2
 bne .fallback
 bsr raster_bg_mark
 movem.l (sp),d0-a6
 bsr raster_bg_bitmap_cpu
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 move.l raster_bitmap_done(pc),-(sp)
 rts
.fallback:
 bsr raster_frame_fallback
.native:
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 move.l raster_bitmap_continue(pc),-(sp)
 move.w $220a(a4),$44(a6)
 rts
raster_bg_bitmap_end:
 movem.l (sp)+,d0-d6/a0-a3/a5
 rts

; Prepared, aligned copy. Preserve each source group and native plane ordering.
raster_bg_bitmap_cpu:
 lea -12(sp),sp
 move.l sp,a6
 move.w d0,(a6)
 move.w d1,d0
 lsr.w #6,d0
 move.w d0,2(a6)
 move.w d2,4(a6)
 move.l a0,a3
 moveq #0,d7
 move.b 12(a5),d7
 moveq #0,d6
 bsr .group
 move.b 13(a5),d7
 moveq #1,d6
 bsr .group
 lea 14(a5),a5
.sources:
 move.b (a5)+,d7
 beq .done
 moveq #2,d6
 bsr .group
 adda.w (a6),a3
 bra .sources
.done:
 lea 12(sp),sp
 rts
.group:
 movem.l d5-d7/a3-a6,-(sp)
 lea $bfe(a4),a5
 moveq #0,d5
.plane:
 move.l (a5)+,a1
 btst d5,d7
 beq .next
 adda.w 4(a6),a1
 cmp.w #2,d6
 bne .constant
 move.l a3,a0
 move.w 2(a6),d0
 movem.l d5-d7,-(sp)
 bsr raster_copy_rows
 movem.l (sp)+,d5-d7
 bra .next
.constant:
 moveq #0,d2
 tst.w d6
 beq .value
 moveq #-1,d2
.value:
 move.w 2(a6),d0
 mulu #10,d0
 subq.w #1,d0
.fill:
 move.l d2,(a1)+
 dbra d0,.fill
.next:
 addq.w #1,d5
 cmp.w #4,d5
 blo .plane
 movem.l (sp)+,d5-d7/a3-a6
 rts
 even
raster_background: dc.w 0
raster_bg_reference_active: dc.w 0
raster_bg_passed: dc.l 0
raster_bg_failed: dc.l 0
raster_bg_seeded: dc.l 0
raster_bitmap_continue: dc.l 0
raster_bitmap_done: dc.l 0
raster_bg_valid: dcb.b 200,0
 even
