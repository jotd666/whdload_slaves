;*---------------------------------------------------------------------------
;  :Program.	FighterBomberHD.s
;  :Contents.	Slave for "Fighter Bomber" from Activision/Vectorgrafx
;  :Author.	Galahad of Fairlight / JOTD / paraj
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	PhxAs, vasm, barfly
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	sys:include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD		BARFLY
	OUTPUT	sys:fighterbomber/fighter.slave
	;OPT	O+ OG+			;enable optimizing
	ENDC
	
PROGRAM_START = $500
PROGRAM_SIZE = $4F200-PROGRAM_START
RELOC_TABLE_ADDRESS = PROGRAM_START+PROGRAM_SIZE
SAVEMEM = $32000

;CHIP_ONLY
;USE_PROFILER

RELOC_ENABLED = 1
	IFD	RELOC_ENABLED
RELOC_MEM = $50000+SAVEMEM
	ELSE
RELOC_MEM = SAVEMEM
	ENDC

SHOWFPS=0 ; =0 => disable, 1 => show fps, 2 => use last_time as counter

;==========================================================================

	IFD	CHIP_ONLY
	IFD	USE_PROFILER
	; let's party with 2MB chip so we can use profiler memory in $180000
BASMEM_SIZE	equ	$200000
	ELSE
BASMEM_SIZE	equ	$80000+RELOC_MEM
	ENDC
	
EXPMEM_SIZE	equ	0
	ELSE
BASMEM_SIZE	equ	$80000
EXPMEM_SIZE	equ	RELOC_MEM
	
	ENDC

;======================================================================
screenw=320
screenh=200
nbpl=4

bplrowwords=screenw/16
bplrowbytes=bplrowwords*2
rowdelta=bplrowbytes*nbpl
	
;======================================================================

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		dc.l	BASMEM_SIZE		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$46		;ws_keyexit = Del
_expmem
		dc.l	EXPMEM_SIZE		;ws_ExpMem
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

_name	dc.b	'Fighter Bomber'
		IFD		CHIP_ONLY
		dc.b	" (chip/debug mode)"
		ENDC
		IFD		USE_PROFILER
		dc.b	" (profiling on)"
		ENDC
		
		dc.b	0
_copy	dc.b	'1989 Activision',0
_info	dc.b	'-----------------------',10
	dc.b	'Installed and fixed by',10
	dc.b	'Galahad of Fairlight & JOTD & paraj',10
	dc.b	'Version '
	DECL_VERSION
	dc.b	10
	dc.b	'------------------------',10
	dc.b	'Thanks to Slinka & Yoyo',10
	dc.b	'------------------------',0
save:	dc.b	'FB_Save',0
log:	dc.b	'FB_PilotsLog',0
_config
	dc.b	"BW;"
	dc.b	"C5:B:skip intro;"
    ;dc.b    "C1:B:infinite ammo;"
    dc.b	0

reloc_file_name_table
	dc.b	"fighterbomber.reloc",0
unreloc_file_name_table
	dc.b	"fighterbomber."
	IFD		CHIP_ONLY
	dc.b	"chip_"
	ENDC
	dc.b	"unreloc"
	dc.b	0
	
	CNOP 0,2


;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		IFD		CHIP_ONLY
		lea		_expmem(pc),a0
		move.l	#$80000,(a0)
		
		; set CPU and cache options
		ENDC

		IFD		USE_PROFILER
		lea		$180000,a0	; buffer start
		move.l	#$10000,d0	; buffer size
		lea		$100.W,a1	; where to read control & write start & size (example $100.W)
		bsr		init_fixed_address
		
		ENDC
		
		move.l	_resload(pc),a2
		move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	resload_SetCPU(a2)
		
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

		
		lea		save_buffer(pc),a1
		IFD		RELOC_ENABLED
		lea		_reloc_base(pc),a0
		move.l	_expmem(pc),d0
		add.l	d0,(a0)
		add.l	#SAVEMEM,d0
		move.l	d0,(a1)
		ELSE
		move.l	_expmem(pc),(a1)
		ENDC
	
		pea		smc_trap13(pc)
		move.l	(a7)+,$B4.W	; trap #13

		pea		smc_trap14(pc)
		move.l	(a7)+,$B8.W	; trap #14

		pea		smc_trap15(pc)
		move.l	(a7)+,$BC.W	; trap #15

		bsr	init_jump_target1
		bsr	init_jump_target2
		
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
wait_and_load
	JSR	$7e800
