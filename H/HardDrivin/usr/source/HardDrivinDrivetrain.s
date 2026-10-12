; Experimental reference integrator, not a performance-accepted policy.
; Driving advances engine and projected position in fields.
; Manual/neutral support is separately gated by VERIFY_DRIVETRAIN_MANUAL.
; VERIFY_DRIVETRAIN_SKID retains native held-vector motion during skids.
; VERIFY_DRIVETRAIN_AIR extends this to falling and partial wheel contact.
; Gravity/contact remain once per outer pass, after restoring its interval.
; Steering, contact/scene work and input sampling remain once per outer pass.
; Zero/eight-field intervals and other driving modes keep the native pair.
_drivetrain_install:
	movem.l d0/a0-a2,-(a7)
	lea _drivetrain_engine(pc),a0
	move.l _code_start(pc),d0
	addi.l #$b662,d0
	move.l d0,(a0)+
	move.l _code_start(pc),d0
	addi.l #$b500,d0
	move.l d0,(a0)+
	move.l _code_start(pc),d0
	addi.l #$baea,d0
	move.l d0,(a0)
	lea _drivetrain_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	IFD VERIFY_DRIVETRAIN_PHASE
	bsr _phase_install
	ENDC
	movem.l (a7)+,d0/a0-a2
	rts
_drivetrain_patches:
	PL_START
	; PERF_RANGE VERIFY_DRIVETRAIN_REFERENCE $0cdb6 $0008: engine/position reference integration
	PL_PSS $cdb6,_drivetrain_frame,2
	; PERF_RANGE VERIFY_DRIVETRAIN_REFERENCE $0baca $0006: publish engine pitch once per outer pass
	PL_PS $baca,_drivetrain_audio
	IFD VERIFY_DRIVETRAIN_MANUAL
	; PERF_RANGE VERIFY_DRIVETRAIN_MANUAL $0b9ba $0006: consume manual gear input once per outer pass
	PL_PS $b9ba,_drivetrain_manual
	ENDC
	IFD VERIFY_DRIVETRAIN_POWER
	; PERF_RANGE VERIFY_DRIVETRAIN_POWER $0b696 $002a: reuse identical throttle/ratio power
	PL_PSS $b696,_drivetrain_power,$24
	ENDC
	IFD VERIFY_DRIVETRAIN_SQRT
	; PERF_RANGE VERIFY_DRIVETRAIN_SQRT $0b856 $0006: reuse identical engine root operands
	PL_PS $b856,_drivetrain_sqrt
	ENDC
	PL_END
_drivetrain_engine: dc.l 0
_drivetrain_position: dc.l 0
_drivetrain_audio_exit: dc.l 0
	dc.b 'HDDRIVE1'
; Original interval, remaining fields, held brake, active; engine calls, frames.
; Active1 integrates ticks; active2 publishes the already-integrated final pose.
_drivetrain_state: dc.w 0,0,0,0
	dc.l 0,0
	dc.b 'HDDTICK1'
_drivetrain_tick_offsets:
	dc.l _drivetrain_tick_before-_drivetrain_tick_offsets
	dc.l _drivetrain_tick_after-_drivetrain_tick_offsets

_drivetrain_frame:
	IFD VERIFY_DRIVETRAIN_PHASE
	bra _phase_frame
	ENDC
_drivetrain_reference_frame:
	movem.l d0/a0,-(a7)
	lea _drivetrain_state(pc),a0
	clr.w 6(a0)
	move.w _time_scalar_fields(pc),d0
	move.w d0,(a0)
	beq .single
	cmpi.w #8,d0
	beq .single
	move.b _dispatch_state+DS_ACTIVE(pc),d0
	beq .single
	tst.b -$69fa(a4)
	bne .single
	IFND VERIFY_DRIVETRAIN_SKID
	tst.b -$50cf(a4)
	bne .single
	ENDC
	IFND VERIFY_DRIVETRAIN_AIR
	cmpi.b #15,-$66f0(a4)
	bne .single
	tst.w -$66f2(a4)
	bne .single
	ENDC
	IFND VERIFY_DRIVETRAIN_MANUAL
	tst.b -$66c2(a4)
	beq .single
	cmpi.w #1,-$66ca(a4)
	ELSE
	tst.w -$66ca(a4)
	ENDC
	blt .single
	cmpi.w #4,-$66ca(a4)
	bgt .single
	move.w (a0),2(a0)
	moveq #0,d0
	move.b -$66ef(a4),d0
	move.w d0,4(a0)
	move.w #1,6(a0)
	addq.l #1,12(a0)
	lea _time_scalar_fields(pc),a0
	move.w #1,(a0)
	movem.l (a7)+,d0/a0
