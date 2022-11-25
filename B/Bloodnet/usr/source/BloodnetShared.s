
_patch_dos
	move.l	a6,a0
	add.w	#_LVOOpen+2,a0
	lea	_open_save(pc),a1
	move.l	(a0),(a1)
	lea	_openfile(pc),a1
	move.l	a1,(a0)

	move.l	a6,a0
	add.w	#_LVOLock+2,a0
	lea	_lock_save(pc),a1
	move.l	(a0),(a1)
	lea	_lockfile(pc),a1
	move.l	a1,(a0)

	bsr	_flushcache
	rts


_openfile:
	cmp.l	#MODE_NEWFILE,D2
	bne.b	.skip	
	move.l	d1,a0
	bsr	_rework_path
.skip
	move.l	_open_save(pc),-(a7)
	rts

_lockfile:
;	move.l	d1,a0
;	bsr	_rework_path
	move.l	_lock_save(pc),-(a7)
	rts

; workaround for change directory/parent bug with KickEmu
; game first changes dir to 'save', then to '/' but there must be
; a bug in the write routine of kickemu and WHDLoad tries to save the
; file in "save/save" directory.
; no problems with load feature since it uses absolute name via assign
; (Bloodnet_SG/save)

_rework_path
	lea	(a0),a1
	bsr	_get_long

	cmp.l	#'save',d0
	beq.b	.try2
	cmp.l	#'Save',d0
	bne.b	.skip
.try2
	lea	4(a0),a1
	bsr	_get_long
	cmp.l	#'/gam',d0
	bne.b	.skip
.save
	lea	(a0),a1
	move.l	a2,-(a7)
	lea	5(a1),a2
.copy
	move.l	(a2)+,(a1)+
	bne.b	.copy
	move.l	(a7)+,a2

	; about to write: about to OS swap
.skip
	rts

; < a1
; > d0

_get_long
	move.b	(a1)+,d0
	rol.l	#8,d0
	move.b	(a1)+,d0
	rol.l	#8,d0
	move.b	(a1)+,d0
	rol.l	#8,d0
	move.b	(a1)+,d0
	rts

_open_save:
	dc.l	0
_lock_save
	dc.l	0

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	jsr	(a5)
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

