	; Rob Northen imager

	; A track contains 12 sectors, each containing 512 bytes data.

	; Sector format description:

	; sync ($1448)
	; word ($4891)
	; 1 word checksum
	; 256 words data

		incdir	Includes:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Alien Breed 2 imager V1.0",10,"by Mr.Larmer on 16.03.2001",0
		cnop	0,4

DSK_1:		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS	; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_2:		dc.l	DSK_3		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_3:		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_3		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1:
		TLENTRY	0,1,$1600,SYNC_STD,DMFM_STD
		TLENTRY	1,1,$400,SYNC_INDEX,DMFM_NULL
		TLENTRY	2,159,$1800,$1448,DMFM_RN_1
		TLEND

TL_2:
		TLENTRY	0,159,$1800,$1448,DMFM_RN_2
		TLEND

TL_3:
		TLENTRY	0,159,$1800,$1448,DMFM_RN_3
		TLEND

DMFM_RN_1:
		move.l	#$00123111,d7	; ID for disk 1
		bra.b	decode
DMFM_RN_2:
		move.l	#$00123222,d7	; ID for disk 2
		bra.b	decode
DMFM_RN_3:
		move.l	#$00123333,d7	; ID for disk 3
decode
		move.l	#$55555555,d3
		moveq	#12-1,d4
		move.l	d0,d6		; track
.loop
		cmp.w	#$4891,(a0)+
		bne.b	.sectorerror

		move.l	(a0)+,d1
		move.l	(a0)+,d2
		andi.l	d3,d1
		andi.l	d3,d2
		lsl.l	#1,d1
		or.l	d2,d1
		move.l	d7,d0
		bset	#31,d0
		eor.l	d0,d1

		bsr.b	.CalcChecksum
		cmp.w	d0,d1
		bne.b	.checksumerror

		bclr	#31,d1
		swap	d1
		cmp.b	d1,d6		; track nr
		bne.b	.trackerror
		ror.l	#8,d1
		and.l	#$F,d1		; block in track
		mulu	#$200,d1
		move.l	a1,a3
		add.l	d1,a3

		moveq	#$7F,d0
		move.l	d7,d5
		lea	$200(a0),a2
.loop2
		move.l	(a0)+,d1
		move.l	(a2)+,d2
		and.l	d3,d1
		and.l	d3,d2
		lsl.l	#1,d1
		or.l	d2,d1
		eor.l	d1,d5
		move.l	d5,(a3)+
		move.l	d1,d5
		dbf	d0,.loop2

		lea	(a2),a0
		move.w	(a0)+,d0

		moveq	#0,d1
		moveq	#7,d2
.loop3
		roxl.w	#2,d0
		roxl.b	#1,d1
		dbf	d2,.loop3

		add.w	d1,d1
		add.l	d1,a0

		dbf	d4,.loop

		moveq	#IERR_OK,d0
		rts
.checksumerror
		moveq	#IERR_CHECKSUM,d0
		rts
.trackerror
		moveq	#IERR_NOTRACK,d0
		rts
.sectorerror
		moveq	#IERR_NOSECTOR,d0
		rts

.CalcChecksum
		movem.l	d1-d2/a0,-(a7)

		moveq	#0,d0
		move.w	#$FF,d1
.loop4
		move.l	(a0)+,d2
		eor.l	d2,d0
		dbra	d1,.loop4

		and.l	d3,d0
		move.l	d0,d1
		swap	d1
		add.w	d1,d1
		or.w	d1,d0

		movem.l	(a7)+,d1-d2/a0
		rts
