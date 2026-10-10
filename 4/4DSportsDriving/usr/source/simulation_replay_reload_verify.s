 IFND SIM_REPLAY_RELOAD_TARGET
SIM_REPLAY_RELOAD_TARGET = 1555
 ENDC
; Fresh-process acceptance: load a packet saved by a different emulator run,
; install into the actual game arrays, then invoke the original native seek.
; This fixture uses matching DEFAULT assets already initialized by the game.
sim_replay_reload_fixture:
 cmp.w #50,-$15fa(a4)
 bne .return
 tst.b $45(a4)
 bne .return
 tst.b -$16d8(a4)
 bne .return
 cmp.w #160,-$940(a4)
 bne .return
 movem.l d0-a6,-(sp)
 lea sim_replay_reload_fixture(pc),a0
 adda.l #tape_configured-sim_replay_reload_fixture,a0
 tst.l (a0)
 beq .out
 lea sim_replay_reload_fixture(pc),a5
 adda.l #sim_replay_reload_marker-sim_replay_reload_fixture,a5
 tst.l 12(a5)
 bne .out
 lea sim_replay_reload_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_replay_reload_fixture,a0
 move.w #1,(a0)
 IFD SIM_REPLAY_MENU
 ; Exercise the patched native loader and the original full race initializer.
 pea sim_replay_reload_basename(pc)
 pea sim_replay_reload_directory(pc)
 lea sim_replay_reload_fixture(pc),a0
 adda.l #tape_game-sim_replay_reload_fixture,a0
 move.l (a0),a0
 adda.l #$80ee,a0
 jsr (a0)
 addq.l #8,sp
 move.l d0,16(a5)
 tst.l d0
 bne .failed
 moveq #0,d0
 move.b -$173a(a4),d0
 move.w d0,-$15fa(a4)
 move.w #-1,-(sp)
 lea sim_replay_reload_fixture(pc),a0
 adda.l #tape_game-sim_replay_reload_fixture,a0
 move.l (a0),a0
 adda.l #$e06a,a0
 jsr (a0)
 addq.l #2,sp
 lea sim_replay_reload_fixture(pc),a0
 adda.l #sim_replay_menu_install_status-sim_replay_reload_fixture,a0
 move.l (a0),20(a5)
 tst.l (a0)
 bne .failed
 tst.w -$940(a4)
 bne .failed
 ELSE
 movea.l $bda(a4),a6
 lea sim_replay_reload_name(pc),a0
 lea sim_replay_reload_fixture(pc),a1
 adda.l #sim_replay_reload_buffer-sim_replay_reload_fixture,a1
 bsr sim_replay_file_read
 move.l d0,16(a5)
 tst.l d0
 bne .failed
 cmp.w #50,d1
 bne .failed
 ; Structurally consistent but unreachable epoch: valid CRC must not help.
 movea.l a1,a3
 move.l 32(a3),d7
 movea.l a3,a2
 adda.l #SIM_REPLAY_CRC_OFFSET,a2
 move.l (a2),d6
 move.w -$1738(a4),d5
 move.l #46500,32(a3)
 movea.l a3,a0
 move.l #SIM_REPLAY_CRC_OFFSET,d0
 bsr sim_replay_crc
 move.l d0,(a2)
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_install
 move.l d0,28(a5)
 cmp.w #1,d0
 bne .failed
 cmp.w #160,-$940(a4)
 bne .failed
 cmp.w -$1738(a4),d5
 bne .failed
 move.l d7,32(a3)
 move.l d6,(a2)
 movea.l a3,a0
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_install
 move.l d0,20(a5)
 tst.l d0
 bne .failed
 ENDC
 move.l #1,12(a5)
 move.b #2,$45(a4)
 move.w #SIM_REPLAY_RELOAD_TARGET,-(sp)
 lea sim_replay_reload_fixture(pc),a0
 adda.l #tape_game-sim_replay_reload_fixture,a0
 move.l (a0),a0
 adda.l #$e518,a0
 jsr (a0)
 addq.l #2,sp
 ; The seek restores the requested checkpoint; normal replay consumes to1555.
 moveq #0,d0
 move.w -$940(a4),d0
 move.l d0,24(a5)
.out:
 movem.l (sp)+,d0-a6
.return:
 rts
.failed:
 lea sim_replay_reload_fixture(pc),a0
 adda.l #perf_failure-sim_replay_reload_fixture,a0
 move.l #32,(a0)
 illegal
 bra .failed
sim_replay_reload_directory: dc.b 0
sim_replay_reload_basename: dc.b "A4000-io-test",0
sim_replay_reload_name: dc.b "A4000-io-test.rpl",0
 even
