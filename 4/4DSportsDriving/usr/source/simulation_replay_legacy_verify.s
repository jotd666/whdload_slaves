; Fresh-process native10/20 replay acceptance. Assets must match the saved
; DEFAULT race. The file is produced by the native-format save path.
; No synthetic pose/input is injected after playback takes ownership.
sim_replay_legacy_fixture:
 cmp.w #SIM_REPLAY_LEGACY_TEST,-$15fa(a4)
 bne .return
 tst.b $45(a4)
 bne .return
 cmp.w #160,-$940(a4)
 bne .return
 movem.l d0-a6,-(sp)
 lea sim_replay_legacy_fixture(pc),a0
 adda.l #tape_configured-sim_replay_legacy_fixture,a0
 tst.l (a0)
 beq .out
 lea sim_replay_legacy_marker(pc),a3
 tst.l 12(a3)
 bne .out
 lea sim_replay_legacy_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_replay_legacy_fixture,a0
 move.w #1,(a0)
 move.b #2,$45(a4)        ; native caller owns playback before full init
 pea sim_replay_legacy_basename(pc)
 pea sim_replay_legacy_directory(pc)
 lea sim_replay_legacy_fixture(pc),a0
 adda.l #tape_game-sim_replay_legacy_fixture,a0
 move.l (a0),a0
 adda.l #$80ee,a0
 jsr (a0)
 addq.l #8,sp
 tst.w d0
 bne .failed
 cmp.b #SIM_REPLAY_LEGACY_TEST,-$173a(a4)
 bne .failed
 move.w #SIM_REPLAY_LEGACY_TEST,-$15fa(a4)
 move.w #-1,-(sp)
 lea sim_replay_legacy_fixture(pc),a0
 adda.l #tape_game-sim_replay_legacy_fixture,a0
 move.l (a0),a0
 adda.l #$e06a,a0
 jsr (a0)
 addq.l #2,sp
 tst.w -$940(a4)
 bne .failed
 move.w -$1738(a4),16(a3)
 ; Returning through the already entered E5F2 executes the first replay step.
 ; Keep producer ahead of that consumer; all later targets come from fields.
 move.w #1,$a0(a4)
 clr.b $3d(a4)
 clr.b $44(a4)
 addq.l #1,12(a3)
.out:
 movem.l (sp)+,d0-a6
.return:
 rts
.failed:
 lea sim_replay_legacy_fixture(pc),a0
 adda.l #perf_failure-sim_replay_legacy_fixture,a0
 move.l #61,(a0)
 illegal
 bra .failed
sim_replay_legacy_directory: dc.b 0
sim_replay_legacy_basename: dc.b "A4000-native-direct",0
 even
sim_replay_legacy_marker:
 dc.b "4DRPLLEG"
 dc.w 1,SIM_REPLAY_LEGACY_TEST
 dc.l 0
 dc.w 0,0
