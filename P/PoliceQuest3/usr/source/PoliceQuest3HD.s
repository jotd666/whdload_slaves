;*---------------------------------------------------------------------------
;  :Program.	PoliceQuest3HD.asm
;  :Contents.	Slave for "PoliceQuest3"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: PoliceQuest3HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"PoliceQuest3.slave"
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
FASTMEMSIZE	= $C0000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
CACHE
;DISKSONBOOT
;DOSASSIGN
;DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 25000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 4500
CBDOSLOADSEG

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s



;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.4"
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
	

slv_name		dc.b	"Police Quest III - The Kindred",0
slv_copy		dc.b	"1992 Sierra",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
			dc.b	"Thanks to BTTR/Hubert Maier for disk images",10,10
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

	; prog

	moveq	#6,d2
	bsr	_get_section
	pea	_copy_savedir(pc)
	move.l	(a7)+,$1548-$BF0(a0)	; 64FA

	; avoid access fault

	move.l	#23,d2
	bsr	_get_section
	
	add.l	#$7D0-$294,a0
	move.w	#$4EB9,(a0)+
	pea	_check_a0(pc)
	move.l	(a7)+,(a0)

.skip_prog
.outcb
	rts

_check_a0:
	cmp.l	#0,a0
	beq.b	.sk
	cmp.w	#$1234,-10(a0)
	rts
.sk
	cmp.l	#1,a0	; wrong test
	rts

; < d1 seglist
; < d2 section #
; > a0 segment
_get_section
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


_wrong_version:
		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

_copy_savedir
	movem.l	d0/a0,-(a7)
	move.l	(12,A7),a0	; dest
	cmp.l	(16,A7),a0	; source
	beq.b	.skip

	move.l	#'SYS:',d0
	bsr	set_long
	addq.l	#4,a0
	move.l	#'save',d0
	bsr	set_long
	move.b	#0,4(a0)

	bsr	_patchintuition
.skip
	movem.l	(a7)+,d0/a0

	rts

; < A0: address
; < D0: longword
set_long
	movem.l	d0,-(a7)
	move.b	d0,3(a0)
	lsr.l	#8,d0
	move.b	d0,2(a0)
	lsr.l	#8,d0
	move.b	d0,1(a0)
	lsr.l	#8,d0
	move.b	d0,(a0)
	movem.l	(a7)+,d0
	rts

_patchintuition:
	movem.l	D0-A6,-(a7)
	lea	.intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	move.l	a6,a0
	add.w	#_LVOCloseScreen+2,a0
	pea	_quit(pc)
	move.l	(a7)+,(a0)
	
	movem.l	(a7)+,D0-A6
	rts

.intname:
	dc.b	"intuition.library",0
	even

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
