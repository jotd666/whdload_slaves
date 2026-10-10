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
 IFNE SIM_STARTUP_TESTS
 dc.b "4DEVNTST"
 dc.w 1,8
sim_events_passed: dc.l 0
sim_events_cases:
 dc.w 10,0,300,1500,300
 dc.l 0,1800
 dc.w 20,6000,29999,6600,29999
 dc.l 0,36599
 dc.w 50,0,0,1500,64036
 dc.l 0,0
 dc.w 50,0,160,1500,64196
 dc.l 160,160
 dc.w 50,43500,29999,45000,28499
 dc.l 73499,73499
 dc.w 50,36000,29536,37500,28036
 dc.l 65536,65536
 dc.w 50,45000,30000,45000,30000
 dc.l 75000,75000
 dc.w 50,0,30000,30000,0
 dc.l 30000,30000
sim_events_selftest:
 movem.l d0-a6,-(sp)
 lea sim_events_selftest(pc),a4
 adda.l #sim_results_test_arena+$1600-sim_events_selftest,a4
 lea $40(a4),a5
 clr.w -2(a5)
 lea sim_events_cases(pc),a2
 moveq #7,d7
.case:
 bsr sim_results_reset
 move.w (a2),-$15fa(a4)
 move.w 2(a2),-$2e0(a4)
 move.w 4(a2),-$940(a4)
 moveq #0,d6
 subq.w #1,d6
 bsr sim_events_record_player
 bsr sim_events_record_opponent
 moveq #0,d6
 addx.w d6,d6
 cmp.w #1,d6
 bne .failed
 move.w 4(a2),d0
 cmp.w -$93a(a4),d0
 bne .failed
 cmp.w -$938(a4),d0
 bne .failed
 lea sim_results_state(pc),a0
 move.l 10(a2),d0
 cmp.l 16(a0),d0
 bne .failed
 cmp.l 20(a0),d0
 bne .failed
 move.w 6(a2),-$2e0(a4)
 moveq #0,d6
 subq.w #1,d6
 bsr sim_events_local_player
 moveq #0,d6
 addx.w d6,d6
 cmp.w #1,d6
 bne .failed
 move.w 8(a2),d0
 cmp.w -2(a5),d0
 bne .failed
 moveq #0,d6
 add.w d6,d6
 bsr sim_events_local_opponent
 moveq #0,d6
 addx.w d6,d6
 tst.w d6
 bne .failed
 move.w 8(a2),d0
 cmp.w -2(a5),d0
 bne .failed
 lea sim_results_summary(pc),a0
 move.l 10(a2),16(a0)
 move.l 10(a2),20(a0)
 move.w 4(a2),-$2ec(a4)
 move.w 4(a2),-$2ea(a4)
 bsr sim_events_summary_compare
 bne .failed
 bsr sim_events_average_test
 cmp.w #50,-$15fa(a4)
 beq .full
 and.l #$ffff,d0
.full:
 cmp.l 14(a2),d0
 bne .failed
 bsr sim_events_average_divisor
 cmp.l 14(a2),d1
 bne .failed
 ; The same pair must remain unequal when the full times differ by65536.
 lea sim_results_summary(pc),a0
 add.l #65536,20(a0)
 bsr sim_events_summary_compare
 seq d0
 cmp.w #50,-$15fa(a4)
 bne .native_equal
 tst.b d0
 bne .failed
 bra .passed
.native_equal:
 tst.b d0
 beq .failed
.passed:
 lea sim_events_passed(pc),a0
 addq.l #1,(a0)
 lea 18(a2),a2
 dbra d7,.case
 clr.w -2(a5)
 bsr sim_results_reset
 lea sim_results_summary(pc),a0
 moveq #SIM_TIME_STATE_BYTES/4-1,d0
.clear:
 clr.l (a0)+
 dbra d0,.clear
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #23,(a0)
 illegal
 bra .failed

 ENDC
