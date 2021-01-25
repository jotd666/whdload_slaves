	; Psygnosis imager

	; A track contains 6 sectors, each containing 1024 bytes data.

	; Sector format description:

	; sync ($4489)
	; word ($4489)*3
	; 1 word checksum
	; 512 words data

		incdir	Include:
		include	RawDIC.i
		OUTPUT	RedZone.islave

		SLAVE_HEADER
		dc.b	2	; Slave version (RawDIC v3.3)
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Red Zone imager V1.0",10,"by JOTD & Mr.Larmer on 21.03.2005",0
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

TL_1:
	TLENTRY	2,131,$1800,SYNC_STD,DMFM_RN
	TLENTRY	132,132,$1800,SYNC_STD,DMFM_NULL	; faulty track (PAL)
	TLENTRY	133,159,$1800,SYNC_STD,DMFM_RN
	TLEND
TL_2:
	TLENTRY	2,159,$1800,SYNC_STD,DMFM_RN
	TLEND

SaveFiles:
	; read bootblock

	move.l	#2,d0
	jsr	rawdic_ReadTrack(a5)	;a1 = Track buffer

	move.l	A1,A0
	lea	$1000(A0),A1
	move.l	a0,a3		; for directory buffer, variable $10 by $10
	lea	$C00(A0),A2	; for directory block list, constant
	moveq.l	#0,D6		; the file counter

	; LOOP ON THE FILES
.wloop
	lea	$10(A3),A3	; add $10 (first file is always "Reserved")
	addq.l	#1,D6		; add $1 to file counter

	cmp.l	A2,A3
	bcc.b	.ok

	cmp.b	#$ff,(A3)	; no name -> skip
	beq	.nextfile

	; first, create empty file

	move.l	a3,a0
	move.l	a0,a1
	moveq.l	#0,d0
	jsr	rawdic_SaveFile(a5)

	move.l	$C(A3),D0	; file length
	move.l	D0,.filesize	; store the size

	; search the block bitmap for relevant blocks

	moveq.l	#0,D3	; block counter
.sloop
	move.b	(A2,D3.W),D4	; block index

	cmp.w	#$3FF,D3
	bcs	.notend

	cmp.b	#$FF,D4
	beq	.nextfile	; end of block info -> next file please
	bra	.error	; ripped disk corrupt, directory error

.notend
	cmp.b	D6,D4		; block index matches our file??
	beq	.matchblock
.nextblock
	addq.l	#1,D3		; next offset
	bra	.sloop

	; *** calculate the real offset and copy the block in the buffer
.matchblock
	move.l	D3,D0		; copy position
	mulu	#$400,d0
	sub.l	#$3000,D0	; we started from physical track 2

	; write to disk from offset D0

	move.l	#$400,d1	; max length to write at one time
	cmp.l	.filesize(pc),d1
	bcs.b	.write400
	; filesize < d1: write filesize len instead of $400
	move.l	.filesize(pc),d1
.write400
	sub.l	d1,.filesize
	move.l	a3,a0	; name
	jsr	rawdic_AppendDiskFile(a5)

	bra	.nextblock

.nextfile
	bra	.wloop


.ok
	moveq	#IERR_OK,d0
	rts
.error
	moveq	#IERR_CHECKSUM,d0
	rts
.filesize
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
