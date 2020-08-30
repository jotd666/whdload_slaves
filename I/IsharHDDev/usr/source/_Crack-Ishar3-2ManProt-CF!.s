
;***************************************
;******** ISHAR 2 AGA/ECS *********
;***** remove 2 manual protections ****
;***************************************
;**** Manual protection Crack Info *****
;***************************************
;Check1 & Check 2
;$5E(A6).b	; start of protection Word list crypted
;$5A(A6).w	; LG max each word ($f)
;$114(A6).b	; num of word in list asked
;$??(a6).b	; count for 3 trials (1,2,3)
;$CE(aà).b	; Start of typed word by user (dest buffer)
; $24		; decrypt word key

;***************************************
;***************************************
;***************************************
	IFD CRACK_CF
;***************************************
;***************************************
;***************************************
_crack	; CFOU (good)
	; (2 manual protections removed)
	; =>just press 'return' key
;***************************************
;***************************************
;***************************************
	; Check 1&2
	move.l	(a1),d0
	LSL.L	#2,D0
	ADDQ.L	#4,D0

	MOVE.L	D0,A0
	ADD.L	#$2632,A0
	cmp.l	#$101b4880,(a0)
	bne .pas
	MOVE.W	#$4EB9,(A0)+
	PEA	_prepcrack(PC)
	MOVE.L	(SP)+,(A0)
.pas	RTS

_prepcrack
	CMP.B	#7,-5(A3)
	BNE	.skip
	MOVEM.l	D0/A0-A3,-(SP)
	LEA	lbL00007E(PC),A2
	BSR	_test_data
	BNE	.sk1
	LEA	lbL00008E(PC),A2
	BSR	_test_data
	BEQ	.sk2
.sk1

 IFD	_FlashINCrack
.t	move.w	#$f0,$dff180
	btst #6,$BFE001
	bne .t
 ENDC
; check1&2 remove CF!

	clr.l	d0
	MOVE.b	$114(a6),d0	; word position
	mulu	#$f,d0
	
	lea	$5E(a6),a0
	add.l	d0,a0	; stard good word in word list
	lea	$cE(a6),a1	;input buffer
	
	clr.l	d0

.enc	move.b	(a0)+,d0	
	tst.b	d0
	beq	.end
	add.b	#$24,d0		; crypt key
	move.b	d0,(a1)+
	bra	.enc

.end
	move.b #$d,(a1)+
	clr.b (a1)	
.sk2	MOVEM.l	(SP)+,D0/A0-A3
.skip
	MOVE.B	(A3)+,D0
	EXT.W	D0
	SWAP	D0
	RTS

_test_data
	MOVE.L	A3,A0
	ADD.W	(A2)+,A0
	LEA	-4(A3),A1
	MOVEQ	#6,D0
.enc
	CMPM.B	(A1)+,(A2)+
	BNE	.fin2
	DBRA	D0,.enc

	MOVEQ	#-$1,D0
	RTS
.fin2
	MOVEQ	#0,D0
	RTS

lbL00007E
	dc.l	$02CE0001
	dc.l	$69070002
	dc.l	$AA9ADED6
	dc.l	$5EA0A68E
lbL00008E
	dc.l	$03670001
	dc.l	$7A070002
	dc.w	$BB00

.fin
	MOVEM.l	(SP)+,D0-D7/A0-A6

	ENDC
;***************************************
;***************************************
;***************************************
