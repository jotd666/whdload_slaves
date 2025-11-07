; Resourced by whdslave_resourcer v0.92
; a program written by JOTD in 2016-2019
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	IFD BARFLY
	OUTPUT	"Roguecraft.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC
	
FASTMEMSIZE = $1f0000

_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	17					; ws_version (was 17)
	dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoDivZero|WHDLF_ClearMem
	dc.l	$e0000					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	$0					; ws_keydebug
_keyexit
	dc.b	$59					; ws_keyexit
_expmem
	dc.l	FASTMEMSIZE					; ws_expmem
	dc.w	_name-_base				; ws_name
	dc.w	_copy-_base				; ws_copy
	dc.w	_info-_base				; ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
;---
_config
	dc.b    "C1:X:Infinite energy:0;"
	dc.b    "C1:X:Max energy at start:1;"
	dc.b    "C1:X:Max strength at start:2;"
	dc.b	0
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.0"
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
_name	dc.b	'Roguecraft (v1.5)',0
_copy	dc.b	'2025 Badger Punch Games',0
_info
	dc.b	'modded & trained by JOTD',10,10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	
_kickname   dc.b    0
;--- version id
    dc.b	0
    even

CIAA_SDR	EQU	$BFEC01


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	
program_name:
	DC.B	'roguecraft.exe',0
	even
start:
	LEA	_resload(PC),A1	;076: 43fa012c
	MOVE.L	A0,(A1)			;07a: 2288
	MOVEA.L	A0,A2			;07c: 2448
	MOVEA.L	_expmem(PC),A0		;07e: 207affa0
	move.l	A0,$C0
	; set user & supervisor stack pointers to fastmem
	ADDA.L	#FASTMEMSIZE-$200,A0		;082: d1fc001efe00
	MOVEA.L	A0,A7			;088: 2e48
	LEA	-1024(A0),A0		;08a: 41e8fc00
	MOVE.L	A0,USP			;08e: 4e60
	LEA	tags(PC),A0		;090: 41fa00f6
	JSR	resload_Control(A2)	;94 (offset=34)
	; disabled set CACR, makes no sense
	;MOVEQ	#1,D0			;098: 7001
	;MOVE.L	D0,D1			;09a: 2200
	;MOVEA.L	_resload(PC),A2	;09c: 247a0106
	;JSR	resload_SetCACR(A2)	;a0 (offset=10)
	; standard SetCPU values
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	JSR	resload_SetCPU(A2)	;ac (offset=60)
	LEA	program_name(PC),A0	;0b0: 41faffb5
	MOVEA.L	_expmem(PC),A1		;0b4: 227aff6a
	MOVEA.L	_resload(PC),A2	;0b8: 247a00ea
	JSR	resload_LoadFileDecrunch(A2)	;bc (offset=8)
	MOVEA.L	_expmem(PC),A0		;0c0: 207aff5e
	CLR.L	-(A7)			;0c4: 42a7
	MOVE.L	#$00000400,-(A7)	;0c6: 2f3c00000400
	PEA	$88100000		;0cc: 487988100000
	PEA	8.W			;0d2: 48780008
	PEA	$88100002		;0d6: 487988100002
	MOVEA.L	A7,A1			;0dc: 224f
	MOVEA.L	_resload(PC),A2	;0de: 247a00c4
	JSR	resload_Relocate(A2)	;e2 (offset=50)
	LEA	20(A7),A7		;0e6: 4fef0014
	MOVEA.L	_expmem(PC),A0		;0ea: 207aff34
	LEA	4(A0),A1		;0ee: 43e80004
	MOVEA.L	(A1)+,A2		;0f2: 2459
	; install vectors
	MOVE.W	#$4eb9,(A2)+		;0f4: 34fc4eb9
	PEA	keyboard_hook(PC)		;0f8: 487a005e
	MOVE.L	(A7)+,(A2)		;0fc: 249f
	MOVEA.L	(A1)+,A2		;0fe: 2459
	MOVE.W	#$4eb9,(A2)+		;100: 34fc4eb9
	PEA	keyboard_hook(PC)		;104: 487a0052
	MOVE.L	(A7)+,(A2)		;108: 249f
	MOVEA.L	(A1)+,A2		;10a: 2459
	MOVE.W	#$4ef9,(A2)+		;10c: 34fc4ef9
	PEA	load_file(PC)		;110: 487a001c
	MOVE.L	(A7)+,(A2)		;114: 249f
	MOVEA.L	(A1)+,A2		;116: 2459
	MOVE.W	#$4ef9,(A2)+		;118: 34fc4ef9
	PEA	save_file(PC)		;11c: 487a0022
	MOVE.L	(A7)+,(A2)		;120: 249f


	MOVEA.L	_resload(PC),A2	;0de: 247a00c4
	move.l	_expmem(pc),a1
	lea		pl_main(pc),a0
	jsr	resload_Patch(a2)
	
	; tell the exe that whdload is in charge!
	MOVEA.L	_expmem(PC),A0		;122: 207afefc
	MOVE.L	#$44454144,D0		;126: 203c44454144
	JMP	(A0)			;12c: 4ed0

