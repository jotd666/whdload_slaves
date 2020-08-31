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
	OUTPUT	"KingsQuest.Slave"
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
FASTMEMSIZE	= $50000
NUMDRIVES	= 1
WPDRIVES	= %1111

DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH

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
		dc.w	0			;ws_CurrentDir
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

_name		dc.b	"King's Quest",0
_copy		dc.b	"1986 Sierra",0
_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Thanks to Tony Aksnes for disk image",10,10
		dc.b	"Version 1.1 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	bsr	_patch_boot

		move.l	a0,a2
		move.l	#WCPUF_Exp_WT,d0
		move.l	#WCPUF_Exp,d1
	;	jsr	(resload_SetCPU,a2)
		move.l	a2,a0

	;initialize kickstart and environment
		bra	_boot

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a0
	cmp.b	#6,(a0)
	bne.b	.skip

	; sierra found

	move.l	d1,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1

	bsr	_patch_segment_1
	bsr	_patchkb

.skip
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


_patch_boot:
	movem.l	d0-a6,-(a7)
	move.l	a0,a2		; resload
	moveq.l	#4,d0		; offset
	moveq.l	#$10,d1		; size
	moveq.l	#1,d2
	move.l	_expmem(pc),a0
	jsr	resload_DiskLoad(a2)
	move.l	_expmem(pc),a0
	cmp.l	#'Viru',$C(a0)	; byte bandit virus found
	beq.b	.reinstall
	cmp.w	#'DO',(a0)
	beq.b	.reinstall
	bra.b	.ok

.reinstall
	; original disk is not bootable: we have to fix that

	moveq.l	#0,d1		; offset
	move.l	#$400,d0	; size
	lea	.disk1name(pc),a0
	lea	.sierraboot(pc),a1
	jsr	resload_SaveFileOffset(a2)

.ok
	movem.l	(a7)+,d0-a6
	rts

.disk1name:
	dc.b	"disk.1",0
	even
.sierraboot:
	incbin	"sierraboot.bin"


_patch_segment_1:
	move.l	_resload(pc),a2
	move.l	a1,-(a7)
	add.l	#$348-$628,a1
	lea	_pl_org2crk(pc),a0	; "original" crack useless now that we used
	jsr	resload_Patch(a2)	; diff method to crack the game and avoid
	move.l	(a7)+,a1		; disk access completely

	lea	$30(a1),a2
	pea	_decryption(pc)
	bsr	_save_and_patch
	addq.l	#4,A7

	bsr	_patchintuition
	rts

_patchintuition:
	lea	.intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	move.l	a6,a0
	add.w	#_LVOCloseScreen+2,a0
	pea	_quit(pc)
	move.l	(a7)+,(a0)
	
	rts

.intname:
	dc.b	"intuition.library",0
	even

_quit
		PEA	TDREASON_OK
		MOVE.L	_resload(PC),-(A7)
		add.l	#resload_Abort,(a7)
		rts

_decryption:
.loop
	move.w	(a0)+,d0
	eor.w	d0,(a1)+
	subq.l	#1,d1
	cmp.w	#$23B,d1	; value-1
	beq.b	.notzone
	cmp.w	#$23A,d1	; value-2
	beq.b	.restore
	cmp.w	#$FFFF,d1
	bne.b	.loop
	
	addq.l	#2,(A7)		; skip rest of DBF

	move.l	A2,-(A7)
	move.l	4(A7),A2	; return address
	add.l	#$110,a2
	pea	_decryption_2(pc)
	bsr	_save_and_patch
	addq.l	#4,A7
	move.l	(A7)+,A2
	bsr	_flushcache
	rts


.notzone
	add.l	#$47C,(A7)	; do some special stuff
	rts

.restore
	; restore original code (or else there will be cyclic errors)

	move.l	A2,-(A7)
	move.l	4(A7),A2
	bsr	_restore_org
	move.l	(A7)+,A2
	bra.b	.loop

