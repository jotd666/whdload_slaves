; Bound retained world credit, including the fractional phase, to 1800 units:
; four 68000 quanta / eight 020+ quanta, just below one nominal second at F=33.
; Excess updates are funded then explicitly dropped, oldest first. Input and
; real-time services still consume their CIA boundaries in chronological order.
TIME_DEBT_LIMIT = 1800
time_debt_bound:
	movem.l d0-d2/a1,-(sp)
	tst.w TIME_LOOP_DUE(a0)
	beq .done
	move.l d3,d1
	sub.l TIME_LOOP_CURSOR(a0),d1
	cmpi.l #160,d1 ; even F=80 cannot retain this many outstanding CIA intervals
	bhi .drop
	; Conservative upper bound on phase units from the top 16 of 128 bits.
	; At most about one extra unit is reserved; the full exact phase is retained.
	moveq #0,d0
	move.w (a0),d0
	addq.l #1,d0
	mulu.w time_loop_quantum(pc),d0
	divu.w #$057d,d0 ; high word of the common 225-unit phase threshold
	andi.l #$ffff,d0
	addq.w #1,d0
	cmp.w time_loop_quantum(pc),d0
	bls .phase
	move.w time_loop_quantum(pc),d0
.phase
	moveq #0,d2
	move.w TIME_LOOP_DUE(a0),d2
	mulu.w time_loop_quantum(pc),d2
	add.w d2,d0
	neg.w d0
	addi.w #TIME_DEBT_LIMIT,d0
	mulu.w time_rate_queue+8(pc),d0
	lsl.l #8,d1
	lsl.l #2,d1
	move.l time_loop_h3(pc),a1
	tst.w $45a6(a1)
	beq .compare
	lsl.l #3,d1
.compare
	cmp.l d0,d1
	bls .done
.drop
	IFD VERIFY
	lea time_debt_header(pc),a1
	moveq #0,d0
	move.w TIME_LOOP_DUE(a0),d0
	add.l d0,20(a1)
	mulu.w time_loop_quantum(pc),d0
	add.l d0,24(a1)
	addq.l #1,28(a1)
	ENDC
	clr.w TIME_LOOP_DUE(a0)
.done
	movem.l (sp)+,d0-d2/a1
	rts
	IFD VERIFY
time_debt_header: dc.b "RBTDEBT1"
	dc.l 1,225,TIME_DEBT_LIMIT,0,0,0
	ENDC
