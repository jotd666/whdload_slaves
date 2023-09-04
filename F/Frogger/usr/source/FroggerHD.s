;*---------------------------------------------------------------------------
;  :Program.	FernandezMustDieHD.asm
;  :Contents.	Slave for "FernandezMustDie" from
;  :Author.	JOTD
;  :History.	28.01.05
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	FernandezMustDie.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

CHIP_ONLY
	IFD		CHIP_ONLY
CHIPMEMSIZE = $80000
EXPMEMSIZE = $0
	ELSE
CHIPMEMSIZE = $80000
EXPMEMSIZE = $20000
	ENDC
	
CHIP_START = $1000

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	data-_base		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	
	dc.l	EXPMEMSIZE			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
data:
	dc.b	"data",0
	
_config
		dc.b	0

	even
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Frogger"
		dc.b	0
_copy		dc.b	"2023 JoeJoe",0
_info		dc.b	"adapted by JOTD",10,10


		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0



;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use


	IFD		CHIP_ONLY
	lea		$60000,a0
	lea		_expmem(pc),a1
	move.l	a0,(a1)
	ENDC
	move.l	_expmem(pc),a1
	move.l	a1,a0		; dest
	add.l	#$1FFF0,a1
	move.l	a1,a7
	
	move.l	_resload(pc),a2
	moveq	#1,d2
	move.l	#$400,d0
	move.l	#$6800,d1
	jsr		resload_DiskLoad(a2)

	lea		free_chip(pc),a0
	move.l	#CHIP_START,(a0)
	

	lea		pl_main(pc),a0
	move.l	_expmem(pc),a1
	move.l	a1,-(a7)
	jmp		resload_Patch(a2)


pl_main:
	PL_START
	PL_S		0,$46			; skip system startup
	PL_NOP		$004bc-$400,8	; remove forbid
	
	PL_R		$0064c-$400
	
	PL_P		$5336-$400,get_vbr
	
	PL_I		$05274-$400
	PL_I		$05286-$400
	
	PL_P		$005a4-$400,_quit
	PL_P		$051fe-$400,alloc_chip_1
	PL_P		$0522c-$400,alloc_chip_2
	PL_END
	
get_vbr:
	moveq	#0,d0
	rts
	
alloc_chip_1:
	move.l	a0,-(a7)
	bsr		alloc_chip_2
	move.l	(a7)+,a0
	CMPA.L	#$0000,A0		;0521a: b0fc0000
	BEQ.S	LAB_03AC		;0521e: 670a
	MOVEA.L	(A1),A1			;05220: 2251
	SUBQ.W	#1,D1			;05222: 5341
LAB_03AB:
	MOVE.B	(A0)+,(A1)+		;05224: 12d8
	DBF	D1,LAB_03AB		;05226: 51c9fffc
LAB_03AC:
	RTS				;0522a: 4e75
	
alloc_chip_2:
	lea		free_chip(pc),a0
	move.l	(a0),(a1)
	; for next time
	add.l	d1,(a0)
	rts
	
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
buttonwait	dc.l	0
		dc.l	0

free_chip:
	dc.l	0
;--------------------------------

_resload	dc.l	0		;address of resident loader



