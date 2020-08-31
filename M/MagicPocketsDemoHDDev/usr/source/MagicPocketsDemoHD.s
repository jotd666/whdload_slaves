;*---------------------------------------------------------------------------
;  :Program.	GodsDemoHD.asm
;  :Contents.	Slave for "Gods Demo" from
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
	OUTPUT	MagicPocketsDemo.slave
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
		dc.l	$100000
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

_name		dc.b	"Magic Pockets Demo",0
_copy		dc.b	"1992 The Bitmap Brothers",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
	dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	$A,$D,0

BASE_ADDRESS = $10000

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2

	lea	$FFF00,a7
	move.l	#$FFFFFFFE,(a7)
	move.l	a7,$dff080		; install default copperlist

	MOVEQ	#56,D0			;00016: 7038
	MOVE.L	D0,$0.W

	LEA	$DFF000,A3
	MOVE	#$2700,SR
	LEA	$120(A3),A0
	; clear sprites
	moveq	#0,d0
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	

	MOVE	#$7FFF,154(A3)		;02C: 377C7FFF009A
	MOVE	#$7FFF,156(A3)		;032: 377C7FFF009C
	MOVE	#$7DEF,150(A3)		;038: 377C7DEF0096
	MOVE	#$8250,150(A3)		;03E: 377C82500096

	; load boot file

	lea	bootname(pc),a0
	lea	$769F0-$37A10,A1
	move.l	#237968,D0	; size
	move.l	#$0,D1		; offset
	move.l	_resload(pc),a2
	jsr	resload_LoadFileOffset(a2)

	lea	$76A1C,a0
	bsr	relocate_decrunch
	bsr	_flushcache


	lea	$900.W,A7
	MOVEA.L	#$0003F0A2,A3
	MOVE.L	(A3)+,D0
	MOVE.L	A7,A1
	MOVEA.L	A3,A4
	MOVE.L	A1,$76FFC
	MOVE.L	D0,$77000
	bsr	decrunch

	movem.l	d0-d1/a0-a2,-(a7)
	;enable cache in chipmem
	move.l	#WCPUF_Base_WT|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	move.l	_resload(pc),a2
	jsr	(resload_SetCPU,a2)
	movem.l	(a7)+,d0-d1/a0-a2

	jmp	$900.W

; < A0 decrunch source

relocate_decrunch:
	lea	decrunch(pc),a1
	move.l	#$17C,d0
.copy
	move.l	(a0)+,(a1)+
	dbf	d0,.copy

	lea	decrunch(pc),a1
	move.w	#$6004,$52(a1)
	move.w	#$6004,$B4(a1)

	rts

_flushcache
	move.l	_resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts
	

bootname
	dc.b	"pockets",0
	even


;--------------------------------

_resload	dc.l	0		;address of resident loader

decrunch
	blk.l	$180,0
