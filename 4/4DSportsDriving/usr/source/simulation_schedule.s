; Field-owned live input capture and replay pacing. Live records are imported
; through the native history writer in the main task. Replay already owns its
; recorded input, so the interrupt only publishes a bounded target cursor.
; active=1 owns live mode 0; active=3 owns replay mode 2. Startup mode 1 keeps
; native scheduling. A mode change cannot reuse the previous clock epoch.
SIM_QUEUE_COUNT = 256
SIM_QUEUE_SIZE = 8

; Called by the VBL server with scratch registers saved, after counting field.
sim_schedule_field:
 lea sim_schedule_active(pc),a0
 tst.w (a0)
 beq .done
 lea sim_schedule_modal(pc),a0
 tst.w (a0)
 bne .modal_paused
 move.l sim_schedule_a4(pc),a4
 cmp.b #2,$45(a4)
 beq .replay
 tst.b $45(a4)
 bne .paused
 move.w sim_schedule_active(pc),d0
 cmp.w #1,d0
 bne .paused
 tst.b $42(a4)
 bne .paused
 tst.b $a9a(a4)
 bne .paused
 tst.w $a9c(a4)
 bne .paused
 move.w -$948(a4),d0
 cmp.w -$946(a4),d0
 bge .paused             ; native event deadline; CIA retains sound handling
 lea sim_schedule_phase(pc),a0
 move.w sim_schedule_rate(pc),d0
 add.w d0,(a0)
 move.w sim_time_field_hz(pc),d0
 cmp.w (a0),d0
 bhi .done
 sub.w d0,(a0)
 lea sim_schedule_write(pc),a2
 move.w (a2),d0
 sub.w sim_schedule_read(pc),d0
 cmp.w #SIM_QUEUE_COUNT,d0
 bhs .overflow
 moveq #0,d3              ; analogue steering demand
 moveq #0,d4              ; analogue-present flag
 tst.b -$68a(a4)
 bne .zero
 tst.b -$7710(a4)
 bne .mouse
 jsr -$799e(a4)           ; pure held-key / joystick hardware reader
 move.w d0,d5
 bra .gears
.mouse:
 moveq #1,d4
 move.w $2102(a4),d0      ; native mouse x, as read by $2A6DE
 sub.w #160,d0
 asr.w #1,d0
 ext.w d0                ; native conversion truncates to signed byte
 tst.b d0
 beq .steer_ready
 bmi .negative
 and.w #$ff,d0
 lea -$7514(a4),a0
 move.b (a0,d0.w),d0
 bra .steer_ready
.negative:
 ext.w d0
 neg.w d0
 lea -$7514(a4),a0
 move.b (a0,d0.w),d0
 neg.b d0
.steer_ready:
 move.b d0,d3
 moveq #0,d5
 btst #0,-$3360+1(a4)
 beq .mouse_throttle
 moveq #2,d5
 bra .gears
.mouse_throttle:
 btst #1,-$3360+1(a4)
 beq .gears
 moveq #1,d5
.gears:
 btst #5,d5
 beq .direct_gears
 btst #0,d5
 beq .gear_down
 bset #4,d5
.gear_down:
 btst #1,d5
 beq .direct_gears
 bset #5,d5
.direct_gears:
 tst.w $20c6(a4)
 beq .publish
 tst.b $2356+$20(a4)
 beq .direct_down
 bset #4,d5
.direct_down:
 tst.b $2356+$31(a4)
 beq .publish
 bset #5,d5
 bra .publish
.zero:
 moveq #0,d5
.publish:
 move.w (a2),d0
 and.w #SIM_QUEUE_COUNT-1,d0
 lsl.w #3,d0
 lea sim_schedule_queue(pc),a0
 adda.w d0,a0
 move.l sim_clock_fields(pc),(a0)+
 move.b d5,(a0)+
 move.b d3,(a0)+
 move.b d4,(a0)+
 clr.b (a0)
 addq.w #1,(a2)           ; payload precedes publication
 addq.w #1,$9c(a4)
 lea sim_schedule_ticks(pc),a0
 addq.l #1,(a0)
