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
	INCLUDE	whdmacros.i

	IFD		BARFLY
	OUTPUT	sys:fighterbomber/fighter.slave
	;OPT	O+ OG+			;enable optimizing
	ENDC
	
;======================================================================

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
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
	dc.w	0                       ;ws_kickname
	dc.l	0                       ;ws_kicksize
	dc.w	0                       ;ws_kickcrc
	dc.w	_config-base		;ws_config


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

_name	dc.b	'-> F I G H T E R  B O M B E R <-',0
_copy	dc.b	'1989 Activision',0
_info	dc.b	'-----------------------',10
	dc.b	'Installed and fixed by',10
	dc.b	'Galahad of Fairlight & JOTD',10
	dc.b	'Version '
	DECL_VERSION
	dc.b	10
	dc.b	'------------------------',10
	dc.b	'Thanks to Slinka & Yoyo',10
	dc.b	'------------------------',0
save:	dc.b	'FB_Save',0
log:	dc.b	'FB_PilotsLog',0
_config
	dc.b	"C5:B:skip intro;"
    ;dc.b    "C1:B:infinite ammo;"
    dc.b	0

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
		bsr		Loader
		move.l	a0,a1
		move.l	a1,-(a7)
		add.l	#$38,(a7)
		lea		pl_boot(pc),a0
		move.l	_resload(pc),a2
		jsr		resload_Patch(a2)
		rts   ;Execute Boot Loader $7E038
		
copylock:
		move.l	#$8488ffc4,d0		;Copylock Serial Key
		move.l	d0,$24.w		;Secondary store
		rts		
		
pl_boot:
	PL_START
	PL_IFC5
	PL_L	$52,$60000084
	PL_ENDIF
	PL_P	$800,Loader
	PL_P	$9A,patch			;Patch before intro
	PL_P	$FC,gamepatch		;Game patcher!
	PL_P	$104,copylock		;Patch Copylock Routine!
	PL_END
	
	
;-----------------------------------
;Intro Patch
patch:
		move.w	#$4e75,$11280		;Remove RTE
		move.w	#$4e71,$110c4		;Remove move.w sr,-(a7)
		jmp	$10000
;----------------------------------


gamepatch:

		lea	save(pc),a0
		move.l	save_buffer(pc),a1
		bsr	_LoadFile

		IFND	RELOC_ENABLED
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
		ENDC
		
		move.l	_resload(pc),a2
		lea		pl_main(pc),a0
		move.l	_reloc_base(pc),a1
		move.l	a1,-(a7)
		jsr		resload_Patch(a2)
		add.l	#$500,(a7)
		rts
		
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
		move.l	save_buffer(pc),a1
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
		move.l	save_buffer(pc),a1
		move.l	#$31800,d0
		bsr	_SaveFile
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
		bsr	_LoadDisk
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
		bsr	_LoadDisk
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
	
pl_main
	PL_START
	PL_CB	$14878			;Fix Address Error
	PL_P	$366ca,Loader2	;Game Loader patched!
	PL_R	$3786c		;Remove Manual Protection
	PL_PS	$30cd4,no_save
	PL_PS	$31348,no_save
	PL_PS	$30dc6,do_save
	PL_PS	$30df6,do_save
	PL_L	$30ed8,$600000d6	;Remove FORMAT option!
	PL_P	$2eeba,logger_save
	PL_PS	$2ee68,logger_load
	PL_END
	
	
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
		ds.b	$1bb34-$1b8fc
speedup:
		ds.b	$20714-$20518
depack:
		ds.b	$2596e-$258be
;----------------------------------

_reloc_base
	dc.l	0
save_buffer
	dc.l	$80000
	
;======================================================================

	END
