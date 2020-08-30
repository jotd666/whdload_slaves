;*---------------------------------------------------------------------------
; Program:	BubbleBobble.s
; Contents:	Slave for "Bubble Bobble" (c) 1988 Firebird
; Author:	Codetapper of Action
; History:	29.04.01 - v1.0
;		         - Full load from HD
;		         - 2 versions supported
;		         - Copy protection removed
;		         - Loads and saves high scores
;		         - Buttonwait tooltype added for title picture
;		         - RomIcon, NewIcon and OS3.5 Colour Icon (created by Frank!)
;		         - Quit option (default key is 'F10')
;		15.07.07 - v1.1
;		         - Now supports 4 versions
;		         - Completely rewrote slave, no longer requires OSEmu
;		         - Now works on WHDLoad 16+
;		         - All files can be packed to save space (FImp, Propack etc)
;		         - Trainer added: 
;		            Del - Toggle infinite lives on/off (set Custom1=1 to turn on)
;		             F9 - Jump to the final level
;		           Help - Skip the current level
;		         - Stack relocated to fast memory
;		         - Fire button will skip the "Now it is the beginning of a fantastic story"
;		           intro
; Requires:	WHDLoad 10+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"BubbleBobble.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

CHIPMEM		equ	$80000
GAME_ADDRESS	equ	$2000
FREEMEM_ADDRESS	equ	$16000
COPPERLIST	equ	$110
STACK_ADDRESS	equ	$10c
IGNORE_JOY_DIRECTIONS

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError 		;ws_flags
		dc.l	CHIPMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_Data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$1000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
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
	ENDM
	
_name		dc.b	"Bubble Bobble",0
_copy		dc.b	"1988 Firebird",0
_info		dc.b	"Installed by Codetapper/Action! & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		dc.b	-1,10,"Keys: Help - Skip current level   "
		dc.b	10,"        F9 - Jump to final level  "
		dc.b	10,"       Del - Toggle infinite lives"
		dc.b	-1,"Thanks to Mad-Matt for the Hit Squad version"
		dc.b	10,"and Frank for the original and the icons!"
		dc.b	0
_Data		dc.b	"data",0
_MainName	dc.b	"bubble",0
_Highs		dc.b	"BubbleBobble.highs",0
_HighScoreNames	dc.b	"IAN","FRA","MAT","CHR","CAR",0
_CheatFlag	dc.b	0
_config
	dc.b	"BW;"
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C2:X:Blue/2nd button jumps:0;"
		dc.b	0

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
		
		lea	_MainName(pc),a0	;Load main file
		move.l	_GameAddress(pc),a1
		move.l	a1,a5
		bsr	_LoadFile

		
		cmp.l	#$8d24280,$24(a5)	;SPS 1344, 2518
		beq	.SPS1344_2518

		cmp.l	#$104afc,$28(a5)	;SPS 1343
		beq	.SPS1343

		cmp.l	#$81243f9,$24(a5)	;SPS 1342
		bne	_wrongver

.SPS1342	bsr	_Relocate
		lea	_PL_SPS_1342(pc),a0
		lea	_1342_Addys(pc),a1
		bra	_PatchGame

;======================================================================

.SPS1343	bsr	_DecryptSPS1343		;Decrypt the copylock
		bra	.Common1343_44

.SPS1344_2518	bsr	_Relocate

.Common1343_44	lea	_PL_SPS_1344(pc),a0
		lea	_1344_Addys(pc),a1
		;bra	_PatchGame		;Deliberately falls through

;======================================================================

_PatchGame	lea	_GameParams(pc),a3
		move.l	_GameAddress(pc),d7
		moveq	#GAME_PARAM_CNT-1,d1
.CopyGameParams	move.l	(a1)+,d0		;Read a value
		add.l	d7,d0			;Add game address
		move.l	d0,(a3)+		;Copy into destination
		dbf	d1,.CopyGameParams

		bsr	_DefaultNames		;Default high score names
		bsr	_LoadHighScores		;Load high scores if found
		pea	_Level3Int(pc)
		move.l	(sp)+,$6c

		move.l	a5,a1			;Patch main game
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	_expmem(pc),d0		;Save stack address
		add.l	#$1000,d0
		move.l	d0,STACK_ADDRESS

		move.l	_Custom1(pc),d0		;Custom1 for infinite lives
		beq	.PatchLowMem
		bsr	_ToggleLives

