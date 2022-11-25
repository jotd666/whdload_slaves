;*---------------------------------------------------------------------------
;  :Program.	PuggsyHD.asm
;  :Contents.	Slave for "Puggsy" from Psygnosis
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
	OUTPUT	Puggsy.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;CHIP_ONLY

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
        IFD CHIP_ONLY
		dc.l	$100000		;ws_BaseMemSize
        ELSE
		dc.l	$80000		;ws_BaseMemSize
        ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	_start-_base	;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$58		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem		
    IFD CHIP_ONLY
    dc.l    0
    ELSE
	dc.l	$80000			;ws_ExpMem
    ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

	IFD BARFLY
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
	dc.b	'$VER: slave '
	DECL_VERSION
	dc.b	0
		
_data   dc.b    "data",0
_name	dc.b	'Puggsy'
    IFD CHIP_ONLY
    dc.b    " (CHIP/DEBUG mode)"
    ENDC
    dc.b    0
_copy	dc.b	'1993 Psygnosis',0
_info
    dc.b   'adapted by JOTD',10,10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	
_config
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C2:B:blue/second button jumps;"
        dc.b    "C5:B:skip introduction;"
		dc.b	0

	CNOP 0,2
IGNORE_JOY_DIRECTIONS
    include ReadJoyPad.s

_start
    lea	_resload(pc),a1
    move.l	a0,(a1)			;save for later use

    IFD CHIP_ONLY
    lea _expmem(pc),a0
    move.l  #$80000,(a0)
    ENDC
	lea	introname(pc),A0
	lea	$800.W,A1
    move.l  _resload(pc),a2
    ; load+RNC unpack
    jsr     (resload_LoadFileDecrunch,a2)

	; **** boot stuff and patch
    movem.l a0-a2/d0-d1,-(a7)
    lea pl_boot(pc),a0
    sub.l   a1,a1
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,a0-a2/d0-d1

	move.w	#$7FFF,_custom+dmacon
	JMP	$918.W

pl_boot
    PL_START
    PL_IFC5
    PL_L    $918,$4EF82024
    PL_ENDIF
	PL_P	$1248,RNCDecrunch
	PL_P	$2502,LoadFile
	PL_PS	$1074,KbInt
	PL_P	$148C,GetExtMem_1
	PL_P	$02088,PatchMain
	PL_P	$20FE,PatchIntro2
	PL_R	$21C4
    
    PL_P    $3be0,RNCDecrunch
    
;	PL_R	$22CE
;	PL_R	$23B0

	PL_END


pl_intro:
    PL_START
	PL_P	$D40C,LoadFile
	PL_P	$DF0A,RNCDecrunch
	PL_P	$D022,PatchMain
	PL_R	$D0E2
	PL_P	$1CE9A,GetExtMem_3
	PL_END
    
PatchIntro2
    movem.l a0-a2/d0-d1,-(a7)
    lea pl_intro(pc),a0
    sub.l   a1,a1
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,a0-a2/d0-d1

	jmp	$CC26

GetExtMem_1:
	move.l	_expmem(pc),$8F4.W
	RTS

GetExtMem_2:
	move.l	_expmem(pc),$2FB74
	RTS

GetExtMem_3:
	move.l	_expmem(pc),$7F2E4
	RTS

RNCDecrunch:
    movem.l a2/d1,-(a7)
    move.l  _resload(pc),a2
    jsr (resload_Decrunch,a2)
    movem.l (a7)+,a2/d1
	
	rts

KbInt:
	move.b	D0,$808.W
	cmp.b	_keyexit(pc),D0
	beq     _quit
.noquit
	RTS

control_method = $1AC3C
current_keycode = $20058

KbInt_2:
	move.b	D0,current_keycode
	cmp.b	_keyexit(pc),D0
	beq     _quit
.noquit
	RTS

_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


set_alt_controls
    CLR.B	current_keycode		; original
    move.w  #1,control_method
    rts
    
start_address = $1B2C0

