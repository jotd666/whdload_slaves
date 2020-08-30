;*---------------------------------------------------------------------------
; Program:	SuperfrogCD32.s
; Contents:	Slave for "Superfrog CD³²" (c) 1994 Team 17
; Author:	Codetapper of Action
; History:	03.05.01 - v1.0
;		         - Full load from HD
;		         - Loads and saves high scores automatically (unless you cheat!)
;		         - Load/Save high score menu options have been disabled (disk version)
;		         - Compatible with JST disk images (rename them to Disk.x)
;		         - Intro installed separately
;		         - All O/S code removed in CD³² version (no need for OSEmu!)
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

		IFD BARFLY
		OUTPUT	"SuperfrogCD32.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

BASEMEM		equ	$1f0000

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_NoKbd		;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_Data-_base		;ws_CurrentDir
		dc.w	_DoNotCache-_base	;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

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
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_name		dc.b	"Superfrog CD³²",0
_copy		dc.b	"1994 Team 17",0
_info		dc.b	"Installed by Codetapper/Action! & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		
		dc.b	10,-1,"Keys: Help - Skip current level            "

		dc.b	-1,"Keys: Help - Skip current level            "
		dc.b	10,"        F9 - Toggle infinite lives and time"
		dc.b	-1,"Thanks to Chris Vella for the disk version, and to"
		dc.b	10,"Carlo Pirri and Xavier Bodenand for the CD versions!"
		dc.b	0
_Data		dc.b	"data",0
_SuperfrogName	dc.b	"SuperfrogCD",0
_DoNotCache	dc.b	"(SFIntro)",0
_Highs		dc.b	"Superfrog.highs",0
_LastKeypress	dc.b	0
_CheatFlag	dc.b	0
_Registered	dc.b	0
_config
        dc.b    "C1:X:blue/second button jumps:0;"
        dc.b    "C2:X:preserve original level codes:0;"
		dc.b	0
		EVEN

;======================================================================
_Start						;a0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	lea	$8,a0
		lea	BASEMEM,a1
_Clear		clr.l	(a0)+
		cmp.l	a0,a1
		bgt	_Clear

		lea	_Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)

		bsr	_detect_controller_type
		
;		move.l	_Private3(pc),d2
;		tst.l	d2
;		ble	_NotRegistered

		lea	_Registered(pc),a0
		move.b	#-1,(a0)

_NotRegistered	lea	_SuperfrogName(pc),a0	;Load main file
		move.l	_GameAddress(pc),a1
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)
		
		move.l	a5,a0
		sub.l	a1,a1
		jsr	resload_Relocate(a2)

		move.l	a5,a1
		
		move.l	a1,a0			;Check we have the right
		add.l	#$d56c,a0		;loading address for OSEmu
		cmp.l	#$48e73c38,(a0)		;(check the ATN! decruncher
		bne	_wrongver		;is where it should be)

		lea	_PL_Game(pc),a0		;Patch second part
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		lea	_HighScoresAddy(pc),a0	;Save high score position
		move.l	a5,a1
		add.l	#$3606,a1
		move.l	a1,(a0)

		bsr	_LoadHighScores		;Load high scores

		move.l	a5,a0
		lea	BASEMEM-$1000,a1
		
		lea	$dff180,a0
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

		clr.l	($4).w			;Added for Project F fix
		jsr	(a5)			;Start game

		bra	_exit			;When user hits Escape