.loop:
	movem.l d0/a0,-(a7)
	lea _drivetrain_state(pc),a0
	move.w 4(a0),d0
	move.b d0,-$66ef(a4)
	addq.l #1,8(a0)
	movem.l (a7)+,d0/a0
	IFD VERIFY_DRIVETRAIN_SETTLED
	bsr _drivetrain_save_inputs
	ENDC
	bsr _drivetrain_engine_tick
	; Keep outputs and incoming X from the last native position call.
	movem.l d0/a0,-(a7)
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,-(a7)
	lea _drivetrain_state(pc),a0
	subq.w #1,2(a0)
	beq.s .finish
	IFD VERIFY_DRIVETRAIN_SETTLED
	bsr _drivetrain_skip_settled
	ENDC
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0/a0
	bra.s .loop
.finish:
	move.w (a0),d0
	move.w #2,6(a0)
	lea _time_scalar_fields(pc),a0
	move.w d0,(a0)
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0/a0
	pea .published(pc)
	move.l _drivetrain_position(pc),-(a7)
	rts
.published:
	move.l a0,-(a7)
	lea _drivetrain_state(pc),a0
	clr.w 6(a0)
	movea.l (a7)+,a0
	rts
.single:
	addq.l #1,8(a0)
	addq.l #1,12(a0)
	movem.l (a7)+,d0/a0
	; This common pair also exercises the original n=8 compatibility path.
_drivetrain_pair:
	pea .position(pc)
	move.l _drivetrain_engine(pc),-(a7)
	rts
.position:
	move.l _drivetrain_position(pc),-(a7)
	rts

; The engine does not consume word positions. Accumulate the exact fieldwise
; projected displacement here; run native word-pose/gravity/skid housekeeping
; once after the final tick, with the full original interval restored.
_drivetrain_engine_tick:
	pea _drivetrain_position_tick(pc)
	move.l _drivetrain_engine(pc),-(a7)
	rts
_drivetrain_position_tick:
	movem.l d0-d4/a0,-(a7)
	bsr _projection_snapshot
	lea _motion_position_state(pc),a0
	move.w -$66e2(a4),(a0)+
	move.w -$66e0(a4),(a0)+
	move.w -$66de(a4),(a0)
	IFD VERIFY_DRIVETRAIN_SKID
	; Native B500 retains the projected movement vector throughout a skid.
	tst.b -$50cf(a4)
	bne.s _drivetrain_tick_before
	ENDC
	move.w -$66d8(a4),d0
	bsr _projection_integer_components
	move.w d0,-$66e2(a4)
	move.w d1,-$66e0(a4)
	move.w d2,-$66de(a4)
_drivetrain_tick_before:
	IFD VERIFY_DRIVETRAIN_POSITION
	bsr _drivetrain_position_add
	ELSE
	bsr _motion_position_add
	ENDC
_drivetrain_tick_after:
	movem.l (a7)+,d0-d4/a0
	rts

_drivetrain_audio:
	move.l a0,-(a7)
	lea _drivetrain_state(pc),a0
	tst.w 6(a0)
	beq.s .native
	cmpi.w #1,2(a0)
	bhi.s .skip
.native:
	tst.b -$5224(a4)
	bne.s .done
.skip:
	move.l _drivetrain_audio_exit(pc),4(a7)
.done:
	movea.l (a7)+,a0
	rts

	IFD VERIFY_DRIVETRAIN_SETTLED
; After an unchanged one-field engine update, all its variable inputs are fixed.
; Terrain/trig/turn/skid are held by the outer pass. Keep the final engine call
; for native pitch publication; integrate only the intervening position ticks.
	dc.b 'HDFIXPT1'
_drivetrain_settled_state:
	dc.l 0,0                 ; skipped fields, successful bulk integrations
	dcb.b 28,0               ; scalar companions and native engine inputs
