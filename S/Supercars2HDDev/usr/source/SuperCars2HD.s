;*---------------------------------------------------------------------------
; Program:	SuperCars2.s
; Contents:	Slave for "Super Cars 2" (c) 1991 Magnetic Fields/Gremlin
; Author:	Codetapper/Action!
; History:	24.08.05 - v1.0
;		         - Full load from HD
;		         - Loads and save best scores and fastest times (unless you cheat!)
;		         - Both decrunchers relocated to fast memory (huge loading speedup!)
;		         - Manual protection removed (screen will never appear!)
;		         - Disk protection removed
;		         - Blitter wait inserted
;		         - Snoop bug fixed in copperlist setup
;		         - Trainer added: Set CUSTOM1=1 to activate the built in cheat mode
;		                          Set CUSTOM2=1-7 to start on whichever track you wish
;		         - NTSC screen layout changed: Set CUSTOM3=1 to move the panel up a bit or 
;		           use the keys +/- to switch the status panel during the game
;		         - All intro screens can be bypassed with fire or either mouse button
;		         - RomIcon, NewIcon and 2 OS3.5 Colour Icons (all created by Frank!)
;		         - Quit option (default key is F10)
; Requires:	WHDLoad 15+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Info:		$7494e.w = Races complete
;		$74ea0   = Key pressed
;		$74f28   = Key released
;		$79a7c.w = disk number wanted (0/1 and game adds on '1')
;		$79ad4   = Empty dbf loop used for random numbers, left in
;		$7a466   = Check for cheat modes
;		$7a7aa   = After prize money screen
;		$7b130.w = 1 if player 1 cheating (default = 0)
;		$7b132.w = 1 if player 2 cheating (default = 0)
;		$7b134   = Check if the player names are Wonderland/The Seer
;		$7b518   = Magnetic Fields intro music plays now
;		$7c3e6.w = Difficulty (0-2)
;		$7d60a   = Ask for disk 1/2
;		$7e74c-$7e91a = Records
;
;		Gremlin delay removed as not consistent enough:
;
;		PL_PS	$79b98,_GremlinDelay
;		PL_W	$79b9e,$4e71
;
;		To wire in a high score, add this:
;
;				PL_L	$7c460,$4eb80106
;				PL_P	$106,_FakeScore
;
;		_FakeScore	move.w	#8,d4		;8 points
;				move.w	d4,$12(a0)
;				rts
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"SuperCars2.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
    
;---
_config
    dc.b    "BW;"
	dc.b    "C1:B:enable permanent cheat mode;"
	dc.b    "C2:X:joypad controls player 1:0;"
	dc.b    "C2:X:joypad controls player 2:1;"    
	dc.b    "C3:L:Start race:1,2,3,4,5,6,7;"
	dc.b	0
    
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
	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	0
    
_name		dc.b	"Super Cars 2",0
_copy		dc.b	"1991 Magnetic Fields/Gremlin",0
_info		dc.b	"Installed by Codetapper/Action! & JOTD",10
		dc.b	"Version "
        DECL_VERSION
        dc.b    10
		dc.b	-1,"Keys: F1-F7 - Select starting track number"
		dc.b	10,"         F8 - Activate cheat mode         "
		dc.b	-1,"Thanks to Jean-François Fabre for the JST version"
		dc.b	10,"and to Frank for the original and the icons!"
		dc.b	0
_HighsFileName	dc.b	"SuperCars2.highs",0
_DiskNumber	dc.b	1
_CheatFlag	dc.b	0
_SaveFileExists	dc.b	0
		EVEN
IGNORE_JOY_DIRECTIONS
        include     ReadJoyPad.s
        