.PatchLowMem	lea	_PL_LowMem(pc),a0	;Patch low memory
		sub.l	a1,a1
		jsr	resload_Patch(a2)

		move.l	#COPPERLIST,$dff080
		move.l	#COPPERLIST,$dff084

		bsr	_SetupKeyboard
		move.w	#$83c0,$dff096

		jmp	(a5)			;Start game

_PL_LowMem	PL_START
		PL_P	$100,_AllocMem		;Allocate memory routine
		PL_P	$106,_FireOnIntro	;Check for fire: tst.b ($563,a0)
		PL_L	COPPERLIST,$01000200	;Copperlist
		PL_L	COPPERLIST+4,$9c8010
		PL_L	COPPERLIST+8,-2
		PL_END

_PL_SPS_1342	PL_START
		PL_IFC2
		PL_PS	$3dfe,load_joydat_0
		PL_PS	$3e0e,load_joydat_1
		PL_ENDIF
		PL_P	$3d7a,handle_pause_and_quit_1342

		PL_S	$6,$3e-$6		;Close Workbench
		PL_L	$54,176896		;Fix asprites.spr length
		PL_L	$64,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$80,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$9c,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$b8,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$d4,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$f0,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$10c,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$128,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$144,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$160,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$17c,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$194,$70ff4e71		;jsr _LVOOpenLibrary(a6)
		PL_PS	$1f0,_Copylock1342	;Checked at $2f3a
		PL_NOP	$1f6,4
		PL_PS	$e84,_BlitWait
		PL_S	$e8a,$92-$8a
		PL_W	$fe4,$4200		;Colour bit fix
		PL_PS	$10f8,_Keybd		;move.b $bfec01,d0
		PL_I	$2f48			;Copy protection failure
		PL_R	$3a90			;Open file
		PL_P	$3aa8,_ReadFile		;Read file
		PL_R	$3aba			;Close file
		PL_L	$8118,$4eb80106		;Skip long game intro
		PL_PS	$adbe,_SavePatch	;move.w (4,a1),(0,a3)
        
        ; avoid too fast game
        PL_PS	$04d6,reset_game_loop_counter_1342
        PL_PS	$04e2,force_vbl_wait_game
        
        PL_PSS   $116C,count_vblank,2  ; vbl counter hook

         ; fix the "black screen after bomb" issue
        PL_PSS  $727A,fix_diw_loop,6
        PL_PSS  $7294,fix_diw_end_1342,10
        
        PL_PSS  $D00,fade_in_delay,8
        PL_PSS  $c86,fade_out_delay,8
		PL_END

_1342_Addys	dc.l	$b1c2			;High score position
		dc.l	$88a			;Level complete address
		dc.l	$8a6			;Delay after a level
		dc.l	$6888			;Infinite lives player 1
		dc.l	$68a0			;Infinite lives player 2
		dc.l	$7ae			;Level number

_1344_Addys	dc.l	$b21e			;High score position
		dc.l	$894			;Level complete address
		dc.l	$8ae			;Delay after a level
		dc.l	$6884			;Infinite lives player 1
		dc.l	$689c			;Infinite lives player 2
		dc.l	$7b6			;Level number

_PL_SPS_1344	PL_START
		; second button jumps if custom2 set
		PL_IFC2
		PL_PS	$3e04,load_joydat_0
		PL_PS	$3e14,load_joydat_1
		PL_ENDIF
		; pause/quit with keyboard AND joypad
		PL_P	$3d82,handle_pause_and_quit_1344
		; original codetapper fixes
		PL_S	$0,$38			;Close Workbench
		PL_L	$5e,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$7a,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$96,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$b2,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$ce,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$ea,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$106,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$122,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$13e,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$14a,5000		;Stack fix (was 1546)
		PL_L	$15a,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$176,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$192,$4eb80100		;jsr _LVOAllocMem(a6)
		PL_L	$1aa,$70ff4e71		;jsr _LVOOpenLibrary(a6)
		PL_L	$1b6,STACK_ADDRESS	;Stack to fast memory
		PL_L	$24a,$4e714e71		;Copy protection (safety)
		PL_L	$344,STACK_ADDRESS	;Stack to fast memory
		PL_L	$4fa,STACK_ADDRESS	;Stack to fast memory
		PL_PS	$e88,_BlitWait
		PL_S	$e8e,$96-$8e
		PL_W	$fe8,$4200		;Colour bit fix
		PL_PS	$10fc,_Keybd		;move.b $bfec01,d0
		PL_R	$3aae			;Open file
		PL_P	$3ac6,_ReadFile		;Read file
		PL_L	$810c,$4eb80106		;Skip long game intro
		PL_L	$9f8e,STACK_ADDRESS	;Stack to fast memory
		PL_PS	$ae1a,_SavePatch	;move.w (4,a1),(0,a3)
		PL_P	$db94,_Protec2518	;Copy protection (SPS 2518)

        ; avoid too fast game
        PL_PS	$9f86,reset_game_loop_counter_1344
        PL_PS	$9f92,force_vbl_wait_game
        
        PL_PSS   $1170,count_vblank,2  ; vbl counter hook

        ; jotd: fix the "black screen after bomb" issue
        PL_PSS  $726e,fix_diw_loop,6
        PL_PSS  $7288,fix_diw_end_1344,10

        PL_PSS  $0c8a,fade_in_delay,8
        PL_PSS  $0d04,fade_out_delay,8
		PL_END

