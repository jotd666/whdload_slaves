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
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/intuition.i
	INCLUDE	lvo/dos.i
	INCLUDE	dos/dos.i

	IFD BARFLY
	OUTPUT	"KingsQuest2.Slave"
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
CBDOSLOADSEG
STARTHOOK
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH



BLACKSCREEN

;======================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5d

;============================================================================

	INCLUDE	kick13_mod.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC
	
DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
		
slv_name		dc.b	"King's Quest 2: Romancing the Throne",0
slv_copy		dc.b	"1987 Sierra",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Thanks to Tony Aksnes for disk image",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir
		dc.b	0
	EVEN
	
; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a0
	cmp.b	#6,(a0)
	bne.b	.skip

	bsr	_patchintuition

	; sierra found

	move.l	d1,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1
	move.l	_resload(pc),a2
	move.l	a1,-(a7)
	add.l	#$348-$628,a1
	lea	_pl_org2crk(pc),a0
	jsr	resload_Patch(a2)
	move.l	(a7)+,a1

	lea	$30(a1),a2
	pea	_decryption(pc)
	bsr	_save_and_patch
	addq.l	#4,A7

.skip
	rts

_patchintuition:
	movem.l	d0-d1/a0-a1/a6,-(a7)
	lea	.intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	move.l	a6,a0
	add.w	#_LVOCloseScreen+2,a0
	pea	_quit(pc)
	move.l	(a7)+,(a0)
	movem.l	(a7)+,d0-d1/a0-a1/a6	
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
        PL_W    $628,$126f
        PL_W    $62a,$18ea
        PL_W    $646,$8c9f
        PL_W    $648,$3809
        PL_W    $64a,$5c24
        PL_W    $660,$3115
        PL_W    $662,$50e7
        PL_W    $67e,$9f62
        PL_W    $680,$6b75
        PL_W    $682,$6818
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

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

_hexsearch:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts

_fix1:
	movem.l	D0-D1/A0-A2,-(A7)
	move.l	_resload(pc),a2
	move.l	A4,a1
	lea	_pl_diskprot(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,D0-D1/A0-A2
	RTS

_pl_diskprot:
	PL_START
	PL_W	$0,$0002
	PL_W	$2,$a7b8
	PL_W	$6,$0710
	PL_W	$38,$0002
	PL_W	$3a,$a7b8
	PL_W	$3e,$06d8
	PL_W	$60,$0001
	PL_W	$62,$7590
	PL_W	$68,$0700
	PL_W	$74,$ffff
	PL_W	$76,$ffff
	PL_W	$78,$ffff
	PL_W	$7a,$ffff
	PL_W	$7c,$8009
	PL_W	$88,$0002
	PL_W	$8a,$a7b8
	PL_W	$92,$0001
	PL_W	$c04,$1f73
	PL_W	$c2e,$4eae
	PL_W	$c30,$feda
	PL_W	$c32,$2840
	PL_W	$c34,$4aac
	PL_W	$c36,$00ac
	PL_W	$c38,$6700
	PL_W	$c3a,$00a8
	PL_W	$c3c,$6100
	PL_W	$c3e,$016c
	PL_W	$c40,$206c
	PL_W	$c42,$00ac
	PL_W	$c44,$d1c8
	PL_W	$c46,$d1c8
	PL_W	$c48,$2068
	PL_W	$c4a,$0010
	PL_W	$c4c,$d1c8
	PL_W	$c4e,$d1c8
	PL_W	$c50,$48e7
	PL_W	$c52,$2030
	PL_W	$c54,$45f9
	PL_W	$c62,$7000
	PL_W	$c64,$1018
	PL_W	$c66,$26ca
	PL_W	$c68,$6002
	PL_W	$c6a,$14d8
	PL_W	$c6c,$51c8
	PL_W	$c6e,$fffc
	PL_W	$c70,$421a
	PL_W	$c72,$2039
	PL_W	$c80,$5380
	PL_W	$c82,$6f1e
	PL_W	$c84,$0c01
	PL_W	$c86,$0020
	PL_W	$c88,$6ff4
	PL_W	$c8a,$5282
	PL_W	$c8c,$26ca
	PL_W	$c8e,$600a
	PL_W	$c90,$1218
	PL_W	$c92,$5380
	PL_W	$c94,$0c01
	PL_W	$c96,$0020
	PL_W	$c98,$6f04
	PL_W	$c9a,$14c1
	PL_W	$c9c,$60f2
	PL_W	$c9e,$421a
	PL_W	$ca0,$60dc
	PL_W	$ca2,$421a
	PL_W	$ca4,$429b
	PL_W	$ca6,$2002
	PL_W	$ca8,$4cdf
	PL_W	$caa,$0c04
	PL_W	$cac,$4879
	PL_W	$ce2,$6100
	PL_W	$ce4,$00c6
	PL_W	$ce6,$6100
	PL_W	$ce8,$00b0
	PL_W	$cea,$23c0
	PL_W	$cf2,$2f00
	PL_W	$cf4,$2440
	PL_W	$cf6,$202a
	PL_W	$cf8,$0024
	PL_W	$cfa,$6710
	PL_W	$cfc,$2c79
	PL_W	$d04,$2228
	PL_W	$d06,$0000
	PL_W	$d08,$4eae
	PL_W	$d0a,$ff82
	PL_W	$d0c,$222a
	PL_W	$d0e,$0020
	PL_W	$d10,$6728
	PL_W	$d12,$243c
	PL_W	$d14,$0000
	PL_W	$d16,$03ed
	PL_W	$d18,$4eae
	PL_W	$d1a,$ffe2
	PL_W	$d1c,$23c0
	PL_W	$d30,$e588
	PL_W	$d32,$2040
	PL_W	$d34,$2968
	PL_W	$d36,$0008
	PL_W	$d38,$00a4
	PL_W	$d3a,$4eb9
	PL_W	$d42,$6004
	PL_W	$d44,$202f
	PL_W	$d46,$0004
	PL_W	$d48,$2e79
	PL_W	$d50,$2c79
	PL_W	$d52,$0000
	PL_W	$d54,$0004
	PL_W	$d56,$2039
	PL_W	$d5e,$2240
	PL_W	$d60,$4eae
	PL_W	$d62,$fe62
	PL_W	$d64,$4ab9
	PL_W	$d78,$fe86
	PL_W	$d7a,$201f
	PL_W	$d7c,$4e75
	PL_W	$d7e,$48e7
	PL_W	$d80,$0106
	PL_W	$d82,$2e3c
	PL_W	$d84,$0003
	PL_W	$d86,$8007
	PL_W	$d88,$2c78
	PL_W	$d8a,$0004
	PL_W	$d8c,$4eae
	PL_W	$d8e,$ff94
	PL_W	$d90,$4cdf
	PL_W	$d92,$6080
	PL_W	$d94,$7064
	PL_W	$d96,$60b0
	PL_W	$d98,$41ec
	PL_W	$d9a,$005c
	PL_W	$d9c,$4eae
	PL_W	$d9e,$fe80
	PL_W	$da0,$41ec
	PL_W	$da2,$005c
	PL_W	$da4,$4eae
	PL_W	$da6,$fe8c
	PL_W	$da8,$4e75
	PL_W	$daa,$42b9
	PL_W	$db8,$0000
	PL_W	$dba,$001e
	PL_W	$dbc,$4eae
	PL_W	$dbe,$fdd8
	PL_W	$dc0,$23c0
	PL_END


_starthook:
	movem.l	d0-a6,-(a7)
	move.l	a0,a2		; resload
	moveq.l	#4,d0		; offset
	moveq.l	#$10,d1		; size
	moveq.l	#1,d2
	lea	$10000,a0
	jsr	resload_DiskLoad(a2)
	lea	$10000,a0
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

	END

