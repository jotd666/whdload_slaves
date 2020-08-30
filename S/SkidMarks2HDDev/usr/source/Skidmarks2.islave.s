
		; Super Skidmarks disk imager
		;
		; Written by JOTD
		;
		; disk format is the same as Skidmarks
		; (fortunately :))

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"Skidmarks2.islave"

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$V","ER:"
Text		dc.b	"SkidMarks 2 / Super Skidmarks imager 1.0",10
		dc.b	"by JOTD on "
		INCBIN	"T:date"
		dc.b	0
		cnop	0,4

DSK_1		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_0_159		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	cars_1	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_2		dc.l	DSK_3		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_0_159		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	cars_2	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_3		dc.l	DSK_4		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_0_159		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	tracks_1	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_4		dc.l	DSK_5		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_0_159		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	tracks_2	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_5		dc.l	DSK_6		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_0_159		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	tracks_3	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_6		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_0_159		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	tracks_4	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TRACK_LENGTH = $1800

DEFTRACK:MACRO
	TLENTRY	\1,\1,TRACK_LENGTH,SYNC_STD,DMFM_Skidmarks
	ENDM

DEFCARAGA:MACRO
\1_name:
	dc.b	"vehicles/","\1",".aga",0
	ENDM

	DEFCARAGA	mini
	DEFCARAGA	porsche
	DEFCARAGA	vw
	DEFCARAGA	Camaro
	DEFCARAGA	TRUCK
	DEFCARAGA	F1
	DEFCARAGA	cow
	DEFCARAGA	midget
	DEFCARAGA	caravan


CARENTRY:MACRO
	FLENTRY	\1_name,\2,\3-\2
	ENDM

cars_1
	CARENTRY	mini,$1800,$20406
	CARENTRY	porsche,$20408,$3CCDA
	CARENTRY	vw,$3CCE0,$5EC6C
	CARENTRY	Camaro,$5EC70,$8724A
	CARENTRY	TRUCK,$87250,$AEE3E
	CARENTRY	F1,$AEE40,$D20D2
	CARENTRY	cow,$D20D8,$EED70
	FLEND

cars_2
	CARENTRY	midget,$1800,$244DE
	CARENTRY	caravan,$244E0,$4D4D4
;	CARENTRY	1,$4D4D8,$5D99E
;	CARENTRY	2,$5D9A0,$70CB0
;	CARENTRY	3,$70CB0,$878E4
;	CARENTRY	4,$878E8,$9DD1C
;	CARENTRY	5,$9DD20,$B1D50
;	CARENTRY	6,$B1D50,$C135C
;	CARENTRY	7,$C1360,$D4CF4
;	CARENTRY	8,$D4CF8,$EC24E
	FLEND

DEFTRK:MACRO
track\1:
	dc.b	"T:track_\1",0
	ENDM

	DEFTRK	1
	DEFTRK	2
	DEFTRK	3
	DEFTRK	4

	EVEN

TRACKENTRY:MACRO
tracks_\1
	FLENTRY	track\1,$1800,158*$1800
	FLEND
	ENDM

; filelist of track disks 1-4, filesize is approx. but we don't care
; because we'll perform a WRip in the end and join files to remove
; unnecessary data (would not match CD32 track files)

	TRACKENTRY	1
	TRACKENTRY	2
	TRACKENTRY	3
	TRACKENTRY	4

