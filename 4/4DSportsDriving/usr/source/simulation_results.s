; Full A4000 result-time state. Native words remain low-word mirrors until
; their result/UI consumers and disk representation are converted separately.
SIM_TIME_STATE_BYTES = 32
; +0 accumulated penalties, +4 player finish (including penalties),
; +8 opponent finish, +12 last awarded penalty, +16 player event,
; +20 opponent event; these six longs are unsigned 50 Hz ticks.
; +24/+28: unsigned 64-bit accumulated native speed samples, high/low.
sim_results_reset:
 movem.l d0/a0,-(sp)
 lea sim_results_state(pc),a0
 moveq #SIM_TIME_STATE_BYTES/4-1,d0
.clear:
 clr.l (a0)+
 dbra d0,.clear
 cmp.w #50,-$15fa(a4)
 bne .native
 clr.w $50(a4)
.native:
 movem.l (sp)+,d0/a0
 move.w -2(a5),-$936(a4)
 rts

; The native EXT.L after multiplication discards/sign-extends the product.
; Retain the complete product in A4000 before multiplying by three.
sim_results_award:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -6(a5),d0
 muls -$15fa(a4),d0
 ext.l d0
 move.l d0,d1
 lsl.l #1,d0
 add.l d1,d0
 move.w d0,$50(a4)
 rts
.wide:
 move.w -6(a5),d0
 mulu #50,d0
 move.l d0,d1
 lsl.l #1,d0
 add.l d1,d0
 movem.l a0,-(sp)
 lea sim_results_state(pc),a0
 move.l d0,12(a0)
 movem.l (sp)+,a0
 move.w d0,$50(a4)
 rts

sim_results_accumulate:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w $50(a4),d0
 add.w d0,-$936(a4)
 rts
.wide:
 movem.l a0,-(sp)
 lea sim_results_state(pc),a0
 move.l 12(a0),d0
 add.l d0,(a0)
 move.w 2(a0),-$936(a4)
 movem.l (sp)+,a0
 rts

sim_results_player:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2e0(a4),d0
 add.w -$940(a4),d0
 add.w -$936(a4),d0
 move.w d0,-$93e(a4)
 rts
.wide:
 movem.l d1/a0,-(sp)
 moveq #0,d0
 move.w -$2e0(a4),d0
 moveq #0,d1
 move.w -$940(a4),d1
 add.l d1,d0
 lea sim_results_state(pc),a0
 add.l (a0),d0
 move.l d0,4(a0)
 movem.l (sp)+,d1/a0
 move.w d0,-$93e(a4)
 rts

sim_results_opponent:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2e0(a4),d0
 add.w -$940(a4),d0
 move.w d0,-$93c(a4)
 rts
.wide:
 movem.l d1/a0,-(sp)
 moveq #0,d0
 move.w -$2e0(a4),d0
 moveq #0,d1
 move.w -$940(a4),d1
 add.l d1,d0
 lea sim_results_state(pc),a0
 move.l d0,8(a0)
 movem.l (sp)+,d1/a0
 move.w d0,-$93c(a4)
 rts
 even
 dc.b "4DTSTATE"
 dc.w 3,SIM_TIME_STATE_BYTES
sim_results_state: dcb.b SIM_TIME_STATE_BYTES,0

; $116AA copies the result summary only when the original bit-2 replay gate
; permits it. Preserve the same ownership for wide values: seeking a replay
; restores sim_results_state, but must not overwrite the completed result.
; Input D0=4, A0=summary, A1=live stats. Native copy covers exactly 22 bytes.
sim_results_summary_copy:
.copy:
 move.l (a1)+,(a0)+
 dbra d0,.copy
 movem.l d0/a0-a1,-(sp)
 lea sim_results_summary(pc),a0
 cmp.w #50,-$15fa(a4)
 bne .clear
 lea sim_results_state(pc),a1
 moveq #SIM_TIME_STATE_BYTES/4-1,d0
.wide:
 move.l (a1)+,(a0)+
 dbra d0,.wide
 bra .done
.clear:
 moveq #SIM_TIME_STATE_BYTES/4-1,d0
.zero:
 clr.l (a0)+
 dbra d0,.zero
.done:
 movem.l (sp)+,d0/a0-a1
 move.w (a1)+,(a0)+       ; original final MOVE flags; all above preserves X
 rts
 even
 dc.b "4DRSUMRY"
 dc.w 3,SIM_TIME_STATE_BYTES
sim_results_summary: dcb.b SIM_TIME_STATE_BYTES,0
