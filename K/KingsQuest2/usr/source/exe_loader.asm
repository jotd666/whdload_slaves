	INCDIR	Include:
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i

; this was used to freeze the game just before startup
; so we could trace the program on a real A500 setup (more compatible)
; without whdload and grab the 16-bit key + decrypt buffer by putting
; memwatches at first segment + $4F0 something (where the code is partially
; encrypted, means around offset $00516 of first segment)

start:
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
        lea exe(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
        bsr load_exe
        moveq.l #0,d0
        rts
        


load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)

	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found


.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
    blitz
    nop
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

	;remove exe

	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)
.end
	movem.l	(a7)+,d0-a6
	rts


_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
args		dc.b	10
args_end
	dc.b	0
       
_dosname
    dc.b    "dos.library",0
exe
    dc.b    "sierra",0
 