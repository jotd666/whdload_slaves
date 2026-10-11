; Development-only angular-rate and fall-acceleration integration.
; Requires VERIFY_TIME_SCALARS; shares its per-substep field count.
; Rate callers are distinguished from geometry/contact callers of the same
; rotation helpers. Contact relaxation and position integration are separate.
_motion_install:
	movem.l d0/a0-a2,-(a7)
	movea.l _code_start(pc),a0
	lea _motion_pitch_function(pc),a1
	movea.l a0,a2
	adda.l #$b194,a2
	move.l a2,(a1)+
	movea.l a0,a2
	adda.l #$b1d0,a2
	move.l a2,(a1)
	movea.l a0,a1
	lea _motion_patches(pc),a0
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,d0/a0-a2
	rts
_motion_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_MOTION $0b36a $000c: roll-rate integration
	PL_PSS $b36a,_motion_roll_base,6
	; PERF_RANGE VERIFY_TIME_MOTION $0b380 $0006: pitch-rate caller
	PL_PS $b380,_motion_pitch_rate
	; PERF_RANGE VERIFY_TIME_MOTION $0b38a $0006: spin-rate caller
	PL_PS $b38a,_motion_yaw_rate
	; PERF_RANGE VERIFY_TIME_MOTION $0b448 $0006: steering-rate caller
	PL_PS $b448,_motion_yaw_rate
	; PERF_RANGE VERIFY_TIME_MOTION $0b1c6 $0008: projected pitch increment
	PL_PSS $b1c6,_motion_pitch_add,2
	; PERF_RANGE VERIFY_TIME_MOTION $0b254 $0010: projected yaw/pitch/roll increments
	PL_PSS $b254,_motion_yaw_add,$a
	; PERF_RANGE VERIFY_TIME_MOTION $0ccc2 $0008: inverted-contact fall acceleration
	PL_PSS $ccc2,_motion_fall_inverted,2
	; PERF_RANGE VERIFY_TIME_MOTION $0ccd4 $0008: dispatch airborne fall acceleration
	PL_PSS $ccd4,_motion_fall_airborne,2
	; PERF_RANGE VERIFY_TIME_MOTION $0cc8a $0006: ground constraint dispatch
	PL_PS $cc8a,_motion_fall_ground
	; PERF_RANGE VERIFY_TIME_MOTION $0cca0 $0006: inverted constraint dispatch
	PL_PS $cca0,_motion_fall_ground_end
	; PERF_RANGE VERIFY_TIME_MOTION $0b62a $0012: spin exponential retention
	PL_PSS $b62a,_motion_spin_decay,$c
	; PERF_RANGE VERIFY_TIME_MOTION $0cb6c $0008: hard-contact angular-rate reset
	PL_PSS $cb6c,_motion_contact_rates,2
	; PERF_RANGE VERIFY_TIME_MOTION $0bf80 $0008: barrier angular-rate reset
	PL_PSS $bf80,_motion_contact_rates,2
	; PERF_RANGE VERIFY_TIME_MOTION $0cd96 $0006: roll-to-zero constraint dispatch
	PL_PS $cd96,_motion_roll_snap
	PL_END

_motion_roll_base:
	movem.l d1-d2/a0-a1,-(a7)
	move.w -$66b8(a4),-$66b2(a4)
	move.w -$66ec(a4),d0
	lea _motion_state+MS_ROLL(pc),a0
	lea -$66b2(a4),a1
	bsr _motion_angle_rate
	add.w d0,(a1)
	move.w (a1),d0
	movem.l (a7)+,d1-d2/a0-a1
	tst.w d0
	rts

; The original argument remains beneath the patch-call return address. Pass
; a copy to the native rotation function, then remove the original argument
; together with the displaced ADDQ #2,SP without changing preserved registers.
_motion_pitch_rate:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	st MS_RATE(a0)
	movea.l (a7)+,a0
	move.w 4(a7),-(a7)
	movea.l _motion_pitch_function(pc),a0
	jsr (a0)
	addq.w #2,a7
	bra.s _motion_rate_return
_motion_yaw_rate:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	st MS_RATE(a0)
	movea.l (a7)+,a0
	move.w 4(a7),-(a7)
	movea.l _motion_yaw_function(pc),a0
	jsr (a0)
	addq.w #2,a7
_motion_rate_return:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.b MS_RATE(a0)
	movea.l (a7)+,a0
	move.l (a7),2(a7)
	addq.w #2,a7
	rts

_motion_pitch_add:
	move.w 8(a5),d0
	movem.l d1-d2/a0-a1,-(a7)
	lea _motion_state+MS_PITCH(pc),a0
	lea -$66b4(a4),a1
	bsr _motion_angle_component
	movem.l (a7)+,d1-d2/a0-a1
	add.w d0,-$66b4(a4)
	rts
