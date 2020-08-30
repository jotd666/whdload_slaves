;*---------------------------------------------------------------------------
;  :Program.	Speedball2CD32HD.asm
;  :Contents.	Slave for "Speedball2CD32"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: Speedball2CD32HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	2002: started
;               2004: finally got rid of lowlevel.library and mapped keys properly
;               2017: change button read so it works with a real joypad (issue #0000996)
;               2018: I don't see how it worked on a real joypad, it didn't (issue #0000996)
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
	OUTPUT	"Speedball2CD32.slave"
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
FASTMEMSIZE	= $60000
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
INITAGA
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

;============================================================================

	INCLUDE	kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

assign_cd0
	dc.b	"SB2",0

slv_name		dc.b	"Speedball 2 CD³²",0
slv_copy		dc.b	"1994 Renegade",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"P:   pause",10
			dc.b	"ESC: quit game",10,10
			dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

_program:
	dc.b	"game",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

	;enable cache, in chipmem too (game uses chipmem for code, can't be otherwise)
		move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;patch cd.device

		bsr	patch_cd_device

	;assigns
		lea	assign_cd0(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign


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

; < d7: seglist

patch_main
	moveq	#0,d0
	bsr	get_section
	lea	pl_section_0(pc),a0
	jsr	(resload_Patch,a2)

	moveq	#4,d0
	bsr	get_section
	lea	pl_section_4(pc),a0
	jsr	(resload_Patch,a2)

	rts

; < d7 seglist
; < d0 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d0
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d0,.loop
.out
	addq.l	#4,a1
	rts

pl_section_0:
	PL_START

	; remove open/close lowlevel library calls

	PL_L	$346,$4E714E71
	PL_L	$3BA,$4E714E71

	; lowlevel.ReadJoyPort() patches

	; during intro

	PL_PS	$4A6,read_joy_1

	; during game, only for port 1. port 0 is read the usual way
	; no need for special CD32 buttons read on port 0

	PL_PS	$592,read_joy_2

	PL_END

pl_section_4
	PL_START

	; modify text on quit game option

	PL_L	$2DE6,$0B464952	; "FIR..."
	PL_B	$2DEA,'E'
	PL_L	$2DF2,$0F455343 ; "ESC"
	PL_W	$2DF6,'  '

	; modify text on pause option

	PL_B	$2E29,' '
	PL_W	$2E2A,'P '
	PL_END

SET_JOY_BUTTON:MACRO
	bset	#JPB_BUTTON_\1,D0	; button pressed
	ENDM

read_joy_1
	move.l	#JP_TYPE_GAMECTLR,D0	; force joypad connected
	bsr	joy_test
	rts

read_joy_2
	move.l	D1,-(a7)
	move.l	#JP_TYPE_GAMECTLR,D0	; force joypad connected
	bsr	joy_test

	; read keyboard

	move.b	$bfec01,d1
	ror.b	#1,d1
	not.b	d1

	cmp.b	#69,D1			; ESC
	bne.b	.skq
	or.l	#JP_BUTTON_MASK,d0
.skq
	cmp.b	#$19,d1
	bne.b	.skp
	SET_JOY_BUTTON	BLUE		; P = PAUSE
.skp
	move.l	(a7)+,d1
	rts



; tests joystick moves on port 1 (adapted from fakepad.s by me)
; > D0: joystick & fire (1 & 2 if avail) button bits set

joy_test:
	movem.l	A1/D3-D6,-(A7)
	move.w	$DFF00C,D4	; game controller #1
	move.w	D4,D5
	btst	#1,D4
	beq.b	.left_off
	bset	#JPB_JOY_RIGHT,D0
	bra.b	.vert_test
.left_off:
	btst	#9,D4
	beq.b	.vert_test
	bset	#JPB_JOY_LEFT,D0
.vert_test
	lsr.w	#1,D4
	eor.w	D5,D4
	btst	#0,D4
	beq.b	.back_off
	bset	#JPB_JOY_DOWN,D0
	bra.b	.exit
.back_off
	btst	#8,D4
	beq.b	.exit
	bset	#JPB_JOY_UP,D0
.exit
		
	lea	$BFE001,a1
		
	moveq	#CIAB_GAMEPORT1,d3	; red button ( port 1 )

	; test buttons

	btst	#7,(a1)
	bne	.no_b1

	SET_JOY_BUTTON	RED
.no_b1
	; 2nd button test

	btst	#6,potinp+$DFF000
	bne	.no_b2

	SET_JOY_BUTTON	BLUE
	; reset ports (FF00 is the proper value according to RobinsonB5@eab)
	; should fix issue #000996
	move.w	#$FF00,(potgo+_custom)	
.no_b2
		

	movem.l	(A7)+,A1/D3-D6
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
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


;============================================================================

; cd.device "emulation" stuff, borrowed to fakepad.s (by JOTD too :))


CDDEVICE_ID = $CDDECDDE

PATCH_IO:MACRO
	move.l	$4.W,a0
	add.w	#_LVO\1+2,a0
	lea	.\1_save\@(pc),a1
	move.l	(a0),(a1)
	lea	.\1\@(pc),a1
	move.l	a1,(a0)
	bra.b	.cont\@
.\1_save\@:
	dc.l	0
.\1\@:
	cmp.l	#CDDEVICE_ID,IO_DEVICE(a1)
	beq.b	.ignore\@
	bra.b	.org\@
	; ignore (cd.device)
.ignore\@
	moveq.l	#0,D0
	rts
.org\@
	move.l	.\1_save\@(pc),-(A7)
	rts
.cont\@
	ENDM


patch_cd_device:
	movem.l	D0-A6,-(A7)

	;redirect calls: opendevice/closedevice

	move.l	4.W,a0
	add.w	#_LVOOpenDevice+2,a0
	lea	_opendev_save(pc),a1
	move.l	(a0),(a1)
	lea	_opendev(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOCloseDevice+2,a0
	lea	_closedev_save(pc),a1
	move.l	(a0),(a1)
	lea	_closedev(pc),a1
	move.l	a1,(a0)

	PATCH_IO	DoIO
	PATCH_IO	SendIO
	PATCH_IO	CheckIO
	PATCH_IO	WaitIO
	PATCH_IO	AbortIO

	bsr	_flushcache

	movem.l	(A7)+,D0-A6
	rts

_closedev:
	move.l	IO_DEVICE(a1),D0
	cmp.l	#CDDEVICE_ID,D0
	beq.b	.out

.org
	move.l	_closedev_save(pc),-(a7)
	rts

.out
	moveq	#0,D0
	rts

_opendev:
	movem.l	D0,-(a7)
	move.l	(a0),d0
	cmp.l	#'cd.d',D0
	beq.b	.cddevice
	bra.b	.org

	; cdtv device
.cddevice
	move.l	#CDDEVICE_ID,IO_DEVICE(a1)
.exit
	movem.l	(A7)+,D0
	moveq.l	#0,D0
	rts

.org
	movem.l	(A7)+,D0
	move.l	_opendev_save(pc),-(a7)
	rts

_opendev_save:
	dc.l	0
_closedev_save:
	dc.l	0
