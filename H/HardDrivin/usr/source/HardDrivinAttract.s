; Elapsed attract camera/scroll/timeout. The two setup camera calls remain
; native. The visible cockpit establishes the epoch; no live physics runs.
_attract_install:
	movem.l d0/a0-a2,-(a7)
	IFND VERIFY_DISPATCH_NATIVE
	movea.l _code_start(pc),a0
	adda.l #$d832,a0
	lea _attract_native_math(pc),a1
	moveq #101,d0
.copy:
	move.w (a0)+,(a1)+
	dbf d0,.copy
	move.w #$4e75,(a1)
	ENDC
	lea _attract_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,d0/a0-a2
	rts
_attract_patches:
	PL_START
	IFD VERIFY_ATTRACT_PAUSE
	; PERF_RANGE VERIFY_ATTRACT_PAUSE $01382 $0006: input-only attract pause
	PL_P $1382,_attract_pause_key
	ENDC
	; PERF_RANGE VERIFY_TIME_ATTRACT $10844 $000a: visible attract epoch
	PL_PSS $10844,_attract_begin,4
	; PERF_RANGE VERIFY_TIME_ATTRACT $1084e $0008: controls and elapsed phase
	PL_PSS $1084e,_attract_frame,2
	; PERF_RANGE VERIFY_TIME_ATTRACT $1088c $000a: 8000-field attract duration
	PL_PSS $1088c,_attract_end,4
	; PERF_RANGE VERIFY_TIME_ATTRACT $10898 $0006: exit and page toggle
	PL_PS $10898,_attract_exit
	IFND VERIFY_DISPATCH_NATIVE
	; PERF_RANGE VERIFY_TIME_ATTRACT $0d574 $0008: ordered route crossings
	PL_PSS $d574,_attract_route,2
	; PERF_RANGE VERIFY_TIME_ATTRACT $0d832 $00cc: field-fraction route pose
	PL_PSS $d832,_attract_pose,$c6
	; PERF_RANGE VERIFY_TIME_ATTRACT $0d8fe $0024: suppress per-draw route advance
	PL_PSS $d8fe,_attract_advance,$1e
	; PERF_RANGE VERIFY_TIME_ATTRACT $1067a $0008: high-score page scroll
	PL_PSS $1067a,_attract_scroll,2
	; PERF_RANGE VERIFY_TIME_ATTRACT $10714 $0008: champion page scroll
	PL_PSS $10714,_attract_scroll,2
	ENDC
	PL_END
_attract_signature: dc.b 'HDATTR01'
AT_START equ 0
AT_AGE equ 4
AT_ROUTE_AGE equ 8
AT_PHASE equ 12
AT_ACTIVE equ 14
_attract_state: dcb.b 16,0
_attract_begin:
	movem.l d0-d1/a0,-(a7)
	moveq #0,d1
	roxl.b #1,d1
	move.w d1,-(a7)
	lea _attract_state(pc),a0
	move.l _replay_state+RP_WALL(pc),AT_START(a0)
	clr.l AT_AGE(a0)
	clr.l AT_ROUTE_AGE(a0)
	moveq #0,d0
	move.b -$6b2c(a4),d0
	lsl.w #3,d0
	move.w d0,AT_PHASE(a0)
	st AT_ACTIVE(a0)
	move.w (a7)+,d1
	lsr.b #1,d1
	movem.l (a7)+,d0-d1/a0
	move.b #$ff,-$6a13(a4)
	clr.w -2(a5)
	rts
_attract_frame:
	jsr -$7e7e(a4)
	IFND VERIFY_DISPATCH_NATIVE
	bsr _attract_clock
	ENDC
	tst.b -$69fc(a4)
	rts
_attract_clock:
	movem.l d0-d1/a0,-(a7)
	moveq #0,d1
	roxl.b #1,d1
	move.w d1,-(a7)
	lea _attract_state(pc),a0
	move.l _replay_state+RP_WALL(pc),d0
	sub.l AT_START(a0),d0
	move.l d0,AT_AGE(a0)
	lsr.l #3,d0
	cmpi.l #1000,d0
	bls.s .bounded
	move.l #1000,d0
