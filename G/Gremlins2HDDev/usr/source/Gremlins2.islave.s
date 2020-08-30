
		; Gremlins 2 imager
		;
		; Written by JOTD from Patcher slave by Mr Larmer
		;
		; Sector format description:
		;
		; sync ($A245) then sync2 ($4489)

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"Gremlins2.islave"

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text		dc.b	"Gremlins 2 imager V1.0",10
		dc.b	"by JOTD & Mr Larmer on "
		INCBIN	"T:date"
		dc.b	0
		cnop	0,4

DSK_1		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1		
		TLENTRY	000,000,$1600,$4489,DMFM_STD
		TLENTRY	001,133,$18A8,$A245,DMFM_G2
		TLEND

;======================================================================

; IN:	A0 = raw
;	A1 = dest
; OUT:	D0 = error

DMFM_G2
		lea	$7C00(a0),a5	;A5 = end of raw data
		subq.l	#2,a0
.sync4
		addq.l	#2,A0

		cmp.l	A0,A5
		bls.b	.error1

		move.l	(A0),D0

		cmp.w	#$4489,D0
		beq.b	.sync4

		addq.l	#4,A0

		moveq	#0,D4
		move.w	#$629,D7
.1
		bsr.b	.GetLongWords

		add.l	D0,D4
		move.l	D0,(A1)+
		dbra	D7,.1

		bsr.b	.GetLongWords

		not.l	D4
		cmp.l	D4,D0
		bne.b	.error2

		bra.b	.success

.success	moveq	#0,d0
.quit
		rts

.error1		moveq	#IERR_NOSYNC,d0
		bra.b	.quit
.error2		moveq	#IERR_CHECKSUM,d0
		bra.b	.quit

.GetLongWords
		move.l	$18AC(A0),D0
		swap	D0
		move.l	$18AE(A0),D1
		move.w	D1,D0

		move.l	(A0)+,D1
		swap	D1
		move.l	-2(A0),D2
		move.w	D2,D1

		and.l	#$55555555,D0
		and.l	#$55555555,D1
		add.l	D1,D1
		or.l	D1,D0

		rts



_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts

_NoSector	moveq	#IERR_NOSECTOR,d0
		rts
