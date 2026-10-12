; Native replay loader integration. Bounded staging precedes any live writes.
; Tagged checkpoints remain pending while the native caller loads resources.
; The full E06A initialization tail installs/restores them exactly once.
sim_replay_load_entry:
 link a5,#0
 movem.l d1-d7/a0-a6,-(sp)
 lea sim_replay_pending(pc),a0
 clr.w (a0)                ; staging will be overwritten; never retain stale pending data
 pea -$1736(a4)
 pea sim_replay_extension(pc)
 move.l 12(a5),-(sp)
 move.l 8(a5),-(sp)
 lea sim_replay_load_entry(pc),a0
 adda.l #sim_game-sim_replay_load_entry,a0
 move.l (a0),a0
 adda.l #$189a6,a0
 jsr (a0)
 lea 16(sp),sp
 lea -$1736(a4),a0
 lea sim_replay_load_entry(pc),a1
 adda.l #sim_replay_pending_file-sim_replay_load_entry,a1
 movea.l $bda(a4),a6
 bsr sim_replay_file_read
 lea sim_replay_menu_status(pc),a2
 move.l d0,(a2)
 tst.l d0
 bne .failed
 move.l d1,d7
 IFD SIM_RUNTIME
 cmp.w #50,d7
 bne .timing_allowed
 btst #0,_custom3+3(pc)
 bne .unsupported_timing
 lea sim_replay_load_entry(pc),a0
 adda.l #sim_time_field_hz-sim_replay_load_entry,a0
 cmp.w #50,(a0)
 beq .timing_allowed
.unsupported_timing:
 move.l #4,(a2)           ; valid A4000 file, incompatible timing/video
 bra .failed             ; no live prefix, input or checkpoint writes yet
.timing_allowed:
 ENDC
 movea.l a1,a3
 cmp.w #50,d7
 bne .prefix
 adda.w #SIM_REPLAY_HEADER,a3
.prefix:
 movea.l a3,a0
 movea.l -$177c(a4),a1
 move.w #SIM_REPLAY_PREFIX-1,d0
 bsr sim_replay_copy
 cmp.w #50,d7
 beq .header
 ; Native input must also be scattered into the enlarged allocation.
 movea.l -$1770(a4),a1
 move.l d2,d0
 sub.l #SIM_REPLAY_PREFIX,d0
 beq .header
 subq.w #1,d0
 bsr sim_replay_copy
.header:
 movea.l a3,a0
 lea -$1750(a4),a1
 moveq #25,d0
 bsr sim_replay_copy
 lea sim_replay_pending(pc),a0
 clr.w (a0)
 cmp.w #50,d7
 bne .loaded
 move.w #1,(a0)
 ; Full native initialization re-enables the CIA producer. A loaded tagged
 ; replay must own playback mode before that reset, so it advances the
 ; recorded cursor instead of overwriting restored inputs with live keys.
 move.b #2,$45(a4)
.loaded:
 lea sim_replay_menu_loads(pc),a0
 addq.l #1,(a0)
 moveq #0,d0
 bra .out
.failed:
 bsr sim_replay_load_notice
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 unlk a5
 rts

; Full native initialization tail; preserve incoming X and all registers.
sim_replay_init_tail:
 move.b -1(a5),-$656(a4) ; execute before restoring a saved checkpoint
 movem.l d0-d7/a0-a6,-(sp)
 moveq #0,d0
 addx.w d0,d0
 move.w d0,-(sp)
 lea sim_replay_pending(pc),a0
 tst.w (a0)
 bne .install
 ; The native UI can build an opponent while still in A2500, then reuse
 ; that route on Re-start Driving after selecting A4000. Rebuild only a
 ; fresh live 50 Hz race, never a replay seek or a pending file install.
 cmp.w #-1,8(a5)
 bne .out
 cmp.w #50,-$15fa(a4)
 bne .out
 ; Re-start Driving invokes initialization while mode is still replay.
 ; Identify the three native fresh-race callers, excluding attract/load/seek.
 lea sim_replay_init_tail(pc),a0
 adda.l #sim_game-sim_replay_init_tail,a0
 move.l 4(a5),d0
 sub.l (a0),d0
 cmp.l #$7022,d0
 beq .fresh_race
 cmp.l #$7530,d0
 beq .fresh_race
 cmp.l #$9d0e,d0
 bne .out
