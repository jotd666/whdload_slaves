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

	IFD BARFLY
	OUTPUT	"AsterixGetAFix.slave"
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
CHIPMEMSIZE	= $C0000
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
STACKSIZE = 8000
BOOTDOS

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s
    include ReadJoyPad.s
    
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
    
slv_config:		
        dc.b    "C1:B:Trainer Infinite Energy;"
        dc.b    "C3:X:Disable blitter fixes:0;"
        dc.b    "C3:X:Disable speed regulation:1;"
		dc.b	0

slv_name		dc.b	"Asterix - Operation Getafix / Hinkelstein / Le coup du menhir"
    IFD CHIP_ONLY
    dc.b    " (DEBUG MODE)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1989 Cockel Vision",0
slv_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to Tony Aksnes/Captain HIT for disk images",10,10
		dc.b	"Version "
		DECL_VERSION

		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"essai",0
_args		dc.b	10
_args_end
	dc.b	0

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

    bsr _detect_controller_types
    
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
       move.l  #$3FA0-$7D0,d0
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
        PATCH_XXXLIB_OFFSET BltClear
        PATCH_XXXLIB_OFFSET BltMaskBitMapRastPort
        PATCH_XXXLIB_OFFSET BltBitMap
skip_gfx_fix
        
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase


	;load exe
		lea	_program(pc),a0
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
    
; this should work and should be faster, but apparently it does not!!
DECL_GFX_WITH_WAIT_NW:MACRO
new_\1
    bsr wait_blit
	move.l	old_\1(pc),-(a7)
	rts

    ENDM
    
    ; the calls where a wait is useful
    DECL_GFX_WITH_WAIT  BltClear
    DECL_GFX_WITH_WAIT  BltMaskBitMapRastPort
    DECL_GFX_WITH_WAIT  BltBitMap
    DECL_GFX_WITH_WAIT  RectFill
   

    
; < d7: seglist (APTR)

patch_main
	move.l	d7,a1
	add.l	#4,a1	; first segment
    IFD CHIP_ONLY
    move.l  a1,$100.W
    ENDC
	; english?

	lea	pl_main_uk_1(pc),a0

	move.l	a1,a2
	add.l	#$A074,a2
	cmp.l	#$0C6D0031,(a2)
	beq.b	.patch

	; english v2?

	lea	pl_main_uk_2(pc),a0

	move.l	a1,a2
	add.l	#$A092,a2
	cmp.l	#$0C6D0031,(a2)
	beq.b	.patch

	; german?

	lea	pl_main_de(pc),a0

	move.l	a1,a2
	add.l	#$A130,a2
	cmp.l	#$0C6D0031,(a2)
	beq.b	.patch

    ; french ?
	lea	pl_main_fr(pc),a0
	move.l	a1,a2
	add.l	#$0a520,a2
	cmp.l	#$0C6D0031,(a2)
	beq.b	.patch

    ; spanish ?
    
	lea	pl_main_sp(pc),a0
	move.l	a1,a2
	add.l	#$0a030,a2
	cmp.l	#$0C6D0031,(a2)
	beq.b	.patch

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
.patch
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	rts

pl_main_fr
    PL_START
	; no need to press protection number: this looks wrong

	PL_S	$0a512,6
	PL_L	$0a520,$70006016

	; crack

	PL_PS	$31D0,fix_protection_de_fr

	; fix access faults

	PL_PSS	$1aeec,fix_af_1,2
	PL_PSS	$1B15A,fix_af_2,2

    ; wrong blitter waits (testing bit 14 of $DFF002 in memory)
    ; plus those are useless and don't prevent program to be broken
    PL_NOP  $1c366,10
    PL_NOP  $1c3c2,10
    
    ; cpu-dependent for(;;) loops
    PL_PSS  $1a50e,cpu_loop_1,6
    PL_PSS  $1b7d0,cpu_loop_2,6

    ; wrong CIA word read
    PL_PS  $1d7fe,read_ciasdr
    
    ; audio dma delay else sound is borked
    PL_PSS  $1dd26,sound_dma_write,2
    PL_PS   $1dc7c,sound_dma_write_2

    ; right mouse button replacement read
    PL_PSS   $1b6ae,read_right_mouse,6

    ; speed regulation
    PL_IFC3X    1
    PL_ELSE
    PL_PS   $02b38,regulate_speed
    PL_ENDIF
    
    ; trainer
    PL_IFC1
    PL_NOP  $0edce,4
    PL_NOP  $0edd8,4
    PL_ENDIF

    ; restore original code (cracked version)
    PL_W    $03c7a,$504F
    PL_END
    
