;*---------------------------------------------------------------------------
;  :Program.	rocknroll.islave.asm
;  :Contents.	Imager for Rock 'n Roll
;  :Author.	Wepl
;  :Version.	$Id: rocknroll.islave.asm 1.1 2012/08/28 01:17:02 wepl Exp wepl $
;  :History.	27.08.12 created, based on patcher slave and hs imager
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;
;	v1 sps-801 2 disk
;	Disk 1:	0-1	standard
;		2-161	$1800 bytes sync 5284/5484/5242 with gaps!
;		160	highscores
;	Disk 2:	0-161	$1800 bytes sync 5284/5484/5242
;
;	v2 sps-2167 1 disk
;	Disk 1:	0-159	standard
;		160	$1800 bytes sync 5284 highscores
;
;============================================================================

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/rocknroll install/RocknRoll.ISlave"
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
		dc.l	_v2_disk1	; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Rock 'n Roll Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
_fld1		dc.b	"Disk.1",0
_fld2		dc.b	"Disk.2",0
_flh		dc.b	"rrhigh",0
	EVEN

;============================================================================

_v2_disk1	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	.fl		; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	_v1_disk1	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,159,$1600,SYNC_STD,DMFM_STD
		TLEND

.fl		FLENTRY	FL_DISKNAME,0,FL_DISKLENGTH
		FLEND

.crc		CRCENTRY 0,$67b8
		CRCEND

_v1_disk1	dc.l	_v1_disk2	; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	.fl		; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,1,$1800,0,DMFM_NULL
		TLENTRY 2,3,$1800,$5284,_decode
		TLENTRY	4,5,$1800,$5484,_decode
		TLENTRY	6,9,$1800,$5242,_decode
		TLENTRY	10,11,$1800,$5284,_decode
		TLENTRY	12,13,$1800,$5484,_decode
		TLENTRY	14,17,$1800,$5284,_decode
		TLENTRY	18,19,$1800,$5242,_decode
		TLENTRY	20,23,$1800,$5284,_decode
		TLENTRY	24,25,$1800,$5484,_decode
		TLENTRY	26,29,$1800,$5242,_decode
		TLENTRY	30,31,$1800,$5284,_decode
		TLENTRY	32,33,$1800,$5484,_decode
		TLENTRY	34,37,$1800,$5284,_decode
		TLENTRY	38,39,$1800,$5242,_decode
		TLENTRY	40,43,$1800,$5284,_decode
		TLENTRY	44,45,$1800,$5484,_decode
		TLENTRY	46,49,$1800,$5242,_decode
		TLENTRY	50,51,$1800,$5284,_decode
		TLENTRY	52,53,$1800,$5484,_decode
		TLENTRY	54,57,$1800,$5284,_decode
		TLENTRY	58,59,$1800,$5242,_decode
		TLENTRY	60,63,$1800,$5284,_decode
		TLENTRY	64,65,$1800,$5484,_decode
		TLENTRY	66,67,$1800,$5242,_decode
		TLENTRY	68,68,$1800,$5242,_decode
		TLENTRY	69,70,$1800,0,DMFM_NULL
		TLENTRY	71,71,$1800,$5284,_decode
		TLENTRY	72,73,$1800,$5484,_decode
		TLENTRY	74,77,$1800,$5284,_decode
		TLENTRY	78,79,$1800,$5242,_decode
		TLENTRY	80,83,$1800,$5284,_decode
		TLENTRY	84,90,$1800,0,DMFM_NULL
		TLENTRY	91,91,$1800,$5284,_decode
		TLENTRY	92,93,$1800,$5484,_decode
		TLENTRY	94,97,$1800,$5284,_decode
		TLENTRY	98,99,$1800,$5242,_decode
		TLENTRY	100,103,$1800,$5284,_decode
		TLENTRY	104,105,$1800,$5484,_decode
		TLENTRY	106,109,$1800,$5242,_decode
		TLENTRY	110,111,$1800,$5284,_decode
		TLENTRY	112,113,$1800,$5484,_decode
		TLENTRY	114,117,$1800,$5284,_decode
		TLENTRY	118,119,$1800,$5242,_decode
		TLENTRY	120,123,$1800,$5284,_decode
		TLENTRY	124,125,$1800,$5484,_decode
		TLENTRY	126,129,$1800,$5242,_decode
		TLENTRY	130,131,$1800,$5284,_decode
		TLENTRY	132,133,$1800,$5484,_decode
		TLENTRY	134,137,$1800,$5284,_decode
		TLENTRY	138,139,$1800,$5242,_decode
		TLENTRY	140,143,$1800,$5284,_decode
		TLENTRY	144,145,$1800,$5484,_decode
		TLENTRY	146,149,$1800,$5242,_decode
		TLENTRY	150,151,$1800,$5284,_decode
		TLENTRY	152,156,$1800,0,DMFM_NULL
		TLENTRY	157,157,$1800,$5284,_decode
		TLENTRY	158,158,$1800,$5242,_decode
		TLENTRY	159,160,$1800,0,DMFM_NULL
		TLENTRY 161,161,$1800,$5284,_decode
		TLEND

.fl		FLENTRY FL_DISKNAME,0,FL_DISKLENGTH
		FLEND

_v1_disk2	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	.fl		; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY 0,3,$1800,$5284,_decode
		TLENTRY	4,5,$1800,$5484,_decode
		TLENTRY	6,9,$1800,$5242,_decode
		TLENTRY	10,11,$1800,$5284,_decode
		TLENTRY	12,13,$1800,$5484,_decode
		TLENTRY	14,17,$1800,$5284,_decode
		TLENTRY	18,19,$1800,$5242,_decode
		TLENTRY	20,23,$1800,$5284,_decode
		TLENTRY	24,25,$1800,$5484,_decode
		TLENTRY	26,29,$1800,$5242,_decode
		TLENTRY	30,31,$1800,$5284,_decode
		TLENTRY	32,33,$1800,$5484,_decode
		TLENTRY	34,37,$1800,$5284,_decode
		TLENTRY	38,39,$1800,$5242,_decode
		TLENTRY	40,43,$1800,$5284,_decode
		TLENTRY	44,45,$1800,$5484,_decode
		TLENTRY	46,49,$1800,$5242,_decode
		TLENTRY	50,51,$1800,$5284,_decode
		TLENTRY	52,53,$1800,$5484,_decode
		TLENTRY	54,57,$1800,$5284,_decode
		TLENTRY	58,59,$1800,$5242,_decode
		TLENTRY	60,63,$1800,$5284,_decode
		TLENTRY	64,65,$1800,$5484,_decode
		TLENTRY	66,69,$1800,$5242,_decode
		TLENTRY	70,71,$1800,$5284,_decode
		TLENTRY	72,73,$1800,$5484,_decode
		TLENTRY	74,77,$1800,$5284,_decode
		TLENTRY	78,79,$1800,$5242,_decode
		TLENTRY	80,83,$1800,$5284,_decode
		TLENTRY	84,85,$1800,$5484,_decode
		TLENTRY	86,89,$1800,$5242,_decode
		TLENTRY	90,91,$1800,$5284,_decode
		TLENTRY	92,93,$1800,$5484,_decode
		TLENTRY	94,97,$1800,$5284,_decode
		TLENTRY	98,99,$1800,$5242,_decode
		TLENTRY	100,103,$1800,$5284,_decode
		TLENTRY	104,105,$1800,$5484,_decode
		TLENTRY	106,109,$1800,$5242,_decode
		TLENTRY	110,111,$1800,$5284,_decode
		TLENTRY	112,113,$1800,$5484,_decode
		TLENTRY	114,117,$1800,$5284,_decode
		TLENTRY	118,119,$1800,$5242,_decode
		TLENTRY	120,123,$1800,$5284,_decode
		TLENTRY	124,125,$1800,$5484,_decode
		TLENTRY	126,129,$1800,$5242,_decode
		TLENTRY	130,131,$1800,$5284,_decode
		TLENTRY	132,133,$1800,$5484,_decode
		TLENTRY	134,137,$1800,$5284,_decode
		TLENTRY	138,139,$1800,$5242,_decode
		TLENTRY	140,143,$1800,$5284,_decode
		TLENTRY	144,145,$1800,$5484,_decode
		TLENTRY	146,149,$1800,$5242,_decode
		TLENTRY	150,151,$1800,$5284,_decode
		TLENTRY	152,153,$1800,$5484,_decode
		TLENTRY	154,157,$1800,$5284,_decode
		TLENTRY	158,159,$1800,$5242,_decode
		TLENTRY 160,160,$1800,$5284,_decode
		TLENTRY 161,161,$1800,$5284,_decode_hs
		TLEND

.fl		FLENTRY FL_DISKNAME,0,FL_DISKLENGTH
		FLENTRY _flh,161*$1800,$1800
		FLEND

;============================================================================

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decode
		move.l	#$55555555,d3
		moveq	#0,d1			;d1 = chksum
		move.l	a1,a4

		MOVE.W	#$05FF,D7
.12		move.l	($1800,a0),d4
		move.l	(a0)+,d0
		AND.L  D3,D0
		AND.L  D3,D4
		LSL.L	#1,D0
		OR.L	D4,D0
		MOVE.L	D0,(A1)+
		EOR.L	D0,D1
		DBF	D7,.12
		LEA.L	$1800(A0),A0

		move.l	(a0)+,d0
		move.l	(a0)+,d4
		AND.L  D3,D0
		AND.L  D3,D4
		LSL.L	#1,D0
		OR.L	D4,D0
		CMP.L	D1,D0
		BNE	.error

.ok		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts

_decode_hs	bsr	_decode

		MOVE.L	A4,A1				;highscoreprotect
		MOVE.W	#$10A0/4-1,D2
		MOVEQ.L	#0,D1
.H1		ADD.L	(A1)+,D1
		DBF	D2,.H1
		MOVE.L	D1,$10A0(A4)

		rts

;============================================================================

	END