.done:
 rts
.replay:
 move.w sim_schedule_active(pc),d0
 cmp.w #3,d0
 bne .paused              ; wait for the main task to publish the new owner
 tst.b $42(a4)
 bne .paused
 tst.b $a9a(a4)
 bne .paused
 tst.w $a9c(a4)
 bne .paused
 tst.b $44(a4)
 bne .paused              ; native replay pause / seek gate
 ; Half speed adds rate/(2*field_hz), normal twice, double four times.
 ; Keeping a common denominator also preserves phase across speed changes.
 move.w sim_schedule_rate(pc),d0
 cmp.b #2,$3d(a4)
 beq .replay_phase
 add.w d0,d0
 cmp.b #3,$3d(a4)
 bne .replay_phase
 add.w d0,d0
.replay_phase:
 lea sim_schedule_phase(pc),a0
 add.w d0,(a0)
.replay_due:
 move.w sim_time_field_hz(pc),d0
 add.w d0,d0
 cmp.w (a0),d0
 bhi .done
 sub.w d0,(a0)
 move.w $a0(a4),d0
 cmp.w -$1738(a4),d0
 bhs .paused              ; bounded even at double speed with one input left
 addq.w #1,$a0(a4)        ; recorded bytes are immutable; publish target last
 addq.w #1,$9c(a4)
 lea sim_schedule_ticks(pc),a1
 addq.l #1,(a1)
 bra .replay_due          ; at most two complete steps per PAL field
.modal_paused:
 lea sim_schedule_modal_fields(pc),a0
 addq.l #1,(a0)
.paused:
 lea sim_schedule_phase(pc),a0
 clr.w (a0)
 rts
.overflow:
 lea sim_schedule_overflow(pc),a0
 move.w #1,(a0)
 rts

; $70E0: move.w $A0(a4),d0; cmp.w -$940(a4),d0.
sim_schedule_poll:
 movem.l d0-d7/a0-a6,-(sp)
 moveq #0,d0
 addx.b d0,d0
 move.w d0,-(sp)
 lea sim_schedule_poll(pc),a0
 adda.l #sim_ready-sim_schedule_poll,a0
 move.l (a0),d0
 beq .return
 moveq #0,d7
 move.b $45(a4),d7
 beq .supported
 cmp.w #2,d7
 bne .deactivate
.supported:
 ; Native COP1LC publication clears this flag; the VBL handler sets it.
 ; Keep A4000 from reusing the old display buffer before the list switch.
 ; Wait before importing pending physics so the next render uses fresh input.
 cmp.w #50,-$15fa(a4)
 bne .display_ready
.wait_display:
 tst.w $d28(a4)
 beq .wait_display
.display_ready:
 addq.w #1,d7             ; requested owner: live=1, replay=3
 tst.b -$3ff4(a4)
 bne .return              ; an outer native dialog still owns input
 bsr sim_schedule_resume_modal
 lea sim_schedule_active(pc),a0
 cmp.w (a0),d7
 beq .drain
 clr.w (a0)              ; close old owner before clearing its epoch
 ; Startup can leave recorded length ahead of its reset producer cursor.
 ; A held start key skips the native idle-frame clear at $7138. Live input
 ; overwrites from the producer, so discard that stale tail before recording.
 ; Loaded replay and native Normal/A2500 retain their existing length.
 cmp.w #1,d7
 bne .history_ready
 cmp.w #50,-$15fa(a4)
 bne .history_ready
 move.w $a0(a4),-$1738(a4)
