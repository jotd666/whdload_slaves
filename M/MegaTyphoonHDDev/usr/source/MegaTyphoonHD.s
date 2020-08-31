;*---------------------------------------------------------------------------
;  :Program.	MegaTyphoonHD.asm
;  :Contents.	Slave for "MegaTyphoon"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: MegaTyphoonHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"MegaTyphoon.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;DEBUG

	IFD	DEBUG
CHIPMEMSIZE	= $130000
FASTMEMSIZE	= $0000	
	ELSE
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $30000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM


slv_name		dc.b	"Mega-Typhoon",0
slv_copy		dc.b	"1996 Bernhard Braun / Nordlicht Edv",0
slv_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Set CUSTOM1=1 for infinite lives",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Mega-Typhoon",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload),a2		;A2 = resload

		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

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
		beq	_end			;file not found


	;patch here
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		add.l	#4,a1

		lea	pl_main(pc),a0
		move.l	_custom1(pc),d0
		beq.b	.sk
		lea	pl_train(pc),a0
.sk
		jsr	resload_Patch(a2)
	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_end
		pea	_program(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

pl_train
	PL_START
	PL_W	$5D1A,$4E71	; infinite lives	
	PL_NEXT	pl_main

pl_main
	PL_START

	; access fault at the final level 1 monster

	PL_PS	$65D6,fix_af_1
	PL_PS	$6678,fix_af_1
	PL_PS	$671A,fix_af_1
	PL_PS	$67BC,fix_af_1
	PL_PS	$685E,fix_af_1

	; empty DBF loop

	PL_P	$8F1A,emulate_dbf

	PL_END

fix_af_1
	move.l	a4,d5
	bmi.b	.avoid

	MOVE.L	546(A4),D5
	OR.L	588(A4),D5
.ret	
	addq.l	#2,(a7)
	RTS
.avoid
	moveq	#0,d5
	bra.b	.ret

emulate_dbf
	move.l	d0,-(a7)
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.l	(a7)+,d0
	move.w	(a7)+,d0	; orig
	rts

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
