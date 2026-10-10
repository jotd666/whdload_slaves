 IFND SIM_REPLAY_SAVE_RATE
SIM_REPLAY_SAVE_RATE = 50
 ENDC
 IFND SIM_REPLAY_SAVE_TICK
SIM_REPLAY_SAVE_TICK = 160
 ENDC
; Real native direct save plus the chooser's confirmed-write branch. File-name
; navigation/overwrite prompts remain a separate UI acceptance requirement.
sim_replay_save_fixture:
 cmp.w #SIM_REPLAY_SAVE_RATE,-$15fa(a4)
 bne .return
 tst.b $45(a4)
 bne .return
 tst.b -$16d8(a4)
 bne .return
 cmp.w #SIM_REPLAY_SAVE_TICK,-$940(a4)
 bne .return
 movem.l d0-a6,-(sp)
 lea sim_replay_save_fixture(pc),a0
 adda.l #tape_configured-sim_replay_save_fixture,a0
 tst.l (a0)
 beq .out
 lea sim_replay_save_test_marker(pc),a3
 tst.l 12(a3)
 bne .out
 lea sim_replay_save_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_replay_save_fixture,a0
 move.w #1,(a0)
 pea sim_replay_save_test_direct(pc)
 lea sim_replay_save_fixture(pc),a0
 adda.l #tape_game-sim_replay_save_fixture,a0
 move.l (a0),a0
 adda.l #$813e,a0
 jsr (a0)
 addq.l #4,sp
 tst.w d0
 bne .failed
 addq.l #1,12(a3)
 lea sim_replay_save_test_dialog(pc),a0
 movea.l -$177c(a4),a1
 moveq #0,d0
 move.w -$1738(a4),d0
 add.l #SIM_REPLAY_PREFIX,d0
 bsr sim_replay_save_test_chooser
 cmp.w #1,d0
 bne .failed
 addq.l #1,12(a3)
 ; The same generic dialog call must leave non-replay payloads untouched.
 lea sim_replay_save_test_other(pc),a0
 lea sim_replay_save_test_payload(pc),a1
 moveq #4,d0
 bsr sim_replay_save_test_chooser
 cmp.w #1,d0
 bne .failed
 addq.l #1,12(a3)
.out:
 movem.l (sp)+,d0-a6
.return:
 rts
.failed:
 lea sim_replay_save_fixture(pc),a0
 adda.l #perf_failure-sim_replay_save_fixture,a0
 move.l #35,(a0)
 illegal
 bra .failed

; Recreate the native chooser frame at its confirmed-write branch. Its real
; argument cleanup, status test and UNLK/RTS finish this helper normally.
sim_replay_save_test_chooser:
 link a5,#-4
 move.l d0,-(sp)
 move.l a1,-(sp)
 move.l a0,-(sp)
 lea sim_replay_save_test_chooser(pc),a0
 adda.l #tape_game-sim_replay_save_test_chooser,a0
 move.l (a0),a0
 adda.l #$1b1b2,a0
 jmp (a0)
sim_replay_save_test_direct: dc.b "A4000-native-direct.rpl",0
sim_replay_save_test_dialog: dc.b "A4000-native-dialog.rpl",0
sim_replay_save_test_other: dc.b "replay-other-test.dat",0
sim_replay_save_test_payload: dc.b "TEST"
 even
sim_replay_save_test_marker:
 dc.b "4DRPLSVT"
 dc.w 2,3
 dc.l 0
 dc.w SIM_REPLAY_SAVE_RATE,SIM_REPLAY_SAVE_TICK
