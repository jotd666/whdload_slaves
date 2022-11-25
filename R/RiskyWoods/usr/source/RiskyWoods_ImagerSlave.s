***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        RISKY WOODS IMAGER SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               May 2016                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 06-Dec-2017	- and another file size bug fixed (add.w d1,d1 -> add.l d1,d1)

; 28-Nov-2017	- file size bug fixed

; 28-Jun-2016	- work started, done just for fun


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Risky Woods imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(06.12.2017)",0
	CNOP	0,4

.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.disk2	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.tracks	TLENTRY 000,159,$1600,SYNC_STD,DMFM_STD
	TLEND



SaveFiles
	move.w	d0,d5		; save disk number
	moveq	#0,d0
	jsr	rawdic_ReadTrack(a5)
	lea	$200(a1),a4	; a4: directory

	moveq	#0,d6
	move.w	.num(pc),d7	; file number
.save	move.w	d7,d0
	lea	.name(pc),a0
	bsr.b	.convName	; build file name

	move.w	(a4)+,d0
	moveq	#0,d1
	move.w	(a4)+,d1
	beq.b	.nextfile
	addq.w	#1,d6
	mulu.w	#512,d0
	add.l	d1,d1		; MUST be add.l here!
	jsr	rawdic_SaveDiskFile(a5)

.nextfile
	addq.w	#1,d7

	cmp.w	#"RW",(a4)	; end of file table?
	bne.b	.save

	cmp.w	#1,d5		; disk 1?
	bne.b	.nomain
	lea	.name(pc),a0	; save main file
	move.b	#"R",(a0)
	move.b	#"W",1(a0)
	move.l	#$400,d0
	move.l	#$fc00,d1
	jsr	rawdic_SaveDiskFile(a5)
.nomain

	move.w	d6,.num


.done	moveq	#IERR_OK,d0
	rts

.num	dc.w	0

.convName
	movem.l	d0/d1/a0,-(a7)
	moveq	#2-1,d3		; max. 2 digits
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

.TAB	dc.w	10
	dc.w	1

.name	dc.b	"00",0
	CNOP	0,2


