;*---------------------------------------------------------------------------
;  :Program.	wotdslave.asm
;  :Contents.	Slave for "Wrath of the Demon"
;  :Author.	Harry
;  :History.	10.01.98/5.2.98
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25
;  :To Do.
;---------------------------------------------------------------------------*

;crc_v1	= $57C1
;crc_v2	= $F885	;NTSC

;$7E418	DISK-# REQUESTED (D0)
;7EEB4	RTS

	INCDIR	asm-one:Include2.0/
	INCLUDE	own/whdload.i
;	INCLUDE	own/CCRMAKRO

;	OUTPUT	wart:gods/gods.slave
;	BOPT	O+ OG+			;enable optimizing
;	BOPT	w4-			;disable 64k warnings

;======================================================================

.base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	4		;ws_Version
		dc.w	WHDLF_Disk!WHDLF_NoError!WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize			;$bc000
		dc.l	$00		;ws_ExecInstall
		dc.w	SLStart-.base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
 		dc.b	$00		;debugkey
qkey		dc.b	$5D		;quitkey

;======================================================================

;	DOSCMD	"WDate >T:date"
		dc.b	"$VER:Wrath_of_the_Demon_1.01"
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
	MOVE.B	qkey(PC),d0
	LEA.L	keyhp\.qkey(PC),a0
	MOVE.B	d0,(A0)
	SUBQ.B	#2,D0
	LEA.L	KEYHP\.TKEY(PC),A0
	MOVE.B	D0,(A0)
;	BSET	#1,$BFE001

	LEA.L	$7C000,A7

	MOVEQ	#0,D0
	MOVE.L	#$80000-$7D00A,D1
	LEA	$7D00A,A0
	MOVEQ	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)

;	LEA.L	$80000,A7

	MOVE.W	#$4EF9,$7E31E
	PEA	LOADROUT(PC)
	MOVE.L	(A7)+,$7E320
	MOVE.W	#$4EF9,$7E418
	PEA	REQUESTDISK(PC)
	MOVE.L	(A7)+,$7E41A

	MOVE.W	#$4E75,$7EEB4
	MOVE.W	#$4E75,$7EE72
	MOVE.W	#$4e75,$7E248

	MOVE.B	#$40,$7D689		;FILELAENGEN KORRIGIEREN
	MOVE.B	#$EC,$7D75F
	MOVE.B	#$B8,$7D7B7
	MOVE.B	#$28,$7Da19

	MOVE.B	#$0,$7D091		;DISKDRIVE EINSCHALTEN -> OR #0


	MOVE.W	#$4EF9,$40.W
	PEA	DECREND(PC)
	MOVE.L	(A7)+,$42.W

	MOVE.L	#$4EF80040,$7E2E4

	MOVE.W	#$4EB9,$7F55C
	PEA	KEYHP(PC)
	MOVE.L	(A7)+,$7F55E

	MOVE.W	#$4E75,$7EED2
	MOVE.W	#$4E71,$7DCEE		;SKIP SCREEN 'INSERT SAVE DISK'

	MOVE.W	#$4EF9,$7DE2E		;LOAD SAVEGAME TO $20000
	PEA	LOADPOS(PC)
	MOVE.L	(A7)+,$7DE30
	
	MOVE.W	#$4E75,$7E6CE

	MOVE.W	#$4EB9,$7DF32
	PEA	SAVEPOS(PC)
	MOVE.L	(A7)+,$7DF34
	MOVE.L	#$60000000+$7E040-$7DF3A,$7DF38
					;7DF32  SAVE, BRA 7E040

	MOVE.W	#$162,$7DEDE

	MOVE.W	#$4EB9,$7D590
	PEA	BUTTONWAIT(PC)
	MOVE.L	(A7)+,$7D592

	JMP	$7D074



DECREND	
	MOVE.L	(A7),A0
	CMP.L	#$80000,A0
	BHS.W	.NOTFOUND
	CMP.L	#$40,A0
	BLS.W	.NOTFOUND

	CMP.L	#$1D840,-$10(A0)	;SPEZIALKRAM AENDERN
	BNE.S	.SK1			;DRACHE, LIFEABZUG
	MOVE.L	$1E720,$1E6E4
	MOVE.L	$1E6E0,$1E6DC

.SK1	CMP.L	#$225EC,-$10(A0)	;HOEHLE, STICK
	BNE.S	.SK2
	MOVE.B	#$60,$207E.W

.SK2	CMP.L	#$20BEC,-$10(A0)	;HOEHLENWAECHTER, BLITTER
	BNE.S	.SK3
	MOVE.B	#$60,$1CED6

.SK3	CMP.L	#$1AB28,-$10(A0)	;SCHLOSS, TUER
	BNE.S	.SK4
	MOVE.B	#$60,$1F80.W
	MOVE.W	#$7400,$AD4A		;ACCESSFAULT
	MOVE.L	#$143A6EAD,$AD4C

.SK4	CMP.L	#$16BB8,-$10(A0)	;SUMPFWESEN, ENDE (NULLENPRUEFUNG)
	BNE.S	.SK0
	MOVE.L	#$4E714E71,$1D4FE

.SK0	CMP.L	#$15F58,-$10(A0)	;GOBLINPART, SPEICHERZERMUELLEN
	BNE.S	.SK5
	MOVE.W	#$6044,$1E8EA