.loop
	btst	#6,$bfe001
	beq.b	.out
	btst	#7,$bfe001
	beq.b	.out
	bra.b	.loop
.out	
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
	PL_IFBW
	PL_PS	$86,wait_and_load
	PL_ENDIF
	PL_END
	
	
;-----------------------------------
;Intro Patch
patch:
		move.w	#$4e75,$11280		;Remove RTE
		move.w	#$4e71,$110c4		;Remove move.w sr,-(a7)
		bsr		_flushcache
		jmp	$10000
;----------------------------------


gamepatch:
		lea	save(pc),a0
		move.l	save_buffer(pc),a1
		bsr	_LoadFile

		IFD		RELOC_ENABLED
		; copy program
		
		move.l	#PROGRAM_SIZE,d0
		lsr.l	#2,d0
		lea		PROGRAM_START,a0
		move.l	_reloc_base(pc),A1
.copy
		move.l	(a0)+,(a1)+
		subq.l	#1,d0
		bne.b	.copy
				
		; load reloc table
		move.l	_resload(pc),a2
		lea		RELOC_TABLE_ADDRESS,a1
		lea		reloc_file_name_table(pc),a0
		jsr		resload_LoadFileDecrunch(a2)

		; relocate
		move.l	_reloc_base(pc),a0
		lea		(-PROGRAM_START,a0),a1	; expansion mem
		move.l	a1,d1
		lea		RELOC_TABLE_ADDRESS,a1
.reloc
		move.l	(a1)+,d0
		beq.b	.end
		add.l	d1,(a0,d0.l)
		bra.b	.reloc
.end
		lea		RELOC_TABLE_ADDRESS,a1
		lea		unreloc_file_name_table(pc),a0
		jsr		resload_LoadFileDecrunch(a2)

		; unrelocate
		move.l	_reloc_base(pc),a0
		lea		(-PROGRAM_START,a0),a1	; expansion mem
		move.l	a1,d1
		lea		RELOC_TABLE_ADDRESS,a1
.unreloc
		move.l	(a1)+,d0
		beq.b	.endu
		sub.l	d1,(a0,d0.l)
		bra.b	.unreloc
.endu
		
	IFNE	0
		; protect mem: 
w 0 $1000 $24A
w 1 $124C $9D4-$24C
w 2 $1A82 $4E500-$1A82
		; unprotect mem: 
w 0
w 1
w 2
		; protect for smc: 
w 0 $80500 $4E000 none
smc 0
	ENDC
	
		ELSE
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
		move.l	attnflags(pc),d0
		btst	#AFB_68020,d0
		beq.b	.p
		lea		pl_main_020(pc),a0	; more fixes
.p
		move.l	_reloc_base(pc),a1
		move.l	a1,-(a7)
		sub.w	#PROGRAM_START,a1
		jsr		resload_Patch(a2)
		
		; patch base mem so snoop bugs are fixed
		move.l	_resload(pc),a2
		lea		pl_main_snoop(pc),a0
		sub.l	a1,a1
		jsr		resload_Patch(a2)		
		
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
		add.l	_reloc_base(pc),a1
		add.l	#PROGRAM_START,a1
		move.l	a1,-(a7)
		move.w	#$0fff,d0
clear:		clr.l	(a1)+
		dbra	d0,clear
		move.l	(a7)+,a1

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
		add.l	_reloc_base(pc),d0
		add.l	#PROGRAM_START,d0
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
		
		sub.l	_reloc_base(pc),a0
		sub.w	#PROGRAM_START,a0
		
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