_motion_yaw_add:
	movem.l d1-d2/a0-a1,-(a7)
	move.w 8(a5),d0
	lea _motion_state+MS_YAW(pc),a0
	lea -$66b6(a4),a1
	bsr _motion_angle_component
	add.w d0,(a1)
	move.l d0,-(a7)
	move.w d4,d0
	lea _motion_state+MS_PITCH(pc),a0
	lea -$66b4(a4),a1
	bsr _motion_angle_component
	add.w d0,(a1)
	move.w d5,d0
	lea _motion_state+MS_ROLL(pc),a0
	lea -$66b2(a4),a1
	bsr _motion_angle_component
	add.w d0,(a1)
	move.l (a7)+,d0
	movem.l (a7)+,d1-d2/a0-a1
	rts

; A0 -> signed Q16 carry.l, last integer angle.w. A1 -> current game angle.
; Accept the native +/-1440 wrap without dropping the fractional angle.
; Explicit mode/reset writers clear the companions independently of this
; mismatch check, including same-value resets. D1/D2 are scratch.
_motion_angle_component:
	move.l d0,-(a7)
	move.b _motion_state+MS_RATE(pc),d0
	beq.s .constraint
	move.l (a7)+,d0
	bra.s _motion_angle_rate
.constraint:
	move.l (a7)+,d0
	clr.l (a0)
	move.w (a1),d1
	add.w d0,d1
	move.w d1,4(a0)
	rts
_motion_angle_rate:
	move.w (a1),d1
	sub.w 4(a0),d1
	beq.s .current
	cmpi.w #1440,d1
	beq.s .current
	cmpi.w #-1440,d1
	beq.s .current
	clr.l (a0)
.current:
	move.w _time_scalar_fields(pc),d1
	move.l (a0),d2
	bsr _time_scale_q16
	move.l d2,(a0)
	move.w (a1),d1
	add.w d0,d1
	move.w d1,4(a0)
	rts

_motion_fall_inverted:
	move.w -14(a5),d0
	bsr _motion_fall_delta
	add.w d0,-$66f2(a4)
	rts
_motion_fall_airborne:
	tst.b -1(a5)
	bne.s .contact
	move.l d0,-(a7)
	moveq #5,d0
	bsr _motion_fall_delta
	add.w d0,-$66f2(a4)
	move.l (a7)+,d0
	move.l a0,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$cd86,a0
	move.l a0,4(a7)
	movea.l (a7)+,a0
.contact:
	rts
_motion_fall_delta:
	movem.l d1-d2/a0,-(a7)
	lea _motion_state(pc),a0
	move.w -$66f2(a4),d1
	cmp.w MS_FALL_LAST(a0),d1
	beq.s .current
	clr.w MS_FALL_CARRY(a0)
.current:
	move.w _time_scalar_fields(pc),d1
	move.w MS_FALL_CARRY(a0),d2
	ext.l d2
	bsr _time_scale_word
	move.w d2,MS_FALL_CARRY(a0)
	move.w -$66f2(a4),d1
	add.w d0,d1
	move.w d1,MS_FALL_LAST(a0)
	movem.l (a7)+,d1-d2/a0
	rts
_motion_fall_ground:
	tst.b -$86f(a4)
	beq.s _motion_fall_reset_fraction
	move.l a0,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$cc96,a0
	move.l a0,4(a7)
	movea.l (a7)+,a0
	rts
_motion_fall_ground_end:
	cmpi.w #320,d0
	bgt.s .done
	move.l a0,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$cccc,a0
	move.l a0,4(a7)
	movea.l (a7)+,a0
	bra.s _motion_fall_reset_fraction
.done:
	rts
_motion_fall_reset_fraction:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.l MS_FALL_CARRY(a0)
	movea.l (a7)+,a0
	rts

_motion_contact_rates:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.l MS_PITCH(a0)
	clr.l MS_ROLL(a0)
	movea.l (a7)+,a0
	clr.w -$66ea(a4)
	clr.w -$66ec(a4)
	rts
_motion_roll_snap:
	cmpi.w #3,d0
	blt.s .zero
	move.l a0,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$cda0,a0
	move.l a0,4(a7)
	movea.l (a7)+,a0
	rts
.zero:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.l MS_ROLL(a0)
	clr.w MS_ROLL+4(a0)
	movea.l (a7)+,a0
	rts

_motion_spin_decay:
	movem.l d1-d4/a0-a1,-(a7)
	lea _motion_state(pc),a0
	move.w -$66e6(a4),d0
	cmp.w MS_SPIN_LAST(a0),d0
	beq.s .current
	clr.l MS_SPIN_CARRY(a0)
.current:
	move.w _time_scalar_fields(pc),d1
	cmpi.w #8,d1
	beq.s .native
	swap d0
	clr.w d0
	add.l MS_SPIN_CARRY(a0),d0
	move.l d0,d3
	bpl.s .magnitude
	neg.l d0
.magnitude:
	move.l d0,d4
	lea _motion_spin_loss(pc),a1
	add.w d1,d1
	move.w (a1,d1.w),d1
	swap d0
	mulu.w d1,d0
	move.l d4,d2
	mulu.w d1,d2
	clr.w d2
	swap d2
	add.l d2,d0
	sub.l d0,d4
	tst.l d3
	bpl.s .positive
	neg.l d4
