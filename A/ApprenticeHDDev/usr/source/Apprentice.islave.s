

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i

	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Apprentice imager V1.0",10
	dc.b	"by Ralf & JOTD "
	dc.b	"(02.01.2021)",0
	CNOP	0,4



.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_NORESTRICTIONS		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

TRACK_SIZE = $1838
.tracks
    TLENTRY	000,000,$1600,$4489,DMFM_STD
    TLENTRY	000,000,TRACK_SIZE-$1600,$4489,DMFM_NULL    ; so same track size
	TLENTRY	001,159,TRACK_SIZE,$4489,decode
	TLEND


; a0.l: mfm data
; a1.l: destination

; adapted from Ralf ripping code
decode
	CMP	#$2AAA,(A0)+
	BNE	.sector_error

	MOVE.L	#TRACK_SIZE/4-1,D5
	MOVEQ	#0,D4
	MOVE.L	#$55555555,D3
	
.DECODE_TRACK
	MOVE.L	(A0)+,D0
	MOVE.L	(A0)+,D1

	AND.L	D3,D0
	AND.L	D3,D1
	ADD.L	D0,D0
	OR.L	D1,D0

	ADD.L	D0,D4
	MOVE.L	D0,(A1)+
	
	DBF	D5,.DECODE_TRACK

	MOVE.L	(A0)+,D0
	MOVE.L	(A0)+,D1

	AND.L	D3,D0
	AND.L	D3,D1
	ADD.L	D0,D0
	OR.L	D1,D0
	
	CMP.B	D0,D4
	BEQ	.TRACK_OK

.TRACK_ERROR
	MOVEQ	#IERR_CHECKSUM,D0
	RTS
.TRACK_OK
	moveq	#IERR_OK,d0
	rts


.sector_error
	moveq	#IERR_NOSECTOR,d0
	rts