pl_main_snoop
	PL_START
	PL_W	$2e5ec,$200		; fix snoop
	PL_L	$2e5ee,$01000200	; overwrite bogus entry
	PL_END

pl_main_020:
	PL_START
	; optimize for 020+ in the loop which is frequently called
	; (15000-150c8)
	PL_L	$14f56,$d2f02200    ;            adda.w (a0,d2.w*2,$00),a1
	PL_NOP	$14f56+4,2
	PL_L	$1502e,$d2f02200    ;            adda.w (a0,d2.w*2,$00),a1
	PL_NOP	$15032,2
	; that one is more interesting as it's in the critical path
	; when blitter is ready
	PL_AW	$15084,2	; skip the NOP
	PL_NOP	$1508e,2	
	PL_L	$15090,$d2f02200    ;            adda.w (a0,d2.w*2,$00),a1
	PL_NEXT	pl_main
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

	ifne SHOWFPS
	PL_PS	$0c198,update_fps_counter
	PL_PS	$2e3ec,update_fps_counter
	endc

	PL_PS	$0c012,use_fmode3

	PL_PS	$0b05e,keyboard_hook


	PL_PS	$143c6,cpu_dependent_loop_d2
	PL_PS	$143f8,cpu_dependent_loop_d0
	PL_PSS	$1464a,cpu_dependent_loop_d0_2,2
	
	PL_PS	$179d8,fix_smc_address

	IFD		RELOC_ENABLED
	PL_P	$1ff34,reloc_d1
	;PL_P	$1f5dc,reloc_d0	; address compared to is unrelocated nothing to do!!
	PL_P	$1fdd8,jump_reloc
	PL_PS	$219d0,reloc_a5
	
	; fix hardcoded sprite pointers in copperlist
	; (not needed in fastmem, but more convenient for chip debug)
	IFD		CHIP_ONLY
	PL_AW	$0c270,$8	; adds $80000
	PL_AW	$2c622,$8	; adds $80000
	PL_AW	$2e6a8,$8	; adds $80000
	PL_AW	$35600,$8	; adds $80000 to hardcoded sprite address
	PL_AW	$35608,$8	; adds $80000
	ENDC
	ENDC
	
	; a lot of smc moving RTS or NOP, handle that by trap #14
    PL_W	$0f00a,$4E4E
    PL_W	$1acbe,$4E4E
    PL_W	$1acf8,$4E4E
    PL_W	$1adba,$4E4E
    PL_W	$1af14,$4E4E
    PL_W	$2c1c8,$4E4E
    PL_W	$2c332,$4E4E
    PL_W	$2df40,$4E4E
    PL_W	$2e0ce,$4E4E
    PL_W	$2e7da,$4E4E
    PL_W	$2e924,$4E4E
    PL_W	$2ee4a,$4E4E
    PL_W	$33f48,$4E4E
    PL_W	$3632e,$4E4E
    PL_W	$36336,$4E4E
    PL_W	$46b6c,$4E4E
    PL_W	$46c92,$4E4E

	; trap 13
    PL_W	$20e94,$4E4D

	; smc involving JMP $xxxx.L, handled with trap #15
	; this one isn't used in game, so don't bother
	;MOVE.L	#lb_0f11c,lb_0f056+2	;0efec: 23fc0000f11c0000f058
	;MOVE.L	#lb_0f05e,lb_0f056+2	;0eff8: 23fc0000f05e0000f058
    PL_W	$0f056,$4E4F


	; Heavily used SMC
	PL_PSS	$14c38,set_target1_15000,4
	PL_PSS	$14c46,set_target1_14ef4,4
	PL_PS	$14ee4,call_target1


	; This SMC is heavily used, so handle it specially
	PL_PSS	$14e58,set_target2_14dc8,4
	PL_PSS	$14e76,set_target2_14dc8,4
	PL_PSS	$14ea0,set_target2_14dc8,4
	PL_PSS	$15196,set_target2_14e48,4
	PL_PSS	$15326,change_target2,32
	PL_PS	$14df2,call_target2


	;CLR.B	lb_14fdc+4		;14eba: 423900014fe0
	;CLR.B	lb_150b4+4		;14ec0: 4239000150b8
	PL_PS	$14ec0,smc_14ec0

	;BCHG	#4,lb_14fdc+4		;14fae: 0879000400014fe0
	PL_PSS	$14fae,smc_14fae,2
	;BCHG	#4,lb_150b4+4		;15086: 08790004000150b8
	PL_PSS	$15086,smc_15086,2

	
	; after setting a jump
	PL_PS	$33d32,flush_after_smc
	; various smc
	PL_P	$1772c,smc_1772c
	PL_PS	$179d8,smc_179d8
	PL_P	$344dc,smc_344dc
	PL_PSS	$33f70,smc_33f70,4
	PL_PS	$3790a,smc_3790A
	PL_PSS	$f026,smc_f026,2
	PL_PS	$214cc,smc_214cc
	PL_PS	$21842,smc_21842
	
	; profiling
	IFD		USE_PROFILER
	PL_PS	$0b0da,vbl_hook
	PL_S	$0b0e0,$12
	ENDC
	
	
	PL_NEXT	pl_main_snoop
	
	IFD		USE_PROFILER
