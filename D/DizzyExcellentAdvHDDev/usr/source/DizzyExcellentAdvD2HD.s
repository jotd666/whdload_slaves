;*---------------------------------------------------------------------------
;  :Program.	CastlevaniaHD.asm
;  :Contents.	Slave for "Dizzy Excellent Adventure" from 
;  :Author.	JOTD
;  :Original	v1 jotd@wanadoo.fr
;  :Version.	$Id: battleisle.asm 0.5 2000/11/26 21:13:41 jah Exp $
;  :History.	23.05.01 started
;		23.05.01 finished
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"DizzyExcellentAdvD2.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	11			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap		;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_data		dc.b	"disk2",0
_name		dc.b	"Dizzy Excellent Adventure (disk 2)",0
_copy		dc.b	"1992 Codemasters",0
_info		dc.b	"Installed by Abaddon",10,10
		dc.b	"WHDLoad conversion by JOTD",10,10
		dc.b	"Thanks to ? for original diskimage",10,10
		dc.b	"Version 1.1 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
	even

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	lea	_resload(pc),a2
	move.l	a0,(a2)
	move.l	a0,a2	;a2 = resload

;	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
;	move.l	#WCPUF_All,d1
;	jsr	(resload_SetCPU,a2)
		
	;get tags
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)
		

	lea	loader_name(pc),a0
	lea	$1ffe0,a1
	jsr	(resload_LoadFileDecrunch,a2)

	lea	pl_boot(pc),a0
	sub.l	a1,a1
	jsr	(resload_Patch,a2)	

	move	#$2104,SR
	jmp	$20004

pl_boot
	PL_START
	PL_P	$20054,patch_boot
	PL_END

patch_boot
.copyloop
	move.b	(a0)+,(a1)+
	dbf		d0,.copyloop

	sub.l	a1,a1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$404.W
	
pl_main
	PL_START
	PL_R	$550					;protection patch
	PL_PS	$1196,loadspell
	PL_PS	$111a,loadpanic
	PL_P	$11b0,spellboundjmp
	PL_P	$1134,panicjmp
	PL_PS	$ee6,KbMain
	PL_R	$1366				;more protection shit
	PL_END

	;quit
quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)



loadspell:
	lea		$1000.w,a1
	bsr		loadf
	rts

loadpanic:
	lea		$3e0,a1
	bsr		loadf
	rts


loadf:
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	(resload_LoadFileDecrunch,a2)
	bsr	_flushcache
	movem.l	(a7)+,d0-d1/a0-a2
	rts

loadfiles_spellbound
	bsr	loadf
	jmp	$2D8C0

spellboundjmp:
	movem.l	$74040,d0-d7/a0-a6
	move.l	#$2d966,$84
	move.w	#$4e75,$2d8e4
	patchs	$2d09e,KbMain
	patch	$2d8aa,loadfiles_spellbound
	bsr	_flushcache
	jmp	$1000.w

panicjmp:
	movem.l $740ae,d0-d7/a0-a6
	patchs	$66c,KbMagic
;	move.l	_custom1(pc),d1
;	beq		skip
;skip:
	bsr	_flushcache
	jmp		$404.w

KbMain:
	move.w	d0,$2d06e
	movem.l D0-A6,-(A7)
	bra		KbInt
KbMagic:
	movem.l D0-A6,-(A7)
	not.b	d0
	ror.b	#$1,d0
	bra		KbInt
KbInt:
	cmp.b	_keyexit(pc),d0				; f10
	beq		quit
	movem.l (A7)+,D0-A6
	rts


_flushcache
	move.l	A2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

_emulate_dbf:
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts

_ackkb:
	bset	#6,$BFEE01
	move.w  d0,-(a7)
	move.w	#2,D0
	bsr	_beamdelay

	move.w	(a7)+,d0
	bclr	#6,$BFEE01

	rts

_beamdelay:
	tst.w	D0
	beq.b	.exit
.loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS

.loop2
	cmp.b	$dff006,d0
	beq.s	.loop2
	move.w	(a7)+,d0
	dbf	d0,.loop1

.exit
	rts	

;---------------

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

_resload
	dc.l	0

loader_name
	dc.b	"VC",0
	even

;============================================================================

	END
