;*---------------------------------------------------------------------------
;  :Program.	ChaosEngineDemoHD.asm
;  :Contents.	Slave for "ChaosEngine Demo" from
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
	OUTPUT	ChaosEngineDemo.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

USE_FASTMEM

	IFD	USE_FASTMEM
BASEMEMSIZE = $80000
	ELSE
BASEMEMSIZE = $100000
	ENDC

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulDivZero	;ws_flags
		dc.l	BASEMEMSIZE
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	datadir-_base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	$60000			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
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

_name		dc.b	"Chaos Engine Demo",0
_copy		dc.b	"1993 The Bitmap Brothers",0
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

	lea	BASEMEMSIZE-$100,a7

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2

	;enable cache in fastmem
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	; fastmem or chipmem only
	IFD	USE_FASTMEM
	move.l	_expmem(pc),d0
	add.l	#$1000,d0
	ELSE
	move.l	#$80000,d0	; demo doesn't work on 1MB chip/nofast amigas
	ENDC
	lea	base_address(pc),A1
	move.l	d0,(a1)

	; load boot file

	lea	bootname(pc),a0
	move.l	base_address(pc),A1
	move.l	_resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)

	move.l	base_address(pc),a0
	sub.l	a1,a1                   ;tags
	jsr	(resload_Relocate,a2)

	lea	pl_boot(pc),a0
	move.l	base_address(pc),A1
	jsr	resload_Patch(a2)
		
	move.l	#$3E,d5			; ??
	move.l	base_address(pc),A1
	lea	-$1000(a1),a3	; RNC exe decrunch routine location
	lea	$FC000+$34134,a5	; global vector address?
	move.l	base_address(pc),-(a7)
	rts

pl_boot
	PL_START
	PL_W	$842,$4E71	; remove TRAP
	PL_P	$B60C,read_file
	PL_END

; < A0 filename
; < A1 address

read_file
	movem.l	d2/a0-a2,-(a7)
	tst.l	d0
	beq.b	.load
	; other commands unsupported
	illegal
.load
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)

	move.l	d0,d1	; returns length in d1
	movem.l	(a7)+,d2/a0-a2
	moveq	#0,d0
	rts

	;enable cache in chipmem for game

	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

_flushcache
	move.l	_resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts
	

soundtracker_fix
	moveq	#7,d0
	addq.l	#2,(a7)
	bra	_beamdelay

bootname
	dc.b	"ACHAOS",0
	even

;--------------------------------

_resload	dc.l	0		;address of resident loader
base_address
	dc.l	0

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

