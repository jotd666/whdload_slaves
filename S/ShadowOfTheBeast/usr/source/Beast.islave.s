                incdir  Includes:
                include RawDIC.i

                SLAVE_HEADER
                dc.b    1       ; Slave version
                dc.b    0;SFLG_DEBUG;0       ; Slave flags
                dc.l    DSK_1   ; Pointer to the first disk structure
                dc.l    Text    ; Pointer to the text displayed in the imager window

                dc.b    "$VER:"
Text:           dc.b    "Shadow Of The Beast imager V1.2a Harry's Patcher",10,"Adapted for RAWDIC by CFou! "
		dc.b	"on 16.12.2019",0
                cnop    0,4

DSK_1:          dc.l    DSK_2               ; Pointer to next disk structure
                dc.w    1               ; Disk structure version
                dc.w    DFLG_DOUBLEINC  ; Disk flags
                dc.l    TL_1            ; List of tracks which contain data
                dc.l    0               ; UNUSED, ALWAYS SET TO 0!
                dc.l    FL_DISK1	; List of files to be saved
                dc.l    CR_Disk1V1      ; Table of certain tracks with CRC values
                dc.l    DSK_1_LT        ; Alternative disk structure, if CRC failed
                dc.l    0               ; Called before a disk is read
                dc.l    0               ; Called after a disk has been read


DSK_2:          dc.l    0               ; Pointer to next disk structure
                dc.w    1               ; Disk structure version
                dc.w    DFLG_DOUBLEINC  ; Disk flags
                dc.l    TL_2            ; List of tracks which contain data
                dc.l    0               ; UNUSED, ALWAYS SET TO 0!
                dc.l    FL_DISKIMAGE    ; List of files to be saved
                dc.l    0              	; Table of certain tracks with CRC values
                dc.l    0               ; Alternative disk structure, if CRC failed
                dc.l    0            	; Called before a disk is read
                dc.l    0               ; Called after a disk has been read


DSK_1_LT

		dc.l    DSK_2_LT        ; Pointer to next disk structure
                dc.w    1               ; Disk structure version
                dc.w    DFLG_DOUBLEINC  ; Disk flags
                dc.l    TL_1_LT         ; List of tracks which contain data
                dc.l    0               ; UNUSED, ALWAYS SET TO 0!
                dc.l    FL_DISK1_LT	; List of files to be saved
                dc.l    0               ; Table of certain tracks with CRC values
                dc.l    0               ; Alternative disk structure, if CRC failed
                dc.l    0               ; Called before a disk is read
                dc.l    0               ; Called after a disk has been read


DSK_2_LT:       dc.l    0               ; Pointer to next disk structure
                dc.w    1               ; Disk structure version
                dc.w    DFLG_DOUBLEINC  ; Disk flags
                dc.l    TL_2_LT            ; List of tracks which contain data
                dc.l    0               ; UNUSED, ALWAYS SET TO 0!
                dc.l    FL_DISKIMAGE    ; List of files to be saved
                dc.l    0               ; Table of certain tracks with CRC values
                dc.l    0               ; Alternative disk structure, if CRC failed
                dc.l    0               ; Called before a disk is read
                dc.l    0               ; Called after a disk has been read





LG_TRACK=$1838
LG_TRACK_LT=$190C

TL_1:
                ;TLENTRY 0,0,$1600,SYNC_STD,DMFM_STD
                TLENTRY 0,0,$400,SYNC_STD,DMFM_STD
                TLENTRY 2,159,LG_TRACK,$4489,DMFM_BeastS0
                TLENTRY 3,80,LG_TRACK,$4489,DMFM_BeastS1
                TLEND

TL_2:
                TLENTRY 0,159,LG_TRACK,$4489,DMFM_BeastS0_Disk2
                TLENTRY 3,159,LG_TRACK,$4489,DMFM_BeastS1_Disk2
                TLEND

