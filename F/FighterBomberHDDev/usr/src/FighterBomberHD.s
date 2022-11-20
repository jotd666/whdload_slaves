;*---------------------------------------------------------------------------
;  :Program.	MK.Asm
;  :Contents.	Slave for "Mortal Kombat" from A<<LAIM ENTERTAINMENT
;  :Author.	Galahad of Fairlight
;  :History.	09.01.01
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	PhxAs
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	sys:include/
	INCLUDE	whdload.i

	OUTPUT	sys:fighterbomber/fighter.slave
	;OPT	O+ OG+			;enable optimizing

;======================================================================

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	13		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$b2000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$46		;ws_keyexit = Del
		dc.l	0		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info

_name	dc.b	'-> F I G H T E R  B O M B E R <-',0
_copy	dc.b	'1989 Activision',0
_info	dc.b	'-----------------------',10
	dc.b	'Installed and fixed by',10
	dc.b	'Galahad of Fairlight',10
	dc.b	'Version 1.0 (01.05.2002)',10
	dc.b	'------------------------',10
	dc.b	'Thanks to Slinka & Yoyo',10
	dc.b	'------------------------',0
save:	dc.b	'FB_Save',0
log:	dc.b	'FB_PilotsLog',0
	CNOP 0,2


;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		moveq	#0,d0
		lea	log(pc),a0
		bsr	_checkfile
		tst.l	d0		
		bne.s	file_exists
		moveq	#2,d2
		move.l	#$2*$200,d0
		move.l	#$1*$200,d1
		lea	$50000,a0
		bsr	_LoadDisk
		move.l	a0,a1
		lea	log(pc),a0
		move.l	d1,d0
		bsr	_SaveFile		
file_exists:
		moveq	#0,d1
		moveq	#$b,d2
		moveq	#1,d3				
		lea	$7e000,a0
		lea	Loader(pc),a2
		jsr	(a2)
		btst	#6,$bfe001
		bne.s	no_press
		move.l	#$60000084,$52(a0)	;Skip Intro
no_press:
		move.w	#$4ef9,$800(a0)
		move.l	a2,$802(a0)		;Boot Loader patched
		lea	patch(pc),a1
		move.l	a1,$9c(a0)		;Patch before intro
		lea	gamepatch(pc),a1
		move.l	a1,$fe(a0)		;Game patcher!
		lea	copylock(pc),a1
		move.w	#$4ef9,$104(a0)
		move.l	a1,$106(a0)		;Patch Copylock Routine!
		jmp	$38(a0)			;Execute Boot Loader
copylock:
		move.l	#$8488ffc4,d0		;Copylock Serial Key
		move.l	d0,$24.w		;Secondary store
		rts		
;-----------------------------------
;Intro Patch
patch:
		move.w	#$4e75,$11280		;Remove RTE
		move.w	#$4e71,$110c4		;Remove move.w sr,-(a7)
		jmp	$10000
;----------------------------------
gamepatch:
		clr.b	$14878			;Fix Address Error
		lea	Loader2(pc),a0
		lea	$366ca,a1
		move.w	#$4ef9,(a1)+
		move.l	a0,(a1)			;Game Loader patched!
		move.w	#$4e75,$3786c		;Remove Manual Protection
		lea	no_save(pc),a0
		move.l	a0,$30cd6
		move.l	a0,$3134a
		lea	do_save(pc),a0
		move.l	a0,$30dc8
		move.l	a0,$30df8
		move.l	#$600000d6,$30ed8	;Remove FORMAT option!
		lea	save(pc),a0
loc:		lea	$80000,a1
		bsr.s	_LoadFile
		lea	logger_save(pc),a0
		move.l	a0,$2eebc
		lea	logger_load(pc),a0
		move.l	a0,$2ee6a
		
		lea	depack(pc),a0
		lea	$258be,a1
		move.l	a1,a2
		move.l	a0,a3
		move.w	#($2596e-$258be)-1,d0
copy_depack:
		move.b	(a1)+,(a0)+
		dbra	d0,copy_depack
		move.w	#$4ef9,(a2)+
		move.l	a3,(a2)			;Patch depack!
		
		lea	speedup(pc),a0
		lea	$20518,a1
		move.l	a1,a2
		move.l	a0,a3
		move.w	#($20714-$20518)-1,d0
