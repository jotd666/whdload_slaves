;============================================================================
;$VER: Apidya RawDIC imager source 2.05 © 2008-2009 Halibut Software
;
; This file may not be distributed, reproduced or altered, in full or in
; part, in any way, without prior written permission from the author.
;
; Special license is granted to the administrators of the WHDLoad project
; to dispose of this file as required in the case where reasonable attempts
; to obtain permission from the author have failed.
;
;============================================================================

	SECTION	ISlave,CODE

	OPT	0

	INCDIR	INCLUDE:
	INCLUDE	RawDIC.i

;--------------------------------

	; islave header structure

	SLAVE_HEADER
	dc.b	1	; slv_Version
	dc.b	0	; slv_Flags
	dc.l	_dsk1	; slv_FirstDisk
	dc.l	_txt	; slv_Text

;--------------------------------

	; disk 1 structures

	CNOP	0,4
_dsk1:	dc.l	_dsk2	; dsk_NextDisk
	dc.w	1	; dsk_Version
	dc.w	DFLG_NORESTRICTIONS|DFLG_SWAPSIDES ; dsk_Flags
	dc.l	_d1_tl	; dsk_TrackList
	dc.l	0	; reserved
	dc.l	FL_DISKIMAGE	; dsk_FileList
	dc.l	0	; dsk_CRCList
	dc.l	0	; dsk_AltDisk
	dc.l	0	; dsk_InitCode
	dc.l	0	; dsk_DiskCode

	CNOP	0,4
_d1_tl:	TLENTRY	001,001,$1600,SYNC_STD,DMFM_STD
	TLENTRY	000,000,$1800,SYNC_STD,_dmfm_1a
	TLENTRY	002,159,$1a00,SYNC_STD,_dmfm_1b
	TLEND

;--------------------------------

	; disk 2 structures

	CNOP	0,4
_dsk2:	dc.l	0	; dsk_NextDisk
	dc.w	1	; dsk_Version
	dc.w	DFLG_NORESTRICTIONS|DFLG_SWAPSIDES ; dsk_Flags
	dc.l	_d2_tl	; dsk_TrackList
	dc.l	0	; reserved
	dc.l	FL_DISKIMAGE	; dsk_FileList
	dc.l	0	; dsk_CRCList
	dc.l	0	; dsk_AltDisk
	dc.l	0	; dsk_InitCode
	dc.l	0	; dsk_DiskCode

	CNOP	0,4
_d2_tl:	TLENTRY	000,159,$1a00,SYNC_STD,_dmfm_2
	TLEND

;--------------------------------

_dmfm_1a:	cmp.w	#$2aaa,(a0)+
	bne	_dmfm_err
	move.w	#$5ff,d7
	bra	_dmfm_main

;--------------------------------

_dmfm_1b:	cmp.w	#46,d0
	beq	.dmfm1b_1

	cmp.w	#$2aa9,(a0)+
	bne	_dmfm_err

	addq.l	#4,a0
	move.w	#$67f,d7
	bra	_dmfm_main

.dmfm1b_1:	cmp.w	#$2aa9,(a0)+
	bne	_dmfm_ok
	move.w	#$5ff,d7
	bra	_dmfm_main

;-----

_dmfm_2:	cmp.w	#$4aa9,(a0)+
	bne	_dmfm_err
	addq.l	#4,a0
	move.w	#$67f,d7
	bra	_dmfm_main

;--------------------------------
; main mfm decoder
; > a0 = source
; > a1 = dest
; > d7 = number of longs - 1

_dmfm_main:	move.l	#$55555555,d5	; decode constant
	moveq	#0,d6	; checksum

.dm_loop:	bsr	.dm_decode_one	; get next long
	move.l	d0,(a1)+	; store and update checksum
	add.l	d0,d6
	dbf	d7,.dm_loop

	bsr	.dm_decode_one	; checksum check
	cmp.l	d0,d6
	bne	_dmfm_err
	bra	_dmfm_ok

;-----

.dm_decode_one:
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	d5,d0
	and.l	d5,d1
	lsl.l	#1,d0
	or.l	d1,d0
	rts

;--------------------------------

_dmfm_err:	moveq	#IERR_CHECKSUM,d0
	rts

_dmfm_ok:	moveq	#IERR_OK,d0
	rts

;--------------------------------

_ver:	dc.b	"$VER: "
_txt:	dc.b	"Apidya Imager "
	INCLUDE	Version.i
	dc.b	10
	INCLUDE	Copyright.i
	dc.b	" - v1.x by Mr. Larmer"
	dc.b	0
	EVEN

;--------------------------------
