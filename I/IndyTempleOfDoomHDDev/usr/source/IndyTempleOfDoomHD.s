;*---------------------------------------------------------------------------
;  :Program.	IndyTempleOfDoomHD.asm
;  :Contents.	Slave for "IndyTempleOfDoom"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: IndyTempleOfDoomHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;DEBUG
	IFD BARFLY
	OUTPUT	"IndyTempleOfDoom.slave"
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

; game loop:
;0001F630 d1ad fff8                ADD.L D0,(A5, -$0008) == $00018c84 [ffffff80]
;0001F634 0cad 0000 00c0 fff8      CMP.L #$000000c0,(A5, -$0008) == $00018c84 [ffffff80]

;============================================================================


	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $50000
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

	include	kick13.s

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
	ENDM

assign
	dc.b	"IndyTempleOfDoom",0

slv_name		dc.b	"Indiana Jones and the Temple Of Doom"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1989 Lucasfilm/Atari Games/Mindscape",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
	dc.b    "C1:X:Run as fast as possible:0;"
	dc.b	0

program:
	dc.b	"indy",0
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

		bsr	calibrate_delay_loop
		
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
;		lea	assign(pc),a0
;		sub.l	a1,a1
;		bsr	_dos_assign

	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		sub.l	a5,a5
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)
		
calibrate_delay_loop
	lea	_custom,a2
	move.w	#$4000,(intena,a2)
.vbl
	btst	#5,(intreqr+1,a2)
	beq.b	.vbl
	
	move.w	#$3FFF,(intreq,a2)
	move.l	#0,d0
.loop
	add.l	#1,d0
	btst	#5,(intreqr+1,a2)
	beq.b	.loop
	
	move.w	#$C000,(intena,a2)
	lea	vbl_counter(pc),a2
	; on a real amiga (well rather WinUAE A500 real speed), value is roughly $D37
	move.l	d0,(a2)
	rts

; < d7: seglist (APTR)


patch_main
	lea	pl_section0(pc),a0
	moveq	#0,d2
	bsr	get_section
	jsr	resload_Patch(a2)
	
	; patch only if much faster CPU
	move.l	vbl_counter(pc),d0
	sub.l	#$D38,d0		; value measured with "exact cycle"
	bmi.b	.skip
	lea	pl_section0_slow(pc),a0
	moveq	#0,d2
	bsr	get_section
	jsr	resload_Patch(a2)
	bsr	beamdelay
.skip
	rts
	
pl_section0_slow
	PL_START
	PL_IFC1
	PL_ELSE
	PL_PSS	$03eec,game_loop,2
	PL_ENDIF
	PL_END
pl_section0
	PL_START
	; cpu dependent loop...
	PL_PS	$83A0,delay
	PL_W	$83A6,$4E71
	PL_END
game_loop:
	;;movem.l	D0,-(a7)   ; no need as D0 is a scratch register for this C program
	move.l	vbl_counter(pc),d0
	sub.l	#$D38,d0		; value measured with "exact cycle"
	lsr.l	#8,d0
	lsr.l	#4,d0	; roughly divide by ... a lot until it matches the real speed
	beq.b	.skip
	bsr	beamdelay
.skip
	;;move.l	(a7)+,d0
	CMPI.L	#$000000c0,-8(A5)	;03eec: 0cad000000c0fff8
	rts
	
delay:
	movem.l	d0,-(a7)
	moveq	#2,d0
	bsr	beamdelay
	movem.l	(a7)+,d0
	ADDQ	#1,(-6,A5)		;083A0: 526DFFFA
	ADDQ	#1,(-8,A5)		;083A4: 526DFFF8
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


; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
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

	bsr	update_task_seglist

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

update_task_seglist
	movem.l	d0/a0/a6,-(a7)
	move.l	$4,A6
	sub.l	a1,a1
	jsr	(_LVOFindTask,a6)
	move.l	d0,a0
	move.l	pr_CLI(a0),d0
	asl.l	#2,d0
	move.l	d0,a0

	; store loaded segments in current task

	move.l	d7,cli_Module(a0)

	movem.l	(a7)+,d0/a0/a6
	rts
vbl_counter
	dc.w	0
tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1		dc.l	0
		dc.l	0

;============================================================================

	END
