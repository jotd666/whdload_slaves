; A4000 in-memory companion snapshots. Native snapshot layout stays intact.
; Tagged replays store these companions; native10/20 layouts stay unchanged.
SIM_HISTORY_SLOTS = 20
SIM_HISTORY_AUX_OFFSET = 8+SIM_PRIVATE_BYTES+SIM_TIME_STATE_BYTES
SIM_HISTORY_CAMERA_OFFSET = SIM_HISTORY_AUX_OFFSET+SIM_AUX_BYTES
SIM_HISTORY_BYTES = SIM_HISTORY_CAMERA_OFFSET+SIM_CAMERA_BYTES ; append camera fractions

; E07A is reached only for the native new-race (-1) initialization, which
; invalidates all twenty native snapshots. Seek-zero initialization also calls
; the history-input reset, so that generic reset must NOT erase companions.
sim_history_new_race:
 movem.l d0/a0,-(sp)
 moveq #0,d0
 addx.w d0,d0
 move.w d0,-(sp)
 bsr sim_history_reset
 move.w (sp)+,d0
 lsr.w #1,d0
 movem.l (sp)+,d0/a0
 clr.w -$2e0(a4)
 move.w -2(a5),-4(a5)
 rts

; E548: native seek-zero reinitializes instead of restoring snapshot zero.
; A4000 must use the complete checkpoint, including all RNG and fractions.
; Relocate our return address over the native twenty-byte argument cleanup.
sim_history_seek_zero:
 movem.l a0,-(sp)
 move.l 4(sp),a0
 move.l a0,24(sp)
 movem.l (sp)+,a0
 cmp.w #50,-$15fa(a4)
 bne .native
 tst.w 8(a5)
 bne .done
 movem.l a0,-(sp)
 lea sim_history_slot(pc),a0
 adda.l #sim_history_records-sim_history_slot,a0
 movea.l (a0),a0
 tst.w (a0)
 beq sim_history_failed
 movem.l (sp)+,a0           ; nonzero flags bypass native initialization
 bra.s .done
.native:
 tst.w 8(a5)
.done:
 lea 20(sp),sp
 rts

; E65A: exact native copy loop, followed by companion save at the same tick.
sim_history_save:
.copy:
 move.l (a1)+,(a0)+
 dbra d0,.copy
 movem.l d0-d2/a0-a2,-(sp)
 moveq #0,d2
 addx.w d2,d2
 move.w d2,-(sp)
 cmp.w #50,-$15fa(a4)
 bne .done
 move.w -2(a5),d0
 lea sim_a4000_private(pc),a1
 lea $228(a4),a2
 bsr sim_history_store
 lea sim_history_slot(pc),a0
 adda.l #sim_history_saves-sim_history_slot,a0
 addq.l #1,(a0)
.done:
 move.w (sp)+,d2
 lsr.w #1,d2
 movem.l (sp)+,d0-d2/a0-a2
 tst.l -4(a1)              ; native final MOVE.L flags; DBRA preserves them
 rts

; E5DA: after native state AND legacy RNG restoration, before caller resumes.
sim_history_restore:
 movem.l d0-d2/a0-a2,-(sp)
 moveq #0,d2
 addx.w d2,d2
 move.w d2,-(sp)
 cmp.w #50,-$15fa(a4)
 bne .done
 move.w -2(a5),d0
 lea sim_a4000_private(pc),a1
 lea $228(a4),a2
 bsr sim_history_load
 lea sim_history_restore(pc),a0
 adda.l #sim_sound_reset-sim_history_restore,a0
 jsr (a0)
 lea sim_results_state(pc),a0
 move.w 14(a0),$50(a4)     ; native message word mirrors the restored award
 lea sim_history_slot(pc),a0
 adda.l #sim_history_restores-sim_history_slot,a0
 addq.l #1,(a0)
.done:
 move.w (sp)+,d2
 lsr.w #1,d2
 movem.l (sp)+,d0-d2/a0-a2
 move.w -$940(a4),$a0(a4)   ; displaced instruction, including flags
 rts

; 7D08: native snapshot/input rotation is complete, before cursor rebasing.
sim_history_rotate:
 movem.l d0-d2/a0-a2,-(sp)
 moveq #0,d2
 addx.w d2,d2
 move.w d2,-(sp)
 cmp.w #50,-$15fa(a4)
 bne .done
 bsr sim_history_shift
 lea sim_history_slot(pc),a0
 adda.l #sim_history_rotations-sim_history_slot,a0
 addq.l #1,(a0)
.done:
 move.w (sp)+,d2
 lsr.w #1,d2
 movem.l (sp)+,d0-d2/a0-a2
 move.w -$15fa(a4),d0
 muls #30,d0
 rts

