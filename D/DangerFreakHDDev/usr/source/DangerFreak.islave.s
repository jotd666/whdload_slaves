	; Danger Freak imager

	; A track contains $1400 bytes

	; Sector format description:

	; sync ($4489)
	; word ($2AAA)

		incdir	Include:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Danger Freak imager V1.0",10,"by JOTD",0
		cnop	0,4

DSK_1:		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0;DFLG_NORESTRICTIONS	; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1:
		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY	1,6,$1400,SYNC_STD,Decode_DF
		TLENTRY	7,7,$1400,SYNC_STD,DMFM_NULL
		TLENTRY	8,8,$1400,SYNC_STD,Decode_DF
		TLENTRY	9,9,$1400,SYNC_STD,DMFM_NULL
		TLENTRY	10,142,$1400,SYNC_STD,Decode_DF
		TLENTRY	143,143,$1400,SYNC_STD,DMFM_NULL
		TLENTRY	144,151,$1400,SYNC_STD,Decode_DF
		TLEND

Decode_DF
	move.l	A1,a3
	move.l	a0,a1

;.lab_000b
;	ADDQ.L	#2,A1			;01A0: 5489
;	CMPI	#$4489,(A1)		;01A2: 0C514489
;	BEQ.S	.lab_000b		;01A6: 67F8

	CMPI	#$2AAA,(A1)		;01A8: 0C512AAA
	BNE	.sectorerror
	ADDQ.L	#2,A1			;01B0: 5489
	MOVE	#$04FF,D7		;01B2: 3E3C04FF
	MOVEQ	#0,D3			;01B6: 7600
.lab_000C:
	MOVE.L	(A1)+,D0		;01B8: 2019
	ANDI.L	#$55555555,D0		;01BA: 028055555555
	ASL.L	#1,D0			;01C0: E380
	MOVE.L	(A1)+,D1		;01C2: 2219
	ANDI.L	#$55555555,D1		;01C4: 028155555555
	OR.L	D1,D0			;01CA: 8081
	ADD.L	D0,D3			;01CC: D680
	TST.L	D5			;01CE: 4A85
	BEQ.S	.lab_000D		;01D0: 6704
	SUBQ.L	#4,D5			;01D2: 5985
	MOVE.L	D0,(A3)+		;01D4: 26C0
.lab_000D:
	DBF	D7,.lab_000C		;01D6: 51CFFFE0
	MOVE.L	(A1)+,D0		;01DA: 2019
	ANDI.L	#$55555555,D0		;01DC: 028055555555
	ASL.L	#1,D0			;01E2: E380
	MOVE.L	(A1)+,D1		;01E4: 2219
	ANDI.L	#$55555555,D1		;01E6: 028155555555
	OR.L	D1,D0			;01EC: 8081
	CMP.B	D0,D3			;01EE: B600
;;;	BNE.S	.checksumerror

	moveq	#IERR_OK,d0
	rts
.checksumerror
	moveq	#IERR_CHECKSUM,d0
	rts
.trackerror
	moveq	#IERR_NOTRACK,d0
	rts
.sectorerror
	moveq	#IERR_NOSECTOR,d0
	rts

