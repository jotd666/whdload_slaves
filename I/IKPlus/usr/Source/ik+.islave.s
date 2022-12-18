;*---------------------------------------------------------------------------
;  :Program.	ik+.islave.asm
;  :Contents.	Imager for IK+
;  :Author.	Wepl
;  :Version.	$Id: ik+.islave.asm 1.1 2001/07/14 10:15:22 jah Exp jah $
;  :History.	13.07.01 created
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;	original release:
;	Disk 1:		0	standard
;			2-120*2	$1800 bytes sync=8944
;			122*2	unformatted
;			1*2	unformatted
;	HitSquad rerelease:
;	Disk 1:		0-159	standard
;
;---------------------------------------------------------------------------*

	INCDIR	SOURCES:Include/
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/IK+ Install/IK+.ISlave"
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODd-			;disable mul optimizing
	BOPT	ODe-			;disable mul optimizing
	ENDC

;============================================================================

	SECTION a,CODE

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0		; Slave flags
	;	dc.b	SFLG_DEBUG	; Slave flags
		dc.l	_disk1		; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"IK+ Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	IFD	BARFLY
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
	ENDC
		dc.b	".",0
_image		dc.b	"IK+.Image",0
	EVEN

;============================================================================

	;original release
_disk1		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SINGLESIDE	; Disk flags
		dc.l	_tl1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl1		; List of files to be saved
		dc.l	_crc1		; Table of certain tracks with CRC values
		dc.l	_disk12		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

_tl1		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY	1,60,$1800,$8944,_decode1
		TLEND

_fl1		FLENTRY	_image,$1600,$58800
		FLEND

_crc1		CRCENTRY 0,$bc15
		CRCEND

_decode1

	;init table
		LEA	(_buf_200),A2
		tst.w	(a2)
		bne	.initend
		MOVEQ	#0,D7
.B4		MOVEQ	#0,D6
		MOVE.B	D7,D6
		LSL.W	#8,D6
		MOVEQ	#7,D0
.BC		LSL.W	#1,D6
		BCC.B	.C4
		EORI.W	#$1021,D6
.C4		DBRA	D0,.BC
		MOVE.B	D6,$0100(A2)
		LSR.W	#8,D6
		MOVE.B	D6,(A2)+
		ADDQ.B	#1,D7
		BNE.B	.B4
.initend
		move.b	#$17,d6
		move.b	#$fd,d7

		MOVE.W	#$17FF,D1
		MOVEA.L	A1,A4
		BSR	.26A

		MOVEQ	#1,D1
		subq.l	#4,a7
		move.l	a7,a4
		BSR	.26A
		OR.B	D6,D7
		addq.l	#4,a7
		bne	.error
		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts

.26A		LEA	.35C(PC),A2
		LEA	(_buf_200),A3
		MOVE.L	A3,D4
		MOVEQ	#$007F,D3
		MOVEQ	#0,D0

.27A		move.w	(a0)+,d0
		ror.l	#8,d0
		AND.W	D3,D0
		MOVEQ	#0,D2
		MOVE.B	(A2,D0.W),D2
		rol.l	#8,d0
		AND.W	D3,D0
		LSL.B	#4,D2
		OR.B	(A2,D0.W),D2
		MOVE.B	D2,(A4)+
		MOVEA.L	D4,A3
		EOR.B	D6,D2
		ADDA.W	D2,A3
		MOVE.B	(A3),D6
		EOR.B	D7,D6
		MOVE.B	$0100(A3),D7
		DBRA	D1,.27A
		RTS	

.35C		DC.L	$10001
		DC.L	$2030203
		DC.L	$10001
		DC.L	$2030203
		DC.L	$4050405
		DC.L	$6070607
		DC.L	$4050405
		DC.L	$6070607
		DC.L	$10001
		DC.L	$2030203
		DC.L	$10001
		DC.L	$2030203
		DC.L	$4050405
		DC.L	$6070607
		DC.L	$4050405
		DC.L	$6070607
		DC.L	$8090809
		DC.L	$A0B0A0B
		DC.L	$8090809
		DC.L	$A0B0A0B
		DC.L	$C0D0C0D
		DC.L	$E0F0E0F
		DC.L	$C0D0C0D
		DC.L	$E0F0E0F
		DC.L	$8090809
		DC.L	$A0B0A0B
		DC.L	$8090809
		DC.L	$A0B0A0B
		DC.L	$C0D0C0D
		DC.L	$E0F0E0F
		DC.L	$C0D0C0D
		DC.L	$E0F0E0F

;============================================================================

	;HitSquad rerelease
_disk12		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	_tl12		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl12		; List of files to be saved
		dc.l	_crc12		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

_tl12		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY	9,$49,$1600,SYNC_STD,DMFM_STD
		TLEND

_fl12		FLENTRY	_image,$1800,$58800
		FLEND

_crc12		CRCENTRY 0,$56af
		CRCEND

;======================================================================

	SECTION	b,BSS

_buf_200	ds.b	$200

;============================================================================

	END

