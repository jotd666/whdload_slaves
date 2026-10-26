; Absolute event timestamps. Native words retain their original local-cursor
; values; all converted A4000 consumers use the replayable absolute values.
sim_events_record_player:
 cmp.w #50,-$15fa(a4)
 bne .native
 movem.l d0-d1/a0,-(sp)
 moveq #0,d0
 addx.w d0,d0
 move.w d0,-(sp)
 moveq #0,d0
 move.w -$2e0(a4),d0
 moveq #0,d1
 move.w -$940(a4),d1
 add.l d1,d0
 lea sim_results_state(pc),a0
 move.l d0,16(a0)
 move.w (sp)+,d0
 lsr.w #1,d0
 movem.l (sp)+,d0-d1/a0
.native:
 move.w -$940(a4),-$93a(a4)
 rts

; Existing animation helpers subtract this local word from the current local
; cursor. Re-express the absolute event relative to the CURRENT rolling base.
sim_events_local_player:
 cmp.w #50,-$15fa(a4)
 bne .native
 movem.l d0-d1/a0,-(sp)
 moveq #0,d0
 addx.w d0,d0
 move.w d0,-(sp)
 lea sim_results_state(pc),a0
 move.l 16(a0),d0
 moveq #0,d1
 move.w -$2e0(a4),d1
 sub.l d1,d0
 move.w d0,-2(a5)
 move.w (sp)+,d0
 lsr.w #1,d0
 movem.l (sp)+,d0-d1/a0
 tst.w -2(a5)
 rts
.native:
 move.w -$93a(a4),-2(a5)
 rts
sim_events_record_opponent:
 cmp.w #50,-$15fa(a4)
 bne .native
 movem.l d0-d1/a0,-(sp)
 moveq #0,d0
 addx.w d0,d0
 move.w d0,-(sp)
 moveq #0,d0
 move.w -$2e0(a4),d0
 moveq #0,d1
 move.w -$940(a4),d1
 add.l d1,d0
 lea sim_results_state(pc),a0
 move.l d0,20(a0)
 move.w (sp)+,d0
 lsr.w #1,d0
 movem.l (sp)+,d0-d1/a0
.native:
 move.w -$940(a4),-$938(a4)
 rts

; Existing animation helpers subtract this local word from the current local
; cursor. Re-express the absolute event relative to the CURRENT rolling base.
sim_events_local_opponent:
 cmp.w #50,-$15fa(a4)
 bne .native
 movem.l d0-d1/a0,-(sp)
 moveq #0,d0
 addx.w d0,d0
 move.w d0,-(sp)
 lea sim_results_state(pc),a0
 move.l 20(a0),d0
 moveq #0,d1
 move.w -$2e0(a4),d1
 sub.l d1,d0
 move.w d0,-2(a5)
 move.w (sp)+,d0
 lsr.w #1,d0
 movem.l (sp)+,d0-d1/a0
 tst.w -2(a5)
 rts
.native:
 move.w -$938(a4),-2(a5)
 rts

sim_events_summary_compare:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2ea(a4),d0
 cmp.w -$2ec(a4),d0
 rts
.wide:
 movem.l a0,-(sp)
 lea sim_results_summary(pc),a0
 move.l 20(a0),d0
 cmp.l 16(a0),d0
 movem.l (sp)+,a0
 rts
sim_events_average_test:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2e0(a4),d0
 add.w -$2ec(a4),d0
 rts
.wide:
 movem.l a0,-(sp)
 lea sim_results_summary(pc),a0
 move.l 16(a0),d0
 movem.l (sp)+,a0
 rts
sim_events_average_divisor:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2e0(a4),d1
 add.w -$2ec(a4),d1
 and.l #$ffff,d1
 rts
.wide:
 movem.l a0,-(sp)
 lea sim_results_summary(pc),a0
 move.l 16(a0),d1
 movem.l (sp)+,a0
 rts
 even
