
_FAST

	IFD	_FAST
CHIPMEMSIZE     = $80000+$10000*0
FASTMEMSIZE     = $40000*1
	ELSE
CHIPMEMSIZE     = $90000
FASTMEMSIZE     = $40000*0
	ENDC

	IFD	_FAST
	ELSE
	ENDC

_FlashHunk

	IFD	_FlashHunk
.t	move.w	#$f0,$dff180
	btst	#6,$BFE001
	BNE	.t	
	ENDC

;============================================================================
;**********************************************************************
;**********************************************************************
;**********************************************************************

_DEC_M1		=$1C8	; LOOKING FOR: 34 39 00 DF F0 1E
_DEC_M2		=$5CC	; LOOKING FOR: 2C 78 00 04 32 28 00 1C OR 2C 79 00 00 00 04 32 28 00 1C
_DEC_M2bis	=$5C4	; IDEM

_FixMusic
		 move.l d7,d0
		movem.l	d0/A0,-(a7)
                lsl.l   #2,d0
                move.l  d0,a0
                move.l  (a0)+,a0                ;a1 = hunk1
                add.l   a0,a0
                add.l   a0,a0
                move.l  (a0)+,a0                ;a2 = hunk2
                add.l   a0,a0
                add.l   a0,a0
                move.l  (a0)+,a0                ;a2 = hunk2
                add.l   a0,a0
                add.l   a0,a0
                move.l  (a0)+,a0                ;a2 = hunk2
                add.l   a0,a0
                add.l   a0,a0
                move.l  (a0),d0                ;a3 = hunk3

                cmp.l #$343900DF,_DEC_M1(a0)	; GB V1
                bne .pas
		move.w	#$4EB9,_DEC_M1(a0)		; 34 39 00 DF F0 1E
		pea	_PatchIntroSound(pc)
		move.l	(a7)+,_DEC_M1+2(a0)
		move.l	#$4E714E71,_DEC_M1+6(a0)
		move.w	#$4E71,_DEC_M1+10(a0)
.pas
;----------------------
                cmp.l #$2C780004,_DEC_M2(a0)	; FR V1, EN/DE V1
                bne .pas1
		move.w	#$4EB9,_DEC_M2(a0)		; 2C 78 00 04 32 28 00 1C or 2C 79 00 00 00 04 2C 78 00 1C
		pea	_PatchMusic(pc)		; Silmarils game before 1992
		move.l	(a7)+,_DEC_M2+2(a0)
		move.w	#$4E71,_DEC_M2+6(a0)
.pas1
;----------------------
                cmp.l #$2C780004,_DEC_M2bis(a0)	; idem variance
                bne .pas2
		move.w	#$4EB9,_DEC_M2bis(a0)
		pea	_PatchMusic(pc)
		move.l	(a7)+,_DEC_M2bis+2(a0)
		move.w	#$4E71,_DEC_M2bis+6(a0)
.pas2
		movem.l	(a7)+,d0/A0
                rts


_PatchIntroSound
			;move.w	#$0f0f,($dff180)
			movem.l	a0,-(a7)
			lea	$dff000,a0
			MOVE.B	6(a0),d2
.line			cmp.b	6(a0),d2
			beq .line
.wait			cmp.b	#$16,7(a0)
			bcs .wait
			move.w	$1E(a0),d2
			and.w	$1c(a0),d2
			movem.l	(a7)+,a0

			;move.w	$dff01e,d2
			;and.w	$dff01c,d2
			rts

_PatchMusic
			;move.w	#$0ff,($dff180)
			MOVE.B	6(a0),d1
.line			cmp.b	6(a0),d1
			beq .line
.wait			cmp.b	#$16,7(a0)
			bcs .wait
			move.w	$1C(a0),D1
			rts

;**********************************************************************
;**********************************************************************
;**********************************************************************