copydata:
		move.b	(a1)+,(a0)+
		dbra	d0,copydata
		move.w	#$4ef9,(a2)+
		move.l	a3,(a2)			;Patch depack!

		lea	speedup2(pc),a0
		lea	$1b8fc,a1
		move.l	a1,a2
		move.l	a0,a3
		move.w	#($1bb34-$1b8fc)-1,d0
copydata2:
		move.b	(a1)+,(a0)+
		dbra	d0,copydata2
		move.w	#$4ef9,(a2)+
		move.l	a3,(a2)			;Patch depack!
		jmp	$500.w
;----------------------------------
logger_load:
		movem.l	d0-d7/a0-a6,-(a7)
		lea	log(pc),a1
		exg	a0,a1
		bsr	_LoadFile
		movem.l	(a7)+,d0-d7/a0-a6
		moveq	#0,d0
		rts
logger_save:
		movem.l	d0-d7/a0-a6,-(a7)
		move.l	#512,d0
		lea	log(pc),a1
		exg	a0,a1
		bsr	_SaveFile
		movem.l	(a7)+,d0-d7/a0-a6
		moveq	#0,d0
		rts	
;---------------------------------------------------
do_save:
		move.l	$36166,a1
		move.w	#$0fff,d0
clear:		clr.l	(a1)+
		dbra	d0,clear
		move.l	$36166,a1
		moveq	#0,d0
		moveq	#-1,d3
		bra.s	load_save
no_save:
		moveq	#0,d0
		moveq	#0,d3

load_save:
		movem.l	d0-d7/a0-a6,-(a7)
		move.l	loc+2(pc),a1
		moveq	#0,d0
		move.w	d1,d0
		moveq	#0,d1
		move.w	d2,d1
		mulu	#$200,d0
		mulu	#$200,d1
		add.l	d0,a1
		subq.w	#1,d1
		moveq	#-1,d4
		move.l	a0,-(a7)
		cmp.w	d4,d3
		beq.s	saver
copy_data:	move.b	(a1)+,(a0)+
		dbra	d1,copy_data					
		move.l	(a7)+,a0		
		bra.s	skip_saver

saver:		move.b	(a0)+,(a1)+
		dbra	d1,saver
		move.l	(a7)+,a1
		lea	save(pc),a0
		move.l	loc+2(pc),a1
		move.l	#$31800,d0
		bsr.s	_SaveFile
skip_saver:
		movem.l	(a7)+,d0-d7/a0-a6
		moveq	#0,d0
		rts

Loader2:
		movem.l	d0-d7/a0-a6,-(a7)
		moveq	#0,d0
		move.w	d1,d0
		moveq	#0,d1
		move.w	d2,d1
		moveq	#0,d2
		moveq	#2,d2
		mulu	#$200,d0
		mulu	#$200,d1		
		bsr.s	_LoadDisk
		movem.l	(a7)+,d0-d7/a0-a6
		rts
Loader:
		movem.l	d0-d7/a0-a6,-(a7)
		moveq	#0,d0
		move.w	d1,d0
		moveq	#0,d1
		move.w	d2,d1
		moveq	#1,d2
		mulu	#$200,d0
		mulu	#$200,d1		
		bsr.s	_LoadDisk
		cmp.l	#$10000,a0
		beq.s	wait
		cmp.l	#$500,a0
		bne.s	skip
		moveq	#$7f,d0
		lsl.l	#8,d0
wait2:		move.b	$dff006,d1
wait		cmp.b	$dff006,d1
		beq.s	wait
		btst	#6,$bfe001
		beq.s	skip
		dbra	d0,wait2
skip:		movem.l	(a7)+,d0-d7/a0-a6
		moveq	#0,d0
		rts
		
;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		bra.b	au
_LoadFile:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		bra.b	au
_SaveFile:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)
au:		movem.l	(a7)+,d0-d1/a0-a2
		rts
_checkfile:
		movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		movem.l	(a7)+,d1/a0-a2
		rts
speedup2:
		dcb.b	$1bb34-$1b8fc
speedup:
		dcb.b	$20714-$20518
depack:
		dcb.b	$2596e-$258be
;----------------------------------

	
;======================================================================

	END