_drivetrain_save_inputs:
	movem.l d0-d3/a0-a1,-(a7)
	lea _drivetrain_state(pc),a0
	cmpi.w #3,2(a0)
	blo.s .done
	lea _time_scalar_state(pc),a0
	lea _drivetrain_settled_state+8(pc),a1
	movem.l (a0),d0-d3
	movem.l d0-d3,(a1)
	move.l -$66da(a4),16(a1) ; wheel speed and velocity
	move.l -$66d6(a4),20(a1) ; RPM and MPH
	move.w -$66ca(a4),24(a1) ; current gear (companion may describe prior gear)
	move.w -$66e4(a4),26(a1) ; throttle and gear-request byte
.done:
	movem.l (a7)+,d0-d3/a0-a1
	rts
_drivetrain_skip_settled:
	movem.l d0-d1/a0-a1,-(a7)
	lea _drivetrain_state(pc),a0
	cmpi.w #2,2(a0)
	blo .done
	lea _drivetrain_settled_state+8(pc),a1
	lea _time_scalar_state(pc),a0
	moveq #3,d1
.compare:
	move.l (a0)+,d0
	cmp.l (a1)+,d0
	IFD VERIFY_DRIVETRAIN_FRACTION
	bne .fraction
	ELSE
	bne .done
	ENDC
	dbf d1,.compare
	move.l -$66da(a4),d0
	cmp.l (a1)+,d0
	bne .done
	move.l -$66d6(a4),d0
	cmp.l (a1)+,d0
	bne .done
	move.w -$66ca(a4),d0
	cmp.w (a1)+,d0
	bne .done
	move.w -$66e4(a4),d0
	cmp.w (a1),d0
	bne .done
	lea _drivetrain_state(pc),a0
	moveq #0,d0
	move.w 2(a0),d0
	subq.w #1,d0
	move.w #1,2(a0)
	lea _drivetrain_settled_state(pc),a1
	add.l d0,(a1)
	addq.l #1,4(a1)
	lea _time_scalar_fields(pc),a1
	move.w d0,(a1)
	bsr _drivetrain_position_tick
	lea _time_scalar_fields(pc),a1
	move.w #1,(a1)
	IFD VERIFY_DRIVETRAIN_FRACTION
	bra.s .done
.fraction:
	bsr _drivetrain_skip_fraction
	ENDC
.done:
	movem.l (a7)+,d0-d1/a0-a1
	rts
	ENDC

	IFD VERIFY_DRIVETRAIN_FRACTION
; A constant native velocity word keeps the force and RPM target fixed. Batch
; fractional acceleration only if every other engine input/companion is fixed,
; and stop before changing that word or crossing the projection's carry sign.
	dc.b 'HDFRAC01'
_drivetrain_fraction_state:
	dc.l 0,0                 ; skipped engine fields, bulk position updates
	dc.w 0,0                 ; last rate, active bulk interval (zero outside helper)
_drivetrain_skip_fraction:
	movem.l d0-d4/a0-a1,-(a7)
	lea _time_scalar_state+2(pc),a0
	lea _drivetrain_settled_state+10(pc),a1
	moveq #6,d1
.compare:
	move.w (a0)+,d0
	cmp.w (a1)+,d0
	bne .done
	dbf d1,.compare
	move.l -$66da(a4),d0
	cmp.l (a1)+,d0
	bne .done
	move.l -$66d6(a4),d0
	cmp.l (a1)+,d0
	bne .done
	move.w -$66ca(a4),d0
	cmp.w (a1)+,d0
	bne .done
	move.w -$66e4(a4),d0
	cmp.w (a1),d0
	bne .done
	; Avoid near-zero dissipation limiting and the native projection wrap range.
	move.w -$66d8(a4),d0
	bpl.s .magnitude
	neg.w d0
.magnitude:
	cmpi.w #2,d0
	blt .done
	cmpi.w #21843,d0
	bgt .done
	lea _time_scalar_state(pc),a0
	move.w (a0),d0
	move.w d0,d1
	sub.w _drivetrain_settled_state+8(pc),d1
	beq .done
	move.w d1,d2
	bmi.s .negative
	moveq #7,d3
	tst.w d0
	bpl.s .positive_bound
	moveq #0,d3
.positive_bound:
	sub.w d0,d3
	bra.s .bound
