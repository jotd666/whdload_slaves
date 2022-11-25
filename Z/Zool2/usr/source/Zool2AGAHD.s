;*---------------------------------------------------------------------------
; Program:	Zool2AGA.s
; Contents:	Slave for "Zool 2 AGA" from Gremlin
; Author:	Codetapper of Action
; History:	28.05.02 - v1.0
;		         - Full load from HD
;		         - 3 versions supported 
;		         - Manual protection removed (screen no longer appears)
;		         - NTSC protection removed
;		         - Loads and saves high scores (unless you cheat)
;		         - Disk requesters removed
;		         - Snoop bugs fixed
;		         - Access faults removed
;		         - Blitter waits added (x12)
;		         - Decruncher relocated to fast memory
;		         - Trainer added (set CUSTOM1=1 to enable cheat, CUSTOM2=1-6 for start level)
;		         - MagicWB, RomIcon, NewIcon and GlowIcon (all created by Frank!) and 2 
;		           Exoticons included (taken from http://exotica.fix.no)
;		         - Quit option (default key is 'F10')
; Requires:	WHDLoad 13+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Cheat Info:	CUSTOM1<>0 to enable cheat mode
; 		CUSTOM2=1-6 for starting level (high scores will save)
;
;		Codes are stored in the game as raw keycodes (for USA keymap) from
;		$15e84 to $15f0c in the main game in following order:
;
;		      $0001 creamola__________________________________10 lives
;		      $0002 vision____________________________________20 lives
;		      $0004 kickass______________________Unlimited smart bombs
;		      $0008 napoleon___________________Bonus level every stage
;		      $0010 alcento_________________________99 items collected
;		      $0020 oldenemy____________________________Unlimited time
;		      $0040 toughguy_____________________________Invincibility
;		      $0080 sesame____________________________Start on level 1
;		      $0100 ronson____________________________Start on level 2
;		      $0200 funkytut__________________________Start on level 3
;		      $0400 hissteria_________________________Start on level 4
;		      $0800 7slurp____________________________Start on level 5
;		      $1000 plunger___________________________Start on level 6
;		      $2000 marrobone________Stops the ball on the bonus level
;		      $4000 bumblebee_____Skip stages (press 'RETURN' to skip)
;		      $8000 warpmode___________________________________Unknown
;
;		The game checks for matches at $15d96 and if a code is correct, the
;		routine at $15e04 is run which bit sets $e7e to the value shown in
;		the list and flashes the screen red for one frame.
;
;		To check for cheating, simply check $e7e for <> 0.
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		INCLUDE	lvo/dos.i
		INCLUDE	lvo/exec.i

		IFD BARFLY
		OUTPUT	"Zool2AGA.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

CHIP_ONLY = 1
    IFD CHIP_ONLY
CHIPMEMSIZE	= $1C0000
FASTMEMSIZE	= $0
    ELSE
CHIPMEMSIZE	= $190000
FASTMEMSIZE	= $80000
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

QUIT_JOYPAD_MASK = JPF_BUTTON_FORWARD|JPF_BUTTON_REVERSE|JPF_BUTTON_PLAY


;DISKSONBOOT
DOSASSIGN
;DEBUG	; leave commented (I think because of nonvolatile.library strange packets...)
HDINIT
INITAGA
;HRTMON
IOCACHE		= 4000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE
DUMMY_CD_DEVICE = 1

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_Examine|WHDLF_ReqAGA|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	kick31cd32.s
    include ReadJoyPad.s

;======================================================================


slv_config:
        dc.b    "C1:X:game trainer:0;"
        dc.b    "C1:X:unlimited smart bombs:1;"
        dc.b    "C1:X:game original cheatkeys:2;"
        dc.b    "C2:B:alternate controls;"
        dc.b    "C3:L:select start world:1,2,3,4,5,6,7 (CD32);"
        dc.b    0
;============================================================================
    IFD    BARFLY
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC
        ENDC
        
DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name		dc.b	"Zool 2 AGA"
                IFD CHIP_ONLY
                dc.b    " (CHIP/DEBUG MODE)"
                ENDC
                dc.b    0
slv_copy		dc.b	"1993 Gremlin",0
slv_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version "
        DECL_VERSION
		dc.b	-1,"Thanks to Chris Vella for the AGA version"
		dc.b	10,"and Mad-Matt for the ECS version!"
		dc.b	0
slv_CurrentDir		dc.b	"data",0
_DosName	dc.b	"dos.library",0
_Arguments	dc.b	10,0
_MainFile_AGA	dc.b	"z2",0
_MainFile_CD32	dc.b	"zool2",0
_Highs		dc.b	"Zool2.highs",0
_DiskNumber	dc.b	1
_CheatFlag	dc.b	0

disk1
    dc.b    "z2d1",0
disk2
    dc.b    "z2d2",0

		EVEN

;======================================================================
_bootdos	;	A0 = resident loader
;======================================================================

        lea	_Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)

		move.l	$4.w,a6			;Open dos library
		moveq	#0,d0
		lea	_DosName(pc),a1
		jsr	_LVOOpenLibrary(a6)

		lea	_DosBase(pc),a4		;Store dos base
		move.l	d0,(a4)
		move.l	d0,a6
	;assigns
		lea	disk1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	disk2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
        
        
        bsr _detect_controller_types

		lea	_MainFile_AGA(pc),a0	;Load main file
        jsr (resload_GetFileSize,a2)
        tst.l   d0
        beq _cd32_version
        
        IFD CHIP_ONLY
        ; useful to align first segment on $20000 address
        ; when using the packed version
        movem.l a6,-(a7)
		move.l	$4.w,a6			;Open dos library
        move.l  #$3DA8,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

		lea	_MainFile_AGA(pc),a0	;Load main file
		move.l	a0,d1
        move.l  a0,a3
		jsr	_LVOLoadSeg(a6)

		tst.l	d0
		beq	_loadseg_error

		lsl.l	#2,d0
		move.l	d0,a1
		addq.l	#4,a1			;$11c88 / $11f08

        
		cmp.l	#$2e814cdf,$234(a1)	;Original propacked file
		beq	_Propacked

		cmp.l	#$2c780004,$8(a1)	;Decrunched file
		bne	_wrongver

		move.l	a1,a5
		bra	_GameCommon_AGA
