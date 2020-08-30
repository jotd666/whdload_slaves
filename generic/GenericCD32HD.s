;*---------------------------------------------------------------------------
;  :Program.	ChaosEngineHD.asm
;  :Contents.	Slave for "ChaosEngine"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ChaosEngineHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

DEBUG

	IFD BARFLY
	OUTPUT	"ChaosEngineCD32.slave"
	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
	
	STRUCTURE	globals,$100
;		LONG	_resload
		LONG	_chipptr
		LONG	_clist
		BYTE	_decinit

;============================================================================

	IFD	DEBUG
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $100000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
INITAGA
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'


DUMMY_CD_DEVICE = 1

;USE_DISK_LOWLEVEL_LIB

USE_DISK_NONVOLATILE_LIB

;============================================================================

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,0

_assign1
	dc.b	"Oscar",0

slv_name		dc.b	"Chaos Engine CD³²"
			IFD	DEBUG
			dc.b	"(DEBUG MODE)"
			ENDC
			dc.b	0
slv_copy		dc.b	"1994 The Bitmap Brothers",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
			dc.b	"CD³² emulation keys:",10,10
			dc.b	"Player 1",10
			dc.b	"P: pause",10
			dc.b	"SPC: special weapon",10
			dc.b	"L-ALT: green",10
			dc.b	"R-ALT: yellow",10
			dc.b	"[When paused] SPC+both ALTs: quit",10,10
			dc.b	"Player 2: keys 567890",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0


_program:
	dc.b	"OscarCD",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	IFND	USE_DISK_LOWLEVEL_LIB
	lea	OSM_JOYPAD1KEYS(pc),a0
	move.l	#$40646519,(a0)	; raw keycodes
	ENDC

	move.l	_resload(pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		bsr	_patch_cd32_libs
		bsr	force_joysticks

		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

patch_main
	addq.l	#4,d7
	move.l	d7,a1
	lea	pl_main(pc),a0
	move.l	a1,$60.W
	jsr	resload_Patch(a2)
	rts
pl_main		PL_START
;		PL_S	$3e,$b4-$3e			;skip os
;		PL_PS	$b4,_getlang
;		PL_P	$89ec,_allocmem			;emulate
;		PL_S	$2e0,$326-$2e0			;disable os-stuff
;		PL_S	$797a,$cc-$7a			;skip os-restore
;		PL_S	$79ee,10			;skip open
;		PL_PS	$7a24,_loadercd
;		PL_S	$7a54,$68-$54			;skip os-save

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		PL_W	$1ccc,$e841			;lsr.w  -> asr.w
		PL_W	$1cce,$c3fc			;mulu   -> muls

	; uncomment the line below and the mojo doesn't break!!!
		PL_W	$1ce6,$d0c1			;adda.l -> adda.w
		
		PL_W	$1df8,$e841			;lsr.w  -> asr.w
		PL_W	$1dfa,$c3fc			;mulu   -> muls
		PL_W	$1e12,$d0c1			;adda.l -> adda.w
		PL_R	$b5c0				;cd.device
		PL_R	$b614				;cd.device
		PL_PS	$afe2,_readjoy			;lowlevel.ReadJoyPort
		PL_PS	$22e0c,_dbf1
		PL_PS	$22e22,_dbf1
		PL_PS	$2354c,_dbf1
		PL_PS	$23562,_dbf1
		PL_PS	$243f4,_dbf2
		PL_PS	$24458,_dbf2
		PL_END
; make-up for the game bug: calls the routine without the tag id
; and it doesn't work (you'd have to disconnect mouse from port 0)

force_joysticks
	movem.l	d0-a6,-(a7)
	lea	.lowlevel_name(pc),a1
	moveq	#0,d0
	move.l	$4.W,a6
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,a6

	lea	.joytag(pc),a1
	moveq	#0,d0
	jsr	_LVOSetJoyPortAttrsA(a6)

	lea	.joytag(pc),a1
	moveq	#1,d0
	jsr	_LVOSetJoyPortAttrsA(a6)

	movem.l	(a7)+,d0-a6
	rts

.joytag
	dc.l	SJA_Type
	dc.l	SJA_TYPE_GAMECTLR
	dc.l	0