.fresh_race:
 tst.b -$16d8(a4)
 bne .out
 tst.b -$174a(a4)
 beq .out
 lea sim_replay_init_tail(pc),a0
 adda.l #sim_game-sim_replay_init_tail,a0
 move.l (a0),a0
 adda.l #$162f6,a0
 jsr (a0)
 bra .out
.install:
 cmp.w #-1,8(a5)
 bne .out
 lea sim_replay_init_tail(pc),a0
 adda.l #sim_replay_pending_file-sim_replay_init_tail,a0
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_install
 lea sim_replay_menu_install_status(pc),a0
 move.l d0,(a0)
 tst.l d0
 bne .failed
 ; Restore the initial retained checkpoint without opening a nested seek UI.
 movea.l -$16bc(a4),a0
 lea -$a80(a4),a1
 move.w #$460-1,d0
 bsr sim_replay_copy
 moveq #0,d0
 lea sim_replay_init_tail(pc),a1
 adda.l #sim_a4000_private-sim_replay_init_tail,a1
 lea $228(a4),a2
 bsr sim_history_load
 lea sim_replay_init_tail(pc),a0
 adda.l #sim_results_state-sim_replay_init_tail,a0
 move.w 14(a0),$50(a4)
 move.w -$940(a4),$a0(a4)
 lea sim_replay_pending(pc),a0
 clr.w (a0)
 lea sim_replay_menu_installs(pc),a0
 addq.l #1,(a0)
 bra .out
.failed:
 ; An immutable validated pending packet must install at active rate50.
 lea sim_replay_init_tail(pc),a0
 adda.l #perf_failure-sim_replay_init_tail,a0
 move.l #33,(a0)
 illegal
 bra .failed
.out:
 move.w (sp)+,d0
 lsr.w #1,d0
 movem.l (sp)+,d0-d7/a0-a6
 tst.b -1(a5)             ; displaced MOVE flags, without rewriting replay state
 rts

; 9E50: discard the original eight bytes of loader arguments. Failure exits
; the menu branch before count clearing, resource reload or race initialization.
sim_replay_load_result:
 movem.l a0,-(sp)
 movea.l 4(sp),a0
 tst.b d0
 beq .success
 adda.l #$9f24-$9e56,a0
 bra .target
.success:
 addq.l #4,a0
.target:
 move.l a0,12(sp)
 movem.l (sp)+,a0
 lea 8(sp),sp
 rts

sim_replay_load_notice:
 movem.l d0-a6,-(sp)
 clr.w -(sp)
 clr.l -(sp)
 move.w -$45d4(a4),-(sp)
 move.w #-1,-(sp)
 move.w #-1,-(sp)
 IFD SIM_RUNTIME
 lea sim_replay_menu_status(pc),a0
 cmp.l #4,(a0)
 bne .ordinary_notice
 pea sim_replay_legacy_text(pc)
 bra .notice_text
.ordinary_notice:
 ENDC
 pea sim_replay_load_text(pc)
 IFD SIM_RUNTIME
.notice_text:
 ENDC
 move.w #1,-(sp)
 move.w #1,-(sp)
 lea sim_replay_load_notice(pc),a0
 adda.l #sim_game-sim_replay_load_notice,a0
 move.l (a0),a0
 adda.l #$17034,a0
 jsr (a0)
 lea 20(sp),sp
 movem.l (sp)+,d0-a6
 rts
sim_replay_extension: dc.b ".rpl",0
sim_replay_load_text:
 ; Native message rows require a closing bracket, including a single line.
 dc.b "Replay file missing or invalid.]",0
 IFD SIM_RUNTIME
sim_replay_legacy_text:
 dc.b "A4000 replay requires PAL and new timing.]",0
 ENDC
 even
 dc.b "4DRPLMNU"
 dc.w 1,0
sim_replay_menu_status: dc.l 0
sim_replay_menu_loads: dc.l 0
sim_replay_menu_install_status: dc.l -1
sim_replay_menu_installs: dc.l 0
sim_replay_pending: dc.w 0
