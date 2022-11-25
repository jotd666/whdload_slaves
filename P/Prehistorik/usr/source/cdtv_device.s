
PATCH_IO:MACRO
lab_\1
	move.l	$4.W,a0
	add.w	#_LVO\1+2,a0
	lea	.\1_save(pc),a1
	move.l	(a0),(a1)
	lea	.\1(pc),a1
	move.l	a1,(a0)
	bra.b	.cont
.\1_save:
	dc.l	0
.\1:
	lea	_fake_cdtvbase(pc),A0
;	cmp.l	IO_DEVICE(a1),A0
;	beq.b	.ignore
;	cmp.l	#$B0DEB0DE,IO_DEVICE(a1)
;	beq.b	_handle_bookmark
	; ignore (cdtv.device)
.ignore
	moveq.l	#0,D0
	rts
.org
	move.l	.\1_save(pc),-(A7)
	rts
.cont
	ENDM

; to get a longword without caring for alignment (68000)

GETLONG:MACRO
		move.b	(\1),\2
		lsl.l	#8,\2
		move.b	(1,\1),\2
		lsl.l	#8,\2
		move.b	(2,\1),\2
		lsl.l	#8,\2
		move.b	(3,\1),\2
		ENDM
_patch_cdtv:
	move.l	4.W,a0
	add.w	#_LVOOpenDevice+2,a0
	lea	_opendev_save_2(pc),a1
	move.l	(a0),(a1)
	lea	_opendev_2(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOCloseDevice+2,a0
	lea	_closedev_save_2(pc),a1
	move.l	(a0),(a1)
	lea	_closedev_2(pc),a1
	move.l	a1,(a0)

	PATCH_IO	DoIO
	PATCH_IO	SendIO
	PATCH_IO	CheckIO
	PATCH_IO	WaitIO
	PATCH_IO	AbortIO

	rts

_opendev_2:
	movem.l	D0,-(a7)
	GETLONG	A0,D0
	cmp.l	#'cdtv',D0
	beq.b	.cdtv
;	cmp.l	#'book',D0
;	beq.b	.bookmark
	bra.b	.org

	; cdtv device
.cdtv
	pea	_fake_cdtvbase(pc)
	move.l	(A7)+,IO_DEVICE(a1)
.exit
	movem.l	(A7)+,D0
	moveq.l	#0,D0
	rts

.org
	movem.l	(A7)+,D0
	move.l	_opendev_save_2(pc),-(a7)
	rts

_closedev_2:
	move.l	IO_DEVICE(a1),D0
	lea	_fake_cdtvbase(pc),a0
	cmp.l	a0,d0
	beq.b	.out
;	cmp.l	#$B0DEB0DE,D0
;	beq.b	.out

.org
	move.l	_closedev_save_2(pc),-(a7)
	rts

.out
	moveq	#0,D0
	rts

_opendev_save_2:
	dc.l	0
_closedev_save_2:
	dc.l	0

; all functions do nothing

	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
_fake_cdtvbase:
	illegal

	