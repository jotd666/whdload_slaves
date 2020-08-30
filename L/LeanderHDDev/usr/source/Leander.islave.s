	; Psygnosis imager

	; A track contains 6 sectors, each containing 1024 bytes data.

	; Sector format description:

	; sync ($4489)
	; word ($4489)*3
	; 1 word checksum
	; 512 words data

		incdir	Include:
		include	RawDIC.i
		OUTPUT	Leander.islave

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Leander imager V1.0",10,"by JOTD & Mr.Larmer on 21.03.2005",0
		cnop	0,4

DISK_STRUCT:MACRO
		dc.l	\1		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_NULL	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	SaveFiles	; Called after a disk has been read
		ENDM

DSK_1:		
		DISK_STRUCT	DSK_2
DSK_2:		
		DISK_STRUCT	DSK_3
DSK_3:		
		DISK_STRUCT	0

TL_1:
		TLENTRY	2,159,$1800,SYNC_STD,DMFM_RN
		TLEND

SaveFiles:
	move.l	d0,.disk_number
	IFEQ	1
	lea	index(pc),a0
	move.l	#0,d0
	move.l	#$1000,d1
	jsr	rawdic_SaveDiskFile(a5)
	ENDC

	; read bootblock

	move.l	#2,d0
	jsr	rawdic_ReadTrack(a5)	;a1 = Track buffer

	move.l	A1,A0
	lea	$1000(A0),A1
	move.l	a1,d5		; upper limit
	move.l	a0,A3	; for directory buffer, variable $10 by $10
	lea	$C00(A0),A2	; for directory block list, constant
	move.l	a2,a4		; directory block list pointer
	moveq.l	#0,D6		; the file counter

	; LOOP ON THE FILES
.wloop

	lea	$10(A3),A3	; add $10
	addq.l	#1,D6		; add $1 to file counter

;;	cmp.l	A2,A3
;;	bcc	.ok

	; loop until we find the proper file counter
.lookup
	move.b	(a4)+,d0
	bmi	.ok
	cmp.l	a4,d5
	beq.b	.error
	cmp.b	d6,d0
	bne.b	.lookup

	cmp.b	#$ff,(A3)	; no name -> skip
	beq	.nextfile

	; create file

	move.l	a3,a0	; name
	cmp.l	#3,.disk_number
	bne.b	.sk
	cmp.b	#'S',(a0)
	bne.b	.sk
	cmp.b	#'H',1(a0)
	bne.b	.sk
	cmp.b	#'O',2(a0)
	bne.b	.sk
	bra.b	.nextfile	; skip SHOP file on disk 3: corrupt
.sk
	move.l	a4,d0
	subq.l	#1,d0		; one less because of (a4)+
	sub.l	a2,d0		; offset in bytes
	mulu.w	#$400,d0	; offset in sectors
	sub.l	#$3000,D0	; we started from physical track 2
	move.l	$C(A3),d1	; file size
	jsr	rawdic_SaveDiskFile(a5)

.nextfile
	bra	.wloop

;index
;	dc.b	"index",0
	even

.ok
		moveq	#IERR_OK,d0
		rts
.error
		moveq	#IERR_CHECKSUM,d0
		rts
.disk_number	
	dc.l	0

DMFM_RN:
		addq.l	#4,a0

		moveq	#6-1,d2
.loop
		moveq	#2,d7
		bsr.w	GetWord
		move.w	(a1),d0

		move.l	#$400,d7
		bsr.w	GetWord

		bsr.w	CalcChecksum
		lea	$400(a1),a1
		cmp.w	d0,d1
		bne.b	.error

		dbf	d2,.loop

		moveq	#IERR_OK,d0
		rts
.error
		moveq	#IERR_CHECKSUM,d0
		rts

CalcChecksum
		movem.l	d7/a1,-(sp)
		move.w	#$1FF,d7
		moveq	#0,d1
.loop
		add.w	(a1)+,d1
		dbra	d7,.loop
		movem.l	(sp)+,d7/a1
		rts

GetWord
		movem.l	d0-d7/a1,-(sp)
		lsr.w	#1,d7
		subq.w	#1,d7
		move.w	#$5555,d4
		move.w	#$AAAA,d5
.loop
		move.w	(a0)+,d0
		move.w	(a0)+,d1
		asl.w	#1,d0
		and.w	d5,d0
		and.w	d4,d1
		or.w	d1,d0
		move.w	d0,(a1)+
		dbra	d7,.loop
		movem.l	(sp)+,d0-d7/a1
		rts
