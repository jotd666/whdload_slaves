; A4000 sound presentation: newest complete 20ms position pair, serviced by
; the existing CIA callback. Never pace physics or modify the audio CIA clock.
; Native10/20 use the original byte-for-byte consumer, including its divider.
;
; The main task writes slot W, advances W, then publishes W (or40 on wrap).
; The published word is slot+1, zero means empty. The CIA interrupt cannot
; overlap a main-task write, and an in-progress slot is never the previously
; published slot. A single word store publishes the completed record last.
; Coalescing discards obsolete POSITION/RPM records only. The native producer
; still executes all sample starts/stops before reaching this hook.
sim_sound_prepare:
 lea sim_sound_prepare(pc),a0
 adda.l #tape_game-sim_sound_prepare,a0
 movea.l (a0),a0
 adda.l #$7984,a0
 lea sim_sound_native_consume(pc),a1
 moveq #70/2-1,d0
.copy:
 move.w (a0)+,(a1)+
 dbra d0,.copy
 rts

; $10904: native MOVE.B $44(a4),-$736C(a4), including flags/X.
; Also reached by the native pause/stop path, which publishes no new record.
sim_sound_publish:
 movem.l d0-d1/a0,-(sp)
 moveq #0,d1
 addx.w d1,d1
 move.w d1,-(sp)
 cmp.w #50,-$15fa(a4)
 bne .done
 tst.b $44(a4)
 bne .flush
 move.w $72(a4),d0
 bne .index
 moveq #40,d0
.index:
 bsr sim_sound_offer
 bra.s .done
.flush:
 bsr sim_sound_reset
.done:
 move.w (sp)+,d1
 lsr.w #1,d1
 movem.l (sp)+,d0-d1/a0
 move.b $44(a4),-$736c(a4)
 rts

; D0.w=completed slot+1 (1..40). Preserve registers; publish last.
sim_sound_offer:
 move.l a0,-(sp)
 lea sim_sound_pending(pc),a0
 addq.l #1,sim_sound_published-sim_sound_pending(a0)
 move.w d0,(a0)
 move.l (sp)+,a0
 rts

; D0.w=take most recent completed slot+1, or zero. Main task is suspended
; throughout the CIA callback, so clearing cannot race a new publication.
sim_sound_take:
 move.l a0,-(sp)
 lea sim_sound_pending(pc),a0
 move.w (a0),d0
 beq .done
 clr.w (a0)
 addq.l #1,sim_sound_played-sim_sound_pending(a0)
.done:
 move.l (sp)+,a0
 tst.w d0
 rts

; $7984..$79CA. All native branches stay within the copied70-byte block or
; reach its appended RTS. The original reentrancy/pause/input code stays live.
sim_sound_consume:
 cmp.w #50,-$15fa(a4)
 bne sim_sound_native_consume
 clr.w $76(a4)
 tst.b $44(a4)
 beq .active
 ; Native104A4 flushes its FIFO before stopping/freeing sound channels.
 ; A CIA interrupt during that stop path must not consume our stale record.
 bsr sim_sound_reset
 bra.s .done
.active:
 bsr sim_sound_take
 beq .done
 subq.w #1,d0
 muls #34,d0
 lea $536(a4),a0
 adda.l d0,a0
 move.w #2,-(sp)          ; pair interval:2 centiseconds, NOT callback delay
 move.l a0,-(sp)
 jsr -$7f20(a4)           ; native positional volume/Doppler for both cars
 addq.l #6,sp
 move.w $72(a4),$74(a4)   ; keep native queue empty after presentation
.done:
 rts
sim_sound_native_consume:
 dcb.b 70,0
 rts

; Audio is presentation state, not replay physics state. Drop stale pending
; audio at full initialization and checkpoint restore; never serialize it.
; Caller preserves registers/flags as required by its displaced instruction.
sim_sound_reset:
 move.l a0,-(sp)
 lea sim_sound_pending(pc),a0
 clr.w (a0)
 move.l (sp)+,a0
 rts

 even
 dc.b "4DAUD050"
 dc.w 1,12
sim_sound_pending: dc.w 0
 dc.w 0
sim_sound_published: dc.l 0
sim_sound_played: dc.l 0
 dc.l $41554447            ; AUDG
 IFNE SIM_STARTUP_TESTS
 dc.b "4DAUDTST"
 dc.w 1,42
sim_sound_passed: dc.l 0

; Forty slots, repeated empty reads, burst coalescing across multiple ring
; wraps, and stale-record flush. Calls the same mailbox helpers as the hooks.
sim_sound_selftest:
 movem.l d0-d2/a0,-(sp)
 moveq #1,d2
.slot:
 move.w d2,d0
 bsr sim_sound_offer
 bsr sim_sound_take
 cmp.w d2,d0
 bne .failed
 bsr sim_sound_take
 bne .failed
 lea sim_sound_passed(pc),a0
 addq.l #1,(a0)
 addq.w #1,d2
 cmp.w #41,d2
 bne .slot
 moveq #0,d2
.burst:
 moveq #0,d0
 move.w d2,d0
 divu #40,d0
 swap d0
 addq.w #1,d0
 bsr sim_sound_offer
 addq.w #1,d2
 cmp.w #123,d2
 bne .burst
 bsr sim_sound_take
 cmp.w #3,d0
 bne .failed
 lea sim_sound_pending(pc),a0
 cmp.l #163,sim_sound_published-sim_sound_pending(a0)
 bne .failed
 cmp.l #41,sim_sound_played-sim_sound_pending(a0)
 bne .failed
 lea sim_sound_passed(pc),a0
 addq.l #1,(a0)
 moveq #40,d0
 bsr sim_sound_offer
 bsr sim_sound_reset
 bsr sim_sound_take
 bne .failed
 lea sim_sound_passed(pc),a0
 addq.l #1,(a0)
 lea sim_sound_pending(pc),a0
 moveq #2,d0
.clear:
 clr.l (a0)+
 dbra d0,.clear
 movem.l (sp)+,d0-d2/a0
 rts
.failed:
 lea sim_sound_selftest(pc),a0
 adda.l #perf_failure-sim_sound_selftest,a0
 move.l #36,(a0)
 illegal
 bra.s .failed

 ENDC