; Helpers: d0.w slot, a1 private state, a2 six-byte RNG. Scratch d0/d1/a0-a2.
sim_history_slot:
 cmp.w #SIM_HISTORY_SLOTS,d0
 bhs sim_history_failed
 mulu #SIM_HISTORY_BYTES,d0
 lea sim_history_slot(pc),a0
 adda.l #sim_history_records-sim_history_slot,a0
 movea.l (a0),a0
 adda.l d0,a0
 rts
sim_history_store:
 bsr sim_history_slot
 clr.w (a0)
 move.l (a2),2(a0)
 move.w 4(a2),6(a0)
 lea 8(a0),a2
 moveq #SIM_PRIVATE_BYTES/4-1,d1
.copy:
 move.l (a1)+,(a2)+
 dbra d1,.copy
 lea sim_results_state(pc),a1
 moveq #SIM_TIME_STATE_BYTES/4-1,d1
.time:
 move.l (a1)+,(a2)+
 dbra d1,.time
 lea sim_history_store(pc),a1
 adda.l #sim_aux_state-sim_history_store,a1
 moveq #SIM_AUX_BYTES/4-1,d1
.auxiliary:
 move.l (a1)+,(a2)+
 dbra d1,.auxiliary
 lea sim_history_store(pc),a1
 adda.l #sim_camera_state-sim_history_store,a1
 move.l (a1)+,(a2)+
 move.l (a1),(a2)+
 move.w #50,(a0)           ; publish a complete companion
 rts
sim_history_load:
 bsr sim_history_slot
 cmp.w #50,(a0)
 bne sim_history_failed    ; never silently reconstruct from stale fractions
 move.l 2(a0),(a2)
 move.w 6(a0),4(a2)
 addq.l #8,a0
 moveq #SIM_PRIVATE_BYTES/4-1,d1
.copy:
 move.l (a0)+,(a1)+
 dbra d1,.copy
 lea sim_results_state(pc),a1
 moveq #SIM_TIME_STATE_BYTES/4-1,d1
.time:
 move.l (a0)+,(a1)+
 dbra d1,.time
 lea sim_history_load(pc),a1
 adda.l #sim_aux_state-sim_history_load,a1
 moveq #SIM_AUX_BYTES/4-1,d1
.auxiliary:
 move.l (a0)+,(a1)+
 dbra d1,.auxiliary
 lea sim_history_load(pc),a1
 adda.l #sim_camera_state-sim_history_load,a1
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)
 rts
sim_history_shift:
 lea sim_history_slot(pc),a0
 adda.l #sim_history_records-sim_history_slot,a0
 movea.l (a0),a0
 lea SIM_HISTORY_BYTES(a0),a1
 move.w #(SIM_HISTORY_SLOTS-1)*SIM_HISTORY_BYTES/4-1,d0
.copy:
 move.l (a1)+,(a0)+
 dbra d0,.copy
 clr.w (a0)               ; old final slot cannot be restored after rotation
 rts
sim_history_reset:
 lea sim_history_slot(pc),a0
 adda.l #sim_history_records-sim_history_slot,a0
 movea.l (a0),a0
 moveq #SIM_HISTORY_SLOTS-1,d0
.clear:
 clr.w (a0)
 lea SIM_HISTORY_BYTES(a0),a0
 dbra d0,.clear
 rts
sim_history_failed:
 lea perf_failure(pc),a0
 move.l #16,(a0)
 illegal
 bra.s sim_history_failed

 IFNE SIM_STARTUP_TESTS
; Save every slot with distinct private/RNG payload, restore in reverse order,
; rotate and check every retained payload, then invalidate all on race reset.
sim_history_selftest:
 movem.l d0-a6,-(sp)
 moveq #0,d7
.seed:
 lea sim_history_slot(pc),a1
 adda.l #sim_history_test_private-sim_history_slot,a1
 moveq #SIM_PRIVATE_BYTES/4-1,d0
.fill:
 move.l d7,(a1)+
 dbra d0,.fill
 lea sim_results_state(pc),a0
 move.l d7,d0
 lsl.l #3,d0
 moveq #SIM_TIME_STATE_BYTES/4-1,d1
.times:
 move.l d0,(a0)+
 addq.l #1,d0
 dbra d1,.times
 lea sim_history_selftest(pc),a0
 adda.l #sim_aux_state-sim_history_selftest,a0
 move.l d7,d0
 lsl.l #8,d0
 moveq #SIM_AUX_BYTES/4-1,d1
.aux_seed:
 move.l d0,(a0)+
 addq.l #1,d0
 dbra d1,.aux_seed
 lea sim_history_selftest(pc),a0
 adda.l #sim_camera_state-sim_history_selftest,a0
 move.l d7,(a0)+
 move.l d7,(a0)
 lea sim_history_slot(pc),a2
 adda.l #sim_history_test_rng-sim_history_slot,a2
 move.l d7,(a2)
 move.w d7,4(a2)
 lea sim_history_slot(pc),a1
 adda.l #sim_history_test_private-sim_history_slot,a1
 move.w d7,d0
 bsr sim_history_store
 addq.w #1,d7
 cmp.w #SIM_HISTORY_SLOTS,d7
 blo .seed
 moveq #SIM_HISTORY_SLOTS-1,d7
 moveq #0,d6