FL_DISK1
	FLENTRY	FL_BOOTNAME,0,$400
	FLENTRY	FL_DISKNAME,$400,LG_TRACK*118
	FLEND

FL_BOOTNAME:	dc.b	"Init",0
		even

CR_Disk1V1
	CRCENTRY 0,$4DA9		;$6B50
	;CRCENTRY 20,$757E
	CRCEND




;---------------- Long track version
TL_1_LT:
                TLENTRY 0,0,$400,SYNC_STD,DMFM_STD
                TLENTRY 2,159,LG_TRACK_LT,$4489,DMFM_BeastS0LT
                TLENTRY 3,159,LG_TRACK_LT,$4489,DMFM_BeastS1LT
                TLEND

TL_2_LT:
                TLENTRY 0,159,LG_TRACK_LT,$4489,DMFM_BeastS0_Disk2LT
                TLENTRY 3,159,LG_TRACK_LT,$4489,DMFM_BeastS1_Disk2LT
                TLEND

FL_DISK1_LT
	FLENTRY	FL_BOOTNAME,0,$400
	FLENTRY	FL_DISKNAME,$400,LG_TRACK_LT*158
	FLEND



DMFM_BeastS1_Disk2LT:
	movem.l	d1-a6,-(a7)
	LEA 	_CRCTAB(pc),a3
	LEA 	_CRCTAB1LT(pc),a2
	move.l	a2,(a3)
	lea	TRLENGTH(pc),a3
	move.w	#LG_TRACK_LT/4-1,(A3)		; $642
	lea	_LGtrack(pc),a3
	move.l	#LG_TRACK_LT,(A3)
	lea	NumDisk(pc),A3
	move.l	#1,(a3)
	lea	Side(pc),A3
	move.l	#1,(a3)
	bra	_common
DMFM_BeastS0_Disk2LT:
	movem.l	d1-a6,-(a7)
	LEA 	_CRCTAB(pc),a3
	LEA 	_CRCTAB1LT(pc),a2
	move.l	a2,(a3)
	lea	TRLENGTH(pc),a3
	move.w	#LG_TRACK_LT/4-1,(A3)		; $642
	lea	_LGtrack(pc),a3
	move.l	#LG_TRACK_LT,(A3)
	lea	NumDisk(pc),A3
	move.l	#1,(a3)
	lea	Side(pc),A3
	move.l	#0,(a3)
	bra	_common
DMFM_BeastS1LT:
	movem.l	d1-a6,-(a7)
	LEA 	_CRCTAB(pc),a3
	LEA 	_CRCTAB1LT(pc),a2
	move.l	a2,(a3)
	lea	TRLENGTH(pc),a3
	move.w	#LG_TRACK_LT/4-1,(A3)		; $642
	lea	_LGtrack(pc),a3
	move.l	#LG_TRACK_LT,(A3)
	lea	NumDisk(pc),A3
	move.l	#0,(a3)
	lea	Side(pc),A3
	move.l	#1,(a3)
	bra	_common
DMFM_BeastS0LT:
	movem.l	d1-a6,-(a7)
	LEA 	_CRCTAB(pc),a3
	LEA 	_CRCTAB1LT(pc),a2
	move.l	a2,(a3)
	lea	TRLENGTH(pc),a3
	move.w	#LG_TRACK_LT/4-1,(A3)		; $642
	lea	_LGtrack(pc),a3
	move.l	#LG_TRACK_LT,(A3)
	lea	NumDisk(pc),A3
	move.l	#0,(a3)
	lea	Side(pc),A3
	move.l	#0,(a3)
	BRA	_common


Side
	dc.l	0
NumDisk
	dc.l	0

_LGtrack	dc.l	LG_TRACK

DMFM_BeastS1_Disk2:
	movem.l	d1-a6,-(a7)
	LEA 	_CRCTAB(pc),a3
	LEA 	_CRCTAB1(pc),a2
	move.l	a2,(a3)
	lea	_LGtrack(pc),a3
	move.l	#LG_TRACK,(A3)
	lea	NumDisk(pc),A3
	move.l	#1,(a3)
	lea	Side(pc),A3
	move.l	#1,(a3)
	bra	_common
