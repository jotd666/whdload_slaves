;*---------------------------------------------------------------------------
;  :Program.	KellyXHD.asm
;  :Contents.	Slave for "KellyX"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: KellyXHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"KellyX.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $50000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH

;============================================================================

;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
slv_name		dc.b	"Kelly X"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1989 Virgin Mastertronic",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Kelly_X",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

_bootdos
	clr.l	$0.W


	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
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
		addq.l	#4,a1
		lea	_pl_main(pc),a0
		jsr	resload_Patch(a2)

		sub.l	a1,a1
		lea	_pl_zpage(pc),a0
		jsr	resload_Patch(a2)

		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		add.l	#$9004,a1
		lea	_hiscore_ptr(pc),a3
		move.l	a1,(a3)			; save hiscore start for later
		lea	_hiscore_name(pc),a0
		jsr	resload_LoadFile(a2)
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
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_pl_zpage:
	PL_START
	PL_P	$100,_emu_dbf_d0
	PL_P	$106,_emu_dbf_d1
	PL_P	$10C,_emu_dbf_d2
	PL_P	$112,_emu_dbf_d6
	PL_P	$118,_int3
	PL_P	$11E,_save_highs
	PL_END


_pl_main:
	PL_START
	PL_P	$C77A,_emu_protect		; removes disk protection

	; nop+dbf d0

	PL_PS	$DFCA,_emu_nop_dbf_d0
	PL_PS	$E032,_emu_nop_dbf_d0
	PL_PS	$E09A,_emu_nop_dbf_d0

	; dbf	d0
	PL_L	$0B96,$4EB80100
	PL_L	$3968,$4EB80100
	PL_L	$39D0,$4EB80100

	; dbf	d1
	PL_L	$13FC,$4EB80106

	; dbf	d2
	PL_L	$DEEE,$4EB8010C
	PL_L	$DF9A,$4EB8010C
	PL_L	$E002,$4EB8010C
	PL_L	$E06A,$4EB8010C

	; dbf	d6
	PL_L	$C82C,$4EB80112

	; (almost) fix music interrupt

	PL_L	$CD34,$4EB80118

	; save hiscores

	PL_L	$E80,$4EB8011E
	
	; keyboard timing & quit key for 68000
	PL_PS	$cd6c,kb_int

	PL_END

_save_highs:
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	lea	_hiscore_name(pc),a0
	move.l	_hiscore_ptr(pc),a1
	move.l	#$9C,d0
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	sub.l	#$46A,(a7)
	rts

kb_int:
	move.l	d0,-(a7)
	cmp.b	_keyexit(pc),d0
	beq	_quit
	moveq	#3,d0
	bsr		_beamdelay
	
	move.l	(a7)+,d0
	rts
	
_int3:
	move.w	$dff01e,d0
	and.w	#$20,d0		; discard blitter/copper interrupts
	beq.b	.skip
	jsr	(8,a0)	; stolen
.skip
	rts


_emu_protect
.loop
	move.l	_bwait(pc),d0
	beq.b	.sk
	btst	#6,$bfe001
	bne.b	.loop
.sk
	moveq	#0,d0
	rts
	
_emu_dbf_d1
	move.l	d0,-(a7)
	move.l	d1,d0
	bsr	_emu_dbf_d0
	move.l	(a7)+,d0
	rts
_emu_dbf_d2
	move.l	d0,-(a7)
	move.l	d2,d0
	bsr	_emu_dbf_d0
	move.l	(a7)+,d0
	rts
_emu_dbf_d6
	move.l	d0,-(a7)
	move.l	d6,d0
	bsr	_emu_dbf_d0
	move.l	(a7)+,d0
	rts

_emu_nop_dbf_d0:
	add.l	d0,d0
_emu_dbf_d0
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0

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

_tag		dc.l	WHDLTAG_BUTTONWAIT_GET
_bwait		dc.l	0
		dc.l	0
		
_quit	
	pea	TDREASON_OK
	move.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)
		
_hiscore_ptr:
	dc.l	0

_hiscore_name:
	dc.b	"highs",0
	even

	END
