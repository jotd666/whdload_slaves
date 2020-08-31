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
	OUTPUT	"DizzyExcellentAdvD1.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

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

_data		dc.b	"disk1",0
_name		dc.b	"Dizzy Excellent Adventure (disk 1)",0
_copy		dc.b	"1992 Codemasters",0
_info		dc.b	"Installed by Abaddon",10,10
		dc.b	"WHDLoad conversion by JOTD",10,10
		dc.b	"Set CUSTOM1=1 for trainer",10,10
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
	move.w	#$4e75,$558.W					;protection patch

	lea	pl_v1(pc),a0

	cmpi.l	#$00040004,$1144.W	; V1
	beq		.patch
	lea	pl_v2(pc),a0
	cmpi.l	#$00040004,$1712.W	; V2
	bne	quit
.patch
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	jmp		$404.W
	
pl_v1
	PL_START
	PL_L	$1822,$17eb0ff4
	PL_P	$119c,yolkjmp
    	PL_P	$1142,bubblejmp
	PL_W	$1112,$601a
	PL_PS	$1202,patkwiksnax1
	PL_PS	$1220,patkwiksnax2
	PL_W	$1226,$4e71
	PL_P	$123e,kwikjmp			;use to patch trainer and quit
	PL_PS	$ef2,KbMain
	PL_R	$129c				;more protection shit
	PL_END

pl_v2
	PL_START
	PL_L	$17BE,$2a915cce
	PL_P	$16d4,yolkjmp
	PL_P	$1710,bubblejmp
	PL_PS	$1126,patkwiksnax1
	PL_PS	$1144,patkwiksnax2
	PL_W	$114a,$4E71
	PL_P	$116c,kwikjmp			;use to patch trainer and quit
	PL_PS	$ef2,KbMain
	PL_R	$132c				;more protection shit
	PL_END

	;quit
quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)



patkwiksnax1:
	lea		$180,a1
	bsr		loadf
	bsr _flushcache
	rts
patkwiksnax2:
	lea		$30ec0,a1
	bsr		loadf
	bsr _flushcache
	rts
loadf:
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	(resload_LoadFileDecrunch,a2)
	bsr	_flushcache
	movem.l	(a7)+,d0-d1/a0-a2
	rts

loadfyolk:
	move.l	a1,-(a7)
	bsr		loadf
	movea.l	(a7)+,a0
	bsr _flushcache
	rts
loadfbub:
	move.l	a1,-(a7)
	bsr		loadf
	movea.l	(a7)+,a0
	clr.l	d0
	bsr _flushcache
	rts
loadfbub2:
	movem.l D0-A6,-(A7)
	bsr	loadf
	movem.l (a7)+,D0-A6
	bsr _flushcache
	rte

loadbubble:
	lea     $66fe0,a1
	bsr		loadf
	bsr _flushcache
	rts

bubblejmp:
  	move.l	#$4e714e71,$41050
	patchs $41058,loadbubble
	move.w  #$4e71,$4105e
	patch $4109c,bubblepatch
	bsr _flushcache
	jmp     $40004

bubblepatch:
	patchs	$67344,KbMagic
	patchs	$6780c,loadfbub
	move.l	#$4e714e71,$67038
	clr.l	$12e
	clr.l	$0

	move.w	#$4e75,$6e0c2			;removes fucking disk check
	move.w	#$4e75,$6e286
	move.w	#$4e75,$6e0a4
	move.w	#$4e75,$6e30e
	move.w	#$4e75,$6e1f4
	move.w	#$6022,$6e2dc

	patch $6e0d8,loadfbub2
	patch $677a0,bubload
	move.w  #$6018,$677a6
	bsr _flushcache
	jmp	$67004

bubload:
	movem.l D0-A6,-(A7)
	bsr		loadf
	movem.l (a7)+,D0-A6
	bsr _flushcache
	rts

yolkjmp:
	patchs	$5c37c,KbMagic

	move.l	#$4e714e71,$5c048			;removes disk check (was an old protection check)
	move.l	#$4e71,$5c04c

	move.l	#$4e714e71,$5c04e			;removes extmem, crashes on quit otherwise unless
	clr.l	$11e						;AllocExtMem, but why waste for the other 2 games
										;just stores file in ram anyway
	patchs	$5c8ea,loadfyolk

	patch $5c87e,quit

	bsr _flushcache
	jmp	$5c004

kwikjmp:
	movem.l $1246,d0-d7/a0-a6
	patch	$3ccd4,Kbkwik			;keyboard fix + quit
	move.l	_custom1(pc),d1
	beq.b	skip
	move.l	#$4e714e71,$98c8			;Infinite lives
	move.w	#$4e71,$98cc
skip:
	bsr _flushcache
	jmp		$3ea.W

KbMain:
	movem.l D0-A6,-(A7)
	bra		KbInt
KbMagic:
	movem.l D0-A6,-(A7)
	not.b	d0
	ror.b	#$1,d0
	bra		KbInt
KbInt:
	cmp.b	_keyexit(pc),d0				; f10
	beq	quit
noquit:
	movem.l (a7)+,D0-A6
	rts

Kbkwik:					;had to rewrite the keyboard routine for KwikSnax
	movem.l D0-A6,-(A7)		;the original didn't wait for the serial and there
	btst	#$3,$bfed01		;were a few other problems
	beq		noquit2
	moveq	#$0,d0
	move.b	$bfec01,d0

;	move.b	#$57,$bfee01

	clr.b	$bfec01

	bsr	_ackkb

;	clr.b	$bfee01
	not.b	d0
	ror.b	#$1,d0
	moveq	#$0,d1
	move.l	d0,d1
	lea		$180.w,a0
	bclr	#$7,d1
	seq		0(a0,d1.w)
	cmp.b	_keyexit(pc),d0				; f10
	beq	quit
noquit2:
	movem.l (a7)+,D0-A6
	bsr _flushcache
	jmp		$3cd02


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
