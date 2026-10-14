; First cache hit of each gauge (each page under FC3; bounded altitude repeats):
; predict state, restore native inputs,
; run the original dispatcher body, compare full pixels and the 40-byte bounded
; drawing-state projection. No simulation/full-state study and no FPS inference.
instrument_cache_twin_begin:
 movem.l d1-a6,-(sp)
 lea instrument_cache_twin_result(pc),a3
 move.l (a3),d0
 bsr instrument_cache_twin_index
 btst d1,d0
 bne .already
 move.l 8(a3),d0
 bne .allocated
 move.l a6,-(sp)
 move.l 4.w,a6
 move.l #40080,d0
 move.l #$10000,d1 ; CPU-only VERIFY snapshot may use any memory
 jsr _LVOAllocMem(a6)
 move.l (sp)+,a6
 move.l d0,8(a3)
 beq .allocation_bad
.allocated
 move.l d4,d0
 addq.l #1,d0
 move.l d0,4(a3)
 move.l 8(a3),a0
 adda.l #40000,a0
 bsr instrument_cache_state_read
 bsr instrument_cache_restore
 move.l 8(a3),a0
 adda.l #40040,a0
 bsr instrument_cache_state_read
 move.l 8(a3),a0
 adda.l #40000,a0
 bsr instrument_cache_state_write_all
 move.l $1d72(a4),a0
 move.l 8(a3),a1
 move.w #9999,d0
.copy
 move.l (a0)+,(a1)+
 dbf d0,.copy
 movem.l (sp)+,d1-a6
 moveq #1,d0 ; run original body with all input registers preserved
 rts
.already
 movem.l (sp)+,d1-a6
 moveq #0,d0
 rts
.allocation_bad
 move.l #3,16(a3)
 move.l d4,24(a3)
 movem.l (sp)+,d1-a6
 moveq #1,d0
 rts

instrument_cache_twin_end:
 movem.l d0-a6,-(sp)
 lea instrument_cache_twin_result(pc),a3
 tst.l 16(a3)
 bne .done
 move.l 4(a3),d0
 beq .done
 subq.l #1,d0
 cmp.l d4,d0
 bne .wrong_gauge
 move.l instrument_cache_h3(pc),a4
 adda.l #$8000,a4
 bsr overlay_blit_wait
 move.l 8(a3),a0
 move.l $1d72(a4),a1
 move.w #39999,d0
.pixels
 cmpm.b (a0)+,(a1)+
 bne .pixel_bad
 dbf d0,.pixels
 lea instrument_cache_twin_post(pc),a0
 bsr instrument_cache_state_read
 lea instrument_cache_twin_post(pc),a0
 move.l 8(a3),a1
 adda.l #40040,a1
 moveq #39,d0
.state
 cmpm.b (a0)+,(a1)+
 bne .state_bad
 dbf d0,.state
 move.l (a3),d0
 bsr instrument_cache_twin_index
 bset d1,d0
 move.l d0,(a3)
 clr.l 4(a3)
 addq.l #1,12(a3)
 move.l #127,d1
 btst #0,gauge_fast_enabled+1(pc)
 beq .mask_ready
 move.l #16383,d1
.mask_ready
 cmp.l d1,d0
 bne .done
 move.l 8(a3),a1
 move.l #40080,d0
 move.l 4.w,a6
 jsr _LVOFreeMem(a6)
 clr.l 8(a3)
.done
 movem.l (sp)+,d0-a6
 rts
.pixel_bad
 move.l #1,16(a3)
 move.l #40000,d1
 sub.l d0,d1
 move.l d1,20(a3)
 bra .failed
.state_bad
 move.l #2,16(a3)
 moveq #40,d1
 sub.l d0,d1
 move.l d1,20(a3)
 bra .failed
.wrong_gauge
 move.l #4,16(a3)
.failed
 move.l d4,24(a3)
 ; The original draw completed. Retain it, disable later reuse, keep evidence.
 movem.l (sp)+,d0-a6
 rts

; Undo the candidate's state writes before executing the original instructions.
; Every copied byte came from this invocation's pre-state, not an older cache.
instrument_cache_state_write_all:
 lea $1d46(a4),a1
 moveq #4,d0
.clip
 move.w (a0)+,(a1)+
 dbf d0,.clip
 move.w (a0)+,$1d52(a4)
 move.l (a0)+,-$6e4(a4)
 move.l (a0)+,-$6e0(a4)
 move.l (a0)+,-$6ec(a4)
 move.l (a0)+,-$6e8(a4)
 move.l (a0)+,-$ed4(a4)
 move.l (a0)+,-$ed0(a4)
 move.w (a0)+,-$eea(a4)
 move.w (a0)+,-$ee6(a4)
 rts
instrument_cache_twin_result: dc.l 0,0,0,0,0,0,0,0
instrument_cache_twin_post: dcb.b 40,0

instrument_cache_twin_repeat: dc.w 0

; FC3 checks each gauge on each physical history page; bit18 keeps seven cases.
instrument_cache_twin_index:
 move.w d4,d1
 btst #0,gauge_fast_enabled+1(pc)
 beq .done
 add.w d1,d1
 tst.b -$ee3(a4)
 beq .done
 addq.w #1,d1
.done
 rts
