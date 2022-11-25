***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          HUNTER IMAGER SLAVE               )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2018                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 10-Oct-2018	- fixed disk saving code, offset for the second part was
;		  wrong (skipped only $1400 bytes instead of $1600)

; 07-Oct-2018	- too many problems with the custom decoder for track,
;		  now track 1 is handled as standard $1600 bytes DOS track
;		  and later converted to a $1400 bytes when saving the
;		  disk image (using rawdic_Save/AppendFile)

; 04-Oct-2018	- added custom decoder for track 1 which just decodes
;		  a normal DOS track but only uses 10 sectors, done to make
;		  the imager compatible with the old format produced by
;		  Harry's "The Patcher" imager so people don't have to
;		  reinstall the game

; 01-Oct-2018	- new approach, works but no checksum checks yet
;		- a while later: checksum check added, imager finished

; 30-Sep-2018	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Hunter imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(10.10.2018)",0
	CNOP	0,4

.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_DOUBLEINC		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	InitCRC		; Called before a disk is read
	dc.l	.SaveDisk	; Called after a disk has been read

.tracks	TLENTRY	000,000,512*11,SYNC_STD,DMFM_STD
	;TLENTRY	001,001,512*10,SYNC_STD,DMFM_NULL
	TLENTRY 002,158,512*10,SYNC_STD,.DecodeTrack
	TLENTRY	003,159,512*10,SYNC_STD,.DecodeTrack
	TLEND



.SaveDisk
	lea	.name(pc),a0
	moveq	#0,d0			; offset
	move.l	#512*10,d1		; length
	jsr	rawdic_SaveDiskFile(a5)
	lea	.name(pc),a0
	move.l	#512*11,d0
	move.l	#158*512*10,d1
	jsr	rawdic_AppendDiskFile(a5)
	moveq	#IERR_OK,d0
	rts


.name	dc.b	"Disk.1",0
	CNOP	0,4





; d0.w: track
; a0.l: MFM buffer
; a1.l: destination
; a5.l: rawdic

.DecodeTrack
	move.l	a1,a3


	moveq	#0,d4			; side number
	moveq	#0,d5				; addx reg

	lsr.w	#1,d0
	addx.b	d5,d4			; odd track number -> side = 1

	move.w	d0,d5			: save track number


	moveq	#10-1,d7		; # of sectors per track
	bra.b	.first

.loop	jsr	rawdic_NextSync(a5)
.first	move.w	(a0),d0
	bsr.b	.DecodeByte
	cmp.b	#$fe,d0			; header block?
	bne.b	.loop

; decode header data
	move.w	2(a0),d0		; decode track number
	bsr.b	.DecodeByte
	cmp.b	d5,d0
	bne.b	.sector_error
	move.w	4(a0),d0		; decode side
	bsr.b	.DecodeByte
	cmp.b	d4,d0
	bne.b	.sector_error


; header is ok, decode sector data
	move.w	6(a0),d0		; decode sector number (1-10)
	bsr.b	.DecodeByte
	subq.b	#1,d0
	cmp.b	#10,d0			; 0-9 only
	bcc.b	.sector_error
	mulu.w	#512,d0
	lea	(a3,d0.w),a4		; destination

; find start of data block
	jsr	rawdic_NextSync(a5)
	subq.w	#3*2,a0

	move.w	3*2(a0),d0
	bsr.b	.DecodeByte
	cmp.b	#$fb,d0			; data block?
	bne.b	.sector_error

; decode and check data
	bsr.b	.CheckData
	tst.l	d0
	bne.b	.checksum_error

	addq.w	#4,a0
	moveq	#512/4-1,d6
.copy	move.l	(a0)+,(a4)+
	dbf	d6,.copy

	dbf	d7,.loop


	moveq	#IERR_OK,d0
	rts

.checksum_error
	moveq	#IERR_CHECKSUM,d0
	rts

.sector_error
	moveq	#IERR_NOSECTOR,d0
	rts

.DecodeByte
	REPT	8
	add.w	d0,d0
	add.l	d0,d0
	ENDR

	swap	d0
	rts


; a0.l: mfm data
.CheckData
	move.l	a0,a1
	move.l	a1,a2
	move.w	#519-1,d1
.dloop	move.w	(a1)+,d0
	bsr	.DecodeByte
	move.b	d0,(a2)+
	dbf	d1,.dloop

	move.w	#517-1,d0
	bsr.w	Checksum
	bne.b	.checksum_error

	moveq	#0,d0
	rts



Checksum
	lea	CRC16Tab(pc),a1
	move.l	a0,a2
	moveq	#-1,d1
	moveq	#-1,d2
	subq.w	#1,d0
.loop	clr.w	d3
	move.b	(a2)+,d3
	eor.b	d1,d3
	move.b	(a1,d3.w),d1
	eor.b	d2,d1
	add.w	#256,d3
	move.b	(a1,d3.w),d2
	dbf	d0,.loop
	lsl.w	#8,d1
	move.b	d2,d1
	cmp.w	(a2),d1
	rts

InitCRC
	lea	CRC16Tab(pc),a1
	moveq	#0,d6
.loop	moveq	#0,d5
	move.b	d6,d5
	lsl.w	#8,d5
	moveq	#8-1,d0
.inner	add.w	d5,d5
	bcc.b	.skip
	eor.w	#$1021,d5
.skip	dbf	d0,.inner
	move.b	d5,256(a1)
	lsr.w	#8,d5
	move.b	d5,(a1)+
	addq.b	#1,d6
	bne.b	.loop
	rts


CRC16Tab	ds.w	256
