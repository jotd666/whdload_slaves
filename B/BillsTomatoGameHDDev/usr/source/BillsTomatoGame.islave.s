
		; Bill Tomato's Game disk imager
		;
		; Written by JOTD
		;
		; Sector format description:
		;
		; sync ($4489)

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"BillsTomatoGame.islave"

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
Text		dc.b	"Bill's Tomato Game imager V1.0",10
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
		TLENTRY	002,157,$1800,$4489,DMFM_BTG
		TLEND

;======================================================================

DMFM_BTG
		MOVEA.L	A0,A3			; MFM data
		MOVEA.L	A1,A2			; destination

		moveq	#0,d0
.loop
		movem.l	D0/A2/A3,-(sp)
		bsr	decode
		movem.l	(sp)+,D0/A2/A3

		LEA	$200(A2),A2

		tst.B	D7
		bne	_ChecksumError

		add.b	#1,D0
		cmp.b	#12,D0
		bne.b	.loop


_OK		moveq	#IERR_OK,d0
		rts

_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts

_NoSector	moveq	#IERR_NOSECTOR,d0
		rts

decode:
	MULU	#$0410,D0		
	ADDA	D0,A3
	MOVEA.L	A3,A0
	BSR	DecodeLong
	SWAP	D0			;0DF6: 4840
	CMPI	#$5046,D0		;0DF8: 0C405046
	BNE	decodeerror
	LEA	16(A3),A0		;0E00: 41EB0010
	MOVE.L	#$00000400,D0		;0E04: 203C00000400
	BSR	ChecksumTrack		;0E0A: 61000294
	MOVE.L	D0,D6			;0E0E: 2C00
	LEA	8(A3),A0		;0E10: 41EB0008
	BSR	DecodeLong		;0E14: 6100030A
	CMP.L	D0,D6			;0E18: BC80
	BNE	decodeerror

	LEA	16(A3),A0		;0E1E: 41EB0010
	MOVEA.L	A2,A1			;0E22: 224A
	MOVE.L	#$00000200,D0		;0E24: 203C00000200
	MOVE.L	A2,D1			;0E2A: 220A
	ANDI	#$0001,D1		; odd???
	BEQ.S	LAB_00CD		;0E30: 6706
	BSR	DecodeATrack		;0E32: 6100049E
	BRA.S	LAB_00CF		;0E36: 6014
LAB_00CD:
	MOVE.L	A2,D1			;0E38: 220A
;	ANDI.L	#$FFF00000,D1		;0E3A: 0281FFF00000
;	BEQ.S	LAB_00CE		; blitter decode!
	BSR	DecodeATrack2
	BRA.W	LAB_00CF		;0E46: 6004
;LAB_00CE:
;	BSR	LAB_00FC		;0E48: 61000402
LAB_00CF:
	MOVEQ	#0,D7
	RTS

decodeerror:
	moveq	#-1,D7
	rts

DecodeATrack2:
	LEA	0(A0,D0.W),A2		;12AE: 45F00000
	LSR	#2,D0			;12B2: E448
	SUBQ	#1,D0			;12B4: 5340
LAB_0100:
	MOVE.L	(A0)+,D1		;12B6: 2218
	MOVE.L	(A2)+,D2		;12B8: 241A
	ANDI.L	#$55555555,D1		;12BA: 028155555555
	ANDI.L	#$55555555,D2		;12C0: 028255555555
	ADD.L	D1,D1			;12C6: D281
	OR.L	D2,D1			;12C8: 8282
	MOVE.L	D1,(A1)+		;12CA: 22C1
	DBF	D0,LAB_0100		;12CC: 51C8FFE8
	RTS

DecodeATrack:
	LEA	0(A0,D0.W),A2		;12D2: 45F00000
	SUBQ	#1,D0			;12D6: 5340
LAB_0102:
	MOVE.B	(A0)+,D1		;12D8: 1218
	MOVE.B	(A2)+,D2		;12DA: 141A
	ANDI.B	#$55,D1			;12DC: 02010055
	ANDI.B	#$55,D2			;12E0: 02020055
	ADD.B	D1,D1			;12E4: D201
	OR.B	D2,D1			;12E6: 8202
	MOVE.B	D1,(A1)+		;12E8: 12C1
	DBF	D0,LAB_0102		;12EA: 51C8FFEC
	RTS				;12EE: 4E75

ChecksumTrack:
	MOVEM.L	D1-D2/A0,-(A7)		;10A0: 48E76080
	MOVE.L	D0,D1			;10A4: 2200
	LSR	#2,D1			;10A6: E449
	SUBQ	#1,D1			;10A8: 5341
	MOVEQ	#0,D0			;10AA: 7000
LAB_00EB:
	MOVE.L	(A0)+,D2		;10AC: 2418
	EOR.L	D2,D0			;10AE: B580
	DBF	D1,LAB_00EB		;10B0: 51C9FFFA
	ANDI.L	#$55555555,D0		;10B4: 028055555555
	MOVEM.L	(A7)+,D1-D2/A0		;10BA: 4CDF0106
	RTS				;10BE: 4E75

DecodeLong:
	MOVE.L	(A0)+,D0		;1120: 2018
	MOVE.L	(A0)+,D1		;1122: 2218
	ANDI.L	#$55555555,D0		;1124: 028055555555
	ANDI.L	#$55555555,D1		;112A: 028155555555
	LSL.L	#1,D0			;1130: E388
	OR.L	D1,D0			;1132: 8081
	RTS				;1134: 4E75