;======================================================================

; about screens switching too quickly when JIT is on:
; original routine waited until VHPOSR reaches $FF
; it works, but this routine was often called several
; times in a row/in a loop, so on fast cpus when calling
; the routine twice, the dff006 value is ALREADY at ff
; and the loop has no effect
;
; problem is: on a slow machine, let's say if the loop
; happens 10 times, values may be the same every 2 calls
; which amounts to a 5 times loop. If we force value to be
; different then it's MUCH slower than expected...
; => we have to wait, but maybe reduce loop values
; but it doesn't matter much in non-JIT mode, let's NOT change anything
; beside forcing 25 Hz in game
;
; so back to "the programmer expects that 1,5 VBL has passed and waits for 2,
; when only 0,8 VBL has passed", so game is twice as fast.

reset_game_loop_counter_1344:
    jsr $3c10.W
 	movem.l	a0,-(a7)
	lea	last_counter(pc),a0
	clr.l	(a0)
	movem.l	(a7)+,a0
	rts

reset_game_loop_counter_1342:
    jsr $2B50.W
 	movem.l	a0,-(a7)
	lea	last_counter(pc),a0
	clr.l	(a0)
	movem.l	(a7)+,a0
	rts

count_vblank:
	movem.l	a1,-(a7)
	lea	vbl_counter(pc),a1
    add.l   #1,(a1)
    movem.l (a7)+,a1
    MOVE.W #$0020,$00dff09c
    rts
 
force_vbl_wait_game:
	bsr	wait_till_next_vbl
.w:
	CMPI.B	#$FF,$DFF006
	BNE.B	.w		;28FD8: 6600FFF6
	rts
   
fade_in_delay
fade_out_delay:
    movem.l d0,-(a7)
    move.l  #$A0,d0
    bsr beamdelay
    movem.l (a7)+,d0
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

wait_till_next_vbl:
	movem.l	d0/a0/a1,-(a7)
	lea	last_counter(pc),a0
	lea	vbl_counter(pc),a1
	
	move.l	(a0),d0
	beq.b	.first
	
	lea	last_counter(pc),a0
	tst.l	d0
	beq.b	.first
	bmi.b	.first	; reset before it wraps
	add.l	#1,d0
	; wait 1 VBL
.wait
;	move.w	#$0F0,$DFF180
	cmp.l	(a1),d0
	bcc.b	.wait
;	move.w	#$0,$DFF180
.first
	; store current counter
	move.l	(A1),(a0)
.avoid
	movem.l	(a7)+,d0/a0/a1
	rts
	
last_counter
	dc.l	0
vbl_counter
    dc.l    0
    
; bug of "black display after bomb" is because program
; is writing MSB of DIWSTRT/DIWSTOP. As the register is write-only
; and (probably) a higher end amiga can only write by 16-bits, there's
; a read cycle somewhere where LSB gets 0 and thus 0 is written in LSB
; resulting in display completely trashed

; fixing is done by writing as word, injecting the proper lsb value

fix_diw_loop:
    movem.l d0,-(a7)
    move.b  d2,d0
    lsl.w   #8,d0
    move.b  #$81,d0
	MOVE.B	D0,$dff08e
    move.b  d3,d0
    lsl.w   #8,d0
    move.b  #$c1,d0
	MOVE.B	D0,$dff090
    movem.l (a7)+,d0
    RTS

