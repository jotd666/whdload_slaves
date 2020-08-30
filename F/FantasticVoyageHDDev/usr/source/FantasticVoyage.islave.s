
		; Fantastic Voyage disk imager
		;
		; Written by JOTD
		;
		; Sector format description:
		;
		; sync ($4489)
		; word ($4D48)
		; track number or something like this (ignored)
		; sector data

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"FantasticVoyage.islave"

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
Text		dc.b	"Fantastic Voyage imager V1.0",10
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
;		TLENTRY	000,000,$400,$4489,DMFM_STD
TL_2
		TLENTRY	002,159,$1800,$4489,_DMFM_Fantastic
		TLEND


;======================================================================

_DMFM_Fantastic
	MOVEA.L	A0,A2			; MFM data

	addq.l	#2,A2

	MOVE.L	(A2)+,D2		;01DC: 241A
	MOVE.L	(A2)+,D3		;01DE: 261A

	move.l	D2,$100.W
	move.l	D3,$104.W

	CLR.L	-8(A2)			;01E0: 42AAFFF8
	CLR.L	-4(A2)			;01E4: 42AAFFFC
	ANDI.L	#$55555555,D2		;01E8: 028255555555
	ANDI.L	#$55555555,D3		;01EE: 028355555555
	LSL.L	#1,D2			;01F4: E38A
	OR.L	D3,D2			;01F6: 8483
	CMPI	#$4D48,D2		;01F8: 4D48 id a retrouver
	BNE.S	_NoSector
	SWAP	D2			;01FE: 4842
	MOVE.B	D2,D0			;0200: 1002
	LSR	#8,D2			;0202: E04A
;	CMP.B	length_to_read+2(PC),D2	;0204: B43A0204
;	BNE.S	LAB_0006		;0208: 669C
LAB_0008:
	MOVE.L	(A2)+,D1		;0220: 221A
	MOVE.L	(A2)+,D3		;0222: 261A
	CLR.L	-8(A2)			;0224: 42AAFFF8
	CLR.L	-4(A2)			;0228: 42AAFFFC
	ANDI.L	#$55555555,D1		;022C: 028155555555
	ANDI.L	#$55555555,D3		;0232: 028355555555
	LSL.L	#1,D1			;0238: E389
	OR.L	D3,D1			;023A: 8283
;;	MOVEA.L	LAB_001F(PC),A1		;023C: 227A01C6
	MOVE	length_to_read(PC),D4		;0240: 383A01C6
	LSR	#2,D4			;0244: E44C
	SUBQ	#1,D4			;0246: 5344
	CLR.L	D0			;0248: 4280
LAB_0009:
	MOVE.L	(A2)+,D2		;0260: 241A
	MOVE.L	(A2)+,D3		;0262: 261A
	CLR.L	-8(A2)			;0264: 42AAFFF8
	CLR.L	-4(A2)			;0268: 42AAFFFC
	ANDI.L	#$55555555,D2		;026C: 028255555555
	ANDI.L	#$55555555,D3		;0272: 028355555555
	LSL.L	#1,D2			;0278: E38A
	OR.L	D3,D2			;027A: 8483
	MOVE.L	D2,(A1)+		;027C: 22C2
	ADD.L	D2,D0			;027E: D082
	DBF	D4,LAB_0009		;0280: 51CCFFC8
	CMP.L	D0,D1			;0284: B280
	BNE	_ChecksumError

_OK		moveq	#IERR_OK,d0
		rts

_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts


_NoSector	moveq	#IERR_NOSECTOR,d0
		rts

length_to_read
	dc.w	$1800
