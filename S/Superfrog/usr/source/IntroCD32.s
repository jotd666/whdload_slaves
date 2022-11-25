;*---------------------------------------------------------------------------
; Program:	IntroCD32.s
; Contents:	Slave for "Superfrog Intro CD남" (c) 1994 Team 17
; Author:	Codetapper of Action
; History:	03.05.01 - v1.0
;		         - Full load from HD
;		         - Loads and saves high scores automatically (unless you cheat!)
;		         - Load/Save high score menu options have been disabled (disk version)
;		         - Compatible with JST disk images (rename them to Disk.x)
;		         - Intro installed separately
;		         - All O/S code removed in CD남 version (no need for OSEmu!)
;		         - ATN! decruncher relocated to fast memory (x3)
;		         - Snoop bugs fixed (move.l #$ffffffff,$dff084)
;		         - Access faults in Project F fixed (x8)
;		         - Instructions included
;		         - Colour bit fixes (x2)
;		         - Trainer (press F9 to toggle infinite lives and time - this only works
;		           for registered users)
;		         - RomIcons, NewIcons and OS3.5 Colour Icons (created by me!)
;		         - Quit option (default key is 'F10')
;		08.05.04 - v1.1
;		         - Level codes can now be entered by typing 4 zeros, then the world, then
;		           the level number. eg. 000032 = World 3, level 2
;		                                 000064 = World 6, level 4
;		                                 000071 = Project F
;		         - Help key added to skip levels
;		         - Project F no-enemies bug fixed (huge thanks to Jeff!)
;		         - Added box icons (thanks to Captain^HIT!)
;		28.08.05 - v1.2
;		         - Supports the CD version released by Islona (thanks Xavier!)
;		         - CD32 version will no longer quit the entire game when you press Escape
; Requires:	WHDLoad 10+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
;---------------------------------------------------------------------------*

		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		INCLUDE	lvo/dos.i
		INCLUDE	lvo/exec.i

		IFD BARFLY
		OUTPUT	"SuperfrogIntroCD32.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

;OSEMU		equ	1			;Use OSEmu

		IFD	OSEMU
BASEMEM		equ	$130000
		ELSE
BASEMEM		equ	$120000
		ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	_DoNotCache-_base	;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

_name		dc.b	"Superfrog Intro CD남",0
_copy		dc.b	"1994 Team 17",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version 1.2 "
		INCBIN	"T:date"
		dc.b	-1,"Thanks to Chris Vella for the disk version, and to"
		dc.b	10,"Carlo Pirri and Xavier Bodenand for the CD versions!"
		dc.b	0
_data		dc.b	"data",0
_SuperfrogIntro	dc.b	"SfIntro",0
_DoNotCache	dc.b	"~(SFIntro)",0
		IFD	OSEMU
_OSEmuName	dc.b	"OSEmu.400",0
_DosName	dc.b	"dos.library",0
		ENDC
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	;lea	$8,a0
		;lea	BASEMEM,a1
_Clear		;clr.l	(a0)+
		;cmp.l	a0,a1
		;bgt	_Clear

		IFD	OSEMU
		lea	$400.w,a1		;Address
		lea	_OSEmuName(pc),a0	;Filename
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)

		move.l	_resload(pc),A0		;Initialise Emu module
		lea.l	_base(pc),A1
		jsr	$400.w

		move.w	#0,sr

		move.l	$4.w,a6			;Open dos library
		moveq	#0,d0
		lea	_DosName(pc),a1
		jsr	_LVOOpenLibrary(a6)

		lea	_DosBase(pc),a4		;Store dos base
		move.l	d0,(a4)
		move.l	d0,a6

		lea	_SuperfrogIntro(pc),a0	;Load main file
		move.l	a0,d1
		jsr	_LVOLoadSeg(a6)

		cmp.l	#0,d0			;Check for LoadSeg failure
		beq	_exit

		lsl.l	#2,d0
		move.l	d0,a1
		addq.l	#4,a1			;a1 = Start of game
		move.l	a1,a5
		
		ELSE
		lea	_SuperfrogIntro(pc),a0	;Load main file
		lea	$400,a1
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)
		
		move.l	a5,a0
		sub.l	a1,a1
		jsr	resload_Relocate(a2)

		pea	_Level2Inter(pc)	;Install keyboard routine
		move.l	(sp)+,$68

		move.l	a5,a1
		ENDC

		lea	_PL_Intro(pc),a0	;Patch intro
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	a5,a0
		lea	BASEMEM-$1000,a1
		