.bounded:
	move.w d0,-2(a5)
	move.w (a7)+,d1
	lsr.b #1,d1
	movem.l (a7)+,d0-d1/a0
	rts
_attract_end:
	IFD VERIFY_DISPATCH_NATIVE
	addq.w #1,-2(a5)
	ELSE
	bsr _attract_clock
	andi #$ef,ccr
	ENDC
	cmpi.w #1000,-2(a5)
	rts
_attract_exit:
	IFND VERIFY_DISPATCH_NATIVE
	; Finish the last drawn interval before resetting the epoch. Timeout
	; clamps this to8000; an input-driven exit consumes only observed time.
	; Otherwise the final fractional phase would be lost on the next setup.
	movem.l a2-a3,-(a7)
	bsr _attract_route
	movem.l (a7)+,a2-a3
	ENDC
	move.l a0,-(a7)
	lea _attract_state(pc),a0
	clr.b AT_ACTIVE(a0)
	movea.l (a7)+,a0
	eori.b #$ff,-$6a7c(a4)
	rts
	IFND VERIFY_DISPATCH_NATIVE
; Render both pages from the same epoch, one native scroll unit per8fields.
; Retain the original decrement when called outside the attract sequence.
_attract_scroll:
	move.l a0,-(a7)
	lea _attract_state(pc),a0
	tst.b AT_ACTIVE(a0)
	beq.s .native
	move.l AT_AGE(a0),d0
	cmpi.l #8000,d0
	bls.s .bounded
	move.l #8000,d0
.bounded:
	lsr.l #3,d0
	neg.w d0
	addi.w #200,d0
	move.w d0,-$4ac(a4)
	bra.s .done
.native:
	move.w -$4ac(a4),d0
	subq.w #1,-$4ac(a4)
.done:
	movea.l (a7)+,a0
	rts
; Advance only the elapsed interval not already consumed. Pose construction
; can be repeated without changing route state a second time.
_attract_route:
	movem.l d0-d2/a0,-(a7)
	lea _attract_state(pc),a0
	tst.b AT_ACTIVE(a0)
	beq.s .done
	move.l AT_AGE(a0),d0
	cmpi.l #8000,d0
	bls.s .bounded
	move.l #8000,d0
.bounded:
	move.l d0,d1
	sub.l AT_ROUTE_AGE(a0),d0
	move.l d1,AT_ROUTE_AGE(a0)
	moveq #0,d1
	move.w AT_PHASE(a0),d1
	add.l d1,d0
.walk:
	cmpi.l #80,d0
	blo.s .phase
	bsr _attract_next
	move.l -$6b28(a4),-$6b24(a4)
	addi.l #20,-$6b28(a4)
	clr.b -$6b2b(a4)
	subi.l #80,d0
	bra.s .walk
.phase:
	move.w d0,AT_PHASE(a0)
	lsr.w #3,d0
	move.b d0,-$6b2c(a4)
.done:
	movem.l (a7)+,d0-d2/a0
	movea.l -$6b24(a4),a2
	movea.l -$6b28(a4),a3
	rts
; Native D586..D5D6 pending-next normalization, before EVERY crossing.
; A0/D0 retained for the elapsed route walker.
_attract_next:
	movea.l -$6b24(a4),a2
	movea.l -$6b28(a4),a3
	tst.b -$6b2a(a4)
	bne.s .alternate
	btst #1,19(a2)
	beq.s .main_end
	tst.b -$6b29(a4)
	bne.s .done
	movea.l -$66ae(a4),a3
	adda.l #20,a3
	move.l a3,-$6b28(a4)
	move.b #1,-$6b2a(a4)
	clr.b -$6b2b(a4)
	bra.s .done
.main_end:
	cmpa.l -$50da(a4),a3
	blo.s .done
	move.l -$6720(a4),-$6b28(a4)
	eori.b #$ff,-$6b29(a4)
	bra.s .done
