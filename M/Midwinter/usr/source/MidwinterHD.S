	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"Midwinter.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC


;--- insert macros here...


;--- power to the people

_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	11					; ws_version
	dc.w	WHDLF_EmulTrap|WHDLF_NoDivZero|WHDLF_NoError
	dc.l	$80000					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	_start-_base				; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
	dc.b	0					; ws_keydebug
_keyexit	dc.b	$5a					; ws_keyexit [numl]
_expmem		dc.l	$0000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
    
_data		dc.b	"data",0
_name		dc.b	"Midwinter",0
_copy		dc.b	"1990 Rainbird",0
_info		dc.b	"Install & fix by Dark Angel / JOTD",10,10
		dc.b	"Version "
        DECL_VERSION
		dc.b	0
        dc.b    "$VER: Midwinter "
        DECL_VERSION
        dc.b    0
		even

;---  emulate bootblock

_start
	lea	_resload(pc),a1
	move.l	a0,(a1)

	move.l	#CACRF_EnableI,d0
	move.l	d0,d1
	jsr	resload_SetCACR(a0)

	moveq	#1,d0
	moveq	#5,d1
	lea	$314e0,a0
	bsr.b	_load1

	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	lea	$0.W,a1
	lea	_pl_part1(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	jmp	$31500

_pl_part1
	PL_START
	PL_P	$32a84,_load1
	PL_P	$317e0,_part2

	PL_R	$32928		; skip floppy access
	PL_R	$3298C		; skip floppy access
	PL_P	$327BA,_fix_snoop
	PL_END

_fix_snoop:
	move.w	(a7)+,d0
	move.w	d0,$dff09e
	movem.l	(a7)+,d0-a6
	rts

;--- patch loader 1

_load1	movem.l	d0-a7,-(sp)
	mulu	#$1400,d0
	addq	#1,d1
	mulu	#$1400,d1
	moveq	#1,d2
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)
	movem.l	(sp)+,d0-a7

	add	d1,d0
	addq	#1,d0

	move	d1,d4
	addq	#1,d4
	mulu	#$1400,d4
	lea	(a0,d4.l),a0

	moveq	#0,d4
	rts


;--- part 2

_part2
	movem.l	d0-d1/a0-a2,-(a7)

	sub.l	a1,a1
	lea	_pl_part2_common(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)


	move.w	$dd7a,d0
	cmp.w	#$33FC,d0
	beq.b	.patch_eng
	move.w	$dd7a+$18,d0
	cmp.w	#$33FC,d0
	beq.b	.patch_ger

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.patch_ger
	lea	$18.W,a1
	bra.b	.patch_generic

.patch_eng
	lea	0.W,a1
.patch_generic
	lea	_disknum_address(pc),a0
	move.l	a1,d1
	add.l	d1,(a0)

	lea	_pl_part2_eng(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$800.w

_pl_part2_common:
	PL_START
	PL_W	$AE0,$6004	; remove password
	PL_PS	$2d36,killbug
	PL_PS	$2fee,killbug
	PL_PS	$30f4,killbug
	PL_END

_pl_part2_eng:
	PL_START
	PL_P	$dd7a,_load2
	PL_P	$de70,_save
	PL_P	$dc56,_drivon
	PL_P	$ce74,_datdsk
	PL_P	$cebe,_gfxdsk

	PL_PS	$6e40,l6e40
	PL_PS	$7040,l7040
	PL_PS	$c720,killbug
	PL_PS	$e55e,killbug
	PL_PS	$5b6e,killbug
	PL_PS	$d374,killbug
	PL_PS	$4740,killbug
	PL_PS	$4f50,killbug
	PL_PS	$5724,killbug
	PL_PS	$5ada,killbug
	PL_PS	$373a,killbug
	PL_PS	$3770,killbug
	PL_PS	$3e30,killbug

	PL_R	$DC88		; snoop

	PL_PS	$65b0,_cia

	PL_END

;--- patch loader 2

_load2	movem.l	d0-a7,-(sp)
	mulu	#$1400,d0
	addq	#1,d1
	mulu	#$1400,d1

	moveq	#3,d2
	lea	saveimg(pc),a1
	tst	(a1)
	bne.b	_disk3

	move.l	_disknum_address(pc),a2
	move.b	(a2),d2
	lsr	#2,d2
	and	#1,d2
	addq	#1,d2

_disk3	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)
	movem.l	(sp)+,d0-a7

	add	d1,d0
	addq	#1,d0

	move	d1,d4
	addq	#1,d4
	mulu	#$1400,d4
	lea	(a0,d4.l),a0

	moveq	#0,d4
	rts


;--- save game

_save	movem.l	d0-a7,-(sp)
	exg	d0,d1
	addq	#1,d0
	mulu	#$1400,d0
	mulu	#$1400,d1
	lea	(a0),a1
	lea	savfile(pc),a0
	move.l	_resload(pc),a6
	jsr	resload_SaveFileOffset(a6)
	movem.l	(sp)+,d0-a7

	add	d1,d0
	addq	#1,d0

	move	d1,d4
	addq	#1,d4
	mulu	#$1400,d4
	lea	(a0,d4.l),a0

	moveq	#0,d4
	rts


;--- no drive check

_drivon	moveq	#0,d4
	rts


;--- insert right disk

_datdsk	lea	saveimg(pc),a0
	move	#-1,(a0)
	rts
;---

_gfxdsk	lea	saveimg(pc),a0
	clr	(a0)
	rts


;--- cia

_cia
	not.b	d1
	ror.b	#1,d1
	cmp.b	_keyexit(pc),d1
	beq.b	.leave

	moveq	#2,d1
.bd_loop1
	move.w  d1,-(a7)
        move.b	$dff006,d1	; VPOS
.bd_loop2
	cmp.b	$dff006,d1
	beq.s	.bd_loop2
	move.w	(a7)+,d1
	dbf	d1,.bd_loop1
	rts


;--- return to os

.leave	pea	TDREASON_OK
	move.l	_resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
	rts


;--- remove bugs

killbug
	move.l	(a0,d0.w),d0
	bmi.b	.bmi
	rts
.bmi	and.l	#$7ffff,d0
	addq.l	#4,(a7)
	rts

;---

l6e40	btst	#$1e,d0
	beq.b	.6e80
	and.l	#$7ffff,d0
	rts
.6e80	and.l	#$7ffff,d0
	add.l	#$80-$46,(a7)
	rts
;---

l7040	btst	#$1e,d0
	beq.b	.707a
	and.l	#$7ffff,d0
	rts
.707a	and.l	#$7ffff,d0
	add.l	#$34,(a7)
	rts

;--------------------------------
_resload	dc.l	0	;	=
saveimg	dc.w	0	;	=
;--------------------------------

_disknum_address
	dc.l	$dc1e

;--- file names

savfile	dc.b	'Disk.3',0

rip