fix_diw_end_1342
	MOVE.W	#$2c81,$dff08e
	MOVE.W	#$f4c1,$dff090
    rts
    
fix_diw_end_1344
	MOVE.W	#$3481,$dff08e
	MOVE.W	#$fcc1,$dff090
    rts
    
handle_pause_and_quit_1344
	movem.l	d0/a1-a2,-(a7)
	move.l	_GameAddress(pc),a1
	lea	$12D2(a1),a2	; current keycode
	lea	$89C(a1),a1
	bsr	handle_pause_and_quit
	movem.l	(a7)+,d0/a1-a2
	RTS
	
handle_pause_and_quit_1342
	movem.l	d0/a1-a2,-(a7)
	move.l	_GameAddress(pc),a1
	lea	$12ce(a1),a2	; current keycode
	lea	$894(a1),a1
	bsr	handle_pause_and_quit
	movem.l	(a7)+,d0/a1-a2
	RTS
	
; d1: keycode
; a1: game quit flag address
handle_pause_and_quit
	bsr	_read_joysticks_buttons
	; handles pause press/release
	move.l	joy1_buttons(pc),d0
	btst	#JPB_BTN_PLAY,d0
	bne.b	.pause
	CMPI.B	#$50,(a2)		;3d82: 0c390050000012d2
	BNE.b	.no_pause		;3d8a: 66000026
	; wait until key/button is released
.pause:
	bsr	.wait_released

	; wait until key/button is pressed again
.pause_loop:
	CMPI.B	#$50,(a2)		;3d9a: 0c390050000012d2
	beq.b	.pause_exit		;3da2: 6600fff6
	bsr	_read_joysticks_buttons
	move.l	joy1_buttons(pc),d0
	btst	#JPB_BTN_PLAY,d0
	beq.b	.pause_loop
.pause_exit
	bsr	.wait_released
.no_pause
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.test_key
	btst	#JPB_BTN_FORWARD,d0
	bne.b	.quit
.test_key
	CMPI.B	#$59,(a2)		;3db2: 0c390059000012d2
	BNE.b	.no_quit		;3dba: 6600000a
	; F10: quit game
.quit
	MOVE.B	#$01,(A1)
.no_quit:
	RTS				;3dc6: 4e75
	
.wait_released
	CMPI.B	#$50,(a2)		;3d8e: 0c390050000012d2
	BEQ.b	.wait_released		;3d96: 6700fff6
	bsr	_read_joysticks_buttons
	move.l	joy1_buttons(pc),d0
	btst	#JPB_BTN_PLAY,d0
	bne.b	.wait_released
	rts

load_joydat_0
	clr.w	d0
	bra	load_joydat_xx

load_joydat_1
	move.w	#2,d0
load_joydat_xx
	; using 2nd button data, tamper with JOYxDAT value
	movem.l	d1-d2,-(a7)
	lea	$DFF00A,a0
	move.w	(a0,d0.w),d1	; joyxdat value
	lea	joy0_buttons(pc),a0
	add.w	d0,a0
	move.l	(a0,d0.w),d2	; read buttons value
	
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d1
	btst	#9,d1
	beq.b	.noneed
	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d2
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=0
.no_blue:
	lea		fake_joydat(pc),a0
	add.w	d0,a0		; set the address to reworked joy direction data
	move.w	d1,(a0)		; store the tampered-with value
	movem.l	(a7)+,d1-d2
	RTS
fake_joydat
	dc.l	0
	
;======================================================================

_ToggleLives	move.l	a0,-(sp)
		move.l	_LivesPlayer1(pc),a0
		eor.w	#$439^$6006,(a0)
		move.l	_LivesPlayer2(pc),a0
		eor.w	#$439^$6006,(a0)
		move.l	(sp)+,a0
		bsr	_SetCheat
		rts

;======================================================================

_LastLevel	move.l	a0,-(sp)
		move.l	_LevelNumber(pc),a0
		move.l	#99,(a0)
		bra	_Skip

_LevelSkip	move.l	a0,-(sp)
_Skip		move.l	_LevelDoneAddy(pc),a0	;Set the flag to show a
		move.w	#0,(a0)			;level is complete
		move.l	_DelayAddy(pc),a0	;Remove the stupid delay
		move.w	#1,(a0)			;so it's instant
		move.l	(sp)+,a0
		bsr	_SetCheat
		rts

