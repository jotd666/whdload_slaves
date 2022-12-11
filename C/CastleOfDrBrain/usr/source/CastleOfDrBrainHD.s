;*---------------------------------------------------------------------------
;  :Program.	KingsQuest5HD.asm
;  :Contents.	Slave for "KingsQuest5"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: KingsQuest5HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"CastleOfDrBrain.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000*2	; stingray: increased to 1MB as otherwise
NUMDRIVES	= 1		; game quits due to lack of memory
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 15000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 7000
CACHE
BOOTEARLY
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
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

slv_name		dc.b	"Castle Of Dr Brain",0
slv_copy		dc.b	"1992 Sierra",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

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

	; prog

	; section 23 - access fault #1, only for dualplay version

	move.w	#23,d2
	bsr	.get_section

	move.l	a0,a1

	add.l	#$7DC-$2A0,a0
	cmp.l	#$0C681234,(a0)
	bne.b	.no2p
	
	lea	pl_s23(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
.no2p
.skip_prog
	rts


; < d1 seglist
; < d2 section #
; > a0 segment
.get_section
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


PATCH_XXXLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1

	ENDM

pl_s23
	PL_START
;	PL_PS	$638-$2A0,check_a0
;	PL_PS	$6D8-$2A0,check_a0
	PL_PS	$7DC-$2A0,check_a0
	PL_END

check_a0:
	cmp.l	#0,a0
	beq.b	.sk
	cmp.w	#$1234,-10(a0)
	rts
.sk
	cmp.l	#1,a0	; wrong test
	rts

_bootearly
	movem.l	D0-A6,-(a7)
	lea	intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	PATCH_XXXLIB_OFFSET	CloseScreen

	bsr	_flushcache	
	movem.l	(a7)+,D0-A6
	rts

intname:
	dc.b	"intuition.library",0
	even

new_CloseScreen
	; first time ok, second time quit
	lea	counter(pc),a1
	move.w	(a1),d0
	cmp.w	#1,d0
	beq	_quit
	add.w	#1,(a1)
	move.l	old_CloseScreen(pc),-(a7)
	rts

counter
	dc.w	0

_quit
		PEA	TDREASON_OK
		MOVE.L	_resload(PC),-(A7)
		add.l	#resload_Abort,(a7)
		rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
