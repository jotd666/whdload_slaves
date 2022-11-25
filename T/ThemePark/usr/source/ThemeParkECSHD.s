;*---------------------------------------------------------------------------
;  :Program.	ThemePark.asm
;  :Contents.	Slave for "ThemePark"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"ThemeParkECS.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================
;CHIP_ONLY
    IFD CHIP_ONLY
CHIPMEMSIZE	= $140000
FASTMEMSIZE	= $0 
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $C0000
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DEBUG
;DISKSONBOOT
HDINIT
;HRTMON
IOCACHE		= 90000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS
CACHE
SEGTRACKER

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s



;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b    "3.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

slv_name		dc.b	"Theme Park (ECS)"
    IFD CHIP_ONLY
    dc.b    " (DEBUG/CHIP mode)"
    ENDC    
            dc.b    0
slv_copy		dc.b	"1991 Bullfrog",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"main",0
_args		dc.b	10
_args_end
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,0

	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end

		clr.l	$0.W			; fix kickemu problem

		move.l	d7,a5
		bsr	_patch_exe

		add.l	a5,a5
		add.l	a5,a5
		addq.l	#4,a5

	;call
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(a5)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)
_quit
	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_end	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_patch_exe
	move.l	_resload(pc),a2
	lea	_pl_main(pc),a0
	move.l	a5,a1
	jsr	resload_PatchSeg(a2)

	rts

_keyboard_hook
	MOVE.W	D0,D1			;56478: 3200
	NOT.B	D1			;5647a: 4601
	ROR.B	#1,D1			;5647c: e219
    cmp.b   _keyexit(pc),d1
    beq _quit
    rts
    
_set_intena:
	bsr	_flushcache
	move.w	#$8020,$DFF09A
	rts

_avoid_af:
	lea	($48,a1),a2
	moveq	#$F,D7
	cmp.l	#0,a0
	bne.b	.ok
	add.l	#$E,(A7)
.ok
	rts


_pl_main:
	PL_START
	PL_S	$0,$B6-$68		; skip green flash
	PL_PS	$4ACAE,_avoid_af	; avoid access fault (actually read in $0)
	PL_P	$4A9B4,_set_intena	; avoid SMC in JMP
	PL_PS	$4B286,_emulate_dbf	; fix infinite loop
    PL_PS   $4A57C,_keyboard_hook
	PL_END


_emulate_dbf:
	move.l	D0,-(A7)
	move.l	D7,D0
	divu.w	#$9,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	move.l	(A7)+,D0
	rts

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

;============================================================================


;============================================================================

	END
