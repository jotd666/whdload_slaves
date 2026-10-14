; G4: only the low 32 bits of the three signed products are observable.
; PERF_RANGE sim:3b1fa 8 bit=5
; d1/a0/a1 and flags are dead at the identified caller; d2-a6 preserved.
dot_install:
	movem.l d0-a6,-(sp)
	move.l #$3b1fa,d0
	moveq #8,d1
	lea dot_expected(pc),a0
	bsr perf_check_bytes
	IFD VERIFY
	btst #3,perf_custom5+2(pc)
	beq.b .no_tests
	bsr dot_selftest
.no_tests
	ENDC
	lea dot_patch(pc),a0
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
dot_expected: dc.w $4e55,$fff0,$48e7,$0030
dot_patch:
	PL_START
	PL_P $3b1fa,dot_entry
	PL_END
dot_entry:
	IFD VERIFY
	btst #3,perf_custom5+2(pc)
	bne dot_twin
	ENDC
DOT_PRODUCT:MACRO
	moveq #0,d1
	move.w (a1),d1
	bpl.b .positive\@
	neg.w d1
.positive\@
	move.l (a0)+,d0
	move.l d0,d2
	swap d2
	mulu.w d1,d0
	mulu.w d1,d2
	swap d2
	clr.w d2
	add.l d2,d0
	tst.w (a1)+
	bpl.b .done\@
	neg.l d0
.done\@
	ENDM
dot_fast:
	movem.l d2-d3,-(sp)
	move.l 12(sp),a0
	move.l 16(sp),a1
	DOT_PRODUCT
	move.l d0,d3
	DOT_PRODUCT
	add.l d0,d3
	DOT_PRODUCT
	add.l d3,d0
	movem.l (sp)+,d2-d3
dot_return:
	rts
