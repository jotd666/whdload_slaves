; Stage the scene and, with P3_BACKGROUND, the viewport background in Fast RAM.
; Dashboard/text stay native on Chip RAM after the viewport copy.
; VERIFY repeats the primitive list natively before perf_reset consumes it.
raster_frame_enter:
 movem.l d0-a6,-(sp)
 moveq #0,d0
 addx.b d0,d0
 move.w d0,-(sp)
 move.w raster_frame_phase(pc),d0
 cmp.w #2,d0
 beq .done
 IFD P3_BACKGROUND
 cmp.w #1,d0
 beq .done
 ENDC
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
 IFD P3_BAND
 IFD P3_BACKGROUND
 move.w raster_background(pc),d0
 beq .native_clip
 move.l $a(a5),a0
 move.w 4(a0),d0
 move.w 6(a0),d1
 bra .clip_ready
.native_clip:
 ENDC
 move.w $ce4(a4),d0
 move.w $ce6(a4),d1
 IFD P3_BACKGROUND
.clip_ready:
 ENDC
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
 ENDC
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
 IFD P3_BAND
 IFND P3_FRAME_TWIN
 IFD P3_BACKGROUND
 move.w raster_background(pc),d0
 beq .seed_plane
 adda.w #8000,a1
 bra .plane_done
.seed_plane:
 ENDC
 adda.w raster_band_offset(pc),a0
 adda.w raster_band_offset(pc),a1
 move.w raster_band_rows(pc),d0
 bsr raster_copy_rows
 adda.w raster_band_tail(pc),a1
 ELSE
 bsr raster_copy_full_plane
 ENDC
 ELSE
 bsr raster_copy_full_plane
 ENDC
 IFD P3_BACKGROUND
.plane_done:
 ENDC
 dbra d1,.plane
 IFD P3_FRAME_TWIN
 move.l raster_buffer(pc),a0
 move.l a0,a1
 adda.l #32000,a1
 move.w #7999,d0
.seed:
 move.l (a0)+,(a1)+
 dbra d0,.seed
 ENDC
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
 IFD P3_BACKGROUND
 bsr raster_bg_seed
 btst #6,$dff002
.bg_wait:
 btst #6,$dff002
 bne .bg_wait
 IFD P3_FRAME_TWIN
 ; Native background writers run alongside the CPU prefix. Check it before
 ; an unsupported writer hands the rest of this background back to native.
 move.w raster_background(pc),d0
 beq .prefix_done
 bsr raster_bg_verify_prefix
.prefix_done:
 ENDC
 ENDC
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
 IFD P3_PIPELINE
 bsr raster_present_wait
 ENDC
 move.l raster_buffer(pc),a0
 IFD P3_BAND
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
 ELSE
 bra raster_frame_to_chip
 ENDC
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
 IFD P3_FRAME_TWIN
 cmp.w #2,d0
 beq .compare
 cmp.w #3,d0
 bne .restore_reference
 ; A fallback finished in chip RAM: save that completed CPU/native result.
 btst #6,$dff002
.wait:
 btst #6,$dff002
 bne .wait
 lea raster_frame_planes(pc),a2
 move.l raster_buffer(pc),a1
 moveq #3,d1
.save_plane:
 move.l (a2)+,a0
 move.w #1999,d0
.save:
 move.l (a0)+,(a1)+
 dbra d0,.save
 dbra d1,.save_plane
.restore_reference:
 IFD P3_BAND
 bsr raster_frame_check_outside
 ENDC
 bsr raster_frame_restore
 move.l raster_buffer(pc),a0
 adda.l #32000,a0
 bsr raster_frame_to_chip
 lea raster_frame_phase(pc),a0
 move.w #2,(a0)
 lsr.w (sp)+
 movem.l (sp)+,d0-a6
 addq.l #4,sp ; discard the BSR from perf_draw_exit; keep native LINK frame
 move.l raster_frame_continue(pc),-(sp)
 rts
.compare:
 btst #6,$dff002
.wait_reference:
 btst #6,$dff002
 bne .wait_reference
 lea raster_frame_planes(pc),a2
 move.l raster_buffer(pc),a1
 moveq #3,d1
.compare_plane:
 move.l (a2)+,a0
 move.w #1999,d0
.compare_word:
 move.l (a0)+,d2
 cmp.l (a1)+,d2
 bne .failed
 dbra d0,.compare_word
 dbra d1,.compare_plane
 lea raster_frames_passed(pc),a0
 addq.l #1,(a0)
 bra .clear
.failed:
 lea raster_frames_failed(pc),a0
 addq.l #1,(a0)
 illegal
 ELSE
 cmp.w #1,d0
 bne .clear
 bsr raster_frame_copyout
 bsr raster_frame_restore
 ENDC
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

; Installed only after the CPU/memory gate succeeds; original W1 stays intact
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
 IFD P3_BACKGROUND
 IFD P3_FRAME_TWIN
 move.w raster_bg_reference_active(pc),d0
 bne .owned
 ENDC
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
 ENDC
 lea raster_fallback_pc(pc),a0
 move.l 66(sp),(a0)
.fallback:
 IFD P3_PIPELINE
 bsr raster_present_wait
 ENDC
 bsr raster_frame_fallback
 IFD P3_BACKGROUND
.owned:
 ENDC
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
 IFD P3_BAND
 IFD P3_FRAME_TWIN
; Verify that narrowing the production copy cannot lose a CPU write outside
; the viewport. The twin seeds whole planes, then compares this area untouched.
raster_frame_check_outside:
 move.l raster_buffer(pc),a0
 move.l a0,a1
 adda.l #32000,a1
 moveq #3,d1
.plane:
 move.w raster_band_offset(pc),d0
 lsr.w #2,d0
 subq.w #1,d0
 bmi .skip
.before:
 move.l (a0)+,d2
 cmp.l (a1)+,d2
 bne .failed
 dbra d0,.before
.skip:
 adda.w raster_band_bytes(pc),a0
 adda.w raster_band_bytes(pc),a1
 move.w raster_band_tail(pc),d0
 lsr.w #2,d0
 subq.w #1,d0
 bmi .next
.after:
 move.l (a0)+,d2
 cmp.l (a1)+,d2
 bne .failed
 dbra d0,.after
.next:
 dbra d1,.plane
 rts
.failed:
 lea raster_frames_failed(pc),a0
 addq.l #1,(a0)
 illegal
 ENDC
raster_band_offset: dc.w 0
raster_band_rows: dc.w 0
raster_band_bytes: dc.w 0
raster_band_tail: dc.w 0
 ENDC
