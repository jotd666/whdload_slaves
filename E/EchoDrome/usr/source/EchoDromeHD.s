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
	OUTPUT	"MoonCresta.slave"
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
;CHIP_ONLY

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
;DOSASSIGN
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

	include	whdload/kick13.s

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


slv_name		dc.b	"Echodrome"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"2025 Pixelplop",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"echodrome",0
args		dc.b	10
args_end
	dc.b	0
slv_config
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
        move.l  #$20000-$1BB20,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

    
	;assigns
;		lea	assign(pc),a0
;		sub.l	a1,a1
;		bsr	_dos_assign


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


jump_a1:
	add.l	a1,a1
	add.l	a1,a1
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	lea		pl_prog(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	(a1)

keyboard_hook:
	MOVE.B	$bfee01,D1		;3b7c6: 123900
	move.w	d0,-(a7)
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	movem.w	(a7)+,d0
	bne.b		.1
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)	
.1:
	rts
	
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
	PL_P	$00166,jump_a1
    PL_END
	
	
pl_prog
    PL_START
	; remove VBR access
	PL_W	$1030a,$7000
	PL_NOP	$1030c,6
	PL_PS	$1b7c6,keyboard_hook
	
	; remove winuae debug detection
	PL_NOP	$1e30c,4
	PL_W	$1e310,$7000
	PL_NOP	$1e36a,4
	PL_W	$1e36e,$7000
	PL_NOP	$20c00,4
 	PL_W	$20c04,$7000
   PL_END
    
get_version:
	movem.l	d1/a0/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#125096,D0
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

		dc.l	0
tagseg
        dc.l    WHDLTAG_DBGSEG_SET
segments:
		dc.l	0
		dc.l	0

;============================================================================

	END