_AllowKeyboard	cmp.l	a0,a1
		ble	_KeyboardDone

		cmp.w	#$33fc,(a0)		;Check for move.w #$8xxx,$dff09a
		bne	_CheckNext		;and change it to move.w #$8xx8,$dff09a
		cmp.l	#$dff09a,4(a0)
		bne	_CheckNext
		move.w	2(a0),d0
		move.w	d0,d1
		and.w	#$8000,d1
		beq	_CheckNext
		or.w	#8,d0
		move.w	d0,2(a0)
		addq	#6,a0

_CheckNext	addq	#2,a0		
		bra	_AllowKeyboard

_KeyboardDone	lea	$dff180,a0
		moveq	#16-1,d0
_ClearPalette	move.w	#0,(a0)+
		dbf	d0,_ClearPalette

		move.l	#$fffffffe,$3fc
		move.l	#$3fc,$dff080

		move.l	_resload(pc),a2
		jsr	resload_FlushCache(a2)

		sub.l	a0,a0			;No command line
		moveq	#0,d0

		move.w	#$83d0,$dff096		;Turn on DMA

		jsr	(a5)			;Start game

		bra	_exit

_PL_Intro	PL_START
		IFD	OSEMU
		PL_R	$166			;Pretend VBR is 0
		PL_R	$b1fc			;move.w #$ffffffff,$dff084
		PL_P	$d09c,_DecrunchATN	;Decrunch ATN!
		ELSE
		PL_R	$c			;Open freeanim.library
		PL_R	$fe			;Pretend VBR is 0
		PL_R	$132			;Get gb_copinit and gb_LOFlist
		PL_R	$144			;Restore gb_copinit and gb_LOFlist
		PL_R	$168			;Blank view and WaitTOF
		PL_P	$1a0,_OpenLibrary	;Open library and store in (a2)
		PL_I	$1aa			;Infinite loop
		PL_R	$b194			;move.w #$ffffffff,$dff084
		PL_PS	$c41e,_OpenDosLibrary	;Open dos library
		PL_L	$c424,$4e714e71
		PL_R	$b1a0			;Restore system
		PL_P	$d034,_DecrunchATN	;Decrunch ATN!
		PL_END

;======================================================================

_EmptyDBF	movem.l	d0-d1,-(sp)
		moveq	#3-1,d1			;wait because handshake min 75 탎
.int2w1		move.b	(_custom+vhposr),d0
.int2w2		cmp.b	(_custom+vhposr),d0	;one line is 63.5 탎
		beq	.int2w2
		dbf	d1,.int2w1		;(min=127탎 max=190.5탎)
		movem.l	(sp)+,d0-d1
		rts

;======================================================================

_Level2Inter	movem.l	d0/a0,-(sp)
		lea	($BFE000).l,a0
		move.b	($D01,a0),d0
		btst	#3,d0
		beq.b	_NotKeybdInt
		clr.w	d0
		move.b	($C01,a0),d0
		bset	#6,$e01(a0)
		not.b	d0
		lsr.b	#1,d0
		cmp.b	_keyexit(pc),d0
		beq	_exit
		cmp.b	#$5f,d0
		bne	_NotKeyDown
_NotKeyDown	bsr	_EmptyDBF
		bclr	#6,$e01(a0)
_NotKeybdInt	movem.l	(sp)+,d0/a0
		move.w	#8,($DFF09C).l
		nop
		nop
		nop
		nop
		rte

;======================================================================

_OpenLibrary	move.l	#$f0000001,(a2)
		rts

;======================================================================

_OpenDosLibrary	move.l	#$f0000001,d0
		rts

		ENDC				;End of single file stuff

;======================================================================

_DecrunchATN	movem.l	d2-d5/a2-a4,-(sp)
		movea.l	a0,a3
		movea.l	a1,a4
		movea.l	a1,a5
		cmpi.l	#'ATN!',(a0)+
		bne.b	_ATN_6
		adda.l	(a0)+,a4
		adda.l	(a0)+,a3
		movea.l	a3,a2
		move.l	(a2)+,-(a0)
		move.l	(a2)+,-(a0)
		move.l	(a2)+,-(a0)
		move.l	(a2)+,d2
		move.w	(a2)+,d3
		bmi.b	_ATN_1
		subq.l	#1,a3
