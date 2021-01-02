;*---------------------------------------------------------------------------
;  :Program.	SpaceQuest3HD.asm
;  :Contents.	Slave for "SpaceQuest3"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SpaceQuest3HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"SpaceQuest3.slave"
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

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $C0000
NUMDRIVES	= 1
WPDRIVES	= %0000

	IFND	DEBUG
BLACKSCREEN
	ELSE
HRTMON
	ENDC

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 45000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
CBDOSLOADSEG

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.2-B"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_name		dc.b	"Space Quest III - The Pirates of Pestulon",0
slv_copy		dc.b	"1989 Sierra",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
			dc.b	"Thanks to BTTR for disk images",10,10
			dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_assign_df0
	dc.b	"DF0",0
	EVEN

;============================================================================

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	move.l	_resload(pc),a2

	add.l	D1,D1		
	add.l	D1,D1	
	move.l	d1,d7

	; now D7 is APTR to seglist

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#'X',1(a0)
	beq	.skip_xlan
	cmp.b	#3,(a0)
	beq.b	.prog1
	cmp.b	#4,(a0)
	beq.b	.prog2
	bra.b	.skip_prog
.prog1
	move.w	#0,d2
	bsr	_get_section
	cmp.w	#$4EF9,(a0)
	bne.b	.skip_prog
.prog2
	; sq3/prog

	move.w	#3,d2
	bsr	_get_section
	; close stuff: quit
	add.l	#$226,a0
	cmp.l	#$48E760E2,(a0)
	bne.b	.noquk
	move.w	#$4EF9,(a0)+
	pea	_quit(pc)
	move.l	(a7)+,(a0)

	; avoid access fault when course is selected

	move.w	#18,d2
	bsr	_get_section
	move.l	a0,a1
	lea	pl_af_uk(pc),a0
	jsr	resload_Patch(a2)
	bra.b	.noqg
.noquk
	; german, quit

	move.w	#0,d2
	bsr	_get_section

	; close stuff: quit
	add.l	#$1EF58,a0
	cmp.l	#$4EAEFF2E,(a0)
	bne.b	.noqg
	move.w	#$4EF9,(a0)+
	pea	_quit(pc)
	move.l	(a7)+,(a0)
.noqg
	; assign for saves

	move.w	#0,d2
	bsr	_get_section
	lea	_prog_start(pc),a1
	move.l	2(a0),(a1)
	pea	_assign_it(pc)
	move.l	(a7)+,2(a0)

.skip_prog
	rts


.skip_xlan
	move.w	#0,d2
	bsr	_get_section
	move.l	#$70004E75,(a0)
	rts

pl_af_uk
	PL_START
	PL_PS	$8422-$7E44,avoid_af
	PL_END


; there is some indirection mixup at some point,
; but this is an harmless access fault, since the game
; manages with it...

avoid_af
	addq.l	#2,(a7)
	movem.l	d0,-(a7)
	move.l	(a0),d0
	cmp.l	#'DEST',d0
	movem.l	(a7)+,d0
	beq.b	.avoid

	; normal operation

	MOVE.L	(A0),-1030(A5)		;08422: 2B50FBFA
	MOVEA.L	-1030(A5),A0		;08426: 206DFBFA
	rts
.avoid
	add.l	#$4C-$2A,(a7)	; skip the rest of the crap
	rts

_quit
		PEA	TDREASON_OK
		MOVE.L	_resload(PC),-(A7)
		add.l	#resload_Abort,(a7)
		rts

_assign_it:
	movem.l	d0-a6,-(a7)
	lea	_dosname(pc),a1
	moveq.l	#0,d0
	move.l	$4.W,a6
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,a6

	lea	_assign_df0(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign

	movem.l	(a7)+,d0-a6

	move.l	_prog_start(pc),-(a7)
	rts

; < d7 seglist
; < d2 section #
; > a0 segment
_get_section
	move.l	d7,a0
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

_prog_start
	dc.l	0
