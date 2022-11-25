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
	OUTPUT	"Raffles.slave"
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

BLACKSCREEN
	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
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
CACHECHIPDATA

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s
IGNORE_JOY_DIRECTIONS
    include     ReadJoyPad.s

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

assign1
	dc.b	"cd0",0
assign2
	dc.b	"df0",0

slv_name		dc.b	"Raffles"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1989 The Edge",0
slv_info		dc.b	"adapted by Bored Seal & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"Raffles",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	dc.b    "C1:X:Trainer Infinite lives:0;"
	dc.b    "C1:X:Trainer Infinite energy:1;"
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN
    
_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

        bsr _detect_controller_types
        
        lea old_vbl(pc),a0
        move.l  $6C,(a0)
        pea vbl_hook(pc)
        move.l  (a7)+,$6C
    
		move.l	_resload(pc),a2		;A2 = resload

	
	;open doslib
		lea	(_gfxname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
        sub.l   a1,a1
        jsr (_LVOLoadView,a6)
        jsr (_LVOWaitTOF,a6)
        jsr (_LVOWaitTOF,a6)
        move.w  #$20,$DFF096    ; turn off sprite dma
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

    IFD CHIP_ONLY
    move.l  a6,-(a7)
    move.l  4,a6
    move.l  #$48A0,d0       ; mem align
    move.l  #MEMF_CHIP,d1
    jsr (_LVOAllocMem,a6)
    move.l  (a7)+,a6
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

; < d7: seglist (APTR)




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
    lea	(tag,pc),a0
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
    
patch_main
    move.l  _resload(pc),a2
    move.l  d7,a1
    add.l   a1,a1
    add.l   a1,a1
    addq.l  #4,a1

	lea	pl_cdtv(pc),a0
    cmp.l	#'CD0:',($3086,a1)	;'cd0:' string?
    beq   .patch		;CDTV Carlo Pirri version

    move.l	a1,a6
    add.l	#$ad78,a6	;Mark Knibbs version
    cmp.l	#$00104afc,(a6)	;disk release
    bne	Unsupported		

    lea	_adr(pc),a6			;count absolute adress
    move.l	a1,a0
    add.l	#$14e8a-$d948,a0
    move.l	a0,(a6)
    
	lea	pl_floppy(pc),a0
.patch
	jsr	resload_Patch(a2)

	rts

pl_floppy
	PL_START
    PL_IFC1X    0
	PL_W    $3454,$6004
    PL_ENDIF
    PL_IFC1X    1
    PL_R    $9140
    PL_ENDIF
    PL_P    $ad58,Copylock
    PL_PS   $14e74-$d948,Fix
    
    ; joypad controls
    PL_P    $43C4,test_key_pressed_floppy
    ; joyfire
    PL_PSS  $2ac4,fire_test,2
    
;save patch
    PL_W    $a590-$6568,$6002	;skip DoIO
    PL_W    $a5ae-$6568,$6002	;skip DoIO
    PL_W    $a5be-$6568,$6002	;skip Delete
    PL_W    $a5e0-$6568,$6006	;skip Lock/Examine (still useful?)

;load patch
	PL_W    $a6f6-$6568,$6002		;skip DoIO
	PL_W    $a710-$6568,$e940+$66	;skip Lock/Examine

	PL_END
    
pl_cdtv
	PL_START
    ; joypad controls
    PL_P    $3f20,test_key_pressed_cdtv
    ; joyfire
    PL_PSS  $2b96,fire_test,2

    PL_IFC1X    0
	PL_W    $34be,$6004
    PL_ENDIF
    
    PL_IFC1X    1
    PL_R    $8cfa
    PL_ENDIF
    
	PL_END

vbl_hook
    btst    #5,_custom+intreqr+1
    beq.b   .novbl
    bsr _read_joysticks_buttons
.novbl
    move.l  old_vbl(pc),-(a7)
    rts

fire_test
    movem.l d0,-(a7)
    move.l  joy1_buttons(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts

OFF_QUIT = 0
OFF_PAUSE = 1
OFF_PICK = 2
OFF_DROP = 3
OFF_BACK = 4

test_key_pressed_floppy
    movem.l a2,-(a7)
    lea floppy_key_table(pc),a2
    bsr test_key_pressed
    movem.l (a7)+,a2
	MOVEM.L	(A7)+,D0/A0		;43d2: 4cdf0101
	RTS				;43d6: 4e75
    
test_key_pressed_cdtv
    movem.l a2,-(a7)
    lea cdtv_key_table(pc),a2
    bsr test_key_pressed
    movem.l (a7)+,a2
	MOVEM.L	(A7)+,D0/A0		;43d2: 4cdf0101
	RTS				;43d6: 4e75
    
    
test_key_pressed
    movem.l d1-d2/a1,-(a7)
    move.l  joy1_buttons(pc),d1
    lea prev_joy1_buttons(pc),a1
    move.l  (a1),d2
    move.l  d1,(a1)     ; store previous value
    btst    #JPB_BTN_FORWARD,d1
    beq.b   .nofwdbwd
    btst    #JPB_BTN_REVERSE,d1
    beq.b   .nofwdbwd
    btst    #JPB_BTN_YEL,d1
    beq.b   .quitgame
    bra _quit
.quitgame
    move.b  (OFF_QUIT,a2),(a0)       ; no quit in CDTV???
    bra.b   .out
.nofwdbwd

    btst    #JPB_BTN_PLAY,d1
    beq.b   .noplay
    move.b  (OFF_PAUSE,a2),(a0)       ; 78
    bra.b   .out
.noplay
    btst    #JPB_BTN_PLAY,d2
    beq.b   .noprevplay
    clr.b   (a0)        ; P was just released
.noprevplay
    btst    #JPB_BTN_YEL,d1
    beq.b   .nopick
    move.b  (OFF_PICK,a2),(a0)       ; 73
    bra.b   .out
.nopick
    btst    #JPB_BTN_GRN,d1
    beq.b   .nodrop
    move.b  (OFF_DROP,a2),(a0)       ; 72
    bra.b   .out
.nodrop
    btst    #JPB_BTN_BLU,d1
    beq.b   .noback
    move.b  (OFF_BACK,a2),(a0)   ; 71
    ;bra.b   .out
.noback
    ;nop
.out
    movem.l (a7)+,d1-d2/a1
    
    ; original code
	CMP.B	(A0),D0			;43c4: b010
	BNE.S	LAB_0233		;43c6: 6606
	MOVE.B	#$01,D0			;43c8: 103c0001
	BRA.S	LAB_0234		;43cc: 6004
LAB_0233:
	MOVE.B	#$00,D0			;43ce: 103c0000
LAB_0234:
    rts
    
Fix		cmp.l	#0,a2			;check if adress is not wrong
		beq	TableEnd
		move.b	(a2)+,(a0)+
		move.b	(a2)+,(a0)+
		move.b	(a2)+,(a0)+
		rts

TableEnd
        lea	4(sp),sp
		move.l	_adr(pc),sp
		rts

Copylock	move.l	#$c105ffc7,d0
		rts

_adr		dc.l	0


Unsupported	
        pea	TDREASON_WRONGVER
_end	move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
        
_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
        dc.l    WHDLTAG_DBGSEG_SET
segments:
		dc.l	0
		dc.l	0
prev_joy1_buttons
		dc.l	0
old_vbl
    dc.l    0
_gfxname:
    dc.b    "graphics.library",0
floppy_key_table    
    dc.b    'Q','P',$85,$91,$83
cdtv_key_table    
    dc.b    'Q',$78,$73,$72,$71
    
;============================================================================

	END