.history_ready:
 lea sim_schedule_a4(pc),a0
 move.l a4,(a0)
 lea sim_schedule_rate(pc),a0
 move.w -$15fa(a4),(a0)
 lea sim_schedule_phase(pc),a0
 clr.w (a0)
 lea sim_schedule_read(pc),a0
 clr.w (a0)
 lea sim_schedule_write(pc),a0
 clr.w (a0)
 lea sim_schedule_active(pc),a0
 move.w d7,(a0)           ; publish initialized state last
.drain:
 cmp.w #3,d7
 beq .replay_end
 tst.b $42(a4)
 bne .return
 tst.b $a9a(a4)
 bne .return
 move.w sim_schedule_overflow(pc),d0
 beq .capacity_ok
 lea perf_failure(pc),a0
 move.l #12,(a0)
 IFD VERIFY
 illegal                  ; diagnostic trap; unread input is retained
 ELSE
 bra sim_schedule_overflow_exit
 ENDC
.capacity_ok:
 move.w $a0(a4),d0
 cmp.w -$940(a4),d0
 bne .return              ; consume older native history first
 move.w sim_schedule_read(pc),d0
 cmp.w sim_schedule_write(pc),d0
 beq .return
 and.w #SIM_QUEUE_COUNT-1,d0
 lsl.w #3,d0
 lea sim_schedule_queue(pc),a0
 adda.w d0,a0
 lea sim_schedule_current(pc),a1
 move.l (a0)+,(a1)+
 move.l (a0),(a1)
 move.w $a0(a4),d6
 lea sim_schedule_enqueuing(pc),a0
 move.w #1,(a0)
 move.w #1,-(sp)          ; native synthetic-input route bypasses live sampling
 lea sim_schedule_poll(pc),a0
 adda.l #sim_game-sim_schedule_poll,a0
 move.l (a0),a0
 adda.l #$7a66,a0
 jsr (a0)
 addq.l #2,sp
 lea sim_schedule_enqueuing(pc),a0
 clr.w (a0)
 cmp.w $a0(a4),d6
 beq .return             ; native history-full prompt: retain the input
 move.b sim_schedule_current+6(pc),d0
 beq .consumed
 ; At most one pending native step: the 64-slot steering ring cannot wrap.
 move.w $a0(a4),d0
 subq.w #1,d0
 and.w #63,d0
 lea $ab0(a4),a0
 move.b sim_schedule_current+5(pc),(a0,d0.w)
 lea $af0(a4),a0
 move.b #1,(a0,d0.w)
.consumed:
 lea sim_schedule_read(pc),a0
 addq.w #1,(a0)
 bra .return
.replay_end:
 ; Native $7A66 handles the audio/paused/end flags. Invoke it only after all
 ; published replay steps have completed; no OS or sound calls from the IRQ.
 tst.b $42(a4)
 bne .return
 tst.b $44(a4)
 bne .return
 tst.b $a9a(a4)
 bne .return
 tst.w $a9c(a4)
 bne .return
 move.w $a0(a4),d0
 cmp.w -$940(a4),d0
 bne .return
 cmp.w -$1738(a4),d0
 blo .return
 clr.w -(sp)
 lea sim_schedule_poll(pc),a0
 adda.l #sim_game-sim_schedule_poll,a0
 move.l (a0),a0
 adda.l #$7a66,a0
 jsr (a0)
 addq.l #2,sp
 bra .return
.deactivate:
 lea sim_schedule_active(pc),a0
 clr.w (a0)
 lea sim_schedule_modal(pc),a0
 clr.w (a0)
.return:
 move.w (sp)+,d0
 lsr.b #1,d0
 movem.l (sp)+,d0-d7/a0-a6
 move.w $a0(a4),d0
 cmp.w -$940(a4),d0
 rts

; $7A04: displaced decrement and BNE $7A5E. Keep the CIA sound service,
; pause/end checks and callback cleanup; skip only its simulation production.
sim_schedule_timer:
 move.l a0,-(sp)
 lea sim_schedule_active(pc),a0
 tst.w (a0)
 move.l (sp)+,a0
 bne .skip
 subq.b #1,$43(a4)
 beq .done
