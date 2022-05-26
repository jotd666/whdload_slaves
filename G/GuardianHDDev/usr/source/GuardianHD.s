;*---------------------------------------------------------------------------
;  :Program.	SyndicateHD.asm
;  :Contents.	Slave for "Syndicate"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SyndicateHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Guardian.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
;CHIP_ONLY
;============================================================================
	IFD	CHIP_ONLY
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $00000
	ELSE
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
;DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 11000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 6000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick31.s
	include	ReadJoyPad.s
	
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name	dc.b	"Guardian"
		IFD		CHIP_ONLY
		dc.b	" (debug/chip mode)"
		ENDC
		dc.b	0
slv_copy	dc.b	"1994 Acid Software",0
slv_info	dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	
slv_config:
    dc.b    "C1:X:trainer infinite lives:0;"
    dc.b    "C1:X:trainer infinite energy:1;"
    dc.b    "C1:X:trainer infinite smart bombs:2;"
    dc.b    "C1:X:trainer infinite missiles:3;"

	dc.b	0
	

_program:
	dc.b	"sw",0
_args	
	dc.b	10
_args_end
	dc.b	0
_noargs
	dc.b	10
_noargs_end
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
	clr.l	$0.W
	
	; detect joypads, with interrupts disabled
	move.l	(4),a6
	jsr	_LVODisable(a6)
	bsr	_detect_controller_types
	jsr	_LVOEnable(a6)
	
	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$20000-$1D8D8,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC
	
	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

check_version
	lea	_program(pc),a0
	jsr	resload_GetFileSize(a2)
	cmp.l	#314720,d0
	beq.b	.ok
	cmp.l	#313952,d0
	beq.b	.ok
	cmp.l	#315736,d0
	bne.b	wrongver

.ok
	rts
wrongver
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
; < d7: seglist (APTR)

patch_main

	move.l	d7,a1
	add.l	#4,a1
	lea	pl_main(pc),a0

	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	rts

pl_main:
	PL_START
	PL_R	$0f66e		; check disk
	PL_P	$0f138,load_file
	PL_P	$0b684,read_joypad
	; 2P port 0 joypad read not wired, they probably
	; decided afterwards to use same joypad
	;PL_I	$0b6f8	; player 2 read routine
	
	PL_IFC1X	0
	PL_NOP		$0fdf4,6
	PL_ENDIF
	PL_IFC1X	1
	PL_NOP		$03e9a,8
	PL_NOP		$03ea4,8
	PL_NOP		$03ee6,8
	PL_ENDIF
	PL_IFC1X	2
	PL_NOP		$06f62,6
	PL_ENDIF
	PL_IFC1X	3
	PL_NOP		$07120,6
	PL_ENDIF
	PL_END

read_joypad
	moveq	#1,d0
	move.l	d1,-(a7)
	bsr	_read_joystick
	; add keyboard
	move.l	(a7)+,d1
	rts
	
; < d0: name
; < d1: location

load_file
	movem.l	d1/a0-a2,-(a7)
	move.l	d0,a0
	move.l	d1,a1
	move.l	_resload(pc),a2
	jsr		resload_LoadFile(a2)
	movem.l	(a7)+,d1/a0-a2
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
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	move.l	a3,-(a7)
	jsr	(_LVOIoErr,a6)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts



_tag		dc.l	WHDLTAG_CUSTOM1_GET
	dc.l	0
		dc.l	0

	END
