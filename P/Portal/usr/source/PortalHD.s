;*---------------------------------------------------------------------------
;  :Program.	PortalHD.asm
;  :Contents.	Slave for "Portal"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: PortalHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"Portal.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
;BLACKSCREEN
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 25000
NUMDRIVES	= 3
WPDRIVES	= %1111
CBDOSLOADSEG
DISKSONBOOT

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_name		dc.b	"Portal",0
slv_copy		dc.b	"1986 Activision",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
			dc.b	"Thanks to Tony Aksnes & BTTR for disk images",10,10
			dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

;============================================================================

	;initialize kickstart and environment


; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	
	beq.b	.out
	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	; skip Kixx intro program

	cmp.b	#'t',1(a0)
	beq.b	.gotitle

	cmp.b	#'m',1(a0)
	bne.b	.skip

	; remove protection

	moveq	#2,d2
	bsr	_get_section
	move.b	#$66,$3B4-$228(a0)
	move.w	#$4EF9,$10E8-$228(a0)
	pea	_quit(pc)
	move.l	(a7)+,$10EA-$228(a0)

	move.l	#41,d2
	bsr	_get_section
	move.l	#$70004E75,$EE6-$834(a0)
	rts

.gotitle:
	movem.l	D1,-(a7)
	move.l	_resload(pc),a2

	;get tags
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	;enable cache
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	bsr	_patchkb
	movem.l	(a7)+,d1
	move.l	_custom1(pc),d0
	beq.b	.out

.skip
	; cancel load of program
	move.l	D1,A0
	move.l	#$70004E75,4(a0)
.out
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

_quit
	pea	TDREASON_OK
	MOVE.L	_resload(PC),-(A7)
	add.l	#resload_Abort,(a7)
	rts
	
_patchkb
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
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
