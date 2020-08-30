;*---------------------------------------------------------------------------
;  :Program.	BlackDawnHD.asm
;  :Contents.	Slave for "BlackDawn"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BlackDawnHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"BlackDawn.slave"
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
NO68020

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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

assign
	dc.b	"bd",0

slv_name		dc.b	"Black Dawn"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"199? Andrew Campbell",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"Black",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	dc.b    "C1:X:Trainer Infinite energy:0;"
	dc.b	"C5:B:disable speed regulation;"
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
        move.l  #$02268,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

    
	;assigns
		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

    move.l  disable_speed_regulation(pc),d0
    bne.b   .skipvbl
    ; install vbl hook which counts vblank
    ; and also reads controllers
        lea old_level3_interrupt(pc),a0
        move.l  $6C.W,(a0)
        lea new_level3_interrupt(pc),a0
        move.l  a0,$6C.W
.skipvbl
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
	lea	pl_main(pc),a0
	bsr	get_version
    
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)
.skip
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

regulate_speed
    movem.l d1/a0,-(a7)
    moveq.l #5,d1
    bsr vbl_reg
    
    movem.l (a7)+,d1/a0
    ; original code
	MOVE.L	#$00000028,D3		;: 263c00000028
    rts

vbl_reg: 
    movem.l d0/a0-a1,-(a7)
    lea vbl_counter(pc),a0
    move.w  (a0),d0
    cmp.w   #20,d0
    bcc.b   .nowait     ; first time called/lost sync/pause/whatever
    ; wait till at least x vblanks passed after last zeroing
.wait
    cmp.w   (a0),d1
    bcc.b   .wait
.nowait
    clr.w   (a0)
    movem.l (a7)+,d0/a0-a1
    rts
        
; apply on SEGMENTS
pl_main
    PL_START
    PL_IFC1X    0
    PL_PS  $06b2a,trainer       ; hit walls
    PL_NOP  $07ca4,4            ; monster damage
    PL_ENDIF
    
    PL_PS   $120a2,dma_wait_d0
    PL_PS   $122b4,dma_wait_d0
    PL_PS   $13070,dma_wait_d0
    PL_PS   $13096,dma_wait_d0_bis
    PL_PS   $11a3e,dma_wait_d1
    PL_PS   $11ba6,dma_wait_d7
    PL_PS   $1305e,dma_wait_d4
    PL_PS   $11940,dma_wait_000f
    PL_IFC5
    PL_ELSE
    PL_PS      $05db2,regulate_speed
    PL_ENDIF
    PL_END
    
dma_wait_000f
    MOVE.W	#$000f,dmacon(A0)		;: 317c000f0096
    bra soundtracker_loop

dma_wait_d0_bis
	MOVE.W	D0,dmacon(A0)		;13096: 31400096
	MOVEQ	#3,D1			;1309a: 7203
    bra soundtracker_loop
dma_wait_d1
    MOVE.W  D1,_custom+dmacon               ;: 33c000dff096
    bra soundtracker_loop
dma_wait_d4
    MOVE.W  D4,_custom+dmacon               ;: 33c000dff096
    bra soundtracker_loop
dma_wait_d7
    MOVE.W  D7,_custom+dmacon               ;: 33c000dff096
    bra soundtracker_loop
    
dma_wait_d0
    MOVE.W  D0,_custom+dmacon               ;: 33c000dff096
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
        
trainer:
	;;MOVEA.L	D7,A0			;06b2a: 2047
    ; decrease energy
    cmp.l   #$77,d3
    bcs.b   .zap
	MOVE.L	D3,230(A0)		;06b2c: 214300e6
.zap
    rts
    
    
get_version:
	movem.l	d1/a0/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#132872,D0
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

tag		dc.l	WHDLTAG_CUSTOM5_GET
disable_speed_regulation	dc.l	0

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
