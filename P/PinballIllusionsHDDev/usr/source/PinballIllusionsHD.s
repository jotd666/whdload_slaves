;*---------------------------------------------------------------------------
;  :Program.	PinballIllusionsHD.asm
;  :Contents.	Slave for "PinballIllusions"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: PinballIllusionsHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"PinballIllusions.slave"

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
FASTMEMSIZE	= $100000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG
INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS

; for CD32 part

DUMMY_CD_DEVICE = 1
USE_DISK_LOWLEVEL_LIB
USE_DISK_NONVOLATILE_LIB

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_ReqAGA|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_assign_1:
	dc.b	"Pin3001",0
_assign_2:
	dc.b	"cd32 illusions",0

slv_name		dc.b	"Pinball Illusions AGA/CD³²",0
slv_copy		dc.b	"1994/95 21st Century Entertainment",0
slv_info		dc.b	"adapted by JOTD",10
			dc.b	"Thanks to Chris Vella for disk images",10,10
			dc.b	"Version 2.3 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Pinball",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

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
		lea	_assign_1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found

		bsr	_patch_cd32_libs

	;patch here
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		addq.l	#4,a1
	
		lea	_pl_pinball_v1(pc),a0
		cmp.l	#$43ED0020,$186(a1)
		beq.b	.patch
		lea	_pl_pinball_v2(pc),a0
		cmp.l	#$43ED0020,$19A(a1)
		beq.b	.patch
		lea	_pl_pinball_v3(pc),a0
		cmp.l	#$43ED0020,$1EC(a1)
		beq.b	.patch

		; unsupported version

		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.patch
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

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_end
		pea	_program(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts


_intro_v1:
	move.l	(A0),68(A5)
	clr.l	(A0)
	move.l	4(A7),A0	; approx. start address
	move.l	#$70004E71,$5C(a0)	; remove VBR stuff
	bsr	_flushcache
	rts

_main_v1:
	lea	32(A5),A1
	move.l	#$70004E71,$5B2(a0)	; remove VBR stuff
	bsr	_flushcache
	jmp	4(A0)


_intro_v2:
_intro_v3:
	move.l	(A0),68(A5)
	clr.l	(A0)
	move.l	4(A7),A0	; approx. start address
	move.l	#$70004E71,$62(a0)	; remove VBR stuff
	bsr	_flushcache
	rts

_main_v2:
	lea	32(A5),A1
	move.l	#$70004E71,$59A(a0)	; remove VBR stuff
	bsr	_flushcache
	jmp	4(A0)


_main_v3:
	lea	32(A5),A1
	move.l	#$70004E71,$3A8(a0)	; remove VBR stuff
	bsr	_flushcache
	jmp	4(A0)

_pl_pinball_v1:
	PL_START
	PL_PS	$14A,_intro_v1
	PL_PS	$188,_main_v1
	PL_W	$186,$4E71
	PL_END

_pl_pinball_v2:
	PL_START
	PL_PS	$15E,_intro_v2
	PL_PS	$19C,_main_v2
	PL_W	$19A,$4E71
	PL_END

; cd32
_pl_pinball_v3:
	PL_START
	PL_PS	$1B0,_intro_v3
	PL_PS	$1EE,_main_v3
	PL_W	$1EC,$4E71
	PL_END

;============================================================================

	END
