; Development stage of CUSTOM1 simulation: integer-rate integration sites.
; VERIFY_TIME_SCALARS keeps this incomplete solver out of release builds.
; The time dispatcher will supply _time_scalar_fields (0..8) per substep.
; Until that dispatcher is connected, VERIFY_SCALAR_FIELDS selects a constant
; test interval. The default 8 exercises native-step car-state equivalence.
; Velocity/RPM rate increments use exact eighth-unit remainders; throttle uses
; Q16 remainders so exponential retention and ramp updates share one state.
; Absolute resets and discrete skid-exit reduction clear companion fractions.
; This module does NOT yet scale position, heading, gravity, traffic or timers.
	IFND VERIFY_SCALAR_FIELDS
VERIFY_SCALAR_FIELDS equ 8
	ENDC
	IFLT VERIFY_SCALAR_FIELDS
	FAIL "VERIFY_SCALAR_FIELDS must be 0..8"
	ENDC
	IFGT VERIFY_SCALAR_FIELDS-8
	FAIL "VERIFY_SCALAR_FIELDS must be 0..8"
	ENDC

_time_scalar_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_SCALARS $0b8a2 $0008: acceleration integration
	PL_PSS $b8a2,_time_velocity_add,2
	; PERF_RANGE VERIFY_TIME_SCALARS $07d36 $000a: positive throttle ramp
	PL_PSS $7d36,_time_throttle_up,4
	; PERF_RANGE VERIFY_TIME_SCALARS $07d50 $0008: negative throttle ramp
	PL_PSS $7d50,_time_throttle_down,2
	; PERF_RANGE VERIFY_TIME_SCALARS $0bcc8 $000a: collision velocity reset
	PL_PSS $bcc8,_time_collision_velocity,4
	; PERF_RANGE VERIFY_TIME_SCALARS $0bda6 $000a: obstacle velocity reset
	PL_PSS $bda6,_time_collision_velocity,4
	; PERF_RANGE VERIFY_TIME_SCALARS $108d8 $0008: recovery velocity/throttle reset
	PL_PSS $108d8,_time_recovery_scalars,2
	; PERF_RANGE VERIFY_TIME_SCALARS $07df0 $0008: expiry throttle/pitch reset
	PL_PSS $7df0,_time_expired_throttle,2
	; PERF_RANGE VERIFY_TIME_SCALARS $0b704 $0026: neutral/airborne RPM slew
	PL_PSS $b704,_time_rpm_neutral,$20
	; PERF_RANGE VERIFY_TIME_SCALARS $0b8d2 $001a: engaged RPM slew
	PL_PSS $b8d2,_time_rpm_engaged,$14
	; PERF_RANGE VERIFY_TIME_SCALARS $059ba $0008: new-race scalar fractions
	PL_PSS $59ba,_time_initial_scalars,2
	; PERF_RANGE VERIFY_TIME_SCALARS $117f8 $0008: Phantom scalar fractions
	PL_PSS $117f8,_time_initial_scalars,2
	; PERF_RANGE VERIFY_TIME_SCALARS $10a88 $0008: recovered-pose velocity/throttle
	PL_PSS $10a88,_time_recovery_scalars,2
	; PERF_RANGE VERIFY_TIME_SCALARS $0bce6 $0008: vehicle-crash throttle reset
	PL_PSS $bce6,_time_expired_throttle,2
	; PERF_RANGE VERIFY_TIME_SCALARS $0bff4 $0008: barrier-crash throttle reset
	PL_PSS $bff4,_time_expired_throttle,2
	; PERF_RANGE VERIFY_TIME_SCALARS $0cc5a $0008: hard-landing throttle reset
	PL_PSS $cc5a,_time_expired_throttle,2
	; PERF_RANGE VERIFY_TIME_SCALARS $0bdc4 $0006: obstacle-crash throttle one
	PL_PS $bdc4,_time_crash_throttle_one
	; PERF_RANGE VERIFY_TIME_SCALARS $0b654 $000a: discrete skid-exit throttle loss
	PL_PSS $b654,_time_skid_exit_throttle,4
	; PERF_RANGE VERIFY_TIME_SCALARS $0b78a $0010: exponential off-road throttle retention
	PL_PSS $b78a,_time_throttle_retention,$a
	PL_END

