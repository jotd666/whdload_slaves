;*---------------------------------------------------------------------------
;  :Program.	DragonStrikeHD.asm
;  :Contents.	Slave for "DragonStrike"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: DragonStrikeHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"DragonStrike.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;CHIP_ONLY
;============================================================================

	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $60000
	ENDC


NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
STACKSIZE = 8000
CACHE

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulDivZero
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	whdload/kick13.s
	INCLUDE	ReadJoyPad.s
	
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
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
slv_name		dc.b	"Dragon Strike"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC

		dc.b	0
slv_copy		dc.b	"1990 Westwood / S.S.I",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"DStrike",0
_args		dc.b	10
_args_end
	dc.b	0
slv_config
    ;dc.b    "C1:X:Trainer:0;"
    dc.b    "C2:B:joypad controls;"		
    dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	bsr		_detect_controller_types
	
	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		; align exe memory on round value
		
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$20000-$1C808,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

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

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_end
		jsr	(_LVOIoErr,a6)
		pea	_program(pc)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		bra.b	_exit
_quit
		pea	TDREASON_OK
_exit
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_patchexe
	lea	_pl_main(pc),a0
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1
	jsr	resload_Patch(a2)
	rts

_pl_main
	PL_START
	PL_P	$B4,_quit	; original exit triggers access fault
	PL_NOP	$2206,2	; removes passwd protection (lockpick v2)
	PL_NOP	$BEC8,2
	PL_PS	$BECA,fix_access_fault
	
	PL_IFC2
	PL_PS	$ba9c,vbl_hook
	PL_PSS	$10968,read_joy1,4
	PL_PSS	$72C0,keyboard_emulation,4
	PL_NOP	$10a24,$C		; skip original fire read
	PL_ENDIF
	
	PL_END
	
keyboard_emulation
	TST.B	13859(A4)		;072c0: 4a2c3623
	BEQ.S	.1		;072c4: 6702
	CLR.L	D2			;072c6: 4282
.1
	or.l	keyboard_bits(pc),d2
	rts
	

vbl_hook
	moveq	#1,d0
	bsr	_read_joystick
	lea	joy1(pc),a5
	move.l	d0,(a5)
	lea	raw_joy1dat(pc),a5
	move.w	d1,(a5)
	
	MOVEA.L	A1,A5			;0ba9c: 2a49
	MOVE.L	4(A5),D0		;0ba9e: 202d0004
	rts
	
read_joy1
	moveq.l	#0,d1
	lea		keyboard_bits(pc),a0
	move.l	joy1(pc),d0
	move.l	d1,-(a7)

	btst	#JPB_BTN_BLU,d0
	beq.b	.no_w2
	bset	#12,d1
.no_w2
	btst	#JPB_BTN_RED,d0
	beq.b	.no_w1
	bset	#11,d1
.no_w1
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.no_faster
	bset	#5,d1
.no_faster
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.no_slower
	bset	#6,d1
.no_slower
	btst	#JPB_BTN_YEL,d0
	beq.b	.no_heal_knight
	bset	#9,d1
.no_heal_knight
	btst	#JPB_BTN_PLAY,d0
	beq.b	.no_heal_dragon
	bset	#10,d1
.no_heal_dragon
	; not enough buttons to map all keys
	; bit 22: check ointment
	; F1: $2000, F2: $10000, F3: $8000, F4: $4000
	
	; +green/third: directions now control lance
	btst	#JPB_BTN_GRN,d0
	beq.b	.no_green
	; green pressed: directions move the lance,	
	btst	#JPB_BTN_UP,d0
	beq.b	.no_up
	bset	#19,d1
.no_up
	btst	#JPB_BTN_LEFT,d0
	beq.b	.no_left
	bset	#21,d1
.no_left
	btst	#JPB_BTN_RIGHT,d0
	beq.b	.no_right
	bset	#22,d1
.no_right
	btst	#JPB_BTN_DOWN,d0
	beq.b	.no_down
	bset	#20,d1
.no_down

	move.l	d1,(a0)
	move.l	(a7)+,d1
	clr.w	d0		; yellow pressed: no joystick moves
	LEA	_custom,A0
	rts
	
.no_green
	move.l	d1,(a0)
	move.l	(a7)+,d1
	LEA	_custom,A0
	move.w	raw_joy1dat(pc),d0
	rts
	
	
fix_access_fault
	cmp.l	#0,a4
	bne.b	.ok
	add.l	#$9C,(a7)	; skip faulty routine (A4 = 0 -> A3 weird value)
	rts
.ok
	MOVEA.L	6(A4),A3		;0BEC8: 266C0006	; A4 = 0 sometimes
	MOVE	12(A3),D0		;0BECC: 302B000C
	rts

keyboard_bits
	dc.l	0
raw_joy1dat
	dc.w	0
	
;============================================================================

	END
