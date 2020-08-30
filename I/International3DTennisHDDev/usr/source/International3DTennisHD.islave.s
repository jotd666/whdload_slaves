
		; International 3D Tennis imager by Codetapper!
		;
		; Disk format description:
		;
		; Track  000-000: $4489 - Standard Dos
		; Track  001-001: $4a4a - Copy protection track
		; Tracks 002-003: $4489 - Standard Dos
		; Tracks 004-079: $4489 - Data
		; Tracks 080-085: $4489 - Standard Dos
		; Tracks 086-122: $4489 - Data
		; Tracks 123-159: $4489 - Standard Dos
		;
		; A track has lots of data per track :)

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"International3DTennis.islave"

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

;=====================================================================

;READ_FROM_WARP	equ	0			;Set to read from a 
						;MFMWarp file

;=====================================================================

		SLAVE_HEADER
		dc.b	1			;Slave version
		dc.b	0			;Slave flags
		dc.l	DSK_Original		;Pointer to the first disk structure
		dc.l	Text			;Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text:		dc.b	"International 3D Tennis imager V1.0",10
		dc.b	"by Codetapper/Action on "
		INCBIN	"T:date"
		dc.b	0
		cnop	0,4

DSK_Original	dc.l	0			;Pointer to next disk structure
		dc.w	1			;Disk structure version
		dc.w	DFLG_NORESTRICTIONS	;Disk flags
		dc.l	TL_Original		;List of tracks which contain data
		dc.l	0			;UNUSED, ALWAYS SET TO 0!
		dc.l	FL_Original		;List of files to be saved
		dc.l	0			;Table of certain tracks with CRC values
		dc.l	0			;Alternative disk structure, if CRC failed
		dc.l	0			;Called before a disk is read
		dc.l	0			;Called after a disk has been read

TL_Original	TLENTRY 000,000,$1600,SYNC_STD,DMFM_STD
		TLENTRY 001,001,$1600,SYNC_STD,DMFM_NULL
		TLENTRY 002,003,$1600,SYNC_STD,DMFM_STD
		TLENTRY	004,079,$1600,SYNC_STD,_DMFM_Int3DTen
		TLENTRY 080,085,$1600,SYNC_STD,DMFM_STD
		TLENTRY	086,122,$1600,SYNC_STD,_DMFM_Int3DTen
		TLEND
		EVEN

FL_Original	FLENTRY FL_Third,4*$1600,20*$1600
		FLENTRY FL_Second,24*$1600,56*$1600
		FLENTRY FL_First,86*$1600,37*$1600
		FLEND

FL_First	dc.b	"International3DTennis.1",0
FL_Second	dc.b	"International3DTennis.2",0
FL_Third	dc.b	"International3DTennis.3",0
		EVEN

;=====================================================================

_DMFM_Int3DTen	subq	#4,a0			;a0 = $4489
		bsr	_DecodeData

		lea	_Header(pc),a0
		cmp.l	#'UBIK',14(a0)
		bne	_Checksum

_OK		moveq	#IERR_OK,d0		;No error
		rts

_Checksum	moveq	#IERR_CHECKSUM,d0
		rts

_NoSector	moveq	#IERR_NOSECTOR,d0
		rts

;=====================================================================

_DecodeData	movem.l	d0-d1/d7/a0-a3,-(sp)	;Decode a track of MFM data 
		move.l	a1,a3			;from a0 to a1

		lea	($1760,a0),a1		;Setup variables
		move.l	#$55555555,d2

		lea	_Header(pc),a2		;Decode $80 bytes of 
		move.w	#($80/4)-1,d7		;header to the buffer
		bsr	_DecodeLoop	

		move.w	#($1600/4)-1,d7		;Decode $1600 bytes of
		move.l	a3,a2			;useful data to the buffer
		bsr	_DecodeLoop	

		movem.l	(sp)+,d0-d1/d7/a0-a3
		rts

;=====================================================================

_DecodeLoop	move.l	(a0)+,d0
		move.l	(a1)+,d1
		and.l	d2,d0
		and.l	d2,d1
		lsl.l	#1,d1
		or.l	d1,d0
		move.l	d0,(a2)+
		dbra	d7,_DecodeLoop
		rts

;=====================================================================

_Header		ds.b	$80