DMFM_BeastS0_Disk2:
	movem.l	d1-a6,-(a7)
	LEA 	_CRCTAB(pc),a3
	LEA 	_CRCTAB1(pc),a2
	move.l	a2,(a3)
	lea	_LGtrack(pc),a3
	move.l	#LG_TRACK,(A3)
	lea	NumDisk(pc),A3
	move.l	#1,(a3)
	lea	Side(pc),A3
	move.l	#0,(a3)
	bra	_common
DMFM_BeastS1:
	movem.l	d1-a6,-(a7)
	LEA 	_CRCTAB(pc),a3
	LEA 	_CRCTAB1(pc),a2
	move.l	a2,(a3)
	lea	_LGtrack(pc),a3
	move.l	#LG_TRACK,(A3)
	lea	NumDisk(pc),A3
	move.l	#0,(a3)
	lea	Side(pc),A3
	move.l	#1,(a3)
	bra	_common
DMFM_BeastS0:
	movem.l	d1-a6,-(a7)
	LEA 	_CRCTAB(pc),a3
	LEA 	_CRCTAB1(pc),a2
	move.l	a2,(a3)
	lea	_LGtrack(pc),a3
	move.l	#LG_TRACK,(A3)
	lea	NumDisk(pc),A3
	move.l	#0,(a3)
	lea	Side(pc),A3
	move.l	#0,(a3)

_common
	sub.l	#4,A0
	move.l	d0,D2
	move.l	A1,A3
	move.l	A0,A2
;.t 	bra .t
	
.5	MOVEQ.L	#$4,D5				;4 tries, then error

.55
	move.l	A2,A0
	move.l	A3,A1

	;MOVE.L	PTB_DEVICESOURCEPTR(A5),A1
	;MOVE.L	PTB_SPACE(A5),IO_DATA(A1)	;track is to load in PTB_SPACE
	;MOVE.L	#$7C00,IO_LENGTH(A1)		;double length of track
						;to decode the index-sync-read data
						;my own trackcounter
	MOVE.L	D2,D0
	LSL.L	#1,D0
	CMP.W	#$A0,D0				;DISK IS ORGANIZED AS TRACK 0-$4F
						;ON SIDE 0, $50-$9F ON SIDE 1
	BLO.S	.S1
	SUB.W	#$A0-1,D0			;SUBTRACT $A0 AND ADD 1
.S1

	;LEA.L	$7C00(A0),A3

	BSR.W	TRACKDECODE
	TST.L	D0
	BEQ.S	.R1OK
	DBF	D5,.55
	BRA.W	.NOTORG

.R1OK

;.t 	bra .t

	move.l	NumDisk(pc),d7
	mulu	#80*4,d7			; $A0*2
	move.l	Side(pc),d6

	LEA.L	(A3),A0
;	MOVE.L	#$1838,D0
	move.l _LGtrack(pc),d0

	BSR.W	CRC16				;COMPARE TRACKCRC

	;LEA.L	CRCTAB1(PC),A0
	move.l	_CRCTAB(pc),a0

	CMP.B	#1,D6				; side
	BNE.S	.CRC1

	lea	80*2(A0),A0	;$A0
	sub.l	#1,D2

	;LEA.L	CRCTAB2(PC),A0
.CRC1	MOVE.L	D2,D1

	add.l	D7,A0		; nextdisk
	;LSL.W	#1,D1
	CMP.W	0(A0,D1.W),D0
	BNE.W	.NOTORG


	movem.l	(a7)+,d1-a6
	moveq	#IERR_OK,d0
	rts
.NOTORG
	nop
.ERR
	movem.l	(a7)+,d1-a6
	moveq	#IERR_CHECKSUM,d0
	rts

	rts

;< A0 RAWTRACK
;< A1 TRACKBUFFER
;> D0 ERROR
;INTERN
;  D5 SHIFT
;  D7 SEKTORANZAHL

