;*---------------------------------------------------------------------------
; Program:	Superfrog.s
; Contents:	Slave for "Superfrog" (c) 1993 Team 17
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
; Info:		$8000a = World
; 		$8000e = Level
; 		$82432 = Look for level code
;---------------------------------------------------------------------------*

		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"Superfrog.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;CHIP_ONLY = 1
	IFD	CHIP_ONLY
BASEMEMSIZE = $100000
EXTMEMSIZE = 0
	ELSE
BASEMEMSIZE = $80000
EXTMEMSIZE = $80000
	ENDC
;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError|WHDLF_NoKbd	;ws_flags
		dc.l	BASEMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXTMEMSIZE			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config
		
_config
        dc.b    "C2:B:blue/second button jumps;"
		dc.b	0

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.5"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
;============================================================================

_name		dc.b	"Superfrog"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP mode)"
	ENDC
	dc.b	0
_copy		dc.b	"1993 Team 17",0
_info		dc.b	"Installed by Codetapper/Action! & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		
		dc.b	10,-1,"Keys: Help - Skip current level            "
		dc.b	10,"        F9 - Toggle infinite lives and time"
		dc.b	-1,"Thanks to Chris Vella for the disk version, and to"
		dc.b	10,"Carlo Pirri and Xavier Bodenand for the CD versions!"
		dc.b	0
_Highs		dc.b	"Superfrog.highs",0
_DiskNumber	dc.b	1
_LastKeypress	dc.b	0
_CheatFlag	dc.b	0

		EVEN

;======================================================================
_Start						;a0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	lea	_Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		
		bsr	_detect_controller_types