_cd32_version
	IFND	USE_DISK_LOWLEVEL_LIB
	lea	OSM_JOYPAD1KEYS(pc),a0
	move.w	#$4019,2(a0)	; yellow ??, P = pause
	move.w	#$4545,4(a0)	; both charcoal: ESC so ESC quits the game in pause mode
	move.w	#$4040,(a0)	;blue/green: SPACE = bomb
    ENDC
    
        bsr _patch_cd32_libs

        IFD CHIP_ONLY
        ; useful to align first segment on $20000 address
        movem.l a6,-(a7)
		move.l	$4.w,a6			;Open dos library
        move.l  #$4038,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

                
		lea	_MainFile_CD32(pc),a0	;Load main file
		move.l	a0,d1
        move.l  a0,a3
		jsr	_LVOLoadSeg(a6)

		tst.l	d0
		beq	_loadseg_error

		lsl.l	#2,d0
		move.l	d0,a1
		addq.l	#4,a1			;$11c88 / $11f08


		move.l	a1,a5
		bra	_GameCommon_CD32
_loadseg_error
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
    
;======================================================================

_Propacked	movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_Boot(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2
		
		lea	_Arguments(pc),a0
		moveq	#1,d0
		
		jmp	(a1)

_PL_Boot	PL_START
		PL_P	$234,_Game
		PL_END

;======================================================================
STORE_ADDRESS:MACRO
    lea \1(pc),a0
    move.l  \3,d0
    add.l   #\2,d0
    move.l  d0,(a0)
    ENDM

_Game		
    move.l	d1,(sp)			;Stolen code
	movem.l	(sp)+,d0-d7/a0-a6	
	move.l	(sp)+,a5

    
_GameCommon_AGA
    movem.l	d0-d2/a0-a2,-(sp)

    ;Store high scores load address
    ;this is the address of the default
    ;highscore table at startup
    STORE_ADDRESS   _HighsAddress,$17b04,a5
    STORE_ADDRESS   _MenuControlReturnAddress,$164E8,a5
    STORE_ADDRESS   _CheatAddress,$e7e,a5

    ; datasection
    move.l  (-4,a5),a1
    add.l   a1,a1
    add.l   a1,a1
    addq.l  #4,a1
    STORE_ADDRESS   _CharacterStatusAddress,$1e134-$018cd4,a1
    STORE_ADDRESS   _KeyrecAddress,$1e1c6-$018cd4,a1
    STORE_ADDRESS   _SvHighsAddress,$18ee2-$18cd4,a1      
    move.l  #6,d3
    bsr	_CheckCheats
    
    bsr	_LoadHighScores

    lea	_PL_Game_AGA(pc),a0
    move.l	a5,a1
    move.l	_resload(pc),a2
    jsr	resload_Patch(a2)

    lea	_PL_LowMem(pc),a0
    sub.l	a1,a1
    jsr	resload_Patch(a2)

    movem.l	(sp)+,d0-d2/a0-a2
    jmp	(a5)

_PL_LowMem	PL_START
    PL_P	$100,_Blt_d1_58_a5
    PL_P	$106,_Blt_d7_58_a5
    PL_END

_PL_Game_AGA	PL_START
    ;;PL_PS	$632,_Keybd
    ;PL_PSS  $aec,stop_sound,2
    PL_PSS    $00109e,cpu_delay,2
    PL_PSS    $011fd6,cpu_delay,2
    PL_PSS    $012030,cpu_delay,2
    PL_PSS    $015b6a,cpu_delay_longer,2
    PL_PSS    $015cd0,cpu_delay_longer,2
    PL_PSS    $0178f6,cpu_delay_longer,2
    
    PL_PSS  $004656,pause_test_d0,2
    PL_PSS  $00477e,esc_test,2
    PL_PSS  $004774,pause_test_chk,2
    PL_PSS  $00478a,pause_test_chk,2
    PL_PSS  $004794,pause_test_chk,2
    PL_PSS  $01286e,pause_test,2
    PL_PSS  $01287a,pause_test_chk,2
    PL_PSS  $012884,pause_test_chk,2
    PL_PSS  $01288e,pause_test_chk,2
    
    PL_P	$8dc,_Decruncher
    PL_S	$b6a,6			;Remove manual protection :)
    PL_PS	$28b0,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
    PL_PS	$3784,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
    PL_PS	$b508,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
    PL_PS	$b5dc,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
    PL_L	$c5ee,$4eb80106		;move.w d7,($58,a5)
    PL_L	$c6fc,$4eb80106		;move.w d7,($58,a5)
    PL_L	$c8a0,$4eb80100		;move.w d1,($58,a5)
    PL_PS	$f422,_Blt_8818_58_a5	;move.w #$8818,($58,a5)
    PL_P	$f470,_Blt_8818_58_a5	;move.w #$8818,($58,a5)
    PL_NOP	$13858,4	;Don't request disk 1
    PL_S	$13860,6		;1 second delay in disk swap
    PL_NOP	$13920,4	;Don't request disk 2
    PL_S	$13928,6		;1 second delay in disk swap
    PL_PS	$15e3c,_SetCheatBit
    PL_PSS	$16a22,_SaveHighScores,2	;Save high scores

    PL_NOP	$16dae,4	;Remove manual protection
    PL_NOP	$16db2,4	;(not needed really!)
    PL_NOP	$16dbc,4
    PL_NOP	$16dc6,4
    PL_NOP	$16dca,4
    PL_NOP	$16dd4,4
    PL_NOP	$16de6,4
    PL_P	$17f1e,_Decruncher
    PL_PS	$182f8,_SoundFault

    PL_IFC1X    1
    PL_NOP  $002c10,4   ; unlimited smart bombs
    PL_ENDIF

    PL_IFC1X    2
    PL_NOP  $004692,4   ; cheatkeys
    PL_NOP  $004672,4   ; levelskip
    PL_ENDIF
            
    PL_IFC2
    PL_PS   $00f55c,read_joypad
    PL_ELSE
    PL_PS   $00f55c,read_controls
    PL_ENDIF
    
    PL_PSS  $00f590,read_fire,2
    
    PL_PSS  $0183e4,dma_wait,2
    PL_PSS  $01840c,dma_wait,2
    
    PL_PS   $018a7e,dma_wait_2
    PL_PS   $018a9a,dma_wait_2
    PL_END

