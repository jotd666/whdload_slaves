;*---------------------------------------------------------------------------
;  :Program.	lotus.islave.asm
;  :Contents.	Imager for Lotus
;  :Author.	Wepl
;  :Version.	$Id: Lotus2.islave.asm 1.4 2007/02/27 20:42:29 wepl Exp wepl $
;  :History.	22.08.99 transformed from lotus imager
;		09.09.99 support for lotus triology version added
;		08.07.00 NextSync added
;		27.02.07 support for v5 added (US/NTSC ReCrack)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;	original release:
;	Disk 1:		0-1	standard
;			2-157	$1800 bytes sync=4489
;			158-159 sync=41244124 protection long track (>2*$1900)
;	Amiga Fun/US NTSC release:
;	Disk 1:		0-159	standard
;	Lotus Triology release:
;	Disk 1:		0-1	standard
;			2-157	$1800 bytes sync=4489
;			158-159 sync=41244124 protection long track (>2*$1900)
;
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/Lotus2 Install/Lotus2.ISlave"
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
	;	dc.b	SFLG_DEBUG	; Slave flags
		dc.l	_disk11		; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Lotus2 Imager",10
		dc.b	"Done by Wepl, Version 1.1 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
	EVEN

;============================================================================

	;original release
_disk11		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES|DFLG_NORESTRICTIONS	; Disk flags
		dc.l	_tl1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl1		; List of files to be saved
		dc.l	_crc1		; Table of certain tracks with CRC values
		dc.l	_disk12		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

_tl1		TLENTRY	1,1,$1600,SYNC_STD,DMFM_STD
		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY	2,157,$1800,$4489,_decode1
		TLEND

_fl1		FLENTRY	FL_DISKNAME,0,FL_DISKLENGTH
		FLEND

_crc1		CRCENTRY 1,$aff2
		CRCEND

	STRUCTURE disk,0
		LONG	disk_id			;"LETC"
		STRUCT	disk_offsets,256*4	;start-offset of each file
		LONG	disk_end		;end of disk
		STRUCT	disk_chain,256		;number of following file
		LONG	disk_jmp		;jump address of first file
		STRUCT	disk_name,64		;name of disk
		LABEL	disk_data

_decode1

.search		cmp.w	#$5555,(a0)+
		beq	.go
		jsr	(rawdic_NextSync,a5)
		tst.l	d0
		bne	.search
		moveq	#IERR_CHECKSUM,d0
		rts

.go		move.w	#$bff,d7
		move.w	#$5555,d2
		moveq	#0,d3
		move.w	d0,d4

.loop		bsr	.get
		move.w	d1,(a1)+
		add.w	d1,d3
		dbf	d7,.loop

		bsr	.get
		cmp.w	d1,d3
		bne	.search
		
		cmp.w	#2,d4			;first image track?
		bne	.ok
		move.l	(disk_end-$1800,a1),d0
		sub.l	#$3000-$2c00,d0		;because contain track 1&2 are only $1600
		move.l	d0,(_fl1+8)		;image size

.ok		moveq	#IERR_OK,d0
		rts

.get		move.w	(a0)+,d0
		move.w	(a0)+,d1
		and.w	d2,d0
		and.w	d2,d1
		add.w	d1,d1
		add.w	d0,d1
		rts

;============================================================================

	;amiga fun rerelease
_disk12		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	_tl12		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl12		; List of files to be saved
		dc.l	_crc12		; Table of certain tracks with CRC values
		dc.l	_disk13		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

_tl12		TLENTRY	0,159,$1600,SYNC_STD,DMFM_STD
		TLEND

_fl12		FLENTRY	FL_DISKNAME,0,FL_DISKLENGTH
		FLEND

_crc12		CRCENTRY 0,$20c4
		CRCEND

;============================================================================

	;lotus triology rerelease
_disk13		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES|DFLG_NORESTRICTIONS	; Disk flags
		dc.l	_tl1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl1		; List of files to be saved
		dc.l	_crc13		; Table of certain tracks with CRC values
		dc.l	_disk15		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

_crc13		CRCENTRY 1,$a553
		CRCEND

;============================================================================

	;US release, ReCrack (Company)
_disk15		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	_tl12		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl12		; List of files to be saved
		dc.l	_crc15		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

_crc15		CRCENTRY 0,$3963
		CRCEND

;============================================================================

	END
