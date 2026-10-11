; W6 single-producer/single-consumer timestamped event queue.
; Used by VERIFY bit 13. The IRQ owner must serialize multiple producers;
; only the producer publishes head and only the consumer publishes tail.
; Entry: eligible CIA boundary.l, device/code.w, value.w, payload[2].l.
; Header: head.w, tail.w (wrapping sequence numbers), overflow.w, high-water.w,
; reserved[2].l. 256 entries follow. Queue/destination memory must not overlap.
; At most 256 outstanding entries, so 16-bit sequence subtraction is unambiguous.
TIME_INPUT_CAPACITY = 256
TIME_INPUT_HEADER = 16
TIME_INPUT_BYTES = TIME_INPUT_HEADER+16*TIME_INPUT_CAPACITY

; a0 queue, a1 complete event. d0=0 success, 1 full (old entries retained).
; Caller owns producer serialization; data is complete before head publication.
time_input_push:
	movem.l d1-d3/a1-a2,-(sp)
	move.w (a0),d1
	move.w d1,d2
	sub.w 2(a0),d2
	cmpi.w #TIME_INPUT_CAPACITY,d2
	bhs.b .full
	move.w d1,d3
	andi.w #TIME_INPUT_CAPACITY-1,d3
	lsl.w #4,d3
	lea TIME_INPUT_HEADER(a0),a2
	adda.w d3,a2
	move.l (a1)+,(a2)+
	move.l (a1)+,(a2)+
	move.l (a1)+,(a2)+
	move.l (a1)+,(a2)+
	addq.w #1,d2
	cmp.w 6(a0),d2
	bls.b .publish
	move.w d2,6(a0)
.publish
	addq.w #1,d1
	move.w d1,(a0)
	moveq #0,d0
	bra.b .done
.full
	move.w #1,4(a0)
	moveq #1,d0
.done
	movem.l (sp)+,d1-d3/a1-a2
	rts

; a0 queue, a1 destination, d0 eligible boundary (unsigned CIA counter).
; Return d0=1 if copied, 0 if empty/future. Timestamp distances must be <2^31.
; Caller freezes a boundary before executing its world ticks. Producers stamp
; acquisition+1, so a late IRQ cannot add to a boundary already being executed.
time_input_pop:
	movem.l d1-d2/a1-a2,-(sp)
	move.w 2(a0),d1
	cmp.w (a0),d1
	beq.b .none
	move.w d1,d2
	andi.w #TIME_INPUT_CAPACITY-1,d2
	lsl.w #4,d2
	lea TIME_INPUT_HEADER(a0),a2
	adda.w d2,a2
	move.l (a2),d2
	sub.l d0,d2
	tst.l d2 ; interpret modular distance, not SUB signed-overflow flags
	bgt.b .none
	move.l (a2)+,(a1)+
	move.l (a2)+,(a1)+
	move.l (a2)+,(a1)+
	move.l (a2)+,(a1)+
	addq.w #1,d1
	move.w d1,2(a0)
	moveq #1,d0
	bra.b .done
.none
	moveq #0,d0
.done
	movem.l (sp)+,d1-d2/a1-a2
	rts

	IFD VERIFY
; Native FIFO test: full queue, no eviction, eligibility before/at deadline,
; 32-bit CIA wrap, 16-bit sequence wrap, exact four-long payload preservation.
	IFD VERIFY
time_input_selftest:
	movem.l d0-a6,-(sp)
	lea .base(pc),a3
.base
	adda.l #time_input_test_queue-.base,a3
	lea time_input_test_result(pc),a4
	clr.l (a4)
	move.l #$7ffffff0,d4
	moveq #1,d5
.phase
	move.l a3,a0
	move.w #$fffa,(a0)
	move.w #$fffa,2(a0)
	clr.l 4(a0)
	lea time_input_test_event(pc),a1
	moveq #0,d7
.fill
	move.l d4,d0
	add.l d7,d0
	move.l d0,(a1)
	move.w d7,4(a1)
	move.w #$55aa,6(a1)
	move.l #$13579bdf,8(a1)
	move.l #$fedcba98,12(a1)
	bsr time_input_push
	tst.w d0
	bne .bad
	addq.w #1,d7
	cmpi.w #TIME_INPUT_CAPACITY,d7
	bne.b .fill
	bsr time_input_push
	cmpi.w #1,d0
	bne .bad
	cmpi.w #TIME_INPUT_CAPACITY,6(a0)
	bne .bad
	cmpi.w #1,4(a0)
	bne .bad
	moveq #0,d7
.drain
	move.l d4,d0
	subq.l #1,d0
	add.l d7,d0
	bsr time_input_pop
	tst.w d0
	bne .bad
	move.l d4,d0
	add.l d7,d0
	move.l d0,d6
	bsr time_input_pop
	cmpi.w #1,d0
	bne .bad
	cmp.l (a1),d6
	bne .bad
	cmp.w 4(a1),d7
	bne .bad
	cmpi.w #$55aa,6(a1)
	bne .bad
	cmpi.l #$13579bdf,8(a1)
	bne .bad
	cmpi.l #$fedcba98,12(a1)
	bne .bad
	addq.w #1,d7
	cmpi.w #TIME_INPUT_CAPACITY,d7
	bne.b .drain
	move.l d4,d0
	addi.l #$200,d0
	bsr time_input_pop
	tst.w d0
	bne .bad
	move.w (a0),d0
	cmp.w 2(a0),d0
	bne .bad
	addi.l #TIME_INPUT_CAPACITY,(a4)
	addi.l #$80000000,d4
	dbf d5,.phase
	movem.l (sp)+,d0-a6
	rts
.bad
	pea time_input_test_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
time_input_test_error: dc.b "Red Baron: W6 input FIFO self-test mismatch",0
	even
time_input_test_result: dc.l 0
time_input_test_event: dcb.l 4,0
	ENDC
	ENDC
