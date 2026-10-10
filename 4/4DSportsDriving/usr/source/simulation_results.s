; Full A4000 result-time state. Native words remain low-word mirrors until
; their result/UI consumers and disk representation are converted separately.
SIM_TIME_STATE_BYTES = 16
; +0 accumulated penalties, +4 player finish (including penalties),
; +8 opponent finish, +12 last awarded penalty; all unsigned 50 Hz ticks.
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
 dc.w 1,SIM_TIME_STATE_BYTES
sim_results_state: dcb.b SIM_TIME_STATE_BYTES,0

 dc.b "4DRESTST"
 dc.w 1,10
sim_results_passed: dc.l 0
sim_results_cases:
 dc.w 10,0,150,1
 dc.l 0
 dc.w 30,30,180,150
 dc.l 0,0,0,0
 dc.w 10,6000,9000,900
 dc.l 500
 dc.w 27000,27500,42500,15000
 dc.l 0,0,0,0
 dc.w 20,0,300,1
 dc.l 0
 dc.w 60,60,360,300
 dc.l 0,0,0,0
 dc.w 20,18000,12000,900
 dc.l 300
 dc.w 54000,54300,18764,30000
 dc.l 0,0,0,0
 dc.w 50,0,160,1
 dc.l 0
 dc.w 150,150,310,160
 dc.l 150,310,160,150
 dc.w 50,0,160,900
 dc.l 0
 dc.w 3928,3928,4088,160
 dc.l 135000,135160,160,135000
 dc.w 50,45000,29999,1
 dc.l 65535
 dc.w 150,149,9612,9463
 dc.l 65685,140684,74999,150
 dc.w 50,45000,30000,900
 dc.l 65535
 dc.w 3928,3927,13391,9464
 dc.l 200535,275535,75000,135000
 dc.w 50,36000,29536,218
 dc.l 0
 dc.w 32700,32700,32700,0
 dc.l 32700,98236,65536,32700
 dc.w 50,45000,30000,32767
 dc.l 1048576
 dc.w 65386,65386,9314,9464
 dc.l 5963626,6038626,75000,4915050
sim_results_selftest:
 movem.l d0-a6,-(sp)
 lea sim_results_selftest(pc),a4
 adda.l #sim_results_test_arena+$1600-sim_results_selftest,a4
 lea $40(a4),a5
 clr.w -2(a5)
 lea sim_results_cases(pc),a2
 moveq #9,d7
.case:
 bsr sim_results_reset
 move.w (a2)+,-$15fa(a4)
 move.w (a2)+,-$2e0(a4)
 move.w (a2)+,-$940(a4)
 move.w (a2)+,-6(a5)
 move.l (a2)+,d0
 move.w d0,-$936(a4)
 cmp.w #50,-$15fa(a4)
 bne .native
 lea sim_results_state(pc),a0
 move.l d0,(a0)
.native:
 bsr sim_results_award
 bsr sim_results_accumulate
 bsr sim_results_player
 bsr sim_results_opponent
 move.w $50(a4),d0
 cmp.w (a2)+,d0
 bne .failed
 move.w -$936(a4),d0
 cmp.w (a2)+,d0
 bne .failed
 move.w -$93e(a4),d0
 cmp.w (a2)+,d0
 bne .failed
 move.w -$93c(a4),d0
 cmp.w (a2)+,d0
 bne .failed
 lea sim_results_state(pc),a0
 moveq #3,d0
.check:
 move.l (a0)+,d1
 cmp.l (a2)+,d1
 bne .failed
 dbra d0,.check
 lea sim_results_passed(pc),a0
 addq.l #1,(a0)
 dbra d7,.case
 bsr sim_results_reset
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #20,(a0)
 illegal
 bra.s .failed

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
 dc.w 1,SIM_TIME_STATE_BYTES
sim_results_summary: dcb.b SIM_TIME_STATE_BYTES,0
 dc.b "4DRSUMST"
 dc.w 1,3
sim_results_summary_passed: dc.l 0
sim_results_summary_test_modes: dc.w 10,20,50
sim_results_summary_test_source:
 dc.l $12345678,$90abcdef,$fedcba98,$76543210,$f00dcafe
 dc.w $8000
sim_results_summary_test_dest: dcb.b 22,0
sim_results_summary_selftest:
 movem.l d0-a6,-(sp)
 lea sim_results_summary_selftest(pc),a4
 adda.l #sim_results_test_arena+$1600-sim_results_summary_selftest,a4
 lea sim_results_summary_test_modes(pc),a3
 moveq #2,d7
.case:
 move.w (a3)+,-$15fa(a4)
 lea sim_results_state(pc),a0
 move.l #65538,(a0)+
 move.l #75000,(a0)+
 move.l #74999,(a0)+
 move.l #135000,(a0)
 lea sim_results_summary(pc),a0
 moveq #3,d0
.dirty:
 move.l #-1,(a0)+
 dbra d0,.dirty
 lea sim_results_summary_test_source(pc),a1
 lea sim_results_summary_test_dest(pc),a0
 moveq #4,d0
 bsr sim_results_summary_copy
 cmp.w #$ffff,d0
 bne .failed
 lea sim_results_summary_test_source+22(pc),a2
 cmpa.l a2,a1
 bne .failed
 lea sim_results_summary_test_dest+22(pc),a2
 cmpa.l a2,a0
 bne .failed
 lea sim_results_summary_test_source(pc),a1
 lea sim_results_summary_test_dest(pc),a0
 moveq #10,d0
.native:
 move.w (a1)+,d1
 cmp.w (a0)+,d1
 bne .failed
 dbra d0,.native
 lea sim_results_summary(pc),a0
 lea sim_results_state(pc),a1
 moveq #3,d0
.check:
 moveq #0,d1
 cmp.w #50,-$15fa(a4)
 bne .compare
 move.l (a1)+,d1
.compare:
 cmp.l (a0)+,d1
 bne .failed
 dbra d0,.check
 lea sim_results_summary_passed(pc),a0
 addq.l #1,(a0)
 dbra d7,.case
 lea sim_results_state(pc),a0
 lea sim_results_summary(pc),a1
 moveq #3,d0
.reset:
 clr.l (a0)+
 clr.l (a1)+
 dbra d0,.reset
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #21,(a0)
 illegal
 bra .failed