;======================================================================
_Start						;a0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	
        lea	$a00,sp
        bsr _detect_controller_types
        
		lea	_Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)

		lea	_BootCode(pc),a0	;Decrunch boot code into position
		lea	$a00,a1
		move.l	a1,a5
		jsr	resload_Decrunch(a2)

		lea	_PL_Boot(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		pea	_Trap15Loader(pc)
		move.l	(sp)+,$bc

		resetregs
		jmp	$a1c

_PL_Boot	PL_START
		PL_R	$d6			;Go to track 0
		PL_R	$fe			;Select DF0:
		PL_R	$12e			;Turn off DF0:
		PL_L	$1b2,$4e4f4e75
		PL_P	$1de,_LoaderPatch
		PL_R	$40e			;Step to correct track
		PL_W	$788,$92		;Copperlist bug
		PL_R	$cbc			;Copy protection
		PL_P	$daa,_exit		;Infinite loop
		PL_END

;======================================================================

_Trap15Loader	bsr	_Loader
		rte

;======================================================================

_LoaderPatch	movem.l	d1-d6/a0-a6,-(sp)
		bsr	_Loader
		movem.l	(sp)+,d1-d6/a0-a6
		moveq	#0,d0
		cmpi.l	#$74700,(sp)
		beq	_MainGamePatch
		rts

;======================================================================

_MainGamePatch	movem.l	d0-d1/a0-a2,-(sp)
        
        
		cmp.l	#$610041fe,$74700	;Make sure it's the original!
		bne	_wrongver

		lea	_PL_Game(pc),a0		;Patch low memory
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	_cheat_mode(pc),d0		;Custom1 = Cheat always on
		beq	.CheckCustom2
		bsr	_AllNamesCheat

.CheckCustom2	move.l	_race_number(pc),d0		;Custom2 = Race number (1-7)
        addq.l  #1,d0
		bgt	.NotTooLow
		moveq	#0,d0
		bra	.NotTooHigh
.NotTooLow	subq	#1,d0
		cmp.l	#6,d0
		blt	.NotTooHigh
		move.l	#6,d0
.NotTooHigh	move.w	d0,$7af8a		;Starting race

		move.l	_ntsc_screen(pc),d0
        cmp.l   #PAL_MONITOR_ID,d0
		beq	.NoNTSCScreen
		bsr	_NTSCScreen

.NoNTSCScreen	bsr	_SetupNames
		bsr	_GameToBuffer		;Copy default scores to
		bsr	_LoadHighs		;buffer and load highs
		bsr	_BufferToGame		;then copy over game
		bsr	_ScoresToLive		;then copy to live buffer

		movem.l	(sp)+,d0-d1/a0-a2
		rts

_PL_Game	PL_START
		PL_P	$100,_BeamDelayD0	;Beam delay for empty DBF's
		PL_PS	$74e94,_Keybd		;Detect quit key
		PL_PS	$79bfa,_MagFieldsDelay
		PL_NOP	$79c00,2
		PL_S	$79c5c,$6c-$5c		;Memory detection
		PL_NOP	$7a440,2		;Wait for disk change
		PL_NOP	$7a44a,4
		PL_PS	$7a44e,_DiskSwap
		PL_PS	$7b150,_Player1CheatOn
		PL_NOP	$7b156,2
		PL_PS	$7b174,_Player2CheatOn
		PL_NOP	$7b17a,2
		PL_S	$7b650,$be-$50		;Protection screen never appears
		PL_W	$7b6e4,$33c0		;Crack game by wiring in the
		PL_R	$7b6ea			;correct page number
		PL_P	$7c420,_GameOver
		PL_P	$7d09e,_CopyCourseRec
		PL_P	$7ea8a,_Decrunch_SASP	;Speed up decrunching
		PL_P	$7ed8e,_Decrunch_SF
		PL_L	$7f11a,$4eb80100	;$7f11a dbra d0,$7f11a
		PL_L	$7f132,$4eb80100	;$7f132 dbra d0,$7f132
		PL_PS	$7f2e0,_AudioFix
        ; joypad control patches
        PL_ORW  $79abc+2,$20    ; enable vblank interrupt        
        PL_PS   $7b1b6,_level3_hook
        PL_P    $74dfa,_level1_hook
        PL_PSS  $78f1c,_test_fire_1,2
        PL_PSS  $78f86,_test_fire_2,2
        PL_PSS  $78fa6,_test_fire_2,2
        PL_IFC2X   0
        PL_PS   $78ee6,_read_joydat_player_1
        PL_ENDIF
        PL_IFC2X   1
        PL_PS   $78ff2,_read_joydat_player_2
        PL_ENDIF
        
        PL_IFBW
        PL_PS   $7a54c,_wait_button
        PL_ENDIF
        
        
		PL_END

;======================================================================

main_loop_caller = $4B1C

; read joyports called
; intro: 000009B8 0007 B1DC 0000 12C0 0000 02E4
; menu: 000009B8 0007 B1DC 0000 0000 0003 81FE
; game: 000009F8 0007 4B1C 0007 A56C

_read_joydat_player_1:
    move.l d1,-(a7)
    move.l d2,-(a7)
    MOVE.W $00dff00c,D0
    move.w  (14,a7),d2
    cmp.w   #main_loop_caller,d2   ; called only from main game loop, not menus
    bne.b   .no_main
	move.l	joy1_buttons(pc),d2	; read buttons values
    bsr read_joydat_xx
.no_main
	move.l	(a7)+,d2
	move.l	(a7)+,d1
    rts
    
_read_joydat_player_2:
    move.l d1,-(a7)
    move.l d2,-(a7)
    MOVE.W $00dff00a,D0
    move.w  (14,a7),d2
    cmp.w   #main_loop_caller,d2   ; called only from main game loop, not menus
    bne.b   .no_main
	move.l	joy0_buttons(pc),d2	; read buttons values
    bsr read_joydat_xx
    
.no_main
	move.l	(a7)+,d2
	move.l	(a7)+,d1
    rts

read_joydat_xx:
	; cancel UP and DOWN from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#0,d0
	btst	#1,d0
	beq.b	.noneed
	bset	#0,d0	; xor 0 and 1 yields 0 cos bit1=1
.noneed
	btst	#JPB_BTN_REVERSE,d2
	beq.b	.no_rev
	; set DOWN because reverse pressed
	bclr	#0,d0
	btst	#1,d0
	bne.b	.no_rev
	bset	#0,d0	; xor 0 and 1 yields 1 cos bit1=0
.no_rev:
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed2
	bset	#8,d0	; xor 8 and 9 yields 8 cos bit9=1
.noneed2

	btst	#JPB_BTN_FORWARD,d2
	beq.b	.no_fwd
	; set UP because forward pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_fwd
	bset	#8,d0	; xor 0 and 1 yields 1 cos bit1=0
.no_fwd:
    rts

_wait_button
.wait
    move.l	joy0_buttons(pc),d0
    btst	#JPB_BTN_RED,d0
    bne.b   .out
    move.l	joy1_buttons(pc),d0
    btst	#JPB_BTN_RED,d0
    beq.b   .wait
.out
    MOVE.W	#$ffff,$7e712
    rts
    
_test_fire_1
    movem.l D0,-(a7)
    move.l  joy1_buttons(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts
_test_fire_2
    movem.l D0,-(a7)
    move.l  joy0_buttons(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts
    
_level1_hook
    bsr _read_joysticks_buttons
    bsr _test_buttons
	MOVE.W	#$0004,156(A6)		;74dfa: 3d7c0004009c
	RTE				;74e00: 4e73
    
_level3_hook:
    MOVE.W	D0,$7b4ce   ; original
    btst    #5,d0   ; vblank?
    bne.b   .vblank
    RTS ; back to copper interrupt routine
.vblank:
    addq.l  #4,a7   ; POP
    bsr _read_joysticks_buttons
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noesc
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noesc
    btst    #JPB_BTN_YEL,d0
    bne   _exit
.noesc
    move.w  #$20,intreq(a6)
	MOVEM.L	(A7)+,D0-D7/A0-A6	;7b2d8: 4cdf7fff
	RTE				;7b2dc: 4e73
 
pause_flag = $74bec
_test_buttons
    movem.l  d0-d1/a0,-(a7)
    lea previous_joy1_buttons(pc),a0
    move.l  (a0),d1
    move.l  joy1_buttons(pc),d0
    move.l  d0,(a0)
    btst    #JPB_BTN_PLAY,d1
    bne.b   .nopause        ; was already pressed
    btst    #JPB_BTN_PLAY,d0
    beq.b   .nopause
    eor.w   #1,pause_flag
.nopause
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noesc
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noesc
    ; simulate ESC only if paused so it can't conflict
    ; with missile/weapon launch
    tst.w   pause_flag
    beq.b   .noesc
    move.w  #$45,$74f90
.noesc
    movem.l  (a7)+,d0-d1/a0
    rts
    
previous_joy1_buttons
    dc.l    0
        
;======================================================================

_Loader		subi.l	#$3000,d0
		move.l	d1,d7
		beq	_NothingToRead
		moveq	#0,d2
		move.b	_DiskNumber(pc),d2	;d2 = Disk number
		movem.l	d1/a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(sp)+,d1/a2
_NothingToRead	rts

;======================================================================

_AudioFix	move.l	d0,-(sp)		;move.b (3,a6),(8,a5)
		moveq	#0,d0
		move.b	(3,a6),d0
		move.w	d0,(8,a5)
		move.l	(sp)+,d0
		rts

;======================================================================

_CopyCourseRec	tst.w	$7ceee			;Check if player one won
		beq	.CopyNameLoop
		tst.w	$7cef0			;Check if player two won
		beq	.CopyNameLoop

		move.w	$74952,d1		;d1 = Track number
		add.w	d1,d1			;d1 = Track number * 2
		lea	$7e8f0,a0		;a0 = Best times
		move.w	$7cf20,(a0,d1.w)	;Restore original time
		rts

.CopyNameLoop	move.b	(a2,d1.w),(a0,d1.w)
		dbra	d1,.CopyNameLoop
		
		bsr	_GameToBuffer
		bsr	_SaveHighs
		rts

;======================================================================

_GremlinDelay	movem.l	d0-d2/a0-a2,-(sp)
		moveq	#25,d0
		bra	_Delay

_MagFieldsDelay	movem.l	d0-d2/a0-a2,-(sp)
		move.l	#120,d0
_Delay		move.l	_resload(pc),a2
		jsr	resload_Delay(a2)
		movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_DiskSwap	move.w	$79a7c,d0		;Stolen code
		movem.l	d0/a0,-(sp)
		lea	_DiskNumber(pc),a0
		addq	#1,d0
		move.b	d0,(a0)
		movem.l	(sp)+,d0/a0
		jsr	$a04.w
		rts

;======================================================================

_BlitWait_d0	BLITWAIT			;Wait for the blitter
		move.w	d0,$dff058		;Stolen code
		rts

;======================================================================

_BeamDelayD0	and.l	#$ffff,d0
		divu	#40,d0
		and.l	#$ffff,d0
		movem.l	d0-d1,-(sp)
		move.l	d0,d1			
		bra	_int2w1

;======================================================================

_EmptyDBF	movem.l	d0-d1,-(sp)
		moveq	#3-1,d1			;wait because handshake min 75 µs

_int2w1		move.b	(_custom+vhposr),d0
.int2w2		cmp.b	(_custom+vhposr),d0	;one line is 63.5 µs
		beq	.int2w2
		dbf	d1,_int2w1
		movem.l	(sp)+,d0-d1
		rts

;======================================================================

_Keybd		not.b	d0			;Stolen code
		ror.b	#1,d0

		cmp.b	_keyexit(pc),d0		;Check for quit key
		beq	_exit
		
		cmp.b	#$0b,d0			;Check for - key
		bne	.CheckAdd
		bsr	_NTSCScreen

.CheckAdd	cmp.b	#$0c,d0			;Check for + key
		bne	.CheckHelp
		bsr	_PALScreen

.CheckHelp	cmp.b	#$5f,d0
		bne	.CheckFKey

.CheckFKey	cmp.b	#$50,d0			;Check for F1-F7 for
		blt	.CheckF8		;the starting race
		cmp.b	#$56,d0
		bgt	.CheckF8
		move.l	d0,-(sp)
		sub.b	#$50,d0
		ext.w	d0
		move.w	d0,$7af8a		;Starting race
		move.l	(sp)+,d0

.CheckF8	cmp.b	#$57,d0			;F8 = Automatic cheat on
		bne	.KeybdEnd
		bsr	_AllNamesCheat

.KeybdEnd	rts

;======================================================================

_NTSCScreen	movem.l	d0-d2/a0-a2,-(sp)
		move.l	#15*40,d2		;Add on amount
		bsr	_StuffCList
		move.w	#$e,$769a6		;New value to add on
		move.w	$7c3e4,d0		;Number of players - 1
		asl.w	#3,d0
		addi.w	#$e,d0
		move.b	d0,$7f6b6		;Reduce DIWSTRT value
		move.b	#$f4,$7f780		;For Frank!
		move.b	#$f4,$7f788
		move.b	#$f5,$7f808
		movem.l	(sp)+,d0-d2/a0-a2
		rts

_PALScreen	movem.l	d0-d2/a0-a2,-(sp)
		move.l	#0,d2			;Add on amount
		bsr	_StuffCList
		move.w	#$24,$769a6		;Default value to add on
		move.w	$7c3e4,d0		;Number of players - 1
		asl.w	#3,d0
		addi.w	#$24,d0
		move.b	d0,$7f6b6		;Original DIWSTRT value ($24/$2c)
		move.b	#$f4,$7f780
		move.b	#$f8,$7f788
		move.b	#$fc,$7f808
		movem.l	(sp)+,d0-d2/a0-a2
		rts

_StuffCList	lea	_CList(pc),a0
		lea	$7f792,a1
		moveq	#4-1,d0
.StuffCListLoop	move.l	(a0)+,d1
		add.l	d2,d1
		move.w	d1,4(a1)
		swap	d1
		move.w	d1,(a1)
		add.l	#8,a1
		dbf	d0,.StuffCListLoop
		rts

_CList		dc.l	$5e7ac,$5ef2c,$5f6ac,$5fe2c

;======================================================================

_SetupNames	move.l	#41,d0
		moveq	#0,d1
		lea	_LiveSaveFile(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetCustom(a2)
		tst.l	d0
		beq	.NoNames

		lea	_LiveSaveFile(pc),a0
		lea	$7d667,a1
		lea	$7e6da,a1
		bsr	_CopyName
		move.b	(a0),d0
		beq	.NoNames
		lea	$7d69b,a1
		lea	$7e6ee,a1
		bsr	_CopyName
.NoNames	rts

_CopyName	moveq	#20-1,d0
		move.b	(a0),d1
		beq	.Rts
.CopyNameLoop	move.b	(a0)+,d1
		cmp.b	#0,d1
		beq	.ClearRest
		cmp.b	#',',d1
		beq	.ClearRest
		move.b	d1,(a1)+
		dbf	d0,.CopyNameLoop
.Rts		rts

.ClearRest	move.b	#'/',(a1)+
		dbf	d0,.ClearRest
		rts

;======================================================================

_Decrunch_SASP	move.l	a5,-(sp)		;A5 isn't used by the
		pea	_Decruncher(pc)		;decruncher
		move.l	(sp)+,a5
		add.l	#$30,a5
		jsr	(a5)
		move.l	(sp)+,a5
		rts

;======================================================================

_Decrunch_SF	move.l	a5,-(sp)		;A5 isn't used by the
		pea	_Decruncher(pc)		;decruncher
		move.l	(sp)+,a5
		add.l	#$334,a5
		jsr	(a5)
		move.l	(sp)+,a5
		rts

;======================================================================

_EncryptHighs	movem.l	d0/a0,-(sp)
		lea	_SaveFileStart(pc),a0
		move.l	#SAVE_FILE_SIZE,d0
.EncryptLoop	eor.b	d0,(a0)+
		subq.l	#1,d0
		bne.s	.EncryptLoop
		movem.l	(sp)+,d0/a0
		rts

;======================================================================

_CopyScores	move.l	#1172-1,d0		;Copy high scores
		bra	_CopyDataA0ToA1

_CopyLaps	move.l	#462-1,d0		;Copy lap times
_CopyDataA0ToA1	move.b	(a0)+,(a1)+
		dbf	d0,_CopyDataA0ToA1
		rts

;======================================================================

_GameToBuffer	movem.l	d0-d1/a0-a2,-(sp)

		lea	$7df00,a0
		lea	_BestScores(pc),a1
		bsr	_CopyScores

		lea	$7e74c,a0
		lea	_FastestLaps(pc),a1
		bsr	_CopyLaps

		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_BufferToGame	movem.l	d0-d1/a0-a2,-(sp)

		lea	_BestScores(pc),a0
		lea	$7df00,a1
		bsr	_CopyScores

		lea	_FastestLaps(pc),a0
		lea	$7e74c,a1
		bsr	_CopyLaps

		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_ScoresToLive	movem.l	d0-d1/a0-a2,-(sp)

		lea	_SaveFileStart(pc),a0
		lea	_LiveSaveFile(pc),a1
		move.l	#SAVE_FILE_SIZE-1,d0
		bsr	_CopyDataA0ToA1

		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_CheckHighs	movem.l	d1/a0-a2,-(sp)

		moveq	#-1,d0
		lea	_SaveFileStart(pc),a0
		lea	_LiveSaveFile(pc),a1
		move.l	#SAVE_FILE_SIZE-1,d1
.CheckNextByte	cmp.b	(a0)+,(a1)+
		bne	.Modified
		dbf	d1,.CheckNextByte
		moveq	#0,d0

.Modified	movem.l	(sp)+,d1/a0-a2
		tst.l	d0
		rts

;======================================================================

_LoadHighs	movem.l	d0-d2/a0-a2,-(sp)

		lea	_HighsFileName(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		
		tst.l	d0
		beq	_NoHighsFile

		lea	_HighsFileName(pc),a0
		lea	_SaveFileStart(pc),a1
		jsr	resload_LoadFile(a2)

		bsr	_EncryptHighs		;Decrypt high scores

_NoHighsFile	movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_Player1CheatOn	move.w	#1,$7b130		;Player 1 cheat on
		bra	_SetCheat

_Player2CheatOn	move.w	#1,$7b132		;Player 2 cheat on
		bra	_SetCheat

_AllNamesCheat	move.w	#$4e71,$7b14a		;Player one cheat on
		move.w	#$4e71,$7b16e		;Player two cheat on

_SetCheat	move.l	a0,-(sp)
		lea	_CheatFlag(pc),a0
		st	(a0)
		move.l	(sp)+,a0
		rts

;======================================================================

_GameOver	lea	$7de20,a1		;lea _GameOver,a1
		jsr	$7c426			;Print text
		bsr	_GameToBuffer
		bra	_SaveHighs

;======================================================================

_SaveHighs	movem.l	d0-d2/a0-a2,-(sp)	;Save high scores

		move.b	_CheatFlag(pc),d0	;Check if player has cheated
		tst.b	d0
		bne	_DoNotSaveHighs

		bsr	_CheckHighs
		beq	_DoNotSaveHighs
		bsr	_ScoresToLive

		bsr	_EncryptHighs		;Encrypt high scores

		lea	_HighsFileName(pc),a0
		lea	_SaveFileStart(pc),a1
		move.l	#_SaveFileEnd-_SaveFileStart,d0
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)

		bsr	_EncryptHighs		;Decrypt them back again

_DoNotSaveHighs	movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================
_resload	dc.l	0			;Resident loader
_Tags		dc.l	WHDLTAG_CUSTOM1_GET
_cheat_mode	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_race_number	dc.l	0
		dc.l	WHDLTAG_MONITOR_GET
_ntsc_screen	dc.l	0
		dc.l	TAG_DONE
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

SAVE_FILE_SIZE	equ	(21*20)+(21*2)+1172

_SaveFileStart
_FastestLaps	
_FastLapNames	ds.b	21*20			;Each name is 20 bytes
_FastLapTimes	ds.b	21*2
_BestScores	ds.b	1172
_SaveFileEnd

_LiveSaveFile	ds.b	SAVE_FILE_SIZE

;======================================================================

_BootCode	dc.l	$524E4301,$1000,$8DF,$11E8113A,$11C11
		dc.l	$19AA6A66,$33433344,$44A52486,$CA0EE0EC,$3266132
		dc.l	$6044612E,$12892A26,$4422221E,$D1051A16,$605C6112
		dc.l	$6040610E,$89440A06,$D6B50259,$834DF900,$DFF0004B
		dc.l	$BFD00049,$C5A74E75,$602491B4,$E058B001,$2C68C403
		dc.l	$B866A213,$482040B,$16075606,$6E2C480C,$C4A2C28
		dc.l	$D340661,$1E6D8061,$3E41EC07,$CCA56306,$50303C00
		dc.l	$FF206C07,$C82F088E,$948A7EB,$504A4067,$1A534032
		dc.l	$2EDCE202,$41FF0034,$23EF42A4,$47B44167,$F451C8FF
		dc.l	$EA4C9FEE,$EA611420,$DB600030,$2292A5,$53CB86B
		dc.l	$2C0DE08,$EDEC4601,$82D03,$1A100167,$EC98A1F
		dc.l	$402353FE,$B632038E,$60EA4236,$BBFE08AD,$20106
		dc.l	$1FF24803,$AE350261,$8ED42E07,$35D4826D,$3C03E84B
		dc.l	$EFF76E6,$280566F8,$7E6FD4A5,$5E4AF507,$D6F3504D
		dc.l	$AF426857,$72D8EFC,$18003C07,$4847BA33,$6825302C
		dc.l	$79D6C018,$7A603C39,$7C839308,$18600601,$67D743BA
		dc.l	$D4C445EC,$6C87200,$1232654D,$B2F3AFFF,$66025241
		dc.l	$E5402031,$7A4267D7,$FEE22231,$10009280,$29410814
		dc.l	$60048563,$F450B866,$FC4A671E,$2EEAAAF0,$67182C00
		dc.l	$8CC74846,$3946081A,$53BDF8F5,$B21C3A42,$1E294808
		dc.l	$C72DD45,$394708,$2D08155,$80A74E62,$49D5D06
		dc.l	$89BAD06B,$2064A26,$71666224,$72080A36,$95AC665C
		dc.l	$D5790102,$BCD11A67,$245283D5,$C6C0005,$674A3F3E
		dc.l	$A2B220FE,$9C517DF0,$BC301F6C,$1FC660CC,$BE43670E
		dc.l	$FAEC084A,$C1086726,$60BAFEAE,$8FB05565,$467DE8D
		dc.l	$1E86098,$E451773,$70F6DCBB,$5E700160,$A700260
		dc.l	$6700360,$270043D,$59970F00,$967FFF00,$9A41FA00
		dc.l	$1006A136,$3C5B1140,$180436,$60FE2DDF,$DE955264
		dc.l	$69736B20,$6572726F,$72206E75,$6D622078,$78982D6C
		dc.l	$F04ECF10,$64619C5A,$72002480,$259E6BB0,$4489007E
		dc.l	$D41C95D4,$5241EC18,$3A2D4800,$20980C3F,$B0612A61
		dc.l	$E9249653,$81671830,$2E001E02,$4067F214,$779D8B0
		dc.l	$A303ACDE,$760043F0,$37127920,$3019B0EB,$667F83E
		dc.l	$3C0BFF34,$3C555561,$1230C1D6,$4151CFFF,$F861083E
		dc.l	$161043C,$8F4E3219,$C042C242,$D241D240,$6A6B7800
		dc.l	$3A3C1702,$CED1FB00,$6604389C,$85024149,$3AA59506
		dc.l	$9A44E24D,$6BAC26A8,$A90CD0C4,$8699DECE,$6E4AACB4
		dc.l	$386832D4,$661A0281,$74ABFFFF,$226C07EC,$D3C13211
		dc.l	$542E5B1A,$70042C1D,$B8B06609,$261A346A,$751C0282
		dc.l	$B986F4D3,$C234CBE8,$1CB2BA1C,$D065F855,$6D1C1EB3
		dc.l	$40B54039,$40DE3132,$18B14136,$C151CDFF,$A0294B77
		dc.l	$F4A86836,$D8D48EFC,$6CC63200,$237B0801,$87FB060D
		dc.l	$1ABA37C1,$4E3941E2,$48E24992,$4067226B,$81ED8AE
		dc.l	$B2600865,$8FB96344,$41534161,$34CFB151,$C9FFF427
		dc.l	$E1B06E52,$DA9B0CE3,$89D2067,$8998EB1,$4D600261
		dc.l	$2D7FD00,$79C6FC10,$9EA83B5,$2B76A32,$D9C0FBF4
		dc.l	$2FEC7451,$D00821F,$D91B67F8,$3A770200,$9C98E045
		dc.l	$2B67F615,$77BE0A0,$2EAE93E1,$FBAFE43E,$7EEFA47F
		dc.l	$7F3E633C,$3676077,$634EBF3F,$7E63B1B4,$7F511A18
		dc.l	$7E7E607F,$1E3E3328,$19BF6046,$4D631803,$6EAA2B73
		dc.l	$18762A6B,$36770F00,$67380703,$66C5173E,$B47F6CF9
		dc.l	$637C7C6F,$7FB4137C,$606B7B63,$7E6B854F,$E32F367F
		dc.l	$1C3E6B18,$49A2BC91,$7E063E3F,$E706A338,$F214636F
		dc.l	$A94A656C,$3DD2B1C,$77361C78,$731860,$3060363
		dc.l	$C63A23F,$D99F63B1,$3F604E31,$7E677F63,$673E603A
		dc.l	$677ED237,$8FBC31C,$3C341906,$FA912EB,$183C001F
		dc.l	$5DE5A056,$45FAFF,$7E1018B0,$306B12A6,$4C3A6B10
		dc.l	$9943616B,$67B6B0A,$7000600A,$4A6B8AA,$C0B83F60
		dc.l	$6C46FF13,$72005000,$80283D18,$BE6440F6,$A6D80020
		dc.l	$12F200B0,$E76DB6C2,$3B0EC2DE,$803D7C83,$8000962F
		dc.l	$D601FFFE,$120AE22,$22128924,$26442228,$2A91482C
		dc.l	$2E30C465,$27480134,$36241238,$3A7115CA,$9E013E1B
		dc.l	$3129654,$92001DD7,$9400C000,$8E99A100,$909EA101
		dc.l	$A5E4010A,$27B2E0E2,$8F450180,$D78F820F,$FFFEA37A
		dc.l	$7205CEEE,$29400828,$2A41306A,$8B7C5341,$67482923
		dc.l	$50674243,$DB754667,$36A6F,$3969D828,$670612D8
		dc.l	$538766FA,$20F2604D,$5A207E00,$D0806603,$352044FC
		dc.l	$F636D180,$E2172BEB,$F0070504,$27370303,$3AF22D3
		dc.l	$6B252C22,$48E77FFE,$26498E25,$C5863D3,$66027EFF
		dc.l	$39583831,$29AF0A2C,$F39A2043,$FAFFCC19,$1DD9246E
		dc.l	$6261971,$FD0825,$E77A2720,$18CF5822,$67107200
		dc.l	$578ABA97,$2005C13A,$D89C6EFC,$D1C042AC,$8304A87
		dc.l	$6712E122,$4898962E,$50801A1D,$3016D953,$6925FA22
		dc.l	$4BD7EC4B,$3F3E7628,$705C9A2C,$534766F8,$D16E4C53
		dc.l	$92552093,$BFDE4759,$DF4DFA01,$80DDF6BE,$B1508E74
		dc.l	$383C40,$80D1C9B8,$5F977EB7,$5C26A272,$4617A2F
		dc.l	$9BD69DC,$710032D3,$F10E1D91,$225FB3CB,$671AB46A
		dc.l	$B11065D8,$4454E5A,$2453FF0,$4BF25000,$442B3C7
		dc.l	$4E9660E2,$4CDF311B,$BC173056,$24585CE2,$21419000
		dc.l	$64684824,$6C701289,$7A844422,$8E989113,$A2D83A4C
		dc.l	$272676EC,$C714CD6,$6326EBDF,$47207A1F,$28604E7C
		dc.l	$1604A7C,$260467C,$360427C,$4603E7C,$5603A72
		dc.l	$161CC7C,$6DC4760,$30AAD8C2,$7C082672,$261B87C
		dc.l	$A8AAD1C,$720361AE,$7C0ED88A,$12720561,$A47C16AD
		dc.l	$F4087208,$619A7C36,$88CFDC6C,$824720E,$618EDE44
		dc.l	$36070243,$3FFF5346,$534341E9,$1E323000,$53440244
		dc.l	$943F1587,$40005282,$51CEFFE8,$A6C2F687,$FF643C
		dc.l	$7600A52,$135A7C10,$AC5A2671,$86FDF2DF,$A3F2FDC2
		dc.l	$758EF470,$CA8E3085,$5338840F,$5DCA5E9D,$EE9675DC
		dc.l	$A2ED115,$5E1048E7,$AC00700F,$121DD201,$D5420B16
		dc.l	$D743D944,$2C58DB45,$3066DD46,$C115C8FF,$E4222C08
		dc.l	$2C3702D7,$C1368389,$448485A2,$FE868797,$C1E7484C
		dc.l	$DF003517,$693E2509,$93E87C44,$861FC19F,$ECFE1FE0
		dc.l	$FCA8F3A8,$3BAE747D,$F0C4EFD2,$6F155EF1,$7FFE2649
		dc.l	$244843EA,$A2A4B,$20280002,$2C40D7C0,$24AE3706
		dc.l	$D1C22E02,$5687E48F,$538724D9,$84ECFC10,$AA6B6F8A
		dc.l	$F6D000,$66081083,$5533EAA4,$6FAA606F,$AA586FAA
		dc.l	$506FF704,$78096002,$780E7401,$76017A05,$32021DB4
		dc.l	$D4BFB083,$8E51DA47,$BE43D383,$5242D643,$524360DA
		dc.l	$32046010,$72097A02,$2977F1FD,$A7A0360,$4720C7A
		dc.l	$4E8F045,$F3700053,$4517224A,$30C93860,$34C9F87C
		dc.l	$19919DC,$DFC65346,$17209ED0,$FCB7CD5E,$37B6ECFF
		dc.l	$E200E84,$D4E756F,$2B930B33,$FC5DDFDF,$F09A3D54
		dc.l	$B82039D1,$6B040280,$4AB40022,$436D81F6,$81B28067
		dc.l	$F0B0BC00,$25936708,$C395DA4C,$DFD0F45D,$C0129441
		dc.l	$F957B5C1,$BF31571F,$FF4258C3,$6B81FD9E,$6100F382
		dc.l	$42474A70,$F2EE3679,$3A9885E2,$8E2B0FDF,$C7A2E5F
		dc.l	$F0088EB8,$F2D7C2F,$42935741,$24A2E1C5,$E8902D95
		dc.l	$6F4847D8,$9B58498E,$CB14467C,$6934B8C9,$71992063
		dc.l	$93323CA2,$D3B25866,$1670FF52,$40B1FC8B,$A8EA4EB0
		dc.l	$640AF204,$4019006A,$C5247BE,$2E390505,$DA68600E
		dc.l	$B77C10C9,$24B04A0F,$67FA651F,$FA001BDF,$F9526020
		dc.l	$F5A27072,$6F746563,$74696F6E,$20666169,$6C6564F0
		dc.l	$E46DEC80,$6D13679C,$41F82E4F,$D201BCDC,$42987593
		dc.l	$60FE778E,$FF0BDFBF,$0

_Decruncher	dc.l	$323A0024,$7E00D080,$66082020,$44FCFFFF,$D180E217
		dc.l	$51C9FFF0,$4E750705,$4040404,$3030000,0
		dc.l	0,0,$48E77FFE,$7E000C58,$53416602
		dc.l	$7EFF4BFA,$FFDA3B58,$C2B58,$E303A,$FFDA43FA
		dc.l	$FFCA1B71,$FD0009,$1B710001,$B2018,$D1C042AD
		dc.l	$124A87,$67122248,$20290008,$50802B40,$1216D9
		dc.l	$538066FA,$224BD7FA,$FFA83E3A,$FFA27000,$D0BAFF9E
		dc.l	$534766F8,$D1AD0012,$536D000C,$3E3AFF8C,$DE47DE47
		dc.l	$4DFA017E,$DDF67000,$508E7400,$383C4000,$3A3C4000
		dc.l	$20204A79,$7E6D8,$6600039E,$72046176,$DE47DE47
		dc.l	$4BFA0030,$DBF57000,$4E95B3CB,$671AB47C,$1065DA
		dc.l	$4450010,$2453FF0,$49F25000,$4420010,$4E9660E2
		dc.l	$4CDF7FFE,$203AFF36,$4E750000,$580000,$5C0000
		dc.l	$600000,$640000,$680000,$6C0000,$700000
		dc.l	$7A0000,$840000,$8E0000,$980000,$A20000
		dc.l	$D80000,$E20000,$1080000,$10C5341,$7E00D080
		dc.l	$66082020,$44FCFFFF,$D180DF47,$51C9FFF0,$4E757C00
		dc.l	$604E7C01,$604A7C02,$60467C03,$60427C04,$603E7C05
		dc.l	$603A7201,$61CC7C06,$DC476030,$720161C2,$7C08DC47
		dc.l	$60267202,$61B87C0A,$DC47601C,$720361AE,$7C0EDC47
		dc.l	$60127205,$61A47C16,$DC476008,$7208619A,$7C36DC47
		dc.l	$DC7AFE7C,$720E618E,$DE443607,$2433FFF,$53465343
		dc.l	$2433FFF,$1E323000,$53440244,$3FFF1587,$40005282
		dc.l	$51CEFFE8,$4E757204,$6100FF64,$3C07600A,$72086100
		dc.l	$FF5A7C10,$DC47DC7A,$FE3C6100,$FE145346,$53440244
		dc.l	$3FFF1587,$40005282,$51CEFFF2,$4E757C01,$600A7203
		dc.l	$6100FF30,$7C02DC47,$53466100,$FDEC5344,$2443FFF
		dc.l	$15874000,$528251CE,$FFEE4E75,$DC,$A2
		dc.l	$5E,$10,$48E7AC00,$700F121C,$D201D542
		dc.l	$D201D743,$D201D944,$D201DB45,$D201DD46,$D201DF47
		dc.l	$51C8FFE4,$223AFDCA,$3702D7C1,$3683D7C1,$3684D7C1
		dc.l	$3685D7C1,$3686D7C1,$368797C1,$97C197C1,$97C197C1
		dc.l	$4CDF0035,$4E7548E7,$AC00700F,$121CD201,$D542D201
		dc.l	$D743D201,$D944D201,$DB45D201,$DD4651C8,$FFE8223A
		dc.l	$FD803702,$D7C13683,$D7C13684,$D7C13685,$D7C13686
		dc.l	$97C197C1,$97C197C1,$4CDF0035,$4E7548E7,$AC00700F
		dc.l	$121CD201,$D542D201,$D743D201,$D944D201,$DB4551C8
		dc.l	$FFEC223A,$FD403702,$D7C13683,$D7C13684,$D7C13685
		dc.l	$97C197C1,$97C14CDF,$354E75,$48E7A800,$700F121C
		dc.l	$D201D542,$D201D743,$D201D944,$51C8FFF0,$223AFD0A
		dc.l	$3702D7C1,$3683D7C1,$368497C1,$97C14CDF,$154E75
		dc.l	$48E77FFE,$244843EA,$A284B,$20280002,$2A40D7C0
		dc.l	$24280006,$D1C22E02,$5687E48F,$538724D9,$51CFFFFC
		dc.l	$10204A79,$7E6D8,$660000F6,$D0006608,$102044FC
		dc.l	$FFFFD100,$640000A4,$D0006608,$102044FC,$FFFFD100
		dc.l	$6460D000,$66081020,$44FCFFFF,$D1006458,$D0006608
		dc.l	$102044FC,$FFFFD100,$6450D000,$66081020,$44FCFFFF
		dc.l	$D1006404,$78096002,$780E7401,$76017A05,$32025341
		dc.l	$7E00D000,$66081020,$44FCFFFF,$D100DF47,$51C9FFF0
		dc.l	$DA47BE43,$66085242,$D6435243,$60DA3204,$60107209
		dc.l	$7A02600A,$720A7A03,$6004720C,$7A045341,$7E00D000
		dc.l	$66081020,$44FCFFFF,$D100DF47,$51C9FFF0,$45F37000
		dc.l	$53451722,$51CDFFFC,$60347401,$76017C01,$32025341
		dc.l	$7E00D000,$66081020,$44FCFFFF,$D100DF47,$51C9FFF0
		dc.l	$DC47BE43,$66085242,$D6435243,$60DA5346,$172051CE
		dc.l	$FFFCB7CC,$6600FF0C,$200D4CDF,$7FFE4E75,$70004CDF
		dc.l	$7FFE4E75

		END
