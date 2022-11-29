
	; Line rendering SMC replacement code for Killing Cloud
	; (c) 2001 Halibut Software

;==========================================================================

SMC1_BODY:	MACRO
	IFEQ	\1&1
	and.w	d1,(a0)+
	ELSE
	or.w	d0,(a0)+
	ENDC
	IFEQ	\1&2
	and.w	d1,$26(a0)
	ELSE
	or.w	d0,$26(a0)
	ENDC
	IFEQ	\1&4
	and.w	d1,$4e(a0)
	ELSE
	or.w	d0,$4e(a0)
	ENDC
	IFEQ	\1&8
	and.w	d1,$76(a0)
	ELSE
	or.w	d0,$76(a0)
	ENDC
	ENDM

;==========================================================================

SMC1_FUNC:	MACRO
_SMC1_A\1:	move.w	d2,d7
	sub.w	d0,d7
	bne.s	.lCA92
	sub.w	d1,d3
	bpl.s	.lCA5A
	add.w	d3,d1
	neg.w	d3
.lCA5A	add.w	d1,d1
	move.w	d0,d2
	andi.w	#$F,d2
	lsr.w	#3,d0
	andi.w	#$FFFE,d0
	add.w	0(a1,d1.w),d0
	adda.w	d0,a0
	clr.w	d0
	eori.w	#$F,d2
	bset	d2,d0
	move.w	d0,d1
	not.w	d1
.lCA7A:	SMC1_BODY	\1
	lea	-$A2(a0),a0
	dbf	d3,.lCA7A
	rts

.lCA92	sub.w	d1,d3
	add.w	d1,d1
	moveq	#$F,d2
	and.w	d0,d2
	eor.w	d2,d0
	asr.w	#3,d0
	add.w	0(a1,d1.w),d0
	adda.w	d0,a0
	clr.w	d0
	eori.w	#$F,d2
	bset	d2,d0
	tst.w	d3
	movea.w	#$FF60,a1
	bpl.s	.lCABA
	movea.w	#$A0,a1
	neg.w	d3
.lCABA	lea	-2(a1),a4
	cmp.w	d3,d7
	bgt	.lCB60
	move.w	d0,d1
	not.w	d1
	move.w	d3,d5
	move.w	d3,d2
	add.w	d2,d2
	neg.w	d7
	add.w	d7,d7
	add.w	d7,d2
	add.w	d7,d5
	bmi.s	.lCB30
.lCB14:	SMC1_BODY	\1
	adda.w	a4,a0
	add.w	d7,d5
	dbmi	d3,.lCB14
	dbpl	d3,.lCB30
	rts
.lCB30:	SMC1_BODY	\1
	ror.w	#1,d1
	ror.w	#1,d0
	bcs.s	.lCB52
	adda.w	a4,a0
	add.w	d2,d5
	dbmi	d3,.lCB14
	dbpl	d3,.lCB30
	rts
.lCB52	adda.w	a1,a0
	add.w	d2,d5
	dbmi	d3,.lCB14
	dbpl	d3,.lCB30
	rts
.lCB60:	move.w	d0,d4
	move.w	d7,d5
	move.w	d7,d2
	add.w	d2,d2
	neg.w	d3
	add.w	d3,d3
	add.w	d3,d2
	add.w	d3,d5
	bmi.s	.lCC12
.lCBCC	or.w	d4,d0
	ror.w	#1,d4
	bcs.s	.lCBF0
	add.w	d3,d5
	dbmi	d7,.lCBCC
	dbpl	d7,.lCC10
	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	rts
.lCBF0	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	clr.w	d0
	add.w	d3,d5
	dbmi	d7,.lCBCC
	dbpl	d7,.lCC10
	rts
.lCC10	or.w	d4,d0
.lCC12	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	clr.w	d0
	ror.w	#1,d4
	bcs.s	.lCC38
	adda.w	a4,a0
	add.w	d2,d5
	dbmi	d7,.lCBCC
	dbpl	d7,.lCC10
	rts
.lCC38	adda.w	a1,a0
	add.w	d2,d5
	dbmi	d7,.lCBCC
	dbpl	d7,.lCC10
	rts

;-----

