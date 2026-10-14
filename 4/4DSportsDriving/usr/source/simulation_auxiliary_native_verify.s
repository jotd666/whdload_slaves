; Optional live-game fixture. Exercise original creator/updater through installed
; hooks, then restore all persistent race/RNG/fraction state before resuming.
 IFD SIM_AUX_NATIVE_TEST
sim_aux_native_fixture:
 cmp.w #50,-$15fa(a4)
 bne .return
 cmp.w #155,-$940(a4)
 bne .return
 tst.b $45(a4)
 bne .return
 movem.l d0-a6,-(sp)
 lea sim_aux_native_marker(pc),a6
 tst.l 12(a6)
 bne .out
 move.w -$15fa(a4),-(sp)
 lea sim_aux_native_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_aux_native_fixture,a0
 move.w (a0),-(sp)
 move.w #1,(a0)
 lea -$a80(a4),a0
 lea sim_aux_saved_native(pc),a1
 bsr .copy
 lea sim_aux_saved_rng(pc),a0
 move.l $228(a4),(a0)
 move.w $22c(a4),4(a0)
 lea sim_aux_state(pc),a0
 lea sim_aux_saved_fractions(pc),a1
 moveq #SIM_AUX_BYTES/4-1,d0
.save_aux:
 move.l (a0)+,(a1)+
 dbra d0,.save_aux
 bsr .clear_native
 move.w #20,-$15fa(a4)
 bsr .create
 lea -$a80(a4),a0
 lea sim_aux_birth_native(pc),a1
 bsr .copy
 lea sim_aux_birth_rng(pc),a0
 move.l $228(a4),(a0)
 move.w $22c(a4),4(a0)
 bsr .clear_native
 lea sim_aux_saved_rng(pc),a0
 move.l (a0),$228(a4)
 move.w 4(a0),$22c(a4)
 lea sim_aux_state(pc),a0
 moveq #SIM_AUX_BYTES/4-1,d0
.poison:
 move.l #-1,(a0)+
 dbra d0,.poison
 move.w #50,-$15fa(a4)
 bsr .create
 lea sim_aux_birth_native(pc),a0
 lea -$a80(a4),a1
 bsr .compare
 lea sim_aux_birth_rng(pc),a0
 move.l $228(a4),d0
 cmp.l (a0),d0
 bne .failed
 move.w $22c(a4),d0
 cmp.w 4(a0),d0
 bne .failed
 addq.l #1,12(a6)
 ; Exactly18 vehicle births clear their records, leaving the six others alone.
 lea sim_aux_state(pc),a0
 moveq #18*8/4-1,d0
.birth_zero:
 tst.l (a0)+
 bne .failed
 dbra d0,.birth_zero
 moveq #6*8/4-1,d0
.birth_untouched:
 cmp.l #-1,(a0)+
 bne .failed
 dbra d0,.birth_untouched
 addq.l #1,12(a6)
 ; Scenery uses the remaining six pool slots (including slot23), with its
 ; different birth velocity multiplier. No unused poison may survive.
 bsr .create_scenery
 lea -$6f2(a4),a0
 moveq #23,d0
.full_pool:
 tst.w (a0)+
 beq .failed
 dbra d0,.full_pool
 lea sim_aux_state(pc),a0
 moveq #SIM_AUX_BYTES/4-1,d0
.full_zero:
 tst.l (a0)+
 bne .failed
 dbra d0,.full_zero
 lea -$a80(a4),a0
 lea sim_aux_birth_native(pc),a1
 bsr .copy
 addq.l #1,12(a6)
 bsr .clear_aux
 move.w #20,-$15fa(a4)
 bsr .update
 bsr .update
 lea -$a80(a4),a0
 lea sim_aux_expected_native(pc),a1
 bsr .copy
 ; Native Normal keeps the two vertical substeps, unlike horizontal/angles.
 bsr .restore_birth
 move.w #10,-$15fa(a4)
 bsr .update
 lea -$a80(a4),a0
 lea sim_aux_normal_native(pc),a1
 bsr .copy
 lea sim_aux_expected_native+$60(pc),a0
 lea -$a20(a4),a1
 moveq #23,d0
.normal_y:
 move.l (a0)+,d1
 cmp.l (a1)+,d1
 bne .failed
 dbra d0,.normal_y
 lea sim_aux_expected_native+$3be(pc),a0
 lea -$6c2(a4),a1
 moveq #23,d0
.normal_v:
 move.w (a0)+,d1
 cmp.w (a1)+,d1
 bne .failed
 dbra d0,.normal_v
 addq.l #1,12(a6)
 bsr .restore_birth
 move.w #50,-$15fa(a4)
 moveq #4,d7
.five:
 bsr .update
 dbra d7,.five
 lea sim_aux_expected_native(pc),a0
 lea -$a80(a4),a1
 bsr .compare
 addq.l #1,12(a6)
 lea sim_aux_state(pc),a0
 moveq #SIM_AUX_BYTES/4-1,d0
