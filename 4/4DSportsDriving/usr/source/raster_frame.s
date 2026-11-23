; Stage the scene and viewport background in Fast RAM.
; Dashboard/text stay native on Chip RAM after the viewport copy.
raster_frame_enter:
 movem.l d0-a6,-(sp)
 moveq #0,d0
 addx.b d0,d0
 move.w d0,-(sp)
 move.w raster_frame_phase(pc),d0
 cmp.w #2,d0
 beq .done
 cmp.w #1,d0
 beq .done
 move.l raster_buffer(pc),d0
 beq .done
 move.l _custom2(pc),d0
 and.l #3,d0
 beq .done
 cmp.w #40,$cd4(a4)
 bne .done
 cmp.w #200,$cd6(a4)
 bne .done
 cmp.b #4,$bfb(a4)
 bne .done
 cmp.b #15,$c36(a4)
 bne .done
 move.w raster_background(pc),d0
 beq .native_clip
 move.l $a(a5),a0
 move.w 4(a0),d0
 move.w 6(a0),d1
 bra .clip_ready
.native_clip:
 move.w $ce4(a4),d0
 move.w $ce6(a4),d1
.clip_ready:
 tst.w d0
 bmi .done
 cmp.w #200,d1
 bhi .done
 sub.w d0,d1
 ble .done
 lea raster_band_rows(pc),a0
 move.w d1,(a0)
 mulu #40,d0
 lea raster_band_offset(pc),a0
 move.w d0,(a0)
 mulu #40,d1
 lea raster_band_bytes(pc),a0
 move.w d1,(a0)
 add.w d1,d0
 move.w #8000,d1
 sub.w d0,d1
 lea raster_band_tail(pc),a0
 move.w d1,(a0)
 btst #6,$dff002
.wait:
 btst #6,$dff002
 bne .wait
 lea raster_frame_planes(pc),a2
 lea $bfe(a4),a3
 move.l raster_buffer(pc),a1
 moveq #3,d1
.plane:
 move.l (a3),a0
 move.l a0,(a2)+
 move.l a1,(a3)+
 move.w raster_background(pc),d0
 beq .seed_plane
 adda.w #8000,a1
 bra .plane_done
.seed_plane:
 adda.w raster_band_offset(pc),a0
 adda.w raster_band_offset(pc),a1
 move.w raster_band_rows(pc),d0
 bsr raster_copy_rows
 adda.w raster_band_tail(pc),a1
.plane_done:
 dbra d1,.plane
 lea raster_frame_phase(pc),a0
 move.w #1,(a0)
 lea raster_staged_count(pc),a0
 addq.l #1,(a0)
.done:
 lsr.w (sp)+
 movem.l (sp)+,d0-a6
 rts

; A rare unsupported primitive must never give the blitter a fast-RAM pointer.
; Flush preceding CPU drawing once, restore chip pointers, and finish on chip.
raster_frame_fallback:
 move.w raster_frame_phase(pc),d0
 cmp.w #1,d0
 bne .done
 bsr raster_bg_seed
 btst #6,$dff002
.bg_wait:
 btst #6,$dff002
 bne .bg_wait
 lea raster_fallback_count(pc),a0
 addq.l #1,(a0)
 bsr raster_frame_copyout
 bsr raster_frame_restore
 lea raster_frame_phase(pc),a0
 move.w #3,(a0)
.done:
 rts
raster_frame_restore:
 lea raster_frame_planes(pc),a0
 lea $bfe(a4),a1
 moveq #3,d0
.loop:
 move.l (a0)+,(a1)+
 dbra d0,.loop
 rts
raster_frame_copyout:
 bsr raster_present_wait
 move.l raster_buffer(pc),a0
 lea raster_frame_planes(pc),a2
 moveq #3,d1
.plane:
 move.l (a2)+,a1
 adda.w raster_band_offset(pc),a0
 adda.w raster_band_offset(pc),a1
 move.w raster_band_rows(pc),d0
 bsr raster_copy_rows
 adda.w raster_band_tail(pc),a0
 dbra d1,.plane
 rts
raster_frame_to_chip:
 lea raster_frame_planes(pc),a2
 moveq #3,d1
.plane:
 move.l (a2)+,a1
 move.w #1999,d0
.copy:
 move.l (a0)+,(a1)+
 dbra d0,.copy
 dbra d1,.plane
 rts
raster_frame_exit:
 movem.l d0-a6,-(sp)
 moveq #0,d0
 addx.b d0,d0
 move.w d0,-(sp)
 move.w raster_frame_phase(pc),d0
 beq .done
 cmp.w #1,d0
 bne .clear
 bsr raster_frame_copyout
 bsr raster_frame_restore
.clear:
 lea raster_frame_phase(pc),a0
 clr.w (a0)
.done:
 lsr.w (sp)+
 movem.l (sp)+,d0-a6
 rts
 even
raster_frame_marker: dc.b '4DFRAMTW'
raster_frames_passed: dc.l 0
raster_frames_failed: dc.l 0
raster_frame_phase: dc.w 0
raster_frame_continue: dc.l 0
raster_frame_planes: dcb.l 4,0

raster_staged_count: dc.l 0
raster_fallback_count: dc.l 0

; Installed only after the CPU/memory gate succeeds; original draw hook stays intact
; on ineligible machines, including its exact per-primitive overhead.
raster_draw_enter:
 bsr raster_frame_enter
 bra.w perf_draw_enter
raster_draw_exit:
 bsr raster_frame_exit
 bra.w perf_draw_exit
raster_own_blitter:
 dc.w $42e7
 movem.l d0-a6,-(sp)
 move.w raster_frame_phase(pc),d0
 cmp.w #1,d0
 bne .fallback
 move.w raster_background(pc),d0
 beq .unknown
 move.l 66(sp),d0
 sub.l perf_game(pc),d0
 cmp.l #$388b2,d0
 bne .caller_ready
 ; The generic native ownership wrapper adds one return address.
 move.l 70(sp),d0
 sub.l perf_game(pc),d0
.caller_ready:
 cmp.l #$3408a,d0
 beq .owned
 cmp.l #$32186,d0
 beq .owned
 cmp.l #$32206,d0
 beq .owned
.unknown:
 lea raster_fallback_pc(pc),a0
 move.l 66(sp),(a0)
.fallback:
 bsr raster_present_wait
 bsr raster_frame_fallback
.owned:
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 bra.w perf_own_blitter
raster_fallback_pc: dc.l 0

; 40 bytes per row, using ten registers; keep loop code small for the 020 cache.
; a0/a1 advance; d1/a2 and the native descriptor registers survive.
raster_copy_full_plane:
 move.w #200,d0
raster_copy_rows:
 movem.l a3-a6,-(sp)
 subq.w #1,d0
.loop:
 movem.l (a0)+,d2-d7/a3-a6
 movem.l d2-d7/a3-a6,(a1)
 lea 40(a1),a1
 dbra d0,.loop
 movem.l (sp)+,a3-a6
 rts
raster_band_offset: dc.w 0
raster_band_rows: dc.w 0
raster_band_bytes: dc.w 0
raster_band_tail: dc.w 0
