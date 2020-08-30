
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

_DEC_M1		=$190A	;LOOKING FOR:	34 39 00 DF F0 1E
_DEC_M2		=$1D98	;LOOKING FOR:	4a 39 00 BF DD 00


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
;                move.l  (a0)+,a0                ;a2 = hunk2
;                add.l   a0,a0
;                add.l   a0,a0
;                move.l  (a0)+,a0                ;a2 = hunk2
;                add.l   a0,a0
;                add.l   a0,a0
                move.l  (a0),d0                ;a3 = hunk3

                cmp.l #$343900DF,_DEC_M1(a0)	;EN V1
                bne .pas
		move.w	#$4EB9,_DEC_M1(a0)	; 34 39 00 DF F0 1E
		pea	_PatchIntroSound(pc)
		move.l	(a7)+,_DEC_M1+2(a0)
		move.l	#$4E714E71,_DEC_M1+6(a0)
		move.w	#$4E71,_DEC_M1+10(a0)
.pas
;----------------------

                cmp.l #$4A3900BF,_DEC_M2(a0)	;  4A 39 00 BF DD 00 (silmarils game after 1992)
                bne .pas3
		move.w	#$4EB9,_DEC_M2(a0)
		pea	_PatchMusic2(pc)
		move.l	(a7)+,_DEC_M2+2(a0)

		cmp.w	#$0098,_DEC_M2-$AA(a0)
		bne	.pas3
		move.w	#200,_DEC_M2-$AA(a0)	; timer $a8-200
.pas3
		movem.l	(a7)+,d0/A0
                rts


_PatchIntroSound
;			move.w	#$0f0f,($dff180)
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

_PatchMusic2
			;move.w	#$0f0f,($dff180)
			tst.b	$bfdd00
			movem.l	d1/a3,-(a7)
			lea $dff000,a3
			MOVE.B	6(a3),d1
.line			cmp.b	6(a3),d1
			beq .line
.wait			cmp.b	#$16,7(a3)
			bcs .wait
			movem.l (a7)+,D1/a3
			rts


;**********************************************************************
;**********************************************************************
;**********************************************************************
