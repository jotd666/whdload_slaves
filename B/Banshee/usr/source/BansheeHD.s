;*---------------------------------------------------------------------------
;  :Program.	BansheeHD.asm
;  :Contents.	Slave for "Banshee"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BansheeHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;				05.04.2026	Trainer added
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"HD2:util/dev/whdload/banshee/Banshee.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

SEGTRACKER
;CHIP_ONLY
;============================================================================

CHIPMEMSIZE	= $1FF000
	IFD		CHIP_ONLY
FASTMEMSIZE	= $0000
	ELSE
FASTMEMSIZE = $80000	
	ENDC
	
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
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
;STACKSIZE = 10000
CACHE
BOOTDOS
HISCORE_LEN = $F0
DUMMY_CD_DEVICE = 1
USE_DISK_NONVOLATILE_LIB = 1

slv_Version	= 19
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_Req68020|WHDLF_ReqAGA|WHDLF_NoKbd
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	kick31cd32.s
IGNORE_JOY_DIRECTIONS
	include	ReadJoyPad.s

;============================================================================



_assign_1
	dc.b	"Banshee1",0
_assign_2
	dc.b	"Banshee2",0
_assign_3
	dc.b	"Banshee3",0
_assign_4
	dc.b	"Banshee4",0
_assign_5
	dc.b	"Bans1",0
	
	IFD BARFLY
	IFND	.passchk
;	 DOSCMD	 "WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"4.0"
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

slv_name		dc.b	"Banshee AGA/CD³²"
		IFD		CHIP_ONLY
		dc.b	" (debug/chip mode)"
		ENDC
		dc.b	0
slv_copy		dc.b	"1992 Core Design",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"Trainer added by Arise from Decay",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
		dc.b	"C1:X:Unlimited Energy:0;"
        dc.b    "C1:X:Unlimited Lives:1;"
		dc.b    "C1:X:Unlimited Loops:2;"
		dc.b	0
_intro:
	dc.b	"picture.exe",0

_program:
	dc.b	"bans.exe",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

