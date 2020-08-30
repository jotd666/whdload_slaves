


		incdir	Include:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1a	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text:		dc.b	"Commando Imager V1.0",10,"by Keith Krellwitz (Abaddon) on 05/01/1999",0
		cnop	0,4

DSK_1a:		dc.l	0		; pointer to next disk structure
		dc.w	1		; disk structure version
		dc.w	DFLG_NORESTRICTIONS	; flags (look below)
		dc.l	TL_1a		; list of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; list of files to be saved
		dc.l	0		; table of certain tracks with CRC values
		dc.l	0		; alternative disk structure, if CRC failed
		dc.l	0		; called before a disk is read
		dc.l	0		; called after a disk has been read


TL_1a:
		TLENTRY	1,95,$1800,$4489,DMFM_GA
		TLENTRY	0,0,$1600,$4489,DMFM_STD
		TLEND

DMFM_GA:
	move.l	d0,d7
	MOVE.L	#$55555555,D5
	move.w	(a0)+,d2
	move.w	(a0)+,d1
	and.w	d5,d2
	and.w	d5,d1
	add.w	d2,d2
	or.w	d2,d1
;	move.l	d1,d3
	cmp.w	d1,d7
	beq		.ok
	jsr	rawdic_NextSync(a5)
	bra		DMFM_GA
.ok
	moveq	#$ffffffff,d4
	move.w	#$5ff,d6
.dec
	move.l	d5,d1
	and.l	$1804(a0),d1
	move.l	d5,d2
	and.l	(a0)+,d2
	add.l	d2,d2
	or.l	d2,d1
	sub.l	d1,d4
	move.l	d1,(a1)+
	dbf		d6,.dec

	move.l	$1804(a0),d1
	and.l	d5,d1
	move.l	(a0)+,d2
	and.l	d5,d2
	add.l	d2,d2
	or.l	d2,d1
	cmp.l	d4,d1
	bne		.csum
	moveq	#IERR_OK,d0
	rts
.csum
	moveq	#IERR_CHECKSUM,d0
	rts

	move.l	d0,(a1)+
	move.l	d1,(a1)+
	moveq	#IERR_OK,d0
	rts

track:
	dc.l	0
