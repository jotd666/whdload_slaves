
	; Deepcore imager

		incdir	Includes:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Deep Core imager V1.1",10,"by Mr.Larmer/Wanted Team on 14.03.2000",0
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

DSK_2:		dc.l	DSK_3		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_3:		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_DOUBLEINC		; Disk flags
		dc.l	TL_3		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1:
		TLENTRY 0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY 1,1,$1998+$398,SYNC_STD,DMFM_NULL
		TLENTRY 2,3,$1998,$448A,DMFM_NR
		TLENTRY 4,4,$1998,$4222,DMFM_NR
		TLENTRY 5,78,$1998,$4215,DMFM_NR
		TLENTRY 79,127,$1998,$4221,DMFM_NR

		TLEND
TL_2:
		TLENTRY 0,0,$1998,$422A,DMFM_NR
		TLENTRY 1,1,$1998,SYNC_STD,DMFM_NULL
		TLENTRY 2,109,$1998,$4242,DMFM_NR

		TLEND
TL_3:
		TLENTRY 0,0,$1998,SYNC_STD,DMFM_NULL
		TLENTRY 2,2,$1998,$4211,DMFM_NR_3
		TLENTRY 4,4,$1998,$4422,DMFM_NR_4
		TLENTRY 6,136,$1998,$4211,DMFM_NR_2
		TLENTRY 138,138,$1998,$4212,DMFM_NR_7
		TLENTRY 140,152,$1998,$4211,DMFM_NR_2
		TLENTRY 154,158,$1998,SYNC_STD,DMFM_NULL
		TLENTRY 1,1,$1998,SYNC_STD,DMFM_NULL
		TLENTRY 3,3,$1998,$4252,DMFM_NR_5
		TLENTRY 5,5,$1998,$4542,DMFM_NR_6
		TLENTRY 7,105,$1998,$4211,DMFM_NR_2

		TLEND
DMFM_NR_7:
		lea	$CCC(a1),a1
		
		bra.b	go3
DMFM_NR_6:
		lea	Sync5(pc),a2

		moveq	#2,d4

		bra.b	go2
DMFM_NR_5:
		lea	Sync3(pc),a2

		bra.b	go
DMFM_NR_4:
		lea	Sync4(pc),a2

		bra.b	go
DMFM_NR_3:
		lea	Sync2(pc),a2
go
		moveq	#11,d4
go2
.loop
		addq.l	#2,a0
		moveq	#$7B,d3

		bsr.b	next
		bne.b	error

		move.w	(a2)+,d0
		jsr	rawdic_NextMFMword(a5)

		dbf	d4,.loop

		addq.l	#2,a0
		moveq	#$7B,d3

		bra.b	next
DMFM_NR_2:
		move.w	#$332,d3

		bsr.b	next
		bne.b	error

		move.w	#$4212,d0
		jsr	rawdic_NextMFMword(a5)
go3
		move.w	#$332,d3

		bra.b	next
DMFM_NR:
		move.w	#$665,d3
next
		bsr.b	GetLongWord
		move.l	d0,d5
loop
		bsr.b	GetLongWord
		eor.l	d0,d5
		move.l	d0,(a1)+
		dbf	d3,loop

		tst.l	d5
		bne.b	error

		moveq	#IERR_OK,d0
		rts
error
		moveq	#IERR_CHECKSUM,d0
		rts

GetLongWord
		move.l	#$55555555,D2
		movem.l	(A0)+,D0/D1
		and.l	D2,D0
		and.l	D2,D1
		add.l	D0,D0
		or.l	D1,D0
		rts
Sync2
		dc.w	$4212,$4215,$4221,$4222,$4225,$4229,$422A
		dc.w	$4242,$4245,$4249,$424A,$4251
Sync3
		dc.w	$4255,$4285,$4289,$428A,$4291,$4292,$4295
		dc.w	$42A1,$42A2,$42A5,$42A9,$4421
Sync4
		dc.w	$4425,$4429,$4442,$4485,$4489,$448A,$44A1
		dc.w	$44A2,$4509,$450A,$4521,$4522
Sync5
		dc.w	$4842,$4845,$4849
