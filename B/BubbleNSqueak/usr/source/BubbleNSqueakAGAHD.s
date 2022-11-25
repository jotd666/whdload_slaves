;*---------------------------------------------------------------------------
;  :Program.	BubbleNSqueakHD.asm
;  :Contents.	Slave for "BubbleNSqueak"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BubbleNSqueakHD.asm 1.3 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"BubbleNSqueakAGA.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;;DEBUG
	IFD	DEBUG
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
DOSASSIGN
INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 6000
BOOTDOS
CACHE

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA|WHDLF_Req68020
slv_keyexit	= $5D	; num '*'


DUMMY_CD_DEVICE = 1
USE_DISK_LOWLEVEL_LIB
USE_DISK_NONVOLATILE_LIB

;============================================================================

	INCLUDE	kick31cd32.s
	include "BubbleShared.s"

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.1"
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
	
_assign1
	dc.b	"Bubble1",0
_assign2
	dc.b	"bubble2",0
slv_config
    dc.b    "C1:X:Start with standard 1 button joystick:0;"
	dc.b	0

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Bubble'N'Squeak AGA/CD³²"
			IFD	DEBUG
			dc.b	" (DEBUG MODE)"
			ENDC
			dc.b	0
slv_copy		dc.b	"1994 Audiogenic",0
slv_info		dc.b	"Install/fix by JOTD",10
		dc.b	"Thanks to Codetapper/Ninjaw for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_program:
	dc.b	"code",0
_program1:
	dc.b	"code1",0
_program2:
	dc.b	"code2",0
_program3:
	dc.b	"code3",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN


;============================================================================

	;initialize kickstart and environment

