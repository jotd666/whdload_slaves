;*---------------------------------------------------------------------------
;  :Program.	FoolsErrandHD.asm
;  :Contents.	Slave for "FoolsErrand"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: FoolsErrandHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;DEBUG
	IFD BARFLY
	OUTPUT	"FoolsErrand.slave"
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


	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $FF000
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
IOCACHE		= 12000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 50000
BOOTDOS
CACHE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
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
	ENDM

assign_game
	dc.b	"Game_Disk",0
assign_show
	dc.b	"Show_Disk",0

slv_name		dc.b	"Fool's Errand"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1990 Miles Computing",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Set CUSTOM1=1 to skip introduction",10
		dc.b	"Set CUSTOM2=1 to see finale",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

finale
	dc.b	"Finale",0
prologue
	dc.b	"Prologue",0
program:
	dc.b	"Fool",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
		clr.l	$0.W

		clr.l	$100.W	; for finale show

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
		lea	assign_game(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign_show(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		move.l	custom1(pc),d0
		bne.b	.skipintro
		move.l	custom2(pc),d0
		bne.b	.tofinale

		lea	prologue(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_intro(pc),a5
		bsr	load_exe

.skipintro
	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe

		tst.l	$100.W
		beq.b	_quit

.tofinale
		lea	finale(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_finale(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_finale
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_finale(pc),a0
	jsr	resload_Patch(a2)
	rts
	
patch_intro
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_intro(pc),a0
	jsr	resload_Patch(a2)
	rts

patch_main
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)
	rts


pl_finale
	PL_START
	PL_L	$2E,$4E714E71	; don't test Status file
	PL_B	$3C,$60	; always run the finale
	PL_END

pl_intro
	PL_START
	PL_PS	$A16A,fix_af_intro
	PL_END

pl_main
	PL_START

	; any code passes

	PL_B	$1E6AE,$60

	; fix finale files shit

	PL_PS	$1E942,enable_finale

	PL_END

enable_finale
	move.l	#-1,$100.W
	add.l	#$74-$48,(A7)	; skip all the file shit
	rts

fix_af_intro
	cmp.l	#$FFFFFFEE,a0
	bne.b	.ok

	rts

.ok
	and.w	#$7FFF,(8,a0)
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
		blk.l	16,0
_stacksize
		dc.l	0

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
custom2		dc.l	0
		dc.l	0

;============================================================================

	END
