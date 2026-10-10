; W6 presentation arithmetic, VERIFY-only. No game-memory hooks or writes.
; Position: d0.l old, d1.l new, d2.l Q16 fraction 0..65536 -> d0.l result.
; Signed endpoints; floor rounding. Unsigned magnitude handles a 33-bit signed
; endpoint difference without overflow. All other registers are preserved.
time_present_position:
	movem.l d1-d6,-(sp)
	tst.l d2
	beq .done
	cmpi.l #65536,d2
	bne .blend
	move.l d1,d0
	bra .done
.blend
	moveq #0,d4
	move.l d1,d3
	cmp.l d0,d1
	blt .negative
	sub.l d0,d3
	bra .multiply
.negative
	moveq #1,d4
	move.l d0,d3
	sub.l d1,d3
.multiply
	move.l d3,d5
	mulu.w d2,d5 ; low magnitude word * fraction
	swap d3
	mulu.w d2,d3 ; high magnitude word * fraction
	move.l d5,d6
	andi.l #$ffff,d6 ; remainder for negative floor rounding
	swap d5
	andi.l #$ffff,d5
	add.l d5,d3 ; full quotient, at most $fffeffff
	tst.w d4
	bne .subtract
	add.l d3,d0
	bra .done
.subtract
	sub.l d3,d0
	tst.w d6
	beq .done
	subq.l #1,d0
.done
	movem.l (sp)+,d1-d6
	rts

; Unsigned word angles in d0/d1 longs. Exactly half a turn takes negative arc.
time_present_angle:
	move.l d1,-(sp)
	sub.w d0,d1
	ext.l d1
	add.l d0,d1
	bsr time_present_position
	andi.l #$ffff,d0
	move.l (sp)+,d1
	rts

; a0 points to the four-long unspent world phase. Requires phase < threshold;
; no due world work may remain. Return floor(phase*65536/threshold) in d0.l.
; Sixteen binary-division steps, no mutation of the clock and no wide multiply.
time_present_fraction:
	movem.l d1-d7/a1,-(sp)
	movem.l (a0),d3-d6
	lea time_core_threshold(pc),a1
	moveq #0,d0
	moveq #15,d7
.bit
	add.l d6,d6
	addx.l d5,d5
	addx.l d4,d4
	addx.l d3,d3 ; twice the valid threshold fits 128 bits
	add.w d0,d0
	cmp.l (a1),d3
	bhi .subtract
	blo .next
	cmp.l 4(a1),d4
	bhi .subtract
	blo .next
	cmp.l 8(a1),d5
	bhi .subtract
	blo .next
	cmp.l 12(a1),d6
	blo .next
.subtract
	sub.l 12(a1),d6
	move.l 8(a1),d1
	subx.l d1,d5
	move.l 4(a1),d1
	subx.l d1,d4
	move.l (a1),d1
	subx.l d1,d3
	addq.w #1,d0
.next
	dbf d7,.bit
	movem.l (sp)+,d1-d7/a1
	rts

; Actual CPU results checked against the generated independent rational oracle.
time_present_selftest:
	movem.l d0-a6,-(sp)
	lea time_present_result(pc),a4
	clr.l (a4)
	clr.l 4(a4)
	lea .cases_base(pc),a3
.cases_base
	adda.l #time_present_cases-.cases_base,a3
	move.w #TIME_PRESENT_CASES-1,d7
.case
	move.l 4(a3),d0
	move.l 8(a3),d1
	move.l 12(a3),d2
	tst.l (a3)
	bne .angle
	bsr time_present_position
	bra .check
.angle
	bsr time_present_angle
.check
	cmp.l 16(a3),d0
	bne .bad
	cmp.l 8(a3),d1
	bne .bad
	cmp.l 12(a3),d2
	bne .bad
	addq.l #1,(a4)
	adda.w #20,a3
	dbf d7,.case
	lea .phases_base(pc),a3
.phases_base
	adda.l #time_present_phase_cases-.phases_base,a3
	move.w #TIME_PRESENT_PHASE_CASES-1,d7
.phase
	move.l a3,a0
	bsr time_present_fraction
	cmp.l 16(a3),d0
	bne .bad
	cmpa.l a3,a0
	bne .bad
	addq.l #1,4(a4)
	adda.w #20,a3
	dbf d7,.phase
	movem.l (sp)+,d0-a6
	rts
.bad
	pea time_present_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
time_present_error: dc.b "Red Baron: W6 interpolation arithmetic mismatch",0
	even
time_present_result: dc.l 0,0
