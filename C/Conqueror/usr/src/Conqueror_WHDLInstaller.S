	incdir	gore:asm/include/
	include	whdload.i


;--- power to the people

j	slave_header				; ws_security + ws_id
	dc.w	5				; ws_version
	dc.w	whdlf_emultrap|whdlf_noerror	; ws_flags
	dc.l	$80000				; ws_basememsize
	dc.l	0				; ws_execinstall
	dc.w	.game-j				; ws_gameloader
	dc.w	0				; ws_currentdir
	dc.w	0				; ws_dontcache
	dc.b	0				; ws_keydebug
	dc.b	0				; ws_keyexit


;--- version id

	dc.b	'$VER: Conqueror HD by Dark Angel V1.1 [22/04/98]',0
	even


;--- read and save bootblock

.game	lea	whdbase(pc),a1
	move.l	a0,(a1)

	moveq	#0,d0
	move.l	#512*2,d1
	lea	$10000,a0
	sub.l	a1,a1
	move.l	whdbase(pc),a6
	jsr	resload_diskloaddev(a6)

	move.l	#512*2,d0
	lea	boot(pc),a0
	lea	$10000,a1
	move.l	whdbase(pc),a6
	jsr	resload_savefile(a6)

	move.l	$10004,d0
	cmp.l	#$5cdc3fa7,d0
	beq.w	.megabx
	cmp.l	#$23454533,d0
	beq.b	.orig


;--- no known version detected

	moveq	#1,d0
	move.l	d0,-(sp)
	moveq	#-1,d0
	move.l	d0,-(sp)
	pea	tdreason_diskload
	move.l	whdbase(pc),-(sp)
	add.l	#resload_abort,(sp)
	rts


;--- install original version

.orig	patch	$10034,.boot
	jmp	$10016
;---

.boot	patch	$20040,.loader
	patch	$20292,.wait
	patch	$202c6,.wait
	jmp	$2002e
;---

.loader	movem.l	d0-a7,-(sp)
	move.l	#2400,d0
	lea	main(pc),a0
	lea	$400.w,a1
	move.l	whdbase(pc),a6
	jsr	resload_savefile(a6)
	movem.l	(sp)+,d0-a7

	patchs	$48a.w,.files
	patch	$a2c.w,.wait
	patch	$a60.w,.wait
	jmp	$400.w
;---

.files	jsr	$5d8.w

	movem.l	d0-a7,-(sp)
	move.l	#32032,d0
	lea	intro(pc),a0
	lea	$10000,a1
	move.l	whdbase(pc),a6
	jsr	resload_savefile(a6)
	movem.l	(sp)+,d0-a7

	patch	$52c.w,.files2
	rts
;---

.files2	movem.l	d0-a7,-(sp)
	move.l	#230108,d0
	lea	title(pc),a0
	lea	$1c000,a1
	move.l	whdbase(pc),a6
	jsr	resload_savefile(a6)
	movem.l	(sp)+,d0-a7

	lea	$1c000,a4
	moveq	#1,d0
	jsr	$5d8.w

	movem.l	d0-a7,-(sp)
	move.l	#75628,d0
	lea	game(pc),a0
	lea	$1c000,a1
	move.l	whdbase(pc),a6
	jsr	resload_savefile(a6)
	movem.l	(sp)+,d0-a7
	bra.w	.leave


;--- fix drive delays

.wait	move.l	d1,-(sp)
	moveq	#60,d1

.next	move.b	$dff006,d0
.line	cmp.b	$dff006,d0
	beq.b	.line
	dbf	d1,.next

	move.l	(sp)+,d1
	rts


;--- install mega box version

.megabx	move.l	#512*2,d0
	move.l	#512*9,d1
	lea	$10000,a0
	sub.l	a1,a1
	move.l	whdbase(pc),a6
	jsr	resload_diskloaddev(a6)

	move.l	#512*9,d0
	lea	main(pc),a0
	lea	$10000,a1
	move.l	whdbase(pc),a6
	jsr	resload_savefile(a6)

	move.l	#512*11,d0
	move.l	#512*149,d1
	lea	$10000,a0
	sub.l	a1,a1
	move.l	whdbase(pc),a6
	jsr	resload_diskloaddev(a6)

	move.l	#76000,d0
	lea	game(pc),a0
	lea	$10000,a1
	move.l	whdbase(pc),a6
	jsr	resload_savefile(a6)


;--- return to os

.leave	pea	tdreason_ok
	move.l	whdbase(pc),-(sp)
	add.l	#resload_abort,(sp)
	rts

;--------------------------------
whdbase	dc.l	0	;	=
;--------------------------------


;--- file names

boot	dc.b	'CqBoot',0
title	dc.b	'CqTitle',0
game	dc.b	'CqGame',0,0
main	dc.b	'CqMain',0,0
intro	dc.b	'CqIntro',0

rip
