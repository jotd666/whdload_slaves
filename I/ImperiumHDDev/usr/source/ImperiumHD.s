;*---------------------------------------------------------------------------
;  :Program.	Imperium.asm
;  :Contents.	Slave for "Imperium"
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
	OUTPUT	"Imperium.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $A0000
FASTMEMSIZE	= $20000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 65000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_NoKbd|WHDLF_EmulDivZero
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0
	even

_assign
	dc.b	"Imperium",0

slv_name		dc.b	"Imperium",0
slv_copy		dc.b	"1990 Electronic Arts",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"sth",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload),a2		;A2 = resload

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
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

	;patch
	bsr	_patch_dos
	bsr	_alloc_fib
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

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

.end	
	pea	_program(pc)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

MOVEFIBA0:MACRO
	move.l	a1,a3
	add.l	#\1,a3
	move.l	a0,2(a3)
	ENDM

_alloc_fib
	move.l	#260,d0
	move.l	#MEMF_CLEAR,d1
	move.l	$4.W,a6
	jsr	_LVOAllocMem(a6)
	lea	_fib(pc),a0
	move.l	d0,(a0)
	bne.b	.sk
	illegal		; should not happen
.sk
	rts


PATCH_OFFSET:MACRO
	move.l	A3,A1
	add.l	#_LVO\1,A1
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	_old\1(pc),a0
	move.l	A1,(A0)+

	move.l	A3,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)

	move.w	#$4EF9,(A1)+	
	pea	_new\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	_end_patch\1
_old\1:
	dc.l	0
_d0_value_\1
	dc.l	0
_end_patch\1:
	ENDM

_patch_dos:
	movem.l	D0-A6,-(A7)
	move.l	A6,A3
	move.l	$4.W,A6
	PATCH_OFFSET	ExNext
	bsr	_flushcache
	movem.l	(A7)+,D0-A6
	rts

_newExNext:
	pea	.after(pc)
	move.l	_d0_value_ExNext(pc),d0
	move.l	_oldExNext(pc),-(A7)
	rts

	; clear the $EE that whdload ExNext sets after the name

.after
	move.l	d2,a0
	lea	(fib_FileName,a0),a0
	moveq	#0,d1
.loop
	tst.b	(a0,d1.w)
	beq.b	.out
	addq.l	#1,d1
	bra.b	.loop
.out
	clr.b	(a0,d1.w)
	cmp.w	#108,d1
	beq.b	.exit
	addq.l	#1,d1
	bra.b	.out
.exit
	move.l	d0,d1
	rts


_patch_exe:
	lea	_program(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	cmp.l	#243616,d0
	bne.b	.1
	bsr	_patch_exe_v1
	bra.b	.out
.1
	cmp.l	#242392,d0
	bne.b	.2
	bsr	_patch_exe_v2
.2
	bra.b	.out
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
.out
	rts

_patch_exe_v1:
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	; apply patches on segment

	move.l	a1,a3
	addq.l	#4,a1
	lea	pl_main_v1(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	; correct fileinfoblock which is not longword-aligned (harmless now but...)

	move.l	a3,a1
	move.l	_fib(pc),a0
	MOVEFIBA0	$7036
	MOVEFIBA0	$7062
	addq.l	#8,a0
	MOVEFIBA0	$7B56
	MOVEFIBA0	$7B6A
	MOVEFIBA0	$7B8C
	MOVEFIBA0	$7BA2
	MOVEFIBA0	$7BB8
	MOVEFIBA0	$7BDA
	MOVEFIBA0	$7C22
	
	bsr	_flushcache
	rts
	

_patch_exe_v2:
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	; apply patches on segment

	move.l	a1,a3
	addq.l	#4,a1
	lea	pl_main_v2(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts
	
_fib:
	dc.l	0

pl_main_v1:
	PL_START
	PL_B	$1C8A8,$60	; remove protection
	PL_END

pl_main_v2:
	PL_START
	PL_B	$1CA64,$60	; remove protection
	PL_END


;============================================================================

	END
