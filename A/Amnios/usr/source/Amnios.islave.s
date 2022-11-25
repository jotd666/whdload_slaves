
	; Amnios imager

		incdir	Include:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Amnios imager V1.1",10,"by Mr.Larmer/Wanted Team on 07.12.1999",0
		cnop	0,4

DSK_1:		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_2:		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1:
		TLENTRY 0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY 1,1,$1800+$200,SYNC_STD,DMFM_NULL

;		TLENTRY 2,152,$1800,$4489,DMFM_NR
;		TLENTRY 153,159,$1800,$4489,DMFM_NULL

		TLENTRY 2,154,$1800,$4489,DMFM_NR

		TLEND
TL_2:
		TLENTRY 0,1,$1800,SYNC_STD,DMFM_NULL

;		TLENTRY 2,138,$1800,$4489,DMFM_NR_2
;		TLENTRY 139,139,$1800,$4489,DMFM_NULL
;		TLENTRY 140,159,$1800,$4489,DMFM_NR_2

		TLENTRY 2,159,$1800,$4489,DMFM_NR_2

		TLEND

DMFM_NR:
	cmp.w	#$5555,(A0)
	bne.b	.error

	move.l	#$55555555,D5

	addq.l	#8,A0

	lea	4(A0),A2
	bsr.b	GetLongWord
	addq.l	#4,A0
	move.l	D0,D7		; checksum

	move.w	#$3000,D1

	move.l	A0,-(A7)
	bsr.b	CalcChecksum
	move.l	(A7)+,A0

	cmp.l	D0,D7
	bne.b	.error

	move.w	#$1800,D2
	lea	(A0,D2.w),A2
	lsr.w	#2,D2
	subq.w	#1,D2
.loop
	bsr.b	GetLongWord
	move.l	D0,(A1)+
	dbf	D2,.loop

		moveq	#IERR_OK,d0
		rts
.error
		moveq	#IERR_CHECKSUM,d0
		rts

GetLongWord
	move.l	(A0)+,D0
	move.l	(A2)+,D1
	and.l	D5,D0
	and.l	D5,D1
	add.l	D0,D0
	or.l	D1,D0
	rts

CalcChecksum
	lsr.w	#2,D1
	move.l	(A0)+,D0
	subq.w	#2,D1
.loop
	move.l	(A0)+,D2
	eor.l	D2,D0
	dbra	D1,.loop
	and.l	D5,D0
	rts

DMFM_NR_2:
	cmp.l	#$552AAAAA,(A0)+
	bne.b	.error

	moveq	#6-1,D4
.loop3
	bsr.b	Decode
	move.w	D0,D2

	move.l	a1,-(a7)
	move.w	#$200-1,D3
.loop
	bsr.b	Decode
	move.w	D0,(A1)+
	dbf	D3,.loop
	move.l	(a7)+,a1

	bsr.b	CalcChecksum2
	sub.w	D1,D2
	bne.b	.error

	dbf	D4,.loop3

		moveq	#IERR_OK,d0
		rts
.error
		moveq	#IERR_CHECKSUM,d0
		rts
Decode
	move.w	(A0)+,D0
	move.w	(A0)+,D1
	asl.w	#1,D0
	and.w	#$AAAA,D0
	and.w	#$5555,D1
	or.w	D1,D0
	rts
CalcChecksum2
	move.w	#$200-1,D3
	moveq	#0,D1
loop2
	add.w	(A1)+,D1
	dbra	D3,loop2
	rts
