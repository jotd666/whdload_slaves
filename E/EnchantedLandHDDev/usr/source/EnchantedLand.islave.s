
	; Enchanted Land imager

		incdir	Include:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Enchanted Land imager V1.0",10,"by Mr.Larmer/Wanted Team on 03.02.2000",0
		cnop	0,4

DSK_1:		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1:
		TLENTRY 0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY 0,0,$200,SYNC_STD,DMFM_NULL
		TLENTRY 1,129,$1800,SYNC_STD,DMFM_NR
		TLENTRY 130,140,$1800,SYNC_STD,DMFM_NULL
		TLENTRY 141,157,$1800,SYNC_STD,DMFM_NR
		TLENTRY 158,158,$1800,SYNC_STD,DMFM_NULL
		TLENTRY 159,159,$1800,SYNC_STD,DMFM_NR

		TLEND
DMFM_NR:
		move.l	#$55555555,d6
		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d6,d0
		and.l	d6,d1
		add.l	d0,d0
		or.l	d1,d0
		rol.l	#8,d0
		cmp.b	#-1,d0
		bne.b	.error
		lea	$28(a0),a0
		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d6,d0
		and.l	d6,d1
		add.l	d0,d0
		or.l	d1,d0
		and.l	d6,d0
		move.l	d0,d7
		lea	$1800(a0),a2
		move.w	#$5ff,d2
		moveq	#0,d3
.loop
		move.l	(a0)+,d0
		move.l	(a2)+,d1
		and.l	d6,d0
		and.l	d6,d1
		eor.l	d0,d3
		eor.l	d1,d3
		add.l	d0,d0
		or.l	d1,d0
		move.l	d0,(a1)+
		dbf	d2,.loop
		and.l	d6,d3
		cmp.l	d3,d7
		bne.b	.error

		moveq	#IERR_OK,d0
		rts
.error
		moveq	#IERR_CHECKSUM,d0
		rts