.common_zero:
 tst.l (a0)+
 bne .failed
 dbra d0,.common_zero
 addq.l #1,12(a6)
 ; Force one fragment across the original ground predicate on the next step.
 move.l #-1000000,-$a20(a4)
 clr.w -$6c2(a4)
 bsr .update
 tst.w -$6f2(a4)
 bne .failed
 lea sim_aux_state(pc),a0
 tst.l (a0)
 bne .failed
 tst.l 4(a0)
 bne .failed
 addq.l #1,12(a6)
 ; Reuse the sole retired slot without clearing its live neighbor.
 lea sim_aux_state(pc),a0
 move.l #-1,(a0)
 move.l #-1,4(a0)
 lea sim_aux_reuse_neighbor(pc),a1
 move.l 8(a0),(a1)
 move.l 12(a0),4(a1)
 bsr .create
 tst.w -$6f2(a4)
 beq .failed
 lea sim_aux_state(pc),a0
 tst.l (a0)
 bne .failed
 tst.l 4(a0)
 bne .failed
 addq.l #1,12(a6)
 lea sim_aux_reuse_neighbor(pc),a1
 move.l 8(a0),d0
 cmp.l (a1),d0
 bne .failed
 move.l 12(a0),d0
 cmp.l 4(a1),d0
 bne .failed
 addq.l #1,12(a6)
 ; Restore the interrupted race, including RNG and preexisting fragments.
 lea sim_aux_saved_native(pc),a0
 lea -$a80(a4),a1
 bsr .copy
 lea sim_aux_saved_rng(pc),a0
 move.l (a0),$228(a4)
 move.w 4(a0),$22c(a4)
 lea sim_aux_saved_fractions(pc),a0
 lea sim_aux_state(pc),a1
 moveq #SIM_AUX_BYTES/4-1,d0
.restore_aux:
 move.l (a0)+,(a1)+
 dbra d0,.restore_aux
 lea sim_aux_native_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_aux_native_fixture,a0
 move.w (sp)+,(a0)
 move.w (sp)+,-$15fa(a4)
.out:
 movem.l (sp)+,d0-a6
.return:
 rts
.clear_native:
 lea -$a80(a4),a0
 move.w #$460/4-1,d0
.clear:
 clr.l (a0)+
 dbra d0,.clear
 rts
.clear_aux:
 lea sim_aux_state(pc),a0
 moveq #SIM_AUX_BYTES/4-1,d0
.clear_fraction:
 clr.l (a0)+
 dbra d0,.clear_fraction
 rts
.restore_birth:
 lea sim_aux_birth_native(pc),a0
 lea -$a80(a4),a1
 bsr .copy
 rts
.copy:
 move.w #$460/4-1,d0
.copy_loop:
 move.l (a0)+,(a1)+
 dbra d0,.copy_loop
 rts
.compare:
 move.w #$460/4-1,d0
.compare_loop:
 move.l (a0)+,d1
 cmp.l (a1)+,d1
 bne .failed
 dbra d0,.compare_loop
 rts
.create:
 clr.w -(sp)              ; speed
 clr.w -(sp)              ; heading
 clr.w -(sp)              ; owner0: vehicle, up to18 fragments
 bra.s .create_call
.create_scenery:
 clr.w -(sp)
 clr.w -(sp)
 move.w #2,-(sp)           ; scenery, up to8 fragments in remaining slots
.create_call:
 lea sim_aux_native_fixture(pc),a0
 adda.l #tape_game-sim_aux_native_fixture,a0
 movea.l (a0),a0
 adda.l #$11940,a0
 jsr (a0)
 addq.l #6,sp
 rts
.update:
 lea sim_aux_native_fixture(pc),a0
 adda.l #tape_game-sim_aux_native_fixture,a0
 movea.l (a0),a0
 adda.l #$11b10,a0
 jsr (a0)
 rts
.failed:
 lea sim_aux_native_fixture(pc),a0
 adda.l #perf_failure-sim_aux_native_fixture,a0
 move.l #37,(a0)
 illegal
 bra .failed
 even
sim_aux_native_marker:
 dc.b "4DAUXNAT"
 dc.w 2,9
 dc.l 0
 dc.l $41554e31
sim_aux_saved_native: dcb.b $460,0
sim_aux_saved_rng: dcb.b 6,0
sim_aux_saved_fractions: dcb.b SIM_AUX_BYTES,0
sim_aux_birth_rng: dcb.b 6,0
sim_aux_birth_native: dcb.b $460,0
sim_aux_expected_native: dcb.b $460,0
sim_aux_normal_native: dcb.b $460,0
sim_aux_reuse_neighbor: dcb.b 8,0
 dc.l $41554e32
 ENDC

; Leave real native-created fragments alive across checkpoint1500 for replay
; acceptance. Only the live recording injects the birth; replay restores it.
 IFD SIM_AUX_SPAWN_TEST
sim_aux_spawn_fixture:
 cmp.w #50,-$15fa(a4)
 bne .return
 cmp.w #1498,-$940(a4)
 bne .return
 tst.b $45(a4)
 bne .return
 tst.b -$16d8(a4)
 bne .return
 movem.l d0-a6,-(sp)
 lea sim_aux_spawn_marker(pc),a6
 tst.l 12(a6)
 bne .out
 clr.w -(sp)
 clr.w -(sp)
 clr.w -(sp)
 lea sim_aux_spawn_fixture(pc),a0
 adda.l #tape_game-sim_aux_spawn_fixture,a0
 movea.l (a0),a0
 adda.l #$11940,a0
 jsr (a0)
 addq.l #6,sp
 addq.l #1,12(a6)
.out:
 movem.l (sp)+,d0-a6
.return:
 rts
 even
sim_aux_spawn_marker:
 dc.b "4DAUXSPN"
 dc.w 1,1498
 dc.l 0
 ENDC
