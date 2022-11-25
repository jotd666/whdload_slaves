	; HollywoodPokerPro imager

	; Sector format description:


		incdir	Include:
		include	RawDIC.i
		OUTPUT	HollywoodPokerPro.islave

		SLAVE_HEADER
		dc.b	2	; Slave version (RawDIC v3.3)
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Hollywood Poker Pro imager V1.0",10,"by JOTD & Dark Angel on 21.03.2006",0
		cnop	0,4

DSK_1:		
		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_NULL	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	SaveFiles	; Called after a disk has been read

DSK_2:		
		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_NULL	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	SaveFiles	; Called after a disk has been read

SYNC_MFM_HP = $9521
LENGTH_MFM_HP	= $1998

TL_1:
	TLENTRY	1,133,LENGTH_MFM_HP,SYNC_MFM_HP,DMFM_HP
	TLEND
TL_2:
	TLENTRY	1,128,LENGTH_MFM_HP,SYNC_MFM_HP,DMFM_HP
	TLEND

SaveFiles:
	; read bootblock

	move.l	#1,d0
	jsr	rawdic_ReadTrack(a5)	;a1 = Track buffer

	move.l	A1,A0
	move.l	a0,a3		; for directory buffer, variable $16 by $16
	lea	$1000(A0),A2	; for directory buffer end

	; LOOP ON THE FILES
.wloop
	cmp.l	A2,A3
	bcc.b	.ok
	cmp.b	#$0,(A3)	; no name : end
	beq	.ok

	moveq.l	#0,d0
	move.b	$10(a3),d0
	subq.l	#1,d0
	mulu	#LENGTH_MFM_HP,d0	; offset
	move.l	$12(a3),d1	; length
	move.l	a3,a0	; name
	jsr	rawdic_SaveDiskFile(a5)

.nextfile
	add.l	#$16,a3
	bra	.wloop


.ok
	moveq	#IERR_OK,d0
	rts
.error
	moveq	#IERR_CHECKSUM,d0
	rts
.filesize
	dc.l	0


; < a0: raw
; < a1: decoded

DMFM_HP:
;;		addq.l	#4,a0

	addq.l	#2,a0
	move.l	#$55555555,d3
	move.l	d3,d4
	add.l	d4,d4

	move.l	a0,-(sp)

	moveq	#0,d0
	move	#LENGTH_MFM_HP/2-1,d7
.check	move.l	(a0)+,d1
	eor.l	d1,d0
	dbf	d7,.check

	and.l	d3,d0
	eor.l	d4,d0
	move.l	d0,d5

	bsr.b	.getone

	move.l	(sp)+,a0

	cmp.l	d0,d5
	bne.b	.error

	move	#LENGTH_MFM_HP/4-1,d7
.decode	bsr.b	.getone
	move.l	d0,(a1)+
	dbf	d7,.decode
	moveq	#IERR_OK,d0
	rts
.error
	moveq	#IERR_CHECKSUM,d0
	rts
;---

.getone	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	d3,d0
	and.l	d3,d1
	add.l	d0,d0
	or.l	d1,d0
	rts
;---