vbl_hook
	move.l	$42(a7),d0	; PC
	move.l	A7,a0		; supervisor
	bra		profiler_vbl_hook
	ENDC
	
fix_smc_address
	move.l	a1,-(a7)
	move.l	_reloc_base(pc),a1
	; emulate MOVE.L	A0,$17a06, smc
	;lb_17a04:
	;MOVEA.L	#$ffffffff,A0		;17a04: 207cffffffff
	add.l	#$17A06-PROGRAM_START,a1
	move.l	a0,(a1)
	move.l	(a7)+,a1
	bra		_flushcache
	
cpu_dependent_loop_d2
	exg.l	d0,d2
	bsr.b	cpu_dependent_loop_d0
	exg.l	d0,d2
	rts
	
cpu_dependent_loop_d0
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$20,D0	; $28 without nop, $20 (random) with nop
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.w	#$FFFF,d0
	rts

cpu_dependent_loop_d0_2
	MOVE.W	#$03e8,D0
emulate_dbf_d0:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0	; $28 without nop
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.w	#$FFFF,d0
	rts

smc_214cc
	MOVE.W	#$0018,D2		;214cc: 343c0018
	SUBQ.W	#1,D2			;214d0: 5342
	bra		_flushcache
	
smc_179d8
	move.l	a1,-(a7)
	move.l	_reloc_base(pc),a1
	add.l	#$17A06-PROGRAM_START,a1
	move.l	a0,(a1)
	move.l	(a7)+,a1
	bra	_flushcache
	
smc_21842
	move.l	a1,-(a7)
	move.l	_reloc_base(pc),a1
	add.l	#$21938-PROGRAM_START,a1
	move.l	a0,(a1)
	move.l	(a7)+,a1
	bra	_flushcache

smc_344dc
	MOVEM.L	(A7)+,D0-D2		;344dc: 4cdf0007
	bra	_flushcache
	
smc_33f70:
	move.l	a1,-(a7)
	move.l	_reloc_base(pc),a1
	add.l	#$33fa2-PROGRAM_START,a1
	move.l	#$fc000000,(a1)
	move.l	(a7)+,a1
	bra	_flushcache
	
smc_3790A:
	movem.l	a1,-(a7)
	move.l	_reloc_base(pc),a1
	add.l	#$3793e-PROGRAM_START,a1
	move.w	d1,(a1)
	bsr	_flushcache
	tst.w	(a1)		; CCR is tested on return
	movem.l	(a7)+,a1
	rts