_decryption_2:
	move.l	A2,-(A7)
	move.l	4(A7),A2
	bsr	_restore_org
	move.l	(A7)+,A2

	SUBQ	#1,D4
.LAB_0000:
	MOVE	(A0)+,D1
	MOVEQ	#15,D5
.LAB_0001:
	MOVEQ	#0,D2
	LSL	#1,D1
	ROXR	#1,D2
	EOR	D2,D0
	LSL	#1,D0
	BCC.S	.LAB_0002
	EOR	D3,D0
.LAB_0002:
	DBF	D5,.LAB_0001
	DBF	D4,.LAB_0000

	; ----RTS----

	MOVE	#$015B,D2
.LAB_0003:
	MOVE	(A0)+,D1
	ADD	D0,D1
	EOR	D1,(A0)
	DBF	D2,.LAB_0003

	bsr	_fix1
	; skip disk code
	add.l	#$A8+$1AC+$CE,(a7)
	rts


_pl_org2crk:
        PL_START
        PL_W    $628,$514f
        PL_W    $62a,$5ab8
        PL_W    $646,$b3ad
        PL_W    $648,$6ebf
        PL_W    $64a,$aee8
        PL_W    $660,$3145
        PL_W    $662,$6fb5
        PL_W    $67e,$182e
        PL_W    $680,$fe73
        PL_W    $682,$5ee4
        PL_END

; < A2: return address

_save_and_patch:
	move.l	A3,-(A7)
	lea	_last_saved(pc),a3
	move.l	(A2),(A3)+
	move.w	4(A2),(A3)
	move.l	(A7)+,A3

	move.w	#$4EB9,(A2)+
	move.l	4(A7),(A2)
	bsr	_flushcache
	rts

; < A2: return address

_restore_org:
	nop
	subq.l	#6,A2
	move.l	_last_saved(pc),(a2)+
	move.w	_last_saved+4(pc),(a2)+
	bsr	_flushcache
	rts

_last_saved:
	dc.l	0,0

