	INCDIR	"Include:"
	INCLUDE	whdload.i
	IFD BARFLY
	OUTPUT	"Dominator.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_dir-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
		dc.l	0
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
;---
	dc.w	slv_config-_base
	
slv_config:
        dc.b    "C1:X:trainer - infinite lives:0;"
		dc.b	0
		
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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

_dir		dc.b	"data",0
_name		dc.b	"Dominator",0
_copy		dc.b	"1989 System 3",0
_info		dc.b	"adapted by Bored Seal & JOTD",10
		dc.b 	"Version "
		DECL_VERSION
		dc.b	0
		even
		
_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2
		lea     (_tags,pc),a0
		jsr     (resload_Control,a2)

		lea	filename(pc),a0
		lea	$1dc,a1
		move.l	a1,a5
		jsr	(resload_LoadFile,a2)

		move.l	a5,a0
		jsr     (resload_CRC16,a2)
		cmp.w	#$d7c8,d0
		bne	Unsupported

		move.w	#$4ef9,$438
		pea	LoadFile(pc)
		move.l	(sp)+,$43a
		move.w	#$4e75,$42e		;disk access

		move.l	#$4e714eb9,d0
		move.l	d0,$5bac
		move.l	d0,$5cd0
		pea	BeamDelay(pc)
		move.l	(sp),$5bb0
		move.l	(sp)+,$5cd4

		move.l	#$7670cf6b,$24		;copylock

		move.w	#$4eb9,$33b4
		pea	FaultFix1(pc)
		move.l	(sp)+,$33b6

		move.w	#$4eb9,$123e
		pea	FaultFix2(pc)
		move.l	(sp)+,$1240

		move.w	#$4eb9,$12b2
		pea	FaultFix3(pc)
		move.l	(sp)+,$12b4

		move.w	#$4ef9,$20a4
		pea	Quit(pc)
		move.l	(sp)+,$20a6

		move.w	#$4ef9,$550e
		pea	SaveHi(pc)
		move.l	(sp)+,$5510

		move.w	#$4EB9,$59A2
		pea	kb_ack(pc)
		move.l	(sp)+,$59A4
		
		bsr	LoadHi

		lea	trainer(pc),a6
		tst.l	(a6)
		beq	NoTrainer
		move.w	#$6006,$4b82		;unlimited lives
;		move.w	#$ffff,$54b4		;invincibility

NoTrainer	lea	$10,a6			;set empty copperlist
		lea	$dff000,a0
		move.l	#$fffffffe,(a6)
		move.l	a6,$80(a0)
		move.w	#$83d0,$96(a0)
		move.w	#$e000,$9a(a0)
		bsr _flushcache
		jmp	$200.W

LoadHi		movem.l	d0-d7/a0-a6,-(sp)
		bsr	Params
                jsr     (resload_GetFileSize,a2)
                tst.l   d0
                beq     NoHisc
		bsr	Params
		jsr	(resload_LoadFile,a2)
NoHisc		movem.l	(sp)+,d0-d7/a0-a6
		rts

Params		lea	hiscore(pc),a0
		lea	$5f5e,a1
		move.l	(_resload,pc),a2
		rts

SaveHi		jsr	$5514
		movem.l	d0-d7/a0-a6,-(sp)
		bsr	Params
		moveq	#$3c,d0
		jsr	(resload_SaveFile,a2)
		movem.l	(sp)+,d0-d7/a0-a6
		rts

Quit		btst	#6,$bfe001
		bne	OK
		bra	_exit
OK		rts

FaultFix1	tst.w	d0
		beq	Nothing
		subq.w	#1,d0
		mulu.w	#8,d0
Nothing		rts

FaultFix2	tst.w	d1
		bpl	Nothing2
		clr.w	d1
Nothing2	mulu.w	#$200,d1
		ror.l	#4,d0
		rts

FaultFix3	tst.w	d1
		bpl	Nothing3
		clr.w	d1		
Nothing3	mulu.w	#$200,d1
		lsr.l	#4,d0
		rts

LoadFile	movem.l a0-a2/d1,-(sp)
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFile,a2)
		movem.l	(sp)+,a0-a2/d1
		rts

BeamDelay	move.l  d0,-(sp)
		moveq	#8,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0
BM_2		cmp.b	$dff006,d0
		beq	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
End		move.l	(sp)+,d0
		rts

kb_ack:
	move.b	$BFEC01,d0
	not.b	d0
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	beq		quit
kb_delay:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
	rts

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
Unsupported	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_exit		pea	TDREASON_OK
		bra	_end

_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0
		dc.l	0
filename	dc.b	"d.img",0
hiscore		dc.b	"Dominator.High",0