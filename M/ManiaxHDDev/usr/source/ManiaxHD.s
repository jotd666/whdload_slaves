;*---------------------------------------------------------------------------
;  :Program.	LegendOfFaerghailHD.asm
;  :Contents.	Slave for "LegendOfFaerghail"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: LegendOfFaerghailHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"Maniax.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;DEBUG

	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
;BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
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
STACKSIZE = 8000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_Examine
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


slv_name		dc.b	"Maniax"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1990 Kingsoft",0
slv_info		dc.b	"adapted & fixed by Harry & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config
        dc.b    "C1:X:infinite lives:0;"
        dc.b    "C2:L:Threshold:default,+20%,+50%,+80%,+90%"
		dc.b	0

program:
	dc.b	"maniax",0

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

		move.l	(_resload,pc),a2		;A2 = resload
		lea	tag(pc),a0
		jsr	resload_Control(a2)
		
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		;PATCH_DOSLIB_OFFSET	Open
		;PATCH_DOSLIB_OFFSET	Close
		;PATCH_DOSLIB_OFFSET	Read

		
		;lea	assign_save(pc),a0
		;lea	saves(pc),a1
		;bsr	_dos_assign


		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe

		; wait forever

		move.l	$4,a6
		moveq	#0,d0
		jsr	_LVOWait(a6)
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < A0 filename
; < A6 dosbase

must_exist
	movem.l	d0-d1/a0-a1/a3,-(a7)
	move.l	a0,d1
	move.l	a0,a3
	move.l	#ACCESS_READ,d2
	jsr	_LVOLock(a6)
	move.l	d0,d1
	beq.b	.error
	jsr	_LVOUnLock(a6)
	movem.l	(a7)+,d0-d1/a0-a1/a3
	rts

.error
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
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

patch_main

	move.l	d7,a1
	add.l	#4,a1

	lea	.ttable(pc),a0
	add.l	threshold_idx(pc),a0
	move.b	(a0),$2E3B(a1)		; threshold
	
	lea	pl_main_seg_0(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts

	
;default,+20%,+50%,+80%,+90%
.ttable
	dc.b	75,20,50,80,90
	even
	
pl_main_seg_0
	PL_START
	PL_IFC1
	PL_L	$8E8,1000	; 1000 lives
	PL_R	$45e4	; no hiscore save
	PL_ENDIF
	
	
	PL_W	$3fFF,$44   ;leave keyboardint on
	PL_W	$40DA,$7601	;fix hiscoreprob
	PL_L	$40dc,$4eaeffd6
	PL_L	$40e0,$4a8067e4
	PL_END

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
	lea	_savestack(pc),a4
	move.l	a7,(a4)
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
_savestack
		dc.l	0
tag		dc.l	WHDLTAG_CUSTOM2_GET
threshold_idx	dc.l	0
		dc.l	0
skip_intro
	dc.l	0

;============================================================================

	END
