;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
; ISHAR AGA Memory Trainer
;------------------
; Seek in CHIP MEMORY: 'ARAMIR'
; Start= adress of first 'ARAMIR' letter
; or START = $5BB56 on 69320 & 68030 in WHD
; or Start = $5C756 on 68040 & 68060 (+$c00) in WHD
;
; Start+$42.W  coins 	1 to 7FFF (32767) 	1 for 1000 coins	; 5C798
; Start+$36.W  vitality	1 TO 7FFF (32767)				; 5C78D
; Start+$1B0.B Physical	1 TO 7F   (127)			 		; 5C906
; Start+$1A8.B Mental	1 TO 7F   (127)					; 5C

;**********************************************************************
;**********************************************************************

_Trainer
        movem.l	D0-a6,-(sp)
        LSL.L   #2,D0
        MOVE.L  D0,A0
        MOVE.L  (A0),D0
        LSL.L   #2,D0
        MOVE.L  D0,A0

	IFD _FlashHunk1
.t
	move.w	#$f0,$dff180
	btst	#6,$bfe001
	bne	.t
	ENDC

		move.l	_custom1(pc),d2
		tst.l	d2
		beq	.noTrainer
      

;----------------------
          	cmp.l 	#$12D866FC,$66D0(a0)    ; $34F7c
          	bne	.pas1T
           	pea	_TrainerTakeAdrBase(pc)
          	move.w	#$4ef9,$66D0(a0)
             	move.l	(a7)+,$66D0+2(a0)

.pas1T

;----------------------
             cmp.l 	#$3E1C3387,$66AA(a0)    ; $34F56
             bne	.pas1
             pea	_TrainerCodeW(pc)
             move.w	#$4ef9,$66Aa(a0)
             move.l	(a7)+,$66aa+2(a0)

.pas1

;----------------------
;             cmp.l 	#$3E1C1387,$66AA-$1c(a0)	; 34F3A
;             bne	.pas1b
;             pea	_TrainerCodeB(pc)
;             move.w	#$4ef9,$66Aa-$1c(a0)
;             move.l	(a7)+,$66aa-$1c+2(a0)
;
;.pas1b


;----------------------
             cmp.l 	#$3E1CDF31,$66AA+$276(a0)	; 351CC
             bne	.pas1t
             pea	_TrainerCodeAddB(pc)
             move.w	#$4ef9,$66Aa+$276(a0)
             move.l	(a7)+,$66aa+$276+2(a0)

.pas1t
;----------------------
.noTrainer
        movem.l	(sp)+,D0-A6
	rts

;*************************************************************
;*************************************************************

;**********************************************************************
;**********************************************************************

dec040	=$c00

_TrainerAdr	dc.l	0

_TrainerTakeAdrBase
	cmp.l	#'ARAM',(a0)		; aramir?
	bne	.nofound	
	move.l	a0,-(sp)
	lea	_TrainerAdr(pc),a0
	move.l	a1,(a0)
	move.l 	(a7)+,a0
.nofound

.enc	move.b	(a0)+,(a1)+
	bne	.enc
	rts

_TrainerCodeW
	IFD _FlashTrainer
.t
	move.w	#$f0,$dff180
	btst	#6,$bfe001
	bne	.t

	ENDC

	move.w	(a4),D7
;--------------------------
	movem.l	d0-D3/A2-a4,-(sp)
	move.l a1,a4
	ext.l	d0
	add.l d0,a4

;-------------------------	
	move.l	_TrainerAdr(pc),a3
	tst.l	(a3)
	beq	.skip

	move.l	_custom1(pc),d3

;	CLR.L D2
	moveq	#4,D2
.ENC
	BTST	#3,D3
	BEq	.pasC
	lea	$42(a3,D2.L*2),a2	; coins
	bsr	_TrainGenW
	lea	(a3,D2.L*2),a2	; coins
	add.l	#$2264,a2
	bsr	_TrainGenW
