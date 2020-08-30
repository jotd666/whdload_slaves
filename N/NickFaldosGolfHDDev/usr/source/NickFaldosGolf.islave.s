	; Rob Northen imager

	; A track contains 12 sectors, each containing 512 bytes data.

	; Sector format description:

	; sync ($4489)
	; word ($4489)*3
	; 256 words data
	; 1 word checksum

		incdir	Include:
		include	RawDIC.i

	IFD	BARFLY
	OUTPUT	NickFaldosGolf.islave
	ENDC
		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text:		dc.b	"Nick Faldo's Golf imager V1.0",10,"by Mr.Larmer on 13.03.2001",0
		cnop	0,4

DSK_1:		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_2:		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1:
		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY	1,1,$1A00,SYNC_INDEX,DMFM_NULL
		TLENTRY	2,74,$1800,SYNC_STD,DMFM_RN
		TLEND
TL_2:
		TLENTRY	0,0,$1600,SYNC_INDEX,DMFM_NULL
		TLENTRY	1,159,$1600,SYNC_STD,DMFM_STD
		TLEND
DMFM_RN:
		addq.l	#4,a0

		moveq	#12-1,d2
.loop2
		moveq	#$7F,d3
		move.l	#$55555555,d4
		moveq	#0,d5
.loop
		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d4,d0
		and.l	d4,d1
		add.l	d0,d0
		or.l	d1,d0
		move.l	d0,(a1)+
		eor.w	d0,d5
		dbf	d3,.loop

		move.w	(a0)+,d0
		move.w	(a0)+,d1
		and.w	d4,d0
		and.w	d4,d1
		add.l	d0,d0
		or.l	d1,d0
		eor.w	d0,d5
		bne.b	.error

		dbf	d2,.loop2

		moveq	#IERR_OK,d0
		rts
.error
		moveq	#IERR_CHECKSUM,d0
		rts
