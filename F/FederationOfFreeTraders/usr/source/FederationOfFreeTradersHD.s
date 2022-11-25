;*---------------------------------------------------------------------------
;  :Program.	FOFT.asm
;  :Contents.	Slave for "FOFT" from Gremlin
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	14.03.2000
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
	OUTPUT	dh2:FOFT/FOFT.slave
	OPT	O+ OG+			;enable optimizing
    ENDC
    

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoDivZero	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	_start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem		dc.l	0		;ws_ExpMem
		dc.w	_name-_base	;ws_name
		dc.w	_copy-_base	;ws_copy
		dc.w	_info-_base	;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
_config
	dc.b	"BW;"
    dc.b	0

DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
    
_name	dc.b	"Federation Of Free Traders",0
_copy	dc.b	'1990 Gremlin',0
_info	dc.b	'Adapted by Mr.Larmer',10
	dc.b	'Version '
    DECL_VERSION
    dc.b    -1
	dc.b	'Greetings to Don Adan',10
	dc.b	'Mark Knibbs',0
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	10,0	

	CNOP 0,2

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	#$2EE0,d0
		move.l	#$1770,d1
		moveq	#1,d2
		lea	$78000,a0
		bsr.w	_LoadDisk

		move.l	a0,-(a7)

		move.l	#$1770,D0
		move.l	_resload(pc),a2
		jsr	resload_CRC16(a2)

    blitz
    
		move.l	(a7)+,a0

		cmp.w	#$AC1F,D0       ; version on whdload CD
		bne.w	.another

		move.w	#$6006,$106(a0)		; skip set red color

		pea	Patch(pc)
		move.l	(a7)+,$14E(a0)

		move.w	#$4E75,d0

		move.w	d0,$152(a0)		; read protection long track
		move.l	#$70004E75,$190(a0)	; protection check ok

		move.w	d0,$574(a0)
		move.w	d0,$63E(a0)
		move.w	d0,$68A(a0)
		move.w	d0,$6BC(a0)
		move.w	d0,$6F2(a0)

		move.w	#$4EF9,$8BC(a0)
		pea	Load(pc)
		move.l	(a7)+,$8BE(a0)

		jmp	(a0)
.another
		cmp.w	#$3EC3,D0
		bne.w	.third

		move.w	#$6006,$B4(a0)		; skip set red color

		pea	Patch2(pc)
		move.l	(a7)+,$102(a0)

		move.w	#$4E75,d0

		move.w	d0,$106(a0)		; read protection long track
		move.l	#$70004E75,$144(a0)	; protection check ok

		move.w	d0,$50E(a0)
		move.w	d0,$5D8(a0)
		move.w	d0,$624(a0)
		move.w	d0,$654(a0)
		move.w	d0,$68A(a0)

		move.w	#$4EF9,$84E(a0)
		pea	Load(pc)
		move.l	(a7)+,$850(a0)

		jmp	(a0)
.third
        cmp.w   #$FEC0,d0
.not_support
		subq.l	#8,a7
		pea	TDREASON_WRONGVER.w
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

;--------------------------------

Patch
		move.w	#$4E75,d0

		move.w	d0,$204.w		; strange code in int 2 ?!

		lea	$4E000,a0

		move.w	d0,$B7E(a0)
		move.w	d0,$C48(a0)
		move.w	d0,$C92(a0)
		move.w	d0,$CC4(a0)
		move.w	d0,$CF8(a0)

		move.w	#$4EF9,$EC2(a0)
		pea	Load(pc)
		move.l	(a7)+,$EC4(a0)

		pea	PatchPlayer(pc)
		move.l	(a7)+,$1162(a0)

		move.w	#$4EF9,$58338
		pea	Stack(pc)
		move.l	(a7)+,$5833A

;save game and format disabled

		move.w	d0,$9CE(a0)
		move.w	d0,$DA8(a0)
		clr.w	$48514

;keyboard works something wrong

		jmp	$800.w

;--------------------------------

Patch2
		move.w	#$4E75,d0

		move.w	d0,$204.w		; strange code in int 2 ?!

		lea	$46000,a0

		move.w	d0,$AF2(a0)
		move.w	d0,$BBC(a0)
		move.w	d0,$C06(a0)
		move.w	d0,$C36(a0)
		move.w	d0,$C6A(a0)

		move.w	#$4EF9,$E3A(a0)
		pea	Load(pc)
		move.l	(a7)+,$E3C(a0)

		pea	PatchPlayer(pc)
		move.l	(a7)+,$106E(a0)

		move.w	#$4EF9,$58338
		pea	Stack(pc)
		move.l	(a7)+,$5833A

;save game and format disabled

		move.w	d0,$936(a0)
		move.w	d0,$D1A(a0)
		clr.w	$4046C

;keyboard works something wrong

		jmp	$800.w

;--------------------------------

Stack
		move.w	#2,6(a1)
		move.w	(a7)+,SR
		rts

;--------------------------------

PatchPlayer
		movem.l	a0-a1,-(a7)

		lea	$58000,a0
		lea	$59000,a1
.loop
		cmp.l	#$337C0002,(a0)		; move.w #2,6(a1)
		bne.b	.next
		cmp.l	#$00064E73,4(a0)	; rte
		bne.b	.next

		move.w	#$4EF9,(a0)
		pea	Stack(pc)
		move.l	(a7)+,2(a0)
.next
		addq.l	#2,a0
		cmp.l	a0,a1
		bne.b	.loop

		movem.l	(a7)+,a0-a1

		jmp	$58000

;--------------------------------

Load
		movem.l	d0-a6,-(a7)

		move.l	4(a3),d0
		mulu	#$1770,d0

		move.l	12(a3),d1

		moveq	#1,D2
		move.l	(a3),a0

		bsr.b	_LoadDisk

		movem.l	(A7)+,d0-a6
		rts

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================
