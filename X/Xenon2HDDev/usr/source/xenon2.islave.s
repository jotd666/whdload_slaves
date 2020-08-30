;*---------------------------------------------------------------------------
;  :Program.	xenon2.islave.asm
;  :Contents.	Imager for Xenon 2
;  :Author.	Wepl
;  :Version.	$Id: xenon2.islave.asm 1.3 2005/05/11 17:52:46 wepl Exp wepl $
;  :History.	10.08.04 created
;		11.02.05 v6 added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	v1/v2/v3:
;	Disk 1:		0	standard
;			1	rob northen copylock (some versions without)
;			2-159	standard
;	Disk 2:		0-159	standard
;
;	v4:
;	Disk 1:		0-159	standard
;
;	v5:
;	Disk 1:		0	standard
;			1-159	$1800 Rob Northen PDos
;
;	v6: speedlock
;	Disk 1:		0	standard
;			1	speedlock protection
;			2	$4489 sync
;				8 byte unknown data
;				$1800 mfm data even, long mfm chksum even
;				$1800 mfm data odd, long mfm chksum odd
;			3-159	$4489 sync
;				4 byte unknown data
;				$1b00 mfm data even, long mfm chksum even
;				$1b00 mfm data odd, long mfm chksum odd
;	 3-47 intro = $4b170 = 307568
;	48-73  main = $2a314 = 172820
;
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/Xenon2 Install/Xenon2.ISlave"
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODd-			;disable mul optimizing
	BOPT	ODe-			;disable mul optimizing
	ENDC

;============================================================================

	SECTION a,CODE

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0		; Slave flags
		dc.l	_disk1v6	; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Xenon 2 Imager",10
		dc.b	"Done by Wepl, Version 1.1 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
	EVEN

;============================================================================

_disk1v6	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	.fl		; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	_disk1v5	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
	;	TLENTRY 2,2,$1800,$4489,_decodev61
		TLENTRY 3,159,$1b00,$4489,_decodev62
		TLEND

.fl		FLENTRY	FL_DISKIMAGE,$1600,$1b00*157
		FLEND

.crc		CRCENTRY 0,$f48a
		CRCEND

	IFEQ 1
	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decodev61	move.l	#$55555555,d5		;D5 = 55555555
		addq.l	#8,a0
		move.w	#$5ff,d7
		moveq	#0,d4

.loop		move.l	($1804,a0),d0
		move.l	(a0)+,d3
		and.l	d5,d0
		and.l	d5,d3
		lsl.l	#1,d0
		or.l	d3,d0
		add.l	d0,d4
		move.l	d0,(a1)+
		dbf	d7,.loop

		move.l	($1804,a0),d0
		move.l	(a0),d3
		and.l	d5,d0
		and.l	d5,d3
		lsl.l	#1,d0
		or.l	d3,d0
		eor.l	d0,d4
		bne	.error
		
		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts
	ENDC

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decodev62	move.l	#$55555555,d5		;D5 = 55555555
		addq.l	#4,a0
		move.w	#$6bf,d7
		moveq	#0,d4

.loop		move.l	($1b04,a0),d0
		move.l	(a0)+,d3
		and.l	d5,d0
		and.l	d5,d3
		lsl.l	#1,d0
		or.l	d3,d0
		add.l	d0,d4
		move.l	d0,(a1)+
		dbf	d7,.loop

		move.l	($1b04,a0),d0
		move.l	(a0),d3
		and.l	d5,d0
		and.l	d5,d3
		lsl.l	#1,d0
		or.l	d3,d0
		eor.l	d0,d4
		bne	.error
		
		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts

;============================================================================

_disk1v5	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	_disk1v4	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY 1,159,$1800,$1448,_decodev5
		TLEND

.crc		CRCENTRY 0,$664a
		CRCEND

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decodev5	move.l	d0,d6			;D6 = track number
		moveq	#0,d7			;D7 = actual sector
		move.l	#$55555555,d2		;D2 = 55555555

.sector		cmp.w	#$4891,(a0)+
		bne	.error
		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		bclr	#31,d0
		move.w	d0,a2			;A2 = chksum
		swap	d0
		cmp.b	d0,d6
		bne	.error
		lsr.w	#8,d0
		cmp.b	d7,d0			;sector number
		bne	.error

		moveq	#512/4-1,d3
		moveq	#0,d4
		moveq	#0,d5			;diskkey

.dec		move.l	($200,a0),d1
		move.l	(a0)+,d0
		eor.l	d0,d4
		and.l	d2,d0
		eor.l	d1,d4
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		eor.l	d0,d5
		move.l	d5,(a1)+
		move.l	d0,d5
		dbf	d3,.dec

		and.l	d2,d4
		move.l	d4,d0
		swap	d4
		add.w	d4,d4
		or.w	d4,d0
		cmp.w	d0,a2
		bne	.error

		add.w	#$200,a0

		move.w	(a0)+,d0
		moveq	#0,d1
		moveq	#7,d3
.gap		roxl.w	#2,d0
		roxl.b	#1,d1
		dbf	d3,.gap

		add.w	d1,d1
		add.l	d1,a0		;sector gap

		addq.w	#1,d7
		cmp.w	#12,d7
		bne	.sector
		
		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts

;============================================================================

_disk1v4	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	_disk1		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,159,$1600,SYNC_STD,DMFM_STD
		TLEND

.crc		CRCENTRY 0,$34dd
		CRCEND

;============================================================================

_disk1		dc.l	_disk2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY	1,1,$1600,SYNC_STD,DMFM_NULL
		TLENTRY	2,159,$1600,SYNC_STD,DMFM_STD
		TLEND

_disk2		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,159,$1600,SYNC_STD,DMFM_STD
		TLEND

;============================================================================

	END
