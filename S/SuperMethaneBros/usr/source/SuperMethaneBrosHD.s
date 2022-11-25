; Resourced by whdslave_resourcer
; a program written by JOTD in 2016
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"SuperMethaneBros.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC


_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	17					; ws_version (was 10)
	dc.w	WHDLF_NoError|WHDLF_EmulTrap
	dc.l	$100000					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	$0					; ws_keydebug
_keyexit
	dc.b	$5d					; ws_keyexit
_expmem
	dc.l	$0					; ws_expmem
	dc.w	_name-_base				; ws_name
	dc.w	_copy-_base				; ws_copy
	dc.w	_info-_base				; ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
;---
_config
;	dc.b	"BW;"
; dc.b    "C1:X:Infinite lives:0;"

	dc.b	0
;00090978 43f9 00df f00a           LEA.L $00dff00a,A1
;0009097E 3031 0000                MOVE.W (A1,D0.W,$00) == $00dff40a,D0

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_data   dc.b    0
_name	dc.b	'Super Methane Bros',0
_copy	dc.b	'1993 Apache',0
_info
    dc.b   'Installed by Codetapper/Action!',10,'Version 1.3 (15.07.2001)',10,'Press Help to toggle infinite lives!',10,'Thanks to Carlo Pirri for the original!',0
_kickname   dc.b    0
;--- version id

    dc.b	0
    even

; IRA V2.00 (Nov  2 2010) (c)1993-95 Tim Ruehsen, (c)2009 Frank Wille


EXT_0001	EQU	$1FC
EXT_0002	EQU	$800
EXT_0003	EQU	$7E6A4
EXT_0004	EQU	$80000
EXT_0005	EQU	$80552
EXT_0006	EQU	$82D0A
EXT_0007	EQU	$894A6
CIAA_PRA	EQU	$BFE001
EXT_0009	EQU	$DFF005
COP1LCH		EQU	$DFF080
COLOR00		EQU	$DFF180

start:
	LEA	_resload(PC),A1
	MOVE.L	A0,(A1)
	MOVE.L	#$00002c00,D0
	MOVE.L	#$00001600,D1
	MOVEQ	#1,D2
	LEA	EXT_0002.W,A0
	MOVEA.L	A0,A5
	MOVEA.L	_resload(PC),A2
	JSR	resload_DiskLoad(A2)	;106 (offset=28)
	MOVE.L	#$fffffffe,EXT_0001.W
	MOVE.L	#$000001fc,COP1LCH
	CLR.W	$100.W
	LEA	LAB_0003(PC),A0
	MOVEA.L	A5,A1
	JSR	resload_Patch(A2)	;126 (offset=64)
	JMP	(A5)

LAB_0003:
	PL_START
	PL_P	$ce,LABN_01B4
	PL_P	$de,decrunch
	PL_P	$300,load_disk
	PL_R	$720
	PL_END

pl_main:
	PL_START
	PL_P	$fa,LABN_02D8
	PL_P	$2094,load_disk
	PL_R	$213e
	PL_R	$214c
	PL_R	$2166
	PL_R	$2174
	PL_R	$23bc
	PL_NOP	$7e7d0,4
	PL_R	$7e812
	PL_L	$80082,$1fc
	PL_NOP	$80518,4
	PL_W	$80524,$6000
	PL_PS	$82cc0,LABN_02E2
	PL_L	$82d04,$4eb800fa
	PL_PS	$86bf2,LABN_0270
	PL_P	$ff32e,decrunch

	PL_PSS	$8dcf2,blitter_wait,2
	PL_PSS	$8defc,blitter_wait,2
	PL_PSS	$8e114,blitter_wait,2
	PL_PSS	$8E4B0,blitter_wait,2
	PL_PSS	$8E7B2,blitter_wait,2
	PL_NOP	$80552,30
	PL_END


LABN_01B4:
	MOVEM.L	D0-D1/A0-A2,-(A7)
	LEA	pl_main(PC),A0
	SUBA.L	A1,A1
	MOVEA.L	_resload(PC),A2
	JSR	resload_Patch(A2)	;1c2 (offset=64)
	
	LEA	current_disk(PC),A0
	MOVEQ	#2,D0
	MOVE.L	D0,(A0)
	BSR.W	load_highscores

LAB_0006:
	MOVEM.L	(A7)+,D0-D1/A0-A2
	JMP	EXT_0004

blitter_wait:
	TST.B	CIAA_PRA
	TST.B	CIAA_PRA
