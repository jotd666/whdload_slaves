;**********************************************************************
;**********************************************************************
;****** Ishar 1 aga 2 manual protection removed ( 1 tested) good ******
;**********************************************************************
;**********************************************************************
;Check3		; same protection of check 3 of transarctica same key&offset
;$18(A6).b	; start of protection Word list crypted
;$14(A6).w	; LG max each word ($f)
;$D8(A6).b	; num of word in list asked
;$D9(a6).b	; count for 3 trials (1,2,3)
;$94(a6).b	; Start of typed word by user (dest buffer)
;$40		; decrypt word key  (at $13(a6) if try count to 0 =>$D9.b=0
;***************************************

      IFD CRACK_CF      ; others crack  ISHAR  improment of good PDX  manual protection remover X2

_pdxCrack
	TST.B	(A3)
	BNE.B	.skip
	CMPI.B	#3,(1,A3)
	BNE.B	.skip
	CMPI.B	#$1A,(2,A3)
	BEQ.B	.testChk2

	CMPI.B	#$1B,(2,A3)
	BNE.B	.skip
	CMPI.B	#6,(-2,A3)
	BNE.B	.skip
	CMPI.B	#2,(-3,A3)
;	BNE.B	.skip
	beq	.foundChk
	BRA.B	.skip

.testChk2
	CMPI.B	#5,(-2,A3)
	BNE.B	.skip
	CMPI.B	#2,(-3,A3)
	BNE.B	.skip

.foundChk
	IFD _FlashInProtection
.t	move.w	#$f0,$dff180
	btst #6,$bfe001
	bne .t
	ENDC
; check1&2 remove CF!
	MOVEM.l	D0/A0-A3,-(SP)
	clr.l	d0
	MOVE.b	$D8(a6),d0	; word position
	mulu	#$f,d0
	
	lea	$18(a6),a0
	add.l	d0,a0	; stard good word in word list
	lea	$94(a6),a1	;input buffer
	
	clr.l	d0

.enc	move.b	(a0)+,d0	
	tst.b	d0
	beq	.end
	add.b	#$40,d0		; crypt key
	move.b	d0,(a1)+
	bra	.enc

.end
	move.b #$d,(a1)+
	clr.b (a1)	
	MOVEM.l	(SP)+,D0/A0-A3


.skip
	MOVE.B	(A3)+,D0
	EXT.W	D0
	RTS

      ENDC

;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
  