_SMC1_B\1:	movea.l	$12(a6),a2
	movea.l	$16(a6),a3
	move.w	d2,d7
	sub.w	d0,d7
	bne.s	.lCCD0
	sub.w	d1,d3
	bpl.s	.lCC7A
	add.w	d3,d1
	neg.w	d3
.lCC7A	move.w	d1,d2
	sub.w	2(a6),d2
	add.w	d2,d2
	adda.w	d2,a2
	adda.w	d2,a3
	move.w	d0,d6
	add.w	d1,d1
	moveq	#$F,d2
	and.w	d0,d2
	eor.w	d2,d0
	asr.w	#3,d0
	add.w	0(a1,d1.w),d0
	adda.w	d0,a0
	clr.w	d0
	eori.w	#$F,d2
	bset	d2,d0
	move.w	d0,d1
	not.w	d1
.lCCA4	cmp.w	(a2)+,d6
	blt.s	.lCCC4
	cmp.w	(a3)+,d6
	bgt.s	.lCCC6
	SMC1_BODY	\1
	lea	-$A2(a0),a0
	dbf	d3,.lCCA4
	rts
.lCCC4	addq.l	#2,a3
.lCCC6	lea	-$A0(a0),a0
	dbf	d3,.lCCA4
	rts
.lCCD0	move.w	d0,d6
	sub.w	d1,d3
	move.w	d1,d2
	sub.w	2(a6),d2
	add.w	d2,d2
	adda.w	d2,a2
	adda.w	d2,a3
	add.w	d1,d1
	moveq	#$F,d2
	and.w	d0,d2
	eor.w	d2,d0
	asr.w	#3,d0
	add.w	0(a1,d1.w),d0
	adda.w	d0,a0
	clr.w	d0
	eori.w	#$F,d2
	bset	d2,d0
	tst.w	d3
	bmi	.lCF60
	cmp.w	d3,d7
	bgt	.lCDE6
	move.w	d0,d1
	not.w	d1
	move.w	d3,d5
	move.w	d3,d2
	add.w	d2,d2
	neg.w	d7
	add.w	d7,d7
	add.w	d7,d2
	add.w	d7,d5
	bmi.s	.lCD8C
.lCD54	cmp.w	(a2)+,d6
	blt.s	.lCD7A
	cmp.w	(a3)+,d6
	bgt.s	.lCD7C
	SMC1_BODY	\1
	lea	-$A2(a0),a0
	add.w	d7,d5
	dbmi	d3,.lCD54
	dbpl	d3,.lCD8C
	rts
.lCD7A	addq.l	#2,a3
.lCD7C	lea	-$A0(a0),a0
	add.w	d7,d5
	dbmi	d3,.lCD54
	dbpl	d3,.lCD8C
	rts
.lCD8C	cmp.w	(a2)+,d6
	blt.s	.lCDBA
	cmp.w	(a3)+,d6
	bgt.s	.lCDBC
	SMC1_BODY	\1
	addq.w	#1,d6
	ror.w	#1,d1
	ror.w	#1,d0
	bcs.s	.lCDD6
	lea	-$A2(a0),a0
	add.w	d2,d5
	dbmi	d3,.lCD54
	dbpl	d3,.lCD8C
	rts
.lCDBA	addq.l	#2,a3
.lCDBC	addq.w	#1,d6
	ror.w	#1,d1
	ror.w	#1,d0
	bcc.s	.lCDC6
	addq.l	#2,a0
.lCDC6	lea	-$A0(a0),a0
	add.w	d2,d5
	dbmi	d3,.lCD54
	dbpl	d3,.lCD8C
	rts
.lCDD6	lea	-$A0(a0),a0
	add.w	d2,d5
	dbmi	d3,.lCD54
	dbpl	d3,.lCD8C
	rts
.lCDE6:	move.w	d0,d4
	clr.w	d0
	move.w	d7,d5
	move.w	d7,d2
	add.w	d2,d2
	neg.w	d3
	add.w	d3,d3
	add.w	d3,d2
	add.w	d3,d5
	bmi.s	.lCEE0
.lCE72	movea.w	(a2)+,a4
	movea.w	(a3)+,a5
	cmp.w	a5,d6
	bgt	.lCF4C
