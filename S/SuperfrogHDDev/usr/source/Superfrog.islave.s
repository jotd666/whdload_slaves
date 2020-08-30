
		; Superfrog imager (Rob Northen) - Key is $12389a

		; A track contains 12 sectors, each containing 512 bytes data.

		; Sector format description:

		; sync ($1448)
		; word ($4891)
		; sector data

		incdir	Include:
		include	RawDIC.i

USE_DISK_IMAGES	equ	0

		OUTPUT	"Superfrog.islave"

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
Text		dc.b	"Superfrog imager V1.0",10
		dc.b	"by Codetapper/Action on "
		INCBIN	"T:date"
		dc.b	0
		cnop	0,4

DSK_1		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS	; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		IFD	USE_DISK_IMAGES
		dc.l	FL_DISKIMAGE	; List of files to be saved
		ELSE
		dc.l	FL_1		; List of files to be saved
		ENDC
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_2		dc.l	DSK_3		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS	; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		IFD	USE_DISK_IMAGES
		dc.l	FL_DISKIMAGE	; List of files to be saved
		ELSE
		dc.l	FL_2		; List of files to be saved
		ENDC
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_3		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS	; Disk flags
		dc.l	TL_3		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		IFD	USE_DISK_IMAGES
		dc.l	FL_DISKIMAGE	; List of files to be saved
		ELSE
		dc.l	FL_3		; List of files to be saved
		ENDC
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1		TLENTRY	000,000,$1600,SYNC_STD,DMFM_STD
		TLENTRY 000,000,$0200,SYNC_STD,DMFM_NULL
		TLENTRY 001,001,$1600,SYNC_STD,DMFM_STD
		TLENTRY 001,001,$0200,SYNC_STD,DMFM_NULL
		TLENTRY	002,159,$1800,$1448,_DMFM_RNPDos_D1
		TLEND

TL_2		TLENTRY	000,159,$1800,$1448,_DMFM_RNPDos_D2
		TLEND

TL_3		TLENTRY	000,000,$1600,SYNC_STD,DMFM_STD
		TLENTRY 001,001,$1a00,SYNC_STD,DMFM_NULL
		TLENTRY	002,159,$1800,$1448,_DMFM_RNPDos_D3
		TLEND

		IFND	USE_DISK_IMAGES

FL_1		FLENTRY	_HERO,$19A*$200,$28*$200
		FLENTRY	_MUSC,$1C2*$200,$6B*$200
		FLENTRY	_MPIC,$22D*$200,$33*$200
		FLENTRY	_HPIC,$260*$200,$2A*$200
		FLENTRY	_AWA1,$28A*$200,$1F*$200
		FLENTRY	_AWA2,$2A9*$200,$1E*$200
		FLENTRY	_L1FX,$2C7*$200,$2F*$200
		FLENTRY	_FRUT,$2F6*$200,$28*$200
		FLENTRY	_FRUC,$31E*$200,$24*$200
		FLENTRY	_FRUM,$342*$200,2*$200
		FLENTRY	_LFFX,$344*$200,11*$200
		FLENTRY	_LFMU,$34F*$200,$2F*$200
		FLENTRY	_L1MU,$37E*$200,$45*$200
		FLENTRY	_L1LP,$3C3*$200,$1F*$200
		FLENTRY	_L1BM,$3E2*$200,$7D*$200
		FLENTRY	_L1BO,$45F*$200,$3B*$200
		FLENTRY	_L1MS,$49A*$200,9*$200
		FLENTRY	_L1MA1,$4A3*$200,12*$200
		FLENTRY	_L1MA2,$4B1*$200,$14*$200
		FLENTRY	_L1MA3,$4C7*$200,$12*$200
		FLENTRY	_L1MA4,$4DB*$200,$16*$200
		FLENTRY	_L1ET,$4F3*$200,$25*$200
		FLENTRY	_L2MU,$518*$200,$46*$200
		FLENTRY	_L2LP,$55E*$200,$1D*$200
		FLENTRY	_L2BM,$57B*$200,$84*$200
		FLENTRY	_L2BO,$5FF*$200,$3E*$200
		FLENTRY	_L2MS,$63D*$200,4*$200
		FLENTRY	_L2MA1,$641*$200,12*$200
		FLENTRY	_L2MA2,$64F*$200,$19*$200
		FLENTRY	_L2MA3,$66A*$200,$1B*$200
		FLENTRY	_L2MA4,$687*$200,$21*$200
		FLENTRY	_L2ET,$6AA*$200,$31*$200
		FLENTRY	_L6MA1,$6DB*$200,13*$200
		FLENTRY	_L6MA2,$6EA*$200,$1C*$200
		FLENTRY	_L6MA3,$708*$200,$1D*$200
		FLENTRY	_L6MA4,$727*$200,$25*$200
		FLENTRY	_INFT,$74E*$200,1*$200
		FLEND