; pause + esc then restart: freeze in dos.Delay() call (why? I dunno,
; but maybe because the game is buggy (cf Nick Faldo's Golf CD) and sets
; D1 with a move.w. kickfs dos emulation maybe returns non-zero in D1 in
; previous system calls, whereas in the real ROM, D1 MSW is zeroed, and
; the Delay bug does not show. But that's not for sure. Maybe some doslib
; interrupt is not in the same state with kickfs than with real ROM, and
; because of the game fiddling with CIAs or VBL it locks up...
;
; the delay call was surely used in order to wait for HD/floppy IO
; to finish, which is useless here, so we remove it harmlessly and the
; loading is even faster :)

new_Delay
	rts

_bootdos

	move.l	(_resload,pc),a2		;A2 = resload

	; better safe than sorry!

	bsr	_emu_copylock


	;install VBL handler
		IFEQ	1
		lea	old_vbl_handler(pc),a0
		move.l	$6C.W,(a0)
		pea	new_vbl_handler(pc)
		move.l	(a7)+,$6C.W
		ENDC

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	PATCH_XXXLIB_OFFSET	Delay

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		lea	_program(pc),a0
		jsr	resload_GetFileSize(a2)
		cmp.l	#139892,d0
		beq.b	_cd32_startup
		cmp.l	#142296,d0
		bne.b	_wrongver  ; only AGA version supported by this slave

	; AGA: joypad routine
		bsr	_detect_controller_types

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_aga(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


_cd32_startup
	;install dummy cd.device

		bsr	_patch_cd32_libs

	;load the 3 executables

		IFEQ	1
		lea	_program1(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_vbr(pc),a5
		bsr	_load_exe

		lea	_program2(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_vbr(pc),a5
		bsr	_load_exe
		ENDC
		
		lea	_program1(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_cd32(pc),a5
		bsr	_load_exe
		rts


; < d7: seglist

_patch_vbr:
	add.l	d7,d7
	add.l	d7,d7
	move.l	d7,a1
	addq.l	#4,a1
	move.l	#$70004E71,$5ABA(a1)
	rts
	
; < d7: seglist

_patch_aga:	
	moveq.l	#0,d2
	bsr	get_section
	IFD	DEBUG
	move.l	a1,$100.W
	ENDC
	lea	_pl_seg0_aga(pc),a0
	jsr	resload_Patch(a2)

	move.b	controller_joypad_1(pc),d0
	beq.b	.nopad
	moveq.l	#0,d2
	bsr	get_section
	lea	_pl_seg0_aga_cd32pad(pc),a0
	jsr	resload_Patch(a2)	
.nopad
	
	moveq.l	#1,d2
	bsr	get_section

	lea	_pl_seg1_aga(pc),a0
	jsr	resload_Patch(a2)


.out
	rts


_patch_cd32

	move.l	d7,a1
	addq.l	#4,a1
	move.l	_resload(pc),a2
	lea	_pl_seg0_cd32(pc),a0
	jsr	resload_Patch(a2)

	move.b	controller_joypad_1(pc),d0
	beq.b	.nopad
	moveq.l	#0,d2
	bsr	get_section
	lea	_pl_seg0_cd32_cd32pad(pc),a0
	jsr	resload_Patch(a2)	
.nopad
	rts

; version 1 (AGA): 2 sections, copylock, code size: 142296

_pl_seg0_aga:
	PL_START
	PL_L	$5AC8,$70004E71		; VBR stuff
	PL_PS	$FF7C,avoid_af_1	; access fault
	PL_P	$137C8,read_joypad_buttons_floppy
	; fix standard joystick 2-button mode
	PL_PS	$136fa,two_button_test_potgo
	; 0: 1-button joystick controller by default
	; 1: 2-button joystick mode
	PL_IFC1
	PL_W	$1b3b8+2,0
	PL_ENDIF
	
	PL_S	$10f26,$10f3e-$10f26	; skip some debug code
	;;PL_S	$13780,$c  	; in-game fire test just before CD32 button test
	;; PL_S	$1365c,$13668-$1365c  	; menu button test + in-game fire test...
	;; PL_S	$136ee,$136FA-$136ee	; in-game fire test
	PL_END
_pl_seg0_aga_cd32pad
	PL_START
	PL_IFC1
	PL_ELSE
	PL_W	$1b3b8+2,2		; CD32 controller by default, unless CUSTOM1 is set
	PL_ENDIF
	PL_END

_pl_seg1_aga:
	PL_START
	PL_P	$0,_emu_copylock
	PL_END
	
;get_pressed_key:
;	ROR.B	#1,D0			;12932: e218
;	MOVE.L	D0,D1			;12934: 2200
;	ANDI.B	#$7f,D1			;12936: 0201007f
	

; > D3 bit 1 set if fire 1, bit 2 set if fire 2

read_joypad_buttons_cd32
	movem.l	d0,-(a7)
	moveq.l	#0,d3
	moveq.l #1,d0	; port 1
	bsr	_read_joystick
	btst	#JPB_BTN_RED,d0
	beq.b	.nofire1
	bset	#1,d3
.nofire1
	btst	#JPB_BTN_BLU,d0
	beq.b	.nofire2
	bset	#2,d3
.nofire2
	movem.l	(a7)+,d0
	rts
	

avoid_af_1
	move.l	A4,D0
	rol.l	#8,d0
	tst.b	d0
	beq.b	.ok
	cmp.b	_expmem(pc),d0
	beq.b	.ok
.pb:
	sub.l	A4,A4
	moveq	#0,D0
	rts
.ok
	moveq	#0,D0
	move.b	(A4),D0
	rts
	
count
	dc.l	0
	
	

; cd32 version: 1 section, code size: 139892  (filename: code3)

_pl_seg0_cd32:
	PL_START
	PL_L	$5ABA,$70004E71		; VBR stuff
	;;PL_P	$137C0,read_joypad_buttons_cd32
	PL_IFC1	
	PL_W	$1b3ac+2,0
	PL_ELSE
	; if custom1 not set, set 2 button joystick
	; (overridden later by the CD32 joypad if detected)
	PL_W	$1b3ac+2,1
	PL_ENDIF
	; fix 2nd button option
	PL_PS	$136f2,two_button_test_potgo
	PL_END

_pl_seg0_cd32_cd32pad:
	PL_START
	PL_IFC1
	PL_ELSE
	PL_W	$1b3ac+2,2
	PL_ENDIF
	PL_END
	rts

_ecsunsup_msg:
	dc.b	"This slave doesn't support the ECS version",0

	
;============================================================================

	END
