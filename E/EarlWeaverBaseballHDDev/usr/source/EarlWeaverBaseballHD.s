;*---------------------------------------------------------------------------
;  :Program.	EarlWeaverBaseballHD.asm
;  :Contents.	Slave for "EarlWeaverBaseball"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: EarlWeaverBaseballHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"EarlWeaverBaseball.slave"
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
WPDRIVES	= %1111

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
BOOTDOS
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 10000
;CBDOSLOADSEG
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
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

_assign
	dc.b	"Earl Weaver Baseball",0
_assign_df0
	dc.b	"df0",0

slv_name		dc.b	"Earl Weaver Baseball"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1986-1987 Electronic Arts",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Thanks to LockPick for help with protection",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_config:
    dc.b    "BW;"
	dc.b	"C2:B:Start commissioner disk editor;"
    dc.b    "C3:X:fast introduction:0;"
	dc.b	"C5:B:disable speed regulation;"
    dc.b    0
slv_CurrentDir:
	dc.b	"data",0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION

main:
	dc.b	"EarlWeaverBaseBall",0
commissioner:
    dc.b    "commissioner",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	EVEN

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
        lea _dosbase(pc),a0
        move.l  d0,(a0)

    move.l  disable_speed_regulation(pc),d0
    bne.b   .skipvbl
    ; install vbl hook which counts vblank
    ; and also reads controllers
        lea old_level3_interrupt(pc),a0
        move.l  $6C.W,(a0)
        lea new_level3_interrupt(pc),a0
        move.l  a0,$6C.W
