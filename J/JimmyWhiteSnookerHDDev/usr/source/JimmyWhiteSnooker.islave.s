
	SECTION	ISlave,CODE
	OPT	O+,W-,P=68000

	; RawDIC imager slave for Jimmy White's Whirlwind Snooker
	; (c) 1998-2004 Halibut Software

	INCDIR	INCLUDE:
	INCLUDE	RawDIC.i
	INCLUDE	SlaveMacros.i

;--------------------------------

	SLAVE_HEADER
	dc.b	1	;slv_Version
	dc.b	0	;slv_Flags
	dc.l	_dsk1	;slv_FirstDisk
	dc.l	_txt	;slv_Text

;--------------------------------

_dsk1:	dc.l	0	;dsk_NextDisk
	dc.w	1	;dsk_Version
	dc.w	0	;dsk_Flags
	dc.l	_d1_tl	;dsk_TrackList
	dc.l	0	;UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NULL	;dsk_FileList
	dc.l	0	;dsk_CRCList
	dc.l	0	;dsk_AltDisk
	dc.l	0	;dsk_InitCode
	dc.l	_d1_final	;dsk_DiskCode

_d1_tl:	TLENTRY	002,040,$1600,SYNC_STD,DMFM_STD ; main code
	TLEND

;--------------------------------

	; disk 1 finalisation code
	;
	; >d0=disk number
	; >a0=disk structure
	; >a5=function base
	;
	; <d0=error code

_d1_final:	movem.l	d0-7/a0-6,-(a7)

	; read start of game data

	moveq	#2,d0
	jsr	rawdic_ReadTrack(a5)

	; find header of compressed game data in buffer

	move.l	#$21c,d0
	cmp.l	#$524e4301,(a1,d0.l)
	beq.s	.d1f_save

	move.l	#$288,d0
	cmp.l	#$524e4302,(a1,d0.l)
	beq.s	.d1f_save

	bra.s	.d1f_err

.d1f_save:	; save compressed game code

	move.l	8(a1,d0.l),d1	; d1=compressed length
	add.l	#32,d1
	lea	.d1f_mainnam(pc),a0
	jsr	rawdic_SaveDiskFile(a5)

	movem.l	(a7)+,d0-7/a0-6	; all done
	moveq	#IERR_OK,d0
	rts

.d1f_err:	movem.l	(a7)+,d0-7/a0-6	; something barfed
	moveq	#IERR_NOWFILE,d0
	rts

;----------

.d1f_mainnam:
	dc.b	"Main",0

;--------------------------------

	dc.b	"$VER: "
_txt:	dc.b	"Jimmy White Snooker imager "
	INCLUDE	Version.i
	dc.b	10
	INCLUDE	Copyright.i
	dc.b	0
	EVEN

;--------------------------------