_NotRegistered	lea	_Track0(pc),a0
		lea	$10000,a1
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_Decrunch(a2)

		lea	_PL_Boot(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		jmp	4(a5)

_PL_Boot	PL_START
		PL_W	$2a,$200		;Colour bit fix
		PL_NOP	$6c,2		;Trap #0
		PL_NOP	$9c,4		;Don't load track 1
		PL_PS	$a0,_SetA0ToTrack1	;lea $7c180,a0
		PL_P	$cc,_PatchTrack1	;jmp $7c180
		PL_P	$534,_Loader		;Patch Rob Northen loader
		PL_P	$6da,_DecrunchATN	;Decrunch ATN!
		PL_END

;======================================================================

_PatchTrack1	movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_Track1(pc),a0
		lea	$7c180,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2

		IFD	CHIP_ONLY
		lea	$80000,a1		;Expansion memory
		ELSE
		move.l	_expmem(pc),a1
		ENDC
		;Further expansion memory
        ;only useful to avoid loading
		sub.l	a2,a2			
		lea	$80000,sp
		jmp	$7c180

_PL_Track1	PL_START
		PL_P	$3378,_Main		;Patch main game
		PL_P	$33a4,_DecrunchATN	;Decrunch ATN!
		PL_P	$3680,_Loader		;Patch Rob Northen loader
		PL_END

;======================================================================

_Main		movem.l	d0-d1/a0-a2,-(sp)

		clr.l	($4).w			;Added for Project F fix

		lea	$40DD(a1),a2
		lea	current_level_address(pc),a0
		move.l	a2,(a0)
		
		lea	_PL_Main(pc),a0		;Patch main game
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		bsr	_LoadHighScores		;Load high scores

		movem.l	(sp)+,d0-d1/a0-a2

		sub.l	a2,a2			;Stolen code
		jmp	(a1)

_PL_Main	PL_START
		PL_P	$2444,_GetLevel		;Allow 0000xx codes to work!
		PL_R	$281e			;Built in load/save high scores in menu
		PL_P	$2c12,_CopyNameIn	;Copies name into high score table
		PL_P	$b098,_Loader		;Patch Rob Northen loader
		PL_L	$baac,$70004e75		;Check for disk in drive
		PL_P	$ce58,_DecrunchATN	;Decrunch ATN! in fastmem
		PL_L	$11bb6,$3fc		;move.l #$ffffffff,$dff084
		PL_PS	$16008,_Keybd		;Detect quit key
		PL_PS	$1c514,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1c52c,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1c570,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1c588,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1c66a,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1c682,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1c6ae,_AF_ProjectF	;Access fault in Project F
		PL_PS	$1c6c6,_AF_ProjectF	;Access fault in Project F

		; a lot of joystick reads...
		; one of them (to d0) is used to control the green ball
		; we must not change that
		
;        PL_PS	$0015d6,read_joy1dat_d6
;        PL_PS	$0017bc,read_joy1dat_d6
;        PL_PS	$0017e6,read_joy1dat_d6
;        PL_PS	$0017f6,read_joy1dat_d6
;        PL_PS	$001822,read_joy1dat_d6
;        PL_PS	$00199a,read_joy1dat_d6
;        PL_PS	$0019bc,read_joy1dat_d6
;        PL_PS	$0019cc,read_joy1dat_d6
;        PL_PS	$0019ee,read_joy1dat_d6

        ;PL_PS	$001590,read_joy1dat_d0
        ;PL_PS	$0046a8,read_joy1dat_d0
        ;PL_PS	$005f52,read_joy1dat_d0
        ;PL_PS	$005f9a,read_joy1dat_d0
        ;PL_PS	$008160,read_joy1dat_d0
        ;PL_PS	$00e13e,read_joy1dat_d0
;        PL_PS	$00fe42,read_joy1dat_d7


;        PL_PS	$011210,read_joy1dat_d0
;        PL_PS	$011322,read_joy1dat_d0

		PL_IFC2
		; this/those particular joydat read is used for jump, others, well
		; are used for other stuff... (maybe other directions, other parts of the game/menu)
		
        PL_PS	$0114c8,read_joy1dat_d0		; one of those 2 control higher jump (on presse)
        PL_PS	$011374,read_joy1dat_d0
        PL_PS	$011a42,read_joy1dat_d0 	; this one controls initial jump
		PL_ENDIF
		
		PL_END


; thanks to robinsonb5@eab for the idea		
read_joy1dat_d0:
	movem.l	d1/a0,-(a7)
	move.l	buttons_state(pc),d0
	moveq.l	#0,d1
	move.w	$DFF00C,D1
	move.l	current_level_address(pc),a0
	cmp.b	#7,(a0)		; project-F ? don't do anything
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

_Keybd
	movem.l	d1,-(a7)
	movem.l	A0,-(a7)
	; here we're going to inject pause/esc too
	moveq.l	#0,d1
    moveq.l #1,d0
	bsr	_read_joystick
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

	IFD	CHIP_ONLY
	lea	$80000,a1		;Expansion memory
	ELSE
	move.l	_expmem(pc),a1
	ENDC

	move.b	_LastKeypress(pc),d1	;If the same key is still
	cmp.b	d0,d1			;down, do not do anything!
	beq	_SameKeyDown

	lea	_LastKeypress(pc),a0	;Store this keypress
	move.b	d0,(a0)

	cmp.b	#$5f,d0			;Check for Help to skip levels
	bne	.NoSkipLevel
	move.l	#1,$a06(a1)
	bra	_SetCheat

.NoSkipLevel	cmp.b	#$58,d0			;Check for F9 key
	bne	_SameKeyDown


	;Trainer options: $876-$879: Time remaining as ASCII
	;                      $82e: Lives
	;                      $834: Score


	eor.w	#$317c^$6004,$de6(a1)		;Set game over lives = -1 (move.w #$ffff,$8082e) $317c $ffff $0058
	eor.l	#$53680058^$4e714e71,$e24(a1)	;Infinite lives (subq.w #1,($58,a0))
	add.l	#$11000,a1	; a1 = $91000
	eor.w	#$33fc^$6006,$a1a(a1)		;Set game over lives = -1 (move.w #$ffff,$8082e) $33fc $ffff $0008 $082e
	eor.l	#$532800a3^$4e714e71,$d6a(a1)	;Infinite time (subq.b #1,($a3,a0))              $5328 $00a3
	add.l	#$b000,a1
	eor.l	#$53680058^$4e714e71,$4D4(a1)    ; $9c4d4	;Infinite lives (subq.w #1,($58,a0))

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

_Loader		movem.l	d1-d2/a0-a2,-(sp)
                move.l  _resload(pc),a2		;a0 = dest address
		mulu	#$200,d1		;offset (sectors)
		mulu	#$200,d2		;length (sectors)
		exg.l	d1,d0			;d0 = offset (bytes)
		exg.l	d2,d1			;d1 = length (bytes)

		cmp.l	#$efc00,d0		;If game loads disk ID sector
		bne	_LoadData		;then change to that disk
		cmp.l	#$200,d1		;until it swaps.
		bne	_LoadData
		lea	_DiskNumber(pc),a1
		addq	#1,d2
		move.b	d2,(a1)

_LoadData	moveq	#0,d2			;d2 = disk
		move.b	_DiskNumber(pc),d2
		jsr	resload_DiskLoad(a2)	;a0 = destination
		movem.l	(sp)+,d1-d2/a0-a2
		moveq	#0,d0
		rts

;======================================================================

_SetA0ToTrack1	lea	_Track1(pc),a0
		rts

current_level_address:
	dc.l	0
buttons_state
	dc.l	0
pause_pressed
	dc.w	0
	
;======================================================================
get_score_addr
	IFD	CHIP_ONLY
	lea	$80000,a1		;Expansion memory
	ELSE
	move.l	_expmem(pc),a1
	ENDC
	add.l	#$2f90,a1
	rts

_LoadHighScores	movem.l	d0-d1/a0-a3,-(sp)
		bsr	get_score_addr
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
		bsr	get_score_addr
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
_Tags		dc.l	WHDLTAG_Private3
_Private3	dc.l	0
		dc.l	TAG_DONE
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
IGNORE_JOY_DIRECTIONS
			include	ReadJoyPad.s
			
_Track0		dc.l	$524E4301,$E00,$A63,$8353B84C,$12011
		dc.l	$192AB366,$36343433,$44544862,$A8EE6C39,$E0456100
		dc.l	$1F443FA,$1E222BC,$400,$33FC40D9,$FEDFF09A
		dc.l	$23FC7FFF,$839934B4,$41F9CAAC,$3F420FC,$10058C9
		dc.l	$80BCFF97,$AFED137,$28688042,$795594F1,$800B2B81
		dc.l	$D096415E,$1A922050,$D1DD0E07,$D045FA02,$40248895
		dc.l	$CA2823CA,$6B37804E,$40BB8F74,$E1DB0FA0,$2E4809C5
		dc.l	$66228842,$80323C00,$B34363C,$5EF8352A,$7C18043
		dc.l	$68443685,$4967FA0,$ABEF08F,$22C1B0B,$37C207A
		dc.l	$126221E,$2496AE16,$4E1D4E42,$4042414E,$3C84D2E8
		dc.l	$6433F45E,$4C7C9D09,$A8E93E01,$E4D25520,$843AF00
		dc.l	$D2310648,$40155902,$26791C8E,$DA0C3900,$44CA7906
		dc.l	$66F623C8,$866260EE,$120410C,$1228920,$1429148
		dc.l	$24264824,$124A2889,$442A5022,$91522C2E,$4824585A
		dc.l	$12893032,$44226062,$91483436,$6824126A,$3889443A
		dc.l	$70229172,$3C3E4824,$787A4AD1,$92A6A0,$8E948100
		dc.l	$90C4C1D6,$EA9400D0,$10823BA,$A4E1B02,$FF0180
		dc.l	$4440182,$FFF00E0,$21E6E274,$60F0DD3B,$D5444630
		dc.l	$3A4C4F41,$4AEB002C,$7904203C,$C88B0022,$4B24DFE8
		dc.l	$4EAEFF3A,$3AE42E67,$A9105347,$672CDCAA,$15CD500
		dc.l	$2F0799C9,$2E1F0280,$FFF8760E,$4A8067D8,$41FAFFA2
		dc.l	$20806006,$588FB568,$FE86DF6A,$32FFC5AA,$D3223AFF
		dc.l	$66B2D003,$3D5A7449,$4E75301F,$221F241F,$2EBA8B0A
		dc.l	$2F022F01,$3F004E73,$EE30879C,$FFC30386,$CC008156
		dc.l	$D93A33C1,$43EF2D7F,$F0CB1F2D,$28F4F49F,$48E73C38
		dc.l	$26482849,$2A490C98,$41544E21,$663ED9D8,$D7D8244B
		dc.l	$211A674C,$241A361A,$6B02538B,$4FEFFFE4,$224F7006
		dc.l	$22DA51C8,$FFFC26D3,$78B5BF82,$67061923,$538266FA
		dc.l	$BBCC6514,$7B4E001C,$70FFB1CB,$67027000,$4CDF1C3C
		dc.l	$4A4ECCD6,$3660416,$23D70364,$642D7354,$CBDC4432
		dc.l	$F734E6CF,$6182370,$3603A30,$3FD90489,$865C0456
		dc.l	$C2167805,$10787572,$2600A78,$3700160,$4786EB8
		dc.l	$7A003200,$B96516EE,$AD081A3B,$6A5000,$D1E27A02
		dc.l	$580010B2,$F3623CE8,$D5425300,$66F2D445,$36F42445
		dc.l	$3001EE6A,$1AD2413F,$C347110,$86DD606,$54270031
		dc.l	$44EF19F5,$DB8539CE,$524AD5C5,$D5CC1922,$530466FA
		dc.l	$B6F9EA06,$A0A1201,$79730203,$3040405,$70E48E7
		dc.l	$FFFE2849,$26492018,$C156803,$F366915C,$E0E3EF67
		dc.l	$8D08049,$67D1C060,$F42E182C,$7E78F9F,$C7504822
		dc.l	$4F2A4FF4,$CDA93722,$C022CBD7,$C0538666,$F03A1A22
		dc.l	$481CA,$FAE7D281,$97344EBB,$CA6266EC,$2412962E
		dc.l	$89442A36,$2291324C,$58482422,$1E12891A,$16443A12
		dc.l	$603B70DC,$C470014E,$757000F0,$A5152C6D,$D63A7391
		dc.l	$2CD85981,$538066F8,$4A816706,$429E6228,$CDDD13B
		dc.l	$F0D109FE,$52AF67DD,$3918E789,$26371808,$B35B2418
		dc.l	$D7B62800,$FB67F660,$E454C550,$4D5186DF,$C7598760
		dc.l	$270FF4C,$DF7FFFCD,$32A7F87F,$FC4E56FF,$DC380002
		dc.l	$440AD33D,$44C3333D,$41FFDE3D,$42FFE03D,$43FFE22D
		dc.l	$48FFE42D,$49FFE8E4,$580240C0,$52403D40,$FFECEF9A
		dc.l	$36026770,$701ED641,$B67C06E0,$6E5ADD90,$281CFB3
		dc.l	$E85482FC,$B0C01,$68B86702,$D241906A,$EE48BC6C
		dc.l	$F0B46EC2,$302EFA6A,$720B9240,$B26EB843,$6F04322E
		dc.l	$67ABF261,$5E662853,$BAE090AA,$37F2671E,$B23AE0F2
		dc.l	$E18801F4,$AE9D5D42,$C94BF0EC,$D1DDB8EE,$60BE2F74
		dc.l	$1CF4E903,$4C201F67,$207200EE,$F4ACE249,$C26F6AD2
		dc.l	$15DB22D,$FA2F4100,$284E5E4A,$803FFED9,$1678040F
		dc.l	$44FCA2A8,$FAF834C2,$367DB4E,$ABCA270,$1D0839C5
		dc.l	$9600BFE0,$167942A,$EE0EE84B,$ED04002A,$BCAA9F79
		dc.l	$3B7C4489,$457C9,$CA618522,$667419B8,$DD6DF467
		dc.l	$46C0FC04,$4041ED00,$6BA9750,$49F9D9AD,$1EC86664
		dc.l	$DDCCFA6F,$755E71A2,$37A84DFC,$DBC03C45,$204D99BD
		dc.l	$16EAE5F6,$6716E5E6,$449EEFF,$FE425461,$7C661AE4
		dc.l	$6E14701A,$DAA57402,$9BC8A2EC,$CC5B51CC,$FF38604C
		dc.l	$553A740A,$9D91303C,$40CE81,$7A616636,$5C386A67
		dc.l	$651CAFF,$E6602C9D,$3128662A,$E306EE66,$24B4D5CA
		dc.l	$6C1EB698,$656E1853,$3E5C2F4,$3D7C7D76,$97E766F6
		dc.l	$99207018,$91181B19,$C9BD98DC,$F8C1ADA3,$D3001770
		dc.l	$A2572008,$2C0F6701,$862C94A7,$4504154A,$904AAD67
		dc.l	$E8FA5AF2,$66BAA9E3,$B666B81D,$53B23602,$B628336D
		dc.l	$5C3C32D0,$86FAB640,$6C50658F,$5691FAFC,$70066AC
		dc.l	$D940323C,$4001932,$E96388C,$FA94B09F,$2B5AFF78
		dc.l	$57552A61,$30460722,$B51BE4D3,$C11E7330,$32C6B0C9
		dc.l	$98CC310E,$52261F39,$A6F82273,$4A5C7698,$FA220392
		dc.l	$4566336E,$200C2C0,$2FB81DF7,$C009F5FC,$B817FA55
		dc.l	$AB4D720A,$E4D641E8,$D08E2080,$51C98E70,$68E80861
		dc.l	$1A36A58D,$43562A34,$E04A48,$713083AB,$E048B02E
		dc.l	$72FFEFEE,$F8A41802,$80550281,$9AD1D080,$80815532
		dc.l	$610CDB26,$3061E016,$1E8E8372,$282F02E4,$495341BB
		dc.l	$EA2418B5,$6DAAFA24,$1F7BB059,$676652F0,$E0707F45
		dc.l	$E83A0626,$3C471D2F,$34241AC2,$83C483D2,$81828222
		dc.l	$C14B27F0,$4CDF070F,$B7C943F4,$1000337C,$67D524A8
		dc.l	$62801000,$96DE589E,$65B5956C,$F8B897E,$23480020
		dc.l	$78859CE2,$296A4080,$A9054084,$FAC9BC9E,$63017008
		dc.l	$298A941F,$660AB336,$5666F270,$FF3D5E42,$A00C957C
		dc.l	$119CB9BC,$24FB062E,$B904396F,$9E4A6EFF,$E26A1E72
		dc.l	$FF13C100,$BFD18059,$DC568001,$81EC9101,$C1FA402D
		dc.l	$FACFE908,$81000761,$D4767200,$C8AF208C,$92E7306E
		dc.l	$6C2AE414,$CAE39BD0,$C8E40830,$65C06CEF,$6A046132
		dc.l	$662AC087,$E24A7201,$9440670E,$834E4442,$70036150
		dc.l	$534266F8,$5AE778C1,$DC3183,$E035603A,$99000C98
		dc.l	$19200074,$559B9904,$9B79D50B,$ED5B261,$1EDB2CEE
		dc.l	$701E6010,$D53BA642,$6F0AD05C,$35E3042E,$B0E30A2A
		dc.l	$4A016B04,$880D49C,$13C056,$E6C09CDC,$201F603A
		dc.l	$61088143,$C978A760,$C30F1439,$53217F56,$B2D58257
		dc.l	$576932,$3BCFFB08,$9E4E67B2,$AF8239F1,$10024C9F
		dc.l	$672A7,$1E08CFBA,$BFDE0066,$F6A37089,$83BFE51C
		dc.l	$1B566718,$13FC831D,$6AD6CC59,$FD45705,$9DE2D5BD
		dc.l	$2DF72AD,$F2F4478,$96980F38,$6EA4E20F,$8A45FF80
		dc.l	$973BF183,$4A1C0F1C,$6183FFD,$7747E47F,$C0771E35
		dc.l	$801E1F1F,$1904DC1F,$9F9853C7,$60030378,$921B1B19
		dc.l	$9B831244,$7F001986,$18318018,$190D5E7D,$44C20F0F
		dc.l	$61FB180,$1F99998F,$19A04746,$253F00FF,$3E1F89FE
		dc.l	$5D28F2C3,$E11298E7,$807F1300,$703F010F,$17FD6F6
		dc.l	$1B3F0403,$E2371880,$9F11F029,$301F10F9,$E3B93084
		dc.l	$9A23F3DD,$887C58C0,$22F6C588,$FC240EF2,$DF881431
		dc.l	$8332B830,$87823C2,$1E3E0C9,$88709F3,$B0CC201C
		dc.l	$22015865,$311F820,$B01A82EE,$FACD501B,$57F06183
		dc.l	$BA149F,$EF800F1,$8A0C109,$32039FB0,$81156359
		dc.l	$78464FF9,$9BE84306,$F8842C3C,$C1E703F8,$19E24974
		dc.l	$FC018DC,$82D01C58,$84E0E39,$BEC374C5,$431090F9
		dc.l	$1260FF1,$C213E459,$FB59C3A2,$4F88DFE0,$9BF58F9
		dc.l	$E209F408,$F6C0F8D0,$430461F8,$F0D48A0E,$57B19F1
		dc.l	$BD21C1A5,$F892091A,$6181BED0,$133298F0,$30198311
		dc.l	$7400C325,$60A71360,$18031999,$818C8099,$DDE465E4
		dc.l	$9998C198,$F5642E61,$801818F1,$44BCF0F9,$6780C1A0
		dc.l	$16806F0,$A15D3AC0,$631990,$47C074F3,$FB768092
		dc.l	$8370F06A,$F998A10D,$6132F003,$18F8C4A0,$319810F0
		dc.l	$F19870F8,$31994813,$30F15B66,$2806EEA9,$90F0F881
		dc.l	$189412D0,$C751FFBE,$4E2BF25F,$460AE41B,$F0347DCC
		dc.l	$7B0DF004,$9E007FC0,$29EC8238,$24F21F82,$D896F40
		dc.l	$FC06E0BF,$A20113D0,$2916E004,$180F049,$4243F45
		dc.l	$C100F24B,$CDF33B6,$1B07972C,$E0C0038E,$8303E333
		dc.l	$E3688174,$C3E3E1E3,$E701C1E0,$C1E3E0D7,$1322F1E0
		dc.l	$C383455D,$3412137,$3007F060,$43F4DF35,$BE9406B8
		dc.l	$804F37F0,$F027D09F,$2493BE1D,$79F1E3F0,$1FF183AA
		dc.l	$A7A82B1,$F34BF0A2,$27D56FC5,$13E0B1F1,$9F408321
		dc.l	$E22BC303,$30304903,$E835349,$2309700,$808103F8
		dc.l	$10020118,$E200C331,$83330633,$2FADC333,$C29322F4
		dc.l	$30061E1,$F3230301,$E1564300,$E1E0F492,$F331F1F6
		dc.l	$1C06EB01,$81F300E3,$31E38046,$633181E3,$631F0E0
		dc.l	$61E330C0,$C80FFFA,$1FFF0AE,$723F000,$9F1F0F
		dc.l	$1FCF1FA0,$AFDF21C8,$308B6A86,$D5FFC000,$407CEE01
		dc.l	$9A7AC002,$80EB2C05,$60708,$8070909,$A080A0B
		dc.l	$C571ED6,$B7E25EFA,$2E1E9D68,$F7C4F7E9,0

_Track1		dc.l	'ATN!',$3AF4,$6B6,$A0800EA5,$4EF90633
		dc.l	$60A00FF,$F801FFF0,$1FFF001,$FFF001FF,$F001FFF0
		dc.l	$1FFF001,$FFF001FF,$F001FFF0,$1FFF001,$FFF001FF
		dc.l	$F001FFF0,$1FFF001,$FFF001FF,$F001FFF0,$1FFF001
		dc.l	$FFF001FF,$F001FFF0,$1FFF001,$FFF001FF,$F001FFF0
		dc.l	$1FFF001,$FFF001FF,$F001FFF0,$1FFF001,$FFF001FF
		dc.l	$F001FFF0,$1FFF001,$FFF001FF,$F001FFF0,$1FFF001
		dc.l	$FFF001FF,$F001FFF0,$1FFF001,$FFF001FF,$F001FFF0
		dc.l	$1FFF001,$FFF001FF,$F001FFF0,$1FFF001,$32F00023
		dc.l	$C80BA280,$23C90584,$D1C93388,$23E6568F,$338C4638
		dc.l	$80744272,$3E915A13,$9A244280,$41FA0064,$8FA84245
		dc.l	$F9F64406,$373A1017,$38722134,$17507221,$283324B2
		dc.l	$B644B321,$2022481F,$A216759D,$AC200322,$D08124B4
		dc.l	$710E4ED1,$26E9E840,$10017A69,$40127A4,$50B4FE00
		dc.l	$380162E2,$39A718F6,$4E3D3C38,$26482849,$2A490C98
		dc.l	$41544E21,$663ED9D8,$D7D8244B,$71006321,$1A241A36
		dc.l	$1A6B0253,$8B7F68FF,$E4097006,$22DA74D3,$FCD25C78
		dc.l	$4A8227,$E9192353,$822AC9BB,$CC65144F,$EF001C70
		dc.l	$FFB1CB67,$2A6FECE6,$1C3C711A,$43276064,$3E41F354
		dc.l	$99A444F,$D0347C93,$E6061823,$47A23A09,$14FA2990
		dc.l	$D9045C5F,$A4021678,$5700360,$10780470,$2600A78
		dc.l	$3700146,$78BB90CE,$1B320012,$80F3163B,$A21A5F6A
		dc.l	$6427047A,$27BA23B,$621542,$D542F91E,$D445E8B6
		dc.l	$24453001,$6881381A,$DFF56C40,$6408FE00,$8500060
		dc.l	$6347110,$582AA0,$310010D6,$3660416,$23D703DB
		dc.l	$85CDFAF2,$524AD5C5,$D5CC1922,$5304D86E,$8600FEEA
		dc.l	$60A0A12,$5A80102,$3030404,$5079EBC,$15001300
		dc.l	$BFD4FFFE,$990F410F,$2423CA0E,$12284A26,$497AA10C
		dc.l	$8E3C03F3,$938F0116,$8A08083D,$1460F42E,$FCDA07E7
		dc.l	$8F9FC750,$48224F2A,$4F7A00D4,$668522C0,$22CBD7C0
		dc.l	$52450C45,$26602,$264C5386,$FFF02C07,$49FAFF8E
		dc.l	$1AC20280,$3F703B22,$AA31818F,$9EE781D2,$814EBB10
		dc.l	$866E60C,$58A2072E,$72202A07,$36722032,$74C7220
		dc.l	$56072272,$201E071A,$72201607,$12601224,$5E7A2480
		dc.l	$64E20B7C,$11C60B8C,$151B2CD8,$79816AF8,$4A816706
		dc.l	$429E5981,$70E2AC01,$F01728CE,$28C0F843,$FAF367E8
		dc.l	$6EE78926,$3718082C,$6D000424,$18D7B628,$9E98F6
		dc.l	$60E47001,$9D53AC83,$14660620,$79FCE016,$504D5186
		dc.l	$D3D0DFC7,$EA891240,$20242064,$4298BFD9,$FAD49FFF
		dc.l	$E6907FD3,$C0428032,$18341820,$4943FAC9,$A4363C80
		dc.l	$283C00,$12389A61,$104A8067,$FD0A33,$FC0F39D2
		dc.l	$BBF18060,$F6C5577F,$FC4E5609,$3A153645,$163D45FF
		dc.l	$DE5324E0,$3D42ED8A,$43FFE42D,$44B6782D,$48CD442D
		dc.l	$490B46E4,$5802484E,$1524057,$D14A0036,$2676C70
		dc.l	$1ED641B6,$7C078043,$71008C48,$C182BB9B,$A641BEE6
		dc.l	$28F4C0C1,$2703F60F,$3642603,$F6720C92,$40B25A81
		dc.l	$E26F04FD,$44E23D41,$17615E66,$28A941E2,$905A41F8
		dc.l	$671E3D40,$FFE20FF8,$E188D54E,$D1AEA72B,$A345F6E2
		dc.l	$4FF2D18E,$F460BE50,$CCF4440C,$1F672089,$66A70AF4
		dc.l	$C68D01FF,$F26702E2,$49C26641,$CD940F6,$D27E112F
		dc.l	$414A724E,$5ED460F4,$703FFE44,$457A027F,$85F4EEF8
		dc.l	$701D6467,$A3A18C9D,$28C51FE6,$C224D70,$BD00AA6
		dc.l	$580BB933,$4259D292,$38A6A2EE,$204D611A,$6608A790
		dc.l	$67122FB1,$570DC700,$BCD1E020,$CC98CDFF,$B46064A3
		dc.l	$1F237C01,$65987C80,$10009642,$615D107F,$7C95A280
		dc.l	$23D04520,$A09C281,$7C144800,$7E3830CA,$B7998B50
		dc.l	$37D43F9,$43090034,$8F09C479,$17E0829,$4AE39413
		dc.l	$6661C364,$66F24085,$60025383,$D10C7AC5,$19CA340
		dc.l	$8C244A80,$E4BD6900,$FA421708,$241DE62A,$6428EABA
		dc.l	$B6C88BA6,$3C06641B,$CC270E7E,$E2C47E51,$36009E67
		dc.l	$878E0C55,$4891F473,$8A1541,$2201837,$9C620102
		dc.l	$81BF42E8,$92808122,$A38808D1,$771FB380,$26A7AB40
		dc.l	$3AF5665C,$E048C882,$FB6654B0,$69826D22,$127490F9
		dc.l	$D2BEF7B0,$16C1641,$ED000A61,$5CB64066,$3C224A61
		dc.l	$7A45EAA2,$9FBF0CFC,$DAFC340A,$301D9A9B,$7407E550
		dc.l	$E31151CA,$EB28ADB,$C1528874,$FA0C6E00,$CEA662D
		dc.l	$59725619,$FFC0811B,$1C7019E4,$82203A41,$37B80684
		dc.l	$6192C472,$67064A6D,$40A67F4,$A8E46080,$7000323C
		dc.l	$FF2418,$B580BA80,$62FA0280,$3BA2C148,$418DB880
		dc.l	$41E88501,$65E48E7,$F8E0707F,$45E80200,$263C0840
		dc.l	$55286C08,$EE221824,$1AC283C4,$83D28182,$82B38422
		dc.l	$C4280151,$C8FFEC4C,$DF073510,$6E540461,$504ABE81
		dc.l	$2611630,$17E248E2,$D0720090,$506A0432,$4440616A
		dc.l	$309F6028,$7255B92A,$8295BFE0,$8A88102F,$1700168
		dc.l	$EA615222,$1F51C9FF,$EAAAC81E,$88D0405F,$E4250
		dc.l	$6110E809,$93F0300,$E2FF3F01,$10B7AA1E,$AC7F32C0
		dc.l	$32010380,$5701D241,$41FB10DE,$8E8338A,$CD676022
		dc.l	$2321FBF,$4A00672A,$3F0061CC,$4A016B04,$D2800108
		dc.l	$80D804A1,$8FC2039,$C0119270,$3614830,$1F531BC6
		dc.l	$D25A33FC,$40198DF,$F09E4A6E,$FFE46A1E,$3E9CF230
		dc.l	$2EFFDE56,$80018107,$4C01C1F8,$420FC08,$72FF13C1
		dc.l	$13D1C581,$761D4,$7064D080,$611ECA83,$74F6FE66
		dc.l	$F0911308,$394A8136,$661C5380,$6718E001,$35BFDE85
		dc.l	$3CCE843,$D40013FC,$2AA4BFD5,$4E753B,$ECD3810B
		dc.l	$4100002,$FC000874,$200E0714,$72201A07,$2E723342
		dc.l	$900122E8,$20352803,$24D04136,$2C008000,$3F20F18
		dc.l	$3E9DE3C,$6E617F3,$82A0000,$3FFE8,$400080
		dc.l	$800100,$C00280,$2801100,$6070708,$709090C
		dc.l	$90A0C0E,$1629855,$1A7E0,$4A68,0

		END