.skip:
 add.l #$54,(sp)          ; return $7A0A -> $7A5E
.done:
 rts

 IFND VERIFY
; A full queue cannot preserve further real-time input. End the run explicitly
; rather than overwrite unread records, silently drop time, or raise a Guru.
; Main-task path only: detach the field server before leaving KickEmu.
sim_schedule_overflow_exit:
 bsr sim_clock_remove
 pea sim_schedule_overflow_message(pc)
 pea TDREASON_FAILMSG
 move.l _resload(pc),a0
 jmp resload_Abort(a0)
sim_schedule_overflow_message:
 dc.b "Simulation input queue full.",10
 dc.b "The computer could not keep up with this simulation rate.",10
 dc.b "Try lower graphics detail or select Normal/A2500 for the next race.",0
 even
 ENDC

; $7C0A: original session-limit arithmetic, with captured input substitution.
sim_schedule_input:
 move.l a0,-(sp)
 lea sim_schedule_enqueuing(pc),a0
 tst.w (a0)
 beq .original
 move.b sim_schedule_current+4(pc),-1(a5)
.original:
 move.l (sp)+,a0
 move.w -$15fa(a4),d0
 muls #1500,d0
 rts

 even
 dc.b "4DSCHED!"
 dc.w 2,SIM_QUEUE_COUNT
sim_schedule_active: dc.w 0
sim_schedule_phase: dc.w 0
sim_schedule_rate: dc.w 0
sim_schedule_read: dc.w 0
sim_schedule_write: dc.w 0
sim_schedule_overflow: dc.w 0
sim_schedule_enqueuing: dc.w 0
sim_schedule_a4: dc.l 0
sim_schedule_ticks: dc.l 0
sim_schedule_current: dcb.b SIM_QUEUE_SIZE,0
sim_schedule_queue: dcb.b SIM_QUEUE_COUNT*SIM_QUEUE_SIZE,0

; Native $7904 initializes input history from startup and full $E06A race
; initialization. Hook its first assignment at $7908. Close the producer FIRST:
; an interrupt before this store completes before reset; one after it returns
; without touching A4 or the queue. No interrupt masking spans buffer clearing.
; The next live/replay main-task poll republishes a fresh pointer/rate epoch.
sim_schedule_reset_history:
 movem.l d0-d1/a0,-(sp)
 moveq #0,d0
 addx.w d0,d0
 move.w d0,-(sp)
 lea sim_schedule_active(pc),a0
 clr.w (a0)
 clr.w sim_schedule_phase-sim_schedule_active(a0)
 clr.w sim_schedule_rate-sim_schedule_active(a0)
 clr.w sim_schedule_read-sim_schedule_active(a0)
 clr.w sim_schedule_write-sim_schedule_active(a0)
 clr.w sim_schedule_overflow-sim_schedule_active(a0)
 clr.w sim_schedule_enqueuing-sim_schedule_active(a0)
 clr.l sim_schedule_a4-sim_schedule_active(a0)
 lea sim_schedule_modal(pc),a0
 clr.w (a0)
 IFD SIM_A4000
 lea sim_schedule_reset_history(pc),a0
 adda.l #sim_sound_reset-sim_schedule_reset_history,a0
 jsr (a0)
 lea sim_a4000_private(pc),a0
 moveq #SIM_PRIVATE_BYTES/4-1,d0
.private:
 clr.l (a0)+
 dbra d0,.private
 lea sim_schedule_reset_history(pc),a0
 adda.l #sim_aux_state-sim_schedule_reset_history,a0
 moveq #SIM_AUX_BYTES/4-1,d0
