; VERIFY-only W6 keyboard producer observation. CUSTOM5 bit 20.
; Observe native key transitions at their acquisition point, not at render polls.
; VERIFY_RANGE sim:308b6 6: whole relocated LEA before the native bitmap store.
; This observer leaves both the native bitmap and native command FIFO untouched.
time_input_observe_install:
	movem.l d0-a6,-(sp)
	bsr time_input_option_observe
	bne .selected
	bsr time_input_option_timing
	beq .done
.selected
	move.l tape_game_steps(pc),d0
	cmpi.l #1,d0
	bne .done
	move.l tape_marker+24(pc),a1
	move.l a1,a3
	adda.l #$308b6,a3
	cmpi.w #$41f9,(a3)
	bne .bad
	move.l a1,d0
	addi.l #$30f8c,d0
	cmp.l 2(a3),d0
	bne .bad
	lea time_input_observe_state(pc),a0
	move.l a1,(a0)+
	move.l d0,(a0)+
	lea .queue_base(pc),a3
.queue_base
	adda.l #time_input_observe_queue-.queue_base,a3
	move.l a3,(a0)
	clr.l (a3)+
	clr.l (a3)+
	clr.l (a3)+
	clr.l (a3)
	move.l time_input_observe_state(pc),a0
	adda.l #$30006,a0
	lea time_input_fixture_epoch(pc),a3
	move.l (a0),(a3)
	lea time_input_observe_patch(pc),a0
	move.l observe_resload(pc),a2
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	bsr time_keys_start
.done
	movem.l (sp)+,d0-a6
	rts
.bad
	lea .error_base(pc),a0
.error_base
	adda.l #perf_mismatch-.error_base,a0
	pea (a0)
	pea TDREASON_FAILMSG
	move.l observe_resload(pc),a2
	jmp resload_Abort(a2)
time_input_observe_patch:
	PL_START
	PL_PS $308b6,time_input_observe_irq
	PL_END

; Only the native supervisor keyboard IRQ calls this wrapper. Serialize against
; higher-priority producers before reading the CIA timestamp and publishing data.
; Restore SR exactly: the displaced LEA must preserve every incoming flag.
time_input_observe_irq:
	move.w sr,-(sp)
	ori.w #$0700,sr
	movem.l d0-d3/a1-a2,-(sp)
	lea -16(sp),sp
	bsr time_input_option_timing
	beq .capture
	move.w time_keys_ready(pc),d2
	beq .restore
.capture
	move.l time_input_observe_state(pc),a2
	adda.l #$30006,a2
	move.l (a2),d2
	move.w d0,4(sp)
	move.w time_keys_ready(pc),d3
	beq .stamp
	lea time_loop_state(pc),a2
	tst.l TIME_LOOP_ACTIVE(a2)
	beq .modal
	sub.l TIME_LOOP_PAUSED(a2),d2
	bra .stamp
.modal
	move.l TIME_LOOP_PAUSE_START(a2),d2
	sub.l TIME_LOOP_PAUSE_BASE(a2),d2
	ori.w #$100,4(sp) ; held-only: menu commands must not replay into flight
.stamp
	addq.l #1,d2
	move.l d2,(sp)
	moveq #0,d2
	move.b d1,d2
	move.w d2,6(sp)
	clr.l 8(sp)
	clr.l 12(sp)
	move.l time_input_observe_state+8(pc),a0
	move.l sp,a1
	bsr time_input_push
.restore
	lea 16(sp),sp
	movem.l (sp)+,d0-d3/a1-a2
	move.l time_input_observe_state+4(pc),a0
	move.w (sp)+,sr
	rts
	CNOP 0,4
	dc.b "RBTINPUT"
time_input_observe_state:
	dc.l 0,0,0 ; sim, native keyboard bitmap, timestamp FIFO


