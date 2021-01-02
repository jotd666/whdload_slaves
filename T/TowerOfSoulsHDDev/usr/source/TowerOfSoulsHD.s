;*---------------------------------------------------------------------------
;  :Program.	TowerOfSoulsHD.asm
;  :Contents.	Slave for "TowerOfSouls"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: TowerOfSoulsHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"TowerOfSouls.slave"
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
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $100000
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
;STACKSIZE = 10000
BOOTDOS
CACHE


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA|WHDLF_Req68020
slv_keyexit	= $5D	; num '*'

	include	whdload/kick31.s

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


slv_name		dc.b	"Tower Of Souls / Der Seelenturm"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1995 Black Magic",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config
	dc.b    "C1:B:unlocked savegames;"			
	dc.b	0

program_en:
	dc.b	"TowerOfSouls",0
program_de:
	dc.b	"Seelenturm",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

        patch $104.W,smc_handler
        bsr fix_smc_1_write_0   ; init to 0
	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

        lea program_en(pc),a0
        jsr (resload_GetFileSize,a2)
        tst.l   d0
        beq.b   .german
        
	;load exe
		lea	program_en(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
        bra.b _quit
.german
		lea	program_de(pc),a0
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
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_section0(pc),a0

    ; save those addresses because patchesis going
    ; to overwrite them
    lea    tstaddr(pc),a3
    add.l  #$9e9a,a1
    move.l  (a1),(a3)
    lea     moveaddr(pc),a3
	move.l	d7,a1
	addq.l	#4,a1
    add.l  #$9e8e,a1
    move.l  (a1),(a3)
    
	move.l	d7,a1
	addq.l	#4,a1
	move.l	(_resload,pc),a2
	jsr	resload_Patch(a2)

    pea new_int_3(pc)
    move.l  (a7)+,$6C.W
	rts


REDIRECTED_VBL = $110

new_int_3:
    movem.l d0,-(a7)
    move.w  _custom+intreqr,d0
    btst    #5,d0   ; VBL ?
    beq.b   .blitter

    movem.l a0-a1,-(a7)
    lea vbl_counter(pc),a0
    add.l   #1,(a0)
    movem.l (a7)+,a0-a1


    movem.l (a7)+,d0
    move.w  #$20,_custom+intreq
    rte
    
.blitter:
    movem.l (a7)+,d0
    move.l  REDIRECTED_VBL,-(a7)
    rts
 

    
; english and german versions have different executables;
; but offsets are strictly identical!

pl_section0

	PL_START
	PL_I	$4bc    ; infinite bra loop
    PL_PSS  $9518,delay60000,4
	PL_PS	$9AA8,kb_delay  ; same offset!
    
    ; fix smc
    PL_NOP   $000ffc,8      ; writes 0 in code, but 0 already in code => useless
    PL_NOP   $00d31c,8      ; writes 2 in code, but 2 already in code => useless
    
    PL_PSS  $85CC,fix_smc_1_write_1,2
    PL_PSS  $85f8,fix_smc_1_write_0,2
    PL_L    $85D6,$4EB80104
    PL_PS   $44e20,audio_dma

    PL_PS   $004e6a,ack_level6_interrupt
    PL_PSS  $039448,avoid_af_1,4
    PL_PSS  $03a0e0,avoid_af_2,2
    PL_PSS  $00d25c,avoid_af_3,4

    ; speed regulation
    ; the game uses level 3 interrupt only
    ; for blitter interrupts. We're redirecting
    ; it, and enabling it for vertical blank
    ; this allows to count the ticks and thus
    ; to regulate the speed
    
    PL_W $00261e+$6,REDIRECTED_VBL
    PL_W $002778+$6,REDIRECTED_VBL
    PL_W $00288e+$6,REDIRECTED_VBL
    PL_W $0029b4+$6,REDIRECTED_VBL
    PL_W $004ef0+$6,REDIRECTED_VBL
    PL_W $004f2a+$6,REDIRECTED_VBL
    PL_W $004f4e+$6,REDIRECTED_VBL
    PL_W $004f72+$6,REDIRECTED_VBL
    PL_W $004f96+$6,REDIRECTED_VBL
    PL_W $004fba+$6,REDIRECTED_VBL
    PL_W $004fda+$6,REDIRECTED_VBL
    PL_W $005052+$6,REDIRECTED_VBL
    PL_W $0050b2+$6,REDIRECTED_VBL
    PL_W $0050f2+$6,REDIRECTED_VBL
    PL_W $005132+$6,REDIRECTED_VBL
    PL_W $005172+$6,REDIRECTED_VBL
    PL_W $0051b2+$6,REDIRECTED_VBL
    PL_W $0051f6+$6,REDIRECTED_VBL
    PL_W $005250+$6,REDIRECTED_VBL
    PL_W $00529c+$6,REDIRECTED_VBL
    PL_W $0052c6+$6,REDIRECTED_VBL
    PL_W $0052f0+$6,REDIRECTED_VBL
    PL_W $00531a+$6,REDIRECTED_VBL
    PL_W $00534c+$6,REDIRECTED_VBL
    PL_W $005380+$6,REDIRECTED_VBL
    PL_W $00540e+$6,REDIRECTED_VBL
    PL_W $005462+$6,REDIRECTED_VBL
    PL_W $005494+$6,REDIRECTED_VBL
    PL_W $0054c6+$6,REDIRECTED_VBL
    PL_W $0054f8+$6,REDIRECTED_VBL
    PL_W $005532+$6,REDIRECTED_VBL
    PL_W $00556e+$6,REDIRECTED_VBL
    PL_W $0055d2+$6,REDIRECTED_VBL
    PL_W $005636+$6,REDIRECTED_VBL
    PL_W $005678+$6,REDIRECTED_VBL
    PL_W $0056ba+$6,REDIRECTED_VBL
    PL_W $005704+$6,REDIRECTED_VBL
    PL_W $00575e+$6,REDIRECTED_VBL
    PL_W $00579a+$6,REDIRECTED_VBL
    PL_W $0057f6+$6,REDIRECTED_VBL
    PL_W $00585a+$6,REDIRECTED_VBL
    PL_W $00589c+$6,REDIRECTED_VBL
    PL_W $0058de+$6,REDIRECTED_VBL
    PL_W $005930+$6,REDIRECTED_VBL
    PL_W $005972+$6,REDIRECTED_VBL
    PL_W $0059ae+$6,REDIRECTED_VBL
    PL_W $0094f2+$6,REDIRECTED_VBL
    PL_W $00955a+$6,REDIRECTED_VBL

    PL_W   $002a2e+2,$E068  ; enable vblank to be able to regulate/count
    PL_PS   $9e8c,init_loop_hook
    PL_PS   $9e98,main_loop_hook
    
    ; trainer: unlocks savegames
    PL_IFC1
    PL_B     $02c54e,$60
    PL_NOP  $02c800,2
    PL_W    $0320a8,$FF
    PL_ENDIF
    
	PL_END
 
init_loop_hook:
    movem.l a0,-(a7)
    move.l  moveaddr(pc),a0
    clr.w   (a0)
    lea previous_vbl_counter(pc),a0
    move.l  vbl_counter(pc),(a0)
    movem.l (a7)+,a0
    rts
 
main_loop_hook:
	movem.l	d0/a0/a1,-(a7)
	lea	previous_vbl_counter(pc),a0
	lea	vbl_counter(pc),a1
	move.l  (a0),d0
	add.l	#1,d0
	; wait 1 VBL
.wait
	cmp.l	(a1),d0
	bcc.b	.wait

	; store current counter
	move.l	(A1),(a0)
.avoid
    move.l  tstaddr(pc),a0
    tst.w   (a0)        ; original code
	movem.l	(a7)+,d0/a0/a1
    rts

	
    
moveaddr
    dc.l    0
tstaddr
    dc.l    0
vbl_counter
    dc.l    0
previous_vbl_counter
    dc.l    0
    
ack_level6_interrupt:
    MOVE.W	#$2000,(intreq,A6)  ; original code
    tst.b   $BFDD00     ; acknowledges interrupt to the CIA. Else interrupt goes on and on
    rts

avoid_af_1
    ; access a table which seems valid up to D7 = $64
    ; after that, it's no longer valid and can trigger access faults
    cmp.w   #104,d7
    bcc.b   .access_fault
	MOVEA.L	(0,A2,D7.W),A2		;: 24727000
	MOVE.L	(20,A2),(24,A3)		;03944c: 276a00140018   ; possible access fault here
    rts
.access_fault
    ; doing nothing is probably the best option here
    move.w     #$F0,$DFF180
    clr.l   (24,A3)
    rts

avoid_af_2
    cmp.w   #104,d1
    bcc.b   .access_fault
    ; same access fault issue
	MOVEA.L	(0,A2,D1.W),A2		;03a0e0: 24721000
	MOVE.W	(22,A2),D4		;03a0e4: 382a0016
    rts
.access_fault
    ; doing nothing is probably the best option here
    move.w     #$F00,$DFF180
    moveq.l #0,d4
    rts

avoid_af_3:
    cmp.w   #104,d0
    bcc.b   .access_fault
	MOVEA.L	(20,A3),A2		;: 246b0014
.out
	CMPA.L	#-1,A2		;00d260: b5fcffffffff
    rts
.access_fault:
    move.w     #$F,$DFF180
    move.l  #-1,a2
    bra.b   .out
    
audio_dma
    MOVE.W	D0,$dff096
    movem.l d0,-(a7)
    bsr soundtracker_loop
    movem.l (a7)+,d0
    rts
 
soundtracker_loop
	move.w	#8,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
    
    
fix_smc_1_write_1
    move.b  #1,$10A.W
    rts
fix_smc_1_write_0
    clr.b  $10A.W
    rts
    
smc_handler
    move.b  $10A.w,d0
    rts
    
blitter_interrupt
	illegal
	btst	#6,$dff01e
	beq.b	.out
	addq.l	#2,(A7)	; skip next 2 bytes
	rts
.out
	illegal
	addq.l	#4,a7	; pop the stack
	move.w	#$50,$dff09c
	rte

delay60000
    move.l  #6000,d0
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.w	#$FFFF,d0
	rts
kb_delay:
;	bset	#6,$BFEE01
	movem.l	D0,-(A7)
    not.b   d0
    ror.b   #1,d0
    cmp.b   _keyexit(pc),d0
    beq   _quit
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
;	bclr	#6,$BFEE01
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
	add.l	d7,d7
	add.l	d7,d7
    IFD	CHIP_ONLY
    move.l  d7,$100.W
    ENDC
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
		dc.l	0

;============================================================================

	END
