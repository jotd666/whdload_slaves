

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

FLAGS		= WHDLF_NoError|WHDLF_ClearMem
QUITKEY		= $59		; F10
;DEBUG

; relocates program to another memory location
RELOC_ENABLED = 0
; uses chipmem for easier debug (addresses are shifted by $80000)
CHIP_ONLY = 1

EXPMEMSIZE = $80000
PROGRAM_START = $800
PROGRAM_SIZE = $11800

	IFD	CHIP_ONLY
CHIPMEMSIZE = $80000+EXPMEMSIZE
FASTMEMSIZE = 0
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = EXPMEMSIZE
	ENDC
	



DECL_VERSION:MACRO
	dc.b	"1.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

HEADER	SLAVE_HEADER		; ws_Security + ws_ID
	dc.w	17		; ws_Version
	dc.w	FLAGS		; ws_Flags
	dc.l	CHIPMEMSIZE		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; _data-HEADER		; ws_CurrentDir
	ENDC
	DC.W	0		; ws_DontCache
	DC.B	0		; ws_keydebug
	dc.b	QUITKEY		; ws_keyexit
_expmem
	dc.l	FASTMEMSIZE		; ws_ExpMem
	dc.w	_name-HEADER	; ws_name
	dc.w	_copy-HEADER	; ws_copy
	dc.w	_info-HEADER	; ws_info
	dc.w	0                       ;ws_kickname
	dc.l	0                       ;ws_kicksize
	dc.w	0                       ;ws_kickcrc
	dc.w	_config-HEADER		;ws_config


_config
    ;dc.b    "C1:B:infinite ammo;"
    dc.b	0

	
_name	DC.B	"Conqueror"
	IFD	CHIP_ONLY
	dc.b	" (chip/debug mode)"
	ENDC
		dc.b	0
_copy	DC.B	"1xxx Activision",0
_info	dc.b	"adapted by Dark Angel & JOTD",10,10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	dc.b	"$VER: Conqueror "
	DECL_VERSION
	dc.b	0

	CNOP	0,2
_reloc_base
	dc.l	PROGRAM_START

Patch	
	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	resload(pc),a2


	IFD	RELOC_ENABLED
	IFD	CHIP_ONLY
	lea	_expmem(pc),a0
	move.l	#$80000,(a0)
	ENDC
	
	lea		_reloc_base(pc),a0
	move.l	_expmem(pc),d0
	add.l	d0,(a0)
	
	; set CPU and cache options
	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	resload_SetCPU(a2)

	ENDC

	lea	boot(pc),a0
	lea	$10000,a1
	jsr	resload_LoadFile(a6)

	move.l	$10004,d0
	cmp.l	#$5cdc3fa7,d0
	beq.b	.megabx
	cmp.l	#$23454533,d0
	beq.b	.orig

;--- return to os

.leave	pea	TDREASON_WRONGVER
	move.l	resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
	rts



;--- original version

.orig	lea	main(pc),a0
	lea	$400.w,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)

	patch	$5d8.w,.loader
	jmp	$400.w


;--- loader

.loader	movem.l	d0-a7,-(sp)

	lsl	#3,d0
	lea	title(pc),a0
	lea	(a0,d0.w),a0
	lea	(a4),a1
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)

	movem.l	(sp)+,d0-a7
	rts


;--- mega box version

.megabx	lea	main(pc),a0
	lea	$70000,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)

	patch	$70036,.boot
	jmp	$70000


;--- patch loader

.boot	patch	$2ec,.ldgame
	jmp	$200.w


;--- load game

.ldgame	lea	game(pc),a0
	lea	$1c000,a1
	move.l	resload(pc),a6
	jmp	resload_LoadFile(a6)





	IFD		RELOC_ENABLED
	
	; copy program

	move.l	#PROGRAM_SIZE/4,d0
	lea		PROGRAM_START,a0
	move.l	_reloc_base(pc),A1
.copyr
	move.l	(a0)+,(a1)+
	subq.l	#1,d0
	bne.b	.copyr
	
	; load reloc table

	move.l	a3,a0		; name of reloc binary table
	lea		PROGRAM_START+PROGRAM_SIZE,a1		; use program end
	move.l	a1,a3	; save load location
	jsr		resload_LoadFileDecrunch(a2)

	; relocate
	move.l	_reloc_base(pc),a0
	lea		(-PROGRAM_START,a0),a1	; reloc base -$800
	move.l	a1,d1
	move.l	a3,a1	; reloc table location
.reloc
	move.l	(a1)+,d0
	beq.b	.end
	add.l	d1,(a0,d0.l)
	bra.b	.reloc
.end

	IFD	UNRELOC_ENABLED
	; unrelocate: cancel relocation of some data that
	; needs to be in chipmem
	move.l	a3,a1	; load location
	move.l	a5,a0	; unreloc binary offset filename (disabled in hunter)
	jsr		resload_LoadFileDecrunch(a2)
	
	; relocate
	move.l	_reloc_base(pc),a0
	lea		(-PROGRAM_START,a0),a1	; reloc base -$1000
	move.l	a1,d1
	move.l	a3,a1	; load location
.unreloc
	move.l	(a1)+,d0
	beq.b	.endu
	; correct offsets
	sub.l	d1,(a0,d0.l)
	bra.b	.unreloc
.endu
	ENDC
	
	; debug: add MMU protect on old program $ -> $ for v1
	; some code is copied by the game at the end of
	; chipmem ($1135C). Too complex/not worth fixing that
	; en: w 0 $800 $11350-$800
	; fr: w 0 $800 $11100
	ENDC
	

	move.l	a4,a0
	move.l	_reloc_base(pc),-(a7)
	move.l	(a7),a1
	jmp	resload_Patch(a2)



.unreloc_program_end_de
	lea	$11954,a0		; end of program, start of chipmem data
	moveq	#0,d0
	rts

	
.unreloc_program_end_en
	lea	$1135c,a0		; end of program, start of chipmem data
	moveq	#0,d0
	rts
	
	
; < D0: value of D0 in line
; .x: DBF D0,x
emulate_dbf
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.w	#$FFFF,d0
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
	




resload		dc.l	0

	
_quit:	pea	(TDREASON_OK).w

	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
	
_reloc_en
	dc.b	"conqueror_orig.reloc",0
_reloc_de
	dc.b	"conqueror_megabox.reloc",0

;--- file names

boot	dc.b	'CqBoot',0
title	dc.b	'CqTitle',0
game	dc.b	'CqGame',0,0
main	dc.b	'CqMain',0,0
intro	dc.b	'CqIntro',0

 