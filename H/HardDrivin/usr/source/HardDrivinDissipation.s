; Resistance may remove existing velocity, never manufacture reverse
; velocity. Drive/slope remain able to move the car through zero. This correction
; does not widen native velocity storage or prove arbitrary long-step stability.
; Input/output follow _time_scale_word: D0 increment, D1 fields, D2 remainder.
_time_limit_dissipation:
	tst.w d1
	beq.s .native
	cmpi.w #8,d1
	bne.s .integrate
	tst.w SS_VELOCITY_CARRY(a0)
	bne.s .integrate
.native:
	; Preserve every original zero-carry native step, including force-law quirks.
	rts
.integrate:
	movem.l d3-d7,-(a7)
	move.w -$66d8(a4),d3
	ext.l d3
	lsl.l #3,d3
	move.w SS_VELOCITY_CARRY(a0),d4
	ext.l d4
	add.l d4,d3
	beq .done
	; Original resistance is signed drag plus brake. Respect the native net
	; acceleration cap by reducing the resistance contribution only as needed,
	; then assigning the remaining capped rate to drive/slope.
	move.w -2(a5),d4
	ext.l d4
	move.w -4(a5),d5
	ext.l d5
	add.l d5,d4
	move.w -18(a5),d5
	ext.l d5
	move.w -6(a5),d6
	ext.l d6
	sub.l d6,d5
	move.w -8(a5),d6
	ext.l d6
	sub.l d6,d5
	tst.l d4
	bmi.s .negative
	beq .done
	tst.l d3
	bmi .done
	tst.l d5
	ble .done
	cmp.l d4,d5
	ble.s .magnitude
	move.l d4,d5
	bra.s .magnitude
.negative:
	tst.l d3
	bpl .done
	tst.l d5
	bpl .done
	cmp.l d4,d5
	bge.s .magnitude
	move.l d4,d5
.magnitude:
	move.l d5,d6
	bpl.s .resistance_abs
	neg.l d6
.resistance_abs:
	tst.l d3
	bpl.s .velocity_abs
	neg.l d3
.velocity_abs:
	; Magnitude can be 65536 when two negative word extrema are added.
	cmpi.l #65536,d6
	beq.s .maximum
	mulu.w d1,d6
	bra.s .compare
.maximum:
	moveq #0,d6
	move.w d1,d6
	swap d6
.compare:
	cmp.l d3,d6
	bls.s .done
	; Resistance consumes the old velocity and its fraction. The remaining
	; numerator is (capped rate + effective resistance)*fields, not zero:
	; retaining it preserves uphill/downhill rollback and engine force.
	move.w -8(a5),d6
	ext.l d6
	add.l d6,d5
	bsr _dissipation_external
	move.w -$66d8(a4),d3
	ext.l d3
	sub.l d3,d0
.done:
	movem.l (a7)+,d3-d7
	rts
; D5 signed effective external rate, D1 unsigned fields. Return absolute
; velocity D0 and eighth-unit remainder D2. Use unsigned 64-bit multiplication
; before /8 so opposing word components cannot overflow a signed numerator.
_dissipation_external:
	move.l d5,d3
	bpl.s .positive
	neg.l d5
.positive:
	move.l d5,d6
	andi.l #$ffff,d6
	mulu.w d1,d6
	swap d5
	andi.l #$ffff,d5
	mulu.w d1,d5
	move.l d5,d7
	swap d7
	andi.l #$ffff,d7
	swap d5
	clr.w d5
	add.l d5,d6
	moveq #0,d5
	addx.l d5,d7
	move.l d6,d2
	andi.l #7,d2
	lsr.l #3,d6
	moveq #29,d5
	lsl.l d5,d7
	or.l d7,d6
	move.l d6,d0
	tst.l d3
	bpl.s .done
	neg.l d0
	neg.l d2
.done:
	rts
	IFD VERIFY_DISSIPATION_MATH
	INCLUDE "HardDrivinDissipationVerify.s"
	ENDC
