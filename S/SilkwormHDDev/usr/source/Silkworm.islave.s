
		; Silkworm Imager  (Barfly assembler source)
		;
		; Written by Keith Krellwitz (Abaddon)
		;

		incdir	include:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_2		; Pointer to the first disk structure
		dc.l	Text		; Pointer to the text displayed in the imager window

		IFD	BARFLY
		OUTPUT	"Silkworm.islave"
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC
		ENDC

		dc.b	"$VER: "
Text		dc.b	"Silkworm Imager V1.1",10
		dc.b	"by Keith Krellwitz (Abaddon) "
		dc.b	"(09.24.2011)"
		dc.b	0
		cnop	0,4

;=====================================================================

_file0		dc.b	"00.slk",0
_file1		dc.b	"01.slk",0
_file2		dc.b	"50.slk",0
_file3		dc.b	"54.slk",0
_file4		dc.b	"58.slk",0
_file5		dc.b	"5c.slk",0
_file6		dc.b	"60.slk",0
_file7		dc.b	"64.slk",0
_file8		dc.b	"68.slk",0
_file9		dc.b	"6c.slk",0
_file10		dc.b	"70.slk",0
		EVEN


DSK_1		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl2	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read


TL_1		TLENTRY	1,1,$1600,SYNC_STD,DMFM_STD
		TLENTRY 002,002,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 004,008,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 010,010,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 012,056,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 080,080,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 082,084,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 086,088,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 090,092,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 094,096,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 098,100,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 102,104,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 106,108,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 110,112,$1600,SYNC_STD,_DecodeLoop
		TLENTRY 114,116,$1600,SYNC_STD,_DecodeLoop
		TLEND
		EVEN

DSK_2		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl2	; List of files to be saved
		dc.l	_crc2		; Table of certain tracks with CRC values
		dc.l	DSK_1		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read


TL_2		TLENTRY	1,1,$1600,SYNC_STD,DMFM_STD
		TLENTRY 002,002,$1600,$4b29,_DecodeLoop2
		TLENTRY 004,008,$1600,$4b29,_DecodeLoop2
		TLENTRY 010,010,$1600,$4b29,_DecodeLoop2
		TLENTRY 012,056,$1600,$4b29,_DecodeLoop2
		TLENTRY 080,080,$1600,$4b29,_DecodeLoop2
		TLENTRY 082,084,$1600,$4b29,_DecodeLoop2
		TLENTRY 086,088,$1600,$4b29,_DecodeLoop2
		TLENTRY 090,092,$1600,$4b29,_DecodeLoop2
		TLENTRY 094,096,$1600,$4b29,_DecodeLoop2
		TLENTRY 098,100,$1600,$4b29,_DecodeLoop2
		TLENTRY 102,104,$1600,$4b29,_DecodeLoop2
		TLENTRY 106,108,$1600,$4b29,_DecodeLoop2
		TLENTRY 110,112,$1600,$4b29,_DecodeLoop2
		TLENTRY 114,116,$1600,$4b29,_DecodeLoop2
		TLEND
		EVEN

_fl2		FLENTRY	_file0,$1600,$8400
		FLENTRY	_file1,$9A00,$3F400
		FLENTRY	_file2,$48E00,$5800
		FLENTRY	_file3,$4D000,$5800
		FLENTRY	_file4,$51200,$5800
		FLENTRY	_file5,$55400,$5800
		FLENTRY	_file6,$59600,$5800
		FLENTRY	_file7,$5D800,$5800
		FLENTRY	_file8,$61A00,$5800
		FLENTRY	_file9,$65C00,$5800
		FLENTRY	_file10,$69E00,$5800
		FLEND
		EVEN


_crc2		CRCENTRY 1,$3c64
		CRCEND


;=====================================================================


_DecodeLoop2
		cmpi.l		#$aaaaaaa5,2(a0)
		beq.b		.decode
		jsr		rawdic_NextSync(a5)
		tst.l		d0
		bne		_DecodeLoop2
		moveq		#IERR_CHECKSUM,d0
		rts
		
.decode		
		ADDQ.W		#6,A0
		MOVEQ		#0,D3
		MOVE.W		#$57F,D4
.dec
		MOVE.L		(A0)+,D1
		MOVE.L		(A0)+,D2
		ANDI.L		#$55555555,D1
		ANDI.L		#$55555555,D2
		ASL.L		#1,D1
		OR.L		D1,D2
		MOVE.L		D2,(A1)+
		ADD.L		D2,D3
		DBF		D4,.dec
		MOVE.L		(A0)+,D1
		MOVE.L		(A0)+,D2
		ANDI.L		#$55555555,D1
		ANDI.L		#$55555555,D2
		ASL.L		#1,D1
		OR.L		D1,D2
		CMP.L		D2,D3
		bne		_Checksum
		moveq		#IERR_OK,d0
		rts




_DecodeLoop
		ADDQ.W		#4,A0
		MOVEQ		#0,D3
		MOVE.W		#$57F,D4
.dec
		MOVE.L		(A0)+,D1
		MOVE.L		(A0)+,D2
		ANDI.L		#$55555555,D1
		ANDI.L		#$55555555,D2
		ASL.L		#1,D1
		OR.L		D1,D2
		MOVE.L		D2,(A1)+
		ADD.L		D2,D3
		DBF		D4,.dec
		MOVE.L		(A0)+,D1
		MOVE.L		(A0)+,D2
		ANDI.L		#$55555555,D1
		ANDI.L		#$55555555,D2
		ASL.L		#1,D1
		OR.L		D1,D2
		CMP.L		D2,D3
		bne		_Checksum
		moveq		#IERR_OK,d0
		rts




_Checksum	moveq		#IERR_CHECKSUM,d0
		rts


_NoSector	moveq		#IERR_NOSECTOR,d0
		rts
