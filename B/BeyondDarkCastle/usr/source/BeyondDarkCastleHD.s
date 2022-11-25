;*---------------------------------------------------------------------------
;  :Program.	BeyondDarkCastle.asm
;  :Contents.	Slave for "Beyond Dark Castle" from Activision
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	16.02.2000
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	BeyondDarkCastle.slave
	OPT	O+ OG+			;enable optimizing
	ENDC


;======================================================================

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$100000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$59		;ws_keyexit = F10
		dc.l	0		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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
_name	dc.b	'Beyond Dark Castle',0
_copy	dc.b	'1989 Activision',0
_info	dc.b	'Installed and fixed by Mr.Larmer & JOTD',10
	dc.b	'Version '
	DECL_VERSION
	dc.b	-1
	dc.b	'Greetings to Don Adan',0
	CNOP 0,2

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		
		lea	$10000,A0
		move.l	#$2C00,D0
		move.l	#$5800,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		move.l	#$80000,$1518.w		; ext mem

		pea	Patch(pc)
		move.l	(a7)+,$16(a0)
		bsr	_flushcache
		jmp	(a0)

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

;--------------------------------
keyboard
	clr.b	($BFEC01)
	movem.w	d0,-(a7)
	not.b	d0
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	beq		quit
	movem.w	(a7)+,d0
	rts

quit:
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
Patch
		patchs	$6BC8,keyboard	; quit key on 68000
		move.w	#$8060,$895C		; set correct DMA

		move.w	#$4EF9,$8A3A
		pea	Patch2(pc)
		move.l	(a7)+,$8A3C

		move.w	#$4EF9,$8C12
		pea	Load(pc)
		move.l	(a7)+,$8C14

		move.w	#$4EF9,$8CD4
		pea	Save(pc)
		move.l	(a7)+,$8CD6

		move.w	#$600C,$91DC		; skip drive init
		move.w	#$4E71,$91F8		; skip drive init
		move.w	#$4E71,$9224		; skip drive init
		move.w	#$6012,$929C		; skip drive init
		move.w	#$600A,$92D6		; skip drive init
		bsr	_flushcache

		jmp	$6870.w

;--------------------------------

Patch2
		cmp.l	#$66000046,$C5F6
		bne.b	.noprot
		cmp.l	#$4A0066F4,$C5FA
		bne.b	.noprot

		move.w	#$6002,$C5F6		;skip manual protection
		move.w	#$4E71,$C5FC
.noprot
		lea	$7FFFC,a7
		bsr	_flushcache
		jmp	$8A40

;--------------------------------

Load
		movem.l	d0-a6,-(A7)

		moveq	#0,d2
		move.b	d0,d2
		addq.b	#1,d2

		moveq	#0,d0
		move.w	d1,d0
		mulu	#$200,d0
		add.l	#$C00,d0

		move.l	#$200,d1

		bsr.b	_LoadDisk

		movem.l	(A7)+,d0-a6
		lea	$200(a0),a0
		moveq	#0,d0
		rts

;--------------------------------

Save
		movem.l	d0-a6,-(A7)

		lea	_nr(pc),a1
		add.b	#'1',d0
		move.b	d0,(a1)

		move.l	#$200,d0		;len
		mulu	#$200,d1
		add.l	#$C00,d1		;offset
		lea	(a0),a1			;address
		lea	_savename(pc),a0	;filename
		move.l	_resload(pc),a2
		jsr	resload_SaveFileOffset(a2)

		movem.l	(A7)+,d0-a6
		lea	$200(a0),a0
		moveq	#0,d0
		rts

_savename
		dc.b	'Disk.'
_nr		dc.b	'1',0
		even

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

	END
