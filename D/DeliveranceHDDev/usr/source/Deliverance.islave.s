
		; Deliverance disk imager
		;
		; Written by Harry & JOTD
		;
		; Sector format description:
		;
		; len: $18A0
		;
		; sync ($4489)

		incdir	Include:
		include	RawDIC.i

		OUTPUT	"Deliverance.islave"

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
Text		dc.b	"Deliverance imager 1.0",10
		dc.b	"by Harry & JOTD on "
		INCBIN	"T:date"
		dc.b	0
		cnop	0,4

DSK_1		dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	files_1	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

DSK_2		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	files_2		; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TRACK_LENGTH = $18A0

DEF_DEL_NAME:MACRO
del_\1:
	dc.b	"D_","\1",0
	ENDM
	
	DEF_DEL_NAME	00
	DEF_DEL_NAME	01
	DEF_DEL_NAME	02
	DEF_DEL_NAME	03
	DEF_DEL_NAME	04
	DEF_DEL_NAME	05
	DEF_DEL_NAME	06
	DEF_DEL_NAME	07
	DEF_DEL_NAME	08
	DEF_DEL_NAME	09
	DEF_DEL_NAME	10
	DEF_DEL_NAME	11
	DEF_DEL_NAME	12
	DEF_DEL_NAME	13
	DEF_DEL_NAME	14
	DEF_DEL_NAME	15
	DEF_DEL_NAME	16
	DEF_DEL_NAME	17
	DEF_DEL_NAME	18
	DEF_DEL_NAME	19
	DEF_DEL_NAME	20
	DEF_DEL_NAME	21
	DEF_DEL_NAME	22_1
	DEF_DEL_NAME	22_2
	DEF_DEL_NAME	23
	DEF_DEL_NAME	24
	DEF_DEL_NAME	25
	DEF_DEL_NAME	26
	DEF_DEL_NAME	27
	DEF_DEL_NAME	28
	DEF_DEL_NAME	29
	DEF_DEL_NAME	30
	DEF_DEL_NAME	31
	DEF_DEL_NAME	32
	DEF_DEL_NAME	33
	DEF_DEL_NAME	34
	DEF_DEL_NAME	35
	DEF_DEL_NAME	36
	DEF_DEL_NAME	37
	DEF_DEL_NAME	38


	even

DEF_ENTRY_1:MACRO
	FLENTRY	del_\1,\2-$18A0,\3-\2
	ENDM

DEF_ENTRY_2:MACRO
	FLENTRY	del_\1,\2-$F4B60-$18A0,\3-\2
	ENDM

files_1
	DEF_ENTRY_1	00,$18A0,$A44C
	DEF_ENTRY_1	01,$A44C,$C5CF
	DEF_ENTRY_1	02,$C5CF,$00013295
	DEF_ENTRY_1	03,$13295,$17C8E
	DEF_ENTRY_1	04,$17C8E,$00017FA1
	DEF_ENTRY_1	05,$00017FA1,$00040997
	DEF_ENTRY_1	06,$00040997,$0004A86C
	DEF_ENTRY_1	07,$0004A86C,$0004BB44
	DEF_ENTRY_1	08,$0004BB44,$0004BC74
	DEF_ENTRY_1	09,$0004BC74,$000534D6
	DEF_ENTRY_1	10,$000534D6,$00073783
	DEF_ENTRY_1	11,$00073783,$000763E6
	DEF_ENTRY_1	12,$000763E6,$00076EF5
	DEF_ENTRY_1	13,$00076EF5,$00090CD8
	DEF_ENTRY_1	14,$00090CD8,$000B71C9
	DEF_ENTRY_1	15,$000B71C9,$000B787D
	DEF_ENTRY_1	16,$000B787D,$000B7976
	DEF_ENTRY_1	17,$000B7976,$000C9C9F
	DEF_ENTRY_1	18,$000C9C9F,$000DF8D9
	DEF_ENTRY_1	19,$000DF8D9,$000E1422
	DEF_ENTRY_1	20,$000E1422,$000E1945
	DEF_ENTRY_1	21,$000E1945,$000F09C5
	DEF_ENTRY_1	22_1,$000F09C5,$F4B60+$18A0
	FLEND


