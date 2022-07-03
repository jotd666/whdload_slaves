
	SECTION	MakeSave,CODE
	OPT	O+,W-,P=68000

	; RawDIC imager slave for Jimmy White's Whirlwind Snooker saved games
	; (c) 1998-2004 Halibut Software

	INCDIR	INCLUDE:
	INCLUDE	RawDIC.i
	INCLUDE	SlaveMacros.i

;--------------------------------

	; ISlave Header structure
	SLAVE_HEADER
	dc.b	1	; slv_Version
	dc.b	0	; slv_Flags
	dc.l	_dsk1	; slv_FirstDisk
	dc.l	_txt	; slv_Text

;--------------------------------

	; Disk 1 disk structures

	CNOP	0,4
_dsk1:	dc.l	0	; dsk_NextDisk
	dc.w	1	; dsk_Version
	dc.w	0	; dsk_Flags
	dc.l	_d1_tl	; dsk_TrackList
	dc.l	0	; UNUSED, ALWAYS SET TO 0!
	dc.l	_d1_fl	; dsk_FileList
	dc.l	0	; dsk_CRCList
	dc.l	0	; dsk_AltDisk
	dc.l	0	; dsk_InitCode
	dc.l	0	; dsk_DiskCode

	; Disk 1 tracklist structure

	CNOP	0,4
_d1_tl:	TLENTRY	156,156,$1600,SYNC_STD,DMFM_STD    ; 6CA (saved games)
	TLENTRY	158,158,$1600,SYNC_STD,DMFM_STD    ; 6B4 (saved scores)
	TLEND

	; Disk 1 filelist structure

	CNOP	0,4
_d1_fl:	FLENTRY	.d1fl_fnam_score,0,$1600
	FLENTRY	.d1fl_fnam_game,$1600,$1600
	FLEND

.d1fl_fnam_score:
	FNAM_GAME
.d1fl_fnam_game:
	FNAM_SCORE

;--------------------------------

_ver:	dc.b	"$VER: "
_txt:	dc.b	"Jimmy White Snooker savegame imager "
	INCLUDE	Version.i
	dc.b	10
	INCLUDE	Copyright.i
	dc.b	0
	EVEN

;--------------------------------