.lCE7C	cmp.w	a4,d6
	bge.s	.lCE9A
	addq.w	#1,d6
	ror.w	#1,d4
	bcc.s	.lCE88
	addq.w	#2,a0
.lCE88	add.w	d3,d5
	dbmi	d7,.lCE7C
	dbpl	d7,.lCF1E
	rts
.lCE94	cmp.w	a5,d6
	bgt	.lCF36
.lCE9A	or.w	d4,d0
	addq.w	#1,d6
	ror.w	#1,d4
	bcs.s	.lCEC0
	add.w	d3,d5
	dbmi	d7,.lCE94
	dbpl	d7,.lCEEA
	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	rts
.lCEC0	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	clr.w	d0
	add.w	d3,d5
	dbmi	d7,.lCE94
	dbpl	d7,.lCEEA
	rts
.lCEE0	movea.w	(a2)+,a4
	movea.w	(a3)+,a5
	cmp.w	a5,d6
	ble.s	.lCEEE
	bra.s	.lCF1E
.lCEEA	cmp.w	a5,d6
	bgt.s	.lCEF4
.lCEEE	cmp.w	a4,d6
	blt.s	.lCEF4
	or.w	d4,d0
.lCEF4	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	clr.w	d0
	addq.w	#1,d6
	ror.w	#1,d4
	bcs.s	.lCF26
	lea	-$A2(a0),a0
	add.w	d2,d5
	dbmi	d7,.lCE72
	dbpl	d7,.lCEE0
	rts
.lCF1E	addq.w	#1,d6
	ror.w	#1,d4
	bcc.s	.lCF26
	addq.w	#2,a0
.lCF26	lea	-$A0(a0),a0
	add.w	d2,d5
	dbmi	d7,.lCE72
	dbpl	d7,.lCEE0
	rts
.lCF36	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	clr.w	d0
	subq.l	#2,a0
.lCF4C	addq.w	#1,d6
	ror.w	#1,d4
	bcc.s	.lCF54
	addq.w	#2,a0
.lCF54	add.w	d3,d5
	dbmi	d7,.lCF4C
	dbpl	d7,.lCF1E
	rts
.lCF60	neg.w	d3
	addq.w	#2,a2
	addq.w	#2,a3
	cmp.w	d3,d7
	bgt	.lD04E
	move.w	d0,d1
	not.w	d1
	move.w	d3,d5
	move.w	d3,d2
	add.w	d2,d2
	neg.w	d7
	add.w	d7,d7
	add.w	d7,d2
	add.w	d7,d5
	bmi.s	.lCFF4
.lCFBC	cmp.w	-(a2),d6
	blt.s	.lCFE2
	cmp.w	-(a3),d6
	bgt.s	.lCFE4
	SMC1_BODY	\1
	lea	$9E(a0),a0
	add.w	d7,d5
	dbmi	d3,.lCFBC
	dbpl	d3,.lCFF4
	rts
.lCFE2	subq.w	#2,a3
.lCFE4	lea	$A0(a0),a0
	add.w	d7,d5
	dbmi	d3,.lCFBC
	dbpl	d3,.lCFF4
	rts
.lCFF4	cmp.w	-(a2),d6
	blt.s	.lD022
	cmp.w	-(a3),d6
	bgt.s	.lD024
	SMC1_BODY	\1
	addq.w	#1,d6
	ror.w	#1,d1
	ror.w	#1,d0
	bcs.s	.lD03E
	lea	$9E(a0),a0
	add.w	d2,d5
	dbmi	d3,.lCFBC
	dbpl	d3,.lCFF4
	rts
.lD022	subq.w	#2,a3
.lD024	addq.w	#1,d6
	ror.w	#1,d1
	ror.w	#1,d0
	bcc.s	.lD02E
	addq.l	#2,a0
.lD02E	lea	$A0(a0),a0
	add.w	d2,d5
	dbmi	d3,.lCFBC
	dbpl	d3,.lCFF4
	rts
.lD03E	lea	$A0(a0),a0
	add.w	d2,d5
	dbmi	d3,.lCFBC
	dbpl	d3,.lCFF4
	rts