files_2
	DEF_ENTRY_2	22_2,$F4B60+$18A0,$001159A8-$3140	; duplicate data
	DEF_ENTRY_2	23,$001159A8,$00115F1E
	DEF_ENTRY_2	24,$00115F1E,$00115FFB
	DEF_ENTRY_2	25,$00115FFB,$0011C88F
	DEF_ENTRY_2	26,$0011C88F,$00148492
	DEF_ENTRY_2	27,$00148492,$00149C2A
	DEF_ENTRY_2	28,$00149C2A,$00149FE6
	DEF_ENTRY_2	29,$00149FE6,$001620AC
	DEF_ENTRY_2	30,$001620AC,$001825EF
	DEF_ENTRY_2	31,$001825EF,$00182DA0
	DEF_ENTRY_2	32,$00182DA0,$00182E7E
	DEF_ENTRY_2	33,$00182E7E,$001A3809
	DEF_ENTRY_2	34,$001A3809,$001C93F7
	DEF_ENTRY_2	35,$001C93F7,$001CA4F2
	DEF_ENTRY_2	36,$001CA4F2,$001CA7C6
	DEF_ENTRY_2	37,$001CA7C6,$001D37E2
	DEF_ENTRY_2	38,$001D37E2,$001EB7A4

	FLEND

TL_1
	TLENTRY	1,159,TRACK_LENGTH,$2112,DMFM_Deliverance
	TLEND

TL_2
	TLENTRY	0,159,TRACK_LENGTH,$2112,DMFM_Deliverance
	TLEND

;======================================================================

; < A0 raw
; < A1 dec

DMFM_Deliverance
	movem.l	d1-a6,-(a7)

	move.l	a1,a4	; A4 = dec in the original routine

	MOVE.L	#$55555555,D5
	MOVE	#$0003,D2
.lab_002B:
	CMPI	#$5245,(A0)+
	DBEQ	D2,.lab_002B
	BNE	.no_sector
	MOVEM	(A0)+,D0-D1
	AND	D5,D0
	AND	D5,D1
	ADD	D0,D0
	OR	D1,D0

;	CMP	EXT_0004.W,D0
;	BNE	.lab_002E		;disk number (skipped)

	MOVEM	(A0)+,D0-D1
	AND	D5,D0
	AND	D5,D1
	ADD	D0,D0
	OR	D1,D0
;	CMP	EXT_0005.W,D0
;	BNE	.lab_002E		;track number (skipped)

	MOVEQ	#0,D0
	MOVE	#$0C50,D1
	MOVEA.L	A0,A1

	; compute checksum

.lab_002C:
	MOVE.L	(A1)+,D2
	EOR.L	D2,D0
	DBF	D1,.lab_002C
	AND.L	D5,D0
	BNE.S	.ERR

	; decode track into decoded buffer

	MOVE	#$18A0,D2

; removed in-game sector offset
;	SUB	D3,D2
;	ADD	D3,D3
;	ADDA	D3,A0

	SUBQ	#1,D2
.lab_002D:
	MOVE.B	(A0)+,D0
	MOVE.B	(A0)+,D1
	AND.B	D5,D0
	AND.B	D5,D1
	ADD.B	D1,D1
	OR.B	D1,D0
	MOVE.B	D0,(A4)+
;;	SUBQ.L	#1,D4			; in-game data counter: removed now we want full decode
	DBF	D2,.lab_002D
	MOVEQ	#0,D3

.END	moveq	#IERR_OK,d0
.out
	movem.l	(a7)+,d1-a6
	rts

.ERR
	moveq	#IERR_CHECKSUM,d0
	bra.b	.out

.no_sector
	moveq	#IERR_NOSECTOR,d0
	bra.b	.out
