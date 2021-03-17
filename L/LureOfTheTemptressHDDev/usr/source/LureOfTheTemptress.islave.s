***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    LURE OF THE TEMPTRESS IMAGER SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             March 2021                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 07-Mar-2021	- optimised the code a bit
;		- COMPATIBILITY_MODE flag added

; 06-Mar-2021	- work started


; This flag changes the way disk 1 (boot) is created.
; If it is set to 1, the first $1800 bytes will be filled
; with empty data (this is how the old images have been created),
; if it is set to 0, the real data from track 0 (AmigaDOS) will be stored
; and padded to $1800 bytes.

COMPATIBLE_MODE	= 0


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Lure of the Temptress imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(07.03.2021)",0
	CNOP	0,4


.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_NORESTRICTIONS		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.disk2	dc.l	.disk3		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.disk3	dc.l	.disk4		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.disk4	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.tracks	IFEQ	COMPATIBLE_MODE-1
	TLENTRY	000,000,512*12,SYNC_STD,DMFM_NULL
	ELSE
	TLENTRY	000,000,512*11,SYNC_STD,DMFM_STD
	TLENTRY	000,000,512*01,SYNC_STD,DMFM_NULL
	ENDC

	TLENTRY 001,141,512*12,SYNC_STD,DecodeTrack
	TLEND

.tracks2
	TLENTRY 000,141,512*12,SYNC_STD,DecodeTrack
	TLEND


; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeTrack
	move.w	d0,d6		; save track number

	move.l	#$55555555,d5	; mask

	lea	0(a0),a3
	moveq	#0,d7		; sector
.sector_loop
	; decode sector header (ID, track number, sector number)
	move.l	a3,a0
	bsr.b	.DecodeLong

	; check if sector number matches
	cmp.b	d7,d0
	bne.b	.SectorError

	; check if track number matches
	lsr.w	#8,d0
	cmp.w	d6,d0
	bne.b	.SectorError

	; check if sector ID is correct
	swap	d0
	cmp.w	#"PF",d0
	bne.b	.SectorError

	; calculate checksum over loaded data and compare
	; with wanted checksum
	lea	$10(a3),a0
	move.w	#512*2,d0
	bsr.b	.CalcChecksum
	move.l	d0,d1

	lea	8(a3),a0
	bsr.b	.DecodeLong
	cmp.l	d1,d0
	bne.b	.ChecksumError


	; decode sector data
	lea	$10(a3),a0
	move.w	#512,d0
	bsr.b	.DecodeSector

	add.w	#1040,a3
	addq.w	#1,d7
	cmp.w	#12,d7
	bne.b	.sector_loop

	moveq	#IERR_OK,d0
	rts

.SectorError
	moveq	#IERR_NOSECTOR,d0
	rts

.ChecksumError
	moveq	#IERR_CHECKSUM,d0
	rts



.DecodeSector
	lea	(a0,d0.w),a2
	lsr.w	#2,d0
	subq.w	#1,d0
.sloop	move.l	(a0)+,d1
	move.l	(a2)+,d2
	and.l	d5,d1
	and.l	d5,d2
	add.l	d1,d1
	or.l	d2,d1
	move.l	d1,(a1)+
	dbf	d0,.sloop
	rts

.DecodeLong
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	d5,d0
	and.l	d5,d1
	add.l	d0,d0
	or.l	d1,d0
	rts

.CalcChecksum
	movem.l	d1/d2/a0,-(sp)
	move.l	d0,d1
	lsr.w	#2,d1
	subq.w	#1,d1
	moveq	#0,d0
.loop	move.l	(a0)+,d2
	eor.l	d2,d0
	dbf	d1,.loop
	and.l	d5,d0
	movem.l	(sp)+,d1/d2/a0
	rts
