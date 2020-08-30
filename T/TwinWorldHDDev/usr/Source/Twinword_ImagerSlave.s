***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         TWINWORLD IMAGER SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            November 2017                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 02-Nov-2017	- work started
;		- and finished a short while later


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Twinworld imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(02.11.2017)",0
	CNOP	0,4



.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_DOUBLEINC	; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.tracks	TLENTRY	003,0159,$1790,$5542,DecodeTrack
	TLENTRY	002,0158,$1790,$5542,DecodeTrack
	TLEND



; d0.w: track number
; a0.l: ptr to mfm buffer
; d6.w: number of bytes to decode-1
; a1.l: ptr to destination buffer

DecodeTrack
	move.w	d0,d7
	move.l	#$55555555,d6

	exg	a0,a1
	addq.l	#2,a1
	bsr.b	.decode		; decode track number
	rol.l	#8,d0
	cmp.b	d7,d0		; check disabled as I can't be bothered
	;bne.b	.error		; to adapt it
	rol.l	#8,d0
	cmp.b	#1,d0
	bne.b	.error
	move.w	#$1790/4-1,d7
.loop	bsr.b	.decode
	move.l	d0,(a0)+
	dbf	d7,.loop
	moveq	#IERR_OK,d0
	rts

.error	moveq	#IERR_CHECKSUM,d0
	rts

.decode	move.l	(a1)+,d0
	move.l	(a1)+,d1
	and.l	d6,d0
	add.l	d0,d0
	and.l	d6,d1
	or.l	d1,d0
	rts


