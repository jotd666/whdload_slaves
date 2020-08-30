;============================================================================

	INCLUDE	kick31.s
	INCLUDE	kickcd32.s

;============================================================================

	IFD	DUMMY_CD_DEVICE
CDDEVICE_ID = $CDDECDDE

	INCLUDE	cddevice.s

PATCH_IO:MACRO
	move.l	$4.W,a0
	add.w	#_LVO\1+2,a0
	lea	.\1_save\@(pc),a1
	move.l	(a0),(a1)
	lea	.\1\@(pc),a1
	move.l	a1,(a0)
	bra.b	.cont\@
.\1_save\@:
	dc.l	0
.\1\@:
	cmp.l	#CDDEVICE_ID,IO_DEVICE(a1)
	beq	cddevice_\1

	move.l	.\1_save\@(pc),-(A7)
	rts
.cont\@
	ENDM
	ENDC



_patch_cd32_libs:
	movem.l	D0-A6,-(A7)

	;redirect calls: openlib/oldopenlib/closelib/opendevice/closedevice

	move.l	4.W,a0
	add.w	#_LVOOpenLibrary+2,a0
	lea	_openlib_save(pc),a1
	move.l	(a0),(a1)
	lea	_openlib(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOOldOpenLibrary+2,a0
	lea	_oldopenlib_save(pc),a1
	move.l	(a0),(a1)
	lea	_oldopenlib(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOCloseLibrary+2,a0
	lea	_closelib_save(pc),a1
	move.l	(a0),(a1)
	lea	_closelib(pc),a1
	move.l	a1,(a0)
	
	IFND	USE_DISK_NONVOLATILE_LIB
	movem.l	D1-A6,-(A7)
	bsr	_nonvolatile_init	; call nonvolatile.s init (new Bert version)
	movem.l	(A7)+,D1-A6
	ENDC
	
	IFD	DUMMY_CD_DEVICE

	move.l	4.W,a0
	add.w	#_LVOOpenDevice+2,a0
	lea	_opendev_save(pc),a1
	move.l	(a0),(a1)
	lea	_opendev(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOCloseDevice+2,a0
	lea	_closedev_save(pc),a1
	move.l	(a0),(a1)
	lea	_closedev(pc),a1
	move.l	a1,(a0)

	PATCH_IO	DoIO
	PATCH_IO	SendIO
	PATCH_IO	CheckIO
	PATCH_IO	WaitIO
	PATCH_IO	AbortIO

	ENDC

	bsr	_flushcache

	movem.l	(A7)+,D0-A6
	rts

	IFD	DUMMY_CD_DEVICE

_closedev:
	move.l	IO_DEVICE(a1),D0
	cmp.l	#CDDEVICE_ID,D0
	beq.b	.out

.org
	move.l	_closedev_save(pc),-(a7)
	rts

.out
	moveq	#0,D0
	rts

_opendev:
	movem.l	D0,-(a7)
	bsr	.get_long
	cmp.l	#'cd.d',D0
	beq.b	.cddevice
	bra.b	.org

	; cdtv device
.cddevice
	move.l	#CDDEVICE_ID,IO_DEVICE(a1)
.exit
	movem.l	(A7)+,D0
	moveq.l	#0,D0
	rts

.org
	movem.l	(A7)+,D0
	move.l	_opendev_save(pc),-(a7)
	rts

; < A0: address
; > D0: longword
.get_long
	move.l	a0,-(a7)
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	move.l	(a7)+,a0
	rts
_opendev_save:
	dc.l	0
_closedev_save:
	dc.l	0
	ENDC

; 68000 compliant way to get a long at any address
; < A0: address
; > D0: longword
get_long_a1
	move.l	a1,-(a7)
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	move.l	(a7)+,a1
	rts
	
_oldopenlib
	moveq	#0,D0
_openlib
		movem.l	D2/D3,-(a7)
		move.l	A1,D2		; save A1 (name)
		move.l	D0,D3		; save D0 (version required)
		bsr	get_long_a1		; 4 first lib letters in D0
		
		IFND	USE_DISK_LOWLEVEL_LIB
		cmp.l	#"lowl",d0
		bne	.skiplowl

		movem.l	D1-A6,-(A7)
		bsr	LOWLINIT		; call dos.s init
		movem.l	(A7)+,D1-A6
		bra.b	.quit
.skiplowl
		ENDC

		cmp.l	#"free",d0
		bne	.skipfree

		movem.l	D1-A6,-(A7)
		bsr	FRANINIT		; call freeanim.s init
		movem.l	(A7)+,D1-A6
		bra.b	.quit
.skipfree
;		IFND	USE_DISK_NONVOLATILE_LIB
;		cmp.l	#"nonv",d0
;		bne	.skipnonv

;		movem.l	D1-A6,-(A7)
;		bsr	NONVINIT		; call nonvolatile.s init (old version)
;		bsr	_nonvolatile_init	; call nonvolatile.s init (new Bert version)
;		movem.l	(A7)+,D1-A6
;		bra.b	.quit
;.skipnonv
;		ENDC

		move.l	d3,d0	; restore D0
		pea	.cont(pc)
		move.l	_openlib_save(pc),-(a7)
		rts
.cont:
		tst.l	D0
		bne	.ok		; opened from ROM/RAM without trouble
	
		IFND	IGNORE_OPENLIB_FAILURE
		tst.l	D0
		bne.b	.ok

		pea	1.W
		move.l	D2,-(A7)
		pea	TDREASON_OSEMUFAIL
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
		ENDC
.ok
.quit
		movem.l	(A7)+,D2/D3
		tst.l	D0
		rts




_closelib	
		IFND	USE_DISK_LOWLEVEL_LIB
		move.l	_lowlbase(pc),D0
		cmp.l	A1,D0		; lowlevellib ?	
		beq.b	.fake
		ENDC

		move.l	_franbase(pc),D0
		cmp.l	A1,D0		; freeanimlib ?	
		beq.b	.fake
		move.l	_nonvbase(pc),D0
		cmp.l	A1,D0		; nonvolatilelib ?	
		bne.b	.org
.fake
		moveq	#0,D0		; close doslib does nothing!
		rts

.org		move.l	_closelib_save(pc),-(a7)
		rts


;-----------------------------------------------
; IN:	D0 = ULONG size of jmp table
;	D1 = ULONG size of variable area
;	A0 = CPTR  subsystem name
; OUT:	D0 = APTR  librarybase

_InitLibrary	movem.l	d0-d1/a0,-(a7)
		add.l	d1,d0
		move.l	#MEMF_CLEAR,d1
		bsr	ForeignAllocMem
		move.l	d0,a0			;jmp table start
                move.l	d0,a1
		add.l	(a7),a1			;jmp table end

		lea	_LVOFail(pc),a2
.1		move.w	#$4EB9,(A0)+
		move.l	a2,(a0)+
		cmp.l	a0,a1
		bhi	.1
		move.l	(8,a7),-4(a0)		;name of library
		move.l	a0,(A7)			;library base
		move.l	a0,a1			;variables start
		add.l	(4,a7),a1		;variables end
.2		move.w	#$eeee,(a0)+
		cmp.l	a0,a1
		bhi	.2

		MOVEM.L	(A7)+,D0/D1/A0
		rts

MYRTZ:
	moveq.l	#0,D0
	rts

_dosbase:
	dc.l	0


ForeignCacheFlush:
	bra	_flushcache

ForeignAllocMem:
	move.l	A6,-(A7)
	move.l	$4.W,A6
	JSRLIB	AllocMem
	move.l	(A7)+,A6
	RTS

ForeignFreeMem:
	move.l	A6,-(A7)
	move.l	$4.W,A6
	JSRLIB	FreeMem
	move.l	(A7)+,A6
	RTS

_LVOFail
		exg.l	d0,a6
		sub.l	d0,(a7)			;LVO
		exg.l	d0,a6
		subq.l	#6,(a7)
		move.l	(-4,a6),-(a7)		;name of library
_emufail
		pea	TDREASON_OSEMUFAIL
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

_openlib_save
	dc.l	0
_oldopenlib_save
	dc.l	0
_closelib_save
	dc.l	0

