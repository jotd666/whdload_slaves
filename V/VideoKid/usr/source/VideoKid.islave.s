
		; VideoKid disk imager
		;
		; Written by JOTD (well, copied from Megatwins disk imager
        ; also by JOTD :))
		;
		; Sector format description:
		;
		; sync ($4489)
		; ???
		; sector data

		incdir	Include:
		include	RawDIC.i
	IFD BARFLY

		OUTPUT	"VideoKid.islave"

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
      
.passchk
		ENDC
        ENDC
        
		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text		dc.b	"VideoKid imager V1.0",10
		dc.b	"by JOTD on "
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
		dc.b	0
		cnop	0,4

DSK_1		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_DOUBLEINC	; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_2		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_DOUBLEINC	; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1
		TLENTRY	000,000,$1400,$4489,DMFM_STD
        TLENTRY	004,158,$1400,$4489,_DMFM
		TLENTRY	003,159,$1400,$4489,_DMFM
		TLEND
TL_2
		TLENTRY	000,000,$1400,$4489,DMFM_STD
		TLENTRY	001,001,$1400,$4489,DMFM_STD
		TLENTRY	002,156,$1400,$4489,_DMFM
		TLENTRY	003,073,$1400,$4489,_DMFM
		TLENTRY	083,153,$1400,$4489,_DMFM
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
	move.l	A0,A2
	move.l	A1,A6

	MOVE.L	#$55555555,D5
	CMPI	#$4489,(A2)+
	BEQ.S	.LAB_0027
	LEA	-2(A2),A2
.LAB_0027:
	MOVEA.L	A2,A0
	BSR	GetLong
	LEA	8(A2),A0
	BSR	GetLong
	MOVE.L	D0,D7
	LEA	16(A2),A0
	MOVE	#$2800,D1
	BSR	LAB_0028		;398: 61000024
	CMP.L	D0,D7			;3A4: BE80
	BNE.S	_ChecksumError

	LEA	16(A2),A0		;3A8: 41EA0008
	MOVE	#$1400,D0		;3AC: 303C1400
	BSR	PutLong		;3B0: 6100002C
	MOVEQ	#0,D4			;3BA: 7800

_OK
	moveq	#IERR_OK,d0
	rts



LAB_0028:
	LSR	#2,D1			;3BE: E449
	MOVE.L	(A0)+,D0		;3C0: 2018
	SUBQ	#2,D1			;3C2: 5541
LAB_0029:
	MOVE.L	(A0)+,D2		;3C4: 2418
	EOR.L	D2,D0			;3C6: B580
	DBF	D1,LAB_0029		;3C8: 51C9FFFA
	AND.L	D5,D0			;3CC: C085
	RTS				;3CE: 4E75


GetLong:
	MOVE.L	(A0)+,D0		;3D0: 2018
	MOVE.L	(A0)+,D1		;3D2: 2218
	AND.L	D5,D0			;3D4: C085
	AND.L	D5,D1			;3D6: C285
	ADD.L	D0,D0			;3D8: D080
	OR.L	D1,D0			;3DA: 8081
	RTS				;3DC: 4E75


PutLong:
	LEA	0(A0,D0.W),A1		;3DE: 43F00000
	LSR	#2,D0			;3E2: E448
	SUBQ	#1,D0			;3E4: 5340
LAB_002C:
	MOVE.L	(A0)+,D1		;3E6: 2218
	MOVE.L	(A1)+,D2		;3E8: 2419
	AND.L	D5,D1			;3EA: C285
	AND.L	D5,D2			;3EC: C485
	ADD.L	D1,D1			;3EE: D281
	OR.L	D2,D1			;3F0: 8282
	MOVE.L	D1,(A6)+		;3F2: 2CC1
	DBF	D0,LAB_002C		;3F4: 51C8FFF0
	RTS				;3F8: 4E75
	

_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts

