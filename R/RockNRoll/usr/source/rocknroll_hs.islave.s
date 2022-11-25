;*---------------------------------------------------------------------------
;  :Program.	rocknroll_hs.islave.asm
;  :Contents.	Imager for Rock' Roll highscore
;  :Author.	Wepl
;  :Version.	$Id: rocknroll_hs.islave.asm 1.1 2012/01/14 19:18:36 wepl Exp wepl $
;  :History.	14.01.12 created, based on game patcher
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;	Disk 1:		
;
;============================================================================

;DEBUG

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/rocknroll install/RocknRoll_HS.ISlave"
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
		dc.l	_disk1		; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Rock'n Roll highscore Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
_fl1		dc.b	"rrhigh",0
	EVEN

;============================================================================

_disk1		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	.fl		; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY 160,160,$1800,$5284,_decode
		TLEND

.fl		FLENTRY _fl1,0,$1800
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

		MOVE.L	A4,A1				;highscoreprotect
		MOVE.W	#$10A0/4-1,D0
		MOVEQ.L	#0,D1
.H1		ADD.L	(A1)+,D1
		DBF	D0,.H1
		MOVE.L	D1,$10A0(A4)

.ok		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts

;============================================================================

	END