PatchMain:
    ; game unpacks some data in chipmem, but goes over the $80000
    ; boundary in the process. The idea is to decrunch it in-place
    ; then copy it partially
    ; 
    ; strange as the previous version of the slave didn't go over
    ; the boundary...
    movem.l a0-a2/d0-d1,-(a7)
    move.l  a0,a1
    move.l  _resload(pc),a2
    jsr (resload_Decrunch,a2)
    movem.l (a7),a0-a2/d0-d1
    
    ; copy truncate to $80000
.copy:
    move.l  (a0)+,(a1)+
    cmp.l   #$80000,a1
    bcs.b   .copy

    bsr  _detect_controller_types

    movem.l (a7),a0-a2/d0-d1
    lea pl_main(pc),a0
    sub.l   a1,a1
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,a0-a2/d0-d1
	JMP	start_address

pl_main
    PL_START
	PL_P	$2FB2A,GetExtMem_2
	PL_P	$1EADC,LoadFile
	PL_PS	$23F3A,Patch2ndButton
	PL_PS	$1FFDC,KbInt_2
	PL_P	$28B1E,RNCDecrunch
	PL_NOP	$23F40,2

	PL_R	$1E792		; goto root block
    
    PL_ORW  $1c80c+2,$20    ; enable vblank
    PL_PS   $1FB90,vblank_hook
    PL_W    $1FB9E+2,$50    ; ack copper & blitter only
    PL_PS   $3c9f4,install_menu_copperlist  ; game map
    PL_PS   $4041E,install_menu_copperlist  ; game menu
    
    PL_IFC1
    PL_NOP  $1f60c,6
    PL_ENDIF
    PL_IFC2
    PL_PS   $1b310,set_alt_controls
    PL_ENDIF
    
    PL_END
    
TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d2
    beq.b   .nochange_\1
    move.b  #\2,d3
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    clr.b   d3   ; released: zero in that game
.pressed_\1
    move.b  d3,(a1) ; store keycode
.nochange_\1
    ENDM  


install_menu_copperlist
    cmp.w   #$9C,($500,a0)
    bne.b   .nopatch
    ; also write vblank to intreq else vbl interrupt
    ; is not active in menu
    move.w   #$8030,($502,a0)
.nopatch
	MOVE.L	A0,$dff080
    
    rts
    
vblank_hook
    btst    #5,_custom+intreqr+1
    bne.b   .vbl
	ADDQ.L	#1,$1c02a
    rts
.vbl
    addq.l  #4,A7
    
    ; vblank hook
    movem.l d0-d3/a0-a1,-(a7)
    lea .toggle(pc),a0
    eor.b   #1,(a0) ; read every 2 vblank, will be enough
    tst.b   (a0)
    beq   .skip_joy
    ; vblank interrupt, read joystick/mouse
    lea buttons_state(pc),a0
    lea $20058,a1
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_read_joystick
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; xor to d2 to get what has changed quickly
    move.l  d0,d2
    eor.l   d1,d2
    beq   .skip_joy
    ; d2 bears changed bits (buttons pressed/released)
    TEST_BUTTON REVERSE,$35 :; B show passwords
    
    ; quit and esc
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .nofwd
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .nofwd
    btst    #JPB_BTN_YEL,d0
    bne _quit
    
    TEST_BUTTON FORWARD,$45
.nofwd
    TEST_BUTTON YEL,$44     ; return
    tst.b   control_method+1
    bne.b   .green
    TEST_BUTTON BLU,$40     ; use object
    bra.b   .pausetest
.green:
    TEST_BUTTON GRN,$40     ; use object
.pausetest    
    TEST_BUTTON PLAY,$19     ; pause
.skip_joy
    movem.l (a7)+,d0-d3/a0-a1
    move.w  #$0020,_custom+intreq
    rte
.toggle
    dc.l    0
    
Patch2ndButton:
	movem.l	D0,-(sp)
	move.l  buttons_state(pc),d0
    not.l   d0
    btst    #JPB_BTN_BLU,d0
	movem.l	(sp)+,D0
	rts

LoadFile:
	movem.l	D1/A0-A2,-(a7)
    move.l  _resload(pc),a2
    jsr     (resload_LoadFile,a2)
	movem.l	(a7)+,D1/A0-A2
	moveq	#0,D0
	RTS

_resload
    dc.l    0
buttons_state
    dc.l    0
introname:
	dc.b	"INTRO.BIN",0
	even
