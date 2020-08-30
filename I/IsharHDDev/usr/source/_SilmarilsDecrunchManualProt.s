slv_config	;DC.B	"C1:X:Unlimited energy:0;"
		DC.B	"BW;"
		dc.b	0

	        move.l  (_resload),a2           ;A2 = resload
       ;get tags
                lea     (_tag2,pc),a0
                jsr     (resload_Control,a2)


;**********************************************************************
;**********************************************************************
;**********************************************************************

_DEC_D1		=$6F60		; look for: 4A 36 6B 00 00 32
 
_PatchDecrunch
		
;--------------------------
        cmp.l	#$4a436b00,_DEC_D1(a0)		; version GB V1& V2
        bne	.pass
        cmp.w	#$0032,_DEC_D1+4(a0)
        bne	.pass
        MOVE.W  #$4EB9,_DEC_D1(A0)
        PEA     crackManual(PC)               ; prepare rip manual protection crack
        MOVE.L  (SP)+,_DEC_D1+$2(A0)
.pass
;--------------------------
	RTS
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************

crackManual
        tst.w d3
        bmi .findecomp
        rts
.findecomp
        add.l #4,a7     ; rippe rts

        movem.l (a7),d0-d7/a0-a6

	IFD	_FlashAfterDecrunch
.t2	move.w	#$f0,$dff180
	btst	#6,$bfe001
	bne .t2
	ENDC 

	move.l	d1,a2	; Lg of decrunched file
	add.l	A1,A2	; and of decrunched file

	move.l	_ButtonWait(pc),d2
	tst.l	D2
	beq	.cont
	cmp.l	#'djee',(a0)
	bne	.no
.wait
	bsr	_WaitButton
	bra	.cont
.no
	cmp.l	#'hero',(a0)
	beq	.wait

.cont
.pasfoundcrack
        add.l	#1,a1
        cmp.l	a2,a1
        beq	.nofoundfin
        CMP.b   #$4c,(A1)
        BNE.S   .pasfoundcrack
        CMP.b   #$36,1(A1)
        BNE.S   .pasfoundcrack
        CMP.b   #$3a,2(A1)
        BNE.S   .pasfoundcrack
        CMP.b   #$14,3(A1)
        BNE.S   .pasfoundcrack

	IFD	_FlashINManualProtect
.t	move.w	#$f0,$dff180
	btst	#6,$bfe001
	bne .t
	ENDC 

        MOVE.B  #$0a,$3(A1)             ; rippe protect
.nofoundfin
        movem.l (a7)+,d0-d7/a0-a6
        rts
;**********************************************************************
;**********************************************************************
_WaitDelay
	move.l	#$4FF,d2
.waitvbl:	
	;move.w	d2,$dff180

	move.l	$dff004,d0
	andi.l	#$1ff00,d0
;	cmp.l	#$13200,d0	; PAL
	cmp.l	#$10100,d0	; NTSc
	bne	.waitvbl
	DBF	d2,.waitvbl
	rts
;**********************************************************************
;**********************************************************************
_WaitButton
.enc
		btst	#7,$bfe001
		beq	.FIRE
		btst	#2,$dff016
		beq	.FIRE
		btst	#6,$dff016
		beq	.FIRE
		btst	#6,$bfe001
		bne	.enc
.FIRE		rts
;**********************************************************************
;**********************************************************************

_tag2
;		dc.l	WHDLTAG_CUSTOM1_GET
;_custom1	dc.l	0
;		dc.l	WHDLTAG_CUSTOM2_GET
;_custom2	dc.l	0
;		dc.l	WHDLTAG_CUSTOM3_GET
;_custom3	dc.l	0
;		dc.l	WHDLTAG_CUSTOM4_GET
;_custom4	dc.l	0
;		dc.l	WHDLTAG_CUSTOM5_GET
;_custom5	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
_ButtonWait	dc.l	0

		dc.l	0
;**********************************************************************
;**********************************************************************
