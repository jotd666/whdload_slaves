;*---------------------------------------------------------------------------
;  :Program.	TFXHD.asm
;  :Contents.	Slave for "TFX"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: TFXHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"TFX.slave"
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
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $600000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $600000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 20000
BOOTDOS
CACHE
SEGTRACKER

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_Req68020|WHDLF_ReqAGA
slv_keyexit	= $27	; 'K' (as num pad is used)

	include	kick31.s
IGNORE_JOY_DIRECTIONS    
    include ReadJoyPad.s
    
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

assign
	dc.b	"did",0
slv_config
	dc.b	"C4:L:executable:auto,TFX (68020),TFX_FPU (68020+FPU),TFX_040 (68040);"
	dc.b	"C5:B:skip intro;"
	dc.b	0	
	EVEN
slv_name		dc.b	"TFX"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1995 Digital Image Design",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

    even
program_table:
    dc.w    program-program_table
    dc.w    program_fpu-program_table
    dc.w    program_040-program_table
    
offset_table:
    dc.w    12958    
    dc.w    12838
    dc.w    13574
keycode_table:
    dc.l    $411c6,$397a6,$3F7DE
int2_hook_table:
    dc.l    $410f0,$396d4,$3f70c
    
; 68020, no fpu
program:
    dc.b    "TFX",0
; 68040 or higher
program_040:
	dc.b	"TFX.040",0
; 68020 with FPU
program_fpu:
	dc.b	"TFX.FPU",0

args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
		clr.l	$0.W

        bsr _detect_controller_types
    ; install vbl hook which counts vblank
    ; and also reads controllers
        lea old_level3_interrupt(pc),a0
        move.l  $6C.W,(a0)
        lea new_level3_interrupt(pc),a0
        move.l  a0,$6C.W
        
        IFD CHIP_ONLY

        move.l  4,a6
        move.l  #$EB38,d0
        move.l  #MEMF_CHIP,D1
        jsr (_LVOAllocMem,a6)
        ENDC
        
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

        move.l  executable(pc),d1
        bne.b   .noauto
    ;load exe
        move.l  attnflags(pc),d0
        btst    #AFB_68040,d0
        beq.b   .030
        btst    #AFB_FPU40,d0
        beq.b   .030
        move.l  #3,d1   ; set 68040 executable
        bra.b   .noauto
.030
    ; not 040 or no 040 fpu
        btst    #AFB_68881,d0
        beq.b   .nofpu
        move.l  #2,d1   ; set 68020+FPU executable

.nofpu
        moveq.l #1,d1   ; simple 68020
.noauto
        subq.l  #1,d1
        cmp.l   #3,d1
        bcs.b   .inrange

; checksum doesn't match, file corrupt
        pea	wrongcustom(pc)
        pea	(TDREASON_FAILMSG).w
        move.l	_resload(pc),a0
        jmp	resload_Abort(a0)
.inrange
        add.w   d1,d1
        lea program_table(pc),a0
        move.w  (a0,d1.w),a1
        add.l   a1,a0       ; program name
        lea program_to_run(pc),a1
        move.l  a0,(a1)
        ; proper offset to be able to reuse the same patch
        ; code for text/image skip
        lea offset_table(pc),a1
        lea offset(pc),a0        
        move.w  (a1,d1.w),d0
        beq.b   .skip1
        move.w  d0,(a0)
.skip1
        ; offset of jump to set keycode
        lea int2_hook_table(pc),a1        
        lea int2_hook_offset(pc),a0        
        move.l  (a1,d1.w*2),d0
        beq.b   .skip2
        move.l  d0,(a0)