.auxiliary:
 clr.l (a0)+
 dbra d0,.auxiliary
 lea sim_schedule_reset_history(pc),a0
 adda.l #sim_camera_state-sim_schedule_reset_history,a0
 clr.l (a0)+
 clr.l (a0)
 ENDC
 IFD SIM_FIXTURE
 ; A restarted test race must arm/capture from its new tick zero as well.
 lea sim_schedule_reset_history(pc),a0
 adda.l #sim_fixture_active-sim_schedule_reset_history,a0
 clr.w (a0)
 clr.w 2(a0)
 ENDC
 lea sim_schedule_resets(pc),a0
 addq.l #1,(a0)
 move.w (sp)+,d0
 lsr.w #1,d0
 movem.l (sp)+,d0-d1/a0
 move.b #1,$43(a4)          ; exact native assignment and flags, X preserved
 rts

 even
 dc.b "4DSCHEDL"
 dc.w 1,0
sim_schedule_resets: dc.l 0
 IFNE SIM_STARTUP_TESTS
 dc.b "4DSCHTST"
 dc.w 1,2
sim_schedule_reset_passed: dc.l 0
sim_schedule_test_native: dcb.b $46,0

; Dirty running and wrapped queue states, both incoming X values. Exercise
; the actual hook, then a field interrupt after closure with the pointer zero.
sim_schedule_reset_selftest:
 movem.l d0-a6,-(sp)
 moveq #0,d7
.case:
 lea sim_schedule_active(pc),a0
 move.w #1,(a0)
 move.w #49,sim_schedule_phase-sim_schedule_active(a0)
 move.w #50,sim_schedule_rate-sim_schedule_active(a0)
 move.w #$fffe,sim_schedule_read-sim_schedule_active(a0)
 move.w #3,sim_schedule_write-sim_schedule_active(a0)
 move.w #1,sim_schedule_overflow-sim_schedule_active(a0)
 move.w #1,sim_schedule_enqueuing-sim_schedule_active(a0)
 move.l #$12345678,sim_schedule_a4-sim_schedule_active(a0)
 IFD SIM_A4000
 lea sim_a4000_private(pc),a0
 moveq #SIM_PRIVATE_BYTES/4-1,d0
.dirty:
 move.l #-1,(a0)+
 dbra d0,.dirty
 lea sim_schedule_reset_history(pc),a0
 adda.l #sim_aux_state-sim_schedule_reset_history,a0
 moveq #SIM_AUX_BYTES/4-1,d0
.dirty_auxiliary:
 move.l #-1,(a0)+
 dbra d0,.dirty_auxiliary
 lea sim_schedule_reset_selftest(pc),a0
 adda.l #sim_camera_state-sim_schedule_reset_selftest,a0
 move.l #-1,(a0)+
 move.l #-1,(a0)
 ENDC
 lea sim_schedule_test_native(pc),a4
 move.w d7,d0
 lsr.w #1,d0
 move.l #$12345678,d0
 move.l #$76543210,d1
 move.l a4,a0
 bsr sim_schedule_reset_history
 smi d2
 seq d3
 svs d4
 scs d5
 moveq #0,d6
 addx.w d6,d6
 cmp.w d7,d6
 bne .failed
 cmp.l #$12345678,d0
 bne .failed
 cmp.l #$76543210,d1
 bne .failed
 cmpa.l a4,a0
 bne .failed
 or.b d3,d2
 or.b d4,d2
 or.b d5,d2
 bne .failed
 cmp.b #1,$43(a4)
 bne .failed
 bsr sim_schedule_field
 lea sim_schedule_active(pc),a0
 moveq #8,d0             ; seven words and one long pointer
.zero:
 tst.w (a0)+
 bne .failed
 dbra d0,.zero
 IFD SIM_A4000
 lea sim_a4000_private(pc),a0
 moveq #SIM_PRIVATE_BYTES/4-1,d0
.private_zero:
 tst.l (a0)+
 bne .failed
 dbra d0,.private_zero
 lea sim_schedule_reset_history(pc),a0
 adda.l #sim_aux_state-sim_schedule_reset_history,a0
 moveq #SIM_AUX_BYTES/4-1,d0