pause_test_chk
    movem.l d0/a0,-(a7)
	; wait for VBL
	lea	$DFF000,a0
	move.w	#$7FFF,intreq(a0)
.wait
	move.w	intreqr(a0),d0
	btst	#5,d0
	beq.b	.wait
	moveq	#1,d0
	bsr	_read_joystick
	lea	joy1_buttons(pc),a0
	move.l	d0,(a0)    
    movem.l (a7)+,d0/a0
pause_test
    movem.l d0/a0,-(a7)
    move.l  joy1_buttons(pc),d0
    not.l   d0
    btst    #JPB_BTN_PLAY,d0
    beq.b   .pressed
    move.l  _KeyrecAddress(pc),a0
    cmp.b  #$cd,(a0)
.pressed
    movem.l (a7)+,d0/a0
    rts
esc_test
    movem.l d0/a0,-(a7)
    move.l  joy1_buttons(pc),d0
    not.l   d0
    btst    #JPB_BTN_FORWARD,d0
    bne.b   .keytest
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .pressed
.keytest
    move.l  _KeyrecAddress(pc),a0
    cmp.b  #$75,(a0)
.pressed
    movem.l (a7)+,d0/a0
    rts

pause_test_d0
    movem.l d1/a0,-(a7)
    move.l  joy1_buttons(pc),d1
    not.l   d1
    btst    #JPB_BTN_PLAY,d1
    beq.b   .pressed
    cmp.b  #$cd,d0
