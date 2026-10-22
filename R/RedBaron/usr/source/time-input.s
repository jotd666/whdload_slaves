; fixed-step timing single-producer/single-consumer timestamped event queue.
; The IRQ owner must serialize multiple producers;
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
