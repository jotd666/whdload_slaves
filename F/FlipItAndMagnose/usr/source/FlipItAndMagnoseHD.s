;*---------------------------------------------------------------------------
;  :Program.	flipitslave.asm
;  :Contents.	Slave for "Flip-it & Magnose"
;  :Author.	Harry
;  :History.	31.10.1998
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25
;  :To Do.
;---------------------------------------------------------------------------*

;crc_v1	= $57C1
;crc_v2	= $F885	;NTSC


	INCDIR	asm-one:Include2.0/
	INCLUDE	whdload.i


;	OUTPUT	wart:gods/gods.slave
;	BOPT	O+ OG+			;enable optimizing
;	BOPT	w4-			;disable 64k warnings

;======================================================================

.base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	4		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		dc.l	$81000		;ws_BaseMemSize
		dc.l	$00		;ws_ExecInstall
		dc.w	SLStart-.base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
 		dc.b	$00		;debugkey
_keyexit		dc.b	$5D		;quitkey

;======================================================================

;	DOSCMD	"WDate >T:date"
		dc.b	"$VER:Flip-it_&_Magnose_Slave_1.00"
;	INCBIN	"T:date"
		dc.b	0
		even

;======================================================================
SLStart	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using

		move.l	#CACRF_EnableI,d0	;enable instruction cache
		move.l	d0,d1			;mask
		jsr	(resload_SetCACR,a0)

	MOVE.L	#$0,D0				;LOAD TRACK1+2
	MOVE.L	#$1800,D1
	LEA.L	$60000,A0
	MOVEQ	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)

	MOVE.W	#$4EF9,$6016C
	PEA	LOADROUTV(PC)
	MOVE.L	(A7)+,$6016E

	PEA	PATCH1(PC)
	MOVE.L	(A7)+,$600FE

;	MOVE.B	#$88,$BFED01


	MOVEQ.L	#0,D7
	SUB.L	A3,A3
	MOVE.W	#$8200,$dff096

	JMP	$60000

PATCH1

	MOVE.W	#$4EF9,$15B0
	PEA	LOADROUT(PC)
	MOVE.L	(A7)+,$15B2

;	MOVE.L	#$4EB80100,$1A0C.W
;	MOVE.L	#$4EB80100,$1D58.W

;	PEA	KEYHP(PC)
;	MOVE.L	(A7)+,$68.W

	CLR.W	$183C.W
	LEA.L	$400.W,A0
	OR.W	#$200,$188A.W

	JMP	$400


LOADROUTV
	MOVEM.L	D0-A6,-(A7)
	MOVE.L	$615B8,A0
	MOVE.L	$615B4,D1
	SUB.L	A0,D1
	BRA.S	LOADGENERAL


;A0-DEST
;D0-STARTTRACK
;D1-#OFTRACKS

LOADROUT
	LEA.L	$16FC.W,A5
	MOVEM.L	D0-A6,-(A7)
	MOVE.L	$1984E,A0
	MOVE.L	$19852,D1
	SUB.L	A0,D1


LOADGENERAL
	SUBQ.L	#2,D0
	MULU.W	#$1800,D0
.DL
;	MOVE.L	D1,D1	;LENGTH
	MOVEQ.L	#1,D2	;DISK#
;	MOVE.L	A0,A0	;DEST
;	MOVE.L	D0,D0	;DISKSTART
	move.l	(_resload,pc),a2
	jsr	(resload_DiskLoad,a2)

.E
	MOVEM.L	(A7)+,D0-A6
;	MOVEQ.L	#0,D0
	RTS




;	CMP.B	_keyexit(pc),$1AA7
;	BEQ.S	_QUIT



;version	dc.w	0	;version of disks
_resload	dc.l	0	;address of resident loader
;HINAME	DC.B	'gianahigh',0
;TRUSED	DC.B	0
	EVEN


; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f
;	NUM *	$5D

	IFEQ	1
KEYHP	
	MOVEM.L	D0/D1/A0,-(A7)
	BTST	#3,$BFED01
	BEQ.S	.SKIP
	MOVE.B	$BFEC01,D0
	NOT.B	D0
	ROR.B	#1,D0
	BSET	#6,$BFEE01
	MOVEQ.L	#$50,D1
	BSR	PATCHTIME
	BCLR	#6,$BFEE01
	CMP.B	#$5D,D0
.QKEY	EQU	*-1
	BEQ.S	QUIT
	CMP.B	#$5B,D0
.TKEY	EQU	*-1
	BNE.S	.SKIP
	EOR.W	#(~$8101&$4E71)!($8101&~$4E71),$6384.W	;SUBTRACT ONE LIFE
	LEA.L	TRUSED(PC),A0
	ST	(A0)

.SKIP	MOVEM.L	(A7)+,D0/D1/A0
;.1	MOVEQ.L	#$50,D6			;ORIG. INSTRUCTION
	MOVE.W	#$8,$DFF09C
	RTE

	ENDC

_QUIT	pea	TDREASON_OK
;	bra	_end
;BADVER	pea	TDREASON_BADVERSION
_end	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