_time_velocity_add:
	move.w -8(a5),d0
	movem.l d1-d2/a0,-(a7)
	lea _time_scalar_state(pc),a0
	; An absolute native writer invalidates the old fractional companion.
	; Collision/recovery same-value resets are hooked explicitly below.
	move.w -$66d8(a4),d1
	cmp.w SS_VELOCITY_LAST(a0),d1
	beq.s .current
	clr.w SS_VELOCITY_CARRY(a0)
.current:
	move.w _time_scalar_fields(pc),d1
	move.w SS_VELOCITY_CARRY(a0),d2
	ext.l d2
	bsr _time_scale_word
	move.w d2,SS_VELOCITY_CARRY(a0)
	; Record expected integer value without changing the native ADD flags.
	move.w -$66d8(a4),d1
	add.w d0,d1
	move.w d1,SS_VELOCITY_LAST(a0)
	movem.l (a7)+,d1-d2/a0
	add.w d0,-$66d8(a4)
	rts

_time_throttle_up:
	movem.l d0-d2/a0,-(a7)
	moveq #2,d0
	bsr _time_throttle_delta
	movem.l (a7)+,d0-d2/a0
	cmpi.b #100,-$66e4(a4)
	rts
_time_throttle_down:
	movem.l d0-d2/a0,-(a7)
	moveq #-2,d0
	bsr _time_throttle_delta
	movem.l (a7)+,d0-d2/a0
	tst.b -$66e4(a4)
	rts

; D0 is native ramp rate. Shared signed fraction means reversing throttle
; direction cancels owed increments rather than retaining two unrelated debts.
_time_throttle_delta:
	lea _time_scalar_state(pc),a0
	move.b -$66e4(a4),d1
	cmp.b SS_THROTTLE_LAST(a0),d1
	beq.s .current
	clr.l SS_THROTTLE_CARRY(a0)
.current:
	move.w _time_scalar_fields(pc),d1
	move.l SS_THROTTLE_CARRY(a0),d2
	bsr _time_scale_q16
	move.l d2,SS_THROTTLE_CARRY(a0)
	add.b d0,-$66e4(a4)
	; Native following instructions still perform integer saturation. Discard
	; outward fractional debt at either saturation boundary, even if no whole
	; increment was produced. Store the expected post-saturation integer.
	move.b -$66e4(a4),d0
	ble.s .zero
	cmpi.b #100,d0
	bge.s .maximum
	bra.s .save
.zero:
	tst.l SS_THROTTLE_CARRY(a0)
	bpl.s .zero_value
	clr.l SS_THROTTLE_CARRY(a0)
.zero_value:
	moveq #0,d0
	bra.s .save
.maximum:
	tst.l SS_THROTTLE_CARRY(a0)
	ble.s .maximum_value
	clr.l SS_THROTTLE_CARRY(a0)
.maximum_value:
	moveq #100,d0
.save:
	move.b d0,SS_THROTTLE_LAST(a0)
	rts

_time_collision_velocity:
	IFD VERIFY_TIME_MOTION
	bsr _motion_reset
	ENDC
	move.l a0,-(a7)
	lea _time_scalar_state(pc),a0
	clr.l SS_VELOCITY_CARRY(a0)
	movea.l (a7)+,a0
	clr.w -$66d8(a4)
	cmpi.w #45,-$66d4(a4)
	rts
_time_recovery_scalars:
	IFD VERIFY_TIME_MOTION
	bsr _motion_reset
	ENDC
	move.l a0,-(a7)
	lea _time_scalar_state(pc),a0
	clr.l SS_VELOCITY_CARRY(a0)
	clr.l SS_THROTTLE_CARRY(a0)
	clr.l SS_RPM_CARRY(a0)
	movea.l (a7)+,a0
	clr.w -$66d8(a4)
	clr.b -$66e4(a4)
	rts
