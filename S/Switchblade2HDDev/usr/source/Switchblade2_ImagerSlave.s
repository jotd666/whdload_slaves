***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       SWITCHBLAD II IMAGER SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2018                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 31-Oct-2018	- code optimised a bit
;		- boot file now saved too

; 30-Oct-2018	- work started
;		- and finished a few minutes

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Switchblade II imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(31.10.2018)",0
	CNOP	0,4

.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_SWAPSIDES	; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read


.tracks	TLENTRY 002,157,$1800,SYNC_STD,DecodeTrack
	TLEND


; d0.w: track
; a0.l: MFM buffer
; a1.l: destination
; a5.l: rawdic

DecodeTrack
	move.w	d0,d5		; save track number

	addq.w	#2,a0		; skip $5555 marker

	move.w	#$5555,d2	; mask
	moveq	#0,d3		; checksum
	move.w	#$1800/2-1,d7
.loop	bsr.b	.decode
	move.w	d0,(a1)+

	add.w	d0,d3

	dbf	d7,.loop
	
	bsr.b	.decode		; decode checksum
	cmp.w	d3,d0
	bne.b	.checksum_error

	bsr.b	.decode		; decode track number
	cmp.w	d5,d0
	bne.b	.checksum_error

	moveq	#IERR_OK,d0
	rts

.checksum_error
	moveq	#IERR_CHECKSUM,d0
	rts

.decode	move.w	(a0)+,d0
	move.w	(a0)+,d1
	and.w	d2,d0
	and.w	d2,d1
	add.w	d1,d1
	add.w	d1,d0
	rts


SaveFiles
	moveq	#3,d0		; directory is on track 3
	jsr	rawdic_ReadTrack(a5)
	lea	Dir,a0
	move.w	#$1800/4-1,d7
.copy	move.l	(a1)+,(a0)+
	dbf	d7,.copy

	lea	Dir,a4
.loop	tst.l	(a4)
	beq.b	.done

	move.l	a4,a0		; file name
	movem.l	16(a4),d0/d1	; offset, length
	sub.l	#$1800*2,d0
	bsr.b	.save
	lea	6*4(a4),a4	; 4 longs for the name, offset.l, size.l
	bra.b	.loop


.done	lea	.intro(pc),a0
	move.l	#$a6800,d0
	move.l	#$42000,d1
	bsr.b	.save
	lea	.boot(pc),a0
	moveq	#0,d0
	move.l	#$1800,d1

.save	jmp	rawdic_SaveDiskFile(a5)

.intro	dc.b	"intro.bin",0
.boot	dc.b	"boot.bin",0


	SECTION	DATA,BSS

Dir	ds.b	$1800