need_clear: dc.w 0 ; Very rarely (ever?) need to clear/flush, but function >200 times/frame, so only flush if needed
smc_14ec0
	movem.l	a1,-(a7)
	lea	need_clear(pc),a1
	tst.w	(a1)
	beq.b	.noclear
	clr.w	(a1)
	move.l	_reloc_base(pc),a1
	add.l	#$150b8-PROGRAM_START,a1
	clr.b	(a1)
	move.l	(a7)+,a1
	bra	_flushcache
.noclear:
	move.l	(a7)+,a1
	rts

smc_14fae
	move.l	a1,-(a7)
	lea	need_clear(pc),a1
	st	(a1)
	move.l	_reloc_base(pc),a1
	add.l	#$14fe0-PROGRAM_START,a1
	BCHG	#4,(a1)
	move.l	(a7)+,a1
	bra	_flushcache
	
smc_15086
	move.l	a1,-(a7)
	lea	need_clear(pc),a1
	st	(a1)
	move.l	_reloc_base(pc),a1
	add.l	#$150b8-PROGRAM_START,a1
	BCHG	#4,(a1)
	move.l	(a7)+,a1
	bra	_flushcache
	
smc_f026:
	move.l	a1,-(a7)
	move.l	_reloc_base(pc),a1
	add.l	#$f114-PROGRAM_START,a1
	move.w	#$0078,(a1)
	move.l	(a7)+,a1
	bra	_flushcache

smc_1772c
	;MOVE.W	D2,lb_1bec8+2		;1772c: 33c20001beca
	;RTS				;17732: 4e75
	move.l	a0,-(a7)
	move.l	_reloc_base(pc),a0
	add.l	#$1beca-PROGRAM_START,a0
	move.w	d2,(a0)
	move.l	(a7)+,a0
	bra	_flushcache
	
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
	
flush_after_smc
	MOVE.W	#$0180,D0		;33d32: 303c0180
	MOVEQ	#31,D1			;33d36: 721f
	bra		_flushcache

	; fix for smc of a4
smc_trap13
	; MOVEA.L	#$ffffffff,A4		;20e94: 287cffffffff
	move.l	2(a7),a4
	move.l	(a4),a4
	addq.l	#4,(2,a7)		; skip the rest of the instruction
	rte

smc_trap14
	movem.l	d0/a0,-(a7)
	move.l	10(a7),a0	; return address
	move.w	(a0),d0		; data to write (nop or rts)
	move.l	(2,a0),a0	; where to write
	move.w	d0,(a0)
	bsr		_flushcache
	movem.l	(a7)+,d0/a0
	add.l	#6,(2,a7)		; skip the rest of the instruction
	rte

	; Fix for JMP $xxxx.L smc
smc_trap15
	move.l	a0,-(a7)
	move.l	6(a7),a0 ; return address
	move.l	(a0),6(a7)
	move.l	(a7)+,a0
	rte
	
	; relocate dynamically, the data is in a
	; binary stream and longs are on odd addresses...
jump_reloc
	add.l	_reloc_base(pc),a1
	sub.w	#PROGRAM_START,a1
	MOVE.L	A0,-(A7)		;1fdd8: 2f08
	JSR	(A1)			;1fdda: 4e91
	MOVEA.L	(A7)+,A0		;1fddc: 205f
	rts
	; same thing, and without that plane crashes
	; on covert mission right at start!
reloc_a5
	add.l	_reloc_base(pc),a5
	sub.w	#PROGRAM_START,a5
	cmp.l	#0,a5	; original
	rts
	; same thing, unidentified part
reloc_d1
	MOVE.B	(A0)+,D1		;1ff34: 1218
	LSL.L	#8,D1			;1ff36: e189
	MOVE.B	(A0)+,D1		;1ff38: 1218

	add.l	_reloc_base(pc),d1
	sub.w	#PROGRAM_START,d1
	rts
	
	; same thing, unidentified part
reloc_d0
	; original just adds 4
	add.l	_reloc_base(pc),d0
	sub.w	#PROGRAM_START-4,d0
	rts