;======================================================================

_SetCheat	move.l	a0,-(sp)
		lea	_CheatFlag(pc),a0
		st	(a0)
		move.l	(sp)+,a0
		rts

;======================================================================

_FireOnIntro	btst	#7,$bfe001
		beq	.SkipIt
		tst.b	($563,a0)		;Stolen code
.SkipIt		rts

;======================================================================

_Keybd	
		move.b	$bfec01,d0
		move.l	d0,-(sp)
		not.b	d0
		ror.b	#1,d0
		cmp.b	#$46,d0
		bne	.CheckHelp
		bsr	_ToggleLives
.CheckHelp	cmp.b	#$5f,d0
		bne	.CheckF9
		bsr	_LevelSkip
.CheckF9	cmp.b	#$58,d0
		bne	.KeyDone
		bsr	_LastLevel
.KeyDone	move.l	(sp)+,d0
		rts

;======================================================================

_BlitWait	BLITWAIT
		rts

;======================================================================

_Copylock1342	bsr	_TitlePic
		move.l	#$2daab0bd,d0		;Copylock key
		move.l	d0,$24
		rts

_Protec2518	bsr	_TitlePic
		moveq	#0,d0
		rts

;======================================================================

_DecryptSPS1343	movem.l	d0-d7/a0-a6,-(sp)

		move.l	#$a765bfd4,d0
		moveq	#0,d1
		move.l	#$c8410000,d2
		move.l	#$00481e02,d3
		moveq	#0,d4
		move.l	#$0448e2b0,d5

		lea	$84e(a5),a6
		adda.l	#$156,a6
		move.l	#$104a4,d6
.DecryptLoop	add.l	d5,d0
		add.l	d0,d1
		add.l	d1,d2
		add.l	d2,d3
		add.l	d3,d4
		add.l	d4,d5
		sub.l	d5,(a6)+
		subq.l	#4,d6
		bne	.DecryptLoop

		lea	$870(a5),a6
		move.l	a6,d6
		subi.l	#$850,d6		;d6 = $20
		adda.l	#$134,a6		;a6 = $9a4

		movem.l	d0-d2/a0-a2,-(sp)
		cmpi.w	#$3E9,(2,a6)		;HUNK_CODE
		bne	.HunksDone
		move.l	(4,a6),d0
		lsl.l	#2,d0
		lea	(8,a6),a1
		lea	(a1,d0.l),a2
		cmpi.l	#$3EC,(a2)+		;HUNK_RELOC32
		bne	.HunksDone
.NextHunk	move.l	(a2)+,d1
		beq	.HunksDone
		move.l	(a2)+,d0
		bsr	.lbC0008C2
		move.l	a0,d2
		tst.l	(-4,a2)
		bne	.RelocLoop
		move.l	d6,d2
		sub.l	#$20,d2			;Added by Ian!
.RelocLoop	move.l	(a2)+,d0
		add.l	d2,(a1,d0.l)
		subq.l	#1,d1
		bne	.RelocLoop
		bra	.NextHunk

.lbC0008C2	movea.l	d6,a0
		subq.l	#4,a0
		tst.l	d0
		beq	.lbC0008D4
		bra	_exit			;Error!
.lbC0008D4	addq.l	#4,a0
		rts

.HunksDone	movem.l	(sp)+,d0-d2/a0-a2

		lea	$9ac(a5),a0		;a0 = Copy from
		movea.l	a0,a1
		suba.l	#$9ac,a1		;a1 = Copy to (originally $98c - changed by Ian!)
		movea.l	#$de00,a2		;a2 = Bytes to copy
		movea.l	#$3028,a3		;a3 = Bytes clear
		movea.l	a1,a4			;a4 = Return address

		move.l	a2,d0
		beq.b	.NoReloc
		cmpa.l	a0,a1
		ble.b	.CopyAscLoop
		adda.l	d0,a0
		adda.l	d0,a1
.CopyDescLoop	move.l	-(a0),-(a1)
		subq.l	#4,d0
		bne.b	.CopyDescLoop
		bra.b	.CheckClear

.CopyAscLoop	move.l	(a0)+,(a1)+
		subq.l	#4,d0
		bne.b	.CopyAscLoop
.CheckClear	move.l	a3,d0
		beq.b	.NoReloc
.ClearLoop	clr.l	(a1)+
		subq.l	#4,d0
		bne.b	.ClearLoop