.auxiliary_zero:
 tst.l (a0)+
 bne .failed
 dbra d0,.auxiliary_zero
 lea sim_schedule_reset_selftest(pc),a0
 adda.l #sim_camera_state-sim_schedule_reset_selftest,a0
 tst.l (a0)+
 bne .failed
 tst.l (a0)
 bne .failed
 ENDC
 lea sim_schedule_reset_passed(pc),a0
 addq.l #1,(a0)
 addq.w #1,d7
 cmp.w #2,d7
 blt .case
 lea sim_schedule_resets(pc),a0
 clr.l (a0)
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #14,(a0)
 illegal
 bra.s .failed

 ENDC

; Common native nested-dialog entry, after its LINK. Closing this gate keeps
; CIA production suppressed (active remains set) while VBL capture is paused.
; Native modal depth is incremented later by the original routine.
sim_schedule_modal_enter:
 movem.l d0-d1/a0,-(sp)
 moveq #0,d0
 addx.w d0,d0
 move.w d0,-(sp)
 bsr sim_schedule_pause_modal
 move.w (sp)+,d0
 lsr.w #1,d0
 movem.l (sp)+,d0-d1/a0
 move.b -$3ff4(a4),d0
 ext.w d0
 rts

sim_schedule_pause_modal:
 lea sim_schedule_active(pc),a0
 tst.w (a0)
 beq.s .done
 cmp.b #1,$45(a4)
 beq.s .done
 lea sim_schedule_modal(pc),a0
 move.w #1,(a0)            ; closes producer before any diagnostic reads
 lea sim_schedule_modal_enters(pc),a0
 addq.l #1,(a0)
.done:
 rts

; Only the main poll, after native modal depth reaches zero, may reopen this
; gate. Finish an already imported native input normally; discard just the
; private queue. A modal called inside the importer leaves its cursor alone
; until that importer returns and consumes its own record exactly once.
sim_schedule_resume_modal:
 lea sim_schedule_modal(pc),a0
 tst.w (a0)
 beq.s .done
 moveq #0,d0
 move.w sim_schedule_write(pc),d0
 sub.w sim_schedule_read(pc),d0
 lea sim_schedule_modal_dropped(pc),a0
 add.l d0,(a0)
 lea sim_schedule_read(pc),a0
 move.w sim_schedule_write(pc),(a0)
 lea sim_schedule_phase(pc),a0
 clr.w (a0)
 lea sim_schedule_modal_resumes(pc),a0
 addq.l #1,(a0)
 lea sim_schedule_modal(pc),a0
 clr.w (a0)               ; publication last: later fields begin fresh phase
.done:
 rts

 even
 dc.b "4DSCHMOD"
 dc.w 1
sim_schedule_modal: dc.w 0
sim_schedule_modal_enters: dc.l 0
sim_schedule_modal_resumes: dc.l 0
sim_schedule_modal_dropped: dc.l 0
sim_schedule_modal_fields: dc.l 0

 even
 IFNE SIM_STARTUP_TESTS
 dc.b "4DSCHMT!"
 dc.w 1,4
sim_schedule_modal_passed: dc.l 0
; Exercise nested entry, no capture while paused, wrapped queued input, and
; preservation of an input already accepted by the native importer. Inactive
; entries must not claim clock ownership; active replay pauses as well.
sim_schedule_modal_selftest:
 movem.l d0-a6,-(sp)
 lea sim_schedule_test_native(pc),a4
 moveq #0,d7
