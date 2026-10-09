; G3: merge the 32-bit cache-miss transform and translation. Cache hits unchanged.
; PERF_RANGE sim:38e02 8 bit=4
vertex_install:
	movem.l d0-a6,-(sp)
	move.l #$38e02,d0
	moveq #8,d1
	lea vertex_expected(pc),a0
	bsr perf_check_bytes
	move.l a1,a0
	adda.l #$3afdc,a0
	lea vertex_context(pc),a3
	move.l (a0),(a3)
	IFD VERIFY
	btst #5,perf_custom5+2(pc)
	beq.b .no_tests
	bsr vertex_selftest
.no_tests
	ENDC
	lea vertex_patch(pc),a0
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
vertex_expected: dc.w $2f02,$11bc,$0001,$0000
vertex_context: dc.l 0 ; h3:0a344
vertex_patch:
	PL_START
	PL_P $38e02,vertex_entry
	PL_END
vertex_entry:
	IFD VERIFY
	btst #5,perf_custom5+2(pc)
	bne vertex_twin
	ENDC
; d3/d4/d5 = signed source coordinates, a3 = matrix, a4 = scratch result.
; Preserve the exact low-long sum before arithmetic shifting modulo 64.
VERTEX_ROW:MACRO
	move.w d3,d0
	muls.w \1(a3),d0
	move.w d4,d1
	muls.w \1+6(a3),d1
	add.l d1,d0
	IFNE \2
	move.w d5,d1
	muls.w \1+12(a3),d1
	add.l d1,d0
	ENDC
	asr.l d6,d0
	move.l d0,\1*2(a4)
	ENDM
vertex_fast:
	movem.l d2-d6/a2-a4,-(sp)
	move.b #1,(a0,d0.w)
	move.w d0,d2
	lsl.w #2,d2
	add.w d0,d0
	add.w d2,d0
	move.l vertex_context(pc),a2
	move.l 8(a2),a0
	adda.w d0,a0
	movem.w (a0),d3-d5
	move.w d3,$164(a2)
	move.w d4,$166(a2)
	move.w d5,$168(a2)
	move.l $f4(a2),a3
	lea $182(a2),a4
	move.b 18(a3),d0
	beq .identity
	moveq #14,d6
	sub.w (a2),d6
	cmp.b #1,d0
	beq .flat
	tst.l d5
	beq .zero_z
	VERTEX_ROW 0,1
	VERTEX_ROW 2,1
	VERTEX_ROW 4,1
	bra .translated
.zero_z
	VERTEX_ROW 0,0
	VERTEX_ROW 2,0
	VERTEX_ROW 4,0
	bra .translated
.flat
	VERTEX_ROW 0,0
	VERTEX_ROW 2,0
	move.w (a2),d6
	asl.l d6,d5
	move.l d5,8(a4)
	bra.b .translated
.identity
	move.w (a2),d6
	asl.l d6,d3
	asl.l d6,d4
	asl.l d6,d5
	movem.l d3-d5,(a4)
.translated
	movem.l $104(a2),d3-d5
	add.l (a4),d3
	move.l d3,(a4)+
	add.l (a4),d4
	move.l d4,(a4)+
	add.l (a4),d5
	move.l d5,(a4)
	lea $2a2(a2),a0
	adda.w d2,a0
	move.l d3,(a0)
	move.l d4,$3fc(a0)
	move.l d5,$7f8(a0)
	movem.l (sp)+,d2-d6/a2-a4
vertex_return:
	rts
