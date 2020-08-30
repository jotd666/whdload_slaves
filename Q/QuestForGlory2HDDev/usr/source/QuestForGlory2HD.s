;*---------------------------------------------------------------------------
;  :Program.	QuestForGlory2HD.asm
;  :Contents.	Slave for "QuestForGlory2"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: QuestForGlory2HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	dos/dosextens.i

	IFD BARFLY
	OUTPUT	"QuestForGlory2.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

; setting chipmem too low results in shitty chip tune sound
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $100000

NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 25000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
CACHE
STACKSIZE = 8000
CBDOSLOADSEG

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s


;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_name		dc.b	"Quest For Glory 2 - Trial by Fire",0
slv_copy		dc.b	"1990 Sierra",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Thanks to BTTR for disk images",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

;============================================================================

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
	cmp.b	#'X',1(a0)
	beq.b	.skip_lan
	cmp.b	#'p',1(a0)
	bne.b	.skip_prog
	
	; prog

	move.w	#0,d2
	bsr	get_section

	movem.l	D0-D1/A0-A2,-(A7)
	move.l	_resload(pc),a2
	move.l	A0,A1
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,D0-D1/A0-A2
	
	bra.b	.out

.skip_prog
	moveq	#0,d0
	move.b	(a0),d0
	lea	(a0,d0.w),a3
	cmp.b	#'v',(a3)
	bne.b	.out
	cmp.b	#'r',-1(a3)
	bne	.out

	; sound driver patch
	IFEQ	1
	move.l	#$2C762000,d0
	move.l	d1,a0
	add.l	#$4+$1A9E,a0
	cmp.l	(a0),d0
	beq.b	.patchsnd

	bra.b	.nosnd
.patchsnd
	move.l	#$4E714EB9,(a0)+
	pea	patch_sound(pc)
	move.l	(a7)+,(a0)
	bra.b	.out
.nosnd
	ENDC
.out
	rts
.skip_lan
	move.l	d1,a0
	move.l	#$70004E75,4(a0)
	rts


; < d1 seglist
; < d2 section #
; > a0 segment
get_section
	move.l	d1,a0
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a0),a0
	add.l	a0,a0
	add.l	a0,a0
	dbf	d2,.loop
.out
	addq.l	#4,a0
	rts

patch_sound
	movem.l	D0,-(a7)
	MOVE.L	$00(A6,D2.W),D0
	move.l	d0,a6
	and.l	#$F00FFFFE,d0
	movem.l	(a7)+,d0
	beq.b	.skip		; 0xx00001-type address: write access fault
	MOVE.W	#$0000,(A6)
.skip
	RTS

pl_main
	PL_START
	PL_PS	$2DCC,copy_savedir
	PL_PS	$1E742,quit
	PL_END

copy_savedir
	movem.l	a1,-(a7)
	move.l	(8,A7),a1	; dest
	move.l	#'SYS:',(a1)+
	move.l	#'save',(a1)+
	move.b	#0,(a1)+
	movem.l	(a7)+,a1
	rts


	
quit
		pea	TDREASON_OK
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

wrong_version:
		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

	END
