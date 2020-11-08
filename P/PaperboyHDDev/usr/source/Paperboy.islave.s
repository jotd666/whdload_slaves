
		; Paperboy disk imager
		;
		; Written ???? by Jean-François Fabre. Thanks to Codetapper/Action!
		;
		; Sector format description:
		;
		; sync ($A245)
		; word (track number ???)
		; sector data

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"Paperboy.islave"

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
Text		dc.b	"Paperboy imager V1.0",10
		dc.b	"by JOTD on "
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
		TLENTRY	000,000,$1700,SYNC_STD,DMFM_STD
		TLENTRY	001,113,$1700,$A245,_DMFM_Paperboy
		TLEND

;======================================================================

_DMFM_Paperboy
		move.l	a0,a4			;a4 = MFM data
		move.l	a1,a2			;a2 = Destination

		move.l	#$55555555,D2
		lea	2(a4),a0
		MOVE	(A0)+,D0
		MOVE	(A0)+,D1
		AND.L	D2,D0
		AND.L	D2,D1
		ADD.L	D0,D0
		OR.L	D1,D0

		; here D0 = sector no (MSW)

		; now we decode

		MOVE.L	#$5BF,D3
		MOVEQ.L	#-1,D4

.DECODE_LOOP
		MOVE.L	$1704(A0),D1
		MOVE.L	(A0)+,D0

		AND.L	D2,D0
		AND.L	D2,D1
		ADD.L	D0,D0
		OR.L	D1,D0

		SUB.L	D0,D4
	
		MOVE.L	D0,(A2)+
		DBF	D3,.DECODE_LOOP

		MOVE.L	$1704(A0),D1
		MOVE.L	(A0)+,D0

		AND.L	D2,D0
		AND.L	D2,D1
		ADD.L	D0,D0
		OR.L	D1,D0
	
		CMP.L	D0,D4
		bne	_ChecksumError

_OK		moveq	#IERR_OK,d0
		rts

_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts

_NoSector	moveq	#IERR_NOSECTOR,d0
		rts
