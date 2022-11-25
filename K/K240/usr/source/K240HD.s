;*---------------------------------------------------------------------------
;  :Program.	K240HD.asm
;  :Contents.	Slave for "K240"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: K240HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"K240.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
BOOTDOS
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

        INCLUDE kick13.s


;============================================================================

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

_assign1
	dc.b	"K240_1",0
_assign2
	dc.b	"K240_2",0
_assign3
	dc.b	"K240_3",0
_assign4
	dc.b	"DF0",0

slv_name		dc.b	"K240",0
slv_copy		dc.b	"1994 Gremlin",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to Adrian for the original disks",10
		dc.b	"and to TRSI/Zenith for the crack",10,10
		dc.b	"Version "
		DECL_VERSION

		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
_intro:
	dc.b	"intro",0
_program:
	dc.b	"playK240",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

_bootdos

	move.l	(_resload,pc),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_NC|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
	;assigns
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
	;assigns
		lea	_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
	;assigns
		lea	_assign4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_intro(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_nointro			;file not found

	;patch here
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	_pl_intro(pc),a0
		sub.l	#$1BAD4,a1
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
		lea	_pl_main(pc),a0
		sub.l	#$1BACC,a1
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

_nointro
		pea	_program(pc)
		bra.b	_fnf
_end
		pea	_program(pc)
_fnf
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_pl_intro:
	PL_START
	PL_W	$1C3F6,$4E71	; skips insert disk 2 and press LMB
	PL_END
_pl_main:
	PL_START
	; remove protection

	PL_S	$1FB96,$18
	
	; load

	PL_W	$1F20E,$4E71	; press LMB
	PL_S	$1F348,6	; LMB
	PL_S	$1F39E,6	; LMB

	; save

	PL_S	$1ED9A,$C	; skip save message + click

	; load/save insert disk messages

	PL_L	$1F0FC,$4E714E71	; searching for games
	PL_L	$1F204,$4E714E71
;;	PL_L	$1F230,$4E714E71	; analyzing (load)
	PL_L	$1F33E,$4E714E71
	PL_L	$1F394,$4E714E71
	PL_END

