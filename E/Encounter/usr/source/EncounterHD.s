;*---------------------------------------------------------------------------
;  :Program.	encounterslave.asm
;  :Contents.	Slave for "Encounter"
;  :Author.	Harry
;  :History.	11.01.98/11.05.98 highscore
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25
;  :To Do.
;---------------------------------------------------------------------------*

;crc_v1	= $57C1
;crc_v2	= $F885	;NTSC



	INCDIR	include:
	INCLUDE	whdload.i

	IFD BARFLY
	OUTPUT	Encounter.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;======================================================================

_base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap|WHDLF_EmulDivZero	;ws_flags
		dc.l	$80000		;ws_BaseMemSize			;$bc000
		dc.l	$00		;ws_ExecInstall
		dc.w	SLStart-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
 		dc.b	$00		;debugkey
_keyexit		dc.b	$5D		;quitkey
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Encounter"
		dc.b	0
_copy		dc.b	"1991 Novagen",0
_info		dc.b	"adapted & fixed by Harry & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

;======================================================================
SLStart	;	A0 = resident loader
;======================================================================

	lea	(_resload,pc),a1
	move.l	a0,(a1)			;save for later using

	move.l	_resload(pc),a2

	move.l	#CACRF_EnableI,d0	;enable instruction cache
	move.l	d0,d1			;mask
	jsr	(resload_SetCACR,a2)

	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

;;	BSET	#1,$BFE001

	MOVE.L	#$8C00,D0
	MOVE.L	#$400,D1
	LEA	$400.W,A0
	MOVEQ	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)

	MOVEQ.L	#0,D0
	MOVE.L	#$7E00,D1
	LEA	$68000,A0
	MOVEQ.L	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)


	JSR	$4BC.W

	bsr	_flushcache
	move.l	_buttonwait(pc),d0
	beq.b	.sk
.WAIT	BTST	#7,$BFE001
	BEQ.S	.sk
	BTST	#6,$BFE001
	BNE.S	.WAIT

.sk
	MOVE.L	#$9000,D0
	MOVE.L	#$6B000-$1AD0,D1
	LEA	$1AD0,A0
	MOVEQ.L	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)


	MOVE.W	#$3491,D0
	LEA	$00006000,A0
	LEA	$00013000,A1
.DEC	MOVE.W	D0,D1
	ASL.W	#3,D1
	EOR.W	D0,D1
	ROXL.W	#1,D1
	ROXL.W	#1,D0
	EORI.W	#$AAAA,D0
	EOR.W	D0,(A0)+
	CMPA.L	A0,A1
	BNE.B	.DEC

	lea	(HIGHNAME,PC),a0	;filename
	move.l	(_resload,PC),a3
	jsr	(resload_GetFileSize,a3)
	tst.l	d0
	beq.s	.SK1
	MOVE.L	#$91E2,A1	;ADDY
	MOVE.L	#$90,D0		;LEN
	lea	(HIGHNAME,PC),a0	;filename
	jsr	(resload_LoadFile,a3)

.SK1
	PEA	INT3(PC)
	MOVE.L	(A7)+,$6C.W

	MOVE.W	#$4EB9,$94C6
	PEA	SAVEHIGH(PC)
	MOVE.L	(A7)+,$94C8

	MOVE.W	#$4eb9,$c4d2
	pea	keyhp(PC)
	MOVE.L	(A7)+,$c4d4

	MOVE.W	#$8390,$DFF096
;	MOVE.W	#$E02C,$DFF09A
	MOVE.W	#$8000+$3500,$DFF09E

;	MOVE.W	#$4ef9,$d7f6
;	pea	quit(PC)
;	MOVE.L	(A7)+,$d7f8




	ifeq	1
	LEA.L	$69666,A0
	LEA.L	$6B000,A1
.CLR	CLR.W	(A0)+
	CMP.L	A0,A1
	BNE.S	.CLR




	MOVE.L	#$91C84E73,$69A8A

	LEA.L	$69A9C,A0
	LEA.L	$69AE6,A1
.MV	MOVE.W	#$1A1A,(A0)+
	CMP.L	A0,A1
	BNE.S	.MV

	MOVEQ.L	#0,D0
	MOVEQ.L	#0,D1
	MOVEQ.L	#0,D2
	MOVEQ.L	#0,D3
	MOVEQ.L	#0,D4
	MOVEQ.L	#0,D5
	MOVEQ.L	#0,D6
	MOVEQ.L	#0,D7
	SUB.L	A0,A0	
	SUB.L	A1,A1	
	SUB.L	A2,A2	
	SUB.L	A3,A3	
	SUB.L	A4,A4	
	SUB.L	A5,A5	
	SUB.L	A6,A6	

;	BRA.W	DEBUG
	endc

	bsr	_flushcache

	JMP	$D7E2

INT3	MOVE.W	#$380,$DFF09C
	RTE

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

SAVEHIGH
	CLR.B	$939B
	MOVEM.L	D0-A2,-(A7)
	LEA.L	$91E2,A1		;ADDY
	move.l	#$90,D0			;len
	lea	HIGHNAME(PC),a0		;filename
	move.l	(_resload,pc),a2
	jsr	(resload_SaveFile,a2)
	MOVEM.L	(A7)+,D0-A2
	RTS


DBFD1
	AND.L	#$FFFF,D1
	DIVU	#$28,D1
.4	MOVE.L	D1,-(A7)
	MOVE.B	$DFF006,D1
.3	CMP.B	$DFF006,D1
	BEQ.S	.3
	MOVE.L	(A7)+,D1
	DBF	D1,.4
	RTS

;version	dc.w	0	;version of disks
_resload	dc.l	0	;address of resident loader
HIGHNAME	DC.B	'ENHIGH',0
	EVEN

; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f
;	NUM *	$5D

keyhp	
	MOVEQ.L	#$50,D1
	BSR.W	DBFD1

	CMP.B	_keyexit(pc),D0
	BEQ.S	QUIT


	CMP.B	#$5B,D0
	BNE.S	.C

;	MOVE.W	#$8280,$dff096
	MOVE.B	#0,$DFF101
	MOVE.B	#0,$DFF104
	MOVE.W	#0,$DFF106
	MOVE.W	#$11,$DFF10C

.C	RTS

DEBUG	PEA	TDREASON_DEBUG
	BRA.S	_end


QUIT	pea	TDREASON_OK
;	bra	_end
;BADVER	pea	TDREASON_BADVERSION
_end	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
_buttonwait	dc.l	0
		dc.l	0
