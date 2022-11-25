	INCDIR	"Include:"
	INCLUDE	whdload.i

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
_config
		dc.b	"BW;"
		dc.b	0
		
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
		
DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_name		dc.b	"Crossbow",0
_copy		dc.b	"1989 Screen 7",0
_info		dc.b	"installed & fixed by Bored Seal",10
			dc.b	"68000/010 support by JOTD",10,10
			dc.b	"Version "
		DECL_VERSION
		dc.b	0
		
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
		even

_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2
                lea     (_tags,pc),a0
                jsr     (resload_Control,a2)

		lea	savedisk(pc),a0
                jsr     (resload_GetFileSize,a2)
		tst.l	d0
		bne	boot

		lea	savedisk(pc),a0		;create savedisk
		suba.l	a1,a1
		move.l	#$23c00,d0
		jsr	(resload_SaveFile,a2)

boot		moveq	#0,d3
		moveq	#$16,d1
		move.l	#$80,d2
		lea	$5000,a0
		bsr	LoadRNCTracks

		move.l	a0,a5
		move.l	d2,d0
		mulu.w	#$200,d0
		jsr	resload_CRC16(a2)
		cmp.w	#$631c,d0
		bne	Unsupported

		move.w	#$4ef9,$eff6
		pea	LoadRNCTracks(pc)
		move.l	(sp)+,$eff8

		move.w	#$4ef9,$b220
		pea	ButtonWait(pc)
		move.l	(sp)+,$b222

		pea	PatchGame(pc)
		move.l	(sp)+,$54(a5)
		bsr	_flushcache

		jmp	(a5)


_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
	
PatchGame	move.w	#$4eb9,$8236
		pea	InsertDisk(pc)
		move.l	(sp)+,$8238
		move.b	#$60,$831e
		
		pea	kbtest(pc)
		move.w	#$4eb9,$2006.W
		move.l	(sp)+,$2008.W
		bsr	_flushcache
		jmp	$1e00

kbtest:
	move.b	d2,$214A.W
	cmp.b	_keyexit(pc),d2
	bne.b	.noquit
	pea	TDREASON_OK
	move.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)	
.noquit
	rts
	
; get long, 68000/68010 friendly
; < A0: address
; > D1: longword
get_long
	move.b	(a0)+,D1
	lsl.l	#8,D1
	move.b	(a0)+,D1
	lsl.l	#8,D1
	move.b	(a0)+,D1
	lsl.l	#8,D1
	move.b	(a0)+,D1
	rts

	
InsertDisk
		bsr	get_long
		lea	disknum(pc),a0
		cmp.l	#'GAME',d1
		bne	savetest
		move.w	#1,(a0)
		bra	Inserted
savetest	cmp.l	#'SAVE',d1
		bne	Inserted
		move.w	#2,(a0)
Inserted	move.l	#$11d,d1
		rts

ButtonWait	movem.l	d0-d7/a0-a6,-(sp)
		lea	button(pc),a0
		tst.l	(a0)
		beq	ButtonPressed
		lea	$bfe001,a0
test		btst	#6,(a0)
		beq	ButtonPressed
		btst	#7,(a0)
		bne	test
ButtonPressed	movem.l	(sp)+,d0-d7/a0-a6
		rts

LoadRNCTracks	movem.l a0-a2/d0-d3,-(sp)
		mulu.w	#$200,d1
		mulu.w	#$200,d2
		move.l	d1,d0
		move.l	d2,d1
		cmp.w	#1,d3
		beq	Save
		lea	disknum(pc),a1
		move.w	(a1),d2
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)
		movem.l (sp)+,a0-a2/d0-d3
		clr.l	d0
		rts

Save		exg.l	d0,d1
		move.l	a0,a1
                lea     savedisk(pc),a0
                move.l  (_resload,pc),a2
		jsr	(resload_SaveFileOffset,a2)
Return		movem.l (sp)+,a0-a2/d0-d3
		moveq	#0,d0
		rts

Unsupported	pea	TDREASON_WRONGVER
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_resload	dc.l	0
disknum		dc.w	1
_tags		dc.l	WHDLTAG_BUTTONWAIT_GET
button		dc.l	0,0
savedisk	dc.b	"Disk.2",0