;*---------------------------------------------------------------------------
;  :Program.	turican.islave.asm
;  :Contents.	Imager for Turrican
;  :Author.	Wepl
;  :Version.	$Id: turrican.islave.asm 1.1 2016/02/09 22:22:55 wepl Exp wepl $
;  :History.	27.08.13 started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/Turrican Install/Turrican.ISlave"
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
		dc.l	_disk1v1	; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Turrican Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
_60000		dc.b	"60000",0
_highs		dc.b	"highs",0
_12		dc.b	"12",0
_1c		dc.b	"1c",0
_28		dc.b	"28",0
_30		dc.b	"30",0
_31		dc.b	"31",0
_46		dc.b	"46",0
_5c		dc.b	"5c",0
_70		dc.b	"70",0
_88		dc.b	"88",0
_89		dc.b	"89",0
_savehighsflag	dc.b	0
	EVEN

;============================================================================
; sps-92 Rainbow Arts

_disk1v1	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	.fl		; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	_disk1v2	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	_savehighs	; Called after a disk has been read

.crc		CRCENTRY 0,$09ef
		CRCEND

.tl		TLENTRY	0,17,$1600,SYNC_STD,DMFM_STD
		TLENTRY 18,26,$1978,$9521,_decodedata
		TLENTRY 27,27,388,$4489,_decodehighs
		TLENTRY 28,157,$1978,$9521,_decodedata
		TLEND

.fl		FLENTRY	_60000,$400,$17e00
		FLENTRY	_12,$1600*18+$1978*($12-18),$d4e4
		FLENTRY	_1c,$1600*18+$1978*($1c-19)+388,$11964
		FLENTRY	_28,$1600*18+$1978*($28-19)+388,$c474
		FLENTRY	_30,$1600*18+$1978*($30-19)+388,$1478
		FLENTRY	_31,$1600*18+$1978*($31-19)+388,$20BC8
		FLENTRY	_46,$1600*18+$1978*($46-19)+388,$22FA8
		FLENTRY	_5c,$1600*18+$1978*($5c-19)+388,$1EBC0
		FLENTRY	_70,$1600*18+$1978*($70-19)+388,$2642C
		FLENTRY	_89,$1600*18+$1978*($89-19)+388,$20914
		FLEND

;============================================================================
; sps-1838 Innerprise

_disk1v2	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	.fl		; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	_disk1v3	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	_savehighs	; Called after a disk has been read

.crc		CRCENTRY 0,$fcd2
		CRCEND

.tl		TLENTRY	0,17,$1600,SYNC_STD,DMFM_STD
		TLENTRY 18,26,$1978,$9521,_decodedata
		TLENTRY 27,27,388,$4489,_decodehighs
		TLENTRY 28,156,$1978,$9521,_decodedata
		TLEND

.fl		FLENTRY	_60000,$400,$17e00
		FLENTRY	_12,$1600*18+$1978*($12-18),$d500
		FLENTRY	_1c,$1600*18+$1978*($1c-19)+388,$11964
		FLENTRY	_28,$1600*18+$1978*($28-19)+388,$c4f4
		FLENTRY	_30,$1600*18+$1978*($30-19)+388,$1478
		FLENTRY	_31,$1600*18+$1978*($31-19)+388,$20BC8
		FLENTRY	_46,$1600*18+$1978*($46-19)+388,$22FA8
		FLENTRY	_5c,$1600*18+$1978*($5c-19)+388,$1EBC0
		FLENTRY	_70,$1600*18+$1978*($70-19)+388,$26168
		FLENTRY	_88,$1600*18+$1978*($88-19)+388,$20914
		FLEND

;============================================================================
; AmigaFun

_disk1v3	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.crc		CRCENTRY 0,$6711
		CRCEND

.tl		TLENTRY 0,159,$1600,SYNC_STD,DMFM_STD
		TLEND

;============================================================================

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decodedata	addq.l	#2,a0			;skip $2aaa
		move.l	#$55555555,d2		;D2 = 55555555
		moveq	#0,d5			;D5 = chksum
		move.w	#$1978/4-1,d3
		move.w	d0,d7

.loop		move.l	(a0)+,d0
		move.l	(a0)+,d1
		eor.l	d0,d5
		eor.l	d1,d5
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		move.l	d0,(a1)+
		dbf	d3,.loop

		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		and.l	d2,d5
		cmp.l	d0,d5
		bne	.error

		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decodehighs	addq.l	#2,a0			;skip $2aaa
		move.l	#$55555555,d2		;D2 = 55555555

		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		eor.l	#$12345678,d0

		addq.l	#8,a0			;skip unused

		move.l	a0,a2
		move.w	#$c7,d3
		moveq	#0,d1
.hlp1		move.l	(a0)+,d4
		eor.l	d4,d1
		dbf	d3,.hlp1
		and.l	d2,d1
		cmp.l	d0,d1
		bne	.error

		move.l	a2,a0
		move.w	#$60,d3
.hlp2		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		move.l	d0,(a1)+
		dbf	d3,.hlp2

		sub.w	#388,a1
		move.w	#$61*4-1,d0
.lp		eor.b	d0,(a1)+
		dbf	d0,.lp

		st	_savehighsflag
.error		moveq	#IERR_OK,d0
		rts

_savehighs	move.b	_savehighsflag,d0
		beq	.end

		move.l	#$1600*18+$1978*9,d0	;offset in disk image
		move.l	#388,d1			;length
		lea	_highs,a0		;name
		jsr	(rawdic_SaveDiskFile,a5)

.end		moveq	#IERR_OK,d0
		rts

;============================================================================

	END