.skip2
        
        movem.l a6,-(a7)
		move.l	$4.w,a6

        move.l  #MEMF_PUBLIC,d1
        move.l  #$11C80,d0
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6

        ; disable mouse
        ; at the same time enable bitplane DMA
        ; this isn't done on 040 version for some reason
        ; which explains black screen at start
        ;
        ; code copied from a non 040 version
        MOVE.W	#$83c0,$dff096
        CLR.W	$dff140
        MOVE.W	#$0020,$dff096


        move.l program_to_run(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

get_version
        move.l  program_to_run(pc),a0
        jsr (resload_GetFileSize,a2)
        cmp.l   #554340,d0
        beq.b   .v020
        
        cmp.l   #599152,d0
        beq.b   .v040
        cmp.l   #503340,d0
        beq.b   .vfpu
        
        pea	TDREASON_WRONGVER
        move.l	_resload(pc),-(a7)
        addq.l	#resload_Abort,(a7)
        rts    
.v020
        lea pl_020(pc),a0
        rts
.v040
        lea pl_040(pc),a0
        rts
.vfpu
        lea pl_fpu(pc),a0
        rts
    
; < d7: seglist (APTR)


patch_main
        bsr get_version
        move.l  d7,a1
        move.l  _resload(pc),a2
        jsr	resload_PatchSeg(a2)
        
        add.l   d7,d7
        add.l   d7,d7
        addq.l  #4,d7
        move.l  d7,a1
        add.l   int2_hook_offset(pc),a1
        lea int2_hook_address(pc),a0
        move.l  a1,(a0)
        rts

pl_020
        PL_START
        ; skip images/text from intro
        PL_IFC5
        ; we have to skip images/text until we reach 16 displays (amounts
        ; to the number of text/images screen shown during the intro
        ; because this routine is also used to display images in menu
        PL_PSS  $44510,pre_display_text_or_image,2
        PL_PSS  $44520,pre_display_text_or_image,2
        ;PL_NOP  $44518,4   ; this works but skips also stuff from main menu!
        ;PL_NOP  $44528,4
        PL_ENDIF
        
        PL_PS   $4CC02,fix_smc
        ;PL_P    $4111c,end_level2_int
        
        ; read joy1
        PL_PSS  $41504,test_fire,2

        PL_END
    
pl_040
        PL_START
        ; force FPU as we already checked that with whdload
        ; and kickstart isn't configured properly for that
        PL_B    $4ea14,$60

        ; skip images & text from intro
        PL_IFC5
        PL_PSS  $43a58,pre_display_text_or_image,2
        PL_PSS  $43a68,pre_display_text_or_image,2
        PL_ENDIF
        
        PL_PS   $4c38a,fix_smc
        
        ; faster blitwait
        PL_PS   $4ba4c,wait_blit
        PL_S    $4ba52,$4ba68-$4ba52
        PL_PS   $4bb08,wait_blit
        PL_S    $4bb0E,$4bb24-$4bb0E
        
        ; read joy1
        PL_PSS  $3fb1c,test_fire,2
        PL_END
    
pl_fpu
        PL_START
        ; force FPU
        PL_B    $48f1c,$60
        ; skip images from intro
        PL_IFC5
        PL_PSS  $3d8d8,pre_display_text_or_image,2
        PL_PSS  $3d8e8,pre_display_text_or_image,2
        PL_ENDIF
        
        PL_PS   $46272,fix_smc

        ; read joy1
        PL_PSS  $39ae4,test_fire,2

        PL_END

test_fire:
     movem.l    d0,-(a7)
     move.l buttons_state(pc),d0
     not.l  d0
     btst   #JPB_BTN_RED,d0
     movem.l    (a7)+,d0
     rts
wait_blit
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
    
pre_display_text_or_image
    lea counter(pc),a0
    cmp.l   #$10,(a0)
    bcs.b   .skip
.out
    move.w  d0,-(a7)
    move.w  offset(pc),d0
	MOVEA.L	(A4,d0.W),A0		;44510: 206c329e
    move.w  (a7)+,d0
	MOVEA.L	(10,A0),A0		;44514: 2068000a
    rts
.skip
    addq.l  #1,(a0)
    add.l   #6,(a7)
    bra.b   .out
    
counter
    dc.l    0

end_level2_int
    moveq.l #0,d0   ; set Z
	MOVEM.L	(A7)+,D0-D7/A0-A6	;: 4cdf7fff
	RTS				;40c70: 4e75
   
; a LOT of SMC alternating between OR.W D3,... and AND.W D4,...
; SHAME for a game using 68020+ instructions so not designed for 68000
; 	ex: BFCLR	D7{8:D2}		;4cce0: ecc70222
;
;        MOVE.B  #$c9,LAB_2088           ;4cb1c: 13fc00c90004ce06
;        MOVE.B  #$87,LAB_2088           ;4cb28: 13fc00870004ce06
;        MOVE.B  #$c9,LAB_2089           ;4cb3a: 13fc00c90004ce08
;        MOVE.B  #$87,LAB_2089           ;4cb46: 13fc00870004ce08
;        MOVE.B  #$c9,LAB_208A           ;4cb58: 13fc00c90004ce0c
;        MOVE.B  #$87,LAB_208A           ;4cb64: 13fc00870004ce0c
;        MOVE.B  #$c9,LAB_208B           ;4cb76: 13fc00c90004ce10
;        MOVE.B  #$87,LAB_208B           ;4cb82: 13fc00870004ce10
;        MOVE.B  #$c9,LAB_208C           ;4cb94: 13fc00c90004ce14
;        MOVE.B  #$87,LAB_208C           ;4cba0: 13fc00870004ce14
;        MOVE.B  #$c9,LAB_208D           ;4cbb2: 13fc00c90004ce16
;        MOVE.B  #$87,LAB_208D           ;4cbbe: 13fc00870004ce16
;        MOVE.B  #$c9,LAB_208E           ;4cbd0: 13fc00c90004ce1a
;        MOVE.B  #$87,LAB_208E           ;4cbdc: 13fc00870004ce1a
;        MOVE.B  #$c9,LAB_208F           ;4cbee: 13fc00c90004ce1e
;        MOVE.B  #$87,LAB_208F           ;4cbfa: 13fc00870004ce1e
; targets:
;LAB_2088:
;	OR.W	D3,(A3)			;4ce06: 8753
;LAB_2089:
;	OR.W	D3,(8000,A3)		;4ce08: 876b1f40
;LAB_208A:
;	OR.W	D3,(16000,A3)		;4ce0c: 876b3e80
;LAB_208B:
;	OR.W	D3,(24000,A3)		;4ce10: 876b5dc0
;LAB_208C:
;	OR.W	D3,(A4)			;4ce14: 8754
;LAB_208D:
;	OR.W	D3,(8000,A4)		;4ce16: 876c1f40
;LAB_208E:
;	OR.W	D3,(16000,A4)		;4ce1a: 876c3e80
;LAB_208F:
;	OR.W	D3,(24000,A4)		;4ce1e: 876c5dc0


; so the easy solution is to flush the cache when it's done
; this seems to fix the otherwise trashed fonts / wrong color ...
; but it's done constantly during game and maybe hinders speed
fix_smc	
	MOVEA.L	(20,A6),A0		;4cc04: 206e0014
    bra _flushcache
    
TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d2
    beq.b   .nochange_\1
    move.b  #\2,d3
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    bset    #7,d3   ; released
.pressed_\1
    pea .nochange_\1(pc)
    MOVEM.L	D0-D7/A0-A6,-(a7)   ; save regs
    move.b  d3,d0
    ; jsr to hook to set key properly
    move.l  a1,-(a7)            
    rts
.nochange_\1
    ENDM
   
new_level3_interrupt
    movem.l d0-d3/a0-a1,-(a7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    beq   .novbl
    ; vblank interrupt, read joystick/mouse
    lea buttons_state(pc),a0
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_read_joystick
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; xor to d2 to get what has changed quickly
    move.l  d0,d2
    eor.l   d1,d2
    beq   .novbl
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d0
    bne     _quit
.noquit    
    move.l int2_hook_address(pc),a1
    ; d2 bears changed bits (buttons pressed/released)
    TEST_BUTTON FORWARD,$5E ; thrust +
    TEST_BUTTON REVERSE,$4A ; thrust -
    TEST_BUTTON BLU,$44     ; return switch weapons
    TEST_BUTTON YEL,$31     ; lock to target
    TEST_BUTTON RED,$40     ; fire
    TEST_BUTTON GRN,$5D     ; after burner increase
    TEST_BUTTON PLAY,$19     ; pause
.novbl
    movem.l (a7)+,d0-d3/a0-a1
    move.l  old_level3_interrupt(pc),-(a7)
    rts
        
old_level3_interrupt
    dc.l    0
buttons_state
    dc.l    0

    
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
	jsr	(a5)
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

    
tag		dc.l	WHDLTAG_CUSTOM4_GET
executable	dc.l	0
        dc.l    WHDLTAG_ATTNFLAGS_GET
attnflags
        dc.l    0
        
		dc.l	0
        
program_to_run
		dc.l	0
offset
    dc.w    0
int2_hook_offset
    dc.l    0
int2_hook_address
    dc.l    0
wrongcustom
    dc.b    "custom exe value out of range 0-3",0

;============================================================================

	END
