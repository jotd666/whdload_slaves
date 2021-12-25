;*---------------------------------------------------------------------------
;  :Program.	AndromedaMissionHD.asm
;  :Contents.	Slave for "AndromedaMission"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: AndromedaMissionHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"AndromedaMission.slave"
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
CHIPMEMSIZE	= $C0000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
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
CACHE


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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
	dc.b	"AKT",0

slv_name		dc.b	"Andromeda Mission"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1988 Demonware",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

intro:
	dc.b	"title",0
program:
	dc.b	"buck",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	dc.b    "C1:X:Trainer Infinite lives:0;"
	dc.b    "C1:X:Trainer Infinite energy:1;"
	dc.b	"C5:B:skip introduction;"
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
        move.l  #$20000-$0001b868,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

;        lea old_level3_interrupt(pc),a0
;        move.l  $6C.W,(a0)
;        pea new_level3_interrupt(pc)
;        move.l  (a7)+,$6C.W
    
	;assigns
		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
        move.l  skip_intro(pc),d0
        bne.b   .no_intro
		lea	intro(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_intro(pc),a5
		bsr	load_exe
.no_intro        
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

patch_main
    bsr get_version
	lea	pl_main_orig(pc),a0
    cmp.w   #1,d0
    beq.b   .original
	lea	pl_main_crk(pc),a0
   
.original
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)
.skip
	rts
    
patch_intro
	lea	pl_intro(pc),a0
    
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)
.skip
	rts

; speed regulation & vbl hook
; not used here. seems that replacing WaitBOVP by a simplified version works
    
vbl_reg:
    movem.l d0-d1/a0-a1,-(a7)
    ; wait BOF once (game does that)
    bsr     wait_bof
    ; now wait another time if we didn't get at least 2 vblanks

    lea vbl_counter(pc),a0
    move.w  (a0),d0
    cmp.w   #2,d0
    bcc.b   .no_wait
    nop
    bsr     wait_bof
.no_wait
    clr.w  (a0)

    movem.l (a7)+,d0-d1/a0-a1
    rts
    
; should do the same as graphics WaitBOVP but seems to work
; whereas the graphics library routine seems to be not tht reliable
; in that context 
wait_bof:
    move.l  #250<<8,d0
.w
	move.l	$dff004,d1
	and.l	#$1ff00,d1
	cmp.l	d0,d1
	bne.b	.w
    rts
    
    
new_level3_interrupt
    movem.l d0/a0,-(a7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    beq.b   .novbl
    ; add to counter
    lea vbl_counter(pc),a0
    addq.w  #1,(a0)
.novbl
    movem.l (a7)+,d0/a0
    move.l  old_level3_interrupt(pc),-(a7)
    rts

; apply on SEGMENTS
pl_main_orig
    PL_START
    PL_PSS  $69a2,game_delay_1,6
    PL_PSS  $2502,game_delay_2,2
    PL_P    $86da,wait_bof
    
    ;;PL_P    $7982,random_routine     ; random routine
    
    ; remove password protection
    PL_B    $52cc,$60
    
    PL_IFC1X    0
    PL_NOP  $2f0c,4     ; infinite lives
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $2d72,6
    PL_NOP  $2eaa,6
    PL_NOP  $2ede,4
    PL_ENDIF
    PL_END
    
pl_main_crk
    PL_START
    PL_PSS  $6828,game_delay_1,6
    PL_PSS  $244e,game_delay_2,2
    PL_P    $8560,wait_bof
    
    ;;PL_P    $7982,random_routine     ; random routine
    
    ; remove password protection
    PL_B    $5152,$60
    
    PL_IFC1X    0
    PL_NOP  $2e58,4     ; infinite lives
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $2cbe,6
    PL_NOP  $2df6,6
    PL_NOP  $2e2a,4
    PL_ENDIF
    PL_END
    
pl_intro
    PL_START
    PL_PSS  $0498,intro_delay,4
    PL_P    $1bd4,wait_bof
    PL_END

random_routine
    moveq   #0,d0
    rts
 
game_delay_1
	move.w  d5,-(a7)
    
    move.w  #$3E8/20,d5
.bd_loop1
	move.w  d5,-(a7)
    move.b	$dff006,d5	; VPOS
.bd_loop2
	cmp.b	$dff006,d5
	beq.s	.bd_loop2
	move.w	(a7)+,d5
	dbf	d5,.bd_loop1
	move.w	(a7)+,d5
	rts 

game_delay_2
    move.w  #$320/20,d5
.bd_loop1
	move.w  d5,-(a7)
    move.b	$dff006,d5	; VPOS
.bd_loop2
	cmp.b	$dff006,d5
	beq.s	.bd_loop2
	move.w	(a7)+,d5
	dbf	d5,.bd_loop1
	rts 
intro_delay
    move.w  #4,d6
.bd_loop1
	move.w  d6,-(a7)
    move.b	$dff006,d6	; VPOS
.bd_loop2
	cmp.b	$dff006,d6
	beq.s	.bd_loop2
	move.w	(a7)+,d6
	dbf	d6,.bd_loop1
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

 
get_version:
	movem.l	d1/a0/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#36232,D0
	beq.b	.original
	cmp.l	#35852,D0
	beq.b	.crack
    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


.original
	moveq	#1,d0
    bra.b   .out
    nop
.crack
	moveq	#2,d0
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

tag		dc.l	WHDLTAG_CUSTOM5_GET
skip_intro	dc.l	0

		dc.l	0
tagseg
        dc.l    WHDLTAG_DBGSEG_SET
segments:
		dc.l	0
		dc.l	0
old_level3_interrupt
    dc.l    0
game_address
    dc.l    0
vbl_counter
    dc.w    0
;============================================================================

	END
