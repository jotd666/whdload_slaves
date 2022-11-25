		incdir	Include:
		include	RawDIC.i

		OUTPUT	"Virocop.islave"

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text		dc.b	"Virocop imager V1.0",10
		dc.b	"by Abaddon on 01/10/2012"
		
		dc.b	0
		cnop	0,4

DSK_1		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_RAWREADONLY	; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read


TL_1
		TLENTRY	000,159,$1600,$4489,_MFM
		TLEND

DSK_2		dc.l	DSK_3		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_RAWREADONLY	; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

;7d
TL_2
		TLENTRY	000,124,$1600,$4489,_MFM
		TLEND


DSK_3		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_RAWREADONLY	; Disk flags
		dc.l	TL_3		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read


TL_3
		TLENTRY	000,123,$1600,$4489,_MFM
		TLEND

;======================================================================


_MFM
		move.l		#$55555555,d3
		moveq		#$a,d5
		moveq		#0,d6
		bra		.start
.readnext	jsr		rawdic_NextSync(a5)
.start		movea.l		a0,a2
		move.l		(a2)+,d0
		move.l		(a2)+,d1
		and.l		d3,d0
		and.l		d3,d1
		add.l		d0,d0
		or.l		d1,d0
		lsr.w		#8,d0
		cmp.b		d0,d6
		bne		.readnext
		add.b		#$1,d6
		mulu.w		#$200,d0
		lea		(a1,d0.l),a3
		lea		($38,a0),a2
		lea		($200,a2),a4
		moveq		#$7f,d4
.decode		move.l		(a2)+,d0
		move.l		(a4)+,d1
		and.l		d3,d0
		and.l		d3,d1
		add.l		d0,d0
		or.l		d1,d0
		move.l		d0,(a3)+
		dbf		d4,.decode	
		dbf		d5,.readnext
		moveq		#IERR_OK,d0
		rts


