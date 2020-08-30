;*---------------------------------------------------------------------------
;  :Program.	Populous2HD.asm
;  :Contents.	Slave for "Populous2"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: Populous2HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Populous2.slave"
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
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $90000
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
SETPATCH
STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_NoDivZero|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	kick13.s

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

assign
	dc.b	"Populous2",0


slv_name		dc.b	"Populous II"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1991 Bullfrog",0
slv_info		dc.b	"adapted by Bored Seal & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"populous.ii",0
args		dc.b	10
args_end
	dc.b	0
program2		dc.b	"challenge",0
credits		dc.b	"credits-cg.exe",0

slv_config		
	dc.b	"C4:L:Game:Classic,Challenge Games;"
	dc.b	"C5:B:disable speed regulation (classic game);"
	dc.b	0	
	even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

_bootdos
		clr.l	$0.W

        IFD CHIP_ONLY
        move.l  4,A6
        move.l  #$3368,D0
        move.l  #MEMF_CHIP,d1
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

    move.l  disable_speed_regulation(pc),d0
    bne.b   .skipvbl
    ; install vbl hook which counts vblank
    ; and also reads controllers
        lea old_level3_interrupt(pc),a0
        move.l  $6C.W,(a0)
        lea new_level3_interrupt(pc),a0
        move.l  a0,$6C.W
.skipvbl
    move.l  game_type(pc),d0
    bne.b   _challenge
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
_challenge
	;load exe
		lea	credits(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		sub.l   a5,a5
		bsr	load_exe
		lea	program2(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main2(pc),a5
		bsr	load_exe
        bra _quit


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

regulate_speed
    movem.l d1/a0,-(a7)
    moveq.l #2,d1
    bsr vbl_reg
    
    ; original code
    move.l  game_address(pc),a0
    tst.w   (a0)
    movem.l (a7)+,d1/a0

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
    

    
; < d7: seglist (BPTR)

patch_main
	bsr	get_version

    move.l  d7,a1
    add.l   a1,a1
    add.l   a1,a1
    lea game_address(pc),a0
    move.l  ($E76+2+4,a1),(a0)  ; store game address


	move.l	d7,a1
	lea	pl_main(pc),a0
	jsr	resload_PatchSeg(a2)

	rts
; < d7: seglist (BPTR)

patch_main2
    move.l  d7,$100

	move.l	d7,a1
	lea	pl_challenge(pc),a0
	jsr	resload_PatchSeg(a2)

    
	rts


pl_main
	PL_START
	PL_NOP	$330C,4	; protection removal
	PL_P	$160,_quit	; clean game exit to wb
	PL_R	$00cb2	; no open screen, crashes (maybe wrong params?)
	PL_R	$00d28	; no close screen
    
    PL_PS   $194d4,dma_sound_wait
    
    PL_PSS  $17fcc,cpu_dependent_loop,2
    PL_PSS  $17fb8,cpu_dependent_loop,2
    
    PL_IFC5
    PL_ELSE
    PL_PS   $00e76,regulate_speed
    PL_ENDIF
	PL_END
    
pl_challenge
	PL_START
	PL_W    $EAE,$6006		;no int after DisownBlitter
	PL_B	$624,$60    	;no gfx trash when 'Esc' is pressed
    PL_PSS  $1e8ae,cpu_dependent_loop,2
    PL_PSS  $1e8c2,cpu_dependent_loop,2
    
    ; remove df0: prefix
    PL_DATA $20b42,7
    dc.b    "fx.dat",0
    even
    
    ; this is needed in kickstart 1.3, must be buggy...
    ; worked in OSEmu! and works perfect in 3.1 as well
    ; but since opening a screen isn't needed, let's skip it
    PL_R    $00ce2      ; open screen
    ;;PL_R    $00cbc      ; close workbench
    ;;PL_P    $000e8,lock_root
	PL_END

; < A6: dosbase
lock_root:
    lea .root(pc),a0
    move.l  a0,d1
	move.l	#ACCESS_READ,D2
    blitz
	jsr	(_LVOLock,a6)
    rts
.root
    dc.b    0
    even
    
cpu_dependent_loop
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$20,D0 ; empiric. $28 for dbf, must be slightly slower
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.w	#$FFFF,d0
	rts
    
dma_sound_wait
    MOVE.W	D2,$dff096
soundtracker_loop
	move.w  d0,-(a7)
	move.w	#4,d0
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
	movem.l	d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#297996,D0
	beq.b	.v1

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.v1
	moveq	#1,d0
;	bra.b	.out

.out
	movem.l	(a7)+,d1/a1
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

	;get tags
    lea bcplptr(pc),a1
    move.l  d7,(a1)
    lea	(segtag,pc),a0
    move.l  _resload(pc),a2
	jsr	(resload_Control,a2)

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)
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

segtag
    dc.l    WHDLTAG_DBGSEG_SET
bcplptr:
    dc.l    0
    dc.l    0
    
tag
    dc.l	WHDLTAG_CUSTOM5_GET
disable_speed_regulation
    dc.l	0
    dc.l	WHDLTAG_CUSTOM4_GET
game_type
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
