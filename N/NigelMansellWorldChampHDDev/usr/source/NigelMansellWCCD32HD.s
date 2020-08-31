;*---------------------------------------------------------------------------
;  :Program.	NigelMansellWCHD.asm
;  :Contents.	Slave for "NigelMansellWC"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: NigelMansellWCHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"NigelMansellWCCD32.slave"
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
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
;INITAGA
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
BLACKSCREEN

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


DUMMY_CD_DEVICE = 1
;USE_DISK_LOWLEVEL_LIB	; can't use without fix: game refuses to work without joypad
;USE_DISK_NONVOLATILE_LIB

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	incbin	"slave_version"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM


_assign1
	dc.b	"CD0",0
_assign2
	dc.b	"mansell",0

slv_name		dc.b	"Nigel Mansell World Champion CD³²",0
slv_copy		dc.b	"1992 Gremlin",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"CUSTOM1=1 to keep control with joypad",10,10
		dc.b	"CUSTOM2=[1-7] with CUSTOM1=0 to set control method",10,10
		dc.b	"Version "
		DECL_VERSION		
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_intro:
	dc.b	"loader1",0
_program:
	dc.b	"mansell",0
_args		dc.b	10
_args_end
	dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload),a2		;A2 = resload

	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	bsr	openwindow	; without this, there is no display!

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

		bsr	_patch_cd32_libs
	;load intro
	IFEQ	1
		lea	_intro(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe
	ENDC
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

patch_main
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_main(pc),a0
	move.l	_custom1(pc),d0
	bne.b	.nocontrolpatch
	lea	pl_control(pc),a0
.nocontrolpatch
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)	
	rts

;	1:CD32_Controller		;11556: 00011576
;	2:JoystickController	;1155A: 0001191E
;	3:JoystickController	;1155E: 0001191E
;	4:KeyboardController	;11562: 00011986
;	5:JoyStick2Controller	;11566: 0001194E
;	6:MouseController		;1156A: 000119CE
;	7:FreeWheelController	;1156E: 00011A06

pl_control
	PL_START

	; workaround for lowlevel ReadJoyPort

	PL_L	$11A6E,JP_BUTTON_MASK&~JPF_BUTTON_BLUE
	PL_L	$1BB2A,JP_BUTTON_MASK&~JPF_BUTTON_BLUE
;	PL_L	$1BBDC,JP_BUTTON_MASK&~JPF_BUTTON_BLUE

	; default control method

	PL_PS	$1151A,select_control_method

	PL_NEXT	pl_main

pl_main
	PL_START

	; proper keyboard ack

	PL_PS	$10CF4,kb_delay
	PL_S	$10D08,6
	PL_S	$10D28,6
	PL_END


select_control_method
	move.l	_custom2(pc),d0
	beq.b	.joy
	cmp.w	#8,d0
	bcc.b	.joy
	rts
.joy
	move.w	#1,d0	; joystick forced
	rts

kb_delay:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
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

openwindow:
	lea	.intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	lea	.newscreen_struct(pc),A0
	jsr	_LVOOpenScreen(A6)

	lea	.newwindow_struct(pc),A0
	move.l	D0,$1E(A0)	; nw_Screen

	jsr	_LVOOpenWindow(A6)
	rts

.newscreen_struct:
	dc.w	0,0
	dc.w	320,200
	dc.w	2
	dc.b	1,0
	dc.W	0
	dc.W	0
	dc.l	0	; no font
	dc.l	0	; no title
	dc.l	0
	dc.l	0
.newwindow_struct:
	dc.w	0,0
	dc.w	320,200
	dc.w	0
	dc.l	0,0,0,0
	dc.l	0	; no title
	dc.l	0,0
	dc.w	10,10,320,200
	dc.w	0

.intname:
	dc.b	"intuition.library",0
	even

; < d7: seglist



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

	;patch here
	cmp.l	#0,A5
	beq.b	.skip

	move.l	d7,-(a7)
	add.l	d7,d7	
	add.l	d7,d7	
	jsr	(a5)
	move.l	(a7)+,d7
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

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

_tag
		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

;============================================================================

	END