.skipvbl
        
	;assigns
		lea	_assign(pc),a0
        sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_df0(pc),a0
        sub.l	a1,a1
		bsr	_dos_assign

	;load exe
    movem.l A6,-(a7)
    ; commissioner: we'll block the fast memory as it triggers
    ; access faults. Probably not 32 bit compatible...
    ; not going to spend hours trying to fix that...
    move.l  4,a6
  	move.l	#MEMF_FAST|MEMF_LARGEST,D1
	jsr (_LVOAvailMem,a6)
   	move.l	#MEMF_FAST|MEMF_LARGEST,D1
	jsr (_LVOAllocMem,a6)
    movem.l (a7)+,a6
    
        move.l  launch_commissioner(pc),d0
        beq.b   .main
		lea	commissioner(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea patch_commissioner(pc),a5
		bsr	load_exe
        bra.b _quit
.main
		lea	main(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_ewb(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (BPTR)

patch_ewb
	; protection, called on "play ball" menu option
	; asks for original disk
    
    move.l  d7,a1
    lea pl_ewb(pc),a0
	move.l	(_resload,pc),a2
	jsr	resload_PatchSeg(a2)
	rts
    
patch_commissioner
    move.l  d7,a1
    lea pl_commissioner(pc),a0
	move.l	(_resload,pc),a2
	jsr	resload_PatchSeg(a2)
	rts

pl_commissioner:
    PL_START
    PL_P    $33bcc,text_and_wait
    PL_P    $33bae,blit_and_wait
    PL_P    $33d38,rectfill_and_wait
    PL_END


text_and_wait:
    JSR     (_LVOText,A6)   ;33bcc: 4eaeffc4 graphics.library (off=-60)
    JSR (_LVOWaitBlit,A6)
	MOVEA.L	(A7)+,A6		;33bd0: 2c5f
	RTS				;33bd2: 4e75
  
blit_and_wait:
	JSR	(_LVOBltBitMap,A6)	;: 4eaeffe2 graphics.library (off=-30)
    JSR (_LVOWaitBlit,A6)
	MOVEM.L	(A7)+,D2-D7/A2/A6	;33bb2: 4cdf44fc
	RTS				;33bb6: 4e75

rectfill_and_wait:
    JSR (_LVORectFill,A6)
    JSR (_LVOWaitBlit,A6)
	MOVEM.L	(A7)+,D2-D3/A6		;33d3c: 4cdf400c
	RTS				;33bb6: 4e75
    
pl_root
	PL_START
    ; section 229
    PL_IFC5
    PL_ELSE
	PL_PSS	$2C406,mainloop,2
    
    PL_PS   $2D366,practice_1_loop
    PL_PS   $2CE92,practice_2_loop
    PL_PS   $2D626,practice_3_loop  ; pitching
    PL_ENDIF
    
    ; not sure if this is a problem but this is a classical problem
    ; so let's prevent a mishap.
    PL_P    $3B148,rectfill_and_wait    
    
    ; hook on infinite loop, not really useful, but that way
    ; we can use "f $20000 $80000" on WinUAE to track game code
    PL_PA    $0008C,infinite_loop
	PL_END
    
pl_ewb
    ; section 9
	PL_START
	PL_PS	$36A+$0a48,emulate_dbf

    ; section 20
	PL_R	$21F8
	PL_L	$48+$21F8,$3E61
	PL_I	$718+$21F8	; active wait loop

;;	PL_R	$512	; drive to head 0
;;	PL_R	$6BE	; track to zero

    ; section 24
	PL_PS	$31d4,patch_titles_1
	PL_PS	$31ea,patch_titles_2
	PL_PS	$31f8,patch_titles_3
	PL_PS	$32f2,patch_in
	;;PL_AL	$32fa+2,21		; skip "Earl Weaver Baseball:" assign
	PL_PS	$3384,patch_root
    
    PL_IFBW
    PL_PS   $3268,after_narrator
    PL_ENDIF
    
    PL_IFC3X    0
    PL_R    $4d80   ; no delay, so intro pics are shown super fast!!
    PL_ENDIF
    
    
    ;;PL_P    $4D58,load_seg
	PL_END
    

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
    
    
load_seg:
	MOVE.L	A6,-(A7)		;4d58: 2f0e
	MOVE.L	8(A7),D1		;4d5a: 222f0008
	MOVEA.L	_dosbase(pc),A6		;4d5e: 2c79000001f8
	JSR	(_LVOLoadSeg,A6)	;4d64: 4eaeff6a dos.library (off=-150)
	MOVEA.L	(A7)+,A6		;4d68: 2c5f
	RTS				;4d6a: 4e75

after_narrator
.lmbloop
	btst	#6,$bfe001
	bne.b	.lmbloop
	MOVEA.L	-20(A6),A0		;: 206effec
	JMP	(A0)			;326c: 4e90
    
    
practice_1_loop
	; now we delay once in a while

    movem.l d1/a0,-(a7)
    moveq.l #2,d1
    bsr vbl_reg
   

    movem.l (a7)+,d1/a0
	; original code
	ANDI.L	#$06002800,D0		;: 028006002800
	rts
    
practice_2_loop
	; now we delay once in a while

    movem.l d1/a0,-(a7)
    moveq.l #2,d1
    bsr vbl_reg
   

    movem.l (a7)+,d1/a0
	; original code
	MOVE.B	-7(A6),D0		;: 102EFFF9
	EXT	D0			;2CE96: 4880
    rts


practice_3_loop
	; now we delay once in a while

    movem.l d1/a0,-(a7)
    moveq.l #2,d1
    bsr vbl_reg
   

    movem.l (a7)+,d1/a0
	; original code
 	ANDI.L	#$00000002,D0		;2D626: 028000000002  
    rts
    
mainloop
    
	; original code
	ADDI.L	#$00000020,-12(A6)	;2C432: 06AE00000020FFF4
	; now we delay once in a while

    movem.l d1/a0,-(a7)
    moveq.l #2,d1
    bsr vbl_reg
   

    movem.l (a7)+,d1/a0
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

; < D0: value of D0 in line
; .x: DBF D0,x
emulate_dbf
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

PATCH_EXE:MACRO
	movem.l	d0-d2/d7/a0-a2,-(a7)
	move.l	a0,d7
	subq.l	#4,d7
    lsr.l   #2,d7   ; BCPL
    move.l  d7,a1
	move.l	_resload(pc),a2
	lea	pl_\1(pc),a0
	jsr	resload_PatchSeg(a2)
	movem.l	(a7)+,d0-d2/d7/a0-a2
    ENDM
    
; titles program is called 3 times.
; First time: init
; Second time: protection (and other stuff?)
; Third time: run

patch_titles_1
	move.l	d0,-$14(a6)
	move.l	d0,a0
    PATCH_EXE   titles
	rts

pl_titles
	PL_START
	PL_PSS	$76,emulate_protection,2
	PL_END

emulate_protection
	move.l	#$10,d0
	move.l	d0,8(a6)
	rts

patch_titles_2
	move.l	-$14(a6),a0
	jmp	(a0)

patch_titles_3
	move.l	-$14(a6),a0
	jmp	(a0)

patch_in
	move.l	-$14(a6),a0
	jmp	(a0)

patch_root
	move.l	-28(a6),a0
	movem.l	d0-d2/d7/a0-a2,-(a7)

    sub.l  #10,a0   ; address has an offset (skips the first jump)
    move.l  a0,d7
    lsr.l   #2,d7
    move.l  d7,a1    
	move.l	_resload(pc),a2
	lea	pl_root(pc),a0
	jsr	resload_PatchSeg(a2)
    
    add.l   d7,d7
    add.l   d7,d7
    move.l  d7,$100
    
	movem.l	(a7)+,d0-d2/d7/a0-a2

	jmp	(a0)

; redirected here so we can track game mainloops more easily
infinite_loop:
    ;;move.w  #$0F0,$DFF180
    bra.b   infinite_loop

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
    lea	(segtag,pc),a0
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

_tag		dc.l	WHDLTAG_CUSTOM5_GET
disable_speed_regulation	dc.l	0
    dc.l	WHDLTAG_CUSTOM2_GET
launch_commissioner	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
buttonwait	dc.l	0
		dc.l	0
        
segtag		
        dc.l    WHDLTAG_DBGSEG_SET
segments:
		dc.l	0
		dc.l	0
_dosbase
    dc.l    0


old_level3_interrupt
    dc.l    0

vbl_counter
    dc.w    0
;============================================================================

	END
