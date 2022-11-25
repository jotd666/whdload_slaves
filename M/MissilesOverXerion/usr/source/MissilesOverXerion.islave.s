		incdir	Include:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Missiles Over Xerion V1.0",10,"by Bored Seal on 03.08.2001",0
		cnop	0,4

DSK_1:		dc.l	DSK_2		; pointer to next disk structure
		dc.w	1		; disk structure version
		dc.w	0		; flags (look below)
		dc.l	TL_1		; list of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_1		; list of files to be saved
		dc.l	0		; table of certain tracks with CRC values
		dc.l	0		; alternative disk structure, if CRC failed
		dc.l	0
		dc.l	0

DSK_2:		dc.l	0		; pointer to next disk structure
		dc.w	1		; disk structure version
		dc.w	0		; flags (look below)
		dc.l	TL_2		; list of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_2		; list of files to be saved
		dc.l	0		; table of certain tracks with CRC values
		dc.l	0		; alternative disk structure, if CRC failed
		dc.l	0
		dc.l	0

TL_1:		TLENTRY	0,33,$1600,SYNC_STD,DMFM_STD
		TLENTRY	34,126,$1600,SYNC_STD,DMFM_NULL
		TLENTRY	127,159,$1600,SYNC_STD,DMFM_STD
		TLEND

TL_2:		TLENTRY	0,159,$1600,SYNC_STD,DMFM_STD
		TLEND

FL_1		FLENTRY	disk,0,$2dc00
		FLENTRY	game,$af000,$11a00
		FLEND

FL_2		FLENTRY disk2,0,901120
		FLEND

disk		dc.b	"Disk.1",0
disk2		dc.b	"Disk.2",0
game		dc.b	"Xerion",0
