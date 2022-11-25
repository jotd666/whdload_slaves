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
SEGTRACKER

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA|WHDLF_Req68020
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b    "3.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
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

slv_name		dc.b	"Theme Park AGA"
    IFD CHIP_ONLY
    dc.b    " (DEBUG/CHIP mode)"
    ENDC
            dc.b    0
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
	dc.b	$A,0
slv_config
        dc.b    "C1:B:skip introduction;"
		dc.b	0

	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

		lea	_tag(pc),a0
		jsr	resload_Control(a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

        bsr get_version
        
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



get_version:
	movem.l	d1/a1,-(a7)
	lea	_intro(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#594380,D0      ; "main" is actually the intro
	beq.b	.aga


	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.aga
    moveq.l #0,d0
.out
    movem.l	(a7)+,d1/a1
    rts

    bra.b   .out
    
; < d7: seglist

_intro_patch:
	move.l	d7,a1
	lea	_patchlist_intro(pc),a0
	jsr	resload_PatchSeg(a2)

	rts

; < d7: seglist

_game_patch:
	move.l	d7,a1
	lea	_patchlist_aga(pc),a0
	jsr	resload_PatchSeg(a2)
	rts

_patchlist_intro:
	PL_START
    PL_S    0,$4E   ; skip yellow flash + debug code
	PL_P	$9244,_set_interrupt
	PL_END
    

_patchlist_aga:
	PL_START
    PL_S    0,$4E   ; skip yellow flash + debug code
    PL_PS   $53bf4,avoid_af_1
	PL_P	$57980,_set_interrupt
	PL_PS	$58354,_emulate_dbf	; fix infinite loop
    PL_PS   $57504,_keyboard_hook

	PL_END


_keyboard_hook
	MOVE.W	D0,D1			;56478: 3200
	NOT.B	D1			;5647a: 4601
	ROR.B	#1,D1			;5647c: e219
    cmp.b   _keyexit(pc),d1
    beq _quit
    rts
    
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

avoid_af_1
    cmp.l   #CHIPMEMSIZE,a1
    bcs.b   .ok
    cmp.l   _expmem(pc),a1
    bcc.b   .ok
    rts
.ok
	NOT.W	D4			;53bf4: 4644
	AND.W	D4,(0,A1,D1.W)		;53bf6: c9711000
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
_set_interrupt:
	; fix SMC problem
	bsr	_flushcache
	; original code
	move.w	#$8020,$dff09a
	; enable video & sprite DMA (else: black screen!)
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



	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	jsr	(a5)
.skip
	;call
	add.l	d7,d7
	add.l	d7,d7
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
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