TRLENGTH	DC.W	$060D ; ($1838/4-1)

TRACKDECODE	MOVEM.L	A2/A3/A4/A5/D2/D3/D4/D5/D6/D7,-(A7)
	MOVE.L	A0,A2
;	LEA.L	($7C00-$1900*2)(A0),A4
.ANF
;;	MOVE.L	#$55555555,D3
	;BSR.W	GETSYNC
	;TST.L	D0
	;BNE.W	.ERR
	;SUBQ.L	#2,A2		;DUE MY LONGWORDREADER

;	MOVE.L	(A6)+,D0
	MOVE.L	(A2)+,D0	;get higher part
	MOVE.L	(A2),D6		;get lower part
	LSR.L	D5,D6		;shift lower part with count
	MOVEQ.L	#$20,D2		;higher part has to be shifted to fill
				;the rest-place, a longword has 20 bits
	SUB.L	D5,D2
	LSL.L	D2,D0
	OR.L	D6,D0		;my code ends

;	MOVE.L	(A6)+,D1
	MOVE.L	(A2)+,D1	;get higher part
	MOVE.L	(A2),D6		;get lower part
	LSR.L	D5,D6		;shift lower part with count
	MOVEQ.L	#$20,D2		;higher part has to be shifted to fill
				;the rest-place, a longword has 20 bits
	SUB.L	D5,D2
	LSL.L	D2,D1
	OR.L	D6,D1		;my code ends
	ASL.L	#1,D0
	ANDI.L	#$AAAAAAAA,D0
	ANDI.L	#$55555555,D1
	OR.L	D1,D0
	CMP.L	#$534F5442,D0	;'SOTB'
	BNE.B	.ERR

	MOVE.W	TRLENGTH(PC),D7

.1
;	MOVE.L	(A6)+,D0
	MOVE.L	(A2)+,D0	;get higher part
	MOVE.L	(A2),D6		;get lower part
	LSR.L	D5,D6		;shift lower part with count
	MOVEQ.L	#$20,D2		;higher part has to be shifted to fill
				;the rest-place, a longword has 20 bits
	SUB.L	D5,D2
	LSL.L	D2,D0
	OR.L	D6,D0		;my code ends

;	MOVE.L	(A6)+,D1
	MOVE.L	(A2)+,D1	;get higher part
	MOVE.L	(A2),D6		;get lower part
	LSR.L	D5,D6		;shift lower part with count
	MOVEQ.L	#$20,D2		;higher part has to be shifted to fill
				;the rest-place, a longword has 20 bits
	SUB.L	D5,D2
	LSL.L	D2,D1
	OR.L	D6,D1		;my code ends

	ASL.L	#1,D0
	ANDI.L	#$AAAAAAAA,D0
	ANDI.L	#$55555555,D1
	OR.L	D1,D0
	MOVE.L	D0,(A1)+
	DBF	D7,.1
				;ROUTINE HAS NO CHECKSUM *ARGL*
	MOVEQ.L	#0,D0
.END
	MOVEM.L	(A7)+,A2/A3/A4/A5/D2/D3/D4/D5/D6/D7
	RTS
.ERR
	MOVEQ.L	#-1,D0
	BRA.S	.END


;----------------------------------------
; ANSI CRC16
; taken from "ProAsm"
; Übergabe :	d0 = ULONG length
;		a0 = APTR  address
; Rückgabe :	d0 = UWORD crc checksum

CRC16		;CheckVersion 3,resload_CRC16	;avail starting version 3
		movem.l	d2/d5/d7,-(a7)
		move.l	d0,d7
		moveq	#0,d0
		lea	_CRC16table(pc),a1	;CRC16 table for speed up
		move.w	#$ff,d1
		moveq	#0,d2
.loop		move.b	(a0)+,d2		;take a byte
		eor.w	d2,d0
		move.w	d0,d5
		and.w	d1,d0
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lsr.w	#8,d5
		eor.w	d5,d0
		subq.l	#1,d7
		bne	.loop
		movem.l	(a7)+,d2/d5/d7
		rts