.check:
 lea sim_history_slot(pc),a1
 adda.l #sim_history_test_private-sim_history_slot,a1
 moveq #SIM_PRIVATE_BYTES/4-1,d0
.dirty:
 move.l #-1,(a1)+
 dbra d0,.dirty
 lea sim_results_state(pc),a0
 moveq #SIM_TIME_STATE_BYTES/4-1,d0
.dirty_times:
 move.l #-1,(a0)+
 dbra d0,.dirty_times
 lea sim_history_selftest(pc),a0
 adda.l #sim_aux_state-sim_history_selftest,a0
 moveq #SIM_AUX_BYTES/4-1,d0
.aux_dirty:
 move.l #-1,(a0)+
 dbra d0,.aux_dirty
 lea sim_history_selftest(pc),a0
 adda.l #sim_camera_state-sim_history_selftest,a0
 move.l #-1,(a0)+
 move.l #-1,(a0)
 lea sim_history_slot(pc),a2
 adda.l #sim_history_test_rng-sim_history_slot,a2
 move.l #-1,(a2)
 move.w #-1,4(a2)
 lea sim_history_slot(pc),a1
 adda.l #sim_history_test_private-sim_history_slot,a1
 move.w d7,d0
 bsr sim_history_load
 move.l d7,d2
 add.l d6,d2
 lea sim_history_slot(pc),a2
 adda.l #sim_history_test_rng-sim_history_slot,a2
 cmp.l (a2),d2
 bne sim_history_failed
 cmp.w 4(a2),d2
 bne sim_history_failed
 lea sim_history_slot(pc),a1
 adda.l #sim_history_test_private-sim_history_slot,a1
 moveq #SIM_PRIVATE_BYTES/4-1,d0
.verify:
 cmp.l (a1)+,d2
 bne sim_history_failed
 dbra d0,.verify
 lea sim_results_state(pc),a0
 move.l d2,d3
 lsl.l #3,d3
 moveq #SIM_TIME_STATE_BYTES/4-1,d0
.verify_times:
 cmp.l (a0)+,d3
 bne sim_history_failed
 addq.l #1,d3
 dbra d0,.verify_times
 lea sim_history_selftest(pc),a0
 adda.l #sim_aux_state-sim_history_selftest,a0
 move.l d2,d3
 lsl.l #8,d3
 moveq #SIM_AUX_BYTES/4-1,d0
.aux_verify:
 cmp.l (a0)+,d3
 bne sim_history_failed
 addq.l #1,d3
 dbra d0,.aux_verify
 lea sim_history_selftest(pc),a0
 adda.l #sim_camera_state-sim_history_selftest,a0
 cmp.l (a0)+,d2
 bne sim_history_failed
 cmp.l (a0),d2
 bne sim_history_failed
 lea sim_history_slot(pc),a0
 adda.l #sim_history_passed-sim_history_slot,a0
 addq.l #1,(a0)
 dbra d7,.check
 tst.w d6
 bne .reset
 bsr sim_history_shift
 lea sim_history_slot(pc),a0
 adda.l #sim_history_records-sim_history_slot,a0
 movea.l (a0),a0
 adda.l #19*SIM_HISTORY_BYTES,a0
 tst.w (a0)
 bne sim_history_failed
 moveq #1,d6
 moveq #SIM_HISTORY_SLOTS-2,d7
 bra .check
.reset:
 lea sim_results_state(pc),a0
 moveq #SIM_TIME_STATE_BYTES/4-1,d0
.clear_times:
 clr.l (a0)+
 dbra d0,.clear_times
 lea sim_history_selftest(pc),a0
 adda.l #sim_aux_state-sim_history_selftest,a0
 moveq #SIM_AUX_BYTES/4-1,d0
.aux_clear:
 clr.l (a0)+
 dbra d0,.aux_clear
 lea sim_history_selftest(pc),a0
 adda.l #sim_camera_state-sim_history_selftest,a0
 clr.l (a0)+
 clr.l (a0)
 bsr sim_history_reset
 lea sim_history_slot(pc),a0
 adda.l #sim_history_records-sim_history_slot,a0
 movea.l (a0),a0
 moveq #SIM_HISTORY_SLOTS-1,d0
.empty:
 tst.w (a0)
 bne sim_history_failed
 lea SIM_HISTORY_BYTES(a0),a0
 dbra d0,.empty
 lea sim_history_slot(pc),a0
 adda.l #sim_history_passed-sim_history_slot,a0
 addq.l #1,(a0)
 movem.l (sp)+,d0-a6
 rts

 ENDC