FL_2		FLENTRY _L1FX,0*$200,$2F*$200
		FLENTRY _FRUT,$2F*$200,$28*$200
		FLENTRY _FRUC,$57*$200,$24*$200
		FLENTRY _FRUM,$7B*$200,2*$200
		FLENTRY _LFFX,$7D*$200,11*$200
		FLENTRY _LFMU,$88*$200,$2F*$200
		FLENTRY _L3MU,$B7*$200,$3A*$200
		FLENTRY _L3LP,$F1*$200,$1F*$200
		FLENTRY _L3BM,$110*$200,$7F*$200
		FLENTRY _L3BO,$18F*$200,$3A*$200
		FLENTRY _L3MS,$1C9*$200,5*$200
		FLENTRY _L3MA1,$1CE*$200,11*$200
		FLENTRY _L3MA2,$1DB*$200,$15*$200
		FLENTRY _L3MA3,$1F2*$200,$15*$200
		FLENTRY _L3MA4,$209*$200,$1D*$200
		FLENTRY _L3ET,$228*$200,$2C*$200
		FLENTRY _L4MU,$254*$200,$3E*$200
		FLENTRY _L4LP,$292*$200,$23*$200
		FLENTRY _L4BM,$2B5*$200,$71*$200
		FLENTRY _L4BO,$326*$200,$3D*$200
		FLENTRY _L4MS,$363*$200,4*$200
		FLENTRY _L4MA1,$367*$200,14*$200
		FLENTRY _L4MA2,$377*$200,$1B*$200
		FLENTRY _L4MA3,$394*$200,$15*$200
		FLENTRY _L4MA4,$3AB*$200,$23*$200
		FLENTRY _L4ET,$3D0*$200,$2F*$200
		FLENTRY _L5MU,$3FF*$200,$3B*$200
		FLENTRY _L5LP,$43A*$200,$17*$200
		FLENTRY _L5BM,$451*$200,$5A*$200
		FLENTRY _L5BO,$4AB*$200,$30*$200
		FLENTRY _L5MS,$4DB*$200,3*$200
		FLENTRY _L5MA1,$4DE*$200,10*$200
		FLENTRY _L5MA2,$4EA*$200,$1A*$200
		FLENTRY _L5MA3,$506*$200,$19*$200
		FLENTRY _L5MA4,$521*$200,$20*$200
		FLENTRY _L5ET,$543*$200,$28*$200
		FLENTRY _LBFX,$56B*$200,$1A*$200
		FLENTRY _LBMU,$585*$200,$3C*$200
		FLENTRY _LBLP,$5C1*$200,$2C*$200
		FLENTRY _LBBM,$5ED*$200,$48*$200
		FLENTRY _LBBO,$635*$200,$2A*$200
		FLENTRY _LBMA,$65F*$200,7*$200
		FLENTRY _L6ET,$668*$200,$29*$200
		FLENTRY _L6MU,$691*$200,$3B*$200
		FLENTRY _L6LP,$6CC*$200,$10*$200
		FLENTRY _L6BM,$6DC*$200,$4C*$200
		FLENTRY _L6BO,$728*$200,$3C*$200
		FLENTRY _L6MS,$764*$200,6*$200
		FLEND

FL_3		FLENTRY _Intro,0,$589*$200
		FLENTRY	_END1,$589*$200,$95*$200
		FLENTRY	_END2,$61E*$200,$95*$200
		FLENTRY	_LWBM,$6B3*$200,$35*$200
		FLENTRY	_LWBO,$6E8*$200,$1B*$200
		FLENTRY	_LWMS,$703*$200,2*$200
		FLENTRY	_LWMA1,$705*$200,4*$200
		FLENTRY	_L6MA1,$709*$200,13*$200
		FLENTRY _L6MA2,$718*200,$1C*$200
		FLENTRY	_L6MA3,$736*$200,$1D*$200
		FLENTRY	_L6MA4,$755*$200,$25*$200
		FLEND