.negative:
	neg.w d2
	moveq #7,d3
	tst.w d0
	ble.s .negative_bound
	moveq #0,d3
.negative_bound:
	add.w d0,d3
.bound:
	divu.w d2,d3
	andi.l #$ffff,d3
	beq .done
	lea _drivetrain_state(pc),a1
	moveq #0,d4
	move.w 2(a1),d4
	subq.w #1,d4
	cmp.w d4,d3
	bls.s .bounded
	move.w d4,d3
.bounded:
	tst.w d3
	beq.s .done
	sub.w d3,2(a1)
	move.w d1,d2
	muls.w d3,d2
	add.w d2,(a0)
	lea _drivetrain_fraction_state(pc),a1
	add.l d3,(a1)
	addq.l #1,4(a1)
	move.w d1,8(a1)
	move.w d3,10(a1)
	lea _time_scalar_fields(pc),a1
	move.w d3,(a1)
	bsr _drivetrain_position_tick
	lea _drivetrain_fraction_state(pc),a1
	clr.w 10(a1)
	lea _time_scalar_fields(pc),a1
	move.w #1,(a1)
.done:
	movem.l (a7)+,d0-d4/a0-a1
	rts
	ENDC

	IFD VERIFY_DRIVETRAIN_POSITION
; Combine integer and fractional Euler contributions before splitting once.
; Only the reference's one-field ticks use this; bulk/native steps retain the
; general helper. Guard projected words so the Q16 intermediate fits a long.
_drivetrain_position_add:
	movem.l d0-d7/a0-a3/a5,-(a7)
	move.w _time_scalar_fields(pc),d0
	cmpi.w #1,d0
	bne .fallback
	lea _motion_position_state(pc),a0
	lea -$66e2(a4),a1
	moveq #2,d7
.check:
	move.w (a0)+,d0
	addi.w #16383,d0
	cmpi.w #32766,d0
	bhi .fallback
	move.w (a1)+,d0
	addi.w #16383,d0
	cmpi.w #32766,d0
	bhi .fallback
	dbf d7,.check
	bsr _projection_update
	lea _motion_position_state(pc),a0
	lea _motion_position_state+8(pc),a5
	lea _projection_state(pc),a1
	lea -$66e2(a4),a2
	lea -$6704(a4),a3
	moveq #2,d7
.axis:
	move.w (a2)+,d0
	ext.l d0
	move.w (a0),d1
	ext.l d1
	move.l d0,d4
	add.l d1,d4
	sub.l d1,d0
	lsl.l #3,d0
	add.l d4,d0              ; 9*v - 7*u
	lsl.l #8,d0
	lsl.l #4,d0              ; integer projection contribution in Q16
	move.l d0,d6
	move.l (a1),d0
	move.l 12(a1),d1
	move.l d0,d4
	add.l d1,d4
	sub.l d1,d0
	lsl.l #3,d0
	add.l d4,d0
	asr.l #4,d0              ; floor((9*q - 7*previous_q)/16)
	add.l d6,d0
	move.l (a5),d1
	lsl.l #8,d1
	add.l d1,d1
	add.l d1,d0
	add.l 24(a1),d0
	bsr _time_split_q16
	add.l d0,(a3)+
	clr.l (a5)+
	move.l d2,24(a1)
	addq.l #2,a0
	addq.l #4,a1
	dbf d7,.axis
	movem.l (a7)+,d0-d7/a0-a3/a5
	rts
.fallback:
	movem.l (a7)+,d0-d7/a0-a3/a5
	bra _motion_position_add
	ENDC

	IFD VERIFY_DRIVETRAIN_SQRT
; The engine's native square-root routine is pure. Reuse only identical complete
; long operands during inner reference ticks. Native/full-step calls still run
; the original function. Its scratch outputs are dead at B85C except D0.
	dc.b 'HDSQRT01'
_drivetrain_sqrt_state:
	dc.l 0,0                 ; complete operand, native result
	dc.w 0,0                 ; valid, padding
	dc.l 0,0                 ; hits, misses
_drivetrain_sqrt:
	movem.l d1/a0,-(a7)
	move.w _drivetrain_state+6(pc),d1
	cmpi.w #1,d1
	bne.s .native
	lea _drivetrain_sqrt_state(pc),a0
	move.l 12(a7),d1
	tst.w 8(a0)
	beq.s .miss
	cmp.l (a0),d1
	bne.s .miss
	addq.l #1,12(a0)
	move.l 4(a0),d0
	bra.s .done
