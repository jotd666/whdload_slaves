;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;CHIP_ONLY

	IFD BARFLY
	OUTPUT	"Powder.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFND	CHIP_ONLY
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ELSE
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
HRTMON
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
BOOTDOS
CACHE
HDINIT
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
SEGTRACKER
;============================================================================


slv_Version	= 19
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick31.s
IGNORE_JOY_DIRECTIONS    
    INCLUDE ReadJoyPad.s
    
;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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

slv_name		dc.b	"Powder",0
slv_copy		dc.b	"1998 wtf",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
_args:
	dc.b	10
_args_end:
	dc.b	0
_program:
	dc.b	"POWDER",0
slv_config:
	dc.b    "C1:X:Trainer Infinite Lives:0;"
	dc.b	0

	EVEN

;============================================================================



	;initialize kickstart and environment


_bootdos	move.l	(_resload,pc),a2		;A2 = resload

    bsr get_version
	move.l	4,a6
	jsr		(_LVODisable,a6)
    bsr _detect_controller_types
	jsr		(_LVOEnable,a6)

    
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase


	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

	;patch
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
        addq.l  #4,a1
        
        bsr	_patchexe

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1

		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check

		movem.l	d0/d7/a2/a6,-(a7)

		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)
        bra.b _quit
.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
    
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
_quit
		pea	TDREASON_OK
        move.l  _resload(pc),a2
		jmp	(resload_Abort,a2)


get_version:
	movem.l	d1/a1,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#58920,D0       ; fr/kixx/us
	beq.b	.ok

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.ok
     lea    _progsize(pc),a0
     move.l d0,(a0)
	 movem.l	(a7)+,d1/a1
     rts
     
_patchexe
    ; install vbl hook which counts vblank
    ; and also reads controllers
;    lea old_level3_interrupt(pc),a0
;    move.l  $6C.W,(a0)
;    lea new_level3_interrupt(pc),a0
;    move.l  a0,$6C.W

	lea		pl_main(pc),a0
    jsr resload_Patch(a2)
    rts
    
pl_main:
    PL_START
	PL_P	$002ea,zero_vbr
    PL_END

zero_vbr:
	moveq	#0,d0
	rte
	
TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d1
    beq.b   .nochange_\1
    move.b  #\2,d3
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    bset    #7,d3   ; released
.pressed_\1

    not.b   d3
    rol.b   #1,d3
    move.b  d3,$bfec01 ; store keycode
.nochange_\1
    ENDM
   
    
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
; just keycode
new_level3_interrupt
    movem.l d0-d3/a0-a1,-(a7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    beq   .novbl
    bsr vblank
.novbl    
    movem.l (a7)+,d0-d3/a0-a1
    move.l  old_level3_interrupt(pc),-(a7)
    rts    
    
    
vblank
    movem.l a0-a1/d0-d1/d3,-(a7)
    ; vblank interrupt, read joystick/mouse
    lea counter(pc),a1
	ADDQ.b	#1,(A1)
    move.b  (a1),d0     ; read every 40ms
    btst    #0,d0
    beq   .nochange
    lea prev_buttons_state(pc),a0
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_read_joystick
    ; xor to d1 to get what has changed quickly
    eor.l   d0,d1
    beq.b   .nochange   ; cheap-o test just in case no input has changed
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; d1 bears changed bits (buttons pressed/released)
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d0
    bne _quit
.noquit    
    ;TEST_BUTTON REVERSE,$4A
    ;TEST_BUTTON FORWARD,$5E
    TEST_BUTTON BLU,$33     ; 'C'
    TEST_BUTTON GRN,$21     ; 'S' sound on/off
    TEST_BUTTON PLAY,$19     ; pause
.nochange
    movem.l (a7)+,a0-a1/d1-d0/d3
	RTS				;585c: 4e75

counter:
	dc.w	0
dma_delay
	move.w  d0,-(a7)
	move.w	#4,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
	rts 

 
_progsize
    dc.l    0
prev_buttons_state
        dc.l    0
old_level3_interrupt        
        dc.l    0
;============================================================================

	END