.positive:
	move.l d4,d0
	bsr _time_split_q16
	move.l d2,MS_SPIN_CARRY(a0)
	bra.s .save
.native:
	muls.w #9,d0
	ext.l d0
	divs.w #10,d0
	clr.l MS_SPIN_CARRY(a0)
.save:
	move.w d0,MS_SPIN_LAST(a0)
	movem.l (a7)+,d1-d4/a0-a1
	move.w d0,-$66e6(a4)
	rts
_motion_spin_reset:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.l MS_SPIN_CARRY(a0)
	movea.l (a7)+,a0
	rts
_motion_spin_loss:
	dc.w 0,857,1704,2539,3363,4177,4979,5772,6554

_motion_reset:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	movea.l (a7)+,a0
	rts
MS_YAW equ 0
MS_PITCH equ 6
MS_ROLL equ 12
MS_FALL_CARRY equ 18
MS_FALL_LAST equ 20
MS_RATE equ 22
MS_SPIN_CARRY equ 24
MS_SPIN_LAST equ 28
_motion_pitch_function: dc.l 0
_motion_yaw_function: dc.l 0
_motion_signature: dc.b 'HDMOTN01'
_motion_state: dcb.b 32,0

	IFD VERIFY_MOTION_MATH
; Isolated arithmetic fixtures use private fake globals and restore every
; register/state slot before game initialization; no debugger writes required.
_motion_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	lea _motion_fake_globals(pc),a4
	adda.l #$66f2,a4
	lea _time_scalar_fields(pc),a5
	lea _motion_angle_values(pc),a6
	lea _motion_angle_results(pc),a2
	moveq #4,d7
.angle_value:
	move.w (a6)+,d4
	moveq #0,d5
.angle_fields:
	move.w d5,(a5)
	lea _motion_angle_configs(pc),a3
	moveq #2,d6
.angle_case:
	lea _motion_state+MS_YAW(pc),a0
	lea _motion_fake_globals+60(pc),a1
	move.w (a3)+,(a1)
	move.w (a3)+,4(a0)
	move.l (a3)+,(a0)
	move.w d4,d0
	bsr _motion_angle_rate
	move.l d0,(a2)+
	move.l (a0),(a2)+
	move.w 4(a0),(a2)+
	dbf d6,.angle_case
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .angle_fields
	dbf d7,.angle_value

	lea _motion_spin_values(pc),a6
	lea _motion_spin_results(pc),a2
	moveq #6,d7
.spin_value:
	move.w (a6)+,d4
	moveq #0,d5
.spin_fields:
	move.w d5,(a5)
	lea _motion_spin_carries(pc),a3
	moveq #4,d6
.spin_case:
	lea _motion_state(pc),a0
	move.w d4,-$66e6(a4)
	move.w d4,MS_SPIN_LAST(a0)
	move.l (a3)+,MS_SPIN_CARRY(a0)
	bsr _motion_spin_decay
	move.w -$66e6(a4),(a2)+
	move.l MS_SPIN_CARRY(a0),(a2)+
	dbf d6,.spin_case
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .spin_fields
	dbf d7,.spin_value
	lea _motion_fall_values(pc),a6
	lea _motion_fall_results(pc),a2
	moveq #2,d7
.fall_value:
	move.w (a6)+,d4
	moveq #0,d5
.fall_fields:
	move.w d5,(a5)
	lea _motion_fall_configs(pc),a3
	moveq #2,d6
.fall_case:
	lea _motion_state(pc),a0
	move.w (a3)+,-$66f2(a4)
	move.w (a3)+,MS_FALL_LAST(a0)
	move.w (a3)+,MS_FALL_CARRY(a0)
	move.w d4,d0
	bsr _motion_fall_delta
	move.l d0,(a2)+
	move.w MS_FALL_LAST(a0),(a2)+
	move.w MS_FALL_CARRY(a0),(a2)+
	dbf d6,.fall_case
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .fall_fields
	dbf d7,.fall_value
	move.w #VERIFY_SCALAR_FIELDS,(a5)
	bsr _motion_reset
	movem.l (a7)+,d0-d7/a0-a6
	rts
_motion_fake_globals: dcb.b 68,0
_motion_angle_values: dc.w -5,-1,0,1,5
_motion_angle_configs:
	dc.w 719,719
	dc.l 32768
	dc.w -719,721
	dc.l 16384
	dc.w 100,20
	dc.l -65535
_motion_angle_signature: dc.b 'HDANGLE1'
_motion_angle_results: dcb.b 5*9*3*10,0
_motion_spin_values: dc.w -52,-11,-1,0,1,11,52
_motion_spin_carries: dc.l -65535,-8192,0,8192,65535
_motion_spin_signature: dc.b 'HDSPIN01'
_motion_spin_results: dcb.b 7*9*5*6,0
_motion_fall_values: dc.w -5,0,5
_motion_fall_configs: dc.w 49,49,-7,49,49,7,49,0,7
_motion_fall_signature: dc.b 'HDFALL01'
_motion_fall_results: dcb.b 3*9*3*8,0
	ENDC
