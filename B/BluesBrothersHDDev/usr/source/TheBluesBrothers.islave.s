	; The Blues Brothers imager

	; A track contains 10 sectors. Sector 0 to 9 contain 512 bytes data,
	; (Total: $1400 bytes)

	; sector format description:

	; sync ($4489)
	; 1 byte header ID (MFM: $5554)
	; 2 unused bytes
	; 1 byte sector number (0-9) + 1
	; 1 byte
	; 1 word checksum
	; gap
	; sync ($4489)
	; 1 byte data block ID (MFM: $5545)
	; 512 bytes data
	; 1 word checksum

	; The checksum test is quite strange, a CRC16 calculation is done
	; which always leads to 0 when everything went ok.
	; Part of the CRC16 calculation are also 3 sync signal words and
	; the header/data block ID, and ofcourse the checksum.

	; The MFM decoding is done by skipping all odd bits in the bitstream.

	; Similar formats: Thalion games (uses the same CRC16 method)

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"TheBluesBrothers.islave"

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"The Blues Brothers imager V1.0",10,"by Mr.Larmer on 23.06.2001",0
		cnop	0,4

DSK_1:		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	Init		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1:
		TLENTRY 20,79,$1400,SYNC_STD,DMFM_NR
		TLENTRY 82,157,$1400,SYNC_STD,DMFM_NR

		TLEND
DMFM_NR:
		lea	SectorFlags(pc),a2
		moveq	#9,d1
.l0		sf	(a2)+		; clear sector flags
		dbra	d1,.l0

		moveq	#9,d1
		bra.b	.s0		; don't search first sync
.l1		jsr	rawdic_NextSync(a5)
.s0		cmp.w	#$5554,(a0)
		bne.b	.l1

		bsr.b	DMFM_NR_header
		bne.b	.error

		jsr	rawdic_NextSync(a5)	; search data block
		cmp.w	#$5545,(a0)
		bne.b	.s0

		move.b	d2,d0

		bsr	DMFM_NR_data
		bne.b	.error
		dbra	d1,.l1

		lea	SectorFlags(pc),a2
		moveq	#9,d1
.l2		tst.b	(a2)+		; if one sector is missing, one of
		dbeq	d1,.l2		; these flags will be FALSE
		beq.b	.nosect

		moveq	#IERR_OK,d0
.error		rts
.nosect		moveq	#IERR_NOSECTOR,d0
		rts

DMFM_NR_header:

		; => D2.b=sector number

		movem.l	d1/a0,-(sp)

		bsr.b	InitCRC16
		moveq	#9,d6
		bsr.b	StreamCalcCRC16
		or.b	d2,d3		; header checksum ok?
		bne.b	.error

		subq.l	#4*2,a0		; 4 bytes back
		bsr.b	NextByte	; get sector number
		subq.b	#1,d0
		move.b	d0,d2

		movem.l	(sp)+,d1/a0
		moveq	#IERR_OK,d0
		rts
.error		movem.l	(sp)+,d1/a0
		moveq	#IERR_CHECKSUM,d0
		rts

DMFM_NR_data:

		; D0.b=sector number

		movem.l	d1/a0-a1,-(sp)

		cmp.b	#9,d0
		bhi.b	.error
		move.w	#$01ff,d5
.s0
		lea	SectorFlags(pc),a2
		and.w	#$00ff,d2
		st	(a2,d2.w)

		lsl.w	#8,d0
		lsl.w	#1,d0
		add.w	d0,a1

		bsr.b	InitCRC16
		moveq	#3,d6
		bsr.b	StreamCalcCRC16

.l1		bsr.b	NextByte	; calculate header checksum
		bsr.b	CalcCRC16
		move.b	d0,(a1)+
		dbra	d5,.l1

		moveq	#1,d6
		bsr.b	StreamCalcCRC16

		or.b	d2,d3
		bne.b	.error

		movem.l	(sp)+,d1/a0-a1
		moveq	#IERR_OK,d0
		rts
.error		movem.l	(sp)+,d1/a0-a1
		moveq	#IERR_CHECKSUM,d0
		rts

InitCRC16:	lea	CRC_table,a2	; initialise registers for CalcCRC16
		moveq	#0,d0
		moveq	#0,d1
		moveq	#-1,d2
		moveq	#-1,d3
		subq.l	#3*2,a0		; 3 syncwords needed for CRC calculation
		rts

StreamCalcCRC16:
.l0		bsr.b	NextByte
		bsr.b	CalcCRC16
		dbra	d6,.l0
		rts

NextByte:	move.w	(a0)+,d0
		BITSKIP_B d0
		rts
CalcCRC16:
		move.b	d0,d1
		eor.b	d2,d1
		lea	(a2,d1.w),a3
		move.b	(a3),d2
		eor.b	d3,d2
		move.b	$0100(a3),d3
		rts

Init:		; initialisation of the CRC table.

		lea	CRC_table,a0
		moveq	#0,d1
.l1		moveq	#0,d2
		move.b	d1,d2
		lsl.w	#8,d2
		moveq	#7,d0
.l0		add.w	d2,d2
		bcc.b	.s0
		eor.w	#$1021,d2	; $1021 = standard CRC16 value
.s0		dbra	d0,.l0
		move.b	d2,$0100(a0)
		lsr.w	#8,d2
		move.b	d2,(a0)+
		addq.b	#1,d1
		bne.b	.l1

		moveq	#IERR_OK,d0
		rts

SectorFlags:	ds.b	10

	section	"BSS",bss

CRC_table:	ds.b	$200

