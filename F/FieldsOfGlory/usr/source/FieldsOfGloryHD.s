;*---------------------------------------------------------------------------
;  :Program.	FieldsOfGlory.asm
;  :Contents.	Slave for "FieldsOfGlory"
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
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"FieldsOfGlory.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 50000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS
;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s



;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_assign1
	dc.b	"FOG1",0
_assign2
	dc.b	"FOG2",0

slv_name		dc.b	"Fields Of Glory",0
slv_copy		dc.b	"1989 Microprose",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to Dr Bong for diskimages",10,10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"FOG",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
;============================================================================

	;initialize kickstart and environment

_bootdos
	bsr	_patchkb

	move.l	(_resload),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
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
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

	;patch
		lea	pl_main(pc),a0
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		addq.l	#4,a1
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

.end		moveq	#0,d0
		rts

pl_main
	PL_START

	; protection

	PL_L	$7F6,$10D966FC
	PL_W	$7FA,$600E

	; wrong code

	PL_L	$65CE,$4E714E71

	; access faults

	PL_W	$96A4,$4E71
	PL_PS	$96A6,fix_af
	PL_W	$973A,$4E71
	PL_PS	$973C,fix_af
	PL_END

fix_af
	move.l	D0,-(a7)
	move.l	a3,d0
	cmp.l	#CHIPMEMSIZE,d0
	bcs.b	.ok

	cmp.l	_expmem(pc),d0
	bcc.b	.ok

	; avoid access fault: set A3 to 0

	sub.l	a3,a3
.ok
	move.l	(a7)+,d0

	MOVE.B	115(A3),D0		;096A4: 102B0073
	ANDI.B	#$06,D0			;096A8: 02000006
	rts

_patchkb
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

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

	END
