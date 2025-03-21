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
	OUTPUT	"Boppin.slave"
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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

assign
	dc.b	"jff",0

slv_name		dc.b	"Black Dawn II"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1994 Andrew Campbell",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"DAWNII",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	;dc.b    "C1:X:Trainer Infinite lives:0;"
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
    cmp.l   #2,d0
    beq.b   .original
	lea	pl_boot(pc),a0
.original    
    IFD    CHIP_ONLY
    move.l  d7,a1
    add.l  a1,a1
    add.l  a1,a1
    addq.l  #4,a1
    move.l  a1,$100.W
    ENDC
    
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)
.skip
	rts

; for cranked, ross fixed version uses cranker
pl_boot
	PL_START
    PL_NOP  $144,4
    PL_P    $158,do_jump

	PL_END

JFF_LABEL = $4A46463A       ; "JFF:"

; apply on SEGMENTS
pl_main
    PL_START
    ; apply ross fix: string on even address
    PL_B    $7f4+3,$4a
    ; shift string
    PL_L    $B40,"Icon"
    PL_L    $B44,"s   "
;    PL_DATA $b40,8
;	DC.b	"Icons   "

    
    ; all this shite just to be able to save to hard drive
    
    ; first df0/df1 hardcoded assigns
    PL_L    $24790-$10,JFF_LABEL
    PL_L    $24796-$10,JFF_LABEL
    PL_L    $247e6-$10,JFF_LABEL
    PL_L    $247f6-$10,JFF_LABEL
    PL_L    $247fc-$10,JFF_LABEL
    PL_L    $24802-$10,JFF_LABEL
    PL_L    $24808-$10,JFF_LABEL
    PL_L    $24818-$10,JFF_LABEL
    PL_L    $2481e-$10,JFF_LABEL
    PL_L    $24824-$10,JFF_LABEL

    ; then direct access to drives 0 and 1 using CIAs
    
    PL_NOP  $21fe0,4    ; no write to cia (select drive 0)
    PL_DATA $21fee,4
    moveq.l #-1,d3
    nop                 ; not write protected

    PL_NOP  $2203e,4
    PL_DATA $2204c,4
    moveq.l #-1,d3
    nop                 ; not write protected

    
    PL_NOP  $22606,4    ; no write to cia (select drive 0)
    PL_DATA $22614,4
    moveq.l #-1,d3
    nop                 ; disk change bit
    
    PL_NOP  $226ae,4    ; no write to cia (select drive 0)
    PL_DATA $226bc,4
    moveq.l #-1,d3
    nop                 ; disk change bit
    
    PL_END
    
pl_main_ross:
	PL_START
    
    ; all this shite just to be able to save to hard drive
    
    ; first df0/df1 hardcoded assigns
    PL_L    $24790,JFF_LABEL
    PL_L    $24796,JFF_LABEL
    PL_L    $247e6,JFF_LABEL
    PL_L    $247f6,JFF_LABEL
    PL_L    $247fc,JFF_LABEL
    PL_L    $24802,JFF_LABEL
    PL_L    $24808,JFF_LABEL
    PL_L    $24818,JFF_LABEL
    PL_L    $2481e,JFF_LABEL
    PL_L    $24824,JFF_LABEL

    ; then direct access to drives 0 and 1 using CIAs
    
    PL_NOP  $21ff0,4    ; no write to cia (select drive 0)
    PL_DATA $21ffe,4
    moveq.l #-1,d3
    nop                 ; not write protected

    PL_NOP  $2204e,4
    PL_DATA $2205c,4
    moveq.l #-1,d3
    nop                 ; not write protected

    
    PL_NOP  $22616,4    ; no write to cia (select drive 0)
    PL_DATA $22624,4
    moveq.l #-1,d3
    nop                 ; disk change bit
    
    PL_NOP  $226be,4    ; no write to cia (select drive 0)
    PL_DATA $226cc,4
    moveq.l #-1,d3
    nop                 ; disk change bit
 
	PL_END


do_jump
	ADDQ.L	#1,A1			;00158: 5289
	ADDA.L	A1,A1			;0015a: d3c9
	ADDA.L	A1,A1			;0015c: d3c9
    movem.l A1,-(a7)
	lea	pl_main_ross(pc),a0
    move.l  _resload(pc),a2
	jsr	resload_Patch(a2)
    movem.l (a7)+,A1
    
	JMP	(A1)			;0015e: 4ed1
    

    
get_version:
	movem.l	d1/a0/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#$1ABAC,D0
	beq.b	.ross

    cmp.l   #232476,d0
    beq.b   .original
    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.ross
	moveq	#1,d0
    bra.b   .out
.original
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
