; VERIFY-only W6 experiment. CUSTOM4 forces the primary dt at each flight
; input checkpoint. Zero is observation-only. Secondary dt, menus and original
; clock arithmetic remain unchanged. Never use forced runs for FPS claims.
; CUSTOM4 bit 16 holds Right throughout a forced-dt physics run.
; Forced-dt fixtures require the timestamped W6 input owner to remain disabled.
; CUSTOM4=$40000 fixes both native dt words to 225 during the setup prelude
; only, then stops when W6 owns flight. Requires W6 plus deferred installation.
; CUSTOM4=$80000 selects private overlay invalidation/refill; no dt force.
; CUSTOM4=$20000 instead selects Pause in the W6 modal IRQ fixture; no dt force.
; a1 is h3; preserve every input register. No additional sim-code hook.
time_probe_step:
	IFD VERIFY_D5_SCENARIO
	bsr d5_scenario_prepare
	ENDC
	movem.l d0/a0,-(sp)
	; CUSTOM5 bit 18: one synthetic low-altitude descent at first flight.
	; Deliberately changes initial conditions; never a normal mission sample.
	move.l tape_game_steps(pc),d0
	cmp.l #1,d0
	bne.b .clock
	lea .custom5_2(pc),a0
.custom5_2
	adda.l #perf_custom5+1-.custom5_2,a0
	btst #2,(a0)
	beq.b .clock
	move.l $4578(a1),a0
	move.l #512,16(a0)
	move.w #-1024,$f8(a0)
	move.w #-1024,$fe(a0)
	move.w #-220,$ce(a0)
	move.w #-220,$d4(a0)
	clr.w $104(a0)
.clock
	lea .custom4_base(pc),a0
.custom4_base
	adda.l #perf_custom4-.custom4_base,a0
	move.l (a0),d0
	beq .done
	cmp.l #$80000,d0
	beq .done
	cmp.l #$40000,d0
	beq .done
	cmp.l #$20000,d0
	beq.b .modal_fixture
	cmp.l #$1ffff,d0
	bhi.b .bad
	andi.l #$ffff,d0
	cmp.l #100,d0
	beq.b .force
	cmp.l #225,d0
	beq.b .force
	cmp.l #450,d0
	beq.b .force
	cmp.l #900,d0
	beq.b .force
	cmp.l #2200,d0
	beq.b .force
.modal_fixture
	cmp.l #$20000,d0
	bne.b .bad
	bsr time_input_option_timing
	beq.b .bad
	bsr time_input_option_fixture
	beq.b .bad
	bsr time_input_option_modal
	bne.b .done
.bad
	lea .mismatch_base(pc),a0
.mismatch_base
	adda.l #perf_mismatch-.mismatch_base,a0
	pea (a0)
	pea TDREASON_FAILMSG
	move.l observe_resload(pc),a2
	jmp resload_Abort(a2)
.force
	move.w d0,$4834(a1)
	btst #0,1(a0) ; CUSTOM4 bit 16, big-endian ULONG
	beq .done
	move.w time_keys_ready(pc),d0
	bne.b .bad
	move.l tape_keybase(pc),a0
	move.b #1,$4e(a0)
.done
	; CUSTOM5 bit 19: hold the native fire key for projectile tests.
	lea .custom5_3(pc),a0
.custom5_3
	adda.l #perf_custom5+1-.custom5_3,a0
	btst #3,(a0)
	beq.b .return
	move.l tape_keybase(pc),a0
	move.b #1,$40(a0)
.return
	movem.l (sp)+,d0/a0
	rts

; Called only after tape_flight verifies the native flight caller. The prelude
; deliberately fixes both clocks, including the flight polls around Preferences.
; Once W6 is active its clocks/input remain exclusively scheduler-owned.
time_prelude_step:
	movem.l d0-d1/a0-a1,-(sp)
	lea .options(pc),a0
.options
	adda.l #perf_custom4-.options,a0
	cmpi.l #$40000,(a0)
	bne .done
	lea .mask(pc),a0
.mask
	adda.l #perf_mask-.mask,a0
	btst #5,2(a0) ; CUSTOM2 bit 13
	beq .bad
	lea .deferred(pc),a0
.deferred
	adda.l #perf_custom5-.deferred,a0
	btst #1,2(a0) ; CUSTOM5 bit 9
	beq .bad
	lea .state(pc),a0
.state
	adda.l #time_loop_state-.state,a0
	tst.l TIME_LOOP_ACTIVE(a0)
	bne .done
	move.l tape_marker+24(pc),a1
	moveq #2,d0
.hunk
	move.l -4(a1),d1
	lsl.l #2,d1
	addq.l #4,d1
	move.l d1,a1
	dbf d0,.hunk
	move.w #225,$4834(a1)
	move.w #225,$4836(a1)
	lea time_prelude_count(pc),a0
	addq.l #1,(a0)
.done
	movem.l (sp)+,d0-d1/a0-a1
	rts
.bad
	lea .error(pc),a0
.error
	adda.l #perf_mismatch-.error,a0
	pea (a0)
	pea TDREASON_FAILMSG
	move.l observe_resload(pc),a2
	jmp resload_Abort(a2)
