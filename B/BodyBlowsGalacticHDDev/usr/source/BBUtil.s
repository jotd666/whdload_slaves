DISK_1 = $48162937
DISK_2 = $43532741

; --------------------------------------------------------------------

_kbint:
	move.b	$BFEC01,D0
	move.l	D0,-(sp)
	not.b	D0
	ror.b	#1,D0

	cmp.b	_keyexit(pc),D0
	bne	.noquit

	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

.noquit
	move.l	(sp)+,D0
	rts	

_flushcache
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

_decrunch:
	movem.l	D1/A0-A2,-(A7)
	MOVE.L	_resload(PC),A2
	JSR	(resload_Decrunch,a2)
	movem.l	(A7)+,D1/A0-A2
	tst.l	d0
	rts

_wrongver:
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
_read_sectors:
	movem.l	d1-d2/a0-a2,-(A7)

	moveq.l	#0,D0
	cmp.l	#DISK_1,D4
	bne	.disk2

	subq.l	#2,d1
	bra.b	.doload
	
.disk2
	cmp.l	#DISK_2,D4
	bne	.readnothing
	moveq.l	#1,D0
.doload
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
_read_nothing:
	moveq	#0,d0
	rts


_resload:
	dc.l	0