_PL_Game	PL_START
		PL_S	$178,6			;bset d3,$bfe201
		PL_R	$296			;Pretend VBR is 0
		PL_R	$2ca			;Get gb_ActiView, gb_copinit and gb_LOFlist
		PL_R	$2e8			;Restore view
		PL_R	$312			;Load blank view
		PL_P	$350,_OpenLibrary	;Open library and store in (a2)
		PL_I	$35a			;Infinite loop
		PL_NOP	$378,$4		;jsr _LVOAddIntServer(a6)
		PL_NOP	$398,$4		;jsr _LVORemIntServer(a6)
		PL_NOP	$4ae,$4		;Escape no longer quits game
		PL_B	$faa,$60		;Escape during game will not quit
		PL_IFC2
		PL_ELSE		
		PL_P	$29cc,_GetLevel		;Allow 0000xx codes to work!
		PL_ENDIF
		PL_P	$31b0,_CopyNameIn	;Copies name into high score table
		PL_PS	$7e14,_OpenDosLibrary	;Open dos library
		PL_W	$7e1a,$4e71
		PL_P	$b6ac,_Loader		;Load file a0 at a1
		PL_P	$d56c,_DecrunchATN	;ATN! decruncher
		PL_PS	$167d0,_Keybd
		PL_PS	$1cce8,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1cd00,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1cd44,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1cd5c,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1ce3e,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1ce56,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1ce82,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1ce9a,_AF_ProjectF	;Access fault in Project F

		PL_IFC1
		; this particular joydat read is used for jump, others, well
		; are used for other stuff... (maybe other directions, other parts of the game/menu)
        PL_PS	$011c16,read_joy1dat_d0
		PL_ENDIF
		PL_END

; thanks to robinsonb5@eab for the idea		
read_joy1dat_d0:
	movem.l	d1/a0,-(a7)
	move.l	buttons_state(pc),d0
	moveq.l	#0,d1
	move.w	$DFF00C,D1
	move.l	_GameAddress(pc),a0
	cmp.b	#7,$4813(a0)		; project-F ? don't do anything
	beq.b	.no_blue
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d1
	btst	#9,d1
	beq.b	.noneed
	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	move.l	d1,d0
	movem.l	(a7)+,d1/a0
	RTS

;======================================================================

_GetLevel	move.l	d2,-(sp)
		move.w	#'10',d2

.CheckCode	add.b	#1,d2			;d2 = Our code to check
		cmp.b	#'5',d2
		bne	.NotNextWorld
		add.w	#$100-4,d2		;'15' will become '21'

.NotNextWorld	adda.l	#10,a0
		cmpi.l	#$ffffffff,(a0)
		beq	.NoCodeFound
		cmp.l	(a0),d0
		bne	.CheckNewCode
		cmp.w	(4,a0),d1
		beq	.CodeFound

.CheckNewCode	cmp.l	#'0000',d0		;Look for new codes in 000011 format
		bne	.CheckCode
		cmp.w	d1,d2
		bne	.CheckCode

.CodeFound	movea.l	(6,a0),a1
		jsr	(a1)

.NoCodeFound	movem.l	(sp)+,d2
		rts

;======================================================================

_Loader		movem.l	d0-d1/a0-a3,-(sp)
		move.l	a0,a3
_FindColon	move.b	(a0)+,d0
		cmp.b	#0,d0
		beq	_NotFound
		cmp.b	#':',d0
		beq	_LoadFile
		bra	_FindColon

_NotFound	move.l	a3,a0

_LoadFile	move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		movem.l	(sp)+,d0-d1/a0-a3
		rts

;======================================================================

_Keybd
	movem.l	d1,-(a7)
	movem.l	A0,-(a7)
	; here we're going to inject pause/esc too
	moveq.l	#0,d1
	bsr	_read_joystick_port_1
	lea	buttons_state(pc),a0
	move.l	d0,(a0)
	btst	#JPB_BTN_PLAY,d0
	bne.b	.pause
	; reset pause press flag
	lea	pause_pressed(pc),a0
	clr.b	(a0)
	bra.b	.nopause
.pause
	lea	pause_pressed(pc),a0
	tst.b	(a0)
	bne.b	.dont_press_again
.presspause
	move.b	#$19,d1	; code for "P"
	st.b	(a0)
.dont_press_again	
.nopause
	movem.l	(a7)+,a0
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	move.b	#$45,d1	; code for "ESC"
.noesc
	tst.b	d1
	beq.b	.nobuttonpress	; no button pressed, don't clobber keyboard
	move.w	d1,d0
	; inverse serialization of the keycode
	not.b	d0
	rol.b	#1,d0
	bra.b	.zpress
.nobuttonpress	; no button pressed, read keyboard
	move.b	$bfec01,d0		;Stolen code
