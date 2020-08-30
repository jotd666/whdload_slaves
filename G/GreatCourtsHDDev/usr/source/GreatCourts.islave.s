
		; Great Courts / Pro Tennis Tour disk imager
		;
		; Written by JOTD
		;
		; Sector format description:
		;
		; sync ($5542)
		; track number
		; sector data
		;
		; there is no serious checksum !

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"GreatCourts.islave"

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
Text		dc.b	"Great Courts/Pro Tennis Tour imager V1.0",10
		dc.b	"by JOTD on "
		INCBIN	"T:date"
		dc.b	0
		cnop	0,4

DSK_1		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_DOUBLEINC	; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1
		TLENTRY	003,143,$1790,$5542,_DMFM
		TLENTRY	002,156,$1790,$5542,_DMFM
		TLEND

;======================================================================

 ; tle_Decoder: A pointer to a subroutine which is called after the MFM data of
 ;		a track has been read.
 ;		Put your MFM track to RAW track conversion routines here!!!

 ;		A0=MFM data
 ;		A1=trackbuffer
 ;		A5=RawDIC library base
 ;              D0.w=tracknumber
 ;              => D0.l=errorcode


_DMFM
	; D7 = track number used to checksum the track, ignored
	ANDI.L	#$000000FF,D7		;084E: 0287000000FF

	ADDQ.L	#2,A0			;085A: 5489
	MOVE.L	(A0)+,D0		;085C: 2019
	MOVE.L	(A0)+,D1		;085E: 2219

	ANDI.L	#$55555555,D0		;0860: 028055555555
	ANDI.L	#$55555555,D1		;0866: 028155555555
	LSL.L	#1,D0			;086C: E388
	OR.L	D1,D0			;086E: 8081
	ROL.L	#8,D0			;0870: E198

;	CMP.B	D7,D0			;0872: B007
;	BNE.S	LAB_0038		;0874: 6636

	ROL.L	#8,D0			;0876: E198
	CMP.B	#1,D0			
	BNE.S	_ChecksumError
	MOVE.L	#$000005E3,D7		;0884: 2E3C000005E3
.LAB_0037:
	MOVE.L	(A0)+,D0		;088A: 2019
	MOVE.L	(A0)+,D1		;088C: 2219
	ANDI.L	#$55555555,D0		;088E: 028055555555
	ANDI.L	#$55555555,D1		;0894: 028155555555
	LSL.L	#1,D0			;089A: E388
	OR.L	D1,D0			;089C: 8081
	MOVE.L	D0,(A1)+		;089E: 20C0
	DBF	D7,.LAB_0037		;08A0: 51CFFFE8
_OK		moveq	#IERR_OK,d0
		rts

_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts

