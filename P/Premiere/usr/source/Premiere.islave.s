	; Premiere (Core Design) imager

	; A track contains 6 sectors, each containing 1024 bytes data.

	; Sector format description:

	; sync ($8915)
	; word ($8915)*3
	; 1 word checksum
	; 512 words data

		incdir	Include:
		include	RawDIC.i
		OUTPUT	Premiere.islave

		SLAVE_HEADER
		dc.b	2	; Slave version (RawDIC v3.3)
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Premiere imager V1.0",10,"by JOTD on 21.11.2005",0
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
		dc.l	DSK_3		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_NULL	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	SaveFiles	; Called after a disk has been read

DSK_3:		
		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_NULL	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	SaveFiles	; Called after a disk has been read

TL_1:
	TLENTRY	1,159,$1600,$8915,DMFM_PREMIERE
	TLEND

SaveFiles:
	; read bootblock

	move.l	#1,d0
	jsr	rawdic_ReadTrack(a5)	;a1 = Track buffer

	lea	$200(A1),A2	; for directory block list
	lea	fat(pc),a3
	move.w	#($1400/4)-1,d0
.copy
	move.l	(a2)+,(a3)+
	dbf	d0,.copy

	lea	fat(pc),a2

	; LOOP ON THE FILES
.wloop
	tst.b	(A2)
	beq	.ok

	; get the file size and first sector

	moveq.l	#0,D4
	moveq.l	#0,D5

	move.l	($10,A2),D6	; file size
	move.w	($14,A2),D4	; track
	move.w	($16,A2),D5	; sector

	movem.l	d0-d7/a0-a6,-(a7)

	; first, create empty file

	move.l	a2,a0
	move.l	a0,a1
	moveq.l	#0,d0
	jsr	rawdic_SaveFile(a5)

	movem.l	(a7)+,d0-d7/a0-a6

.loop2
	; get offset for a sector

	bsr	.get_offset

	move.l	#$1FC,D1	; length if file still to read
	cmp.l	D1,D6
	bcc	.writewhole
	move.l	D6,D1		; only writes D6 bytes (<$1FC)
.writewhole
	; write some data to the file

	movem.l	d0-d7/a0-a6,-(a7)
	move.l	a2,a0	; name
	jsr	rawdic_AppendDiskFile(a5)
	movem.l	(a7)+,d0-d7/a0-a6

	sub.l	d1,d6		; length remaining to be read
	beq.b	.nextfile
	bcc.b	.loop2

.nextfile
	lea	($20,a2),a2
	bra	.wloop

.ok
	moveq	#IERR_OK,d0
	rts
.error
	moveq	#IERR_CHECKSUM,d0
	rts

; <> D4 track (updated)
; <> D5 sector (updated)
; > D0 offset

.get_offset
	; then, load the track needed

	move.l	d4,d0
	jsr	rawdic_ReadTrack(a5)	;a1 = Track buffer

	subq.l	#1,D4		; because we did not rip track 0 (dos boot)
	mulu	#$B,D4		; 1 track = 11 sectors
	add.l	D5,D4
	lsl.l	#8,D4		; * $100
	add.l	D4,D4		; * $200: offset in bytes
	move.l	d4,d0
	addq.l	#4,d0

	lsl.l	#8,D5		; * $100
	add.l	D5,D5		; * $200: offset in bytes
	add.l	d5,a1		; buffer to read next data from
	moveq.l	#0,D4
	moveq.l	#0,D5
	move.w	(A1)+,D4
	move.w	(A1)+,D5	; next track/sector

	rts

.filesize
	dc.l	0

; a0 raw
; a1 dec

DMFM_PREMIERE:
	moveq.l	#0,D7
	bsr	DecodeLong
	move.l	D6,.checksum

	sub.l	#4,a1
	move.l	#$57F,D7
	bsr	DecodeLong

	cmp.l	.checksum,D6
	bne	.error
.ok
	moveq	#IERR_OK,d0
	rts
.error
	moveq	#IERR_CHECKSUM,d0
	rts

.checksum
	dc.l	0

; < D7-1: number of longwords to read

DecodeLong:
	MOVEQ	#0,D6			;2A2: 7C00
loop:
	MOVE.L	(A0)+,D0		;2A4: 2018
	MOVE.L	(A0)+,D1		;2A6: 2218
	ANDI.L	#$55555555,D0		;2A8: 028055555555
	ANDI.L	#$55555555,D1		;2AE: 028155555555
	ADD.L	D0,D0			;2B4: D080
	OR.L	D1,D0			;2B6: 8081
	MOVE.L	D0,(A1)+		;2B8: 22C0
	ADD.L	D0,D6			;2BA: DC80
	DBF	D7,loop
	RTS				;2C0: 4E75

fat
	ds.b	$1400