_ATN_1		lea	(-$1C,sp),sp
		movea.l	sp,a1
		moveq	#6,d0
_ATN_2		move.l	(a2)+,(a1)+
		dbra	d0,_ATN_2
		movea.l	sp,a1
		moveq	#0,d4
_ATN_3		tst.l	d2
		beq.b	_ATN_5
_ATN_4		move.b	-(a3),-(a4)
		subq.l	#1,d2
		bne.b	_ATN_4
_ATN_5		cmpa.l	a4,a5
		bcs.b	_ATN_8
		lea	($1C,sp),sp
		moveq	#-1,d0
		cmpa.l	a3,a0
		beq.b	_ATN_7
_ATN_6		moveq	#0,d0
_ATN_7		movem.l	(sp)+,d2-d5/a2-a4
		tst.l	d0
		rts

_ATN_8		add.b	d3,d3
		bne.b	_ATN_9
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_9		bcc.b	_ATN_21
		add.b	d3,d3
		bne.b	_ATN_10
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_10		bcc.b	_ATN_20
		add.b	d3,d3
		bne.b	_ATN_11
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_11		bcc.b	_ATN_19
		add.b	d3,d3
		bne.b	_ATN_12
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_12		bcc.b	_ATN_18
		add.b	d3,d3
		bne.b	_ATN_13
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_13		bcc.b	_ATN_14
		move.b	-(a3),d4
		moveq	#3,d0
		bra.b	_ATN_22

_ATN_14		add.b	d3,d3
		bne.b	_ATN_15
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_15		addx.b	d4,d4
		add.b	d3,d3
		bne.b	_ATN_16
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_16		addx.b	d4,d4
		add.b	d3,d3
		bne.b	_ATN_17
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_17		addx.b	d4,d4
		addq.b	#6,d4
		moveq	#3,d0
		bra.b	_ATN_22

_ATN_18		moveq	#5,d4
		moveq	#3,d0
		bra.b	_ATN_22

_ATN_19		moveq	#4,d4
		moveq	#2,d0
		bra.b	_ATN_22

_ATN_20		moveq	#3,d4
		moveq	#1,d0
		bra.b	_ATN_22

_ATN_21		moveq	#2,d4
		moveq	#0,d0
_ATN_22		moveq	#0,d5
		move.w	d0,d1
		add.b	d3,d3
		bne.b	_ATN_23
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_23		bcc.b	_ATN_26
		add.b	d3,d3
		bne.b	_ATN_24
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_24		bcc.b	_ATN_25
		move.b	(_ATN_36,pc,d0.w),d5
		addq.b	#8,d0
		bra.b	_ATN_26

_ATN_25		moveq	#2,d5
		addq.b	#4,d0
_ATN_26		move.b	(_ATN_37,pc,d0.w),d0
_ATN_27		add.b	d3,d3
		bne.b	_ATN_28
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_28		addx.w	d2,d2
		subq.b	#1,d0
		bne.b	_ATN_27
		add.w	d5,d2
		moveq	#0,d5
		movea.l	d5,a2
		move.w	d1,d0
		add.b	d3,d3
		bne.b	_ATN_29
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_29		bcc.b	_ATN_32
		add.w	d1,d1
		add.b	d3,d3
		bne.b	_ATN_30
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_30		bcc.b	_ATN_31
		movea.w	(8,a1,d1.w),a2
		addq.b	#8,d0
		bra.b	_ATN_32

_ATN_31		movea.w	(a1,d1.w),a2
		addq.b	#4,d0
_ATN_32		move.b	($10,a1,d0.w),d0
_ATN_33		add.b	d3,d3
		bne.b	_ATN_34
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_34		addx.l	d5,d5
		subq.b	#1,d0
		bne.b	_ATN_33
		addq.w	#1,a2
		adda.l	d5,a2
		adda.l	a4,a2
_ATN_35		move.b	-(a2),-(a4)
		subq.b	#1,d4
		bne.b	_ATN_35
		bra.w	_ATN_3

_ATN_36		dc.b	6
		dc.b	10
		dc.b	10
		dc.b	$12
_ATN_37		dc.b	1
		dc.b	1
		dc.b	1
		dc.b	1
		dc.b	2
		dc.b	3
		dc.b	3
		dc.b	4
		dc.b	4
		dc.b	5
		dc.b	7
		dc.b	14

		EVEN

;======================================================================
_resload	dc.l	0		;address of resident loader
_DosBase	dc.l	0
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts
		END