.alternate:
	cmpa.l -$50d6(a4),a3
	blo.s .done
	move.l -$50f2(a4),-$6b28(a4)
	clr.b -$6b2a(a4)
.done:
	rts
_attract_pose:
	move.l a0,-(a7)
	lea _attract_state(pc),a0
	tst.b AT_ACTIVE(a0)
	beq .native
	movem.l d2-d3/a1,-(a7)
	moveq #0,d3
	move.w AT_PHASE(a0),d3
	lea -$6b44(a4),a0
	lea -$6716(a4),a1
	moveq #2,d2
.xyz:
	move.w (a0)+,d0
	muls.w d3,d0
	divs.w #80,d0
	add.w 10(a0),d0
	move.w d0,(a1)+
	dbf d2,.xyz
	moveq #80,d1
	sub.w d3,d1
	muls.w 12(a2),d1
	move.w d3,d0
	muls.w 12(a3),d0
	add.l d0,d1
	divs.w #80,d1
	move.w d1,-$66bc(a4)
	moveq #80,d1
	sub.w d3,d1
	muls.w 16(a2),d1
	move.w d3,d0
	muls.w 16(a3),d0
	add.l d0,d1
	divs.w #80,d1
	move.w d1,-$66b8(a4)
	lea _attract_state(pc),a0
	bsr _attract_heading
	move.w d0,-$66ba(a4)
.restore:
	movem.l (a7)+,d2-d3/a1
	movea.l (a7)+,a0
	rts
.native:
	movea.l (a7)+,a0
	bra _attract_native_math
; Cache construction at D772 resets heading to the current segment's angle.
; Preserve that hold for phases0..4, then interpolate toward the next angle.
; Evaluate from route geometry, not the most recently rendered heading.
_attract_heading:
	move.w 14(a2),d0
	cmpi.w #32,d3
	bls.s .done
	subi.w #32,d3
	move.w 14(a3),d1
	cmpi.w #360,d0
	ble.s .angle
	tst.w d1
	bge.s .angle
	addi.w #1440,d1
.angle:
	muls.w d3,d1
	neg.w d3
	addi.w #48,d3
	muls.w d3,d0
	add.l d1,d0
	divs.w #48,d0
.done:
	rts
_attract_advance:
	move.l a0,-(a7)
	lea _attract_state(pc),a0
	tst.b AT_ACTIVE(a0)
	movea.l (a7)+,a0
	bne.s .done
	addq.b #1,-$6b2c(a4)
	cmpi.b #10,-$6b2c(a4)
	blt.s .done
	clr.b -$6b2c(a4)
	movea.l -$6b28(a4),a0
	addi.l #20,-$6b28(a4)
	move.l a0,-$6b24(a4)
	clr.b -$6b2b(a4)
.done:
	rts
; Runtime copy of the original self-contained interpolation block + RTS.
_attract_native_math: dcb.w 103,0
	ENDC

	IFD VERIFY_ATTRACT_PAUSE
_attract_input_signature: dc.b 'HDATKEY1'
; raw VBL count.l, resume deadline.l, one-shot phase.w.
_attract_input_state: dcb.b 10,0
_attract_pause_key:
	move.l -4(a5),d0
	movem.l d1/a0,-(a7)
	tst.l d0
	bne.s .done
	lea _attract_state(pc),a0
	tst.b AT_ACTIVE(a0)
	beq.s .done
	lea _attract_input_state(pc),a0
	tst.w 8(a0)
	bne.s .resume
	move.l _attract_state+AT_AGE(pc),d1
	cmpi.l #24,d1
	blo.s .done
	move.w #1,8(a0)
	move.l (a0),d1
	addi.l #40,d1
	move.l d1,4(a0)
	moveq #$20,d0
	bra.s .done
.resume:
	cmpi.w #1,8(a0)
	bne.s .done
	move.l (a0),d1
	cmp.l 4(a0),d1
	blo.s .done
	move.w #2,8(a0)
	moveq #$20,d0
.done:
	movem.l (a7)+,d1/a0
	tst.l d0
	unlk a5
	rts
	ENDC