.miss:
	move.l d1,(a0)
	addq.l #1,16(a0)
	move.l d1,-(a7)
	jsr -$7e42(a4)
	addq.l #4,a7
	lea _drivetrain_sqrt_state(pc),a0
	move.l d0,4(a0)
	move.w #1,8(a0)
	bra.s .done
.native:
	move.l 12(a7),-(a7)
	jsr -$7e42(a4)
	addq.l #4,a7
.done:
	movem.l (a7)+,d1/a0
	; Displaced ADDQ removes the original long argument below our return PC.
	move.l (a7),4(a7)
	addq.l #4,a7
	rts
	ENDC

	IFD VERIFY_DRIVETRAIN_POWER
; Complete native inputs: signed throttle byte and both ratio words at A2.
; Cache only inner reference ticks. Slip halving, resistance, braking, slope
; and all subsequent engine/gear updates remain native and execute each tick.
	dc.b 'HDPOWER1'
_drivetrain_power_state:
	dc.l 0                   ; ratio numerator/denominator words
	dc.w 0,0                 ; signed throttle, valid
	dc.l 0                   ; final native D0 result
	dc.w 0,0                 ; first conversion (D4 word), padding
	dc.l 0,0                 ; hits, misses
_drivetrain_power:
	movem.l d1/a0,-(a7)
	move.w _drivetrain_state+6(pc),d1
	cmpi.w #1,d1
	bne.s .uncached
	lea _drivetrain_power_state(pc),a0
	tst.w 6(a0)
	beq.s .miss
	move.l (a2),d1
	cmp.l (a0),d1
	bne.s .miss
	move.b -$66e4(a4),d1
	ext.w d1
	cmp.w 4(a0),d1
	bne.s .miss
	addq.l #1,16(a0)
	move.w 12(a0),d4
	move.l 8(a0),d0
	movem.l (a7)+,d1/a0
	move.w d0,-14(a5)
	rts
.miss:
	addq.l #1,20(a0)
	moveq #1,d1
.uncached:
	; Native $2950 only clobbers D0. Keep D1/A0 saved once across both
	; calls; D1 distinguishes a cache miss from an uncached native step.
	; Displaced B696..B6BC, including both native multiply/divide calls.
	move.w #100,-(a7)
	move.w #450,-(a7)
	move.b -$66e4(a4),d0
	ext.w d0
	move.w d0,-(a7)
	jsr -$7f5c(a4)
	addq.w #6,a7
	move.w d0,d4
	move.w (a2),-(a7)
	move.w 2(a2),-(a7)
	move.w d4,-(a7)
	jsr -$7f5c(a4)
	addq.w #6,a7
	move.w d0,-14(a5)
	cmpi.w #1,d1
	bne.s .done
	move.l (a2),(a0)
	move.b -$66e4(a4),d1
	ext.w d1
	move.w d1,4(a0)
	move.w #1,6(a0)
	move.l d0,8(a0)
	move.w d4,12(a0)
.done:
	movem.l (a7)+,d1/a0
	rts
	ENDC

	IFD VERIFY_DRIVETRAIN_MANUAL
; VBL input may arrive while this frame's engine recurrence is running. Leave
; later requests queued for the next outer pass instead of consuming them in
; an intermediate tick. Native/full-step behavior is unchanged.
_drivetrain_manual:
	movem.l d0/a0,-(a7)
	lea _drivetrain_state(pc),a0
	cmpi.w #1,6(a0)
	bne.s .native
	move.w (a0),d0
	cmp.w 2(a0),d0
	beq.s .native
	move.l _code_start(pc),d0
	addi.l #$ba8a,d0
	move.l d0,8(a7)
	bra.s .done
.native:
	tst.b -$66e3(a4)
	beq.s .done
	move.l _code_start(pc),d0
	addi.l #$b9c8,d0
	move.l d0,8(a7)
.done:
	movem.l (a7)+,d0/a0
	rts
	ENDC

	IFD VERIFY_DRIVETRAIN_PHASE
	INCLUDE "HardDrivinPhase.s"
	ENDC
