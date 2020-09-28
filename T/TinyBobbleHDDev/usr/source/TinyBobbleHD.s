;*---------------------------------------------------------------------------
;  :Program.	BoppinHD.asm
;  :Contents.	Slave for "Boppin"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BoppinHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"TinyBobble.slave"
	IFND	CHIP_ONLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
;;BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	kick13.s
IGNORE_JOY_DIRECTIONS
    include     ReadJoyPad.s
    
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.0"
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



slv_name		dc.b	"Tiny Bobble"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"2020 Pink^abyss",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0


program:
	dc.b	"aYs_tinybobble",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	;dc.b    "C1:X:trainer start with 9.000.000$:0;"
    dc.b    "C2:B:blue/second button jumps;"
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN


_bootdos
		clr.l	$0.W

        bsr _detect_controller_types
        lea controller_joypad_0(pc),a0
        clr.b   (a0)        ; no need to read port 0 extra buttons...
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload
        lea	(tag,pc),a0
        jsr	(resload_Control,a2)

	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
        
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$48C0,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

    
	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)




patch_main
	lea	pl_unp(pc),a0
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)
	rts

; apply on SEGMENTS
pl_unp
    PL_START
    PL_P    $000bc,end_unpack
    PL_END
 
pl_main
    PL_START
    ; skip read at $F0FF60
    PL_S    $01800,$16
    PL_W    $01820,$588f
    PL_S    $01822,$16
    PL_R    $0253E
    PL_R    $0a380
    PL_S    $17f52,$68-$52
    PL_NOP  $19a04,6
    PL_S    $19a0e,$1A-$E
    ; remove vbr read & other MMU registers shit
    PL_B  $00374,$60
    ; vbl hook
    PL_PSS  $2602,vbl_hook,2
    ; keyboard hook
    PL_PS   $2448,keyboard
    ; joystick
    PL_PS   $ba3C,read_fire
    PL_PS   $ba92,read_fire
    ; 2nd button jumps
    PL_IFC2
    PL_PS   $B9FE,second_button
    PL_ENDIF
    
    ; pause
    PL_PS   $1F850,wait_pause_quit
    PL_PSS  $1f5c8,pause_test,2
    PL_PS   $1F7F0,read_joypad_pause
    PL_PS   $1F85C,exit_vpos_loop
    PL_PS   $1f870,exit_vpos_loop
    
    ; hiscore save & load
    PL_PS    $1803e,load_highs
    PL_PSS   $11736,save_highs,2
    PL_END

wait_tof
.w:
	MOVE.L	$dff004,D0		;3f856: 203900
	ANDI.L	#$0001ff00,D0		;3f85c: 02800001ff00
	CMPI.L	#$0,D0		;3f862: 0c8000013700
	BNE.S	.w		;3f868: 67ec
    rts
    
read_joypad_pause
; wait top of frame to read the buttons
    bsr wait_tof
    bsr _read_joysticks_buttons
    
    MOVE.W	A5,D6			;3f7f0: 3c0d
	BTST	#0,D7			;3f7f2: 08070000
    rts
    
load_highs
    movem.l d0-d1/a0-a3,-(a7)
    move.l  loaded_highscore(pc),d0
    tst.l   d0
    bne   .noload
    ; no highscore loaded: load it now
    move.l  _resload(pc),a3
    lea highname(pc),a0
    jsr (resload_GetFileSize,a3)
    tst.l   d0
    beq.b   .noload
    lea loaded_highscore(pc),a1
    lea highname(pc),a0
    jsr (resload_LoadFile,a3)
    ; store loaded hiscore in location
    move.l  loaded_highscore(pc),(6240+6,A2)
.noload        
    movem.l (a7)+,d0-d1/a0-a3
    MOVE.W	#$0003,(6440,A2)    ; original code
    RTS
    

    ; this is called quite a lot, so it's a save/load routine
save_highs
    movem.l d0-d1/a0-a3,-(a7)
         
.loaded
    lea highname(pc),a0
    lea	(6240,A2),a1
    move.l  (a1),d0
    ; don't save if same highscore as already loaded
    cmp.l   loaded_highscore(pc),d0
    beq.b   .nosave
    move.l  _resload(pc),a3
    moveq.l #4,d0
    jsr (resload_SaveFile,a3)
.nosave
    movem.l (a7)+,d0-d1/a0-a3
    ; original
	TST.B	(-8,A5)			;31736: 4a2dfff8
    bne.b   .out
	add.l   #$d24-$73c,(a7) ; emulate branch
.out
    rts
    