COUNT macro
	ifeq SHOWFPS-2
	move.l	a0,-(sp)
	lea	last_time(pc),a0
	addq.l	#1,(a0)
	move.l	(sp)+,a0
	endc
	endm
	
_flushcache:
	COUNT
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
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
		
		IFND	RELOC_ENABLED
speedup2:
		ds.b	$1bb34-$1b8fc
speedup:
		ds.b	$20714-$20518
depack:
		ds.b	$2596e-$258be
		ENDC

; 4.53 -> 4.98fps (meh)
use_fmode3:
        btst.b  #9-8,vposr(a6)
        beq.b   .noaga
        move.w  #$0003,fmode(a6)
        move.w  #$00b8,ddfstop(a6)
	rts
.noaga
	MOVE.W	#$00d0,ddfstop(A6)		;0c012: 3d7c00d00094
        rts

;--------------------------------
; FPS counter

	ifne SHOWFPS

onedigit macro
        divu.w  #10,d0
        swap    d0
        moveq   #$f,d1
        and.l   d0,d1
        bsr     _drawdigit
        clr.w   d0
        swap    d0
        endm

last_time: dc.l 0
update_fps_counter:
        movem.l d1-d7/a0-a6,-(sp)

	ifne SHOWFPS-2
        ; Read CIAB tod
        moveq   #0,d0
        move.b  $bfda00,d0
        swap    d0
        move.b  $bfd900,d0
        lsl.w   #8,d0
        move.b  $bfd800,d0
        lea     last_time(pc),a0
        move.l  (a0),d1
        move.l  d0,(a0)
        sub.l   d1,d0
        ; d0=delta
	else
        lea     last_time(pc),a0
	move.l	(a0),d0
	clr.l	(a0)
	endc

	;move.l	_reloc_base(pc),a0
	;add.l	#$01a7a-PROGRAM_START,a0
	move.l	$1a7a.w,d7 ; not relocated
	move.l	d7,a2

        lea     (bplrowbytes-1,a2),a2
	ifne SHOWFPS-2
        move.l  d0,d1
        beq     .out
        move.l  #50*100*312,d0
        divu    d1,d0
		swap	d0
		clr.w	d0
		swap	d0
        onedigit
        onedigit
        moveq   #10,d1
        bsr     _drawdigit
        onedigit
        onedigit
	else
		swap	d0
		clr.w	d0
		swap	d0
	rept 5
	onedigit
	endr
	endc

.out:
	;MOVE.L	lb_01a7a_bitplanes_1,D0		;0c198: 203900001a7a
	move.l	d7,d0
        movem.l (sp)+,d1-d7/a0-a6

	rts	

_drawdigit:
        lsl.w   #3,d1
        lea     (_char_data,pc,d1.l),a0
        move.l  a2,a1
        moveq   #8-1,d3
.l:
        move.b  (a0)+,d2
        move.b  d2,(a1)
        move.b  d2,1*bplrowbytes(a1)
        move.b  d2,2*bplrowbytes(a1)
        move.b  d2,3*bplrowbytes(a1)
        add.w   #rowdelta,a1
        dbf     d3,.l
        subq.l  #1,a2
        rts

