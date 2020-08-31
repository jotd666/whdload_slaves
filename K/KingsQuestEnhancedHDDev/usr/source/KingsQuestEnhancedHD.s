;*---------------------------------------------------------------------------
;  :Program.	KingQuestEnhancedHD.asm
;  :Contents.	Slave for "KingQuestEnhanced"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: KingQuestEnhancedHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/intuition.i

;DEBUG
	IFD BARFLY
	OUTPUT	"KingsQuestEnhanced.slave"
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
;DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 6000
;;BOOTDOS
CACHE
CBDOSLOADSEG

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.1-B"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM
program:
	dc.b	"kq1",0
args		dc.b	10
args_end
	dc.b	0

slv_name		dc.b	"Kings Quest I: Quest For The Crown (Enhanced)"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1990 Sierra",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	move.l	d0,a0
	add.l	a0,a0
	add.l	a0,a0
	cmp.b	#4,(a0)
	bne.b	.skip_prog

	; prog

	; section 0

	move.l	d1,d7
	moveq	#0,d2
	bsr	get_section
	lea	pl_section_0(pc),A0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)

	bra.b	.outcb
.skip_prog
	cmp.b	#'s',3(a0)
	bne.b	.skip_stack
	move.l	d1,a0
	move.l	#$70004E75,4(a0)	; cancels stack command
.skip_stack
.outcb
	rts

pl_section_0
	PL_START
	PL_PS	$3092,copy_savedir
	PL_PS	$1ED78,delay_loop
	PL_END


delay_loop:
	movem.l	D0,-(a7)
	move.l	#$1000,D0
	bsr	beamdelay
	movem.l	(A7)+,d0
	addq.l	#$8,(a7)
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


copy_savedir
	movem.l	a1,-(a7)
	move.l	(8,A7),a1	; dest
	move.l	#'SYS:',(a1)+
	move.l	#'save',(a1)+
	move.b	#0,(a1)+
	movem.l	(a7)+,a1

	bsr	_patchintuition
	bsr	_flushcache

	rts


_patchintuition:
	movem.l	D0-A6,-(a7)
	lea	.intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	; patch to avoid crash when quitting: close screen quits whdload cleanly
	move.l	a6,a0
	add.w	#_LVOCloseScreen+2,a0
	pea	quit(pc)
	move.l	(a7)+,(a0)
	movem.l	(a7)+,D0-A6
	rts

.intname:
	dc.b	"intuition.library",0
	even


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

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1		dc.l	0
		dc.l	0

;============================================================================

	END