_bootdos
	clr.l	$0.W


	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

	;for CD³² version
	
		bsr	_patch_cd32_libs
		bsr	_detect_controller_types
		
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
		lea	_assign_3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_5(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

 	;load intro
		lea	_intro(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe
	;load main
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)



_emu_copylock:
	movem.l	D1/A0,-(A7)
	move.l	8(A7),A0	; return address: copylock start
	lea	$794(A0),A0	; aera to change (copylock+$79A)

	MOVE	#$0019,D1		;4DC: 323C0019
	MOVE.L	#$0005DB42,D0		;4E0: 203C0005DB42
.LAB_0002:
	MULU	#$0011,D0		;4E6: C0FC0011
	ADDQ.L	#1,D0			;4EA: 5280
	MOVE	D0,(A0)+		;4EC: 30C0
	DBF	D1,.LAB_0002		;4EE: 51C9FFF6


	move.l	#$CF3EED9B,D0
	move.l	D0,(A3)
	movem.l	(A7)+,D1/A0
	rts


; patch according to version

VERSION_PL:MACRO
.\1
	lea	pl_\1(pc),a0
	bra.b	.out
	ENDM

get_version:
	movem.l	d0-d1/a1,-(a7)
	lea	.progname(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#154408,D0
	beq.b	.floppy

	cmp.l	#149524,d0
	beq.b	.cd32


	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	VERSION_PL	floppy
	VERSION_PL	cd32
	nop
.out
	movem.l	(a7)+,d0-d1/a1
	rts
.progname
	dc.b	"bans.exe",0
	even

pl_floppy:
	PL_START
	; fix access faults
	PL_PS	$0111a6,_move_a4_d0
	PL_PS	$011d1e,_move_a4_d3
	PL_PS	$011ce0,_move_a4_d6
	PL_PS	$0172d0,_move_a4_d6
	PL_PS	$0172fc,_move_a4_d6
	PL_PS	$01735c,_move_a4_d6
	PL_PS	$01828c,_move_a4_d6
	PL_PS	$00857a,move_potgo_d2
	PL_PS	$07299e,_emu_copylock
	PL_L	$07299e+6,$600008AC		; skip to copylock end
	PL_IFC1X	1
	PL_NOPS $104ac,2		;lives
	PL_ENDIF
	PL_IFC1X	2
	PL_NOPS $d78c,2			;loops
	PL_ENDIF
	PL_IFC1X	0
	PL_NOPS	$1088a,2
	PL_NOPS $10898,2		;energy
	PL_NOPS	$108a6,2
	PL_NOPS	$108b8,2
	PL_NOPS	$108c0,2
	PL_ENDIF
	PL_END
	
pl_cd32:
	PL_START
	; fix access faults
	PL_PS	$10888,_move_a4_d0
	PL_PS	$11400,_move_a4_d3
	PL_PS	$113c2,_move_a4_d6
	PL_PS	$16962,_move_a4_d6
	PL_PS	$1698e,_move_a4_d6
	PL_PS	$169ee,_move_a4_d6
	PL_PS	$1791e,_move_a4_d6
	PL_PS	$07c2a,move_potgo_d2
	
	; direct patch of joyport read
	; lowlevel library code is legacy plus for some
	; reason now it doesn't work except for buttons.
	; replacing by whdload v19 ReadJoyPad which has
	; the same interface directly at the location
	; where the executable calls it
	PL_P	$632,read_joy_port
	PL_PSS	$638,read_joy_port,4

	PL_IFC1X	1
	PL_NOPS $00fb8e,2		;lives
	PL_ENDIF
	PL_IFC1X	2
	PL_NOPS $00ce6e,2			;loops
	PL_ENDIF
	PL_IFC1X	0
	PL_NOPS	$0ff6c,2
	PL_NOPS $0ff7a,2		;energy
	PL_NOPS	$0ff88,2
	PL_NOPS	$0ff9a,2
	PL_NOPS	$0ffa2,2
	PL_ENDIF
	PL_END

read_joy_port:
	move.l	A2,-(A7)	
	move.l	_resload(pc),a2
	moveq	#0,d2
	move.b	d0,d2
	jsr		resload_ReadJoyPort(a2)
	move.l	(A7)+,A2
	rts
	
; < d7: seglist

_patch_exe:
	movem.l	D0-D1/A0-A2,-(A7)	

	bsr	install_joy_reader

	move.l	_resload(pc),a2
	bsr		get_version
	move.l	d7,a1
	jsr		(resload_PatchSeg,a2)
	
	movem.l	(A7)+,D0-D1/A0-A2
	rts




MOVEA4DX:MACRO
_move_a4_d\1:
	move.w	$8A(A0),D\1
	cmp.l	#-1,A4	; does the game try to access $FFFFFFFF address?
	beq.b	.avoid
	cmp.w	(A4),D\1
	rts
.avoid
	cmp.l	#0,A4	; so Z flag is cleared
	rts
	ENDM

	MOVEA4DX	0
	MOVEA4DX	3
	MOVEA4DX	6

install_joy_reader
	lea	old_int_3(pc),a0
	move.l	$6C.W,(a0)
	lea	joy_reader(pc),a0
	move.l	a0,$6C.W
	rts

joy_reader
	btst	#5,$dff01f
	beq.b	.skip

	; only VBL interrupt is of interest here

	movem.l	d0/a0,-(a7)
	bsr		_joystick
	lea	dff016_value(pc),a0
	move.l	joy1(pc),d0
	st.b	(a0)
	btst	#JPB_BTN_BLU,d0	; port 1
	bne.b	.no1
	bclr	#6,(a0)
.no1
	move.l	joy0(pc),d0
	btst	#JPB_BTN_BLU,d0	; port 1
	bne.b	.no0
	bclr	#2,(a0)
.no0
	movem.l	(a7)+,a0/d0
.skip
	move.l	old_int_3(pc),-(a7)
	rts
old_int_3
	dc.l	0
dff016_value
	dc.w	0

_save_hiscore:
	clr.l	(A0)		; stolen code

	tst.w	D1
	bne.B	.skip

	movem.l	D0-D1/A0-A2,-(A7)
	move.l	_custom1(pc),d0
	bne.b	.train
	move.l	_score_address(pc),A1
	move.l	#HISCORE_LEN,D0
	lea	_savename(pc),A0
	move.l	_resload(pc),A2
	jsr	resload_SaveFile(a2)
.train:
	movem.l	(A7)+,D0-D1/A0-A2
.skip
	rts

_load_hiscore:
	movem.l	D0-D1/A0-A2,-(A7)
	move.l	_score_address(pc),A1
	move.l	#HISCORE_LEN,D0
	lea	_savename(pc),A0
	move.l	_resload(pc),A2
	jsr	resload_LoadFile(a2)

	movem.l	(A7)+,D0-D1/A0-A2
	rts


move_potgo_d2:
	move.b	dff016_value(pc),D2
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
	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)

	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
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


_score_address:
	dc.l	0
_savename:
	dc.b	"banshee.hi",0
	even
_scorebuffer:
	dc.b	"SHIT"	; invalid hiscore
	ds.b	HISCORE_LEN-4,0


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