; CUSTOM5 bit 21: four decoded keyboard transitions from supervisor VBlank.
; Bit 22 opens Preferences with F10 and closes it with Escape.
; CUSTOM4=$20000 selects Pause (P) instead, retaining the same recorded IRQ path.
; Exercise the installed native LEA hook and the unchanged bitmap/FIFO tail.
; This does not test the host keyboard mapping or CIA serial handshake.
time_input_fixture:
	bsr time_input_option_fixture
	beq .done
	movem.l d0-a6,-(sp)
	move.w sr,-(sp)
	ori.w #$0700,sr
	; The Pause fixture begins only after flight owns timestamped input.
	; A500 VERIFY installation can outlast the old fixed startup deadlines.
	bsr time_input_option_pause
	beq .epoch_ready
	lea time_input_pause_epoch_ready(pc),a3
	tst.w (a3)
	bne .epoch_ready
	move.w time_keys_ready(pc),d0
	beq .restore
	lea time_loop_state(pc),a2
	tst.l TIME_LOOP_ACTIVE(a2)
	beq .restore
	move.l time_loop_cia(pc),a0
	move.l (a0),d0
	lea time_input_fixture_epoch(pc),a1
	move.l d0,(a1)
	move.w #1,(a3)
.epoch_ready
	move.l time_input_observe_state(pc),a0
	move.l a0,d0
	beq .restore
	lea time_input_fixture_index(pc),a3
	moveq #0,d3
	move.w (a3),d3
	moveq #4,d4
	bsr time_input_option_modal
	beq .limit
	moveq #8,d4
.limit
	cmp.w d4,d3
	bhs .restore
	adda.l #$30006,a0
	move.l (a0),d2
	sub.l time_input_fixture_epoch(pc),d2
	bsr time_input_option_modal
	bne .modal_time
	move.w d3,d4
	mulu.w #3,d4
	bsr time_input_option_timing
	beq .short
	move.w d3,d4
	mulu.w #18,d4
.short
	addq.l #2,d4
	bra .deadline
.modal_time
	move.w d3,d4
	add.w d4,d4
	lea time_input_modal_deadlines(pc),a4
	move.w (a4,d4.w),d4
.deadline
	cmp.l d4,d2
	blo .restore
	moveq #$4e,d0
	cmpi.w #2,d3
	blo.b .key
	moveq #$40,d0
	cmpi.w #4,d3
	blo .key
	moveq #$59,d0
	bsr time_input_option_pause
	beq .modal_key
	moveq #$19,d0
.modal_key
	cmpi.w #6,d3
	blo .key
	moveq #$45,d0
.key
	moveq #1,d1
	move.w d3,d4
	andi.w #1,d4
	eor.w d4,d1
	; Keep independent acquisition evidence before calling the native hook.
	move.l d3,d4
	lsl.w #3,d4
	lea time_input_fixture_log(pc),a4
	adda.w d4,a4
	move.l (a0),(a4)+
	move.w d0,(a4)+
	move.w d1,(a4)
	; Retain the independently observed clock tuple at each acquisition.
	move.l d3,d4
	lsl.w #4,d4
	lea time_input_fixture_clocks(pc),a4
	adda.w d4,a4
	lea time_loop_state(pc),a2
	move.l TIME_LOOP_ACTIVE(a2),(a4)+
	move.l TIME_LOOP_PAUSED(a2),(a4)+
	move.l TIME_LOOP_PAUSE_START(a2),(a4)+
	move.l TIME_LOOP_PAUSE_BASE(a2),(a4)
	addq.w #1,(a3)
	move.l time_input_observe_state(pc),a1
	adda.l #$30f4c,a1 ; native key FIFO argument of decoded keyboard callback
	move.l time_input_observe_state(pc),a2
	adda.l #$308b6,a2
	jsr (a2)
.restore
	move.w (sp)+,sr
	movem.l (sp)+,d0-a6
.done
	rts
time_input_fixture_epoch: dc.l 0
time_input_fixture_index: dc.w 0
time_input_pause_epoch_ready: dc.w 0
	even
time_input_fixture_log: dcb.b 64,0
time_input_fixture_clocks: dcb.b 128,0
time_input_modal_deadlines: dc.w 2,20,38,56,74,76,300,302

time_input_option_pause:
	movem.l a0,-(sp)
	lea .base(pc),a0
.base
	adda.l #perf_custom4+1-.base,a0
	btst #1,(a0)
	move.l (sp)+,a0
	rts

; Long-range VERIFY option read, preserving registers and all flags except Z.
time_input_option_observe:
	movem.l a0,-(sp)
	lea .base(pc),a0
.base
	adda.l #perf_custom5+1-.base,a0
	btst #4,(a0)
	move.l (sp)+,a0
	rts

; Long-range VERIFY option read, preserving registers and all flags except Z.
time_input_option_fixture:
	movem.l a0,-(sp)
	lea .base(pc),a0
