;*---------------------------------------------------------------------------
;  :Program.	ThemeParkAGAHD.asm
;  :Contents.	Slave for "ThemeParkAGA"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ThemeParkAGAHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"ThemeParkAGA.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $A0000
NUMDRIVES	= 1
WPDRIVES	= %1111

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG
INITAGA
HDINIT
;HRTMON
IOCACHE		= 160000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS


;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_assign1
	dc.b	"TP1",0
_assign2
	dc.b	"TP2",0
_assign3
	dc.b	"TP3",0
_assign4
	dc.b	"TP4",0

slv_name		dc.b	"Theme Park AGA",0
slv_copy		dc.b	"1993 Bullfrog",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_intro:
	dc.b	"main",0
_program:
	dc.b	"park",0
_args		dc.b	10
_args_end
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload),a2		;A2 = resload

		lea	_tag(pc),a0
		jsr	resload_Control(a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load intro
		move.l	_custom1(pc),d0
		bne.b	.skipintro
		lea	_intro(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_intro_patch(pc),a5
		bsr	_load_exe
.skipintro
	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_game_patch(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

_intro_patch:
	move.l	d7,a1
	addq.l	#4,a1

	; first segment: code

	lea	_patchlist_intro(pc),a0
	jsr	resload_Patch(a2)

	rts

; < d7: seglist

_game_patch:
	move.l	d7,a1
	addq.l	#4,a1

	; first segment: code

	lea	_patchlist_aga(pc),a0
	jsr	resload_Patch(a2)

	rts

_patchlist_intro:
	PL_START
	PL_P	$9244,_set_interrupt
	PL_END

_patchlist_aga:
	PL_START
	PL_P	$57980,_set_interrupt
	PL_END

_set_interrupt:
	; fix SMC problem
	bsr	_flushcache
	; original code
	move.w	#$8020,$dff09a
	; enable video & sprite DMA (why is this needed?)
	move.w	#$8120,$dff096
	rts

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	add.l	d7,d7
	add.l	d7,d7

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	jsr	(a5)
.skip
	;call
	move.l	d7,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	lsr.l	#2,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