.pasC
	BTST	#0,D3
	BEq	.pasV
	lea	$36(a3,D2.L*2),a2	; vitality
	cmp.w 	#0,d7		; PL reset leave it
	beq .noPL
	cmp.w	#0,(a2)
	beq .noPL
	move.w	#$ff,(a2)		; froce vitalité to remove freeze bug
	bsr	_TrainGenW
.noPL
.pasV	DBF	D2,.ENC
;------------------------
;----------------------------
.skip	movem.l	(sp)+,d0-d3/A2-a4
;--------------------------
	;move.w	(a4)+,d7	; stolen code
	move.w	d7,(0,a1,d0.w)  ; stolen code
	move.w	(a4)+,d7	; stolen code
	rts


;--------------------------

_TrainGenW
	cmp.l	a2,a4
	bne	.non
	cmp.w	(A4),d7
	bgE 	.non	
	move.w	(a4),d7
.non	rts

_TrainGenB
	cmp.l	a2,a4
	bne	.non
	cmp.b	(A4),d7
	bgE 	.non	
	move.b	(a4),d7
.non	rts

_TrainGenAddB
	cmp.l	a2,a4
	bne	.non
	move.b (a4),D1
	add.b d7,D1
	cmp.b (a4),D1
	bgE 	.non	
	sub.b	d7,(a4)
.non	rts
;********************************************************************** Not needed
_TrainerCodeB
	IFD _FlashTrainer
.t
	move.w	#$f0,$dff180
	btst	#6,$bfe001
	bne	.t

	ENDC

	move.w	(a4),d7
;--------------------------
	movem.l	d0-d2/a2-a4,-(sp)
	move.l a1,a4
	ext.l	d0
	add.l d0,a4

;-------------------------	
	move.l	_TrainerAdr(pc),a3
	tst.l	(a3)
	beq	.skip

	move.l	_custom1(pc),d3

	CLR.L D2
	moveq	#4,D2
.ENC
	BTST	#2,D3
	BEq	.pasM
	lEA	$1A8(a3),a2	; MENTAL
	ADD.L	D2,A2
	bsr	_TrainGenB
.pasM
	BTST	#1,D3
	BEq	.pasP
	lEA	$1B0(a3),a2	; PHYSICAL
	ADD.L	D2,A2
	bsr	_TrainGenB
.pasP	DBF	D2,.ENC
;------------------------

.skip	movem.l	(sp)+,d0-D2/a2-a4

;--------------------------
;	move.w	(a4)+,d7	; stolen code
	move.b	d7,(0,a1,d0.w)  ; stolen code
	move.w	(a4)+,d7	; stolen code
	rts
;**********************************************************************
;**********************************************************************
_TrainerCodeAddB
	IFD _FlashTrainer
.t
	move.w	#$f0,$dff180
	btst	#6,$bfe001
	bne	.t

	ENDC
	move.w	(a4),d7
;--------------------------
	movem.l	d0-D2/a2-a4,-(sp)
	move.l a1,a4
	ext.l	d0
	add.l d0,a4

;-------------------------	
	move.l	_TrainerAdr(pc),a3
	tst.l	(a3)
	beq	.skip

	move.l	_custom1(pc),d3

;	CLR.L	D2
	moveq	#4,D2
.ENC
	BTST	#2,D3
	BEq	.pasM
	lEA	$1A8(a3),a2	; MENTAL
	ADD.L	D2,A2
	bsr	_TrainGenAddB
.pasM
	BTST	#1,D3
	BEq	.pasP
	lEA	$1B0(a3),a2	; PHYSICAL
	ADD.L	D2,A2
	bsr	_TrainGenAddB
.pasP	DBF	D2,.ENC
;------------------------
.pas020

;----------------------------
.skip	movem.l	(sp)+,d0-D2/a2-a4
	;move.w	(a4)+,d7	; stolen code
	add.b	d7,(0,a1,d0.w)  ; stolen code
	move.w	(a4)+,d7	; stolen code
	rts

;**********************************************************************
;**********************************************************************
;**********************************************************************