_char_data:
        dc.b    %00111100, %01100110, %01101110, %01111110, %01110110, %01100110, %00111100, %00000000  ; 0
        dc.b    %00011000, %00111000, %01111000, %00011000, %00011000, %00011000, %00011000, %00000000  ; 1
        dc.b    %00111100, %01100110, %00000110, %00001100, %00011000, %00110000, %01111110, %00000000  ; 2
        dc.b    %00111100, %01100110, %00000110, %00011100, %00000110, %01100110, %00111100, %00000000  ; 3
        dc.b    %00011100, %00111100, %01101100, %11001100, %11111110, %00001100, %00001100, %00000000  ; 4
        dc.b    %01111110, %01100000, %01111100, %00000110, %00000110, %01100110, %00111100, %00000000  ; 5
        dc.b    %00011100, %00110000, %01100000, %01111100, %01100110, %01100110, %00111100, %00000000  ; 6
        dc.b    %01111110, %00000110, %00000110, %00001100, %00011000, %00011000, %00011000, %00000000  ; 7
        dc.b    %00111100, %01100110, %01100110, %00111100, %01100110, %01100110, %00111100, %00000000  ; 8
        dc.b    %00111100, %01100110, %01100110, %00111110, %00000110, %00001100, %00111000, %00000000  ; 9
        dc.b    %00000000, %00000000, %00000000, %00000000, %00000000, %00011000, %00011000, %00000000  ; .

	endc ; SHOWFPS

;----------------------------------
; SMC jump at $14ee4
target1: dc.l 0 ;$14ef4

init_jump_target1:
set_target1_14ef4:
	movem.l	a0/a1,-(sp)
	lea	target1(pc),a0
	move.l	_reloc_base(pc),a1
	add.l	#$14ef4-PROGRAM_START,a1
	move.l	a1,(a0)
	movem.l	(sp)+,a0/a1
	rts

set_target1_15000:
	movem.l	a0/a1,-(sp)
	lea	target1(pc),a0
	move.l	_reloc_base(pc),a1
	add.l	#$15000-PROGRAM_START,a1
	move.l	a1,(a0)
	movem.l	(sp)+,a0/a1
	rts

call_target1:
	move.l	target1(pc),(a7)
	rts

;----------------------------------
; SMC jump at $14df2
target2: dc.l 0 ;$14dc8

init_jump_target2:
set_target2_14dc8:
	movem.l	a0/a1,-(sp)
	lea	target2(pc),a0
	move.l	_reloc_base(pc),a1
	add.l	#$14dc8-PROGRAM_START,a1
	move.l	a1,(a0)
	movem.l	(sp)+,a0/a1
	rts

set_target2_14e48:
	movem.l	a0/a1,-(sp)
	lea	target2(pc),a0
	move.l	_reloc_base(pc),a1
	add.l	#$14e48-PROGRAM_START,a1
	move.l	a1,(a0)
	movem.l	(sp)+,a0/a1
	rts

	;CMPI.L	#lb_14e48,lb_14df2+2	;15326: 0cb900014e4800014df4
	;BEQ.W	.lb_15342		;15330: 67000010
	;MOVE.L	#lb_14e66,lb_14df2+2	;15334: 23fc00014e6600014df4
	;BRA.W	.lb_1534c		;1533e: 6000000c
;.lb_15342:
	;MOVE.L	#lb_14e84,lb_14df2+2	;15342: 23fc00014e8400014df4
;.lb_1534c:
change_target2:
	movem.l	a0/a1,-(sp)
	lea	target2(pc),a0
	move.l	_reloc_base(pc),a1
	add.l	#$14e48-PROGRAM_START,a1
	cmp.l	(a0),a1
	beq.b	.out
	add.l	#$14e66-$14e48,a1
	move.l	a1,(a0)
.out:
	movem.l	(sp)+,a0/a1
	rts

call_target2:
	move.l	target2(pc),(a7)
	rts

;----------------------------------
keyboard_hook:
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit
	pea	TDREASON_OK.l
	move.l	_resload(pc),a0
	jmp	resload_Abort(a0)
.noquit:
	move.l	d0,-(sp)
	moveq	#2,d0 ; delay
	bsr	beamdelay
	move.l	(sp)+,d0

	MOVE.B	#$00,3072(A0)		;0b05e: 117c00000c00
	rts

;----------------------------------
_reloc_base
	dc.l	PROGRAM_START
save_buffer
	dc.l	0

_tag		dc.l	WHDLTAG_ATTNFLAGS_GET
attnflags	dc.l	0
		dc.l	0	
	IFD	USE_PROFILER
	include	profiler.s
	ENDC
	
;======================================================================

	END
