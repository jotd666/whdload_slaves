;*---------------------------------------------------------------------------
;  :Program.	BlastarHD.asm
;  :Contents.	Slave for "Blastar" from Core Design
;  :Author.	JOTD
;  :History.	
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	Apprentice.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

USE_FASTMEM

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem	
	dc.l	$1000
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
_config
    dc.b    "C1:X:Trainer Infinite Lives:0;"
    dc.b    "C1:X:Trainer start with 1000 coin:1;"
    dc.b    "C2:B:use blue/second button to jump;"
    dc.b    "C3:L:Start level:1,2,3,4,5,6,7,8,9,10,11,12,13,14,"
    dc.b    "15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,"
    dc.b    "33,34,35,36,37;"			
    dc.b	0
    
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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
    
_name		dc.b	"Apprentice"
		dc.b	0
_copy		dc.b	"1990 Rainbow Arts",0
_info		dc.b	"adapted by Ralf & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$VER: slave "
	DECL_VERSION
    dc.b    0
	even

IGNORE_JOY_DIRECTIONS
BASE_ADDRESS = $70000
TITLE =	$20002
GAME = $AA00
SCORES_LEN = $50

    include ReadJoyPad.s
    
;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	a0,a2
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

        ; relocate stack in fastmem (Bert)
		move.l  _expmem(pc),d0
        add.l   #$1000,d0
        move.l  d0,a7

		; load & version check

		lea	BASE_ADDRESS,A0
		move.l	#$400,D0		; offset
		move.l	#$1200,D1		; length
		moveq	#1,D2
		bsr	_loaddisk


		lea	pl_boot(pc),a0
		lea	BASE_ADDRESS,A1
		jsr	resload_Patch(a2)
		
		jmp	BASE_ADDRESS


pl_boot
	PL_START
	PL_PS	$DE,MY_TITLE
	PL_PS	$11A,MY_GAME
	;;PL_P	$12A,MY_MAINIRQ
	PL_P	$142,MY_LOADER
	PL_P	$1D4,MY_SAVE
	PL_END

MY_TITLE
	MOVEM.L	D0-D1/A0-A2,-(A7)

    move.l  _resload(pc),a2
    lea pl_title(pc),a0
    sub.l   a1,a1
    jsr (resload_Patch,a2)
	
	MOVEM.L	(A7)+,D0-D1/A0-A2
	JMP	TITLE
    
MY_GAME    
	MOVEM.L	D0-D1/A0-A2,-(A7)
    bsr _detect_controller_types

    move.l  _resload(pc),a2
    lea pl_game(pc),a0
    sub.l   a1,a1
    jsr (resload_Patch,a2)

	MOVEM.L	(A7)+,D0-D1/A0-A2

    move.l  trainer(pc),d0
    btst    #1,d0
    beq.b   .nomoney
    move.w  #1000,$c82a
.nomoney
    move.l  start_level(pc),d0
    cmp.l   #37,d0
    bcs.b   .ok
    moveq.l #0,d0 
.ok
	JMP	GAME

MY_LOADER
	MOVEM.L	D0-A6,-(A7)

	CMP.B	#$B0,D0
	BEQ	.LOAD_SCORES

	MOVE.L	D0,D1
	LEA	(A0),A1
	AND.L	#$000000FF,D1
	ROL.L	#3,D1
	LEA	$820,A0     ; file table
	MOVEQ	#0,D3
	MOVE.L	D3,D4
	MOVE.L	D4,D5
	MOVE.L	0(A0,D1),D2
	MOVE.B	4(A0,D1),D3
	MOVE.B	5(A0,D1),D4
	MOVE	6(A0,D1),D5
	ADD.L	D3,D3
	AND.L	#$00000001,D4
	ADD.L	D4,D3
	MULU	#$1838,D3
	MOVEQ	#0,D0

	; d2: length in bytes
	; d3+d5: offset
	; a1: address

	move.l	d2,d1		; length
	move.l	d3,d0   ; offset
	add.l	d5,d0		; offset
	move.l	a1,a0		; destination
	moveq.l	#1,D2		; disk 1	
    bsr _loaddisk
    bra.b   .out

.LOAD_SCORES
	move.l  a0,-(a7)    
    move.l  _resload(pc),a2
	LEA	SCORES_NAME(PC),A0
	jsr (resload_GetFileSize,a2)
    move.l  (a7)+,a1
    tst.l   d0
    beq.b   .out
	LEA	SCORES_NAME(PC),A0
	jsr (resload_LoadFile,a2)    
.out
	MOVEM.L	(A7)+,D0-A6
	RTS
	
