; Enhanced supervisor stack in optional WHDLoad-managed expansion memory.
; The slave hunk itself is not a valid stack on WHDLoad interrupt entry.
; Original $a876c discards the trap frame and establishes a new stack;
; do not transplant an active frame. Keep IRQs disabled during the switch.
STEP_STACK_SIZE = $4000
step_stack_start:
	move.w #$2700,sr
	movem.l d0/a0-a1,-(a7)
	lea step_stack_start(pc),a0
	adda.l #_expmem-step_stack_start,a0
	move.l (a0),a0
	cmpa.l #$200000,a0
	bcs .original
	cmpa.l #$a00000,a0
	bcs .fast
	cmpa.l #$1000000,a0
	bcs .original
.fast:
	move.l a0,a1
	move.w #(STEP_STACK_SIZE+32)/4-1,d0
.fill:
	move.l #$a55aa55a,(a0)+
	dbf d0,.fill
	lea step_stack_top(pc),a0
	lea 16+STEP_STACK_SIZE(a1),a1
	move.l a1,(a0)
	movem.l (a7)+,d0/a0-a1
	move.l step_stack_top(pc),a7
	move.w #$2700,sr
	jmp $a8776
public_ref_153 equ *-4
.original:
	movem.l (a7)+,d0/a0-a1
	lea $77cbe,a7
	move.w #$2700,sr
	jmp $a8776
public_ref_154 equ *-4

	cnop 0,4
step_stack_top:
	dc.l 0