_time_expired_throttle:
	move.l a0,-(a7)
	lea _time_scalar_state(pc),a0
	clr.l SS_THROTTLE_CARRY(a0)
	movea.l (a7)+,a0
	clr.b -$66e4(a4)
	clr.w -$69fe(a4)
	rts

; Q16 table for 1-(7/8)^(fields/8), rounded to nearest Q16 unit. The original
; >30 threshold remains outside this hook. At T=1 preserve native integer
; truncation exactly; at smaller T retain the full fractional throttle state.
_time_throttle_retention:
	movem.l d1-d5/a0-a1,-(a7)
	lea _time_scalar_state(pc),a0
	moveq #0,d0
	move.b -$66e4(a4),d0
	cmp.b SS_THROTTLE_LAST(a0),d0
	beq.s .current
	clr.l SS_THROTTLE_CARRY(a0)
.current:
	move.w _time_scalar_fields(pc),d1
	cmpi.w #8,d1
	beq.s .native
	move.l d0,d4
	swap d4
	add.l SS_THROTTLE_CARRY(a0),d4
	bsr _decay_throttle
	cmpi.l #$10000,d1
	beq.s .zero_retention
	mulu.w d1,d0
	move.l SS_THROTTLE_CARRY(a0),d2
	move.l d2,d3
	bpl.s .magnitude
	neg.l d2
.magnitude:
	mulu.w d1,d2
	move.w d2,d5
	clr.w d2
	swap d2
	tst.l d3
	bpl.s .loss
	tst.w d5
	beq.s .negative_exact
	addq.l #1,d2
.negative_exact:
	neg.l d2
.loss:
	add.l d2,d0
	sub.l d0,d4
	move.l d4,d2
	andi.l #$ffff,d2
	move.l d2,SS_THROTTLE_CARRY(a0)
	swap d4
	move.w d4,d0
	bra.s .save
.zero_retention:
	moveq #0,d0
	clr.l SS_THROTTLE_CARRY(a0)
	bra.s .save
.native:
	muls.w #7,d0
	asr.w #3,d0
	clr.l SS_THROTTLE_CARRY(a0)
.save:
	move.b d0,SS_THROTTLE_LAST(a0)
	movem.l (a7)+,d1-d5/a0-a1
	move.b d0,-$66e4(a4)
	rts

_time_initial_scalars:
	bsr _time_reset_scalars
	clr.w -$66d6(a4)
	clr.w -$66d4(a4)
	rts
_time_crash_throttle_one:
	move.l a0,-(a7)
	lea _time_scalar_state(pc),a0
	clr.l SS_THROTTLE_CARRY(a0)
	move.b #1,SS_THROTTLE_LAST(a0)
	movea.l (a7)+,a0
	move.b #1,-$66e4(a4)
	rts
_time_skid_exit_throttle:
	IFD VERIFY_TIME_MOTION
	bsr _motion_spin_reset
	ENDC
	muls.w #7,d0
	asr.w #3,d0
	move.l a0,-(a7)
	lea _time_scalar_state(pc),a0
	clr.l SS_THROTTLE_CARRY(a0)
	move.b d0,SS_THROTTLE_LAST(a0)
	movea.l (a7)+,a0
	move.b d0,-$66e4(a4)
	rts

; Scale the slew LIMIT, not the distance to target. Fractional motion toward
; a reachable target saturates there and clears its remainder. Native gear
; changes invalidate RPM fractions even if the integer RPM happens to match.
_time_rpm_neutral:
	move.w -12(a5),d0
	bsr _time_rpm_delta
	move.w d0,-12(a5)
	add.w d0,-$66d6(a4)
	rts
_time_rpm_engaged:
	move.l d0,-(a7)
	move.w d4,d0
	bsr _time_rpm_delta
	move.w d0,d4
	move.l (a7)+,d0
	add.w d4,-$66d6(a4)
	rts
