;*---------------------------------------------------------------------------
;  :Program.	starglider2.islave.asm
;  :Contents.	Imager for Starglider 2 by Argonaut Software
;  :Author.	Graham, Wepl
;  :Version.	$Id: Starglider2.islave.asm 1.4 2005/07/24 16:46:42 wepl Exp wepl $
;  :History.	04.06.05 created from resourced islve by Graham
;		09.07.05 sound rip added
;		24.07.05 crc vrification fixed (did not work for v1)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;	v1 Disk 1:
;			0,2,4		???
;			6-154*2		5 sectors à $400 byte + 1 sector à $200 byte
;			1-159*2		5 sectors à $400 byte + 1 sector à $200 byte
;			on Wolfgangs disk tracks 3 and 43 are with checksum error
;
;	v2 Disk 1:	Amiga/AtariST Dual Disk Format?
;			0		standard
;			2-150*2		5 sectors à $400 byte + 1 sector à $200 byte
;			152-160*2	unformatted
;			1-159*2		5 sectors à $400 byte + 1 sector à $200 byte
;
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/Starglider2 Install/Starglider2.ISlave"
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
		dc.l	_disk_v1	; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		db	'Starglider 2 Imager',$A
		db	'by Graham, Wepl, Version 1.2 '
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
_game		db	'Starglider2',0
_sound		db	'Starglider2.sound',0
	EVEN

_disk_v1	dl	0		;dsk_NextDisk
		dw	1		;dsk_Version
		dw	DFLG_DOUBLEINC	;dsk_Flags
		dl	_tracks_v1	;dsk_TrackList
		dl	0		;dsk_TLExtension
		dl	_files_v1	;dsk_FileList
		dl	_crc_v1		;dsk_CRCList
		dl	_disk_v2	;dsk_AltDisk
		dl	_init_v1	;dsk_InitCode
		dl	0		;dsk_DiskCode

LENGTH_V1 = $1997b

_tracks_v1	TLENTRY	6,154,$1600,$4489,_decode
		TLENTRY	1,159,$1600,$4489,_decode
		TLEND

_files_v1	FLENTRY	_game,0,LENGTH_V1*4
		FLENTRY	_sound,75*$1600,$6ca00
		FLEND

_crc_v1		CRCENTRY 6,$3c09
		CRCEND

_init_v1	move.l	#LENGTH_V1,_decryptlength
		bra	_init

_disk_v2	dl	0		;dsk_NextDisk
		dw	1		;dsk_Version
		dw	DFLG_DOUBLEINC	;dsk_Flags
		dl	_tracks_v2	;dsk_TrackList
		dl	0		;dsk_TLExtension
		dl	_files_v2	;dsk_FileList
		dl	_crc_v2		;dsk_CRCList
		dl	0		;dsk_AltDisk
		dl	_init_v2	;dsk_InitCode
		dl	0		;dsk_DiskCode

LENGTH_V2 = $19310

_tracks_v2	TLENTRY	2,150,$1600,$4489,_decode
		TLENTRY	1,159,$1600,$4489,_decode
		TLEND

_files_v2	FLENTRY	_game,0,LENGTH_V2*4
		FLENTRY	_sound,75*$1600,$6ca00
		FLEND

_crc_v2		CRCENTRY 2,$8bdf
		CRCEND

_init_v2	move.l	#LENGTH_V2,_decryptlength
		bra	_init

_decode	lea	(_flags,pc),a2
	moveq	#5,d1
.flags	sf	(a2)+
	dbra	d1,.flags
	moveq	#5,d1
	bra.b	.chksync1

.bigloop	jsr	(rawdic_NextSync,a5)
.chksync1	cmpi.w	#$5554,(a0)
	bne.b	.bigloop
	bsr.b	_checksum
	bne.b	.rts
	jsr	(rawdic_NextSync,a5)
	cmpi.w	#$5545,(a0)
	bne.b	.chksync1
	move.b	d2,d0
	bsr.w	_getsector
	bne.b	.rts
	dbra	d1,.bigloop
	lea	(_flags,pc),a2
	moveq	#5,d1