.case:
 lea sim_schedule_active(pc),a0
 move.w d7,d0
 and.w #1,d0
 move.w d0,(a0)
 move.w #49,sim_schedule_phase-sim_schedule_active(a0)
 move.w #$fffe,sim_schedule_read-sim_schedule_active(a0)
 move.w #3,sim_schedule_write-sim_schedule_active(a0)
 move.w #1,sim_schedule_enqueuing-sim_schedule_active(a0)
 move.l #$12345678,sim_schedule_a4-sim_schedule_active(a0)
 move.w d7,d0
 and.w #2,d0
 move.b d0,$45(a4)
 lea sim_schedule_modal(pc),a0
 clr.w (a0)
 clr.l sim_schedule_modal_enters-sim_schedule_modal(a0)
 clr.l sim_schedule_modal_resumes-sim_schedule_modal(a0)
 clr.l sim_schedule_modal_dropped-sim_schedule_modal(a0)
 clr.l sim_schedule_modal_fields-sim_schedule_modal(a0)
 bsr sim_schedule_pause_modal
 bsr sim_schedule_pause_modal
 lea sim_schedule_read(pc),a0
 cmp.w #$fffe,(a0)
 bne .failed
 cmp.w #3,sim_schedule_write-sim_schedule_read(a0)
 bne .failed
 cmp.w #1,sim_schedule_enqueuing-sim_schedule_read(a0)
 bne .failed
 btst #0,d7              ; both active live and replay owners pause
 beq .unclaimed
 cmp.w #1,sim_schedule_modal-sim_schedule_read(a0)
 bne .failed
 cmp.l #2,sim_schedule_modal_enters-sim_schedule_read(a0)
 bne .failed
 bsr sim_schedule_field
 bsr sim_schedule_field
 bsr sim_schedule_field
 lea sim_schedule_modal_fields(pc),a0
 cmp.l #3,(a0)
 bne .failed
 lea sim_schedule_ticks(pc),a0
 tst.l (a0)
 bne .failed
 ; Complete one in-flight import before the next main poll resumes capture.
 lea sim_schedule_read(pc),a0
 addq.w #1,(a0)
 clr.w sim_schedule_enqueuing-sim_schedule_read(a0)
 bsr sim_schedule_resume_modal
 bsr sim_schedule_resume_modal ; reopening is idempotent
 lea sim_schedule_read(pc),a0
 cmp.w #3,(a0)
 bne .failed
 tst.w sim_schedule_phase-sim_schedule_read(a0)
 bne .failed
 tst.w sim_schedule_modal-sim_schedule_read(a0)
 bne .failed
 cmp.l #1,sim_schedule_modal_resumes-sim_schedule_read(a0)
 bne .failed
 cmp.l #4,sim_schedule_modal_dropped-sim_schedule_read(a0)
 bne .failed
 bra.s .passed
.unclaimed:
 tst.w sim_schedule_modal-sim_schedule_read(a0)
 bne .failed
 tst.l sim_schedule_modal_enters-sim_schedule_read(a0)
 bne .failed
 cmp.w #49,sim_schedule_phase-sim_schedule_read(a0)
 bne .failed
.passed:
 lea sim_schedule_modal_passed(pc),a0
 addq.l #1,(a0)
 addq.w #1,d7
 cmp.w #4,d7
 blt .case
 bsr sim_schedule_reset_history
 lea sim_schedule_resets(pc),a0
 clr.l (a0)
 lea sim_schedule_modal_enters(pc),a0
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #15,(a0)
 illegal
 bra.s .failed


; Exercise the actual interrupt producer, not a host-side copy of its maths.
; Scratch A4 includes every native field read by the replay branch.
sim_schedule_replay_selftest:
 movem.l d0-a6,-(sp)
 lea sim_schedule_replay_selftest(pc),a4
 adda.l #sim_schedule_replay_native-sim_schedule_replay_selftest,a4
 lea sim_schedule_active(pc),a0
 move.w #3,(a0)
 move.l a4,sim_schedule_a4-sim_schedule_active(a0)
 move.b #2,$45(a4)
 move.w #30000,-$1738(a4)
 moveq #0,d6
.rate:
 lea sim_schedule_replay_rates(pc),a0
 move.w (a0,d6.w),d5
 lea sim_schedule_rate(pc),a0
 move.w d5,(a0)
 moveq #0,d4
