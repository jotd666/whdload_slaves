; Completed-result guards and unsigned winner comparison. These consume the
; gated summary, not replay's live state. Every fallback reproduces native
; word flags. Stack-cleanup hooks relocate their injected return address over
; discarded arguments using flag-neutral address/MOVEM instructions.
sim_results_test_player:
 cmp.w #50,-$15fa(a4)
 beq .wide
 tst.w -$2f0(a4)
 rts
.wide:
 movem.l a0,-(sp)
 lea sim_results_summary(pc),a0
 tst.l 4(a0)
 movem.l (sp)+,a0
 rts
sim_results_test_opponent:
 cmp.w #50,-$15fa(a4)
 beq .wide
 tst.w -$2ee(a4)
 rts
.wide:
 movem.l a0,-(sp)
 lea sim_results_summary(pc),a0
 tst.l 8(a0)
 movem.l (sp)+,a0
 rts
sim_results_test_penalty:
 cmp.w #50,-$15fa(a4)
 beq .wide
 tst.w -$2e8(a4)
 rts
.wide:
 movem.l a0,-(sp)
 lea sim_results_summary(pc),a0
 tst.l 0(a0)
 movem.l (sp)+,a0
 rts
sim_results_ui_player_pop8:
 bsr sim_results_test_player
 movem.l a0,-(sp)
 movea.l 4(sp),a0
 movem.l a0,12(sp)
 movem.l (sp)+,a0
 lea 8(sp),sp
 rts
sim_results_ui_penalty_pop12:
 bsr sim_results_test_penalty
 movem.l a0,-(sp)
 movea.l 4(sp),a0
 movem.l a0,16(sp)
 movem.l (sp)+,a0
 lea 12(sp),sp
 rts
sim_results_ui_opponent_bne:
 bsr sim_results_test_opponent
 beq .done
 movem.l a0,-(sp)
 movea.l 4(sp),a0
 lea 84(a0),a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
.done:
 rts
sim_results_ui_player_pop16:
 bsr sim_results_test_player
 movem.l a0,-(sp)
 movea.l 4(sp),a0
 movem.l a0,20(sp)
 movem.l (sp)+,a0
 lea 16(sp),sp
 rts
sim_results_ui_player_beq10:
 bsr sim_results_test_player
 bne .done
 movem.l a0,-(sp)
 movea.l 4(sp),a0
 lea 10(a0),a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
.done:
 rts
sim_results_ui_compare:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2ee(a4),d0
 cmp.w -$2f0(a4),d0
 rts
.wide:
 movem.l a0,-(sp)
 lea sim_results_summary(pc),a0
 move.l 8(a0),d0
 cmp.l 4(a0),d0
 movem.l (sp)+,a0
 rts
sim_results_ui_player_pop24:
 bsr sim_results_test_player
 movem.l a0,-(sp)
 movea.l 4(sp),a0
 movem.l a0,28(sp)
 movem.l (sp)+,a0
 lea 24(sp),sp
 rts
sim_results_ui_player_beq20:
 bsr sim_results_test_player
 bne .done
 movem.l a0,-(sp)
 movea.l 4(sp),a0
 lea 20(a0),a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
.done:
 rts
sim_results_ui_player_pop14:
 bsr sim_results_test_player
 movem.l a0,-(sp)
 movea.l 4(sp),a0
 movem.l a0,18(sp)
 movem.l (sp)+,a0
 lea 14(sp),sp
 rts
sim_results_ui_player_beq42:
 bsr sim_results_test_player
 bne .done
 movem.l a0,-(sp)
 movea.l 4(sp),a0
 lea 42(a0),a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
.done:
 rts
 even
 dc.b "4DRUITST"
 dc.w 1,204
sim_results_ui_passed: dc.l 0
sim_results_ui_selftest:
 movem.l d0-a6,-(sp)
 lea sim_results_ui_selftest(pc),a4
 adda.l #sim_results_test_arena+$1600-sim_results_ui_selftest,a4
 lea sim_results_ui_selftest(pc),a5
 adda.l #sim_results_ui_cases-sim_results_ui_selftest,a5
 move.w #203,d7
sim_results_ui_test_case:
 move.w 20(a5),-$15fa(a4)
 lea sim_results_summary(pc),a0
 move.l 4(a5),4(a0)
 move.l 8(a5),8(a0)
 move.l 12(a5),(a0)
 move.w 6(a5),-$2f0(a4)
 move.w 10(a5),-$2ee(a4)
 move.w 14(a5),-$2e8(a4)
 movea.l sp,a6
 lea sim_results_ui_selftest(pc),a1
 adda.l #sim_results_ui_stack+2048-sim_results_ui_selftest,a1
 movea.l a1,sp
 lea sim_results_ui_return(pc),a0
 movem.l a0,(sp)
 lea sim_results_ui_selftest(pc),a1
 adda.l (a5),a1
 lea sim_results_ui_selftest(pc),a0
 move.l #$88776655,d0
 moveq #0,d6
 tst.w 22(a5)
 beq .xzero
 subq.w #1,d6
 bra .invoke
.xzero:
 add.w d6,d6
.invoke:
 jmp (a1)
sim_results_ui_return:
 lea sim_results_ui_return(pc),a2
 bra.w sim_results_ui_caught
 dcb.w 1,$4e71
sim_results_ui_return_10:
 lea sim_results_ui_return_10(pc),a2
 bra.w sim_results_ui_caught
 dcb.w 1,$4e71
sim_results_ui_return_20:
 lea sim_results_ui_return_20(pc),a2
 bra.w sim_results_ui_caught
 dcb.w 7,$4e71
sim_results_ui_return_42:
 lea sim_results_ui_return_42(pc),a2
 bra.w sim_results_ui_caught
 dcb.w 17,$4e71
sim_results_ui_return_84:
 lea sim_results_ui_return_84(pc),a2
 bra.w sim_results_ui_caught
sim_results_ui_caught:
 seq d2
 scs d3
 smi d4
 svs d5
 moveq #0,d6
 addx.w d6,d6
 movea.l sp,a1
 movea.l a6,sp
 cmp.w 22(a5),d6
 bne .failed
 cmp.b 28(a5),d2
 bne .failed
 cmp.b 29(a5),d3
 bne .failed
 cmp.b 30(a5),d4
 bne .failed
 cmp.b 31(a5),d5
 bne .failed
 cmp.l 16(a5),d0
 bne .failed
 lea sim_results_ui_selftest(pc),a3
 cmpa.l a3,a0
 bne .failed
 lea sim_results_ui_selftest(pc),a3
 adda.l #sim_results_ui_stack+2052-sim_results_ui_selftest,a3
 adda.w 24(a5),a3
 cmpa.l a3,a1
 bne .failed
 lea sim_results_ui_return(pc),a3
 adda.w 26(a5),a3
 cmpa.l a3,a2
 bne .failed
 lea sim_results_ui_passed(pc),a0
 addq.l #1,(a0)
 lea 32(a5),a5
 dbra d7,sim_results_ui_test_case
 lea sim_results_summary(pc),a0
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #22,(a0)
 illegal
 bra .failed