TL_0_159
	DEFTRACK	159
	DEFTRACK	158
	DEFTRACK	157
	DEFTRACK	156
	DEFTRACK	155
	DEFTRACK	154
	DEFTRACK	153
	DEFTRACK	152
	DEFTRACK	151
	DEFTRACK	150
	DEFTRACK	149
	DEFTRACK	148
	DEFTRACK	147
	DEFTRACK	146
	DEFTRACK	145
	DEFTRACK	144
	DEFTRACK	143
	DEFTRACK	142
	DEFTRACK	141
	DEFTRACK	140
	DEFTRACK	139
	DEFTRACK	138
	DEFTRACK	137
	DEFTRACK	136
	DEFTRACK	135
	DEFTRACK	134
	DEFTRACK	133
	DEFTRACK	132
	DEFTRACK	131
	DEFTRACK	130
	DEFTRACK	129
	DEFTRACK	128
	DEFTRACK	127
	DEFTRACK	126
	DEFTRACK	125
	DEFTRACK	124
	DEFTRACK	123
	DEFTRACK	122
	DEFTRACK	121
	DEFTRACK	120
	DEFTRACK	119
	DEFTRACK	118
	DEFTRACK	117
	DEFTRACK	116
	DEFTRACK	115
	DEFTRACK	114
	DEFTRACK	113
	DEFTRACK	112
	DEFTRACK	111
	DEFTRACK	110
	DEFTRACK	109
	DEFTRACK	108
	DEFTRACK	107
	DEFTRACK	106
	DEFTRACK	105
	DEFTRACK	104
	DEFTRACK	103
	DEFTRACK	102
	DEFTRACK	101
	DEFTRACK	100
	DEFTRACK	99
	DEFTRACK	98
	DEFTRACK	97
	DEFTRACK	96
	DEFTRACK	95
	DEFTRACK	94
	DEFTRACK	93
	DEFTRACK	92
	DEFTRACK	91
	DEFTRACK	90
	DEFTRACK	89
	DEFTRACK	88
	DEFTRACK	87
	DEFTRACK	86
	DEFTRACK	85
	DEFTRACK	84
	DEFTRACK	83
	DEFTRACK	82
	DEFTRACK	81
	DEFTRACK	80
	DEFTRACK	79
	DEFTRACK	78
	DEFTRACK	77
	DEFTRACK	76
	DEFTRACK	75
	DEFTRACK	74
	DEFTRACK	73
	DEFTRACK	72
	DEFTRACK	71
	DEFTRACK	70
	DEFTRACK	69
	DEFTRACK	68
	DEFTRACK	67
	DEFTRACK	66
	DEFTRACK	65
	DEFTRACK	64
	DEFTRACK	63
	DEFTRACK	62
	DEFTRACK	61
	DEFTRACK	60
	DEFTRACK	59
	DEFTRACK	58
	DEFTRACK	57
	DEFTRACK	56
	DEFTRACK	55
	DEFTRACK	54
	DEFTRACK	53
	DEFTRACK	52
	DEFTRACK	51
	DEFTRACK	50
	DEFTRACK	49
	DEFTRACK	48
	DEFTRACK	47
	DEFTRACK	46
	DEFTRACK	45
	DEFTRACK	44
	DEFTRACK	43
	DEFTRACK	42
	DEFTRACK	41
	DEFTRACK	40
	DEFTRACK	39
	DEFTRACK	38
	DEFTRACK	37
	DEFTRACK	36
	DEFTRACK	35
	DEFTRACK	34
	DEFTRACK	33
	DEFTRACK	32
	DEFTRACK	31
	DEFTRACK	30
	DEFTRACK	29
	DEFTRACK	28
	DEFTRACK	27
	DEFTRACK	26
	DEFTRACK	25
	DEFTRACK	24
	DEFTRACK	23
	DEFTRACK	22
	DEFTRACK	21
	DEFTRACK	20
	DEFTRACK	19
	DEFTRACK	18
	DEFTRACK	17
	DEFTRACK	16
	DEFTRACK	15
	DEFTRACK	14
	DEFTRACK	13
	DEFTRACK	12
	DEFTRACK	11
	DEFTRACK	10
	DEFTRACK	9
	DEFTRACK	8
	DEFTRACK	7
	DEFTRACK	6
	DEFTRACK	5
	DEFTRACK	4
	DEFTRACK	3
	DEFTRACK	2
	DEFTRACK	1
	DEFTRACK	0
		TLEND

;======================================================================

DMFM_Skidmarks
	MOVEA.L	A0,A2			; MFM data
	MOVEA.L	A1,A3			; destination

	move.l	A3,A0

	move.l	A2,A1

	addq.l	#2,A1
	LEA	$1808(A1),A2
	MOVE.L	#$55555555,D2
	MOVE.W	#$05FF,D3
.LB_1498
	bsr	.decode
	MOVE.L	D0,(A0)+
	DBF	D3,.LB_1498
	
	bsr	.decode	
	bsr	.decode	
	move.l	d0,d5	; d5: expected track checksum

	MOVE.L	A3,A0
	CLR.L	D0
	MOVE.W	#$05FF,D3
.LB_14BC
	MOVE.L	(A0)+,D4
	ADDX.L	D4,D0
	DBF	D3,.LB_14BC

	MOVE.L	#$FFFFFFFF,D1
	SUB.L	D0,D1

	MOVEQ	#$00,D0
	CMP.L	D5,D1
	BNE.B	_ChecksumError
	RTS	

.decode
	MOVE.L	(A1)+,D0
	AND.L	D2,D0
	ADD.L	D0,D0
	MOVE.L	(A2)+,D1
	AND.L	D2,D1
	OR.L	D1,D0
	rts

_OK		moveq	#IERR_OK,d0
		rts

_ChecksumError	moveq	#IERR_CHECKSUM,d0
		rts

_NoSector	moveq	#IERR_NOSECTOR,d0
		rts
