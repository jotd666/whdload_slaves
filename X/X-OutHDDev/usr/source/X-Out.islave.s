
		; Prince Of Persia disk imager
		;
		; Written by JOTD
		;
		; Sector format description:
		;
		; sync ($8455)
		; word ($2AAA)
		; checksum
		; sector data

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"X-Out.islave"

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
Text		dc.b	"X-Out imager V1.0",10
		dc.b	"by JOTD on "
		INCBIN	"T:date"
		dc.b	0
		cnop	0,4

DSK_1		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_2		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1
		TLENTRY	002,159,$1750,$8455,_DMFM_XOut
		TLEND
TL_2
		TLENTRY	002,120,$1750,$8455,_DMFM_XOut
		TLEND

;======================================================================

_DMFM_XOut
		MOVEA.L	A0,A2			; MFM data

		cmp.w	#$2AAA,(A2)+
		bne	_NoSector

		addq.l	#2,a0

	MOVE.L	#$55555555,D3
	MOVE.L	(A2)+,D5

	AND.L	D3,D5			; checksum
	MOVEQ	#0,D1
	MOVE.L	#$0BA7,D0
.decodeloop1

	MOVE.L	(A2)+,D6

	AND.L	D3,D6
	ADD.L	D6,D1
	DBF	D0,.decodeloop1

	AND.L	D3,D1
	CMP.L	D1,D5
	BNE	_ChecksumError		; wrong checksum

	MOVE.L	#$05D3,D0		;1D6: 303C05D3
	LEA	4(A0),A2

.decodeloop2:
	MOVE.L	$1750(A2),D1		;1E0: 222A1750
	move.l	(A2)+,D2

	AND.L	D3,D1			;1E6: C283
	AND.L	D3,D2			;1E8: C483
	ASL.L	#1,D2			;1EA: E382
	OR.L	D2,D1			;1EC: 8282
	MOVE.L	D1,(A1)+		;1EE: 22C1
	DBF	D0,.decodeloop2


_OK		moveq	#IERR_OK,d0
		rts

_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts


_NoSector	moveq	#IERR_NOSECTOR,d0
		rts

