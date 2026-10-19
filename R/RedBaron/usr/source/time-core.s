; fixed-step timing exact clock kernel. CPU selection chooses the 225- or 450-unit rate table.
; Both use normalized phase < 225*LCM(10..80); 450-unit increments are half.
; The owner advances once per unprocessed CIA tick and retains the CIA cursor
; as debt. It must execute every returned world tick before advancing again.
; a0: phase[4].l (big endian), secondary_phase.w. d0.w: F=10..80,
; d1.w: multiplier 1 or 8. Preconditions checked by the scheduler owner.
; Returns d0.w=world updates (0..4), d1.w=128-unit service ticks (0..1).
; Preserves d2-d7/a0-a6. All phase arithmetic is exact across F changes.
time_core_advance:
	movem.l d2-d7/a0-a2,-(sp)
	subi.w #10,d0
	lsl.w #4,d0
	lea time_core_rates(pc),a1
	adda.w time_core_rate_offset(pc),a1
	adda.w d0,a1
	movem.l (a1),d2-d5
	cmpi.w #8,d1
	bne.b .add
	moveq #2,d6
.compress
	add.l d5,d5
	addx.l d4,d4
	addx.l d3,d3
	addx.l d2,d2
	dbf d6,.compress
.add
	; ADDX memory form predecrements both operands. Stack carries rate limbs.
	movem.l d2-d5,-(sp)
	lea 16(sp),a1
	lea 16(a0),a2
	moveq #0,d6
	add.l d6,d6 ; clear X
	addx.l -(a1),-(a2)
	addx.l -(a1),-(a2)
	addx.l -(a1),-(a2)
	addx.l -(a1),-(a2)
	lea 16(sp),sp
	moveq #0,d0
	lea time_core_threshold(pc),a1
.again
	moveq #3,d6
	move.l a0,a2
	move.l a1,-(sp)
.compare
	move.l (a2)+,d2
	cmp.l (a1)+,d2
	bhi.b .subtract
	blo.b .fraction
	dbf d6,.compare
.subtract
	move.l (sp)+,a1
	lea 16(a1),a1
	lea 16(a0),a2
	moveq #0,d6
	add.l d6,d6
	subx.l -(a1),-(a2)
	subx.l -(a1),-(a2)
	subx.l -(a1),-(a2)
	subx.l -(a1),-(a2)
	addq.w #1,d0
	bra.b .again
.fraction
	move.l (sp)+,a1
	moveq #0,d1
	addi.w #1024,16(a0)
	cmpi.w #2560,16(a0)
	blo.b .done
	subi.w #2560,16(a0)
	moveq #1,d1
.done
	movem.l (sp)+,d2-d7/a0-a2
	rts
time_core_rate_offset: dc.w 0 ; 225 table by default; 450 selected at install
	INCLUDE "time-core-rates.i"