_CRC16table:
	dc.w  $0000,$c0c1,$c181,$0140,$c301,$03c0,$0280,$c241
	dc.w  $c601,$06c0,$0780,$c741,$0500,$c5c1,$c481,$0440
	dc.w  $cc01,$0cc0,$0d80,$cd41,$0f00,$cfc1,$ce81,$0e40
	dc.w  $0a00,$cac1,$cb81,$0b40,$c901,$09c0,$0880,$c841
	dc.w  $d801,$18c0,$1980,$d941,$1b00,$dbc1,$da81,$1a40
	dc.w  $1e00,$dec1,$df81,$1f40,$dd01,$1dc0,$1c80,$dc41
	dc.w  $1400,$d4c1,$d581,$1540,$d701,$17c0,$1680,$d641
	dc.w  $d201,$12c0,$1380,$d341,$1100,$d1c1,$d081,$1040
	dc.w  $f001,$30c0,$3180,$f141,$3300,$f3c1,$f281,$3240
	dc.w  $3600,$f6c1,$f781,$3740,$f501,$35c0,$3480,$f441
	dc.w  $3c00,$fcc1,$fd81,$3d40,$ff01,$3fc0,$3e80,$fe41
	dc.w  $fa01,$3ac0,$3b80,$fb41,$3900,$f9c1,$f881,$3840
	dc.w  $2800,$e8c1,$e981,$2940,$eb01,$2bc0,$2a80,$ea41
	dc.w  $ee01,$2ec0,$2f80,$ef41,$2d00,$edc1,$ec81,$2c40
	dc.w  $e401,$24c0,$2580,$e541,$2700,$e7c1,$e681,$2640
	dc.w  $2200,$e2c1,$e381,$2340,$e101,$21c0,$2080,$e041
	dc.w  $a001,$60c0,$6180,$a141,$6300,$a3c1,$a281,$6240
	dc.w  $6600,$a6c1,$a781,$6740,$a501,$65c0,$6480,$a441
	dc.w  $6c00,$acc1,$ad81,$6d40,$af01,$6fc0,$6e80,$ae41
	dc.w  $aa01,$6ac0,$6b80,$ab41,$6900,$a9c1,$a881,$6840
	dc.w  $7800,$b8c1,$b981,$7940,$bb01,$7bc0,$7a80,$ba41
	dc.w  $be01,$7ec0,$7f80,$bf41,$7d00,$bdc1,$bc81,$7c40
	dc.w  $b401,$74c0,$7580,$b541,$7700,$b7c1,$b681,$7640
	dc.w  $7200,$b2c1,$b381,$7340,$b101,$71c0,$7080,$b041
	dc.w  $5000,$90c1,$9181,$5140,$9301,$53c0,$5280,$9241
	dc.w  $9601,$56c0,$5780,$9741,$5500,$95c1,$9481,$5440
	dc.w  $9c01,$5cc0,$5d80,$9d41,$5f00,$9fc1,$9e81,$5e40
	dc.w  $5a00,$9ac1,$9b81,$5b40,$9901,$59c0,$5880,$9841
	dc.w  $8801,$48c0,$4980,$8941,$4b00,$8bc1,$8a81,$4a40
	dc.w  $4e00,$8ec1,$8f81,$4f40,$8d01,$4dc0,$4c80,$8c41
	dc.w  $4400,$84c1,$8581,$4540,$8701,$47c0,$4680,$8641
	dc.w  $8201,$42c0,$4380,$8341,$4100,$81c1,$8081,$4040

_CRCTAB	dc.l	0

_CRCTAB1	
CRCTAB2		EQU	*+$A0*2
	INCBIN	BEAST1CRC
_CRCTAB1LT	
CRCTAB2LT	EQU	*+$A0*2
	INCBIN	BEAST1CRCLT

	END
