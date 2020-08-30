
		; Prince Of Persia disk imager
		;
		; Written by JOTD
		;
		; Sector format description:
		;
		; sync ($4891)
		; word ($44A9)
		; side (ignored)
		; sector data

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"PrinceOfPersia.islave"

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
Text		dc.b	"Prince Of Persia imager V1.0",10
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
		TLENTRY	001,084,$1800,$4891,_DMFM_Prince
		TLEND

;======================================================================

_DMFM_Prince
		MOVEA.L	A0,A2			; MFM data
		MOVEA.L	A1,A3			; destination?

		subq.l	#2,A2

		cmp.w	#$44A9,2(A2)
		bne	_ChecksumError

		MOVE	#$0008,D0		;294: 303C0008
		LEA	4(A2),A0		;298: 41EA0004
		MOVEA.L	A0,A1			;29C: destination
		BSR	_DecodeBytes		;29E: 61000378
		MOVE	#$3008,D0		;2A2: 303C3008
		LEA	12(A2),A0		;2A6: 41EA000C
		BSR	LAB_003F		;2AA: 610003B6
		CMP.L	4(A2),D0		;2AE: B0AA0004
		bne	_ChecksumError

	MOVE	#$0008,D0		;2B4: 303C0008
	LEA	12(A2),A0		;2B8: 41EA000C
	MOVEA.L	A0,A1			;2BC: 2248
	BSR	_DecodeBytes		;2BE: 61000358

;	MOVE.L	(A0),D0			;2C2: 2010
;	CMP	_side(PC),D0		;2C4: B07AFDEE
;	BNE.S	LAB_001C		; side check, skipped

	MOVE	#$3000,D0		;2CA: 303C3000
	LEA	20(A2),A0		;2CE: 41EA0014
	MOVEA.L	A3,A1			;2D2: 224B
	CMPA.L	#$00000000,A1		;2D4: B3FC00000000
	BEQ.S	_OK		;2DA: 6704
	BSR	_DecodeBytes		;2DC: 6100033A

_OK		moveq	#IERR_OK,d0
		rts

_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts

LAB_003F:
	MOVEM.L	D1-D2/A0,-(A7)		;662: 48E76080
	MOVE	D0,D1			;666: 3200
	LSR	#2,D1			;668: E449
	SUBQ	#1,D1			;66A: 5341
	MOVEQ	#0,D0			;66C: 7000
.LAB_0040:
	MOVE.L	(A0)+,D2		;66E: 2418
	EOR.L	D2,D0			;670: B580
	DBF	D1,.LAB_0040		;672: 51C9FFFA
	ANDI.L	#$55555555,D0		;676: 028055555555
	MOVEM.L	(A7)+,D1-D2/A0		;67C: 4CDF0106
	RTS				;680: 4E75

; < A0: MFM data
; < A1: pointer on destination
; < D0: offset?

_DecodeBytes:
	MOVEM.L	D0-D2/A0-A2,-(A7)	;618: 48E7E0E0
	MOVEA.L	A0,A2			;61C: 2448
	LSR	#1,D0			;61E: E248
	ADDA	D0,A2			;620: D4C0
	LSR	#1,D0			;622: E248
	SUBQ	#1,D0			;624: 5340
.LAB_003E:
	MOVE	(A0)+,D1		;626: 3218
	ANDI	#$5555,D1		;628: 02415555
	ASL	#1,D1			;62C: E341
	MOVE	(A2)+,D2		;62E: 341A
	ANDI	#$5555,D2		;630: 02425555
	OR	D2,D1			;634: 8242
	MOVE	D1,(A1)+		;636: 32C1
	DBF	D0,.LAB_003E		;638: 51C8FFEC
	MOVEM.L	(A7)+,D0-D2/A0-A2	;63C: 4CDF0707
	RTS	

_NoSector	moveq	#IERR_NOSECTOR,d0
		rts

_side:
	dc.w	0