time_prelude_count: dc.l 0

	IFD VERIFY_D5_SCENARIO
; Controlled starting conditions for native D5 outcome integration.
; No clock, health, damage or mission-result flag is fabricated.
; 1 = gentle ground approach; 2 = steep descent; 3 = isolated transit;
; 4 = live enemy lined up on the player forward axis for native gunfire.
; Optional VERIFY_D5_TRACK_TARGET keeps that firing geometry for at most 64
; world updates. It isolates damage/kill-credit integration, not AI evasion.
; This file is included only in VERIFY. Ordinary builds contain no fixture.
	IFND VERIFY_D5_DISTANCE_SHIFT
VERIFY_D5_DISTANCE_SHIFT = 4
	ENDC
d5_scenario_prepare:
	movem.l d0-d2/a0-a4,-(sp)
	lea .option(pc),a2
.option
	adda.l #perf_custom2+2-.option,a2
	btst #5,(a2) ; W6 requested, including deferred installation
	beq .done
	lea .loop(pc),a2
.loop
	adda.l #time_loop_state-.loop,a2
	tst.l TIME_LOOP_ACTIVE(a2)
	beq .done
	move.l TIME_LOOP_STEPS(a2),d0
	IFD VERIFY_D5_TRACK_TARGET
	cmpi.l #4,d0
	bcs .done
	cmpi.l #67,d0
	bhi .done
	ELSE
	cmpi.l #4,d0
	bne .done
	ENDC
	move.l $4578(a1),a0
	IFNE VERIFY_D5_SCENARIO-3
	IFNE VERIFY_D5_SCENARIO-4
	IFNE VERIFY_D5_SCENARIO-1
	move.l #512,16(a0)
	move.w #-1024,$f8(a0)
	move.w #-1024,$fe(a0)
	move.w #-220,$ce(a0)
	move.w #-220,$d4(a0)
	ELSE
	move.l #60,16(a0)
	clr.w 20(a0)
	clr.w 22(a0)
	clr.w $ce(a0)
	clr.w $d0(a0)
	clr.w $d4(a0)
	clr.w $d6(a0)
	clr.l $f4(a0)
	clr.l $f8(a0)
	clr.l $fc(a0)
	move.l $457c(a1),a2
	clr.w 6(a2)
	ENDC
	clr.w $104(a0)
	ENDC
	ENDC
	; Move other aircraft far away once. Native eligibility
	; still decides whether C is allowed; no compression/eligibility flag write.
	move.w $5578(a1),d0
	move.l $5584(a1),a2
	subq.w #1,d0
	bmi .done
.objects
	move.l a2,a3
	cmpa.l a0,a3
	beq .next
	IFEQ VERIFY_D5_SCENARIO-4
	move.l d5_scenario_target(pc),d1
	beq .choose
	IFD VERIFY_D5_TRACK_TARGET
	cmpa.l d1,a3
	bne .next
	move.l 34(a3),d1
	andi.l #$48,d1
	bne .done
	bra .lineup
	ELSE
	bra .relocate
	ENDC
.choose
	tst.b 38(a3)
	bne .relocate
	; Registry also contains camera objects with type zero. Require a live
	; enemy in the actual 318-byte aircraft pool, not a camera lookalike.
	move.l a3,d2
	sub.l $5584(a1),d2
	bcs .relocate
	move.w $5578(a1),d1
	mulu #318,d1
	cmp.l d1,d2
	bhs .relocate
	move.l 34(a3),d1
	andi.l #$48,d1
	bne .relocate
	move.l 34(a3),d1
	move.l 34(a0),d2
	eor.l d2,d1
	btst #10,d1
	beq .relocate
	lea d5_scenario_target(pc),a4
	move.l a3,(a4)
.lineup
	move.w $32(a0),d1
	asr.w #VERIFY_D5_DISTANCE_SHIFT,d1
	ext.l d1
	add.l 8(a0),d1
	move.l d1,8(a3)
	move.w $34(a0),d1
	asr.w #VERIFY_D5_DISTANCE_SHIFT,d1
	ext.l d1
	add.l 12(a0),d1
	move.l d1,12(a3)
	move.w $36(a0),d1
	asr.w #VERIFY_D5_DISTANCE_SHIFT,d1
	ext.l d1
	add.l 16(a0),d1
	move.l d1,16(a3)
	move.l 20(a0),20(a3)
	move.w 24(a0),24(a3)
	move.l $ce(a0),$ce(a3)
	move.l $d2(a0),$d2(a3)
	move.l $d6(a0),$d6(a3)
	move.l $f4(a0),$f4(a3)
	move.l $f8(a0),$f8(a3)
	move.l $fc(a0),$fc(a3)
	bra .next
.relocate
	ENDC
	addi.l #2000000,8(a3)
	addi.l #2000000,12(a3)
.next
	adda.w #318,a2
	dbf d0,.objects
.done
	movem.l (sp)+,d0-d2/a0-a4
	rts
d5_scenario_target: dc.l 0
	ENDC