.speed:
 move.b d4,$3d(a4)
 lea sim_schedule_phase(pc),a0
 clr.w (a0)
 clr.w $a0(a4)
 clr.w $9c(a4)
 lea sim_schedule_ticks(pc),a0
 clr.l (a0)
 move.w #249,d7
.fields:
 bsr sim_schedule_field
 dbra d7,.fields
 move.w d5,d3
 mulu #5,d3
 cmp.w #2,d4
 bne .not_half
 lsr.w #1,d3
.not_half:
 cmp.w #3,d4
 bne .expected
 add.w d3,d3
.expected:
 cmp.w $a0(a4),d3
 bne .failed
 cmp.w $9c(a4),d3
 bne .failed
 cmp.l sim_schedule_ticks(pc),d3
 bne .failed
 move.w sim_schedule_phase(pc),d0
 tst.w d0
 bne .failed
 bsr .passed
 addq.w #1,d4
 cmp.w #4,d4
 blo .speed
 addq.w #2,d6
 cmp.w #6,d6
 blo .rate
 ; Double-speed tail with one remaining input never publishes count+1.
 move.w #29999,$a0(a4)
 bsr sim_schedule_field
 cmp.w #30000,$a0(a4)
 bne .failed
 bsr sim_schedule_field
 cmp.w #30000,$a0(a4)
 bne .failed
 bsr .passed
 ; A speed change keeps the fractional field already accumulated.
 clr.w $a0(a4)
 move.b #2,$3d(a4)
 bsr sim_schedule_field   ; half: 0 steps, phase50
 move.b #3,$3d(a4)
 bsr sim_schedule_field   ; double: 2 steps, phase50
 clr.b $3d(a4)
 bsr sim_schedule_field   ; normal: 1 step, phase50
 cmp.w #3,$a0(a4)
 bne .failed
 move.w sim_schedule_phase(pc),d0
 cmp.w #50,d0
 bne .failed
 bsr .passed
 ; Each native pause gate drops elapsed phase, with no target publication.
 moveq #0,d6
.pause_case:
 move.b #2,$3d(a4)
 clr.w $a0(a4)
 lea sim_schedule_phase(pc),a0
 move.w #99,(a0)
 lea sim_schedule_replay_gates(pc),a0
 move.w (a0,d6.w),d0
 st (a4,d0.w)
 bsr sim_schedule_field
 tst.w $a0(a4)
 bne .failed
 move.w sim_schedule_phase(pc),d0
 tst.w d0
 bne .failed
 lea sim_schedule_replay_gates(pc),a0
 move.w (a0,d6.w),d0
 clr.b (a4,d0.w)
 bsr sim_schedule_field
 tst.w $a0(a4)           ; fresh half-speed phase; no resume burst
 bne .failed
 bsr sim_schedule_field
 cmp.w #1,$a0(a4)
 bne .failed
 bsr .passed
 addq.w #2,d6
 cmp.w #8,d6
 blo .pause_case
 ; A mode transition must wait for main-task ownership publication.
 clr.w $a0(a4)
 lea sim_schedule_active(pc),a0
 move.w #1,(a0)
 bsr sim_schedule_field
 tst.w $a0(a4)
 bne .failed
 bsr .passed
 bsr sim_schedule_reset_history
 lea sim_schedule_resets(pc),a0
 clr.l (a0)
 lea sim_schedule_ticks(pc),a0
 clr.l (a0)
 movem.l (sp)+,d0-a6
 rts
.passed:
 lea sim_schedule_replay_passed(pc),a0
 addq.l #1,(a0)
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #60,(a0)
 illegal
 bra .failed
sim_schedule_replay_rates: dc.w 10,20,50
sim_schedule_replay_gates: dc.w $42,$44,$a9a,$a9c
 even
 dc.b "4DRPLCLK"
 dc.w 2,19
sim_schedule_replay_passed: dc.l 0

 ENDC