.secchk	tst.b	(a2)+
	dbeq	d1,.secchk
	beq.b	.fewsectors
	lea	(_decryptlength,pc),a0	;decrypt
	move.l	(a0),d3
	move.l	#$AAAAAAAA,d2
	move.w	#$57F,d1
.loop	move.l	(a1),d0
	eor.l	d2,d0
	sub.l	d3,d0
	ror.l	#1,d0
	subq.l	#1,d3
	bmi.b	.nomi
	move.l	d0,(a1)+
	dbra	d1,.loop
.nomi	move.l	d3,(a0)
	moveq	#IERR_OK,d0
.rts	rts

.fewsectors	moveq	#IERR_NOSECTOR,d0
	rts

_checksum	movem.l	d1/a0,-(sp)
	bsr.b	_initregs
	moveq	#9,d6
	bsr.b	_getbytes_d6
	or.b	d2,d3
	bne.b	.badchksum
	subq.l	#8,a0
	bsr.b	_getbyte
	subi.b	#$F5,d0
	move.b	d0,d2
	movem.l	(sp)+,d1/a0
	moveq	#IERR_OK,d0
	rts

.badchksum	movem.l	(sp)+,d1/a0
	moveq	#IERR_CHECKSUM,d0
	rts

_getsector	movem.l	d1/a0/a1,-(sp)	;5 sectors = $400 + 1 sector = $200 makes $1600
	move.w	#$3FF,d5
	cmp.b	#5,d0
	bhi.b	.badchksum
	bne.b	.no5
	move.w	#$1FF,d5
.no5	lea	(_flags,pc),a2
	andi.w	#$FF,d2
	st	(a2,d2.w)
	lsl.w	#8,d0
	lsl.w	#2,d0
	adda.w	d0,a1
	bsr.b	_initregs
	moveq	#3,d6
	bsr.b	_getbytes_d6
.loop	bsr.b	_getbyte
	bsr.b	_eor
	move.b	d0,(a1)+
	dbra	d5,.loop
	moveq	#1,d6
	bsr.b	_getbytes_d6
	or.b	d2,d3
	bne.b	.badchksum
	movem.l	(sp)+,d1/a0/a1
	moveq	#IERR_OK,d0
	rts

.badchksum	movem.l	(sp)+,d1/a0/a1
	moveq	#IERR_CHECKSUM,d0
	rts

_initregs	lea	(_blockbuffer).l,a2
	moveq	#0,d1
	moveq	#-1,d2
	moveq	#-1,d3
	subq.l	#6,a0
	rts

_getbytes_d6	bsr.b	_getbyte
	bsr.b	_eor
	dbra	d6,_getbytes_d6
	rts

_getbyte	move.w	(a0)+,d0
	moveq	#7,d7
lbC0001AE	add.w	d0,d0
	add.l	d0,d0
	dbra	d7,lbC0001AE
	swap	d0
	rts

_eor	move.b	d0,d1
	eor.b	d2,d1
	lea	(a2,d1.w),a3
	move.b	(a3),d2
	eor.b	d3,d2
	move.b	($100,a3),d3
	rts

_init	lea	(_blockbuffer).l,a0
	moveq	#0,d1
lbC0001D4	moveq	#0,d2
	move.b	d1,d2
	lsl.w	#8,d2
	moveq	#7,d0
lbC0001DC	add.w	d2,d2
	bcc.b	lbC0001E4
	eori.w	#$1021,d2
lbC0001E4	dbra	d0,lbC0001DC
	move.b	d2,($100,a0)
	lsr.w	#8,d2
	move.b	d2,(a0)+
	addq.b	#1,d1
	bne.b	lbC0001D4
	moveq	#0,d0
	rts

_decryptlength	dl	0
_flags	dl	0
	dl	0

	SECTION	Starglider2islavers000204,BSS
_blockbuffer	ds.b	$200

	end