.lowlevel_name
	dc.b	"lowlevel.library",0
	even


CHIP_DATA_OFFSET = $2BE22 ; $A49DC
CHIP_DATA_SIZE = $A77FC-CHIP_DATA_OFFSET


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

	add.l	d7,d7
	add.l	d7,d7

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	a4-a6/d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a4-a6/d7
.skip
	;call
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

;--------------------------------

_getlang	clr.l	-(a7)
		clr.l	-(a7)
		pea	WHDLTAG_LANG_GET
		move.l	a7,a0
		move.l	(_resload,pc),a1
		jsr	(resload_Control,a1)
		addq.l	#4,a7
		move.l	(a7)+,d0
		addq.l	#4,a7
		rts

;--------------------------------

_dbf2
_dbf1		movem.l	d0-d1,-(a7)
		moveq	#8,d1
.1		move.b	($dff006),d0
.2		cmp.b	($dff006),d0
		beq	.2
		dbf	d1,.1
		movem.l	(a7)+,d0-d1
		addq.l	#2,(a7)
		rts

;--------------------------------

_vbi		move.w	#INTF_VERTB,(_custom+intreq)
		rte

;--------------------------------

_allocmem	addq.l	#7,d0				;round up
		and.b	#$f8,d0

		move.l	(_chipptr),a1
		add.l	d0,(_chipptr)
	IFEQ 1
		move.l	(_chipptr),d1
		cmp.l	(_upchip,pc),d1
		blo	.0
		illegal
.0
	ENDC
		move.l	a1,a0
		lsr.l	#3,d0
.clr		clr.l	(a0)+
		clr.l	(a0)+
		subq.l	#1,d0
		bne	.clr
		move.l	a1,d0
		rts

;--------------------------------

_loader		addq.l	#4,a0				;skip "df0:"
		move.l	a2,-(a7)
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFileDecrunch,a2)
		move.l	(a7)+,a2
		moveq	#0,d0				;return code
		rts

_decrunch	bset	#0,(_decinit)
		bne	.initok
		movem.l	d0/a0-a1,-(a7)
		move.l	(12,a7),a0
		move.l	(_expmem,pc),a1
		move.w	#($9266-$8e02)/4-1,d0
.cp		move.l	(a0)+,(a1)+
		dbf	d0,.cp
		move.l	(_resload,pc),a0
		jsr	(resload_FlushCache,a0)
		movem.l	(a7)+,d0/a0-a1

.initok		addq.l	#4,a7
		cmp.l	#"TSM!",(a0)
		bne	.rts

		movem.l	d0-d7/a0-a6,-(a7)
		addq.l	#4,a0
		move.l	(_expmem,pc),-(a7)
.rts		rts

_loadercd	addq.l	#6,a0				;skip "Oscar:"
		move.l	d2,a1
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFileDecrunch,a2)
		add.l	#14,(a7)
		rts

;--------------------------------

_enabledma	move.w	#$c028,(intena,a6)
		waitvb	a6
		move.w	#$86e0!DMAF_RASTER,(dmacon,a6)
		rts

;--------------------------------

_readjoy	move.l	d2,-(a7)

		moveq	#0,d0
		btst	#7,$bfe001
		bne	.1
		bset	#JPB_BUTTON_RED,d0
.1		move.w	_custom+potinp,d1
		btst	#14,D1
		bne	.2
		bset	#JPB_BUTTON_BLUE,d0
.2
		move.w	_custom+joy1dat,d1
		move.w	d1,d2
		btst	#1,d1
		beq	.left_off
		bset	#JPB_JOY_RIGHT,d0
		bra	.vert_test
.left_off	btst	#9,d1
		beq	.vert_test
		bset	#JPB_JOY_LEFT,d0
.vert_test	lsr.w	#1,d1
		eor.w	d2,d1
		btst	#0,d1
		beq	.back_off
		bset	#JPB_JOY_DOWN,d0
		bra	.exit
.back_off	btst	#8,d1
		beq	.exit
		bset	#JPB_JOY_UP,d0
.exit
		move.l	(a7)+,d2
		rts

;============================================================================
