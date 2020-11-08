
		; Zool 2 Imager
		;
		; Disk 1: Tracks 000-001: Sync ($4489), length $1600 bytes
		;         Tracks 002-159: Sync ($4489), length $1800 bytes
		;
		; Disk 2: Tracks 000-159: Sync ($4489), length $1800 bytes

		incdir	include:
		include	RawDIC.i

		OUTPUT	"Zool2.islave"

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0		; Slave flags
		dc.l	DSK_1		; Pointer to the first disk structure
		dc.l	Text		; Pointer to the text displayed in the imager window

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

		dc.b	"$VER:"
Text		dc.b	"Zool 2 imager V1.0",10
		dc.b	"by Codetapper/Action "
		INCBIN	"T:date"
		dc.b	0
		cnop	0,4

;=====================================================================

DSK_1		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_2		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1		TLENTRY 002,159,$1800,SYNC_STD,_RipTrack
		TLEND
		EVEN

TL_2		TLENTRY 000,159,$1800,SYNC_STD,_RipTrack
		TLEND
		EVEN

;=====================================================================

_RipTrack	exg.l	a0,a1			;Game uses a0 as dest
						;and a1 as MFM
		move.w	#$c00-1,d7
		move.w	#$5555,d2
		move.w	#0,d3

_Find5555	move.w	(a1)+,d0
		cmpi.w	#$5555,d0
		bne.b	_Find5555

_DecodeLoop	move.w	(a1)+,d0
		move.w	(a1)+,d1
		and.w	d2,d0
		and.w	d2,d1
		add.w	d1,d1
		or.w	d1,d0
		add.w	d0,d3
		move.w	d0,(a0)+
		dbra	d7,_DecodeLoop
		move.w	(a1)+,d0
		move.w	(a1)+,d1
		and.w	d2,d0
		and.w	d2,d1
		add.w	d1,d1
		add.w	d0,d1
		move.w	d1,d7
		cmp.w	d3,d7
		bne.b	_Checksum

_OK		moveq	#IERR_OK,d0
		rts

_Checksum	moveq	#IERR_CHECKSUM,d0
		rts
