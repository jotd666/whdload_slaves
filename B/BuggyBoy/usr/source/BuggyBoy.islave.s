
		; Buggy Boy imager
		;
		; Tracks 000-000: Sync $4489 (Dos)
		; Tracks 001-067: Sync $a245, $18a8 bytes of data

		incdir	Include:
		include	RawDIC.i

		IFD	BARFLY
		OUTPUT	"BuggyBoy.islave"
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC
		ENDC

;=====================================================================

TRACK_SIZE	equ	$18a8

;=====================================================================

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0		; Slave flags
		dc.l	DSK_Tenstar	; Pointer to the first disk structure
		dc.l	Text		; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text		dc.b	"Buggy Boy imager V1.1",10
		dc.b	"by Codetapper/Action "
		IFD	BARFLY
		INCBIN	"T:date"
		ELSE
		dc.b	"(17.05.2014)"
		ENDC
		dc.b	0
		cnop	0,4

DSK_Tenstar	dc.l	0			; Pointer to next disk structure
		dc.w	1			; Disk structure version
		dc.w	DFLG_NORESTRICTIONS	; Disk flags
		dc.l	TL_Tenstar		; List of tracks which contain data
		dc.l	0			; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE		; List of files to be saved
		dc.l	CRC_Tenstar		; Table of certain tracks with CRC values
		dc.l	DSK_Tenstar_V2		; Alternative disk structure, if CRC failed
		dc.l	0			; Called before a disk is read
		dc.l	0			; Called after a disk has been read

DSK_Tenstar_V2	dc.l	0			; Pointer to next disk structure
		dc.w	1			; Disk structure version
		dc.w	DFLG_NORESTRICTIONS	; Disk flags
		dc.l	TL_Tenstar		; List of tracks which contain data
		dc.l	0			; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE		; List of files to be saved
		dc.l	CRC_Tenstar_V2		; Table of certain tracks with CRC values
		dc.l	DSK_Story		; Alternative disk structure, if CRC failed
		dc.l	0			; Called before a disk is read
		dc.l	0			; Called after a disk has been read

DSK_Story:	dc.l	0			; Pointer to next disk structure
		dc.w	1			; Disk structure version
		dc.w	DFLG_NORESTRICTIONS	; Disk flags
		dc.l	TL_Story		; List of tracks which contain data
		dc.l	0			; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE		; List of files to be saved
		dc.l	CRC_Story		; Table of certain tracks with CRC values
		dc.l	0			; Alternative disk structure, if CRC failed
		dc.l	0			; Called before a disk is read
		dc.l	0			; Called after a disk has been read

TL_Tenstar	TLENTRY 000,000,$1600,SYNC_STD,DMFM_STD
		TLENTRY 000,000,TRACK_SIZE-$1600,SYNC_STD,DMFM_NULL
		TLENTRY	001,067,TRACK_SIZE,$a245,_DMFM_BuggyBoy
		TLEND

TL_Story	TLENTRY 000,000,$1600,SYNC_STD,DMFM_STD
		TLENTRY 000,000,TRACK_SIZE-$1600,SYNC_STD,DMFM_NULL
		TLENTRY	001,073,TRACK_SIZE,$a245,_DMFM_BuggyBoy
		TLEND

CRC_Tenstar	CRCENTRY 000,$6f9c
		CRCEND

CRC_Tenstar_V2	CRCENTRY 000,$3769
		CRCEND

CRC_Story	CRCENTRY 000,$fd1a
		CRCEND

;=====================================================================

_DMFM_BuggyBoy	add.w	#2,a0			;Skip second $4489 sync
		move.l	a0,a3
		move.l	a1,a4
		move.l	#$55555555,d3
		move.w	(a3)+,d2
		move.w	(a3)+,d1
		moveq	#0,d4
		move.w	#$629,d6
_DecodeLoop	move.l	($18AC,a3),d1
		and.l	d3,d1
		move.l	(a3)+,d2
		and.l	d3,d2
		add.l	d2,d2
		or.l	d2,d1
		add.l	d1,d4
		move.l	d1,(a4)+
		dbra	d6,_DecodeLoop
		move.l	($18AC,a3),d1
		and.l	d3,d1
		move.l	(a3)+,d2
		and.l	d3,d2
		add.l	d2,d2
		or.l	d2,d1
		not.l	d4
		cmp.l	d4,d1
		bne	_Checksum

_OK		moveq	#IERR_OK,d0		;No error
		rts

_Checksum	moveq	#IERR_CHECKSUM,d0
		rts

;=====================================================================
