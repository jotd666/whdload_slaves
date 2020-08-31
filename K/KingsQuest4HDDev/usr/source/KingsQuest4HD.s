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
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"KingsQuest4.Slave"
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
NUMDRIVES	= 4
WPDRIVES	= %1111

DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
SETPATCH

;============================================================================

KICKSIZE	= $40000		;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	11			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

_data		dc.b	"data",0
_name		dc.b	"King's Quest 4",0
_copy		dc.b	"1990 Sierra",0
_info		dc.b	"Adapted & fixed by JOTD",10,10
		dc.b	"Thanks to Icy[ool & BTTR for disk images",10,10
		dc.b	"Version 1.1 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		move.l	a0,a2
	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
		move.l	a2,a0

	;initialize kickstart and environment
		bra	_boot


; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	


	move.l	_expmem(pc),a0
	add.l	#$3568C,a0
	cmp.w	#$1630,(a0)
	bne.b	.skiprom
	move.w	#$4EB9,(a0)+
	pea	_patch_endcli(pc)
	move.l	(a7)+,(a0)+

.skiprom
	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#4,(a0)
	bne.b	.skip_prog
	; prog

	; section 3

	move.w	#3,d2
	bsr	.get_section

	; close stuff: quit

	add.l	#$216,a0
	move.w	#$4EF9,(a0)+
	pea	_quit(pc)
	move.l	(a7)+,(a0)

	; section 22, BTTR crack specific

	move.w	#18,d2
	bsr	.get_section

	lea	$1C88-$30C(a0),a1
	cmp.l	#$4EB80100,(a1)
	bne.b	.nobttr

	patch	$100,_patch_prot_bttr
	bra	.prog_out

.nobttr
	; section 35

	move.w	#35,d2
	bsr	.get_section

	lea	$216(a0),a1
	cmp.l	#$226C97CC,(a1)
	bne.b	.not_v1

	move.l	#-$6834,d0
	bra.b	.vcommon

.not_v1
	cmp.l	#$226C97FC,(a1)
	bne.b	.not_v2

	move.l	#-$6804,d0

.vcommon
	; activate protection replayer

	move.l	#$4E714EB9,(a1)+
	pea	_patch_prot(pc)
	move.l	(a7)+,(a1)

	; store protection variable offset

	lea	_variable_offset(pc),a1
	move.l	d0,(a1)

.prog_out
	; in case the game reboots...

	lea	_prot_counter(pc),a1
	clr.l	(a1)

	bsr	_patchkb
	rts

.skip_prog
	cmp.b	#$C,(a0)
	bne.b	.nosnd
	move.l	d1,a0
	add.l	#$4+$1498,a0
	cmp.l	#$22B62020,(a0)
	bne.b	.nosnd

	move.l	d1,a0
	add.l	#$4+$14AA,a0
	move.w	#$4EB9,(a0)+
	pea	_patch_sound(pc)
	move.l	(a7)+,(a0)

.nosnd
	cmp.b	#7,(a0)
	bne.b	.return
	; cracker program
	move.l	d1,a0
	move.l	#$70004E75,4(a0)
.return
	rts

.not_v2:
	bra	_wrong_version

; < d1 seglist
; < d1 section #
; > a0 segment
.get_section
	move.l	d1,a0
	subq	#1,d2
.loop
	move.l	(a0),a0
	add.l	a0,a0
	add.l	a0,a0
	dbf	d2,.loop
	addq.l	#4,a0
	rts

_patch_endcli:
	moveq	#0,d3
	tst.l	D2
	bmi.b	.out
	MOVE.B	0(A0,D2.L),D3		;3568C: 16302800	; EndCLI access fault
.out
	MOVE.L	D3,D1			;35690: 2203
	rts

_patch_sound:
	movem.l	D0,-(a7)
	move.b	$8(a1),d0
	cmp.b	_expmem(pc),d0
	movem.l	(a7)+,d0
	beq.b	.skip
	MOVE.B	$0020(A6),$0008(A1)
.skip
	rts

_af_address:
	dc.l	0

_wrong_version:
		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

_quit
		PEA	TDREASON_OK
		MOVE.L	_resload(PC),-(A7)
		add.l	#resload_Abort,(a7)
		rts


_patchkb
	IFEQ	KICKSIZE-$40000

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
	ELSE
	rts
	ENDC


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0


_patch_prot:
	lea	_prot_counter(pc),a1
	addq.l	#1,(a1)
	cmp.l	#$1E,(A1)
	bne	.org

	; at this point, the user just pressed RETURN
	; at the protection check
	; "replay" of page 4 word 7 third paragraph

	lea	-$e4a(a3),a1

	move.w	#$013c,$cdc(a1)	; password configuration
	move.l	#'with',$cde(a1)
	move.w	#0,$ce2(a1)
.org
	move.l	d0,-(a7)
	move.l	_variable_offset(pc),d0
	move.l	(a4,d0.L),a1
	move.l	(a7)+,d0
	move.w	(2,a1),(a3)
	rts
_prot_counter
	dc.l	0

_variable_offset:
	dc.l	0

_patch_prot_bttr:
	movem.l	d1/a1,-(a7)
	lea	_prot_counter(pc),a1
	move.l	#-26636,d1
	tst.l	(a1)
	bne.b	.skip
	clr	(a4,d1.l)
	move.l	#1,(a1)
	bra.b	.out
.skip
	move.w	d0,(a4,d1.l)
.out
	movem.l	(a7)+,d1/a1
	rts

;============================================================================

	IFEQ	KICKSIZE-$40000
	INCLUDE	kick13.s
	ELSE
	INCLUDE	kick31.s
	ENDC

;============================================================================

	END