.lD04E	move.w	d0,d4
	clr.w	d0
	move.w	d7,d5
	move.w	d7,d2
	add.w	d2,d2
	neg.w	d3
	add.w	d3,d3
	add.w	d3,d2
	add.w	d3,d5
	bmi.s	.lD148
.lD0DA	movea.w	-(a2),a4
	movea.w	-(a3),a5
	cmp.w	a5,d6
	bgt	.lD19C
.lD0E4	cmp.w	a4,d6
	bge.s	.lD102
	addq.w	#1,d6
	ror.w	#1,d4
	bcc.s	.lD0F0
	addq.l	#2,a0
.lD0F0	add.w	d3,d5
	dbmi	d7,.lD0E4
	dbpl	d7,.lD1B0
	rts
.lD0FC	cmp.w	a5,d6
	bgt	.lD186
.lD102	or.w	d4,d0
	addq.w	#1,d6
	ror.w	#1,d4
	bcs.s	.lD128
	add.w	d3,d5
	dbmi	d7,.lD0FC
	dbpl	d7,.lD152
	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	rts
.lD128	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	clr.w	d0
	add.w	d3,d5
	dbmi	d7,.lD0FC
	dbpl	d7,.lD152
	rts
.lD148	movea.w	-(a2),a4
	movea.w	-(a3),a5
	cmp.w	a5,d6
	ble.s	.lD156
	bra.s	.lD1B0
.lD152	cmp.w	a5,d6
	bgt.s	.lD15C
.lD156	cmp.w	a4,d6
	blt.s	.lD15C
	or.w	d4,d0
.lD15C	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	clr.w	d0
	addq.w	#1,d6
	ror.w	#1,d4
	bcs.s	.lD1B8
	lea	$9E(a0),a0
	add.w	d2,d5
	dbmi	d7,.lD0DA
	dbpl	d7,.lD148
	rts
.lD186	move.w	d0,d1
	not.w	d1
	SMC1_BODY	\1
	clr.w	d0
	subq.l	#2,a0
.lD19C	addq.w	#1,d6
	ror.w	#1,d4
	bcc.s	.lD1A4
	addq.l	#2,a0
.lD1A4	add.w	d3,d5
	dbmi	d7,.lD19C
	dbpl	d7,.lD1B0
	rts
.lD1B0	addq.w	#1,d6
	ror.w	#1,d4
	bcc.s	.lD1B8
	addq.l	#2,a0
.lD1B8	lea	$A0(a0),a0
	add.w	d2,d5
	dbmi	d7,.lD0DA
	dbpl	d7,.lD148
	rts
	ENDM

;==========================================================================

_base:	dc.l	_SMC1_A00-_base,_SMC1_A01-_base,_SMC1_A02-_base,_SMC1_A03-_base
	dc.l	_SMC1_A04-_base,_SMC1_A05-_base,_SMC1_A06-_base,_SMC1_A07-_base
	dc.l	_SMC1_A08-_base,_SMC1_A09-_base,_SMC1_A10-_base,_SMC1_A11-_base
	dc.l	_SMC1_A12-_base,_SMC1_A13-_base,_SMC1_A14-_base,_SMC1_A15-_base

	dc.l	_SMC1_B00-_base,_SMC1_B01-_base,_SMC1_B02-_base,_SMC1_B03-_base
	dc.l	_SMC1_B04-_base,_SMC1_B05-_base,_SMC1_B06-_base,_SMC1_B07-_base
	dc.l	_SMC1_B08-_base,_SMC1_B09-_base,_SMC1_B10-_base,_SMC1_B11-_base
	dc.l	_SMC1_B12-_base,_SMC1_B13-_base,_SMC1_B14-_base,_SMC1_B15-_base

	SMC1_FUNC	00
	SMC1_FUNC	01
	SMC1_FUNC	02
	SMC1_FUNC	03
	SMC1_FUNC	04
	SMC1_FUNC	05
	SMC1_FUNC	06
	SMC1_FUNC	07
	SMC1_FUNC	08
	SMC1_FUNC	09
	SMC1_FUNC	10
	SMC1_FUNC	11
	SMC1_FUNC	12
	SMC1_FUNC	13
	SMC1_FUNC	14
	SMC1_FUNC	15

;==========================================================================