_HERO		dc.b	"HERO",0
_END1		dc.b	"END1",0
_END2		dc.b	"END2",0
_AWA1		dc.b	"AWA1",0
_AWA2		dc.b	"AWA2",0
_INFT		dc.b	"INFT",0
_MUSC		dc.b	"MUSC",0
_MPIC		dc.b	"MPIC",0
_HPIC		dc.b	"HPIC",0
_FRUT		dc.b	"FRUT",0
_FRUC		dc.b	"FRUC",0
_FRUM		dc.b	"FRUM",0
_LFFX		dc.b	"LFFX",0
_LFMU		dc.b	"LFMU",0
_LBFX		dc.b	"LBFX",0
_LBMU		dc.b	"LBMU",0
_LBBM		dc.b	"LBBM",0
_LBBO		dc.b	"LBBO",0
_LBMA		dc.b	"LBMA",0
_LBLP		dc.b	"LBLP",0
_L1FX		dc.b	"L1FX",0
_L1MU		dc.b	"L1MU",0
_L1BM		dc.b	"L1BM",0
_L1BO		dc.b	"L1BO",0
_L1MS		dc.b	"L1MS",0
_L1LP		dc.b	"L1LP",0
_L1ET		dc.b	"L1ET",0
_L1MA1		dc.b	"L1MA1",0
_L1MA2		dc.b	"L1MA2",0
_L1MA3		dc.b	"L1MA3",0
_L1MA4		dc.b	"L1MA4",0
_L2MU		dc.b	"L2MU",0
_L2BM		dc.b	"L2BM",0
_L2BO		dc.b	"L2BO",0
_L2MS		dc.b	"L2MS",0
_L2LP		dc.b	"L2LP",0
_L2ET		dc.b	"L2ET",0
_L2MA1		dc.b	"L2MA1",0
_L2MA2		dc.b	"L2MA2",0
_L2MA3		dc.b	"L2MA3",0
_L2MA4		dc.b	"L2MA4",0
_L3MU		dc.b	"L3MU",0
_L3BM		dc.b	"L3BM",0
_L3BO		dc.b	"L3BO",0
_L3MS		dc.b	"L3MS",0
_L3LP		dc.b	"L3LP",0
_L3ET		dc.b	"L3ET",0
_L3MA1		dc.b	"L3MA1",0
_L3MA2		dc.b	"L3MA2",0
_L3MA3		dc.b	"L3MA3",0
_L3MA4		dc.b	"L3MA4",0
_L4MU		dc.b	"L4MU",0
_L4BM		dc.b	"L4BM",0
_L4BO		dc.b	"L4BO",0
_L4MS		dc.b	"L4MS",0
_L4LP		dc.b	"L4LP",0
_L4ET		dc.b	"L4ET",0
_L4MA1		dc.b	"L4MA1",0
_L4MA2		dc.b	"L4MA2",0
_L4MA3		dc.b	"L4MA3",0
_L4MA4		dc.b	"L4MA4",0
_L5MU		dc.b	"L5MU",0
_L5BM		dc.b	"L5BM",0
_L5BO		dc.b	"L5BO",0
_L5MS		dc.b	"L5MS",0
_L5LP		dc.b	"L5LP",0
_L5ET		dc.b	"L5ET",0
_L5MA1		dc.b	"L5MA1",0
_L5MA2		dc.b	"L5MA2",0
_L5MA3		dc.b	"L5MA3",0
_L5MA4		dc.b	"L5MA4",0
_L6MU		dc.b	"L6MU",0
_L6BM		dc.b	"L6BM",0
_L6BO		dc.b	"L6BO",0
_L6MS		dc.b	"L6MS",0
_L6LP		dc.b	"L6LP",0
_L6ET		dc.b	"L6ET",0
_L6MA1		dc.b	"L6MA1",0
_L6MA2		dc.b	"L6MA2",0
_L6MA3		dc.b	"L6MA3",0
_L6MA4		dc.b	"L6MA4",0
_LWBM		dc.b	"LWBM",0
_LWBO		dc.b	"LWBO",0
_LWMS		dc.b	"LWMS",0
_LWMA1		dc.b	"LWMA1",0
_Intro		dc.b	"Disk.3",0
		ENDC
		EVEN

;======================================================================

_DMFM_RNPDos_D1	move.l	#$12389a,d6		;d6 = Disk key for disk 1
		bra	_RN_PDos

_DMFM_RNPDos_D2	move.l	#$12389a,d6		;d6 = Disk key for disk 2
		bra	_RN_PDos

_DMFM_RNPDos_D3	move.l	#$12389a,d6		;d6 = Disk key for disk 3
		bra	_RN_PDos

;======================================================================

_RN_PDos	moveq	#0,d7			;d7 = Sector complete counter
		move.l	a0,a5			;a5 = MFM data
		move.l	a1,a2			;a2 = Destination

_NextSector	cmpi.w	#$4891,(a5)		;Check for word $4891
		bne	_NoSector

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
