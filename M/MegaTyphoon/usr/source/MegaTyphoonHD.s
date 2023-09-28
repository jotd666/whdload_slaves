;*---------------------------------------------------------------------------
;  :Program.	MegaTyphoonHD.asm
;  :Contents.	Slave for "MegaTyphoon"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: MegaTyphoonHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"MegaTyphoon.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;CHIP_ONLY

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $130000
FASTMEMSIZE	= $0000	
	ELSE
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $30000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s
IGNORE_JOY_DIRECTIONS
        include     ReadJoyPad.s
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

slv_config:
	dc.b    "C1:X:Trainer infinite lives:0;"
	dc.b    "C1:X:Trainer infinite smart bombs:1;"
	dc.b	0

slv_name		dc.b	"Mega-Typhoon"
    IFD CHIP_ONLY
    dc.b    " (debug/chip mode)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1996 Bernhard Braun / Nordlicht Edv",0
slv_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Mega-Typhoon",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

		;lea	(_tag,pc),a0
		;jsr	(resload_Control,a2)
        bsr _detect_controller_types
        
        ; install our handler for the menu
        lea system_vbl(pc),a0
        move.l  $6C.W,(a0)
        lea vbl_hook_sys(pc),a0
        move.l  a0,$6C.W
        
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

        IFD CHIP_ONLY
        move.l  a6,-(A7)
        move.l  4,A6
        move.l  #$48B0,d0
        move.l  #MEMF_CHIP,d1
        jsr (_LVOAllocMem,a6)
        move.l  (a7)+,a6
        ENDC
    
	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		add.l	#4,a1

    ; copy current key address from the code
        move.l  ($00674,a1),d0
        lea rawkey_address(pc),a0
        move.l  d0,(a0)
        
		lea	pl_main(pc),a0
		jsr	resload_Patch(a2)
	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_end
		pea	_program(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts


pl_main
	PL_START
    PL_IFC1X    0
  	PL_NOP	$5D1A,2	; infinite lives	
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $07278,6    ; infinite bombs
    PL_ENDIF
    
	; access fault at the final level 1 monster

	PL_PS	$65D6,fix_af_1
	PL_PS	$6678,fix_af_1
	PL_PS	$671A,fix_af_1
	PL_PS	$67BC,fix_af_1
	PL_PS	$685E,fix_af_1

	; empty DBF loop

	PL_P	$8F1A,emulate_dbf

    ; vbl hook to read joypad
    PL_PS   $045a6,vbl_hook
    PL_PS   $04878,vbl_hook
    ; button 2
    PL_PS   $0454a,read_buttons
    PL_S    $04550,$14
    ;;PL_PSS    $04580,read_fire,$10,4
	PL_END

read_buttons
    move.l  joy1_buttons(pc),d1
    btst    #JPB_BTN_RED,d1
    bne.b   .red
    bset    #7,d0   ; original
.red
    not.l   d1
    btst    #JPB_BTN_BLU,d1  
    rts

vbl_hook_sys:
    move.l  system_vbl(pc),-(a7)
    bra.b   vbl_hook_2
vbl_hook    
    LEA	_custom,A5
vbl_hook_2
    movem.l d0/d1/a0,-(a7)
    lea previous_buttons(pc),a0
    move.l  (a0),d1
    move.l  joy1_buttons(pc),(a0)
    bsr _read_joysticks_buttons
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noesc
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noesc
    btst    #JPB_BTN_YEL,d0
    bne   _quit
    ; quit current game
    move.l  rawkey_address(pc),a0
    move.b  #$75,(a0) 
.noesc
    btst    #JPB_BTN_PLAY,d0
    beq.b   .nopause
    move.l  rawkey_address(pc),a0
    move.b  #$cd,(a0)
    bra.b   .out
.nopause
    btst    #JPB_BTN_PLAY,d1
    beq.b   .out
    ; just released
    move.l  rawkey_address(pc),a0
    move.b  #$0,(a0)
    
.out
    movem.l (a7)+,d0/d1/a0    
    rts
 
system_vbl
    dc.l    0
rawkey_address
    dc.l    0
previous_buttons
    dc.l    0
    
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

    
fix_af_1
	move.l	a4,d5
	bmi.b	.avoid

	MOVE.L	546(A4),D5
	OR.L	588(A4),D5
.ret	
	addq.l	#2,(a7)
	RTS
.avoid
	moveq	#0,d5
	bra.b	.ret

emulate_dbf
	move.l	d0,-(a7)
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.l	(a7)+,d0
	move.w	(a7)+,d0	; orig
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



;============================================================================

	END