pl_main_uk_2
	PL_START
	; no need to press protection number

	PL_S	$A084,6
	PL_L	$A092,$70006016

	; crack

	PL_PS	$31D0,fix_protection

	; fix access faults

	PL_PSS	$1AA66,fix_af_1,2
	PL_PSS	$1ACD4,fix_af_2,2
    
    ; wrong blitter waits (testing bit 14 of $DFF002 in memory)
    ; plus those are useless and don't prevent program to be broken
    PL_NOP  $1bee0,10
    PL_NOP  $1bf3c,10
    
    ; cpu-dependent for(;;) loops
    PL_PSS  $1a088,cpu_loop_1,6
    PL_PSS  $1b34a,cpu_loop_2,6

    ; wrong CIA word read
    PL_PS  $1d378,read_ciasdr
    
    ; audio dma delay else sound is borked
    PL_PSS  $1d8a0,sound_dma_write,2
    PL_PS   $1d7f6,sound_dma_write_2
    
    ; right mouse button replacement read
    PL_PSS   $1b228,read_right_mouse,6
    
    ; speed regulation
    PL_IFC3X    1
    PL_ELSE
    PL_PS   $02b38,regulate_speed  ; regulates both action & druid part
    PL_ENDIF
    
    ; trainer
    PL_IFC1
    PL_NOP  $0e948,4
    PL_NOP  $0e952,4
    PL_ENDIF
    
	PL_END

pl_main_sp
	PL_START
	; no need to press protection number

	PL_S	$0a022,6
	PL_L	$0a030,$70006016

	; crack

	PL_PS	$31D0,fix_protection

	; fix access faults

	PL_PSS	$1aa04,fix_af_1,2
	PL_PSS	$1ac72,fix_af_2,2
    
    ; wrong blitter waits (testing bit 14 of $DFF002 in memory)
    ; plus those are useless and don't prevent program to be broken
    PL_NOP  $1be7e,10
    PL_NOP  $1beda,10
    
    ; cpu-dependent for(;;) loops
    PL_PSS  $1a026,cpu_loop_1,6
    PL_PSS  $1b2e8,cpu_loop_2,6

    ; wrong CIA word read
    PL_PS  $1d316,read_ciasdr
    
    ; audio dma delay else sound is borked
    PL_PSS  $1d83e,sound_dma_write,2
    PL_PS   $1d794,sound_dma_write_2
    
    ; right mouse button replacement read
    PL_PSS   $1b1c6,read_right_mouse,6
    
    ; speed regulation
    ;;;PL_PS   $03104,regulate_speed_action   ; regulates action part only
    PL_IFC3X    1
    PL_ELSE
    PL_PS   $02b38,regulate_speed  ; regulates both action & druid part
    PL_ENDIF
    
    ; trainer
    PL_IFC1
    PL_NOP  $0e8e6,4
    PL_NOP  $0e8f0,4
    PL_ENDIF
    
	PL_END

pl_main_de
	PL_START
	; no need to press protection number

	PL_S	$A122,6
	PL_L	$A130,$70006016

	; crack

	PL_PS	$31D0,fix_protection_de_fr

	; fix access faults

	PL_PSS	$1AB04,fix_af_1,2
	PL_PSS	$1AD72,fix_af_2,2

    ; wrong blitter waits (testing bit 14 of $DFF002 in memory)
    ; plus those are useless and don't prevent program to be broken
    PL_NOP  $1bf7e,10
    PL_NOP  $1bfda,10
    
    ; cpu-dependent for(;;) loops
    PL_PSS  $1a126,cpu_loop_1,6
    PL_PSS  $1b3e8,cpu_loop_2,6

    ; wrong CIA word read
    PL_PS  $1d416,read_ciasdr
    
    ; audio dma delay else sound is borked
    PL_PSS  $1d93e,sound_dma_write,2
    PL_PS   $1d894,sound_dma_write_2

    ; right mouse button replacement read
    PL_PSS   $1b2c6,read_right_mouse,6
    
    ; speed regulation
    PL_IFC3X    1
    PL_ELSE
    PL_PS   $02b38,regulate_speed
    PL_ENDIF
    
    ; trainer
    PL_IFC1
    PL_NOP  $0e9e6,4
    PL_NOP  $0e9f0,4
    PL_ENDIF

	PL_END


