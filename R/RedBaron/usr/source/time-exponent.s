; VERIFY W6 / CUSTOM2 bit 13, sim v1 only.
; PERF_RANGE sim:2c31c 6 bit=13
; Exact D0/D1/D2/CCR replacement for the original exponent encoding helper.
time_exp_install:
	movem.l d0-a6,-(sp)
	move.l #$2c31c,d0
	moveq #32,d1
	lea time_exp_original(pc),a0
	lea .check_base(pc),a6
.check_base
	adda.l #perf_check_bytes-.check_base,a6
	jsr (a6)
	lea .attn_base(pc),a0
.attn_base
	adda.l #perf_attnflags+3-.attn_base,a0
	btst #0,(a0)
	beq .cpu_ready
	lea time_exp_read_ccr(pc),a0
	move.w #$42c3,(a0)
.cpu_ready
	bsr time_exp_selftest
	IFD VERIFY_MATRIX_EXPERIMENT
	bsr time_matrix_install
	ENDC
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
.patch:
	PL_START
	PL_P $2c31c,time_exp_fast
	PL_END

; Five bounded decisions find floor(log2(D0)). No table, address register or
; hidden upper-word clobber. The final MOVE restores the original D2-derived
; NZ flags; ADD.W clears X for nonzero input, while zero retains incoming X.
time_exp_fast:
	move.l d2,-(sp)
	move.l d0,d1
	beq.b .done
	moveq #0,d2
	cmpi.l #$10000,d1
	bcs.b .byte
	swap d1
	andi.l #$ffff,d1
	moveq #16,d2
.byte
	cmpi.w #$100,d1
	bcs.b .nibble
	lsr.w #8,d1
	addq.w #8,d2
.nibble
	cmpi.w #16,d1
	bcs.b .pair
	lsr.w #4,d1
	addq.w #4,d2
.pair
	cmpi.w #4,d1
	bcs.b .bit
	lsr.w #2,d1
	addq.w #2,d2
.bit
	cmpi.w #2,d1
	bcs.b .encode
	addq.w #1,d2
.encode
	moveq #32,d1
	sub.w d2,d1
	lsl.l d1,d0
	swap d0
	lsr.w #8,d0
	lsl.w #8,d2
	add.w d2,d0
	moveq #0,d1
.done
	move.l (sp)+,d2
	rts

; Exact 32 original bytes, also used by the installation byte check.
time_exp_original:
	move.l d2,-(sp)
	dc.w $143c,$ffff	; MOVE.B #-1,D2; preserve original unused high byte
	move.l d0,d1
	beq.b .done
.count
	addq.b #1,d2
	lsr.l #1,d1
	bne.b .count
.normalize
	add.l d0,d0
	bcc.b .normalize
	swap d0
	lsr.w #8,d0
	lsl.w #8,d2
	add.w d2,d0
.done
	move.l (sp)+,d2
	rts

; Private native twins plus independently generated host D0 expectations.
; All 32 input CCR combinations and four caller D2 flag patterns per value.
time_exp_selftest:
	movem.l d0-a6,-(sp)
	lea time_exp_result(pc),a4
	clr.l (a4)
	lea time_exp_cases(pc),a3
	move.w #TIME_EXP_CASE_COUNT-1,d7
.case
	moveq #31,d6
.flags
	move.l (a3),d0
	move.l #$13579bdf,d1
	move.l 4(a3),d2
	moveq #0,d3
	move.w d6,ccr
	bsr time_exp_original
	bsr time_exp_read_ccr
	andi.w #31,d3
	lea time_exp_expected(pc),a4
	movem.l d0-d3,(a4)
	move.l (a3),d0
	move.l #$13579bdf,d1
	move.l 4(a3),d2
	moveq #0,d3
	move.w d6,ccr
	bsr time_exp_fast
	bsr time_exp_read_ccr
	andi.w #31,d3
	cmp.l (a4)+,d0
	bne time_exp_bad
	cmp.l (a4)+,d1
	bne time_exp_bad
	cmp.l (a4)+,d2
	bne time_exp_bad
	cmp.l (a4)+,d3
	bne time_exp_bad
	cmp.l 8(a3),d0
	bne time_exp_bad
	tst.l d1
	bne time_exp_bad
	cmp.l 4(a3),d2
	bne time_exp_bad
	moveq #0,d4
	tst.l d2
	bne .not_zero_d2
	moveq #4,d4
	bra .nz_ready
.not_zero_d2
	bpl .nz_ready
	moveq #8,d4
.nz_ready
	tst.l (a3)
	bne .flags_ready
	move.w d6,d5
	andi.w #16,d5
	or.w d5,d4
.flags_ready
	cmp.w d4,d3
	bne time_exp_bad
	lea time_exp_result(pc),a4
	addq.l #1,(a4)
	dbf d6,.flags
	lea 12(a3),a3
	dbf d7,.case
	movem.l (sp)+,d0-a6
	rts

time_exp_read_ccr:
	move.w sr,d3
	rts

time_exp_bad:
	pea .message(pc)
	pea TDREASON_FAILMSG
	lea .resload_base(pc),a2
.resload_base
	adda.l #_resload-.resload_base,a2
	move.l (a2),a2
	jmp resload_Abort(a2)
.message: dc.b "Red Baron: W6 exponent twin mismatch",0
	even
time_exp_expected: dcb.l 4,0
time_exp_result: dc.l 0
	include "time-exponent-cases.i"
