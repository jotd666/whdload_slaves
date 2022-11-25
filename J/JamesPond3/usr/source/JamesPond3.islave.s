		incdir	Include:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"James Pond 3 AGA imager V1.0",10,"by Bored Seal on 04.05.1999",0
		cnop	0,4

DSK_1:		dc.l	DSK_2		; pointer to next disk structure
		dc.w	1		; disk structure version
		dc.w	0		; flags (look below)
		dc.l	TL_1		; list of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_NOFILES	; list of files to be saved
		dc.l	0		; table of certain tracks with CRC values
		dc.l	0		; alternative disk structure, if CRC failed
		dc.l	0
		dc.l	Extract1	; called after a disk has been read

DSK_2:		dc.l	DSK_3		; pointer to next disk structure
		dc.w	1		; disk structure version
		dc.w	0		; flags (look below)
		dc.l	TL_1		; list of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_NOFILES	; list of files to be saved
		dc.l	0		; table of certain tracks with CRC values
		dc.l	0		; alternative disk structure, if CRC failed
		dc.l	0		; called before a disk is read
		dc.l	Extract1	; called after a disk has been read

DSK_3:		dc.l	0		; pointer to next disk structure
		dc.w	1		; disk structure version
		dc.w	0		; flags (look below)
		dc.l	TL_1		; list of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_NOFILES	; list of files to be saved
		dc.l	0		; table of certain tracks with CRC values
		dc.l	0		; alternative disk structure, if CRC failed
		dc.l	0
		dc.l	Extract1	; called after a disk has been read

TL_1:		TLENTRY	0,137,$1600,SYNC_STD,DMFM_STD
		TLEND

Extract1:	move.w	#1,d0
		jsr	rawdic_ReadTrack(a5)	; read track containing directory

		lea	$2c00,a4			;offset is 0
		lea	$F(a1),a1		;skip disk id

fileloop	lea	4(a1),a0		;filename
		tst.l	(a1)			;is there a file ?
		beq	Out
		move.l	a4,d0			;offset
		move.l	(a1),d1			;lenght
		jsr	rawdic_SaveDiskFile(a5)

		move.l	(a1),d0			;raise offset counter (+ file lenght)
		add.l	d0,a4
		lea	16(a1),a1		;next file
		bra	fileloop

Out		moveq	#IERR_OK,d0
		rts