pl_main_uk_1
	PL_START
	; no need to press protection number

	PL_S	$A066,6
	PL_L	$A074,$70006016

	; crack

	PL_PS	$31D0,fix_protection

	; fix access faults
	PL_PSS	$1AA40,fix_af_1,2
	PL_PSS	$1ACAE,fix_af_2,2

    ; wrong blitter waits (testing bit 14 of $DFF002 in memory)
    ; plus those are useless and don't prevent program to be broken
    PL_NOP  $1beba,10
    PL_NOP  $1bf16,10
    
    ; cpu-dependent for(;;) loops
    PL_PSS  $1a062,cpu_loop_1,6
    PL_PSS  $1b324,cpu_loop_2,6

    ; wrong CIA word read
    PL_PS  $1D352,read_ciasdr
    
    ; audio dma delay else sound is borked
    PL_PSS  $1d87a,sound_dma_write,2
    PL_PS   $1d7d0,sound_dma_write_2
    
    ; right mouse button replacement read
    PL_PSS   $1b202,read_right_mouse,6

    ; speed regulation
    PL_IFC3X    1
    PL_ELSE
    PL_PS   $02b38,regulate_speed
    PL_ENDIF
    
    ; trainer
    PL_IFC1
    PL_NOP  $0e922,4
    PL_NOP  $0e92c,4
    PL_ENDIF

	PL_END

read_right_mouse
    move.l  joy0(pc),d0
    not.l   d0
    btst    #JPB_BTN_BLU,d0
    rts

regulate_speed
    movem.l d1,-(a7)
    moveq.l #2,d1
    bsr vbl_reg
    movem.l (a7)+,d1
    
	TST.B	13(A5)			;02b38: 4a2d000d
    bne.b   .nob
    add.l   #$72-$3e,(a7)
.nob
    rts
    
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
    bsr _joystick
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
    
    
sound_dma_write_2
    MOVE.W	D1,_custom+dmacon
    bra.b   sound_delay
    
sound_dma_write
    MOVE.W	0(A5,D0.W),_custom+dmacon
sound_delay
    movem.w D0,-(a7)
    move.w  #4,d0
    bsr beamdelay
    movem.w (a7)+,d0
    rts
 
read_ciasdr
	MOVE.B	(1,A0),D0			;1d352: 3010 avoid reading as word
	AND.W	#$007f,D0		;1d354: c07c007f
    RTS
    
cpu_loop_2
    move.w  #10,d0
    bsr beamdelay
    rts
    
cpu_loop_1
    move.w  #220,d0
    bsr beamdelay
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
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
    
FIX_BIT31_AF:MACRO
	cmp.l	#-1,a0
	beq.b	.sk\@
	movem.l	d0,-(a7)
	move.l	a0,d0
	bclr	#31,d0
	move.l	d0,a0
	movem.l	(a7)+,d0

	move.l	(a0),(-\1,a5)
.out\@
	tst.l	(-\1,a5)
	rts
.sk\@
	clr.l	(-\1,a5)
	bra.b	.out\@
	ENDM

fix_protection
	MOVE.B	D0,-25964(A4)		;031D0: 122C9A94
	move.b	d0,d1
	EXT	D1			;031D4: 4881
	rts

fix_protection_de_fr
	MOVE.B	D0,-25896(A4)
	move.b	d0,d1
	EXT	D1
	rts

fix_af_1
	FIX_BIT31_AF	$10
fix_af_2
	FIX_BIT31_AF	$C

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
_gfxname
    dc.b    "graphics.library",0
    
;============================================================================

	END
