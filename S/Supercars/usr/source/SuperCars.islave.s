
		; Super Cars Imager - 16 bit Hit Machine (1 disk)
		;                   - Hit Squad (1 disk)
		;                   - 2 disk version
		;
		; Disk 1: Tracks 000-000: Sync ($4489), length $1600 bytes
		;         Tracks 001-001: Sync ($4124), length $1800 bytes (protection)
		;         Tracks 002-159: Sync ($4489), length $1800 bytes
		;
		; Disk 2: Tracks 000-159: Sync ($4489), length $1800 bytes
		;
		; Changes: 21/04/2015 - Calls rawdic_NextSync to locate
		;                       next sync if $5555 is not found
		;			after the sync marks

		incdir	include:
		include	RawDIC.i

		OUTPUT	"SuperCars.islave"

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0		; Slave flags
		dc.l	HITMACH_DISK_1	; Pointer to the first disk structure
		dc.l	Text		; Pointer to the text displayed in the imager window

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

		dc.b	"$VER:"
Text		dc.b	"Super Cars imager V1.3",10
		dc.b	"by Codetapper/Action "
		INCBIN	"T:date"
		dc.b	0
		cnop	0,4

;=====================================================================

HITMACH_DISK_1	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	HITMACH_TL_1	; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	HITMACH_CRC_1	; Table of certain tracks with CRC values
		dc.l	DOUBLE_DISK_1	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

HITMACH_CRC_1	CRCENTRY 002,$31c1	; Ronny Illgen's single disk version
		CRCEND			; (16 bit Hit Machine)
		EVEN

HITMACH_TL_1	TLENTRY 002,135,$1800,SYNC_STD,_RipTrack
		TLEND
		EVEN

;=====================================================================

DOUBLE_DISK_1	dc.l	DOUBLE_DISK_2	; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	DOUBLE_TL_1	; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	DOUBLE_CRC_1	; Table of certain tracks with CRC values
		dc.l	HITSQUAD_DISK_1	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DOUBLE_DISK_2	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	DOUBLE_TL_2	; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DOUBLE_CRC_1	CRCENTRY 002,$010d
		CRCEND
		EVEN

DOUBLE_TL_1	TLENTRY 002,056,$1800,SYNC_STD,_RipTrack
		TLEND
		EVEN

DOUBLE_TL_2	TLENTRY 000,148,$1800,SYNC_STD,_RipTrack
		TLEND
		EVEN

;=====================================================================

HITSQUAD_DISK_1	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES|DFLG_NORESTRICTIONS	; Disk flags
		dc.l	HITSQUAD_TL_1	; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	HITSQUAD_FL_1	; List of files to be saved
		dc.l	HITSQUAD_CRC_1	; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

HITSQUAD_CRC_1	CRCENTRY 002,$9622	; Matthew Thompson's single disk version
		CRCEND			; (Hit Squad)
		EVEN

HITSQUAD_TL_1	TLENTRY 001,001,$1600,SYNC_STD,DMFM_STD
		TLENTRY 000,000,$1600,SYNC_STD,DMFM_STD
		TLENTRY 000,000,$0400,SYNC_STD,DMFM_NULL
		TLENTRY 002,157,$1800,SYNC_STD,_RipTrack
		TLEND
		EVEN

HITSQUAD_FL_1	FLENTRY	FL_Boot,0,$1600*1
		FLENTRY	FL_Disk,$1800*2,$1800*156
		FLEND

FL_Boot		dc.b	"SuperCars.boot",0
FL_Disk		dc.b	"Disk.1",0
		EVEN

;=====================================================================

_RipTrack	move.w	#$c00-1,d7
		move.w	#$5555,d2
		move.w	#0,d3

_Find5555	move.w	(a0)+,d0
		cmp.w	d2,d0
		beq	_DecodeLoop

		jsr	rawdic_NextSync(a5)
		bra	_Find5555

_DecodeLoop	bsr	_ReadWord
		add.w	d0,d3
		move.w	d0,(a1)+
		dbra	d7,_DecodeLoop

		bsr	_ReadWord
		cmp.w	d0,d3
		bne.b	_Checksum

_OK		moveq	#IERR_OK,d0
		rts

_Checksum	moveq	#IERR_CHECKSUM,d0
		rts

_ReadWord	move.w	(a0)+,d0
		move.w	(a0)+,d1
		and.w	d2,d0
		and.w	d2,d1
		add.w	d1,d1
		or.w	d1,d0
		rts
