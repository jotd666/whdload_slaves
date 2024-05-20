
		; Rob Northen PDos imager (Barfly assembler source)
		;
		; Written by Codetapper/Action with assistance from
		; Jean-François Fabre and Greg! Thanks guys!
		;
		; Insert key in d6 for each disk at line 85, 88...
		; Common keys for various games:
		;
		; Alien Breed 2 AGA:         $123111 - Disk 1
		;                            $123222 - Disk 2
		;                            $123333 - Disk 3
		; Body Blows:              $13246679 - Disk 1
		;                          $13246678 - Disk 2
		;                          $13246677 - Disk 3
		; Mortal Kombat 1 and 2:          $0 - All disks
		; Project X Special Edition: $123898 - All disks
		; Superfrog:                 $12389a - All disks
		;
		; For other Probe games, try $0 or disassemble the game :)
		;
		; A track contains 12 sectors, each containing 512 bytes data.
		;
		; Sector format description:
		;
		; sync ($1448)
		; word ($4891)
		; sector data

		incdir	Include:
		include	RawDIC.i

	IFD	BARFLY
		OUTPUT	"ArcadePool.islave"

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC
	ENDC
	
		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text		dc.b	"Arcade Pool PDos imager V1.2",10
		dc.b	"by Codetapper/Action/JOTD on "
		IFD		BARFLY
		INCBIN	"T:date"
		ELSE
		INCBIN	datetime
		ENDC
		dc.b	0
		cnop	0,4

DSK_1		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1	
		TLENTRY	000,003,$1600,SYNC_STD,DMFM_STD
		TLENTRY	004,157,$1800,$1448,_DMFM_RNPDos_D1
		TLENTRY	158,159,$1600,SYNC_STD,DMFM_NULL	; v2 has invalid track, v1 has empty RN track
		TLEND

;======================================================================

_DMFM_RNPDos_D1	move.l	#$16023101,d6			;d6 = Disk key for disk 1
		bra	_RN_PDos

;======================================================================

_RN_PDos	moveq	#0,d7			;d7 = Sector complete counter
		move.l	a0,a5			;a5 = MFM data
		move.l	a1,a2			;a2 = Destination

_NextSector	cmpi.w	#$4891,(a5)		;Check for word $4891 on each
		bne	_NoSector		;sector boundary

		lea	2(a5),a0
		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	#$55555555,d0
		and.l	#$55555555,d1
		add.l	d0,d0
		or.l	d1,d0

		move.l	d6,d1			;Disk key
		bset	#31,d1
		eor.l	d1,d0
		move.l	d0,d3			;Checksum
		swap	d0
		lsr.w	#8,d0

		lea	$a(a5),a0
		bsr	_GetChecksum
		cmp.w	d0,d3
		bne	_ChecksumError
		move.l	a2,a1
		bsr	_DecodeData
		lea	$200(a2),a2

		adda.w	#$40a,a5
		move.w	(a5)+,d0
		moveq	#0,d1
		moveq	#7,d2
_Unwind		roxl.w	#2,d0
		roxl.b	#1,d1
		dbf	d2,_Unwind

		add.w	d1,d1
		adda.l	d1,a5
		addq.w	#1,d7			;Check if we have decoded
		cmpi.w	#12,d7			;all 12 sectors
		bne	_NextSector

_OK		moveq	#IERR_OK,d0
		rts

_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts

_NoSector	moveq	#IERR_NOSECTOR,d0
		rts

;======================================================================

_GetChecksum	movem.l	d1-d2/a0,-(a7)
		moveq	#0,d0
		move.w	#$ff,d1
_ChecksumLoop	move.l	(a0)+,d2
		eor.l	d2,d0
		dbf	d1,_ChecksumLoop
		andi.l	#$55555555,d0
		move.l	d0,d1
		swap	d1
		add.w	d1,d1
		or.w	d1,d0
		movem.l	(a7)+,d1-d2/a0
		rts

;======================================================================

_DecodeData	movem.l	d0-d4/a0-a2,-(a7)
		moveq	#$7f,d0
		lea	($200,a0),a2
		move.l	#$55555555,d3
		move.l	d6,d4			;Disk key
_DecodeLoop	move.l	(a0)+,d1
		move.l	(a2)+,d2
		and.l	d3,d1
		and.l	d3,d2
		add.l	d1,d1
		or.l	d2,d1
		eor.l	d1,d4
		move.l	d4,(a1)+
		move.l	d1,d4
		dbf	d0,_DecodeLoop
		movem.l	(a7)+,d0-d4/a0-a2
		rts