.base
	adda.l #perf_custom5+1-.base,a0
	btst #5,(a0)
	move.l (sp)+,a0
	rts

; Long-range VERIFY option read, preserving registers and all flags except Z.
time_input_option_modal:
	movem.l a0,-(sp)
	lea .base(pc),a0
.base
	adda.l #perf_custom5+1-.base,a0
	btst #6,(a0)
	move.l (sp)+,a0
	rts

; Long-range VERIFY option read, preserving registers and all flags except Z.
time_input_option_timing:
	movem.l a0,-(sp)
	lea .base(pc),a0
.base
	adda.l #perf_mask+2-.base,a0
	btst #5,(a0)
	move.l (sp)+,a0
	rts


; CUSTOM5 bit 31: deterministic scheduled-input fixture for render-schedule
; comparisons. These are synthetic queue records, NOT keyboard acquisitions.
; Seed once at world tick zero after native input ownership is ready. Deadlines
; are relative to the actual flight cursor, independent of setup/drawing time.
; Keep all physical acquisition fixtures (bits 21/22) separate from this mode.
time_input_replay_seed:
	movem.l d0/a0-a1,-(sp)
	lea .options_base(pc),a0
.options_base
	adda.l #perf_custom5-.options_base,a0
	btst #7,(a0)
	beq .done
	lea time_input_replay_done(pc),a1
	move.w (a1),d0
	bne .done ; one atomic state: 0 idle, 1 pending, 2 complete
	lea time_loop_state(pc),a0
	move.l TIME_LOOP_CURSOR(a0),d0
	sub.l TIME_LOOP_PAUSED(a0),d0
	move.l d0,2(a1)
	move.w #1,(a1) ; publish only after the complete origin
.done
	movem.l (sp)+,d0/a0-a1
	rts

; Called only from the supervisor VBlank observer, after native input seeding.
; Real producers cannot interleave the four synthetic future records.
time_input_replay_irq:
	movem.l d0-a6,-(sp)
	move.w sr,-(sp)
	ori.w #$0700,sr
	lea time_input_replay_done(pc),a4
	cmpi.w #1,(a4)
	bne .done
	lea .options_base(pc),a0
.options_base
	adda.l #perf_custom5-.options_base,a0
	btst #5,1(a0)
	bne .bad
	btst #6,1(a0)
	bne .bad
	move.w time_keys_ready(pc),d0
	beq .bad
	move.l 2(a4),d5
	lea time_loop_state(pc),a2
	move.l TIME_LOOP_CURSOR(a2),d0
	sub.l TIME_LOOP_PAUSED(a2),d0
	sub.l d5,d0
	cmpi.l #32,d0
	bhs .bad ; never install an event after its eligible world boundary
	move.l time_input_observe_state+8(pc),a0
	move.w (a0),d0
	cmp.w 2(a0),d0
	bne .bad
	lea time_input_replay_records(pc),a1
	moveq #0,d4
.next
	IFD VERIFY_WORLD_QUANTUM_TWIN
	addi.l #512,d5 ; sustain input across the deliberately expensive twins
	ELSE
	addi.l #32,d5
	ENDC
	move.l d5,(a1)
	move.w #$4e,4(a1)
	lea .view_options_base(pc),a3
.view_options_base
	adda.l #perf_custom5+3-.view_options_base,a3
	btst #4,(a3) ; combine the existing rear-view fixture with replay
	beq .first_key
	move.w #$51,4(a1)
.first_key
	cmpi.w #2,d4
	blo .key
	move.w #$40,4(a1)
.key
	move.w d4,d0
	andi.w #1,d0
	eori.w #1,d0
	move.w d0,6(a1)
	clr.l 8(a1)
	clr.l 12(a1)
	bsr time_input_push
	tst.l d0
	bne .bad
	adda.w #16,a1
	addq.w #1,d4
	cmpi.w #4,d4
	blo .next
	move.w #2,(a4)
.done
	move.w (sp)+,sr
	movem.l (sp)+,d0-a6
	rts
.bad
	pea .error(pc)
	pea TDREASON_FAILMSG
	move.l observe_resload(pc),a2
	jmp resload_Abort(a2)
.error: dc.b "Red Baron: invalid scheduled-input fixture setup",0
	even
time_input_replay_done: dc.w 0
time_input_replay_origin: dc.l 0
time_input_replay_records: dcb.l 16,0