.pressed
    movem.l (a7)+,d1/a0
    bne.b   .nobranch
    add.l   #$4774-$465C,(a7)
.nobranch
    rts

cpu_delay
	move.w  d0,-(a7)
    move.w  #6,D0
    bsr beam_delay
	move.w	(a7)+,d0
    rts
cpu_delay_longer
	move.w  d0,-(a7)
    move.w  #60,D0
    bsr beam_delay
	move.w	(a7)+,d0
    rts
    
dma_wait_2
    MOVE.W	D6,$dff096
    bra st_wait

dma_wait
    MOVE.W	(26,A4),$dff096
st_wait
	move.w  d0,-(a7)
	move.w	#4,d0
    bsr beam_delay
	move.w	(a7)+,d0
    rts
beam_delay
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	rts
    
read_controls:
    movem.l d0/a0,-(a7)
	moveq	#1,d0
	bsr	_read_joystick

	lea	joy1_buttons(pc),a0
	move.l	d0,(a0)
    movem.l (a7)+,d0/a0
	MOVE.W	$DFF00C,D6
    rts
    
read_joypad:
    bsr read_controls
	movem.l	d0/a0,-(a7)
    move.l  _MenuControlReturnAddress(pc),a0
    cmp.l   ($18,a7),a0
    beq.b   .no_blue     ; called from the menu => ignore
    
    move.l  joy1_buttons(pc),d0
	move.l	_CharacterStatusAddress(pc),a0
    cmp.w   #3,(a0)
	beq.b	.no_blue    ; climbing, ignore
	
	bclr	#8,D6
	btst	#9,D6
	beq.b	.noneed
	bset	#8,D6	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,D6
	btst	#9,D6
	bne.b	.no_blue
	bset	#8,D6	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	movem.l	(a7)+,d0/a0
	RTS    
    
