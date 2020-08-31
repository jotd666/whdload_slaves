	incdir	include:
	include	whdload.i
	include	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	Indy500.slave

	DOSCMD	"WDate  >T:date"

	ENDC

pushall:MACRO
	movem.l	d0-a6,-(A7)
	ENDM

pullall:MACRO
	movem.l	(a7)+,d0-a6
	ENDM

CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000

;--- power to the people

_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	11					; ws_version
	dc.w	WHDLF_EmulTrap|WHDLF_Disk|WHDLF_NoError	; ws_flags
	dc.l	CHIPMEMSIZE					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	_slave-_base				; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
	dc.b	0					; ws_keydebug
	dc.b	$5a					; ws_keyexit [numl]
_expmem:
	dc.l	FASTMEMSIZE
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

_name		dc.b	"Indianapolis 500",0
_copy		dc.b	"1990 Papyrus Design Group",0
_info		dc.b	"installed & fixed by Dark Angel & JOTD",10
		dc.b	"Version 2.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0

		even



;--- bootblock

_slave	lea	_resload(pc),a1
	move.l	a0,(a1)

	lea	_expmem(pc),a0
	tst.l	(a0)
	bne.b	.skip
	move.l	#$80000,(a0)
.skip

	;enable cache
	move.l	_resload(pc),a2
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	moveq	#0,d0
	move.l	#19*$1600,d1
	sub.l	a0,a0
	moveq	#1,d2
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)

	patch	$b0be,.load1
	patchs	$a2a6,.part1
	move.w	#$6004,$A054		; skip fastmem masking
	lea	$dff000,a4
	lea	$bfe001,a5
	lea	$bfd000,a6
	move.l	_expmem(pc),d6			; start ext. mem

	move.l	#CHIPMEMSIZE,d7			; largest mem avail

	move	#$1373,0.w

	bsr	_flushcache
;	LEA	CHIPMEMSIZE-$20,A7
	jmp	$a040
;---

.part1	move.b	$ab7e,d3			; original

	pushall
	move.l	_expmem(pc),a1
	move.l	_resload(pc),a2
	lea	.pl_part1(pc),a0
	jsr	resload_Patch(a2)
	pullall
	rts


;--- disk routines

.load1	pushall

	move	$ab80,d0
	mulu	#512,d0
	move.l	#$1600,d1
	moveq	#1,d2
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)

	pullall
	rts
;---

.load2	pushall

	mulu	#512,d0
	mulu	#512,d1
	moveq	#1,d2
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)

	pullall
	rts
;---

.saver	pushall

	lea	(a0),a1
	lea	disk1(pc),a0
	exg.l	d0,d1
	mulu	#512,d0
	mulu	#512,d1
	move.l	_resload(pc),a6
	jsr	resload_SaveFileOffset(a6)

	pullall
	rts

.pl_part1
	PL_START
	PL_W	$341c6,$4E71			; crack manual protection
	PL_P	$36084,.load2
	PL_P	$360c4,.saver
	PL_END

_flushcache:	move.l	(_resload,pc),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

;--------------------------------
_resload	dc.l	0	;	=
;--------------------------------

;--- file names

disk1	dc.b	'Disk.1',0
