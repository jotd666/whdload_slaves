;*---------------------------------------------------------------------------
;  :Program.	AlienIIIHD.asm
;  :Contents.	Slave for "AlienIII" from
;  :Author.	JOTD
;  :History.	28.01.05
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	AlienIII.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC


USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Alien III"
		dc.b	0
_copy		dc.b	"1992 Virgin",0
_info		dc.b	"adapted & fixed by Abaddon/JOTD",10,10
		dc.b	"Set CUSTOM1=1 for infinite time",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

BASE_ADDRESS = $78000

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	lea	$7FF00,a7

	; load & version check

	lea	BASE_ADDRESS,A0
	move.l	#$1040,d1	; length
	move.l	#$318c,d0	; offset
	moveq	#1,D2
	bsr	_loaddisk

	lea	pl_boot(pc),a0

	lea	BASE_ADDRESS,A1
	jsr	resload_Patch(a2)
	
	jmp	BASE_ADDRESS+$10


pl_boot
	PL_START
	PL_P	$70c,read_sectors
	PL_P	$9a,jumper
	PL_P	$7000,decrunch
	PL_END

pl_train_time
	PL_START
	; infinite time
	PL_W	$99EC,$4E71
	PL_W	$99F6,$4E71
	PL_NEXT	pl_main
pl_main:
	PL_START
	PL_P	$5eec,load
	PL_PS	$4b28,kb_int
	PL_W	$4AB6,$600E		; floppy led off
	PL_L	$690,$600008ea
	PL_P	$6ff0,swap		; disk swap
	PL_S	$139EC,6		; avoid access fault
	PL_END

jumper:
	bsr		patchblit

	IFD	USE_FASTMEM	
	move.l	_expmem(pc),$4.W
	ELSE
	move.l	#$80000,$4.W
	ENDC

	sub.l	a1,a1
	lea	pl_main(pc),a0
	move.l	_custom1(pc),d0
	beq.b	.skip
	lea	pl_train_time(pc),a0
.skip
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	lea	$77000,a1
	movea.l	(a1)+,a0
	jmp	(a0)



load:
	movem.l	a0,-(a7)
	lea		disknum(pc),a0
	move.l	(a0),d0
	movem.l	(a7)+,a0
	bsr	read_sectors
	rts


blitshit:
	move.l	a3,$54(a0)
	bsr	wait_blit
	move.w	d0,$58(a0)
	rts

wait_blit
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
	rts

patchblit:
	movem.l	d0-a6,-(a7)
	lea		$5000.w,a0
	lea		$5600.w,a1
patch:
	cmpi.l	#$214b0054,(a0)
	bne	nopatch
	cmpi.l	#$31400058,$4(a0)
	bne	nopatch
	move.l	#$4E714EB9,(a0)+
	pea	blitshit(pc)
	move.l	(a7)+,(a0)+
nopatch:
	adda.l	#$2,a0
	cmpa.l	a0,a1
	bne	patch
	movem.l	(a7)+,d0-a6
	rts

swap:
	movem.l	a0,-(a7)
	lea	disknum(pc),a0
	eori.l	#$1,(a0)
	movem.l	(a7)+,a0
	jmp	$7006.w

kb_int:
	cmp.b	_keyexit(pc),D0
	bne		.noquit
	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts	
.noquit
	move.b	$dff006,d0
	rts
disknum:
	dc.l	0


read_sectors
	movem.l	d1-d2/a0-a2,-(A7)

	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.readnothing		; length=0: out

	exg.l	d0,d2
	addq.l	#1,d2	; disk number

	exg.l	d0,d1

	ext.l	d0
	lsl.l	#7,d0
	lsl.l	#2,d0
	ext.l	d1
	lsl.l	#7,d1			;diskoffset
	lsl.l	#2,d1
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)
.readnothing
	movem.l	(a7)+,d1-d2/a0-a2
	moveq	#0,d0
	rts

decrunch
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_Decrunch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	bsr	_flushcache
	rts
	
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_loaddisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