.NoReloc	movem.l	(sp)+,d0-d7/a0-a6
		rts

;======================================================================

_TitlePic	movem.l	d0-d1/a0-a2,-(sp)

		move.l	_ButtonWait(pc),d0
		tst.l	d0
		beq	_ShortDelay

		move.l	#5*60*50,d0		;Wait 5 minutes
		bra	_PicDelay

_ShortDelay	move.l	#10,d0			;Wait 1 second
_PicDelay	move.l	_resload(pc),a2
		jsr	resload_Delay(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_DefaultNames	movem.l	d0/a0-a1,-(sp)
		lea	_HighScoreNames(pc),a0
		move.l	_HighScoresPos(pc),a1
		add.l	#$5e,a1
.CopyNames	move.b	(a0)+,d0
		tst.b	d0
		beq	.Done
		move.b	d0,(a1)+
		bra	.CopyNames
.Done		movem.l	(sp)+,d0/a0-a1
		rts

;======================================================================

_SavePatch	move.w	(4,a1),(0,a3)		;Stolen code

		move.l	(sp),-4(sp)		;This mess splices in a
		add.l	#4,sp			;jsr to the _SaveHighScores
		pea	_SaveHighScores(pc)	;routine!
		sub.l	#4,sp
		rts

;======================================================================

_LoadHighScores	movem.l	d0-d1/a0-a3,-(sp)

		move.l	_HighScoresPos(pc),a1	;High scores location
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

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	_HighScoresPos(pc),a1	;High scores location
		move.l  _resload(pc),a2
		bsr	_Encrypt		;Encrypt scores
		move.l	a1,-(sp)
		jsr	resload_SaveFile(a2)	;Save scores
		move.l	(sp)+,a1
		bsr	_Encrypt		;Decrypt scores

		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Encrypt	move.l	#110,d0			;Set d0 = length
		move.l	d0,-(sp)
.enc		eor.b	d0,(a1)+
		subq.l	#1,d0
		bne.s	.enc
		move.l	(sp)+,d0
		sub.l	d0,a1
		rts

;======================================================================

_AllocMem	movem.l	d1-d2/a1,-(sp)
		lea	_FreeMem(pc),a1		;Current free memory
		move.l	(a1),d1
		move.l	d1,d2			;Give this to the program
		add.l	#$ff,d0		;Round to nearest $100 for
		and.l	#$ffffff00,d0		;safety
		add.l	d0,d1
		move.l	d1,(a1)			;Store new free memory

		cmp.l	#CHIPMEM,d1
		bhi	_NoMem

		asr.l	#4,d0
		move.l	d2,a0
.clear		clr.l	(a0)+			;Clear the memory
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		dbf	d0,.clear
		move.l	d2,a0
		move.l	d2,d0

		movem.l	(sp)+,d1-d2/a1
		rts

_NoMem		move.l	#'MEM ',$0
		move.l	#'ERR ',$4
		bra	_exit

;======================================================================

_ReadFile	movem.l	d0-d1/a0-a2,-(sp)
		move.l	d1,a0			;d1 = Filename
		move.l	d2,a1			;d2 = Destination
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_LoadFile	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Relocate	movem.l	d0-d1/a0-a2,-(sp)
		move.l	a5,a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Relocate(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Level3Int	move.l	d0,-(sp)
		move.w	$dff01e,d0
		and.w	#$70,d0
		move.w	d0,$dff09c
		move.l	(sp)+,d0
		nop
		nop
		nop
		nop
		rte

;======================================================================

		INCLUDE	keyboard.s
		INCLUDE ReadJoyPad.s
		
;======================================================================
_resload	dc.l	0			;Resident loader
_GameAddress	dc.l	GAME_ADDRESS
_FreeMem	dc.l	FREEMEM_ADDRESS
_Tags		dc.l	WHDLTAG_BUTTONWAIT_GET
_ButtonWait	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_Custom1	dc.l	0
		dc.l	TAG_DONE
;======================================================================
_GameParams
_HighScoresPos	dc.l	0			;Retain this order!
_LevelDoneAddy	dc.l	0
_DelayAddy	dc.l	0
_LivesPlayer1	dc.l	0
_LivesPlayer2	dc.l	0
_LevelNumber	dc.l	0
GAME_PARAM_CNT	equ	(*-_GameParams)/4
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		END
