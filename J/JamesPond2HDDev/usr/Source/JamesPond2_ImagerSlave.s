***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      JAMES POND 2 IMAGER SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               March 2015                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 13-Mar-2015	- support for Kixx budget version (which is just a stolen
;		  Skid Row crack...) added

; 10-Mar-2015	- took a while but decoding is now correct!
;		- saves files

; 09-Nar-2015	- work started
;		- reads the track data but decoding is not 100% correct


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"James Pond 2 imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(13.03.2015)",0
	CNOP	0,4


.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	.crc		; Table of certain tracks with CRC values
	dc.l	.disk1_kixx	; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.crc	CRCENTRY	0,$97f4	; original version, SPS 1352
	CRCEND

.disk1_kixx
	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks_kixx	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.tracks	TLENTRY	000,000,512*11,SYNC_STD,DMFM_STD
	TLENTRY	001,001,512*11,SYNC_STD,DMFM_NULL
	TLENTRY	002,159,512*11,SYNC_STD,DecodeTrack
	TLEND

.tracks_kixx
	TLENTRY	000,159,512*11,SYNC_STD,DMFM_STD
	TLEND


; d0.w: track number
; a0.l: MFM buffer
; a1.l: destination


DecodeTrack
	move.w	d0,d7		; save track number
	move.l	a1,a4
	
	move.l	#$55555555,d5	; mask
	move.l	a0,a2

	addq.w	#2,a2		; because of "cmp.w #$4489,(a2)+

	
	sub.w	#10,a2
	lea	8(a2),a0
	bsr.b	.DecodeLong	; decode track number

	cmp.b	d0,d7
	bne.b	.sector_error

	lea	$10(a2),a0
	bsr.b	.DecodeLong	; decode checksum
	move.l	d0,d6		; save

	lea	$18(a2),a0
	move.w	#$2800,d1
	bsr.b	.CalcChecksum

	cmp.l	d0,d6
	bne.b	.checksum_error

; decode track data
	add.w	#$18,a2

	moveq	#11-1,d7
.decode_track
	move.l	a2,a0
	move.w	#512,d0
	bsr.b	.DecodeSector
	add.w	#1024,a2
	dbf	d7,.decode_track

.ok	moveq	#IERR_OK,d0	
	rts

.checksum_error
	moveq	#IERR_CHECKSUM,d0
	rts

.sector_error
	moveq	#IERR_NOSECTOR,d0
	rts




.CalcChecksum
	lsr.w	#2,d1
	move.l	(a0)+,d0
	subq.w	#2,d1
.loop	move.l	(a0)+,d2
	eor.l	d2,d0
	dbf	d1,.loop
	and.l	d5,d0
	rts

.DecodeLong
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	d5,d0
	and.l	d5,d1
	add.l	d0,d0
	or.l	d1,d0
	rts

.DecodeSector
	lea	(a0,d0.w),a1
	lsr.w	#2,d0
	subq.w	#1,d0
.secloop
	move.l	(a0)+,d1
	move.l	(a1)+,d2
	and.l	d5,d1
	and.l	d5,d2
	add.l	d1,d1
	or.l	d2,d1
	move.l	d1,(a4)+
	dbf	d0,.secloop
	rts



SaveFiles
	moveq	#2,d0
	jsr	rawdic_ReadTrack(a5)

	move.l	a1,a4			; a4: start of directory
	moveq	#0,d6			; file number
	moveq	#($3000-$2c00)/8-1,d7
.savefiles
	movem.l	(a4)+,d0/d1		; offset (blocks), length (bytes)
	bsr.b	.convName

	lea	.name(pc),a0
	mulu.w	#512,d0
	jsr	rawdic_SaveDiskFile(a5)
	addq.w	#1,d6
	dbf	d7,.savefiles
.done	moveq	#IERR_OK,d0
	rts


.convName
	movem.l	d0/d1/a0,-(a7)
	move.w	d6,d0
	lea	.num(pc),a0
	moveq	#3-1,d3		; convert 3 digits
	lea	.TAB(pc),a1
.loop	moveq	#-"0",d1
.loop2	sub.w	(a1),d0
	dbcs	d1,.loop2
	neg.b	d1
	move.b	d1,(a0)+
.nope	add.w	(a1)+,d0
	dbf	d3,.loop
	movem.l	(a7)+,d0/d1/a0
	rts

.TAB	dc.w	100
	dc.w	10
	dc.w	1

.name	dc.b	"jp2_"
.num	dc.b	"000",0



