; P3 development path: same-input whole-bitmap span twins, VERIFY only.
 IFND VERIFY
 FAIL "P3_RASTER requires VERIFY"
 ENDC
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
 lea raster_buffer(pc),a0
 clr.l (a0)
 move.l perf_attnflags(pc),d0
 btst #1,d0
 beq .done
 move.l 4.w,a6
 move.l perf_game(pc),a1
 bsr raster_fast_memory
 beq .done
 move.l #32000,d0
 moveq #MEMF_FAST,d1
 jsr _LVOAllocMem(a6)
 lea raster_buffer(pc),a0
 move.l d0,(a0)
 beq .done
 move.l d0,a1
 bsr raster_fast_memory
 bne .done
 move.l raster_buffer(pc),a1
 move.l #32000,d0
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
 PL_P $2c6d6,raster_solid ; PERF_RANGE h0:2c6d6 6 bit=1
 PL_P $2bf5c,raster_two ; PERF_RANGE h0:2bf5c 6 bit=1
 PL_PS $2cd44,raster_solid_end ; PERF_RANGE h0:2cd44 6 bit=1
 PL_P $2c632,raster_two_end ; PERF_RANGE h0:2c632 6 bit=1
 PL_END
raster_solid:
 dc.w $42e7 ; MOVE CCR,-(sp), 68010+; path is 020-gated
 movem.l d0-a6,-(sp)
 lea raster_kind(pc),a0
 clr.w (a0)
 bsr raster_before
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 move.l raster_solid_continue(pc),-(sp)
 move.w -$2c(a5),d5
 tst.w d5
 rts
raster_two:
 dc.w $42e7 ; MOVE CCR,-(sp), 68010+; path is 020-gated
 movem.l d0-a6,-(sp)
 lea raster_kind(pc),a0
 move.w #1,(a0)
 bsr raster_before
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 move.l raster_two_continue(pc),-(sp)
 move.w -$2c(a5),d2
 tst.w d2
 rts
raster_before:
 move.w raster_active(pc),d0
 bne raster_fail
 tst.w -$2c(a5)
 ble .done
 cmp.w #40,$cd4(a4)
 bne .done
 cmp.w #200,$cd6(a4)
 bne .done
 cmp.b #4,$bfb(a4)
 bne .done
 cmp.b #15,$c36(a4)
 bne .done
 btst #0,-$3a3a(a4)
 bne .done                 ; stipple remains native until its oracle passes
 move.w -$2e(a5),d0
 bmi .done
 add.w -$2c(a5),d0
 cmp.w #200,d0
 bhi .done
 ; Complete previous native DMA before taking the same-input copy.
 btst #6,$dff002
.wait:
 btst #6,$dff002
 bne .wait
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
 bsr raster_spans
 lea raster_planes(pc),a0
 lea $bfe(a4),a1
 moveq #3,d0
.restore:
 move.l (a0)+,(a1)+
 dbra d0,.restore
 lea raster_active(pc),a0
 move.w #1,(a0)
.done:
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
 move.l -$36(a5),a2
 move.l -$32(a5),a3
 lea $bfe(a4),a6
 moveq #0,d4
 move.w -$2c(a5),d5
 subq.w #1,d5
.row:
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
 move.l (a0),d1
 eor.l d2,d1
 and.l d3,d1
 eor.l d1,(a0)+
 subq.w #2,d0
 bmi .tail
.middle:
 move.l d2,(a0)+
 dbra d0,.middle
.tail:
 move.l (sp)+,d3
.last:
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
