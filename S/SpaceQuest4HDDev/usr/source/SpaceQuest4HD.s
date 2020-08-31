;*---------------------------------------------------------------------------
;  :Program.	SpaceQuestEnhancedHD.asm
;  :Contents.	Slave for "SpaceQuestEnhanced"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SpaceQuest5HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"SpaceQuest4.slave"
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
;CHIPMEMSIZE	= $140000
;FASTMEMSIZE	= $0000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
;DOSASSIGN
;DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 20000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 4500
CBDOSLOADSEG

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_name		dc.b	"Space Quest IV",0
slv_copy		dc.b	"1991 Sierra",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
			dc.b	"Thanks to BTTR for disk images",10,10
			dc.b	"Version 1.1 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
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

	; remove protection

	moveq	#7,d2
	bsr	_get_section
	pea	_crack_it(pc)
	add.l	#$AA2-$944,a0
	move.w	#$4EB9,(a0)+
	move.l	(a7)+,(a0)+

	; avoid access fault

	move.l	#23,d2
	bsr	_get_section
	
	add.l	#$7D0-$294,a0
	move.w	#$4EB9,(a0)+
	pea	_check_a0(pc)
	move.l	(a7)+,(a0)

	;enable cache
	move.l	_resload(pc),a2
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	bsr	_patch_kb
	bra.b	.outcb
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

_crack_it
	ADDQ.L	#1,-4(A5)		;06AA2: 52ADFFFC

	movem.l	d0,-(a7)
	move.l	a0,d0
	btst	#0,d0
	bne.b	.out

	cmp.l	#'Prot',-$14C(a0)
	bne.b	.out

	; replace current code by correct code

	move.l	10(a0),(a0)
.out
	movem.l	(a7)+,d0
	TST.B	(A0)			;06AA6: 4A10
	rts

_copy_savedir
	movem.l	a1,-(a7)
	move.l	(8,A7),a1	; dest
	cmp.l	(12,A7),a1	; source
	beq.b	.skip

	move.l	#'SYS:',(a1)+
	move.l	#'save',(a1)+
	move.b	#0,(a1)+

	bsr	_patchintuition
.skip
	movem.l	(a7)+,a1

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




_patch_kb
	movem.l	D0/D1/A0/A1/A2/A6,-(A7)

	move.l	$68.W,D0
	lea	_kb_routine(pc),A0
	cmp.l	D0,A0
	beq.b	.patched

	lea	_oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
.patched:
	movem.l	(A7)+,D0/D1/A0/A1/A2/A6
	rts


_kb_routine:
	bsr	_ack_kb
	move.l	_oldkb(pc),-(A7)
	rts


_ack_kb:
	movem.l	D0,-(A7)
	bset	#6,$BFEE01
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	rts

_oldkb:
	dc.l	0

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