.SK5	CMP.L	#$1A544,-$10(A0)	;WALD, ACCESS FAULT
	BNE.S	.SK
	MOVE.W	#$7400,$846C
	MOVE.L	#$143A5DC4,$846E

.SK
	MOVEM.L	D0/A1/A2,-(A7)	;FÜR TRAINER RTE VON $400-$20000 SUCHEN
	MOVEQ.L	#0,D0
	LEA.L	$20000,A1
	LEA.L	$400.W,A0
.2	CMP.W	#$4E73,(A0)+
	BNE.S	.1
	CMP.W	#1,D0
	BNE.S	.4
	MOVE.L	A0,A2
.4	CMP.W	#2,D0
	BEQ.S	.3

	ADDQ.L	#1,D0

.1	CMP.L	A1,A0
	BNE.S	.2
.END
	MOVEM.L	(A7)+,A1/A2/D0
.NOTFOUND
	MOVE.L	(A7)+,A0
	RTS

.3	LEA.L	-$400(A0),A1	;VON RTE AUS RUECKWAERTS MOVE.W	#$3F4,$XXXX
.5	CMP.L	#$33FC03F4,(A0)	;SUCHEN AUF EINER LAENGE VON MAX. $400 BYTES
	BEQ.S	.HITPOINTS
	SUBQ.L	#2,A0
	CMP.L	A0,A1
	BNE.S	.5
	LEA.L	TRHPADDY(PC),A1
	CLR.L	(A1)
	BRA.S	.6

.HITPOINTS
	LEA.L	TRHPADDY(PC),A1
	MOVE.L	4(A0),(A1)

.6	BRA.S	.END
;	MOVE.L	A2,A0
;	LEA.L	-$100(A0),A1
;	CMP.





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


;D0-TRACK#
;D6-LENGTH
;D7-TRACKOFFSET
;A0-DEST
;d2-disk#

LOADROUT
	MOVEM.L	D0-A6,-(A7)
	MOVEQ.L	#0,D2
	MOVE.B	DISKNR(PC),D2	;DISK#
	CMP.B	#1,D2
	BNE.S	.NOTD1
	SUBQ.W	#1,D0
.NOTD1	MULU	#$1900,D0
	ADD.L	D7,D0
	
	MOVE.L	D6,D1	;LENGTH
;	MOVE.L	A0,A0	;DEST
;	MOVE.L	D0,D0	;DISKSTART
	move.l	(_resload,pc),a3
	jsr	(resload_DiskLoad,a3)
	MOVEM.L	(A7)+,D0-A6
	MOVEQ.L	#0,D0
	RTS


LOADPOS	MOVEM.L	D0-A6,-(A7)
	
	MOVE.L	#$20000,A1		;ADDY
	MOVE.L	#$140,D0		;LEN
	lea	(POSNAME,PC),a0		;filename
	move.l	(_resload,PC),a3
	jsr	(resload_LoadFile,a3)

	MOVEM.L	(A7)+,D0-A6
	MOVEQ.L	#0,D7
	RTS

SAVEPOS	MOVEM.L	D0-A6,-(A7)
	LEA.L	TRUSED(PC),A0
	TST.B	(A0)
	BNE.S	.SK
	
	MOVE.L	#$20000,A1		;ADDY
	MOVE.L	#$140,D0		;LEN
	lea	(POSNAME,PC),a0		;filename
	move.l	(_resload,PC),a3
	jsr	(resload_SaveFile,a3)

.SK	MOVEM.L	(A7)+,D0-A6
	MOVEQ.L	#0,D7
	RTS



REQUESTDISK
	CMP.B	DISKNR(PC),D0
	BEQ.S	.RTS
;.S	BRA.S	.S
.SK	MOVE.L	A0,-(A7)
	nop
	LEA.L	DISKNR(PC),A0
	MOVE.B	D0,(A0)
	MOVE.L	D0,$7F786
	MOVE.L	(A7)+,A0

.RTS	RTS

BUTTONWAIT
.WAIT	BTST	#7,$BFE001
	BEQ.S	.SK
	BTST	#6,$BFE001
	BNE.S	.WAIT

.SK	RTS



;version	dc.w	0	;version of disks
_resload	dc.l	0	;address of resident loader
TRHPADDY	DC.L	0
POSNAME	DC.B	'wotd.save',0
DISKNR	DC.B	1
trused	dc.B	0
	EVEN

; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f
;	NUM *	$5D

KEYHP	

	MOVEQ.L	#$50,D1
	BSR.W	DBFD1

	MOVE.B	$BFEC01,D0
	NOT.B	D0
	ROR.B	#1,D0
	CMP.B	#$5D,D0
.QKEY	EQU	*-1
	BEQ.S	QUIT
	MOVE.L	A0,-(A7)
	CMP.B	#$5B,D0
.TKEY	EQU	*-1
	BNE.S	.SK
	MOVE.L	TRHPADDY(PC),A0
	MOVE.W	#$03F4,(A0)
	LEA.L	TRUSED(PC),A0
	ST	(A0)
.SK
	MOVE.L	(A7)+,A0
	RTS

QUIT	pea	TDREASON_OK
;QUIT	pea	TDREASON_DEBUG
;	bra	_end
;BADVER	pea	TDREASON_BADVERSION
_end	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
