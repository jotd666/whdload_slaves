; G5 / bit 6, 68000 only: retain vertex-loop tables, bound and list cursor in registers.
; PERF_RANGE sim:3b4cc 8 bit=6
face_install:
	movem.l d0-a6,-(sp)
	move.l perf_attnflags(pc),d0
	andi.l #$8f,d0 ; only the target 68000 class
	bne .done
	move.l a1,a3
	move.l #$3b4cc,d0
	moveq #4,d1
	lea face_bytes(pc),a0
	bsr perf_check_bytes
	move.l a3,a0
	adda.l #$3b4ec,a0
	lea face_flags(pc),a1
	move.l (a0),(a1)
	move.l (a0),d0
	addi.l #$1500,d0
	move.l a3,a0
	adda.l #$3b4d0,a0
	cmp.l (a0),d0
	bne .bad
	move.l a3,d0
	addi.l #$3b544,d0
	lea face_tail+2(pc),a0
	move.l d0,(a0)
	move.l a3,d0
	addi.l #$38dcc,d0
	lea face_transform(pc),a0
	move.l d0,(a0)
	move.l a3,a1
	adda.l #$3b4cc,a1
	lea face_original(pc),a0
	moveq #29,d0
.copy
	move.l (a1)+,(a0)+
	dbf d0,.copy
	IFD VERIFY
	btst #0,perf_attnflags+3(pc)
	beq .ccr_ready
	lea face_twin_ccr_input(pc),a0
	move.w #$42e7,(a0)
	lea face_twin_ccr_original(pc),a0
	move.w #$42e7,(a0)
	lea face_twin_ccr_fast(pc),a0
	move.w #$42e7,(a0)
.ccr_ready
	ENDC
	move.l a3,a1
	lea face_patch(pc),a0
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
.done
	movem.l (sp)+,d0-a6
	rts
.bad
	pea perf_mismatch(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
face_bytes: dc.w $4204,$4279 ; relocated count operand checked against flags + $1500
; The final longword is relocated; check the opcode prefix only in installer.
face_patch:
	PL_START
	PL_P $3b4cc,face_entry
	PL_NOP $3b4d2,2
	PL_END
face_entry:
	IFD VERIFY
	bsr face_twin
	ELSE
	bsr face_fast
	ENDC
face_tail: dc.w $4ef9
	dc.l 0
FACE_COUNT:MACRO
	IFD VERIFY
	movem.l a0-a1,-(sp)
	lea face_verify_header(pc),a1
	move.l \1(a1),a0
	addq.l #1,a0
	move.l a0,\1(a1)
	movem.l (sp)+,a0-a1
	ENDC
	ENDM
face_fast:
	move.l a0,-(sp)
	move.l face_flags(pc),a0
	move.l -$c4(a0),a0
	cmpa.l face_transform(pc),a0
	move.l (sp)+,a0
	bne face_original
	FACE_COUNT 20
	movem.l d5-d6/a2/a5,-(sp)
	move.l face_flags(pc),a2
	move.w -$74(a2),d5
	ext.l d5
	lea $14ec(a2),a5
	moveq #0,d6
	clr.b d4
	clr.w $1500(a2)
.loop
	moveq #0,d3
	move.b (a6)+,d3
	cmpi.b #$ff,d3
	beq .done
	move.w d3,d0
	tst.b (a2,d0.w)
	beq .transform
	FACE_COUNT 24
	add.w d0,d0
	add.w d0,d0
	lea $100(a2),a0
	adda.w d0,a0
	move.l (a0),-$20(a2)
	move.l $3fc(a0),-$1c(a2)
	move.l $7f8(a0),-$18(a2)
	bra .transformed
.transform
	FACE_COUNT 28
	move.l -$c4(a2),a0
	jsr (a0)
.transformed
	move.l a2,a1
	adda.w d3,a1
	cmpi.b #2,(a1)
	beq .append
	lea $4fc(a2),a0
	move.w d3,d0
	lsl.w #2,d0
	adda.w d0,a0
	move.l (a0),d0
	move.l d5,d1
	cmp.l d1,d0
	bge .project
	move.b #3,(a1)
	move.b #1,d4
	bra .append
.project
	move.b #2,(a1)
	move.w d3,d0
	move.l -$c0(a2),a0
	jsr (a0)
.append
	move.l a5,a0
	move.w d6,d0
	addq.w #1,d6
	move.w d6,$1500(a2)
	move.b d3,(a5)+
	bra .loop
.done
	movem.l (sp)+,d5-d6/a2/a5
	rts
face_flags: dc.l 0
face_transform: dc.l 0
face_original: dcb.w 60,$4e71
	rts
	IFD VERIFY
	include "face-verify.s"
	ENDC
