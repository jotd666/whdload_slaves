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
	OUTPUT	"ScubaDiver.slave"
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
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $00000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
INITAGA
HDINIT
IOCACHE		= 10000
MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 10000
SEGTRACKER
BOOTDOS
CACHE


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'

	include	whdload/kick31.s

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

assign1
	dc.b	"Disk 001",0
assign2
	dc.b	"Disk 002",0
assign3
	dc.b	"Disk 003",0
assign4
	dc.b	"ENV",0
ram:
    dc.b    "RAM:",0
    
slv_name		dc.b	"Scuba Diver"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1994 Surreal",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"scuba_diver",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	dc.b    "C1:X:Trainer Infinite energy:0;"
	dc.b    "C1:X:Trainer Infinite lives:1;"
	dc.b    "C1:X:Trainer Infinite air:2;"
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
		lea	assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign4(pc),a0
		lea ram(pc),a1
		bsr	_dos_assign


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


; apply on SEGMENTS
pl_main
    PL_START
    ; zero instead of VBR => D1
    PL_L    $00922,$4E717200
    
    ; wrong level 3 interrupt acknowledge that locked up the game
    PL_W    $bd81a+2,$7FFC

    ; fix access faults
    PL_PS   $c2c64,fix_af
    PL_PS   $c105a,fix_af_2
    
    ; quitkey with VBR at 0
    PL_PSS  $bbb02,ack_keyboard,4
    
    ; sound delays
    PL_PSS  $bc840,soundtracker_wait,4
    PL_PSS  $bc858,soundtracker_wait,4
    PL_PSS  $bcf34,soundtracker_wait,4
    PL_PSS  $bcf46,soundtracker_wait,4
    
    ; trainer: infinite energy
    PL_IFC1X    0
    PL_NOP      $beefc,6
    PL_ENDIF
    ; infinite lives
    PL_IFC1X    1
    PL_NOP      $c13ba,6
    PL_ENDIF
    ; infinite air
    PL_IFC1X    2
    PL_NOP      $beebc,6
    PL_ENDIF

    ; faster & safer blitwaits
    ; 3 nops (not a problem, blitter is working)
    ; followed by actual wait_blit call
    
    PL_PS  $bdd4a+6,wait_blit
    PL_PS  $bdd78+6,wait_blit
    PL_PS  $beac4+6,wait_blit
    PL_PS  $bec9a+6,wait_blit
    PL_PS  $bef7c+6,wait_blit
    PL_PS  $befa4+6,wait_blit
    PL_PS  $befcc+6,wait_blit
    PL_PS  $beff4+6,wait_blit
    PL_PS  $c00a6+6,wait_blit
    PL_PS  $c0126+6,wait_blit
    PL_PS  $c0186+6,wait_blit
    PL_PS  $c03aa+6,wait_blit
    PL_PS  $c03e8+6,wait_blit
    PL_PS  $c0428+6,wait_blit
    PL_PS  $c0466+6,wait_blit
    PL_PS  $c04a6+6,wait_blit
    PL_PS  $c04e4+6,wait_blit
    PL_PS  $c0524+6,wait_blit
    PL_PS  $c0562+6,wait_blit
    PL_PS  $c0764+6,wait_blit
    PL_PS  $c07fa+6,wait_blit
    PL_PS  $c0a32+6,wait_blit
    PL_PS  $c100e+6,wait_blit
    PL_PS  $c1f8c+6,wait_blit
    PL_PS  $c2018+6,wait_blit
    PL_PS  $c205c+6,wait_blit
    PL_PS  $c2d58+6,wait_blit
    PL_PS  $c301e+6,wait_blit

    PL_NOP  $bdd4a,6
    PL_NOP  $bdd78,6
    PL_NOP  $beac4,6
    PL_NOP  $bec9a,6
    PL_NOP  $bef7c,6
    PL_NOP  $befa4,6
    PL_NOP  $befcc,6
    PL_NOP  $beff4,6
    PL_NOP  $c00a6,6
    PL_NOP  $c0126,6
    PL_NOP  $c0186,6
    PL_NOP  $c03aa,6
    PL_NOP  $c03e8,6
    PL_NOP  $c0428,6
    PL_NOP  $c0466,6
    PL_NOP  $c04a6,6
    PL_NOP  $c04e4,6
    PL_NOP  $c0524,6
    PL_NOP  $c0562,6
    PL_NOP  $c0764,6
    PL_NOP  $c07fa,6
    PL_NOP  $c0a32,6
    PL_NOP  $c100e,6
    PL_NOP  $c1f8c,6
    PL_NOP  $c2018,6
    PL_NOP  $c205c,6
    PL_NOP  $c2d58,6
    PL_NOP  $c301e,6
        
    ; fix color bit
    PL_ORW  $99af6,$200 ; default value in copperlist
    
    ; other values set by CPU in copperlist
    PL_ORW  $be02c+2,$200
    PL_ORW  $be7b4+2,$200
    PL_ORW  $be8dc+2,$200
    PL_ORW  $c18b8+2,$200
    PL_ORW  $c1a30+2,$200
    PL_ORW  $c25f2+2,$200
    PL_ORW  $c3138+2,$200
    PL_ORW  $c31d2+2,$200
    ; other values set by CPU in register
    PL_ORW  $c1d70+2,$200    
    PL_ORW  $c26e0+2,$200    
    PL_ORW  $c31c2+2,$200    
    
    ; fixed keyboard
    
    PL_END

ack_keyboard
	MOVE.B	$bfec01,d0
    ror.b   #1,d0
    not.b   d0
    cmp.b   _keyexit(pc),d0
    beq   _quit
    
	move.l	#2,d0
	bsr	beamdelay
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
fix_af:
    and.l   #$FFFF,d0   ; fix: remove MSW that can be anything
    ; rest unchanged
	LSL.W	#2,D0			;c2c64: e548
	ADDA.L	D0,A0			;c2c66: d1c0
	ADDA.L	D0,A1			;c2c68: d3c0
    rts
    
fix_af_2
    ; possible fault here
    ; was D0.L but since it's masked with 7 just before, no need to use long
	move.L	(0,A0,D0.W*4),d0	;c105a: d3f00c00
    ; filters out MSW, table only contains 16 bit offsets
    ; but can be polluted by unknown shit. Isn't an issue on 24 bit
    ; so wasn't noticed
    and.l   #$FFFF,d0
    ; now add to a1 after masking
    add.l   d0,a1
    rts

soundtracker_wait
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
	move.w	(a7)+,d0
	rts 
    
get_version:
	movem.l	d1/a0/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#535156,D0
	beq.b	.ok
    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.ok
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

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
        dc.l    WHDLTAG_DBGSEG_SET
segments:
		dc.l	0
		dc.l	0

;============================================================================

	END
