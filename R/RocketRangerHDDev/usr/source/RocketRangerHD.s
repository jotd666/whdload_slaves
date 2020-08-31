;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	hardware/custom.i
	

	IFD BARFLY
	OUTPUT	"RocketRanger.Slave"
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
FASTMEMSIZE	= $80000
NUMDRIVES	= 2
WPDRIVES	= %1111

DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
SETPATCH
CBDOSLOADSEG
HRTMON

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick13.s

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.5-B"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_CurrentDir
	dc.b	0
slv_name		dc.b	"Rocket Ranger",0
slv_copy		dc.b	"1987-1990 Cinemaware",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Hold TAB during game for fuel codes",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
	EVEN

;============================================================================


	;initialize kickstart and environment

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
;;	move.l	_expmem(pc),$100.W
		bsr	_patch_kb
		bsr	_patch_vbl

		add.l	D1,D1		
		add.l	D1,D1	
		addq.l	#4,d1	

		lsl.l	#2,d0
		move.l	d0,a0
		cmp.l	#$02525200,(A0)
		bne.b	.norr

		move.l	_resload(pc),a2
		move.l	#WCPUF_Exp_NC,d0
		move.l	#WCPUF_Exp,d1
;;		jsr	(resload_SetCPU,a2)

		rts

.norr
		; skip program

		move.l	D1,A0
		move.l	#$70004E75,(A0)
		rts

PLANESIZE=80*265
SCREENSIZE=PLANESIZE
COPPERLIST_SIZE=$50

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


_patch_vbl
	movem.l	D0/D1/A0/A1/A2/A6,-(A7)

	move.l	$6C.W,D0
	lea	_vbl_routine(pc),A0
	cmp.l	D0,A0
	beq.b	.patched

	move.l	$4.W,A6
	lea	_gfxname(pc),a1
	moveq	#0,D0
	JSR	_LVOOpenLibrary(A6)
	lea	_gfxbase(pc),A0
	move.l	D0,(A0)

	move.l	#MEMF_CHIP|MEMF_CLEAR,D1
	move.l	#SCREENSIZE+COPPERLIST_SIZE,D0
	JSR	_LVOAllocMem(A6)
	tst.l	D0
	beq.b	.patched

	lea	_screenbuf(pc),a0
	move.l	D0,(a0)

	move.l	D0,A1
	add.l	#COPPERLIST_SIZE,D0
	move.l	D0,A2
	
	move.w	#diwstrt,(a1)+
	move.w	#$581,(a1)+
	move.w	#diwstop,(a1)+
	move.w	#$29A1,(a1)+
	move.w	#color+2,(A1)+
	move.w	#$0,(A1)+
	move.l	#$2001FF00,(A1)+
	move.w	#bplcon0,(A1)+
	move.w	#$9200,(A1)+
	move.w	#color,(A1)+
	move.w	#$0,(A1)+
	move.w	#color+2,(A1)+
	move.w	#$EE3,(A1)+
	move.w	#bplpt,(A1)+
	swap	D0		; LSW
	move.w	D0,(A1)+
	swap	D0		; MSW
	move.w	#bplpt+2,(A1)+
	move.w	D0,(A1)+
	move.l	#$FFFFFFFE,(A1)+


	lea	.codesraw(pc),a0
	move.l	a2,a1
	move.l	_resload(pc),A2
	jsr	resload_LoadFile(a2)

	lea	_vbl_routine(pc),A0
	lea	_oldvbl(pc),A1
	move.l	$6C.W,(A1)
	move.l	A0,$6C.W
.patched:
	movem.l	(A7)+,D0/D1/A0/A1/A2/A6
	rts

.codesraw:
	dc.b	"codes640265.raw",0
	even

_kb_routine:
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

_vbl_routine:
;	move.l	_oldvbl(pc),-(A7)
;	rts

	movem.l	D0,-(A7)
	move.w	$DFF01E,D0
	and.w	#$20,D0
	beq.b	.novbl

	move.b	$bfec01,d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	#$42,d0
	bne.b	.nocode
	move.w	SR,-(A7)
	move.w	#$2700,SR
	bsr	.toggle	
	move.w	(A7)+,SR
.nocode
.novbl:
	movem.l	(A7)+,D0
	move.l	_oldvbl(pc),-(A7)
	rts

.toggle:
	bsr	_ack_kb
	move.w	#8,$DFF01E

	movem.l	D0-A6,-(A7)

	move.w	$DFF000+dmaconr,D0
	move.l	D0,-(A7)
	move.w	#$2F,$DFF000+dmacon	; stop sprite+sound

	move.l	_screenbuf(pc),D0
	move.l	D0,$DFF080
;;;;	move.w	#0,$DFF088

.wait1
	move.b	$bfec01,d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	#$C2,d0
	bne.b	.wait1

	bsr	_ack_kb

	move.l	_gfxbase(pc),A0
	move.l	$26(A0),$DFF080
;;;;	move.w	#0,$DFF088

	move.l	(A7)+,D0
	or.w	#$8000,D0
	move.w	D0,dmacon+$dff000

	movem.l	(A7)+,D0-A6
	rts

_oldkb:
	dc.l	0
_oldvbl:
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

_quit
	PEA	TDREASON_OK
	MOVE.L	_resload(PC),-(A7)
	add.l	#resload_Abort,(a7)
	rts


saveaddr:
	dc.l	0

_screenbuf:
	dc.l	0
_gfxbase:
	dc.l	0

_gfxname:
	dc.b	"graphics.library",0
	even

;============================================================================

	END
