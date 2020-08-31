; Generic Sierra harddisk patches
; used in:
; - Codename: Iceman
; - Conquests of Camelot
; - Colonel's Bequest
; - Leisure Suit Larry 2
; - Leisure Suit Larry 3
; - Quest For Glory
; - ManHunter

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/intuition.i
	INCLUDE	lvo/dos.i
	INCLUDE	dos/dos.i

HDINIT
NUMDRIVES	= 1
WPDRIVES	= %0000
CBDOSLOADSEG


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick13.s

;============================================================================


slv_CurrentDir
	dc.b	"data",0
	even

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	; skip Kixx intro program

	cmp.b	#'X',1(a0)
	beq.b	.skip_xlan

	lea	.prog(pc),a1
	move.l	a0,a3
.cmpstr
	move.b	(a1)+,d2
	beq.b	.ok
	cmp.b	(a3)+,d2
	beq.b	.cmpstr

	IFD	MAINPROG
	lea	_mainprog(pc),a1
	move.l	a0,a3
.cmpstr2
	move.b	(a1)+,d2
	beq.b	.ok
	cmp.b	(a3)+,d2
	beq.b	.cmpstr2
	ENDC
	bra.b	.skip_prog

	; prog

.ok
	move.w	#0,d2
	bsr	_get_section
	cmp.w	#$4EF9,(a0)
	bne.b	.skip_prog	; Pixie frontend loaded instead of main interpreter

	movem.l	d1-a6,-(a7)
	bsr	_specific_patch
	movem.l	(a7)+,D1-a6
	tst.l	d0
	bne.b	.nootherpatches

	bsr	_generic_patches

.nootherpatches
.skip_prog
	; sound driver patch

	IFD	PATCH_SOUND

	cmp.b	#$C,(a0)
	bne.b	.out

	; sound driver patch: 2 offsets possible depending
	; on amigasnd.drv version

	move.l	#$20290010,d0
	move.l	d1,a0
	add.l	#$4+$18C4,a0
	cmp.l	(a0),d0
	beq.b	.patchsnd

	move.l	d1,a0
	add.l	#$4+$18D6,a0
	cmp.l	(a0),d0
	bne.b	.nosnd
.patchsnd
	move.l	#$4E714EB9,(a0)+
	pea	_patch_sound(pc)
	move.l	(a7)+,(a0)
	bra	.out
.nosnd
	ENDC

.out
	rts


.skip_xlan
	move.w	#0,d2
	bsr	_get_section
	move.l	#$70004E75,(a0)
	rts

.prog:
	dc.b	4,"prog",0
	even

	IFD	PATCH_SOUND
_patch_sound:
	cmp.l	#CHIPMEMSIZE,A1
	bcs.b	.ok
	cmp.l	_expmem(pc),a1
	bcc.b	.ok

	; address problem: MSB has been tampered with
	; restore it

	; MSB from 1 to 5
	
	move.l	a1,d0
	ror.l	#8,d0
	cmp.b	#5,d0
	bcc.b	.restore_msb	

	clr.b	d0
	rol.l	#8,d0
	bra.b	.out

.restore_msb
	; MSB completely broken

	move.l	a1,d0
	move.l	d1,-(a7)
	move.b	_expmem(pc),d1
	ror.l	#8,d1
	or.l	d1,d0
	move.l	(a7)+,d1
.out
	move.l	d0,a1
.ok
	MOVE.L	$0010(A1),D0
	MOVE.L	D0,$0008(A0)
	rts
	ENDC

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

; < D1: seglist APTR

_generic_patches:
	; section 3

	move.w	#3,d2
	bsr	_get_section

	; close stuff: quit

	add.l	#$216,a0
	cmp.l	#$48E760E2,(a0)
	beq.b	.pq
	add.l	#$28-$16,a0
	cmp.l	#$48E760E2,(a0)
	beq.b	.pq
	bra.b	.spq
.pq
	move.w	#$4EF9,(a0)+
	pea	_quit(pc)
	move.l	(a7)+,(a0)
.spq
	; section 11: savedisk/unlock bug

	move.l	#11,d2
	bsr	_get_section
	add.l	#$37A,a0
	move.l	#$4E714EB9,(a0)+
	pea	_savedrive(pc)
	move.l	(a7)+,(a0)

	move.l	#11,d2
	bsr	_get_section
	add.l	#$368,a0
	move.w	#$600A,(a0)	; skip unlock of root dir: crashes kickemu in dos mode

	; no more dos.DeleteFile (avoids os swaps)

	movem.l	d0-d1/a0-a2/a6,-(a7)
	lea	.dosname(pc),a1
	move.l	$4.W,a6
	jsr	_LVOOldOpenLibrary(a6)
	
	move.l	d0,a0
	add.w	#_LVODeleteFile,a0
	move.w	#$4EF9,(a0)+
	lea	_deletefile(pc),a1
	move.l	a1,(a0)

	; enable caches

	move.l	_resload(pc),a2
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	movem.l	(a7)+,d0-d1/a0-a2/a6

	rts


.dosname
	dc.b	"dos.library",0
	even

_deletefile:
	moveq.l	#-1,D0
	rts

_savedrive:
	move.l	a0,-(A7)
	move.l	(8,a5),a1
	lea	.s(pc),a0
.copy
	move.b	(a0)+,(a1)+
	bne.b	.copy
	move.l	(a7)+,a0
	rts

.s:
	dc.b	"SYS:save",0
	even
	
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

	IFEQ	1
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
	ENDC

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0
