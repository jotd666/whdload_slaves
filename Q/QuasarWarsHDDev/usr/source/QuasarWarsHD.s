;*---------------------------------------------------------------------------
;  :Program.	Liberation.asm
;  :Contents.	Slave for "Liberation"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: Liberation.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/intuition.i


;CHIPONLY

	IFD BARFLY
	OUTPUT	"QuasarWars.slave"

	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	ENDC

	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD	CHIPONLY
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0
HRTMON
	ELSE
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
INITAGA
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE
;;STACKSIZE=20000
IGNORE_JOY_DIRECTIONS

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'



;============================================================================

	INCLUDE	kick31.s
    include ReadJoyPad.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.1"
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
slv_name
		dc.b	"Quasar Wars"
	IFD	CHIPONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1996 Light Designs",0
slv_info		dc.b	"Install/fix by JOTD",10,10

			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
;        dc.b    "C1:B:Trainer Infinite Lives;"
        dc.b    "C2:B:secondary weapon only with second button;"
		dc.b	0

assign_d1
	dc.b	"Quasar_Data",0
assign_d2
	dc.b	"Quasar_Data2",0

DO_ASSIGN:MACRO
		lea	\1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
	ENDM

progname:
	dc.b	"quasarwars",0

_args		dc.b	10
_args_end
	dc.b	0
	EVEN

	;initialize kickstart and environment

_bootdos
	; configure the button emulation

    bsr _detect_controller_types
    
	move.l	_resload(pc),a2		;A2 = resload

    ; doing this in debug mode allows code to be located
    ; in exactly $x0000 !!
    ; look at $100 value. If higher than $x0000, alloc less
    ; else alloc more
    ;
    ; this is slightly more complex here because the program
    ; auto-unpacks
    IFD CHIPONLY
	move.l	(4),a6
    move.l  #MEMF_CHIP,D1
    move.l  #$C290-$28,d0
    jsr (_LVOAllocMem,a6)
    ENDC


	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		;bsr	_patch_cd32_libs

		DO_ASSIGN	assign_d1
		DO_ASSIGN	assign_d2

	;load program

		lea	progname(pc),A0

	;load exe
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

patch_exe:
	lea	pl_boot(pc),a0
	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
	rts

pl_boot
	PL_START
	PL_P    $170,after_unpack

	PL_END

after_unpack:
    move.l  60(a7),a1       ; return address
    lea basemem(pc),a0
    move.l  a1,(a0)
    IFD CHIPONLY
    move.l  a1,$100.W
    ENDC
	lea	pl_main(pc),a0

	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

    MOVEM.L (A7)+,D0-D7/A0-A6
    rts     ; jumps
    
pl_main
    PL_START
    PL_DATA    $48a2,2 ; add.l  D0,a0 => add.w D0,A0
    add.w   d0,a0
    PL_PSS      $4174,read_joypad,2
    PL_PSS      $4130,read_fire,2   ; seems not reached
    PL_PS      $3f50,end_pause
    PL_IFC2
    ; prevent secondary weapon to be fired
    ; by double tap of fire button
    PL_NOP      $4248,2
    PL_NOP      $41C6,4
    PL_ENDIF
	PL_END
 
;551E8.B: 0-9 secondary weapon
end_pause
	MOVEA.L	basemem(pc),a0
    add.l   #$78fc,A0		;53f50: 207c000578fc
    movem.l d0-d1,-(a7)
    bsr wait_vbl
    move.l  joy1_buttons(pc),d0
    bsr _read_joysticks_buttons
    btst    #JPB_BTN_PLAY,d0
    bne.b   .noplay
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_PLAY,d0
    beq.b   .noplay
    bset    #1,(3,a0)   ; P    
.noplay   
    
    movem.l (a7)+,d0-d1
    rts
    
wait_vbl:
    movem.l d0/a0,-(a7)
	; wait for VBL
	lea	$DFF000,a0
	move.w	#$7FFF,intreq(a0)
.wait
	move.w	intreqr(a0),d0
	btst	#5,d0
	beq.b	.wait
    movem.l (a7)+,d0/a0
	rts
    
read_joypad:
    movem.l d0-d1/A0,-(a7)
    move.l  joy1_buttons(pc),d1
    bsr _read_joysticks_buttons
    move.l  joy1_buttons(pc),d0
    move.l  basemem(pc),a0
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .nofwd
    btst    #JPB_BTN_FORWARD,d1
    bne.b   .nofwd  ; already pressed
    bset    #1,($7908,a0)   ; right shift
.nofwd    
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .norev
    btst    #JPB_BTN_REVERSE,d1
    bne.b   .norev  ; already pressed
    bsr     prev_secondary_weapon
.norev    
    btst    #JPB_BTN_PLAY,d0
    beq.b   .noplay
    btst    #JPB_BTN_PLAY,d1
    bne.b   .noplay  ; already pressed
    bset    #1,($78FF,a0)   ; P    
.noplay   
    btst    #JPB_BTN_YEL,d0
    beq.b   .noyel
    btst    #JPB_BTN_YEL,d1
    bne.b   .noyel  ; already pressed
    ; set flares, fire it
	move.l	d0,-(a7)		;542e8: 0c39000a000551e8
    move.b  #9,d0    ; flares
    jsr ($4252,a0)
	move.l	(a7)+,d0		;542e8: 0c39000a000551e8
    ;bset    #0,($7907,a0)   ; F9: flares
.noyel
    btst    #JPB_BTN_GRN,d0
    beq.b   .nogrn
    btst    #JPB_BTN_GRN,d1
    bne.b   .nogrn  ; already pressed
    ;bset    #1,($7907,a0)   ; F10: mega bomb
    ; set rear bomb, fire it
	move.l	d0,-(a7)		;542e8: 0c39000a000551e8
    move.b  #4,d0    ; rear bomb
    jsr ($4252,a0)
	move.l	(a7)+,d0		;542e8: 0c39000a000551e8
    
.nogrn
    btst    #JPB_BTN_BLU,d0
    beq.b   .noblu
    btst    #JPB_BTN_BLU,d1
    bne.b   .noblu  ; already pressed    
    jsr ($424C,a0)  ; fire secondary weapon (only uses D0 & D1)
.noblu
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0-d1/a0
    eor #4,ccr    ; flip Z
    rts

secondary_weapon_type = $51E8

prev_secondary_weapon:
	cmp.B	#$01,(secondary_weapon_type,a0)		;542e8: 0c39000a000551e8
	BGT.S	subsw		;542f0: 6f08
	MOVE.B	#$0A,(secondary_weapon_type,a0)		;542f2: 13fc0001000551e8
    bra.b   swout
subsw
	SUBQ.B	#1,(secondary_weapon_type,a0)		;542e2: 5239000551e8
swout:
    move.l  a0,-(a7)
    add.l   #$42FA,(a7)
    rts
    
read_fire:
    movem.l d0,-(a7)
    ;;bsr _read_joysticks_buttons
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    eor #4,ccr    ; flip Z
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
	movem.l	a3-a6/d7,-(a7)
    IFD CHIPONLY
    move.l  d7,d0
    add.l   d0,d0
    add.l   d0,d0
    addq.l  #4,d0
    move.l  D0,$100.W
    ENDC
	jsr	(a5)
	movem.l	(a7)+,a3-a6/d7
.skip
	;call
	add.l	d7,d7
	add.l	d7,d7
	move.l	d7,a1

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

basemem
    dc.l    0

;============================================================================
