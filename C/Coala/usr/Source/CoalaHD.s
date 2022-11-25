

;*---------------------------------------------------------------------------
;  :Program.	CoalaHD.asm
;  :Contents.	Slave for "Coala" from 
;  :Author.	JOTD
;  :Original	v1 jffabre@free.fr
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
	INCLUDE	lvo/dos.i

	IFD BARFLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

NUMDRIVES = 1
WPDRIVES = %1111

;DISKSONBOOT
DOSASSIGN
;DEBUG
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
slv_keyexit	= $5D	; num '*'

basic_Flags = WHDLF_Examine|WHDLF_NoError|WHDLF_EmulPriv|WHDLF_NoKbd
	IFD	INITAGA
slv_Flags =	basic_Flags|WHDLF_ReqAGA
	ELSE
slv_Flags =	basic_Flags
	ENDC



;============================================================================

	INCLUDE	kick31.s

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
	
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_CurrentDir		dc.b	"data",0
slv_name
		dc.b	"Coala "
	IFD	INITAGA
		dc.b	"AGA"
	ELSE
		dc.b	"ECS"
	ENDC
	IFD	DEBUG
		dc.b	" (DEBUG MODE)"
	ENDC
		dc.b	0
slv_copy		dc.b	"1993 Empire",0
slv_info		dc.b	"Install by JOTD",10,10
		dc.b	"Thanx to Angus for the original disks",10,10
		dc.b	"Thanx to Hoodlum for the crack",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_program:
	dc.b	"Coala",0
_args		dc.b	10
_args_end
	dc.b	0
_assign:
	dc.b	"JF0",0
	EVEN

_bootdos
	bsr	install_kb_routine	; for later use in the game

	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
		bsr	_patch_exe

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

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
	rts

_patch_exe:
	movem.l	D0-A6,-(A7)
	move.l	_resload(pc),a2

	move.l	d7,d0
	add.l	d7,D7
	add.l	d7,D7

	moveq.l	#0,d2
	bsr	get_section
	lea	pl_aga_0(pc),a0
	jsr	resload_Patch(A2)

	moveq.l	#4,d2
	bsr	get_section
	lea	pl_aga_4(pc),a0
	jsr	resload_Patch(A2)

	moveq.l	#7,d2
	bsr	get_section
	lea	pl_aga_7(pc),a0
	jsr	resload_Patch(A2)

	moveq.l	#8,d2
	bsr	get_section
	lea	pl_aga_8(pc),a0
	jsr	resload_Patch(A2)

	movem.l	(A7)+,D0-A6
	rts

pl_aga_0:
	PL_START
	PL_S	$6E,$7E-$6E		; completely bypass protection screen
	PL_PSS	$0024C,tst_sdr,2
	PL_PSS	$001F2,clr_sdr,2
	PL_PSS	$040F2,clr_sdr,2
	PL_PSS	$040FC,clr_sdr,2
	PL_PSS	$04602,clr_sdr,2
	PL_PSS	$07704,clr_sdr,2

	PL_PS	$04012,get_sdr


	PL_END

pl_aga_8:
	PL_START
	PL_B	$550D2-$54064,'J'	; changes "DF0:" to "JF0:"
	PL_END

pl_aga_4:
	PL_START
	PL_PSS	$30B9E-$2EA6C,clr_sdr,2
	PL_PSS	$31E1E-$2EA6C,clr_sdr,2
	PL_PSS	$32BD2-$2EA6C,clr_sdr,2

	PL_PS	$30B98-$2EA6C,get_sdr
	PL_PS	$31E3A-$2EA6C,get_sdr
	PL_PS	$32BC6-$2EA6C,get_sdr
	PL_PS	$35BFA-$2EA6C,get_sdr

	PL_B	$31B5A-$2EA6C,'J'	; changes "DF0:" to "JF0:"
	PL_B	$33605-$2EA6C,'J'	; changes "DF0:" to "JF0:"
	PL_END

pl_aga_7
	PL_START
	; copy protection
	PL_L	$32E4-$2D58,$700F4E75
	PL_L	$32E8-$2D58,$700F4E75

	PL_END


get_sdr:
	move.b	bfec01_value(pc),d0
	rts

clr_sdr:
	move.l	a0,-(a7)
	lea	bfec01_value(pc),a0
	clr.b	(a0)

	move.b	#0,$bfec01	; without it it's OK except for pause

	move.l	(a7)+,a0
	;addq.l	#2,(a7)
	rts

tst_sdr:
	movem.l	a0,-(a7)
	lea	bfec01_value(pc),a0
	cmp.b	#$74,(a0)
	movem.l	(a7)+,a0
	rts


install_kb_routine
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	move.l	a0,-(a7)
	lea	bfec01_value(pc),a0
	move.b	$bfec01,(a0)
	move.l	(a7)+,a0

	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

bfec01_value
	dc.w	0

;============================================================================

	END
