
		; Fire and Ice imager (Barfly assembler source)
		;
		; Written by JOTD
		;
		; Sector format description:
		;
		; just like DOS but confuses trackdisk.device by a bad sector header
		; RawDIC just reads that without trouble !!!

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"FireAndIce.islave"

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text		dc.b	"Fire And Ice imager V1.1",10
		dc.b	"by JOTD on "
		INCBIN	"T:date"
		dc.b	0
		cnop	0,4

DSK_1		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_RAWREADONLY; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1		TLENTRY	000,000,$1600,SYNC_STD,DMFM_STD
		TLENTRY	001,001,$1600,SYNC_STD,DMFM_NULL
		TLENTRY	002,129,$1600,SYNC_STD,DMFM_STD
		TLENTRY	130,159,$1600,SYNC_STD,DMFM_NULL
		TLEND

DSK_2		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_RAWREADONLY; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read


TL_2		TLENTRY	000,159,$1600,SYNC_STD,DMFM_STD
		TLEND