LAB_0008:
	BTST	#6,2(A6)
	BNE.S	LAB_0008
	MOVE.L	#$ffff0000,68(A6)
	RTS

load_disk:
	MOVEM.L	D0-D1/A0-A2,-(A7)
	MULU	#$1600,D0
	MOVEQ	#4,D1
	MOVE.L	current_disk(PC),D2
	MOVEA.L	_resload(PC),A2
	MOVEM.L	D0/A0,-(A7)
	JSR	resload_DiskLoad(A2)	;248 (offset=28)
	MOVEM.L	(A7)+,D0/A0
	ADDQ.L	#4,D0
	MOVE.L	(A0),D1
	JSR	resload_DiskLoad(A2)	;254 (offset=28)
	MOVEM.L	(A7)+,D0-D1/A0-A2
	RTS

decrunch:
	MOVEM.L	D0-D1/A0-A2,-(A7)
	MOVEA.L	_resload(PC),A2
	JSR	resload_Decrunch(A2)	;266 (offset=18)
	MOVEM.L	(A7)+,D0-D1/A0-A2
	RTS

LABN_0270:
	CMP.B	_keyexit(PC),D0
	BEQ.W	_quit
	; help: toggle cheat
	CMPI.B	#$5f,D0
	BNE.S	LAB_000D
	EORI.L	#$1d194e15,EXT_0007
	MOVE.L	A0,-(A7)
	LEA	cheat_enabled(PC),A0
	MOVE.B	#$ff,(A0)
	MOVEA.L	(A7)+,A0
LAB_0009:
	BTST	#0,EXT_0009
	BEQ.S	LAB_0009
LAB_000A:
	BTST	#0,EXT_0009
	BNE.S	LAB_000A
	MOVE.L	D0,-(A7)
LAB_000B:
	MOVE.W	D0,COLOR00
	SUBQ.W	#1,D0
	BTST	#0,EXT_0009
	BEQ.S	LAB_000B
LAB_000C:
	MOVE.W	D0,COLOR00
	SUBQ.W	#1,D0
	BTST	#0,EXT_0009
	BNE.S	LAB_000C
	MOVE.L	(A7)+,D0
LAB_000D:
	MOVE.B	D0,D1
	ANDI.W	#$007f,D0
	RTS

LABN_02D8:
	JSR	EXT_0006
	JMP	save_highscores(PC)

LABN_02E2:
	MOVE.W	#$0001,-118(A5)
	JMP	save_highscores(PC)

load_highscores:
	MOVEM.L	D0-D1/A0-A3,-(A7)
	LEA	EXT_0003,A1
	MOVEA.L	A1,A3
	LEA	hiscore_file(PC),A0
	MOVEA.L	_resload(PC),A2
	JSR	resload_GetFileSize(A2)	;300 (offset=24)
	TST.L	D0
	BEQ.S	LAB_000F
	LEA	hiscore_file(PC),A0
	MOVEA.L	A3,A1
	MOVE.L	A1,-(A7)
	JSR	resload_LoadFile(A2)	;310 (offset=8)
	MOVEA.L	(A7)+,A1
	BSR.S	crypt_highscores
LAB_000F:
	MOVEM.L	(A7)+,D0-D1/A0-A3
	RTS

save_highscores:
	MOVEM.L	D0-D1/A0-A2,-(A7)
	MOVE.B	cheat_enabled(PC),D0
	BNE.S	LAB_0011
	LEA	hiscore_file(PC),A0
	LEA	EXT_0003,A1
	MOVEA.L	_resload(PC),A2
	BSR.S	crypt_highscores
	MOVE.L	A1,-(A7)
	JSR	resload_SaveFile(A2)	;33a (offset=c)
	MOVEA.L	(A7)+,A1
	BSR.S	crypt_highscores
LAB_0011:
	MOVEM.L	(A7)+,D0-D1/A0-A2
	RTS

; encrypt/decrypt
crypt_highscores:
	MOVEQ	#64,D0
	MOVE.L	D0,-(A7)
LAB_0013:
	EOR.B	D0,(A1)+
	SUBQ.L	#1,D0
	BNE.S	LAB_0013
	MOVE.L	(A7)+,D0
	SUBA.L	D0,A1
	RTS

_resload:
	dc.l	0
current_disk:
	dc.l	1

_quit:
	PEA	TDREASON_OK
	MOVE.L	_resload(PC),-(A7)
	ADDQ.L	#4,(A7)
	RTS

hiscore_file:
	DC.B	'SuperMethaneBros.highs',0
cheat_enabled:
	dc.b	$00	;e6

