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
CHIPMEMSIZE = $100000
EXPMEMSIZE = $0
	ELSE
CHIPMEMSIZE = $100000
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

_name		dc.b	"Fatal Noise"
		dc.b	0
_copy		dc.b	"1996 ???",0
_info		dc.b	"adapted by JOTD",10,10


		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

BOOT_ADDRESS = $10000

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	lea		BOOT_ADDRESS,a0
	moveq	#0,d0
	move.l	#$5800+$2c00,d1
	move.l	#1,d2
	move.l	_resload(pc),a2
	jsr		resload_DiskLoad(a2)
	
	lea		BOOT_ADDRESS,a1
	lea		pl_boot(pc),a0
	jsr		resload_Patch(a2)
	
	jmp		BOOT_ADDRESS+$32
	
patch_loader
	blitz
	
pl_boot:
	PL_START
	PL_S	$5C,$DC-$5C
	PL_P	$e4,patch_loader
	PL_END
	
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

;--------------------------------

_resload	dc.l	0		;address of resident loader