_fix1:
	movem.l	D0-D1/A0-A2,-(A7)
	move.l	_resload(pc),a2
	move.l	A4,a1
	sub.l	#$17488,a1
	lea	_pl_diskprot(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,D0-D1/A0-A2
	RTS

_pl_diskprot:
	PL_START
	PL_W	$17488,$0002
	PL_W	$1748a,$a500
	PL_W	$1748e,$0710
	PL_W	$174c0,$0002
	PL_W	$174c2,$a500
	PL_W	$174c6,$06d8
	PL_W	$174e8,$0001
	PL_W	$174ea,$7590
	PL_W	$174f0,$0700
	PL_W	$174fc,$ffff
	PL_W	$174fe,$ffff
	PL_W	$17500,$ffff
	PL_W	$17502,$ffff
	PL_W	$17504,$8009
	PL_W	$17510,$0002
	PL_W	$17512,$a500
	PL_W	$1751a,$0001
	PL_W	$1808c,$1f73
	PL_W	$180b6,$4eae
	PL_W	$180b8,$feda
	PL_W	$180ba,$2840
	PL_W	$180bc,$4aac
	PL_W	$180be,$00ac
	PL_W	$180c0,$6700
	PL_W	$180c2,$00a8
	PL_W	$180c4,$6100
	PL_W	$180c6,$016c
	PL_W	$180c8,$206c
	PL_W	$180ca,$00ac
	PL_W	$180cc,$d1c8
	PL_W	$180ce,$d1c8
	PL_W	$180d0,$2068
	PL_W	$180d2,$0010
	PL_W	$180d4,$d1c8
	PL_W	$180d6,$d1c8
	PL_W	$180d8,$48e7
	PL_W	$180da,$2030
	PL_W	$180dc,$45f9
	PL_W	$180ea,$7000
	PL_W	$180ec,$1018
	PL_W	$180ee,$26ca
	PL_W	$180f0,$6002
	PL_W	$180f2,$14d8
	PL_W	$180f4,$51c8
	PL_W	$180f6,$fffc
	PL_W	$180f8,$421a
	PL_W	$180fa,$2039
	PL_W	$18108,$5380
	PL_W	$1810a,$6f1e
	PL_W	$1810c,$0c01
	PL_W	$1810e,$0020
	PL_W	$18110,$6ff4
	PL_W	$18112,$5282
	PL_W	$18114,$26ca
	PL_W	$18116,$600a
	PL_W	$18118,$1218
	PL_W	$1811a,$5380
	PL_W	$1811c,$0c01
	PL_W	$1811e,$0020
	PL_W	$18120,$6f04
	PL_W	$18122,$14c1
	PL_W	$18124,$60f2
	PL_W	$18126,$421a
	PL_W	$18128,$60dc
	PL_W	$1812a,$421a
	PL_W	$1812c,$429b
	PL_W	$1812e,$2002
	PL_W	$18130,$4cdf
	PL_W	$18132,$0c04
	PL_W	$18134,$4879
	PL_W	$1816a,$6100
	PL_W	$1816c,$00c6
	PL_W	$1816e,$6100
	PL_W	$18170,$00b0
	PL_W	$18172,$23c0
	PL_W	$1817a,$2f00
	PL_W	$1817c,$2440
	PL_W	$1817e,$202a
	PL_W	$18180,$0024
	PL_W	$18182,$6710
	PL_W	$18184,$2c79
	PL_W	$1818c,$2228
	PL_W	$1818e,$0000
	PL_W	$18190,$4eae
	PL_W	$18192,$ff82
	PL_W	$18194,$222a
	PL_W	$18196,$0020
	PL_W	$18198,$6728
	PL_W	$1819a,$243c
	PL_W	$1819c,$0000
	PL_W	$1819e,$03ed
	PL_W	$181a0,$4eae
	PL_W	$181a2,$ffe2
	PL_W	$181a4,$23c0
	PL_W	$181b8,$e588
	PL_W	$181ba,$2040
	PL_W	$181bc,$2968
	PL_W	$181be,$0008
	PL_W	$181c0,$00a4
	PL_W	$181c2,$4eb9
	PL_W	$181ca,$6004
	PL_W	$181cc,$202f
	PL_W	$181ce,$0004
	PL_W	$181d0,$2e79
	PL_W	$181d8,$2c79
	PL_W	$181da,$0000
	PL_W	$181dc,$0004
	PL_W	$181de,$2039
	PL_W	$181e6,$2240
	PL_W	$181e8,$4eae
	PL_W	$181ea,$fe62
	PL_W	$181ec,$4ab9
	PL_W	$18200,$fe86
	PL_W	$18202,$201f
	PL_W	$18204,$4e75
	PL_W	$18206,$48e7
	PL_W	$18208,$0106
	PL_W	$1820a,$2e3c
	PL_W	$1820c,$0003
	PL_W	$1820e,$8007
	PL_W	$18210,$2c78
	PL_W	$18212,$0004
	PL_W	$18214,$4eae
	PL_W	$18216,$ff94
	PL_W	$18218,$4cdf
	PL_W	$1821a,$6080
	PL_W	$1821c,$7064
	PL_W	$1821e,$60b0
	PL_W	$18220,$41ec
	PL_W	$18222,$005c
	PL_W	$18224,$4eae
	PL_W	$18226,$fe80
	PL_W	$18228,$41ec
	PL_W	$1822a,$005c
	PL_W	$1822c,$4eae
	PL_W	$1822e,$fe8c
	PL_W	$18230,$4e75
	PL_W	$18232,$42b9
	PL_W	$18240,$0000
	PL_W	$18242,$001e
	PL_W	$18244,$4eae
	PL_W	$18246,$fdd8
	PL_W	$18248,$23c0
	PL_END

;============================================================================

	INCLUDE	kick13.s

;============================================================================

	END