read_fire    
    movem.l D0,-(a7)
    move.l  joy1_buttons(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts
    
_GameCommon_CD32
        movem.l	d0-d3/a0-a2,-(sp)
        
        IFEQ    1
        ;Store high scores load address
        ;this is the address of the default
        ;highscore table at startup
		lea	_HighsAddress(pc),a0
		move.l	a5,d0
		add.l	#$018d00,d0
		move.l	d0,(a0)
		lea	_SvHighsAddress(pc),a0	;Store high scores save address
		move.l	a5,d0
		add.l	#$01a114,d0
		move.l	d0,(a0)
        ENDC

		lea	_CheatAddress(pc),a0	;Store cheat address
		move.l	a5,d0
		add.l	#$00165a,d0
		move.l	d0,(a0)

        move.l  #7,d3
		bsr	_CheckCheats
		;;bsr	_LoadHighScores

		lea	_PL_Game_CD32(pc),a0
		lea	(-4,a5),a1
        move.l  a1,d1
        lsr.l   #2,d1
        move.l  d1,a1   ; BCPL pointer on segments
		move.l	_resload(pc),a2
		jsr	resload_PatchSeg(a2)

;		lea	_PL_LowMem(pc),a0
;		sub.l	a1,a1
;		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d3/a0-a2
		jmp	(a5)

_PL_Game_CD32	PL_START
		PL_P	$0002b2,_Decruncher
;		PL_PS	$28b0,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
;		PL_PS	$3784,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
;		PL_PS	$b508,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
;		PL_PS	$b5dc,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
;		PL_L	$c5ee,$4eb80106		;move.w d7,($58,a5)
;		PL_L	$c6fc,$4eb80106		;move.w d7,($58,a5)
;		PL_L	$c8a0,$4eb80100		;move.w d1,($58,a5)

;		PL_PS	$0101a0,_Blt_8818_58_a5	;move.w #$8818,($58,a5)
;		PL_P	$0101ec,_Blt_8818_58_a5	;move.w #$8818,($58,a5)

		PL_PS	$016f02,_SetCheatBit

		PL_P	$019120,_Decruncher
		PL_PS	$0194fa,_SoundFault
        
        PL_IFC1
        ; disable save highscores to nvram if cheat used
        PL_R     $16e4be
        PL_ENDIF
        
        PL_IFC1X    1
        PL_NOP  $003432,4   ; unlimited smart bombs
        PL_ENDIF
        PL_IFC1X    2
        PL_NOP  $004e86,4   ; cheatkeys
        PL_NOP  $004e62,4   ; levelskip
        PL_ENDIF
        
        PL_IFC2
        ; swap buttons so it's much more standard
        PL_L    $16e638+2,JPF_BUTTON_RED   ; fire
        PL_L    $16e64c+2,JPF_BUTTON_BLUE   ; jump
        PL_L    $16e66c+2,JPF_BUTTON_GREEN  ; smart bomb
        PL_L    $16e694+2,JPF_BUTTON_REVERSE    ; kill
        PL_L    $16e6a0+2,JPF_BUTTON_FORWARD

        PL_L    $16e6b4+2,JPF_BUTTON_BLUE   ; blue+red: spin
        PL_ENDIF
        
        ; sfx by default
        PL_B   $01a104,$FF
        
		PL_END
;======================================================================

_CheckCheats	movem.l	d0-d2/a0,-(sp)

		move.w	#0,d2			;d2 = Cheat value
		move.l	_Custom1(pc),d0		;Check CUSTOM1=Cheat mode
		tst.l	d0			;on the cheat mode
		beq	_NoCheat

        btst    #0,d0
        beq.b   _NoCheat
		move.w	#$c076,d2		;Set default cheats
		bsr	_SetCheatFlag

_NoCheat
        move.l	_start_level(pc),d0		;Check CUSTOM3=Start level
        beq.b   _NoStartLevel
        addq.l  #1,d0
		moveq	#0,d1			;d1 = Initial level mask
		cmp.l	#1,d0
		ble	_NoStartLevel
		cmp.l	d3,d0
		ble	_SetLevel
		move.l	d3,d0			;7 = Maximum start level

_SetLevel	addq	#6,d0
		bset	d0,d2			;Add in start level cheat

_NoStartLevel	move.l	_CheatAddress(pc),a0
		move.w	d2,(a0)
		movem.l	(sp)+,d0-d2/a0
		rts

;======================================================================

_SoundFault	and.l	#$7f,d2
		move.l	(a1,d2.l),(4,a4)	;Stolen code
		rts

;======================================================================

_Keybd		move.b	d0,d1
		lsl.b	#1,d1
		not.b	d1
		cmp.b	_keyexit(pc),d1
		beq	_exit
		rts

;======================================================================

_SetCheatBit	movem.l	d1/a0,-(sp)
		move.l	_CheatAddress(pc),a0
		move.w	d1,(a0)
		and.w	#$e07f,d1
		tst.w	d1
		beq	_LevelCodeOnly		;User just wants to start
		bsr	_SetCheatFlag		;on a level
_LevelCodeOnly	movem.l	(sp)+,d1/a0
		rts

_SetCheatFlag	move.l	a0,-(sp)
		lea	_CheatFlag(pc),a0
		move.b	#-1,(a0)
		move.l	(sp)+,a0
		rts

;======================================================================

_Blt_d1_58_a5	move.w	d1,($58,a5)
		bra	_BlitWait

_Blt_d7_58_a5	move.w	d7,($58,a5)
		bra	_BlitWait

_Blt_1001_58_a5	move.w	#$1001,($58,a5)
		bra	_BlitWait

_Blt_8818_58_a5	move.w	#$8818,($58,a5)
;		bra	_BlitWait

_BlitWait	btst	#6,$dff002
		bne	_BlitWait
		rts

;======================================================================

_LoadHighScores	movem.l	d0-d1/a0-a3,-(sp)
		move.l	_HighsAddress(pc),a1	;a1 = Address ($17b04 from start)
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
		tst.b	d0
		bne	_DoNotSave

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	_SvHighsAddress(pc),a1	;a1 = Address
		move.l  _resload(pc),a2
		bsr	_Encrypt		;Encrypt scores
		move.l	a1,-(sp)
		jsr	resload_SaveFile(a2)	;Save scores
		move.l	(sp)+,a1
		bsr	_Encrypt		;Decrypt scores

_DoNotSave	movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Encrypt	move.l	#112,d0			;Set d0 = length
		move.l	d0,-(sp)
.enc		eor.b	d0,(a1)+
		subq.l	#1,d0
		bne.s	.enc
		move.l	(sp)+,d0
		sub.l	d0,a1
		rts

;======================================================================

_Decruncher	move.b	(a0)+,d7
		btst	#7,d7
		bne.w	_Dec_10
		btst	#6,d7
		beq.w	_Dec_8
		btst	#5,d7
		bne.w	_Dec_4
		btst	#4,d7
		bne.w	_Dec_2
		andi.w	#15,d7
		addq.w	#2,d7
		move.b	(-2,a1),d6
		move.b	(-1,a1),d5
		sub.b	d6,d5
		move.b	(-1,a1),d6
		add.b	d5,d6
_Dec_1		move.b	d6,(a1)+
		add.b	d5,d6
		dbra	d7,_Dec_1
		bra.w	_Dec_15

_Dec_2		andi.w	#15,d7
		addq.w	#1,d7
		move.b	(-4,a1),d6
		lsl.w	#8,d6
		move.b	(-3,a1),d6
		move.b	(-2,a1),d5
		lsl.w	#8,d5
		move.b	(-1,a1),d5
		sub.w	d6,d5
		move.b	(-2,a1),d6
		lsl.w	#8,d6
		move.b	(-1,a1),d6
		add.w	d5,d6
_Dec_3		move.w	d6,d4
		move.b	d4,(1,a1)
		lsr.w	#8,d4
		move.b	d4,(a1)
		addq.l	#2,a1
		add.w	d5,d6
		dbra	d7,_Dec_3
		bra.w	_Dec_15

_Dec_4		btst	#4,d7
		bne.w	_Dec_6
		andi.w	#15,d7
		addq.w	#2,d7
		move.b	(-1,a1),d6
_Dec_5		move.b	d6,(a1)+
		dbra	d7,_Dec_5
		bra.w	_Dec_15

_Dec_6		andi.w	#15,d7
		addq.w	#1,d7
		move.b	(-2,a1),d6
		lsl.w	#8,d6
		move.b	(-1,a1),d6
_Dec_7		move.w	d6,d4
		move.b	d4,(1,a1)
		lsr.w	#8,d4
		move.b	d4,(a1)
		addq.l	#2,a1
		dbra	d7,_Dec_7
		bra.w	_Dec_15

_Dec_8		andi.w	#$3F,d7
		beq.w	_Dec_16
		subq.w	#1,d7
_Dec_9		move.b	(a0)+,(a1)+
		dbra	d7,_Dec_9
		bra.w	_Dec_15

_Dec_10		btst	#6,d7
		beq.w	_Dec_14
		btst	#5,d7
		beq.w	_Dec_13
		andi.w	#$1F,d7
		lsl.w	#8,d7
		move.w	d7,d5
		move.b	(a0)+,d5
		addq.w	#3,d5
		moveq	#0,d7
		move.b	(a0)+,d7
		addq.w	#5,d7
_Dec_11		subq.w	#1,d7
		neg.w	d5
		lea	(a1),a2
		lea	(a2,d5.w),a2
_Dec_12		move.b	(a2)+,(a1)+
		dbra	d7,_Dec_12
		bra.w	_Dec_15

_Dec_13		move.b	d7,d6
		andi.w	#$1C,d7
		andi.w	#3,d6
		lsl.w	#8,d6
		move.w	d6,d5
		move.b	(a0)+,d5
		addq.w	#3,d5
		lsr.w	#2,d7
		addq.b	#4,d7
		andi.w	#$FF,d7
		bra.w	_Dec_11

_Dec_14		andi.w	#$3F,d7
		move.w	d7,d5
		addq.w	#3,d5
		moveq	#3,d7
		bra.w	_Dec_11

_Dec_15		bra.w	_Decruncher

_Dec_16		rts

;======================================================================
_DosBase	dc.l	0
_HighsAddress	dc.l	0
_SvHighsAddress	dc.l	0
_CheatAddress	dc.l	0
_CharacterStatusAddress dc.l    0
_KeyrecAddress      dc.l       0
_MenuControlReturnAddress   dc.l    0

_Tags		dc.l	WHDLTAG_CUSTOM1_GET
_Custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_start_level	dc.l	0
		dc.l	TAG_DONE
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		END