_time_rpm_delta:
	movem.l d1-d3/a0,-(a7)
	lea _time_scalar_state(pc),a0
	move.w -$66d6(a4),d1
	cmp.w SS_RPM_LAST(a0),d1
	bne.s .invalidate
	move.w -$66ca(a4),d1
	cmp.w SS_RPM_GEAR(a0),d1
	beq.s .current
.invalidate:
	clr.w SS_RPM_CARRY(a0)
.current:
	move.w -$66ca(a4),SS_RPM_GEAR(a0)
	move.w d0,d3
	beq.s .target
	move.w #450,d0
	tst.w d3
	bpl.s .rate
	neg.w d0
.rate:
	move.w _time_scalar_fields(pc),d1
	move.w SS_RPM_CARRY(a0),d2
	ext.l d2
	bsr _time_scale_word
	move.w d2,SS_RPM_CARRY(a0)
	tst.w d3
	bmi.s .negative
	cmp.w d0,d3
	ble.s .target
	bra.s .save
.negative:
	cmp.w d0,d3
	bge.s .target
	bra.s .save
.target:
	move.w d3,d0
	clr.w SS_RPM_CARRY(a0)
.save:
	move.w -$66d6(a4),d1
	add.w d0,d1
	cmpi.w #6500,d1
	blt.s .last
	clr.w SS_RPM_CARRY(a0)
	move.w #6500,d1
.last:
	move.w d1,SS_RPM_LAST(a0)
	movem.l (a7)+,d1-d3/a0
	rts

_time_reset_scalars:
	IFD VERIFY_TIME_MOTION
	bsr _motion_reset
	ENDC
	move.l a0,-(a7)
	lea _time_scalar_state(pc),a0
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	movea.l (a7)+,a0
	rts

SS_VELOCITY_CARRY equ 0
SS_VELOCITY_LAST equ 2
SS_THROTTLE_CARRY equ 4
SS_THROTTLE_LAST equ 8
SS_RPM_CARRY equ 10
SS_RPM_LAST equ 12
SS_RPM_GEAR equ 14
_time_scalar_fields: dc.w VERIFY_SCALAR_FIELDS
_time_scalar_signature: dc.b 'HDSCAL01'
_time_scalar_state: dcb.b 16,0

	IFD VERIFY_TIME_SCALAR_MATH
; Exhaustive small table fixture using private fake globals, never game bytes.
_time_scalar_math_test:
	movem.l d0-d7/a0-a5,-(a7)
	lea _time_retention_fake(pc),a4
	adda.l #$66e4,a4
	lea _time_scalar_state(pc),a3
	lea _time_scalar_fields(pc),a5
	lea _time_retention_values(pc),a1
	lea _time_retention_results(pc),a2
	moveq #4,d7
.value:
	moveq #0,d4
	move.b (a1)+,d4
	moveq #0,d5
.fields:
	lea _time_retention_fields(pc),a0
	move.w (a0,d5.w),(a5)
	lea _time_retention_carries(pc),a0
	moveq #6,d6
.carry:
	move.b d4,-$66e4(a4)
	move.b d4,SS_THROTTLE_LAST(a3)
	move.l (a0)+,SS_THROTTLE_CARRY(a3)
	bsr _time_throttle_retention
	moveq #0,d0
	move.b -$66e4(a4),d0
	move.w d0,(a2)+
	move.l SS_THROTTLE_CARRY(a3),(a2)+
	dbf d6,.carry
	addq.w #2,d5
	cmpi.w #34,d5
	blo.s .fields
	dbf d7,.value
	move.w #VERIFY_SCALAR_FIELDS,(a5)
	bsr _time_reset_scalars
	movem.l (a7)+,d0-d7/a0-a5
	rts
_time_retention_fields: dc.w 0,1,2,3,4,5,6,7,8,9,15,31,255,705,706,32768,65535
_time_retention_values: dc.b 31,32,50,99,100
	EVEN
_time_retention_carries: dc.l -65535,-8192,-1,0,1,8192,65535
_time_retention_fake: dc.w 0
_time_retention_signature: dc.b 'HDRETN01'
_time_retention_results: dcb.b 5*17*7*6,0
	ENDC
