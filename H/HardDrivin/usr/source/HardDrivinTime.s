; SPS 0126 elapsed-time foundation. Development build: VERIFY_TIME + CUSTOM1.
; This file observes timing; optional scalar/motion diagnostics use a constant T.
; The elapsed-time dispatcher and full scaled simulation are not connected yet.
; No hook is installed unless both gates are on. Production builds exclude it.
;
; Nominal reference f0=50/8 native steps per second. Every PAL field therefore
; contributes exactly $2000 in Q16.16; conversion has no rounding remainder.
; Keep field debt in 32-bit field units, not a saturating Q16.16 total. The
; eventual integrator drains at most eight fields (T<=1) per substep.
TIME_FIELDS_PER_STEP equ 8
TIME_FIELD_Q16 equ $2000

_time_install:
	IFD VERIFY_TRAFFIC_MATH
	bsr _traffic_math_test
	ENDC
	IFD VERIFY_PROJECTION_MATH
	bsr _projection_math_test
	ENDC
	IFD VERIFY_CONTACT_MATH
	bsr _contact_math_test
	ENDC
	IFD VERIFY_MOTION_MATH
	bsr _motion_math_test
	ENDC
	IFD VERIFY_TIME_SCALAR_MATH
	bsr _time_scalar_math_test
	ENDC
	IFD VERIFY_TIME_MATH
	bsr _time_math_test
	ENDC
	cmpi.l #$11a4e,d0
	bne.s .done
	movem.l d0-d1/a0-a2,-(a7)
	move.l _ct_ct1(pc),d0
	beq.s .restore
	movea.l a0,a1
	lea _time_patches(pc),a0
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	IFD VERIFY_TIME_SCALARS
	movea.l _code_start(pc),a1
	lea _time_scalar_patches(pc),a0
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	IFD VERIFY_TIME_MOTION
	bsr _motion_install
	ENDC
	IFD VERIFY_TIME_TRAFFIC
	bsr _traffic_install
	ENDC
	ENDC
.restore:
	movem.l (a7)+,d0-d1/a0-a2
.done:
	rts

_time_patches:
	PL_START
	; PERF_RANGE CUSTOM1 $00050 $0006: VBL elapsed fields, preserve incoming X
	PL_PS $50,_time_vbl
	; PERF_RANGE CUSTOM1 $10ed4 $0008: live-loop boundary and race exit
	PL_P $10ed4,_time_outer
	; PERF_RANGE CUSTOM1 $07c52 $0008: pause entry, native clock/audio calls
	PL_PSS $7c52,_time_pause,2
	; PERF_RANGE CUSTOM1 $07c64 $0006: pause exit, resume prior timing epoch
	PL_PS $7c64,_time_resume
	; PERF_RANGE CUSTOM1 $07770 $0008: options-menu suspension boundary
	PL_PSS $7770,_time_options_suspend,2
	; PERF_RANGE CUSTOM1 $077ac $0006: options-menu resume
	PL_PS $77ac,_time_resume
	; PERF_RANGE CUSTOM1 $10f52 $0008: replay call and frame publication
	PL_PSS $10f52,_time_replay,2
	PL_END

; Enter after native interrupt register saves. A4 has not yet been loaded.
; Saving/restoring CCR is essential: native lap ABCD consumes interrupted X.
; MOVE from SR is legal here on all CPUs because this is the VBL interrupt.
_time_vbl:
	movea.l (a1),a4
	move.w sr,-(a7)
	move.l a0,-(a7)
	lea _time_state(pc),a0
	tst.b TS_ACTIVE(a0)
	beq.s .idle
	addq.l #1,TS_FIELDS(a0)
.idle:
	movea.l (a7)+,a0
	move.w (a7)+,ccr
	tst.b -$6a14(a4)
	rts

; The diagnostic publishes elapsed fields and the first bounded T. Pending is
; cumulative OBSERVED time, not a claim that physics has consumed that time.
; Counters wrap modulo 2^32, including the subtraction at each pass boundary.
_time_outer:
	movem.l d0-d1/a0-a1,-(a7)
	moveq #0,d1
	roxl.b #1,d1
	move.w d1,-(a7)
	lea _time_state(pc),a0
	tst.b -$522c(a4)
	beq.s .leave
	tst.b TS_ACTIVE(a0)
	bne.s .measure
	st TS_ACTIVE(a0)
	IFD VERIFY_TIME_SCALARS
	bsr _time_reset_scalars
	ENDC
	move.l TS_FIELDS(a0),TS_PREVIOUS(a0)
