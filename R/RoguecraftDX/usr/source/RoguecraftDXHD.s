; Resourced by whdslave_resourcer v0.92
; a program written by JOTD in 2016-2019
;
; IRA V2.10 (Jun  1 2022) (c)1993-1995 Tim Ruehsen
; (c)2009-2015 Frank Wille, (c)2014-2019 Nicolas Bastien

EXPMEM_SIZE = $2f0000

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	IFD BARFLY
	OUTPUT	"RoguecraftDX.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC
_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	17					; ws_version (was 17)
	dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoDivZero|WHDLF_ClearMem
	dc.l	$1f0000					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	$0					; ws_keydebug
_keyexit
	dc.b	$59					; ws_keyexit
_expmem
	dc.l	EXPMEM_SIZE					; ws_expmem
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
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.1"
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
_name	dc.b	'Roguecraft DX',0
_copy	dc.b	'2026 Badger Punch Games',0
_info
	dc.b	"trainer by Arise from decay",10
    dc.b	"Version "
	DECL_VERSION
_kickname   dc.b    0
;--- version id
    dc.b	0
    even

CIAA_SDR	EQU	$BFEC01
progname:
	DC.B	'RoguecraftDX.exe',0
	dc.b	$00	;7b
start:
	LEA	_resload(PC),A1	;07c: 43fa0124
	MOVE.L	A0,(A1)			;080: 2288
	MOVEA.L	A0,A2			;082: 2448
	MOVEA.L	_expmem(PC),A0		;084: 207aff9a
	ADDA.L	#EXPMEM_SIZE-$200,A0		;088: d1fc002efe00
	MOVEA.L	A0,A7			;08e: 2e48
	LEA	-1024(A0),A0		;090: 41e8fc00
	MOVE.L	A0,USP			;094: 4e60  setting USP is probably useless as game remains in supervisor
	; reading the tags is useless, nothing is done with it!
	;LEA	tags(PC),A0		;096: 41fa00ee
	;JSR	resload_Control(A2)	;9a (offset=34)

	; standard SetCPU values (they learned from my feedback on their first slave as they used
	; those exact values here :))
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	JSR	resload_SetCPU(A2)


	LEA	progname(PC),A0		;0ae: 41faffba
	MOVEA.L	_expmem(PC),A1		;0b2: 227aff6c
	MOVEA.L	_resload(PC),A2	;0b6: 247a00ea
	JSR	resload_LoadFile(A2)	;ba (offset=8)
	MOVEA.L	_expmem(PC),A0		;0be: 207aff60
	CLR.L	-(A7)			;0c2: 42a7
	MOVE.L	#$00000400,-(A7)	;0c4: 2f3c00000400
	PEA	$88100000		;0ca: 487988100000
	PEA	8.W			;0d0: 48780008
	PEA	$88100002		;0d4: 487988100002
	MOVEA.L	A7,A1			;0da: 224f
	MOVEA.L	_resload(PC),A2	;0dc: 247a00c4
	JSR	resload_Relocate(A2)	;e0 (offset=50)
	LEA	20(A7),A7		;0e4: 4fef0014
	MOVEA.L	_expmem(PC),A0		;0e8: 207aff36
	LEA	4(A0),A1		;0ec: 43e80004
	MOVEA.L	(A1)+,A2		;0f0: 2459
	MOVE.W	#$4eb9,(A2)+		;0f2: 34fc4eb9
	PEA	keyboard_hook(PC)		;0f6: 487a005e
	MOVE.L	(A7)+,(A2)		;0fa: 249f
	MOVEA.L	(A1)+,A2		;0fc: 2459
	MOVE.W	#$4eb9,(A2)+		;0fe: 34fc4eb9
	PEA	keyboard_hook(PC)		;102: 487a0052
	MOVE.L	(A7)+,(A2)		;106: 249f
	MOVEA.L	(A1)+,A2		;108: 2459
	MOVE.W	#$4ef9,(A2)+		;10a: 34fc4ef9
	PEA	load(PC)		;10e: 487a001c
	MOVE.L	(A7)+,(A2)		;112: 249f
	MOVEA.L	(A1)+,A2		;114: 2459
	MOVE.W	#$4ef9,(A2)+		;116: 34fc4ef9
	PEA	save(PC)		;11a: 487a0022
	MOVE.L	(A7)+,(A2)		;11e: 249f
	MOVEA.L	_expmem(PC),A0		;120: 207afefe
	MOVE.L	#$44454144,D0		;124: 203c44454144 "CDAC"
	bsr.b		_flushcache		; added cache flush for good measure!
	JMP	(A0)			;12a: 4ed0


_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
	
load:
	MOVEM.L	D1-D3/A0-A3,-(A7)	;12c: 48e770f0
	MOVEA.L	_resload(PC),A2	;130: 247a0070
	JSR	resload_LoadFile(A2)	;134 (offset=8)
	MOVEM.L	(A7)+,D1-D3/A0-A3	;138: 4cdf0f0e
	RTS				;13c: 4e75

save:
	MOVEM.L	A0-A2,-(A7)		;13e: 48e700e0
	MOVE.L	D1,D0			;142: 2001
	MOVEA.L	_resload(PC),A2	;144: 247a005c
	JSR	resload_SaveFile(A2)	;148 (offset=c)
	MOVEM.L	(A7)+,A0-A2		;14c: 4cdf0700
	MOVEQ	#0,D0			;150: 7000
	RTS				;152: 4e75

	RTS				;154: 4e75

keyboard_hook:
	MOVE.B	CIAA_SDR,D0		;156: 103900bfec01
	NOT.B	D0			;15c: 4600
	ROR.B	#1,D0			;15e: e218
	CMP.B	_keyexit(PC),D0	;160: b03afebd
	BEQ.S	quit		;164: 670e
	CMP.B	_keydebug(PC),D0		;166: b03afeb6
	BEQ.S	debug		;16a: 6702
	RTS				;16c: 4e75

debug:
	PEA	5.W			;16e: 48780005
	BRA.S	exit		;172: 600a
quit:
	PEA	-1.W			;174: 4878ffff
	BRA.S	exit		;178: 6004
	PEA	9.W			;17a: 48780009
exit:
	MOVE.L	_resload(PC),-(A7)	;17e: 2f3a0022
	ADDQ.L	#4,(A7)			;182: 5897
	RTS				;184: 4e75

;tags:
;	dc.l	WHDLTAG_CUSTOM1_GET
;	dc.l	0
;	dc.l	WHDLTAG_CUSTOM2_GET
;	dc.l	0
;	dc.l	WHDLTAG_MONITOR_GET
;	dc.l	0
;	dc.l	0			;19c: 00000000
_resload:
	dc.l	0			;1a2: 00000000


