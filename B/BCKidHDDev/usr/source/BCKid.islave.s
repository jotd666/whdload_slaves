;*---------------------------------------------------------------------------
;  :Program.	bckid.islave.asm
;  :Contents.	Imager for B.C.Kid by Hudson Soft/Factor 5
;  :Author.	Mr.Larmer, Wepl
;  :Version.	$Id: BCKid.islave.asm 1.4 2014/03/17 21:04:32 wepl Exp wepl $
;  :History.	21.02.00 created by Mr.Larmer
;		04.07.06 reworked by Wepl
;		22.02.08 ready for production
;		11.03.14 last file removed from diskimage, probably a dummy to
;			 make it harder for crackers to create a single disk
;			 release
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;	Disk 1:		0-1	standard
;			2-159	$1964 bytes sync=9521
;
;	Image format:
;	Disk 1:		tracks 2-159 = 
;
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/BCKid Install/BCKid.ISlave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	ENDC

;======================================================================

	SECTION a,CODE

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0		; Slave flags
		dc.l	DSK_1		; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"B.C.Kid Imager",10
		dc.b	"Done by Mr.Larmer/Wanted Team & Wepl, Version 1.2 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
_highs		dc.b	"BCKid.highs",0
_boot		dc.b	"boot",0
	EVEN

DSK_1:		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl1		; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1		TLENTRY 0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY 1,1,$1600,SYNC_STD,_highscore
		TLENTRY 2,159,$1964,$9521,_custom
		TLEND

_fl1		FLENTRY	_boot,0,$1600
		FLENTRY	FL_DISKIMAGE,$2c00,($9f-2)*$1964+$7f4
		FLEND

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_highscore	move.l	a1,a2

		moveq	#11,d0
		jsr	(rawdic_DMFM_STANDARD,a5)
		tst.l	d0
		bne	.end

		move.l	#$184,d0
		lea	_highs,a0
		move.l	a2,a1
		jsr	(rawdic_SaveFile,a5)

.end		moveq	#IERR_OK,d0
		rts


	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_custom		cmp.w	#$2AAA,(a0)+
		bne.b	error

		move.l	#$55555555,D2
		move.w	#$658,d3
		moveq	#0,d4
loop
		movem.l	(A0)+,D0/D1
		eor.l	d0,d4
		eor.l	d1,d4
		and.l	D2,D0
		and.l	D2,D1
		add.l	D0,D0
		or.l	D1,D0
		move.l	d0,(a1)+
		dbf	d3,loop

		movem.l	(A0)+,D0/D1
		and.l	D2,D0
		and.l	D2,D1
		add.l	D0,D0
		or.l	D1,D0

		and.l	D2,D4

		cmp.l	d0,d4
		bne.b	error
ok
		moveq	#IERR_OK,d0
		rts
error
		moveq	#IERR_CHECKSUM,d0
		rts