.measure:
	move.l TS_FIELDS(a0),d0
	move.l d0,d1
	sub.l TS_PREVIOUS(a0),d0
	move.l d1,TS_PREVIOUS(a0)
	move.l d0,TS_ELAPSED(a0)
	add.l d0,TS_OBSERVED(a0)
	addq.l #1,TS_PASSES(a0)
	cmpi.l #TIME_FIELDS_PER_STEP,d0
	bls.s .bounded
	moveq #TIME_FIELDS_PER_STEP,d0
.bounded:
	moveq #13,d1
	lsl.l d1,d0
	move.l d0,TS_T(a0)
	movea.l _code_start(pc),a1
	adda.l #$10edc,a1
	bra.s .return
.leave:
	clr.b TS_ACTIVE(a0)
	movea.l _code_start(pc),a1
	adda.l #$10f5e,a1
.return:
	move.l a1,TS_RETURN(a0)
	move.w (a7)+,d1
	lsr.b #1,d1
	movem.l (a7)+,d0-d1/a0-a1
	; Reproduce native final TST flags; use a memory-indirect RTS trampoline.
	move.l _time_state+TS_RETURN(pc),-(a7)
	tst.b -$522c(a4)
	rts

_time_pause:
	move.l a0,-(a7)
	lea _time_state(pc),a0
	move.b TS_ACTIVE(a0),TS_SUSPENDED(a0)
	clr.b TS_ACTIVE(a0)
	movea.l (a7)+,a0
	clr.b -$6a13(a4)
	jsr -$7fd4(a4)
	rts

_time_options_suspend:
	move.l a0,-(a7)
	lea _time_state(pc),a0
	move.b TS_ACTIVE(a0),TS_SUSPENDED(a0)
	clr.b TS_ACTIVE(a0)
	movea.l (a7)+,a0
	clr.b -$6a13(a4)
	clr.b -1(a5)
	rts

_time_resume:
	move.l a0,-(a7)
	lea _time_state(pc),a0
	move.b TS_SUSPENDED(a0),TS_ACTIVE(a0)
	movea.l (a7)+,a0
	move.b #$ff,-$6a13(a4)
	rts

_time_replay:
	; Suspend only if the native replay is actually requested. Ordinary frames
	; must still account for their rendering and ready-buffer wait.
	tst.b -$5229(a4)
	beq.s .ordinary
	movem.l d0/a0,-(a7)
	lea _time_state(pc),a0
	moveq #0,d0
	move.b TS_ACTIVE(a0),d0
	clr.b TS_ACTIVE(a0)
	move.w d0,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$10b08,a0
	jsr (a0)
	move.w (a7)+,d0
	lea _time_state(pc),a0
	move.b d0,TS_ACTIVE(a0)
	IFD VERIFY_TIME_SCALARS
	bsr _time_reset_scalars
	ENDC
	movem.l (a7)+,d0/a0
	bra.s .submit
.ordinary:
	; Native no-replay entry only tests ADD7 and returns, preserving D0/A0.
	move.l a0,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$10b08,a0
	jsr (a0)
	movea.l (a7)+,a0
.submit:
	jsr -$7fe6(a4)
	rts

; Published diagnostic block, retained in slave memory, never game globals.
TS_FIELDS equ 0
TS_PREVIOUS equ 4
TS_ELAPSED equ 8
TS_OBSERVED equ 12
TS_PASSES equ 16
TS_T equ 20
TS_RETURN equ 24
TS_ACTIVE equ 28
TS_SUSPENDED equ 29
	CNOP 0,4
_time_signature: dc.b 'HDTIME01'
_time_state: dcb.b 32,0

; Exact signed integration in eighths of a native step. D0.W is a native
; integer increment, D1.W is elapsed fields 0..8, D2.L is signed carry -7..7.
; Return integer increment in D0.L and signed carry in D2.L; preserve D1.
; DIVS truncates toward zero, matching native signed divisions. The largest
; numerator is +/-262151, so the signed-word quotient cannot overflow.
; Eighths are an exact compact representation of the public Q16.16 fraction.
_time_scale_word:
	muls.w d1,d0
	add.l d2,d0
	divs.w #TIME_FIELDS_PER_STEP,d0
	move.l d0,d2
	swap d2
	ext.l d2
	ext.l d0
	rts