exit_vpos_loop
    ANDI.L	#$0001ff00,D0
    movem.l  d0,-(a7)
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_PLAY,d0
    movem.l  (a7)+,d0  
    bne.b   .exit
    rts
.exit
    move.l  #$13700,d0
    rts
    
pause_test
    cmp.b   #$CD,d0
    beq.b   .branch
    
    movem.l  d0,-(a7)
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d0
    bne     _quit
    
.noquit
    btst    #JPB_BTN_PLAY,d0
    movem.l  (a7)+,d0  
    bne.b   .wait_and_branch
    rts
.branch
    add.l   #$79e-$5ce,(a7)
    rts
.wait_and_branch
    bsr wait_play_released
    bra.b   .branch
    
wait_pause_quit
    cmp.b   #$CD,d0
    beq.b   .branch
    
    movem.l  d0,-(a7)
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_PLAY,d0
    movem.l  (a7)+,d0  
    bne.b   .wait_and_branch2
    rts
.branch
    add.l   #$88-$56,(a7)
    rts
    
.wait_and_branch
    bsr wait_play_released
    bra.b   .branch
        
.wait_and_branch2
    move.l  d0,-(a7)
.wait
    bsr wait_tof
    bsr _read_joysticks_buttons
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .wait
    move.l  (a7)+,d0
    bra.b   .branch
    
wait_play_released    
    move.l  d0,-(a7)
.wait
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .wait
    move.l  (a7)+,d0
    rts
    
; < A1: DFF00A or DFF00C
second_button:
    MOVE.W	(A1),D3

	; using 2nd button data, tamper with JOYxDAT value
	movem.l	d2/a0,-(a7)
	lea	joy0_buttons(pc),a0
    cmp.l   #$DFF00A,a1
    beq.b   .port0
    lea	joy1_buttons(pc),a0
.port0
	move.l	(a0),d2	; read buttons value
	
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d3
	btst	#9,d3
	beq.b	.noneed
	bset	#8,d3	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d2
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d3
	btst	#9,d3
	bne.b	.no_blue
	bset	#8,d3	; xor 8 and 9 yields 1 cos bit9=0
.no_blue:
	movem.l	(a7)+,d2/a0

	MOVE.W	D3,D2			;2ba00: 3403
	LSL.W	#1,D2			;2ba02: e34a

	RTS    
read_fire
    st   d0
    move.l d1,-(a7)
    move.l  joy1_buttons(pc),d1
    btst    #JPB_BTN_RED,d1
    beq.b   .nofire1
    bclr    #7,d0
.nofire1
    move.l  joy0_buttons(pc),d1
    btst    #JPB_BTN_RED,d1
    beq.b   .nofire0
    bclr    #6,d0
.nofire0
    move.l  (a7)+,d1
    rts
    
end_unpack
    lea (4,a3),a1
    move.l  _resload(pc),a2
    lea (4,a3),a1
    lea pl_main(pc),a0
    jsr (resload_Patch,a2)
    jmp (4,a3)
    
    ; not really super-helpful as game already has "ESC"
    ; as a quit key
keyboard:
	MOVE.B	$bfec01,D1		;22448: 123900
    movem.l d1,-(a7)
    ror.b   #1,d1
    not.b   d1
    cmp.b   _keyexit(pc),d1
    beq _quit
    movem.l (a7)+,d1
    RTS
    
vbl_hook
    bsr _read_joysticks_buttons
    ; cheap-o way to check if A0 is 0
    ; (can fail if you're not lucky)
	CMPA.W	#$0000,A0		;22602: b0fc0000
	BEQ.S	LAB_0115		;22606: 6702
	JSR	(A0)			;22608: 4e90
LAB_0115:
    rts
    
get_version:
	movem.l	d1/a0/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#$1BD0C,D0
	beq.b	.original
    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.original
	moveq	#1,d0
    bra.b   .out
    nop


.out
	movem.l	(a7)+,d1/a0/a1
	rts



; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
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
	movem.l	d2/d7/a4,-(a7)

	;get tags
    move.l  _resload(pc),a2
    lea (segments,pc),a0
    move.l  d7,(a0)
    lea	(tagseg,pc),a0
	jsr	(resload_Control,a2)


	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
orig_vbl
    dc.l    0
tag
		dc.l	WHDLTAG_CUSTOM5_GET
skip_intro_flag	dc.l	0
		dc.l	WHDLTAG_CUSTOM4_GET
start_division	dc.l	0
    dc.l    0
tagseg
        dc.l    WHDLTAG_DBGSEG_SET
segments:
		dc.l	0
		dc.l	0
prev_joy1   dc.l    0
loaded_highscore
    dc.l    0
highname
    dc.b    "highscore",0
    
;============================================================================

	END