MY_SAVE
	MOVEM.L	D0/D1/A0/A1,-(A7)
	move.l  trainer(pc),d0
    bne.b   .skip
    move.l  _resload(pc),a2
	MOVE.L	#SCORES_LEN,D0
	move.l  a0,A1
	LEA	SCORES_NAME(PC),A0
	jsr (resload_SaveFile,a2)
.skip	
	MOVEM.L	(A7)+,D0/D1/A0/A1
	RTS
    
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

test_quit
    AND.B #$bf,$00bfee01
	CMP.B	_keyexit(pc),D0
	beq.b   _quit
    rts
    
keyboard_jump_table = $DFB2

; replace joystick UP by 2nd button
; returns JOY1DAT in D0, modified by button 2 press
; (up cancelled if button 2 not pressed)
; < nothing (uses buttons_state 32bit var)
; > D0: modified JOY1DAT
read_joydat:
	move.l	d0,-(a7)
	move.l	joy1(pc),d0
	move.w	$DFF00C,D1
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
	move.l	(a7)+,d0
	RTS

TEST_BUTTON:MACRO
    clr.b   d0
    btst    #JPB_BTN_\1,d2
    beq.b   .nochange_\1
    move.b  #\2,d0
    btst    #JPB_BTN_\1,d0
    bne.b   .action_\1
    bset    #7,d0
.action_\1
    bsr keyboard_handling
.nochange_\1
    ENDM
    
vblank_hook:
    ; don't waste cycles reading input at 50Hz, game
    ; updates are 25Hz
    lea alternate_input_read(pc),a0
    move.b  (a0),d0
    bchg    #0,d0
    move.b  d0,(a0)
    bne   nochange

    lea prev_buttons_state(pc),a0
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_joystick
    move.l  joy1(pc),d0
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; xor to d2 to get what has changed quickly
    move.l  d0,d2
    eor.l   d1,d2
    beq   nochange   ; cheap-o test just in case no input has changed

    TEST_BUTTON GRN,$40 ; "space" activate little player
    TEST_BUTTON YEL,$17 ; "I" display collected objects
    TEST_BUTTON FORWARD,$37 ; "M" toggle music on/off
    TEST_BUTTON PLAY,$19    ; "P" pause
    btst    #JPB_BTN_REVERSE,d0
    beq.b   noesc
wtf    
    TEST_BUTTON GRN,$57 ; reverse+green: quit current game (F8) 
    TEST_BUTTON FORWARD,$45
    btst    #JPB_BTN_REVERSE,d0
    beq.b   noesc
    btst    #JPB_BTN_YEL,d0
    bne _quit
noesc    
nochange
    JMP	$1af26

    
keyboard_handling:
	LEA	keyboard_jump_table,A0
	MOVEQ	#0,D1			;0dd70: 7200
	MOVE.B	D0,D1			;0dd72: 1200
	LSL.W	#2,D1			;0dd74: e549
	MOVEA.L	0(A0,D1.L),A0		;0dd76: 20701800
	JMP	(A0)			;0dd7a: 4e90
    
prev_buttons_state
    dc.l    0
alternate_input_read
    dc.w    0
 
SCORES_NAME
	DC.B	"Apprentice.high"
	CNOP	0,2
	
    
patch_level:
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    sub.l   a1,a1
    MOVE.W #$00a0,$00dff108 ; original
    cmp.l   #$33ed0052,$0001F0CC
    bne.b   .nolevel_12
    lea pl_level_12(pc),a0
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
    rts
.nolevel_12
    ; actually never reached
    movem.l (a7)+,d0-d1/a0-a2
    rts
    
pl_title:
	PL_START
	PL_PSS  $00020040,test_quit,2
	PL_END

pl_game:
	PL_START
	PL_PSS  $0000DD58,test_quit,2
    PL_PSS  $E8FA,patch_level,2
    
    PL_IFC1X    0
    PL_NOP      $11c52,12
    PL_NOP      $12140,12
    PL_ENDIF
    
    PL_IFC2
    PL_PS   $000112BC,read_joydat
    PL_ENDIF
    PL_PS   $0f156,vblank_hook
    PL_PSS  $112F8,test_fire,2
	PL_END

    
pl_level_12:
	PL_START
    ; doesn't seem to be used
    ;PL_PSS  $1f0cc,write_dma,2
	PL_END

test_fire
    move.l  d0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts
    
write_dma
	MOVE.W	82(A5),$dff096
	move.w  d0,-(a7)
	move.w	#7,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
	rts 

_tag		dc.l	WHDLTAG_CUSTOM1_GET
trainer	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
start_level	dc.l	0
		dc.l	0

;--------------------------------

_resload	dc.l	0		;address of resident loader


;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_loaddisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

