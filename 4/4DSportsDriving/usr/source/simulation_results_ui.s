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
