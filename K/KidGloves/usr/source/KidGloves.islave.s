


		incdir	Include:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1a	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text:		dc.b	"Kid Gloves Imager V1.0",10,"by Keith Krellwitz (Abaddon) on 05/22/1999",0
		cnop	0,4

DSK_1a:		dc.l	0		; pointer to next disk structure
		dc.w	1		; disk structure version
		dc.w	DFLG_NORESTRICTIONS	; flags (look below)
		dc.l	TL_1a		; list of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_1	; list of files to be saved
		dc.l	0		; table of certain tracks with CRC values
		dc.l	0		; alternative disk structure, if CRC failed
		dc.l	0		; called before a disk is read
		dc.l	0		; called after a disk has been read


TL_1a:
		TLENTRY	2,95,$1400,$4489,DMFM_GA
		TLEND
FL_1:	
		FLENTRY	FName1,$1400,435200
		FLENTRY	FName2,$6e000,15360
		FLEND



DMFM_GA:
	move.l	#$1,d6
	move.l	d0,d7
	sub.l	#$16,a0
	move.l	a0,a2
	move.l	a1,a3
	moveq	#$f,d0
	bsr		decode
	cmpi.b	#$ff,$b(a1)
	bne		.resync
	cmp.b	$c(a1),d7
	bne		.resync
	cmp.b	$d(a1),d6
	bne		.csum

	lea		$20(a0),a2
	move.w	#$3ff,d0
	move.l	a1,a3
	bsr		decode

	addi.l	#$1,d6
.dec1
	add.l	#$820,a0
	add.l	#$400,a1
	move.l	a0,a2
	move.l	a1,a3
	moveq	#$f,d0
	bsr		decode
	cmpi.b	#$ff,$b(a1)
	bne		.resync
	cmp.b	$c(a1),d7
	bne		.resync
	cmp.b	$d(a1),d6
	bne		.csum

	lea		$20(a0),a2
	move.w	#$3ff,d0
	move.l	a1,a3
	bsr		decode

	addi.l	#$1,d6
	cmpi.l	#$6,d6
	bne		.dec1
	moveq	#IERR_OK,d0
	rts
.resync
	jsr	rawdic_NextSync(a5)
	bra		.dec1

.csum
	moveq	#IERR_CHECKSUM,d0
	rts

decode:
	moveq	#$7,d2
	move.w	(a2)+,d3
.dec
	lsl.w	#$1,d3
	lsl.l	#$1,d3
	dbf		d2,.dec
	swap	d3
	move.b	d3,(a3)+
	dbf		d0,decode
	rts


chk1:
	moveq	#$7,d2
.dec
	lsl.w	#$1,d0
	lsl.l	#$1,d0
	dbf		d2,.dec
	swap	d0
	andi.w	#$ff,d0
	rts
chk2:
	move.w	d2,-(a7)
	moveq	#$0,d1
	move.w	d1,d2
.dec
	move.w	(a2)+,d2
	eor.w	d2,d1
	move.w	(a2)+,d2
	eor.w	d2,d1
	dbf		d0,.dec	
	move.w	(a7)+,d2
	rts
FName1:
	dc.b	"kgloves0.bin",0
	even
FName2:
	dc.b	"kgloves1.bin",0
	even
