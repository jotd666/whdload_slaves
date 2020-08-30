
		; Agony imager (Barfly assembler source)
		;
		; Written by JOTD, original disk reader by Harry
		;
		; Sector format description:
		;

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"Agony.islave"

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

TRACK_LENGTH = $1800

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0       ; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text		dc.b	"Agony imager V1.0",10
		dc.b	"by JOTD/Harry on "
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

DSK_2		dc.l	DSK_3		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_3		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_3		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read



TL_1
	TLENTRY	002,108,TRACK_LENGTH,SYNC_INDEX,DMFM_Agony
	TLEND
TL_2
	TLENTRY	002,155,TRACK_LENGTH,SYNC_INDEX,DMFM_Agony
	TLEND
TL_3
	TLENTRY	000,152,TRACK_LENGTH,SYNC_INDEX,DMFM_Agony
	TLEND

; A0: raw
; A1: decoded

DMFM_Agony:
	; for each unloaded sector 1 bit in d7
	MOVE.L	#$FFF,D7		;$C SECTORS
.NEXTSEC
.FIRST	
	MOVE.W	#$4522,D0		;GET PRESYNC & IDWORDCHECK
	jsr	rawdic_NextMFMword(a5)
	move.l	a0,a2
	MOVE.L	(A2),D0
	CMP.W	#$5122,D0
	BNE.S	.FIRST
.ANF
	move.w	D7,$100.W
	MOVE.W	#$5122,D0		;get main sync
	jsr	rawdic_NextMFMword(a5)
	move.l	a0,a2

	BSR	DecodeLong

	SWAP	D0
	SUB.W	#$FF31,D0
	CMP.W	#$C,D0
	BHS.S	.ANF
	BCLR	D0,D7			;REMOVE SECTOR FROM 'TOLOAD'-TABLE
	BEQ.S	.NOTAGAIN		;SKIP ALREADY DECODED SECTOR
	MOVE.W	D0,D1			;SECTORNR.
	LSL.L	#8,D1
	LSL.L	#1,D1			;MULU #200,D1
	LEA.L	(A1,D1.W),A3
	SWAP	D0
	MOVE.W	D0,-(A7)
	MOVEQ	#$00,D2
	MOVEQ	#$7F,D3
.REP
	BSR	DecodeLong

	MOVE.L	D0,(A3)+

	ADD.W	D0,D2
	SWAP	D0
	ADD.W	D0,D2
	DBF	D3,.REP
	MOVE.W	(A7)+,D0
	CMP.W	D2,D0
	BNE.W	_ChecksumError
.NOTAGAIN
	TST.L	D7
	BNE.S	.ANF

	moveq	#IERR_OK,d0
	rts

;AGONY IS A SECTORIZED DISK WITH $C SECTORS OF $200 BYTE

DecodeLong
	MOVEM.L	D1/D4,-(A7)
	MOVE.L	(A2)+,D0
	MOVE.L	(A2)+,D1
	ASL.L	#1,D0
	ANDI.L	#$AAAAAAAA,D0
	ANDI.L	#$55555555,D1
	OR.L	D1,D0
	MOVEM.L	(A7)+,D1/D4
	RTS	

_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts
