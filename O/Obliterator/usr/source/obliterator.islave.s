;*---------------------------------------------------------------------------
;  :Program.	obliterator.islave.asm
;  :Contents.	Imager for Obliterator
;  :Author.	Wepl
;  :Version.	$Id: obliterator.islave.asm 1.1 2014/07/16 22:25:39 wepl Exp wepl $
;  :History.	16.07.14 started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;	original release:
;	Disk 1:		0-154*2		standard
;			1-131*2		standard
;			131-141*2	standard, 10 save games
;
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/Obliterator Install/Obliterator.ISlave"
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
_text		dc.b	"Obliterator Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
_d1		dc.b	"disk.1",0
_d2		dc.b	"disk.2",0
	EVEN

;============================================================================

	;original release
_disk1		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_DOUBLEINC	; Disk flags
		dc.l	_tl1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl1		; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

_tl1		TLENTRY	0,154,$1600,SYNC_STD,DMFM_STD
		TLENTRY	1,131,$1600,SYNC_STD,DMFM_STD
	;	TLENTRY	133,151,$1600,SYNC_STD,DMFM_NULL
		TLEND

_fl1		FLENTRY	_d1,0,156/2*$1600
		FLENTRY	_d2,156/2*$1600,132/2*$1600
	;	FLENTRY	_d2,156/2*$1600,152/2*$1600
		FLEND

;============================================================================

	END

