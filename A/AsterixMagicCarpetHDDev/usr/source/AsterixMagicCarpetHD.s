;*---------------------------------------------------------------------------
;  :Program.	AsterixGetAFixHD.asm
;  :Contents.	Slave for "AsterixGetAFix"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: AsterixGetAFixHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"AsterixMagicCarpet.slave"
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

    IFD CHIP_ONLY
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0000
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000    
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000


BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 8000
BOOTDOS

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	kick13.s
    
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
    
slv_config:		
		dc.b	0

slv_name		dc.b	"Asterix and the Magic Carpet"
    IFD CHIP_ONLY
    dc.b    " (DEBUG MODE)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1987 Cockel Vision",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION

		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
assign
	dc.b	"df0",0

_program:
	dc.b	"asterix",0
_program2:
	dc.b	"loader",0
_args		dc.b	10
_args_end
	dc.b	0
_setmap:
	dc.b	"setmap",0
_fargs		dc.b	"f",10
_fargs_end
	dc.b	0
_dargs		dc.b	"d",10
_dargs_end
	dc.b	0
_iargs		dc.b	"i",10
_iargs_end
	dc.b	0
_french_keymap
    dc.b    "devs/keymaps/f",0
_german_keymap
    dc.b    "devs/keymaps/d",0
_italian_keymap
    dc.b    "devs/keymaps/i",0
    
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	
	EVEN
    
PATCH_XXXLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
    ENDM
    
_bootdos
	clr.l	$0.W

    ;;bsr _detect_controller_types
    
	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

       IFD CHIP_ONLY
        movem.l a6,-(a7)
        move.l	$4.w,a6			;Open dos library
        move.l  #$48A8,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
       ENDC
        
    ; install vbl hook which counts vblank
    ; and also reads controllers
        lea old_level3_interrupt(pc),a0
        move.l  $6C.W,(a0)
        lea new_level3_interrupt(pc),a0
        move.l  a0,$6C.W
        
        move.l  _speed_fix_controls(pc),d0
        btst    #0,d0
        bne   skip_gfx_fix
	;open doslib
		lea	(_gfxname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = gfxbase
        

        PATCH_XXXLIB_OFFSET RectFill
        PATCH_XXXLIB_OFFSET BltBitMap
skip_gfx_fix
        
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
	;assigns
		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

        lea _french_keymap(pc),a0
        jsr (resload_GetFileSize,a2)
        tst.l   D0
        beq.b   .nofr
		lea	_fargs(pc),a1
		moveq	#_fargs_end-_fargs,d0
        bra.b   .setmap
.nofr
        lea _german_keymap(pc),a0
        jsr (resload_GetFileSize,a2)
        tst.l   D0
        beq.b   .node
		lea	_dargs(pc),a1
		moveq	#_dargs_end-_dargs,d0
        bra.b   .setmap
.node
        lea _italian_keymap(pc),a0
        jsr (resload_GetFileSize,a2)
        tst.l   D0
        beq.b   .noit
		lea	_iargs(pc),a1
		moveq	#_iargs_end-_iargs,d0
        bra.b   .setmap
.noit
        bra .main
.setmap
        lea _setmap(pc),a0
        sub.l   a5,a5
		;;bsr	_load_exe        
.main
	;load exe
	lea	_program2(pc),A0
	jsr	resload_GetFileSize(a2)
    tst.l   d0
    
    beq.b   .noalt
	lea	_program2(pc),A0
    bra.b   .load
.noalt
		lea	_program(pc),a0
.load
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; call graphics.library function then wait
DECL_GFX_WITH_WAIT:MACRO
new_\1
    pea .next(pc)
	move.l	old_\1(pc),-(a7)
	rts
.next:
    bra wait_blit
    ENDM
    
    
    ; the calls where a wait is useful
    DECL_GFX_WITH_WAIT  BltBitMap
    DECL_GFX_WITH_WAIT  RectFill
   

VERSION_PL:MACRO
.\1
	lea	pl_\1(pc),a0
	bra.b	.out
	ENDM
    
; < d7: seglist (APTR)

patch_main
	move.l	d7,a1
	add.l	#4,a1	; first segment
    IFD CHIP_ONLY
    move.l  a1,$100.W
    ENDC
    
    lea game_address(pc),a0
    lea $5a46+$6(a1),a2
    move.l  a2,(a0)
    
    ;;movem.l d0/a2,-(a7)
    move.l  _resload(pc),a2
    move.l  #5,d0
    jsr (resload_Delay,a2)
    ;;movem.l (a7)+,d0/a2

    bsr get_version
    jsr (resload_Patch,a2)
    rts
    
get_version:
	movem.l	d0-d1/a1,-(a7)
	lea	_program(pc),A0
	jsr	resload_GetFileSize(a2)

	cmp.l	#49884,D0
	beq.b	.french_german
	lea	_program2(pc),A0
	jsr	resload_GetFileSize(a2)

	cmp.l	#49884,D0
	beq.b	.french_german

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	VERSION_PL	french_german

    nop

.out
	movem.l	(a7)+,d0-d1/a1
	rts


pl_french_german
    PL_START
    PL_P  $06d8,dmawait_loop
    PL_PSS $5a46,speed_regulation,4
;    cancelling intuition closewindow allows to avoid the crash
;    at startup. Waiting a little while does the same too. Why???
;    PL_R    $9b54,close_window
;    PL_R    $9b5e   ; no CloseWorkbench
    PL_END

speed_regulation
    movem.l d1/a0,-(a7)    
    moveq.l #1,d1
    bsr vbl_reg
    
    ; original game code
    move.l  game_address(pc),a0
    CMPI.L	#$000000ff,(a0)    
    movem.l (a7)+,d1/a0
    rts
    
dmawait_loop    
    movem.w D0,-(a7)
    move.w  #4,d0
    bsr beamdelay
    movem.w (a7)+,d0
    MOVE.W	#$0001,$dff096
    movem.w D0,-(a7)
    move.w  #4,d0
    bsr beamdelay
    movem.w (a7)+,d0
	MOVE.L	(A7)+,D0		;06e8: 201f
	RTS				;06ea: 4e75
    
; < D1: number of ticks
vbl_reg:    
    movem.l d0/a0-a1,-(a7)
    lea vbl_counter(pc),a0
    move.w  (a0),d0
    cmp.w   #10,d0
    bcc.b   .nowait     ; first time called/lost sync/pause/whatever
    ; wait till at least x vblanks passed after last zeroing
.wait
    cmp.w   (a0),d1
    bcc.b   .wait
.nowait
    clr.w   (a0)
    movem.l (a7)+,d0/a0-a1
    rts
    
    
new_level3_interrupt
    movem.l d0/a0,-(a7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    beq.b   .novbl
    ; vblank interrupt, read joystick/mouse
    ;;bsr _joystick
    ; add to counter
    lea vbl_counter(pc),a0
    addq.w  #1,(a0)
.novbl
    movem.l (a7)+,d0/a0
    move.l  old_level3_interrupt(pc),-(a7)
    rts
    
old_level3_interrupt
    dc.l    0

vbl_counter
    dc.w    0
    
 

 
    
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
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
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
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

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

_tag		dc.l	WHDLTAG_CUSTOM3_GET
_speed_fix_controls	dc.l	0
		dc.l	0
game_address
		dc.l	0

_gfxname
    dc.b    "graphics.library",0
    
;============================================================================

	END
