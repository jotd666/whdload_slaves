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
	OUTPUT	"BubbleNSqueakECS.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;DEBUG
	IFD	DEBUG
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
DOSASSIGN
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
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	kick13.s
	include	BubbleShared.s
	
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
    dc.b    "C1:X:Start with 2 button joystick:0;"
	dc.b	0

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Bubble'N'Squeak ECS"
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

	; install a quick&dirty keyboard handler because the kickemu handler doesn't work on 68000
	; probably because the game disables some keyboard handling and the quitkey detection
	; is buried too deep in the patches. First time I see that.
	
	bsr	_patchkb
	
	bsr	_emu_copylock

	bsr	_detect_controller_types
	
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
		cmp.l	#142296,d0
		beq.b	_agaver
		cmp.l	#142296,d0
		beq.b	_cd32ver
		
		cmp.l	#222196,d0
		bne.b	_wrongver  ; only ECS version supported by this slave

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_agaver
	; print a custom message
	pea	_agaunsup_msg(pc)
	bra.b	custom_error
_cd32ver
	; print a custom message
	pea	_cd32unsup_msg(pc)

custom_error:
; checksum doesn't match, file corrupt
	pea	(TDREASON_FAILMSG).w
	move.l	_resload(pc),a0
	jmp	resload_Abort(a0)
	
	
; < d7: seglist

_patch_exe:
	moveq.l	#0,d2
	bsr	get_section

	lea	_pl_seg0_ecs(pc),a0
	jsr	resload_Patch(a2)

	move.b	controller_joypad_1(pc),d0
	beq.b	.nopad
	moveq.l	#0,d2
	bsr	get_section
	lea	_pl_seg0_ecs_cd32pad(pc),a0
	jsr	resload_Patch(a2)	
.nopad

	moveq.l	#1,d2
	bsr	get_section
	
	lea	_pl_seg1_ecs(pc),a0
	jsr	resload_Patch(a2)

	moveq.l	#2,d2
	bsr	get_section

	lea	_pl_seg2_ecs(pc),a0
	jsr	resload_Patch(a2)

	rts


; version 2 (ECS): 3 sections, copylock, code size: 222196

_pl_seg0_ecs:
	PL_START
	PL_P	$2cb48,sync_vpos_with_exact_d1
	PL_L	$15FC8,$70004E71		; VBR stuff
	PL_L	$154,$4E714E71			; force call to protection
	PL_IFC1
	; if set, set controller mode to 2-button joy
	PL_W	$180+2,1
	PL_ENDIF
	PL_P	$246C2,read_joypad_buttons_floppy
	PL_PS	$2460A,two_button_test_potgo
	PL_NOP	$23816,6	; don't clear $BFEC01 CIASDR
	PL_END
_pl_seg1_ecs:
	PL_START
	PL_L	$1F3E-$7C,$70004E71		; VBR stuff
	PL_END
_pl_seg2_ecs:
	PL_START
	PL_P	$0,_emu_copylock
	PL_END

_pl_seg0_ecs_cd32pad
	PL_START
	PL_IFC1
	PL_ELSE
	PL_W	$180+2,2		; CD32 controller by default, unless CUSTOM1 is set
	PL_ENDIF
	PL_END

sync_vpos_with_exact_d1:
.loop
	MOVE.L	4(A6),D0		;23aa4: 202e0004
	LSR.L	#8,D0			;23aa8: e088
	ANDI.W	#$01ff,D0		;23aaa: 024001ff
	sub.w	d1,d0
	beq.b	.out
	cmp.w	#1,d0
	beq.b	.out
	cmp.w	#-1,d0
	beq.b	.out
	BRA.S	.loop		;2cb50: 66f6
.out
	RTS				;2cb52: 4e75
	
	
	
_patchkb
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	movem.l	D0,-(A7)
	move.b	$bfec01,d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	bne.b	.zap
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
.zap
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0
	
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

_agaunsup_msg:
	dc.b	"This slave doesn't support the AGA version",0
_cd32unsup_msg:
	dc.b	"This slave doesn't support the CD32 version",0
	
;============================================================================

	END
