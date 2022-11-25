
	; FOFT imager

		incdir	Includes:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Federation Of Free Traders imager V1.0",10,"by Mr.Larmer/Wanted Team on 12.02.2000",0
		cnop	0,4

DSK_1:		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES!DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1:
		TLENTRY 1,1,$1600,SYNC_STD,DMFM_STD
		TLENTRY 0,0,$1770+$170,SYNC_STD,DMFM_NULL
		TLENTRY 2,157,$1770,SYNC_STD,DMFM_NR

		TLEND
DMFM_NR:
		lea	SectorFlags(pc),a2
		moveq	#2,d1
.l0		sf	(a2)+		; clear sector flags
		dbra	d1,.l0

		move.w	d0,d1

		move.w	2(a0),d0
		bsr.w	rotatebits
		cmp.w	d0,d1
		bne.w	.error

		moveq	#2,d6
		bra.b	.skip
.loop
		jsr	rawdic_NextSync(a5)
.skip
		cmp.w	#$5555,(a0)
		bne.b	.error

		move.w	4(a0),d0
		bsr.w	rotatebits
		cmp.w	#2,d0
		bgt.w	.error
		lea	SectorFlags(pc),a2
		and.w	#$00ff,d0
		st	(a2,d0.w)

		lea	(a1),a2
		mulu	#$7d0,d0
		add.l	d0,a2
		move.w	$FA6(a0),d0
		bsr.w	rotatebits
		move.w	d0,d4
		lsl.w	#8,d4
		move.w	$FA8(a0),d0
		bsr.b	rotatebits
		or.w	d0,d4

		lea	6(a0),a3
		move.w	#$3E7,d0
		bsr.b	calcchecksum
		cmp.w	d1,d4
		bne.b	.error

		move.w	#$7CF,d0
		lea	6(a0),a3
		bsr.w	decodemfm

		dbf	d6,.loop

		lea	SectorFlags(pc),a2
		moveq	#2,d1
.l2		tst.b	(a2)+		; if one sector is missing, one of
		dbeq	d1,.l2		; these flags will be FALSE
		beq.b	.nosect

		moveq	#IERR_OK,d0
		rts
.error
		moveq	#IERR_CHECKSUM,d0
		rts
.nosect
		moveq	#IERR_NOSECTOR,d0
		rts

rotatebits
		moveq	#7,D2
.loop
		lsl.w	#1,D0
		lsl.l	#1,D0
		dbra	D2,.loop
		swap	D0
		andi.w	#$FF,D0
		rts

calcchecksum
		move.w	D2,-(SP)
		moveq	#0,D1
		move.w	D1,D2
.loop
		move.w	(A3)+,D2
		eor.w	D2,D1
		move.w	(A3)+,D2
		eor.w	D2,D1
		dbra	D0,.loop
		move.w	(SP)+,D2
		rts

decodemfm
.loop2
		moveq	#0,D1
		moveq	#7,D2
		move.w	(A3)+,D3
.loop
		lsl.w	#1,D3
		lsl.l	#1,D3
		dbra	D2,.loop
		swap	D3
		move.b	D3,(A2)+
		dbra	D0,.loop2
		rts

SectorFlags:	ds.b	3
		even