pl_main:
	PL_START

	PL_IFC1X	0
	PL_NOP	$0042de,6
	PL_ENDIF
	PL_IFC1X	1
	PL_B	$001544+3,8
	PL_B	$00154c+3,8
	PL_B	$00159a+3,8
	PL_B	$0015a2+3,8
	PL_B	$0015f0+3,8
	PL_B	$0015f8+3,8
	PL_ENDIF
	PL_IFC1X	2
	PL_B	$001554+3,8
	PL_B	$0015aa+3,8
	PL_B	$001600+3,8
	PL_ENDIF
	PL_END
	
load_file:
	MOVEM.L	D1-D3/A0-A3,-(A7)	;12e: 48e770f0
	MOVEA.L	_resload(PC),A2	;132: 247a0070
	JSR	resload_LoadFile(A2)	;136 (offset=8)
	MOVEM.L	(A7)+,D1-D3/A0-A3	;13a: 4cdf0f0e
	RTS				;13e: 4e75

save_file:
	MOVEM.L	A0-A2,-(A7)		;140: 48e700e0
	move.l	trainer(pc),d0
	bne		.skip
	MOVE.L	D1,D0			;144: 2001
	MOVEA.L	_resload(PC),A2	;146: 247a005c
	JSR	resload_SaveFile(A2)	;14a (offset=c)
.skip:
	MOVEM.L	(A7)+,A0-A2		;14e: 4cdf0700
	MOVEQ	#0,D0			;152: 7000
	RTS				;154: 4e75

	RTS				;156: 4e75

keyboard_hook:
	MOVE.B	CIAA_SDR,D0		;158: 103900bfec01
	NOT.B	D0			;15e: 4600
	ROR.B	#1,D0			;160: e218
	CMP.B	_keyexit(PC),D0	;162: b03afebb
	BEQ.S	exit_normally		;166: 670e
	CMP.B	_keydebug(PC),D0		;168: b03afeb4
	BEQ.S	exit_debug		;16c: 6702
	RTS				;16e: 4e75

exit_debug:
	PEA	5.W			;170: 48780005
	BRA.S	LAB_0009		;174: 600a
exit_normally:
	PEA	-1.W			;176: 4878ffff
LAB_0009:
	MOVE.L	_resload(PC),-(A7)	;180: 2f3a0022
	ADDQ.L	#4,(A7)			;184: 5897
	RTS				;186: 4e75

tags:
	dc.l	WHDLTAG_BUTTONWAIT_GET
	dc.l	0
trainer:
	dc.l	WHDLTAG_CUSTOM1_GET
	dc.l	0			;194: 00000000
	dc.l	WHDLTAG_MONITOR_GET
	dc.l	0
	dc.l	0
_resload:
	dc.l	0			;1a2: 00000000