.zpress
	movem.l	(a7)+,d1

		movem.l	d0-d1/a0-a2,-(sp)
		ror.b	#1,d0
		not.b	d0
		cmp.b	_keyexit(pc),d0
		beq	_exit

		move.b	_LastKeypress(pc),d1	;If the same key is still
		cmp.b	d0,d1			;down, do not do anything!
		beq	_SameKeyDown

		lea	_LastKeypress(pc),a0	;Store this keypress
		move.b	d0,(a0)

		cmp.b	#$5f,d0			;Check for Help to skip levels
		bne	.NoSkipLevel
		move.l	#1,$400+$e5a		;Skip level
		bra	_SetCheat

.NoSkipLevel	cmp.b	#$58,d0			;Check for F9 key
		bne	_SameKeyDown

		move.b	_Registered(pc),d0
		beq	_SameKeyDown

		move.l	_GameAddress(pc),a0
		eor.w	#$317c^$6004,$123a(a0)		;Set game over lives = -1 (move.w #$ffff,($58,a0))
		eor.l	#$53680058^$4e714e71,$1278(a0)	;Infinite lives (subq.w #1,($58,a0))
		move.l	#$121c8,d0
		eor.w	#$33fc^$6006,(a0,d0.l)		;Set game over lives = -1 (move.w #$ffff,$8082e)
		move.l	#$1251a,d0
		eor.l	#$532800a3^$4e714e71,(a0,d0.l)	;Infinite time (subq.b #1,($a3,a0))
		move.l	#$1cca8,d0
		eor.l	#$53680058^$4e714e71,(a0,d0.l)	;Infinite lives (subq.w #1,($58,a0))

_SetCheat	lea	_CheatFlag(pc),a0	;Set flag to say user is a cheat
		move.b	#-1,(a0)
		bsr	_FlushLibs

_SameKeyDown	movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_FlushLibs	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_FlushCache(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_OpenLibrary	move.l	#$f0000001,(a2)
		rts

;======================================================================

_OpenDosLibrary	move.l	#$f0000001,d0
		rts

;======================================================================

_AF_ProjectF	cmp.l	#0,a1
		blt	_Fault
		
		move.w	(a1),d0			;a1 is OK so do existing
		andi.w	#$3f,d0			;code
		rts

_Fault		addq	#4,sp			;Access fault occurred so 
		rts				;simply rts

;======================================================================

_CopyNameIn	move.b	(a0)+,d1
		cmpi.b	#'.',d1
		bne.b	_NotDot
		move.b	#' ',d1
_NotDot		move.b	d1,(a1)+
		subq.w	#1,d0
		bne.b	_CopyNameIn

		bsr	_SaveHighScores
		rts

;======================================================================

_LoadHighScores	movem.l	d0-d1/a0-a3,-(sp)
		move.l	_HighScoresAddy(pc),a1
		move.l	a1,a3
		lea	_Highs(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		tst.l	d0
		beq	_NoHighsFound

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	a3,a1			;a1 = Address
		move.l	a1,-(sp)
		jsr	resload_LoadFile(a2)
		move.l	(sp)+,a1
		bsr	_Encrypt

_NoHighsFound	movem.l	(sp)+,d0-d1/a0-a3
		rts

;======================================================================

_SaveHighScores	movem.l	d0-d1/a0-a2,-(sp)

		move.b	_CheatFlag(pc),d0	;Check if user is a cheat
		bne	_DoNotSave

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	_HighScoresAddy(pc),a1	;a1 = Address
		move.l  _resload(pc),a2
		bsr	_Encrypt		;Encrypt scores
		move.l	a1,-(sp)
		jsr	resload_SaveFile(a2)	;Save scores
		move.l	(sp)+,a1
		bsr	_Encrypt		;Decrypt scores

_DoNotSave	movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Encrypt	move.l	#160,d0			;Set d0 = length
		move.l	d0,-(sp)
.enc		eor.b	d0,(a1)+
		subq.l	#1,d0
		bne.s	.enc
		move.l	(sp)+,d0
		sub.l	d0,a1
		rts

;======================================================================
		include	ReadJoybuttons.s

buttons_state
	dc.l	0
pause_pressed
	dc.w	0
	
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
_resload	dc.l	0			;address of resident loader
_DosBase	dc.l	0
_GameAddress	dc.l	$400
_HighScoresAddy	dc.l	0
_Tags		dc.l	WHDLTAG_Private3
_Private3	dc.l	0
		dc.l	TAG_DONE
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
;_debug		pea	TDREASON_DEBUG
;		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		END
