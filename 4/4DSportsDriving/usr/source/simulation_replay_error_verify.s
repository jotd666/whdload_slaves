; Invoke the real native loader with a missing replay and retain the race.
sim_replay_error_fixture:
 cmp.w #50,-$15fa(a4)
 bne .return
 tst.b $45(a4)
 bne .return
 tst.b -$16d8(a4)
 bne .return
 cmp.w #160,-$940(a4)
 bne .return
 movem.l d0-a6,-(sp)
 lea sim_replay_error_fixture(pc),a5
 adda.l #sim_replay_error_marker-sim_replay_error_fixture,a5
 tst.l 12(a5)
 bne .out
 lea sim_replay_error_fixture(pc),a0
 adda.l #tape_configured-sim_replay_error_fixture,a0
 tst.l (a0)
 beq .out
 lea sim_replay_error_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_replay_error_fixture,a0
 move.w #1,(a0)
 lea -$1750(a4),a0
 moveq #26,d0
 bsr sim_replay_crc
 move.l d0,20(a5)
 pea sim_replay_error_name(pc)
 pea sim_replay_error_directory(pc)
 lea sim_replay_error_fixture(pc),a0
 adda.l #tape_game-sim_replay_error_fixture,a0
 move.l (a0),a0
 adda.l #$80ee,a0
 jsr (a0)
 addq.l #8,sp
 move.l d0,16(a5)
 cmp.w #1,d0
 bne .failed
 lea -$1750(a4),a0
 moveq #26,d0
 bsr sim_replay_crc
 move.l d0,24(a5)
 cmp.l 20(a5),d0
 bne .failed
 cmp.w #160,-$940(a4)
 bne .failed
 move.l #1,12(a5)
.out:
 movem.l (sp)+,d0-a6
.return:
 rts
.failed:
 lea sim_replay_error_fixture(pc),a0
 adda.l #perf_failure-sim_replay_error_fixture,a0
 move.l #34,(a0)
 illegal
 bra .failed
sim_replay_error_directory: dc.b 0
sim_replay_error_name: dc.b "missing-replay-test",0
 even
sim_replay_error_marker:
 dc.b "4DRPLERR"
 dc.w 1,0
 dc.l 0,-1,0,0
