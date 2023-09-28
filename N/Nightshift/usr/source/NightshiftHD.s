;*---------------------------------------------------------------------------
;  :Program.	NightshiftHD.asm
;  :Contents.	Slave for "Nightshift"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: NightshiftHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Nightshift.slave"
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
;DISKSONBOOT
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH

;============================================================================

KICKSIZE	= $40000			;34.005
;KICKSIZE	= $80000			;40.068
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	CNOP 0,4
_name		dc.b	"Night Shift",0
_copy		dc.b	"1990 Lucasfilm Games",0
_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"IML",0
_maindir:
	dc.b	"Night Shift",0
_args		dc.b	"HD",10
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

	bsr	_patchkb

	move.l	(_resload),a2		;A2 = resload

	;enable cache
;		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
;		move.l	#WCPUF_All,d1
;		jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;lock directory (for v2)

		lea	_maindir(pc),a1
		move.l	a1,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
		beq.b	.skiplock

		jsr	(_LVOCurrentDir,a6)

.skiplock:
	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
		bsr	_patchexe

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

_patchexe:
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		addq.l	#4,a1
		lea	_pl_main_ntsc(pc),a0
		cmp.l	#$32300800,$7094(a1)
		beq.b	.patch
		lea	_pl_main_pal_2(pc),a0
		cmp.l	#$32300800,$707C(a1)
		beq.b	.patch
		lea	_pl_main_pal_1(pc),a0
		cmp.l	#$61646F77,$7094(a1)
		beq.b	.patch

		; unsupported version

		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts	
.patch
		jsr	resload_Patch(a2)
		rts


_pl_main_pal_1:
	PL_START
	PL_B	$32E,$60	; skip country PAL/NTSC check
	PL_END

_pl_main_ntsc:
	PL_START
	PL_B	$32E,$60	; skip country PAL/NTSC check
	PL_W	$7094+$A,$4E71	; skip protection
	PL_END

_pl_main_pal_2:
	PL_START
	PL_B	$32E,$60	; skip country PAL/NTSC check
	PL_W	$707C+$A,$4E71	; skip protection
	PL_END

_patchkb
	IFEQ	KICKSIZE-$40000

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
	ELSE
	rts
	ENDC

;============================================================================

	IFEQ	KICKSIZE-$40000
	INCLUDE	whdload/kick13.s
	ELSE
	INCLUDE	kick31.s
	ENDC

;============================================================================

	END
