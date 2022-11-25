;*---------------------------------------------------------------------------
;  :Program.	turican2.islave.asm
;  :Contents.	Imager for Turrican 2
;  :Author.	Wepl
;  :Version.	$Id: turrican2.islave.asm 1.3 2007/02/27 20:43:19 wepl Exp wepl $
;  :History.	26.05.05 started
;		08.10.06 highscore encoding added
;			 diskimage length calc added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	v1/v2
;	Disk 1:		0	standard
;			1	highscores
;				$4489 sync
;				$2aaa unused
;				long even/odd chksum
;				8 bytes unused
;			2-159	$1a90 data bytes
;				$9521 sync
;				$2aaa unused
;				2*$1a90 mfm data even/odd
;				long even/odd mfm chksum
;
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/Turrican2 Install/Turrican2.ISlave"
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
		dc.l	_disk1v1	; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Turrican 2 Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
_60000		dc.b	"60000",0
_highs		dc.b	"highs",0
_savehighsflag	dc.b	0
	EVEN

;============================================================================

_disk1v1	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl		; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	_savehighs	; Called after a disk has been read

.crc		CRCENTRY 0,$c3b0
		CRCEND

.tl		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY 1,1,388,$4489,_decodehighs
		TLENTRY 2,159,$1a90,$9521,_decodedata
		TLEND

_fl		FLENTRY	_60000,$400,$800
		FLENTRY	FL_DISKIMAGE,$1600+388,0
		FLEND

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decodedata	addq.l	#2,a0			;skip $2aaa
		move.l	#$55555555,d2		;D2 = 55555555
		moveq	#0,d5			;D5 = chksum
		move.w	#$1a90/4-1,d3
		move.w	d0,d7

.loop		move.l	(a0)+,d0
		move.l	(a0)+,d1
		eor.l	d0,d5
		eor.l	d1,d5
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		move.l	d0,(a1)+
		dbf	d3,.loop

		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		and.l	d2,d5
		cmp.l	d0,d5
		bne	.error

	;calc diskimage length
		cmp.w	#2,d7
		bne	.notrk2
		move.w	($1d4-$1a90,a1),d0
		sub.w	d7,d0
		mulu	#$1a90,d0
		moveq	#0,d1
		move.w	($1d6-$1a90,a1),d1
		add.l	d1,d0
		add.l	($1d8-$1a90,a1),d0
		move.l	d0,_fl+12+8
.notrk2		       
		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decodehighs	addq.l	#2,a0			;skip $2aaa
		move.l	#$55555555,d2		;D2 = 55555555

		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		eor.l	#$12345678,d0

		addq.l	#8,a0			;skip unused

		move.l	a0,a2
		move.w	#$c7,d3
		moveq	#0,d1
.hlp1		move.l	(a0)+,d4
		eor.l	d4,d1
		dbf	d3,.hlp1
		and.l	d2,d1
		cmp.l	d0,d1
		bne	.error

		move.l	a2,a0
		move.w	#$60,d3
.hlp2		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		move.l	d0,(a1)+
		dbf	d3,.hlp2

		sub.w	#388,a1
		move.w	#$61*4-1,d0
.lp		eor.b	d0,(a1)+
		dbf	d0,.lp

		st	_savehighsflag
.error		moveq	#IERR_OK,d0
		rts

_savehighs	move.b	_savehighsflag,d0
		beq	.end

		move.l	#$1600,d0		;offset in disk image
		move.l	#388,d1			;length
		lea	_highs,a0		;name
		jsr	(rawdic_SaveDiskFile,a5)

.end		moveq	#IERR_OK,d0
		rts

;============================================================================

	END
