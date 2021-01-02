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
	OUTPUT	"FeudalLords.slave"
	IFND	DEBUG
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
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
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

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
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

assign
	dc.b	"DF0",0

slv_name		dc.b	"Feudal Lords"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1991 Impressions",0
slv_info		dc.b	"adapted by JOTD",10,10
        dc.b    "Thanks to jurassicman@eab for icon & original disk",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
    dc.b    "BW;"
    dc.b    "C3:B:skip annoying credits intro"
    dc.b    0
    
loader:
	dc.b	"loader.exe",0
main:
	dc.b	"lords.exe",0
args		dc.b	10
args_end
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

	;load exe
		lea	loader(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_loader(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (BPTR)

COUNTDOWN = $156

patch_loader
    clr.l   COUNTDOWN
    patch   $150,skip_intro_wait
    move.l  d7,a1
    lea pl_loader(pc),a0
	move.l	(_resload,pc),a2
	jsr	resload_PatchSeg(a2)

	rts

pl_loader
	PL_START
    
    PL_IFBW
    PL_PS   $0f24,wait_title
    PL_ENDIF
    PL_IFC3
     ; stupid intro forces player to see credits
    PL_L    $5D8A,$4EB80150
    PL_ENDIF
    PL_PS   $4046,compare_to_53 ; fix programming error
    
    PL_P       $3b80,execute_command_string
    
    PL_PS   $5F10,cache_flush   ; called at start
    PL_END

cache_flush:
	MOVE.L	#$000003e8,D6		;5f10: 2c3c000003e8
    bsr _flushcache
    rts
    

; the loop is very annoying when credits are shown for at least 3 minutes...
; this routine cancels the delay until counter reaches a given value
; at the character selection screen. At this point the delay matters
; else characters aren't selectable (clicks too fast)
skip_intro_wait
    cmp.l   #$481,COUNTDOWN
    bcc.b   .wait
    add.l   #1,COUNTDOWN
    rts
.wait    
	CMP.L	D0,D3			;5d8a: b680
	BPL.S	.back		;5d8c: 6af0
    rts
.back
    sub.l   #$10,(a7)   ; emulates loop back
    rts
    
wait_title:
    move.l  a0,d0
    lea .first_time(pc),a0
    tst.w   (a0)
    beq.b   .out
    clr.w    (a0)
.fire
    btst    #6,$bfe001
    bne.b    .fire
.release
    btst    #6,$bfe001
    beq.b    .release
.out
    move.l  d0,a0
	LEA	-14(A3),A3		;: 47ebfff2
	MOVEQ	#1,D0			;0f28: 7001
    rts
.first_time:
    dc.w    1
 
patch_main
    move.l  d7,a1
    lea pl_main(pc),a0
	move.l	(_resload,pc),a2
	jsr	resload_PatchSeg(a2)
	rts

pl_main
    PL_START
    PL_PS   $1be42,compare_to_53
    PL_PS   $1e508,cache_flush
    PL_END

compare_to_53:
    CMPI.B	#$53,D0
    rts
    
execute_command_string:
    move.l  d1,a0
    lea args(pc),a1
    moveq.l #1,d0
    lea patch_main(pc),a5
    bsr load_exe
    ; not reached
    bra _quit
    
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

    IFD CHIP_ONLY
    move.l  d7,d0
    add.l   d0,d0
    add.l   d0,d0
    addq.l  #4,d0
    move.l  d0,$120.w   ; first segment
    ENDC
    
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
		dc.l	0

;============================================================================

	END