; Q16 companion for rates needing exponential retention between ramp updates.
; D0.W: rate with magnitude <=16383; D1.W: fields 0..8; D2.L: signed Q16
; remainder -65535..65535. Return D0.L integer increment, D2.L remainder.
; This bound keeps the intermediate signed product plus carry within 32 bits.
_time_scale_q16:
	muls.w d1,d0
	lsl.l #8,d0
	lsl.l #5,d0
	add.l d2,d0
_time_split_q16:
	move.l d0,d2
	swap d0
	ext.l d0
	andi.l #$ffff,d2
	tst.l d0
	bpl.s .done
	tst.l d2
	beq.s .done
	addq.l #1,d0
	subi.l #$10000,d2
.done:
	rts

; Convert unsigned pending fields D0.L into one bounded step D1.L (Q16.16),
; taken fields D2.L, and remaining pending fields D0.L. No saturating total
; and no discarded fields, including a backlog exceeding Q16.16's range.
_time_take_fields:
	moveq #TIME_FIELDS_PER_STEP,d2
	cmp.l d2,d0
	bhi.s .take
	move.l d0,d2
.take:
	sub.l d2,d0
	move.l d2,d1
	lsl.l #8,d1
	lsl.l #5,d1
	rts

	IFD VERIFY_TIME_MATH
; Boot-time arithmetic fixture; never changes any game state. The host reads
; the output at the signature and compares every result with an independent
; integer model. Inputs are enumerated here, not written through the debugger.
_time_math_test:
	movem.l d0-d7/a0-a2,-(a7)
	lea _time_math_values(pc),a1
	lea _time_math_results(pc),a2
	moveq #8,d7
.value:
	move.w (a1)+,d4
	moveq #0,d5
.fields:
	moveq #-7,d6
.carry:
	move.w d4,d0
	move.w d5,d1
	move.l d6,d2
	bsr _time_scale_word
	move.w d0,(a2)+
	move.w d2,(a2)+
	addq.l #1,d6
	cmpi.w #7,d6
	ble.s .carry
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .fields
	dbf d7,.value
	lea _time_debt_values(pc),a1
	lea _time_debt_results(pc),a2
	moveq #10,d7
.debt:
	move.l (a1)+,d0
	bsr _time_take_fields
	move.l d0,(a2)+
	move.l d1,(a2)+
	move.l d2,(a2)+
	dbf d7,.debt
	lea _time_q16_values(pc),a1
	lea _time_q16_results(pc),a2
	moveq #6,d7
.qvalue:
	move.w (a1)+,d4
	moveq #0,d5
.qfields:
	lea _time_q16_carries(pc),a0
	moveq #6,d6
.qcarry:
	move.w d4,d0
	move.w d5,d1
	move.l (a0)+,d2
	bsr _time_scale_q16
	move.l d0,(a2)+
	move.l d2,(a2)+
	dbf d6,.qcarry
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .qfields
	dbf d7,.qvalue
	movem.l (a7)+,d0-d7/a0-a2
	rts
_time_math_values: dc.w -32768,-100,-3,-1,0,1,3,100,32767
_time_math_signature: dc.b 'HDMATH01'
_time_math_results: dcb.w 9*9*15*2,0
_time_debt_values: dc.l 0,1,7,8,9,15,16,65535,524287,524288,$ffffffff
_time_debt_signature: dc.b "HDDEBT01"
_time_debt_results: dcb.l 11*3,0
_time_q16_values: dc.w -16383,-2,-1,0,1,2,16383
_time_q16_carries: dc.l -65535,-8192,-1,0,1,8192,65535
_time_q16_signature: dc.b 'HDQ16001'
_time_q16_results: dcb.l 7*9*7*2,0
	ENDC

	IFD VERIFY_TIME_SCALARS
	INCLUDE "HardDrivinScalar.s"
	ENDC

	IFD VERIFY_TIME_MOTION
	INCLUDE "HardDrivinContact.s"
	INCLUDE "HardDrivinProjection.s"
	INCLUDE "HardDrivinMotion.s"
	ENDC

	IFD VERIFY_TIME_TRAFFIC
	INCLUDE "HardDrivinTraffic.s"
	ENDC
