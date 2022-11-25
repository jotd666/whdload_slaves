;*---------------------------------------------------------------------------
;  :Program.	XenonIIDemoHD.asm
;  :Contents.	Slave for "Xenon 2 Demo" from The Bitmap Bros
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
	OUTPUT	XenonIIDemo.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	datadir-_base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	dc.l	0
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

datadir
	dc.b	"data",0
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

_name		dc.b	"Xenon II Demo",0
_copy		dc.b	"1989 The Bitmap Brothers",0
_info		dc.b	"adapted & fixed by JOTD",10,10
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

	move.l	a0,a2

	;enable cache in fastmem
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	; load boot file

	lea	x2bin_name(pc),a0
	lea	$400,a1

	move.l	a1,a7

	move.l	#379232,D0	; size
	jsr	resload_LoadFileDecrunch(a2)

	lea	x2demobin_name(pc),a0
	lea	$7FC00,a1
	move.l	#$400,d0
	jsr	resload_LoadFileDecrunch(a2)

	lea	pl_main(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)

	jmp	$5B58.W

pl_main
	PL_START
	PL_P	$3CBC,jsr_a1_24
	PL_PS	$4B7A,fix_rts_clear
	PL_END

; problem not present in the full game

fix_rts_clear
	move.l	($a,a1),a2
	; don't clear memory where there is a RTS
	cmp.w	#$4E75,(a2)
	beq.b	.skip
	clr.w	(a2)
.skip
	rts

jsr_a1_24
	movem.l	d0/a0,-(a7)
	move.l	a1,d0
	and.l	#$FFFFFF,d0
	move.l	d0,a1
	jsr	(a1)
	movem.l	(a7)+,d0/a0
	rts

x2bin_name
	dc.b	"x2.bin",0
x2demobin_name
	dc.b	"x2demo.bin",0
	even
