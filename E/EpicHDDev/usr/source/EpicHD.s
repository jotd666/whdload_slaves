;*---------------------------------------------------------------------------
;  :Program.	epic.slave.asm
;  :Contents.	Slave for "Epic"
;  :Author.	Graham, Wepl
;  :Original.	
;  :Version.	$Id: Epic.slave.asm 1.5 2008/09/07 21:21:05 wepl Exp wepl $
;  :History.	previous versions by Graham v1.3 (15.1.1999)
;		18.08.08 resourced and cleanup
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.16
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE whdmacros.i
	INCLUDE	exec/memory.i
	INCLUDE	lvo/exec.i

	IFD	BARFLY
	OUTPUT	"wart:e/Epic/Epic.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimizer warnings
	SUPER
	ENDC

;CHIP_ONLY

CHIPMEMSTART=$2000
EXPMEMSIZE=$80000
	IFD	ONEMEG_CHIP
CHIPMEMSIZE=$C0000
	ELSE
CHIPMEMSIZE=$80000	
	ENDC
	
	IFD	CHIP_ONLY
FAKEFASTMEMSIZE=EXPMEMSIZE
FASTMEMSIZE=$0
	ELSE
FASTMEMSIZE=EXPMEMSIZE
FAKEFASTMEMSIZE=0
	ENDC
	
EXPMEM_LIST_ADDRESS = $9C78

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoDivZero	;ws_flags
		dc.l	CHIPMEMSIZE+FAKEFASTMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit
_expmem		dc.l	FASTMEMSIZE			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
_config
	IFND	ONEMEG_CHIP
    dc.b    "C1:B:select mission disk;"
	ENDC
    dc.b	0
_data
	dc.b	"data",0
	
;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

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
	
_name		
	IFD	ONEMEG_CHIP
	dc.b	'Epic (1MB chip)'	
	ELSE
	dc.b	'Epic & Mission Disk'
	ENDC
	IFD	CHIP_ONLY
	dc.b	" (debug/chip mode)"
	ENDC
	
			dc.b	0
_copy		dc.b	'1992 Ocean',0
_info		dc.b	'adapted by Graham/Wepl/JOTD',$A
		dc.b	"Version "
		DECL_VERSION
		dc.b	-1
		dc.b	'Entrycodes:',10
		dc.b	'2-AURIGA  3-CEPHEUS  4-APUS  5-MUSCA',10
		dc.b	'6-PYXIS  7-CETUS  8-FORNAX  9-CAELUM  10-CORVUS',10
		IFND	ONEMEG_CHIP
		dc.b	'Warning: CEPHEUS will crash Epic!'
		ENDC
		dc.b	0
mission.MSG	dc.b	'mission',0
CODE.MSG	dc.b	'CODE',0
_num		dc.b	1
_highs		dc.b	'Epic.hi',0
	IFEQ 1
_highs_mission	dc.b	'Epic_MD.hi',0
	ENDC
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

	lea	(_resload,pc),a1
	move.l	a0,(a1)
	move.l	a0,a2			;A2 = _resload

	IFD		CHIP_ONLY
	lea		_expmem(pc),a0
	move.l	#CHIPMEMSIZE,(a0)
	ENDC
	
	lea	$100,a0
	moveq	#-2,d0
	move.l	d0,(a0)
	move.l	a0,_custom+cop1lc

	move.w	#$7FFF,d0
	lea	(_custom).l,a0
	move.w	d0,(intena,a0)
	move.w	d0,(intreq,a0)
	move.w	d0,(dmacon,a0)
	move.w	d0,(adkcon,a0)
	move.w	#(DMAF_COPPER|DMAF_MASTER|DMAF_SETCLR),(dmacon,a0)
	lea	($7FDF0).l,sp
	move.l	sp,usp
	adda.w	#$200,sp

WCPU_VAL = WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB
	move.l	_resload(pc),a2

	IFD		CHIP_ONLY
	; chip/debug mode: just set instruction cache
	move.l	#WCPUF_Base_WT|WCPU_VAL,d0
	ELSE
	;setup cache
	move.l	#WCPUF_Base_NC|WCPU_VAL,d0
	ENDC
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)	
	
	lea		main_file_name(pc),a0
	jsr		resload_GetFileSize(a2)
	tst.l	d0
	beq	.standard_versions
	; this is epic 3 disk HD-installable version
	; install fake exec for AllocMem & AvailMem
	lea $1000.W,A6
	move.l  A6,4.W
	move.l  #$FF,d0
	move.l  #$4AFC4AFC,d1   ; trash other vectors just in case...
.loop
	move.l  d1,-(a6)
	dbf d0,.loop
	move.l  4.W,a6
	lea (_LVOAllocMem,a6),a0
	move.w  #$4EF9,(a0)+
	pea fake_allocmem(pc)
	move.l  (a7)+,(a0)
	lea (_LVOAvailMem,a6),a0
	move.w  #$4EF9,(a0)+
	pea fake_availmem(pc)
	move.l  (a7)+,(a0)

	; configure fake memory
	; chip already configured
	; set fastmem. Note: in chip_only mode
	; the fastmem size will be 0
	move.l  _expmem(pc),a3
	add.l	#$30000,a3	; program size is $2fxxx
	lea free_fastmem(pc),a0
	move.l  a3,(a0)+    ; start

	add.l   #EXPMEMSIZE,a3   ; minus stack
	move.l  a3,(a0) ; top
	
	lea		main_file_name(pc),a0
	move.l	_expmem(pc),a1
	jsr		resload_LoadFileDecrunch(a2)
	move.l  _expmem(pc),a0
    clr.l   -(a7)                   ;TAG_DONE
    move.l  a7,a1                   ;tags	
	move.l	_resload(pc),a2
	jsr	resload_Relocate(a2)
	addq.w	#4,a7
	move.l	_expmem(pc),a1
	patch	$120,_load_sound_buffer
	lea		pl_prog_v3(pc),a0
	jsr		resload_Patch(a2)
	
	; copy sound data from exe to chipmem
	move.l	#$2CF50-$2B766,d0
	move.l	d0,d2
	move.l	#MEMF_CHIP,d1
	bsr		fake_allocmem
	lea		sound_buffer(pc),a0
	move.l	d0,(a0)
	move.l	d0,a1
	move.l	_expmem(pc),a0
	add.l	#$2B766,a0
	lsr.l	#2,d2
	subq.l	#1,d2
.copy
	move.l	(a0)+,(a1)+
	dbf		d2,.copy
	move.l	_expmem(pc),a1
	; relocate short sound buffer to chipmem
	move.l	#$62-$2a,d0
	move.l	d0,d2
	move.l	#MEMF_CHIP,d1
	bsr		fake_allocmem
	move.l	d0,a0
	lsr.l	#2,d2
	subq.l	#1,d2
.clear
	clr.l	(a0)+
	dbf		d2,.clear
	
	
	move.l	_expmem(pc),a1
	lea		.offsets(pc),a0
.reloc
	move.l	(a0)+,d1
	bmi.b	.out
	move.l	d0,(a1,d1.L)
	bra.b	.reloc
.out

	bsr	_flushcache
	move.l	_expmem(pc),-(a7)
	rts
	
.offsets:
        dc.l	$ce+2,$26e2c+2,$26e32+2,$27b36+2,-1
		
.standard_versions
	lea	($800).w,a0
	move.w	#$15FF,d0
.clr	clr.l	(a0)+
	dbra	d0,.clr

	addq.w	#1,($406E).w


	
	
	lea	(_tags,pc),a0
	jsr	(resload_Control,a2)
	move.l	(_c1,pc),d0
	beq.w	_normalgame

_missiongame
	lea	(mission.MSG,pc),a0
	lea	($7d8-$20).w,a1
	jsr	(resload_LoadFileDecrunch,a2)

	lea	_plm1(pc),a0
	sub.l	a1,a1
	jsr	(resload_Patch,a2)

	jsr	($9C7A).l		;startup, a0 = secondary exe
	move.l	a0,-(a7)

	adda.l	#$20840,a0
	bsr	_loadhighs

	lea	_plm2(pc),a0
	move.l	(a7),a1

	
	move.l	_resload(pc),a2
	jmp	(resload_Patch,a2)

_plm1	PL_START
	PL_P	$90a,_copydata_v2	;copylock which reads
	PL_P	$b08,_setexp_mission
	PL_P	$1616,_decrunch
	PL_L	$1922,$70014E75		;checkdisk
	PL_R	$19d4			;disk access
	PL_R	$1a36			;disk access
	PL_R	$1a70			;motor on
	PL_R	$1a98			;motor off
	PL_R	$1b72			;motor ready
	PL_P	$1bc6,.loadtrack
	PL_P	$1e16,_savehighs
	PL_S	$2346,4*4		;cia accesses
	PL_R	$23c0			;cpu detection, set exceptions/traps
	PL_R	$9d44			;calling secondary
	PL_END

.loadtrack	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d0,($191A).w
	move.w	#$20,($1920).w
	move.l	#$1600,d1
	mulu.w	d1,d0
	moveq	#0,d2
	move.b	(_num,pc),d2
	bsr.w	_diskload
	movem.l	(sp)+,d0-d7/a0-a6
	adda.w	#$1600,a0
	clr.w	($4072).w
	rts
	
_plm2	PL_START
	PL_PS	$2e,_copypatch_m2
	PL_PS	$601e,_keyboard
	PL_W	$9152,$602e
	PL_PS	$9192,_patch_num
	PL_S	$9198,$a8
	PL_P	$24734,_snoopssp1
	PL_PS	$2718e,_bw1
	PL_PS	$271d2,_bw3
	PL_PS	$27244,_bw2
	
	; jotd: added fixes for sound / caches
	
	PL_PS	$2384a,_sound_wait_2
	PL_S	$23850,$e
	
	; "remove trap" 68000 vector replaced by a flush
	PL_P	$5cf2,_flushcache_trap
	
	
	PL_END

_load_sound_buffer
	move.l	sound_buffer(pc),a0
	rts
	
_copypatch_m2	move.b	(a0)+,(a1)+
	dbra	d0,_copypatch_m2

	lea	_plm1(pc),a0
	sub.l	a1,a1
	jsr	(resload_Patch,a2)

	lea	$94.w,a1
	bra.w	patch_intrts

	IFEQ 1
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	a0,-(sp)
	lea	(_highs_mission,pc),a0
	movea.l	(_resload,pc),a2
	jsr	(resload_GetFileSize,a2)
	movea.l	(sp)+,a1
	cmp.l	#$80,d0
	bne.b	.no
	lea	(_highs,pc),a0
	adda.l	#$1E9D0,a1
	movea.l	(_resload,pc),a2
	jsr	(resload_LoadFile,a2)
.no	movem.l	(sp)+,d0-d7/a0-a6
	rts
	ENDC

_setexp_mission
	move.l	_expmem(pc),(a0)+		;expmem start
	move.l	#EXPMEMSIZE,(a0)+		;expmem length
	clr.l	(a0)+
	clr.l	(a0)+
	rts

_loadhighs
	move.l	a0,-(sp)
	lea	(_highs,pc),a0
	movea.l	(_resload,pc),a2
	jsr	(resload_GetFileSize,a2)
	movea.l	(sp)+,a1
	tst.l	d0
	beq	.no
	lea	(_highs,pc),a0
	jsr	(resload_LoadFile,a2)
.no	rts

_snoopssp1
	move.l	(a7),$dff080
	addq.l	#4,a7
	rts

_bw3	moveq	#15,d2
	sub.w	d7,d2
	add.w	d7,d7
	bra	_bw

_bw2	move.w	#15,d6
	sub.w	d7,d6

_bw	BLITWAIT
	rts

_bw1	bsr	_bw
	move.w	#-1,$dff044
	addq.l	#2,(a7)
	rts

_normalgame	lea	($6000).w,a0
	moveq	#0,d0
	move.l	#$400,d1
	moveq	#1,d2
	bsr.w	_diskload
	move.l	($6004).w,d0
	cmp.l	#$91D4E3E8,d0	;v1
	beq.b	_normalgame_v1
	cmp.l	#$C9804B44,d0	;v2
	beq.w	_normalgame_v2
	pea	TDREASON_WRONGVER
	jmp	(resload_Abort,a2)

_normalgame_v1	
	jsr	($610C).w
	lea	($864).w,a0
	move.l	#$2200,d0
	move.l	#$3000,d1
	moveq	#1,d2
	bsr.w	_diskload
	bsr.w	_patchmain
	jsr	($86C).w
	jsr	($898).w
	; search expansion memory blocks
	lea	EXPMEM_LIST_ADDRESS,a0
.search	move.l	(a0),d0
	beq.b	.found
	addq.l	#8,a0
	bra.b	.search

.found	subq.l	#8,a0
	lea	(_long,pc),a1
	move.l	(a0),(a1)
	move.l	#$3864,d3
	lea	(CODE.MSG,pc),a0
	move.l	a0,d1
	move.l	(_long,pc),d2
	jsr	($8B0).w		; load file
	
	movea.l	(_long,pc),a1
	lea		pl_prog_v1(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	bsr		_get_attn_flags
	move.w	d0,$4074.W
	; start game
	bsr.w	_loadhighs_v1
	move.l	(_long,pc),-(a7)
	rts
	

_get_attn_flags
	move.l	_attnflags(pc),d1
	moveq	#0,d0
	btst	#AFB_68020,d1
	beq.b	.out
	move.w	#$8,d0
	btst	#AFB_68030,d1
	beq.b	.out
	move.w	#$C,d0
.out
	; finally set 68000
	moveq	#0,d0
	rts
	
_enablecache
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	#CACRF_EnableI|CACRF_EnableD,d0
	move.l	d0,d1
	move.l	_resload(pc),a2
	jsr	(resload_SetCACR,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts
	
_disablecache
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	#CACRF_EnableI|CACRF_EnableD,d1
	clr.l	d0
	move.l	_resload(pc),a2
	jsr	(resload_SetCACR,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts
	
_flushcache_trap
	bsr	_flushcache
	rte
	
_setexp_v1
	lea	EXPMEM_LIST_ADDRESS,a0
	move.l	_expmem(pc),d0
	move.l	d0,(a0)
	jsr	($BD6).w
	jmp	($BE2).w

_copypatch	move.b	(a0)+,(a1)+
	dbra	d0,_copypatch
	bra.w	_patchmain

_copydata	movem.l	d0/a0/a1,-(sp)
	lea	(_data_v1,pc),a1
	move.w	#$1FF,d0
.copy	move.l	(a1)+,(a0)+
	dbra	d0,.copy
	movem.l	(sp)+,d0/a0/a1
	st	d0
	rts

_loadnum	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d0,($1886).w
	move.w	#$20,($188C).w
	move.l	#$1600,d1
	mulu.w	d1,d0
	moveq	#0,d2
	move.b	(_num,pc),d2
	bsr.w	_diskload
	movem.l	(sp)+,d0-d7/a0-a6
	adda.w	#$1600,a0
	clr.w	($4072).w
	rts

_patchmain	

	lea	($2384).w,a0
	move.w	#$1A,d0
.copyskip	move.w	#$6004,(a0)+
	dbra	d0,.copyskip
	lea	($193E).w,a0
	move.w	#$F8,d0
.copyrts	move.w	#$4E75,(a0)+
	dbra	d0,.copyrts
	
	suba.l	a1,a1
	lea		pl_bsw_v1(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	
	suba.l	a1,a1
	bra.w	patch_intrts

_blitwait_1
	bsr		_waitblit
	MOVE.L	D0,64(A6)		;21d6: 2d400040
	MOVE.W	#$0041,88(A6)		;21da: 3d7c00410058
	rts

_waitblit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
	
_loadhighs_v1	movem.l	d0-d7/a0-a6,-(sp)
	move.l	a0,-(sp)
	lea	(_highs,pc),a0
	movea.l	(_resload,pc),a2
	jsr	(resload_GetFileSize,a2)
	movea.l	(sp)+,a1
	cmp.l	#$80,d0
	bne.b	.no
	lea	(_highs,pc),a0
	adda.l	#$20840,a1
	movea.l	(_resload,pc),a2
	jsr	(resload_LoadFile,a2)
.no	movem.l	(sp)+,d0-d7/a0-a6
	rts

_normalgame_v2	jsr	($61BE).w
	lea	($864).w,a0
	move.l	#$2200,d0
	move.l	#$3000,d1
	moveq	#1,d2
	bsr.w	_diskload
	bsr.w	_patchmain_v2
	jsr	($86C).w
	jsr	($898).w
	; scan memory chunks
	lea	EXPMEM_LIST_ADDRESS,a0
.search	move.l	(a0),d0
	beq.b	.found
	addq.l	#8,a0
	bra.b	.search

.found	subq.l	#8,a0
	lea	(_long,pc),a1
	move.l	(a0),(a1)
	move.l	#$3864,d3
	lea	(CODE.MSG,pc),a0
	move.l	a0,d1
	move.l	(_long,pc),d2
	jsr	($8B0).w
	
	movea.l	(_long,pc),a1
	lea		pl_prog_v2(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	bsr.w	_loadhighs_v2
	; start game
	move.l	(_long,pc),-(a7)
	rts
	

pl_prog_v3
	PL_START
	; enable dma at the right time (not too soon else display is trashed)
	PL_P	$27d68,enable_dma
	; return "active" dmacon value even if real dmacon value is "down"
	; (when restoring "system" dmacon)
	PL_PS	$06d96,get_system_dmacon
	;PL_PSS	$06c90,save_system_registers_hook,2
	
	; load sound in chipmem
	PL_L	$2a4be,$4EB80120
	
	; version with executable (runs from HD) is
	; poorly done, and has a big CHIP section to make
	; sure that the game crawls on accelerated amigas...
	; relocate copperlists to chip when using fast for code
    PL_L	$27c86+2,$1010
    PL_L	$27d90+2,$1010
    PL_L	$27f54+2,$1010

    PL_L	$27c94+2,$1800
    PL_L	$27f5e+2,$1800
    PL_L	$27d9a+2,$1800
 		
	; fix access fault
	;;PL_PS	$13bf8,_avoid_af
	; uncomment => no intro music
	;PL_R	$2d1fe
	
	; skip manual protection
	PL_B	$09bbe,$60

	; skip exec.disable & enable
	PL_S	$90,8
	PL_S	$A8,8
	; skip cpu detection, assuming 68000
	PL_S	$2eb0e,$6c-$0e	
	; quit to os
	PL_P	$2e510,_abort_ok
	
	; PL_R	$2d1fe ; to skip intro
	; disk I/O
	PL_P	$2e8f0,open_file_read
	PL_P	$2e924,open_file_write
	PL_PS	$2e968,read_file_hook
	PL_S	$2e96e,$10	; skip and store nb bytes read
	PL_P	$2e9b0,write_file
	
	; various os calls which need to be removed
	PL_R	$2e8ce	; close_dos_library
	PL_R	$2e98a
	PL_R	$2e872	; open dos library
	PL_R	$2e612
	PL_R	$2e624
	PL_R	$2e5b2	; skip wb startup & bogus dos calls
	; os calls that should not be reached
	PL_I	$2e65c
	
	PL_PS	$06f8e,_keyboard
	
	; patches reloc at startup
	PL_PS	$0cc30,_reloc_loop
	PL_S	$0cc30+6,$ac-$94
	
	; jotd: added fixes for SMC
	; (else as cpu detection has been fixed as 68000,
	; game crashes)
	PL_P	$2ebbe,_flushcache_trap
	; flush cache after reading THREEDEE.BIN code file
	PL_S	$2ef2a,$48-$2a
	PL_P	$2ef4a,_flushcache
	
	; flush smc to avoid alien-like text
	; when key is pressed (text display speedup)
	PL_PS	$7f8e,_char_smc

	; dma sound loops
	PL_PSS	$2d586,_sound_wait,2
	PL_PSS	$2d59c,_sound_wait,2
	PL_PSS	$2dcce,_sound_wait,2
	PL_PSS	$2dce4,_sound_wait,2

	; fixes sound
	PL_PS	$26e50,_sound_wait_2
	PL_S	$26e56,$f4-$e4

	PL_END
	
pl_prog_v1
	PL_START
	PL_PS	$2C,_copypatch
	PL_PS	$5FCE,_keyboard
	PL_W	$9152,$602E
	PL_PS	$9192,_patch_num
	PL_W	$9198,$60A6
	
	; jotd: added fixes
	
	; more classic way of handling interrupts
	PL_W	$5e3e+2,$0000
	PL_W	$5e4a+2,$0020
	PL_W	$5e52+2,$8000
	PL_W	$5e5c+2,$0000
	PL_W	$5e6c+2,$8000
	
	; super fast text
	;PL_NOP	$1ec16,4
	
	; flush smc to avoid alien-like text
	; when key is pressed (text display speedup)
	; smc is right after that @exp+$6f54 written
	; from @exp+6e94
	PL_PS	$6f4e,_char_smc
		
	; forces different vectors for cache handling
	; (disable, enable, flush)
	;;PL_NOP	$5cb2,2
	
	; patch cache traps
	;PL_P	$5cfc,_enablecache_trap
	;PL_P	$5d0c,_disablecache_trap
	;PL_P	$5D18,_flushcache_trap
	
	; "remove trap" 68000 vector replaced by a flush
	; all operations (set/disable/flush cache) just flush
	; cache (even if I leave enable/disable alone by reenabling
	; the 68020 vectors above, the text is still garbled without
	; manual smc fix
	PL_P	$5cec,_flushcache_trap

	; fixes sound
	PL_PS	$254de,_sound_wait_2
	PL_S	$254e4,$f2-$e4

	; patches reloc at startup
	PL_PS	$ba8e,_reloc_loop
	PL_S	$ba8e+6,$ac-$94

	; dma sound loops
	PL_PSS	$290fa,_sound_wait,2
	PL_PSS	$29110,_sound_wait,2
	PL_PSS	$29842,_sound_wait,2
	PL_PSS	$29858,_sound_wait,2
	
	; CACR writes
;	PL_I	$5CFC
;	PL_I	$5D0C
;	PL_I	$5d18
	PL_END
	
pl_prog_v2
	PL_START
	PL_PS	$2C,_copypatch_v2
	PL_PS	$6022,_keyboard
	PL_W	$91A2,$602E
	PL_PS	$91E2,_patch_num
	PL_W	$91E8,$60A6
	
	; jotd: added fixes for SMC
	; (else as cpu detection has been fixed as 68000,
	; game crashes)
	PL_P	$5cf2,_flushcache_trap
	
	; patches reloc at startup (not really necessary)
	PL_PS	$bada,_reloc_loop
	PL_S	$bada+6,$ac-$94

	; flush smc to avoid alien-like text
	; when key is pressed (text display speedup)
	PL_PS	$6fa2,_char_smc

	; dma sound loops
	PL_PSS	$291c4,_sound_wait,2
	PL_PSS	$291da,_sound_wait,2
	PL_PSS	$2990c,_sound_wait,2
	PL_PSS	$29922,_sound_wait,2

	PL_END
	
_avoid_af
	cmp.l	#CHIPMEMSIZE,a0
	bcc.b	.skip	; bogus address
	MOVEM.L	24(A0),D0-D2
	rts
.skip
	; bogus: next value
	move.w	#$F00,$DFF180
	add.l	#$c14-$bfe,(a7)
	rts
	
get_system_dmacon
	move.w	#$83C0,d0
	rts

save_system_registers_hook
	move.w	#$7FFF,_custom+intena
	move.w	#$83C0,_custom+dmacon
	rts
	
enable_dma
	; enable dma (else black screen)
	; not at start else screen is trashed before ocean logo
	move.w	#$83C0,_custom+dmacon
	MOVE.L	(A7)+,_custom+cop1lc
	rts
.counter
	dc.l	0
		
_char_smc
	; original
	ANDI.W	#$003f,D0		;86f4e: 0240003f
	ADD.W	D0,D0			;86f52: d040
	bra		_flushcache
	
	
_sound_wait_2
	move.w  d0,-(a7)
	move.w	#2,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
	rts
	
_sound_wait
	move.w  d0,-(a7)
	move.w	#4,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
	rts 
	
_setexp_v2	
	lea	EXPMEM_LIST_ADDRESS,a0
	move.l	_expmem(pc),d0
	move.l	d0,(a0)
	jsr	($CC8).w
	jmp	($CD6).w

_copypatch_v2
	move.b	(a0)+,(a1)+
	dbra	d0,_copypatch_v2
	bra.w	_patchmain_v2

_copydata_v2	movem.l	d0/a0/a1,-(sp)
	lea	(_data_v2,pc),a1
	move.w	#$1FF,d0
.copy	move.l	(a1)+,(a0)+
	dbra	d0,.copy
	movem.l	(sp)+,d0/a0/a1
	st	d0
	rts

_loadnum_v2	
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d0,($199A).w
	move.w	#$20,($19A0).w
	move.l	#$1600,d1
	mulu.w	d1,d0
	moveq	#0,d2
	move.b	(_num,pc),d2
	bsr.w	_diskload
	movem.l	(sp)+,d0-d7/a0-a6
	adda.w	#$1600,a0
	clr.w	($4072).w
	rts

_patchmain_v2
	lea	($249A).w,a0
	move.w	#10,d0
.copyskip	move.w	#$6004,(a0)+
	dbra	d0,.copyskip
	lea	($1A54).w,a0
	move.w	#$F8,d0
.copyrts	move.w	#$4E75,(a0)+
	dbra	d0,.copyrts
	sub.l	a1,a1
	move.l	_resload(pc),a2
	lea		pl_bsw_v2(pc),a0
	jsr		resload_Patch(a2)
	
	movea.w	#$14A,a1	
patch_intrts
	lea		pl_intrts(pc),a0
	move.l	_resload(pc),a2
	jmp		resload_Patch(a2)


pl_bsw_v1
	PL_START
	PL_NOP	$18BA,2
	PL_P	$B06,_setexp_v1
	PL_P	$1B30,_loadnum
	PL_P	$902,_copydata
	PL_W	$2338,$603E
	PL_P	$1D80,_savehighs
	
	; snoop/blitter bugs
	PL_S	$22B0,$10
	PL_PSS	$21d6,_blitwait_1,4
	PL_END
	
pl_bsw_v2
	PL_START
	PL_NOP	$19CE,2
	PL_P	$B84,_setexp_v2
	PL_P	$1C46,_loadnum_v2
	PL_P	$90A,_copydata_v2
	PL_W	$244E,$603E
	PL_P	$1E96,_savehighs
	
	; snoop/blitter bugs
	PL_S	$23c6,$10
	PL_PSS	$22ec,_blitwait_1,4
	
	; another checksum
	PL_B	$0ac4,$60
	PL_END
	
pl_intrts
	PL_START
	PL_PSS	$2486,_intrts1,2
	PL_PSS	$2498,_intrts2,2
	PL_PSS	$24A4,_intrts4,2
	PL_PSS	$24BE,_intrts8,2
	PL_PSS	$24CA,_intrts8,2
	PL_PSS	$24F0,_intrts40,2
	PL_PSS	$2500,_intrts20,2
	PL_PSS	$2514,_intrts10,2
	PL_PSS	$2544,_intrts800,2
	PL_PSS	$2550,_intrts1000,2
	PL_PSS	$2576,_intrts2000,2
	PL_PSS	$2582,_intrts2000,2
	PL_PSS	$258E,_intrts4000,2
	PL_END
	
_reloc_loop
.lb_0491:
	ADDA.L	D1,A0			;8ba8e: d1c1
	MOVE.L	(A0),D4			;8ba90: 2810
	SUB.L	D5,D4			;8ba92: 9885
	BPL.S	.lb_0492		;8ba94: 6a06
	MOVE.L	4(A2,D4.W),D4		;8ba96: 28324004
	BRA.S	.lb_0493		;8ba9a: 6002
.lb_0492:
	ADD.L	D0,D4			;8ba9c: d880
.lb_0493:
	; changes some jumps dynamically (at start)
	MOVE.L	D4,(A0)			;8ba9e: 2084
.lb_0494:
	MOVE.B	(A1)+,D1		;8baa0: 1219
	CMP.B	D2,D1			;8baa2: b202
	BHI.S	.lb_0491		;8baa4: 62e8
	LEA	254(A0),A0		;8baa6: 41e800fe
	BEQ.S	.lb_0494		;8baaa: 67f4
	bra		_flushcache

	
_loadhighs_v2	movem.l	d0-d7/a0-a6,-(sp)
	move.l	a0,-(sp)
	lea	(_highs,pc),a0
	movea.l	(_resload,pc),a2
	jsr	(resload_GetFileSize,a2)
	movea.l	(sp)+,a1
	cmp.l	#$80,d0
	bne.b	.no
	lea	(_highs,pc),a0
	adda.l	#$208F0,a1
	movea.l	(_resload,pc),a2
	jsr	(resload_LoadFile,a2)
.no	movem.l	(sp)+,d0-d7/a0-a6
	rts

_patch_num	movem.l	d0/a0,-(sp)
	move.b	(a0),d0
	beq.b	.eq
	andi.w	#15,d0
	lea	(_num,pc),a0
	move.b	d0,(a0)
.eq	movem.l	(sp)+,d0/a0
	rts

_keyboard	moveq	#0,d2
	move.b	(ciasdr,a1),d2
	move.l	d2,-(sp)
	not.b	d2
	ror.b	#1,d2
	cmp.b	(_keyexit,pc),d2
	beq.w	_abort_ok
	move.l	(sp)+,d2
	rts

_intrts1	moveq	#1,d0
	bra.b	_intrts

_intrts2	moveq	#2,d0
	bra.b	_intrts

_intrts4	moveq	#4,d0
	bra.b	_intrts

_intrts8	moveq	#8,d0
	bra.b	_intrts

_intrts10	moveq	#$10,d0
	bra.b	_intrts

_intrts20	moveq	#$20,d0
	bra.b	_intrts

_intrts40	moveq	#$40,d0
	bra.b	_intrts

_intrts800	move.w	#$800,d0
	bra.b	_intrts

_intrts1000	move.w	#$1000,d0
	bra.b	_intrts

_intrts2000	move.w	#$2000,d0
	bra.b	_intrts

_intrts4000	move.w	#$4000,d0
_intrts	move.w	d0,($DFF09C).l
	move.w	d0,($DFF09C).l
	nop
	nop
	rts

_diskload	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	(_resload,pc),a2
	jsr	(resload_DiskLoad,a2)
	movem.l	(sp)+,d0-d7/a0-a6
	rts

_savehighs	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	a0,a1
	addq.l	#2,a1
	moveq	#$7F,d0
	addq.l	#1,d0
	lea	(_highs,pc),a0
	movea.l	(_resload,pc),a2
	jsr	(resload_SaveFile,a2)
	movem.l	(sp)+,d0-d7/a0-a6
	moveq	#0,d2
	rts

_abort_ok	move.l	#TDREASON_OK,-(sp)
	movea.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)

_flushcache	move.l	a2,-(a7)
		move.l	_resload(pc),a2
		jsr	(resload_FlushCache,a2)
		move.l	(a7)+,a2
		rts

getlonglittle	
		move.b	(a0)+,d7
		ror.l	#8,d7
		move.b	(a0)+,d7
		ror.l	#8,d7
		move.b	(a0)+,d7
		ror.l	#8,d7
		move.b	(a0)+,d7
		ror.l	#8,d7
		rts

; a0=src a1=dst

_decrunch	moveq	#0,d2
	movea.l	a1,a2
	lea	(getbits,pc),a3
	lea	($1FE,a0),a4
	lea	(.6C6,pc),a5
	bsr.b	getlonglittle
	cmpi.l	#'RUSS',d7
	bne.w	jr_decrunch
	bsr.b	getlonglittle
	move.l	d7,-(sp)
	adda.l	d7,a1
	move.l	a1,-(sp)
	bsr.b	getlonglittle
	movea.l	d7,a6
	jsr	(a3)
	bcs.w	.6A4
.644	jsr	(a5)
	move.w	d0,d2
	move.w	d0,d3
	subq.w	#1,d2
.64C	clr.w	d0
	add.l	d7,d7
	bne.b	.654
	jsr	(a3)
.654	addx.w	d0,d0
	add.l	d7,d7
	bne.b	.65C
	jsr	(a3)
.65C	addx.w	d0,d0
	add.l	d7,d7
	bne.b	.664
	jsr	(a3)
.664	addx.w	d0,d0
	add.l	d7,d7
	bne.b	.66C
	jsr	(a3)
.66C	addx.w	d0,d0
	add.l	d7,d7
	bne.b	.674
	jsr	(a3)
.674	addx.w	d0,d0
	add.l	d7,d7
	bne.b	.67C
	jsr	(a3)
.67C	addx.w	d0,d0
	add.l	d7,d7
	bne.b	.684
	jsr	(a3)
.684	addx.w	d0,d0
	add.l	d7,d7
	bne.b	.68C
	jsr	(a3)
.68C	addx.w	d0,d0
	move.b	d0,-(a1)
	dbra	d2,.64C
	cmpa.l	a2,a1
	ble.b	.6BA
	not.w	d3
	bne.b	.6A4
.69C	add.l	d7,d7
	bne.b	.6A2
	jsr	(a3)
.6A2	bcc.b	.644
.6A4	jsr	(a5)
	move.w	d0,d2
	jsr	(a5)
	move.w	d0,d3
	addq.w	#2,d3
.6AE	move.b	(-1,a1,d2.l),-(a1)
	dbra	d3,.6AE
	cmpa.l	a2,a1
	bgt.b	.69C
.6BA	move.l	a6,d0
	bne.w	_illegal
	movea.l	(sp)+,a0
	move.l	(sp)+,d0
	rts

.6C6	clr.w	d0
	clr.w	d1
	add.l	d7,d7
	bne.b	.6D0
	jsr	(a3)
.6D0	addx.w	d1,d1
	add.l	d7,d7
	bne.b	.6D8
	jsr	(a3)
.6D8	addx.w	d1,d1
	addq.w	#1,d1
	add.w	d1,d1
	add.w	d1,d1
	subq.w	#1,d1
.6E2	add.l	d7,d7
	bne.b	.6E8
	jsr	(a3)
.6E8	addx.w	d0,d0
	dbra	d1,.6E2
	rts

getbits	bsr.w	getlonglittle
	not.l	d7
	suba.l	d7,a6
	ori.b	#$10,ccr
	addx.l	d7,d7
	rts

_illegal	illegal

jr_decrunch	cmpi.w	#'RJ',d7
		bne.b	_illegal
		move.b	(a0)+,d0
		lsl.l	#8,d0
		move.b	(a0)+,d0
		lsl.l	#8,d0
		move.b	(a0)+,d0
		lsl.l	#8,d0
		move.b	(a0)+,d0	;uncompressed size
		move.l	d0,-(sp)
		movea.l	a0,a5
;		adda.l	#$F4240,a0
;		lea	(_illegal).l,a4
		moveq	#-$80,d7
		bsr.w	.start
		move.l	(sp)+,d0
		rts

JRGB	MACRO
	add.b	d7,d7
	bne.b	.1\@
	move.b	(a5)+,d7
	addx.b	d7,d7
;	move.w	sr,d4
;	cmpa.l	a0,a5
;	bne.b	.774
;	jsr	(a4)
;.774	move.w	d4,sr
.1\@
	ENDM

.760	lsr.w	#1,d6
	subq.w	#1,d6
.764	JRGB
	addx.w	d5,d5
	dbra	d6,.764
	moveq	#3,d6
	add.w	d5,d6
	add.w	d6,d6
	subq.w	#1,d6
.784	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	dbra	d6,.784
	bra.w	.a5ok2

.17A0	JRGB
	addx.w	d6,d6
	JRGB
	bcc.b	.7E6
	subq.w	#1,d6
	JRGB
	addx.w	d6,d6
	cmpi.b	#9,d6
	beq.w	.760
.7E6	JRGB
	bcc.b	.83E
	JRGB
	addx.w	d5,d5
	JRGB
	bcs.w	.8DE
	tst.w	d5
	bne.b	.83E
	addq.w	#1,d5
.82A	JRGB
	addx.w	d5,d5
.83E	rol.w	#8,d5
	move.b	(a5)+,d5
	movea.l	a1,a2
	suba.w	d5,a2
	subq.w	#1,a2
	subq.w	#1,d6
.850	move.b	(a2)+,(a1)+
	dbra	d6,.850
	bra.b	.a5ok2

.start	JRGB
	bcs.b	.1888
.86C	move.b	(a5)+,(a1)+
.a5ok2	JRGB
	bcc.b	.86C
.1888	moveq	#2,d6
	moveq	#0,d5
	JRGB
	bcc.w	.17A0
	JRGB
	bcc.b	.83E
	addq.w	#1,d6
	JRGB
	bcc.w	.7E6
	move.b	(a5)+,d6
	beq.b	.910
	addq.w	#8,d6
	bra.w	.7E6

.8DE	JRGB
	addx.w	d5,d5
	ori.w	#4,d5
	JRGB
	bcs.w	.83E
	bra.w	.82A

.910	rts

; < D1: filename

open_file_read
	MOVEM.L	D0-D7/A0-A6,-(A7)
	lea		current_file_name(pc),a0
	move.l	d1,(a0)
	move.l	d1,a0
	move.l	_resload(pc),a2
	jsr		resload_GetFileSize(a2)
	lea		current_file_size(pc),a0
	move.l	d0,(a0)
	lea		current_file_position(pc),a0
	clr.l	(a0)
	MOVEM.L	(A7)+,D0-D7/A0-A6
	RTS
	
open_file_write
	MOVEM.L	D0-D7/A0-A6,-(A7)
	lea		current_file_name(pc),a0
	move.l	d1,(a0)
	lea		current_file_size(pc),a0
	clr.l	(a0)
	lea		current_file_position(pc),a0
	clr.l	(a0)
	MOVEM.L	(A7)+,D0-D7/A0-A6
	RTS
	
; < D2: buffer
; < D3: length
; > D0: nb bytes read
read_file_hook
	move.l	_resload(pc),a2
;   success,error = resload_LoadFileOffset(size, offset, name, address)
      ;    D0     D1                         D0     D1     A0      A1
	lea	current_file_position(pc),a3
	move.l	(a3),d1
	move.l	d3,d4
	add.l	d1,d4
	cmp.l	current_file_size(pc),d4
	bcs.b	.ok
	; adjust to match end of file
	move.l	current_file_size(pc),d3
	sub.l	d1,d3
.ok
	move.l	d3,d0
	move.l	d2,a1
	move.l	current_file_name(pc),a0
	jsr	resload_LoadFileOffset(a2)
	add.l	d3,(a3)
	move.l	d3,d0	; size read
	RTS				;2e922: 4e75
; < D2: buffer
; < D3: length
write_file
	MOVEM.L	D0-D7/A0-A6,-(A7)
	move.l	d3,d0
	lea	current_file_position(pc),a3
	move.l	(a3),d1
	move.l	_resload(pc),a2
	move.l	d2,a1
	move.l	current_file_name(pc),a0	
	jsr	resload_SaveFileOffset(a2)
	add.l	d3,(a3)
	MOVEM.L	(A7)+,D0-D7/A0-A6	;2e91e: 4cdf7fff
	RTS				;2e922: 4e75


    ; AllocMem/AvailMem emulation. No need to go full kickemu
    ; since the game never frees the memory it allocates,
    ; making implementation of AllocMem & AvailMem (almost)
    ; trivial. Well, I have added fastmem support to OSEmu so
    ; I can assure you that is trivial in comparison!
    
fake_allocmem
    
    move.l  d2,-(a7)
    move.l  d1,d2
    and.l   #MEMF_CHIP+MEMF_FAST,d2 ; keep only those
    btst    #MEMB_CHIP,d2
    beq.b   .fast
.chip
    lea free_chipmem(pc),a0
    bra.b .alloc
.fast
	; not reached here, program only allocates chipmem
    lea free_fastmem(pc),a0
.alloc
    ; round size on 4 bytes
    move.l  d0,d1
    and.b   #$FC,d1
    cmp.b   d0,d1
    beq.b   .aligned
    addq.l  #4,d1
    move.l  d1,d0       ; new size rounded on 4 bytes
.aligned
    ; get available memory
    move.l  (4,a0),d1
    sub.l   (a0),d1
    cmp.l   d0,d1
    bcs.b   .not_enough
    ; enough memory available, allocate
    move.l  d0,d1   ; size
    move.l  (a0),d0 ; address
    add.l   d1,(a0) ; update memory start

    IFEQ    1
    ; temp compute free memory
    lea free_chipmem(pc),a0
    move.l  (4,a0),$100
    move.l  (a0),d2
    sub.l   d2,$100
    lea free_fastmem(pc),a0
    move.l  (4,a0),$104
    move.l  (a0),d2
    sub.l  d2,$104
    ENDC
    

    move.l  (a7)+,d2
    

    tst.l   d0
    rts
    
.not_enough
    tst.l   d2
    bne.b   .out
    ; no particular memory required: perform a second pass
    ; with chipmem
    move.l  #MEMF_CHIP,d2
    bra   .chip
.out
    moveq.l #0,d0
    move.l  (a7)+,d2
    rts

    
    ; we're ignoring MEMF_LARGEST, assuming free memory is all contiguous
fake_availmem
    btst    #MEMB_CHIP,d1
    beq.b   .fast
    lea free_chipmem(pc),a0
    bra.b .calc
.fast
    lea free_fastmem(pc),a0
.calc
    move.l  (4,a0),d0
    sub.l   (a0),d0
    rts

free_chipmem:
    dc.l    CHIPMEMSTART   ; start
    dc.l    CHIPMEMSIZE-CHIPMEMSTART

    ; initialized dynamically at startup
free_fastmem
    dc.l    0   ; start
    dc.l    0   ; top


_data_v1	dc.l	$77E
	dc.l	$11000C
	dc.l	$30003
	dc.l	$30009
	dc.l	$30003
	dc.l	$20003
	dc.l	$328D5
	dc.l	$500E3
	dc.l	$40004
	dc.l	$40003
	dc.l	$2000B
	dc.l	$700002
	dc.l	$3000A
	dc.l	$280003
	dc.l	$5000F
	dc.l	$140030
	dc.l	$570004
	dc.l	$20008
	dc.l	$40004
	dc.l	$40004
	dc.l	$30004
	dc.l	$40004
	dc.l	$30004
	dc.l	$40004
	dc.l	$40004
	dc.l	$40003
	dc.l	$27C000C
	dc.l	$40016
	dc.l	$40004
	dc.l	$4002F
	dc.l	$30006
	dc.l	$370003
	dc.l	$40004
	dc.l	$40004
	dc.l	$50003
	dc.l	$C0004
	dc.l	$40015
	dc.l	$250014
	dc.l	$10000A
	dc.l	$90003
	dc.l	$30006
	dc.l	$30003
	dc.l	$70008
	dc.l	$30005
	dc.l	$B005F
	dc.l	$21002C
	dc.l	$3000A
	dc.l	$30108
	dc.l	$5000C
	dc.l	$40004
	dc.l	$40007
	dc.l	$30003
	dc.l	$30003
	dc.l	$30006
	dc.l	$30003
	dc.l	$30002
	dc.l	$30002
	dc.l	$90003
	dc.l	$70003
	dc.l	$50003
	dc.l	$30006
	dc.l	$30006
	dc.l	$90005
	dc.l	$30003
	dc.l	$80005
	dc.l	$40006
	dc.l	$60005
	dc.l	$30003
	dc.l	$3000B
	dc.l	$30008
	dc.l	$50004
	dc.l	$60006
	dc.l	$50003
	dc.l	$30003
	dc.l	$11000C
	dc.l	$60004
	dc.l	$50003
	dc.l	$50003
	dc.l	$70005
	dc.l	$50004
	dc.l	$70007
	dc.l	$70007
	dc.l	$70053
	dc.l	$A0049
	dc.l	$120013
	dc.l	$500C3
	dc.l	$84002D
	dc.l	$C30032
	dc.l	$560003
	dc.l	$780006
	dc.l	$520003
	dc.l	$180002
	dc.l	$50003
	dc.l	$20005
	dc.l	$20005
	dc.l	$30002
	dc.l	$A0003
	dc.l	$30003
	dc.l	$60010
	dc.l	$60004
	dc.l	$280521
	dc.l	$30004
	dc.l	$30008
	dc.l	$70004
	dc.l	$4101C3
	dc.l	$30003
	dc.l	$50005
	dc.l	$910005
	dc.l	$40005
	dc.l	$40003
	dc.l	$20003
	dc.l	$80004
	dc.l	$70003
	dc.l	$3000B
	dc.l	$50011
	dc.l	$40005
	dc.l	$B50003
	dc.l	$30003
	dc.l	$30007
	dc.l	$90004
	dc.l	$30003
	dc.l	$40003
	dc.l	$20003
	dc.l	$20003
	dc.l	$50005
	dc.l	$40002
	dc.l	$30002
	dc.l	$30003
	dc.l	$30004
	dc.l	$30005
	dc.l	$3005D
	dc.l	$110003
	dc.l	$90003
	dc.l	$20003
	dc.l	$20003
	dc.l	$50003
	dc.l	$50010
	dc.l	$70003
	dc.l	$F0005
	dc.l	$60005
	dc.l	$90004
	dc.l	$30009
	dc.l	$40006
	dc.l	$40003
	dc.l	$60008
	dc.l	$F0004
	dc.l	$50005
	dc.l	$30012
	dc.l	$30006
	dc.l	$50009
	dc.l	$40003
	dc.l	$90004
	dc.l	$60004
	dc.l	$30005
	dc.l	$30003
	dc.l	$60003
	dc.l	$B0005
	dc.l	$C0008
	dc.l	$150005
	dc.l	$30003
	dc.l	$30004
	dc.l	$50007
	dc.l	$30005
	dc.l	$30003
	dc.l	$30007
	dc.l	$30003
	dc.l	$3000A
	dc.l	$30008
	dc.l	$30004
	dc.l	$80003
	dc.l	$30003
	dc.l	$130007
	dc.l	$30006
	dc.l	$30006
	dc.l	$30002
	dc.l	$30002
	dc.l	$40004
	dc.l	$40004
	dc.l	$40005
	dc.l	$30003
	dc.l	$30008
	dc.l	$80004
	dc.l	$4001C
	dc.l	$30003
	dc.l	$1F003F
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$7D0002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$4D0002
	dc.l	$8B000E
	dc.l	$30003
	dc.l	$70005
	dc.l	$70005
	dc.l	$40003
	dc.l	$30004
	dc.l	$D0003
	dc.l	$B0014
	dc.l	$60005
	dc.l	$50005
	dc.l	$40004
	dc.l	$60005
	dc.l	$70004
	dc.l	$40003
	dc.l	$30003
	dc.l	$30003
	dc.l	$40021
	dc.l	$D0008
	dc.l	$B0013
	dc.l	$F001D
	dc.l	$50007
	dc.l	$30003
	dc.l	$160009
	dc.l	$D0003
	dc.l	$150003
	dc.l	$30011
	dc.l	$50007
	dc.l	$30015
	dc.l	$30003
	dc.l	$3000D
	dc.l	$30003
	dc.l	$30008
	dc.l	$2C0004
	dc.l	$200004
	dc.l	$270013
	dc.l	$14000A
	dc.l	$A0007
	dc.l	$50015
	dc.l	$90003
	dc.l	$30003
	dc.l	$1D0005
	dc.l	$30006
	dc.l	$30003
	dc.l	$870005
	dc.l	$70004
	dc.l	$D0004
	dc.l	$F0003
	dc.l	$60006
	dc.l	$50003
	dc.l	$70006
	dc.l	$4000C
	dc.l	$60004
	dc.l	$70005
	dc.l	$40006
	dc.l	$4000C
	dc.l	$A000C
	dc.l	$70005
	dc.l	$30003
	dc.l	$A000C
	dc.l	$60005
	dc.l	$D0003
	dc.l	$30004
	dc.l	$90003
	dc.l	$3000E
	dc.l	$60008
	dc.l	$40003
	dc.l	$30004
	dc.l	$30003
	dc.l	$6000D
	dc.l	$40004
	dc.l	$60003
	dc.l	$12730003
	dc.l	$3C8CD
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$40002
	dc.l	$20002
	dc.l	$40002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$2A5000F
	dc.l	$50015
	dc.l	$90058
	dc.l	$30008
	dc.l	$30003
	dc.l	$30004
	dc.l	$3007F
	dc.l	$160005
	dc.l	$80005
	dc.l	$80005
	dc.l	$50003
	dc.l	$1110003
	dc.l	$140012
	dc.l	$80009
	dc.l	$B006F
	dc.l	$1C70005
	dc.l	$80003
	dc.l	$30027
	dc.l	$850003
	dc.l	$170003
	dc.l	$70003
	dc.l	$20003
	dc.l	$2006B
	dc.l	$280003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30004
	dc.l	$40008
	dc.l	$7000C
	dc.l	$30004
	dc.l	$20003
	dc.l	$40005
	dc.l	$3000C
	dc.l	$30053
	dc.l	$30006
	dc.l	$30003
	dc.l	$140002
	dc.l	$3C0006
	dc.l	$20002
	dc.l	$1B000A
	dc.l	$B000B
	dc.l	$30003
	dc.l	$190004
	dc.l	$70005
	dc.l	$9003B
	dc.l	$1F001F
	dc.l	$40004
	dc.l	$40005
	dc.l	$E0009
	dc.l	$3005A
	dc.l	$40004
	dc.l	$30006
	dc.l	$40004
	dc.l	$8000C
	dc.l	$50004
	dc.l	$4000C
	dc.l	$60006
	dc.l	$50056
	dc.l	$150003
	dc.l	$6001D
	dc.l	$240037
	dc.l	$D0095
	dc.l	$3003B
	dc.l	$3009B
	dc.l	$3007B
	dc.l	$50005
	dc.l	$190004
	dc.l	$60006
	dc.l	$1D0006
	dc.l	$40007
	dc.l	$40009
	dc.l	$40003
	dc.l	$50009
	dc.l	$E0006
	dc.l	$140003
	dc.l	$C0003
	dc.l	$800ED
	dc.l	$B0006
	dc.l	$40006
	dc.l	$170006
	dc.l	$60006
	dc.l	$50005
	dc.l	$50003
	dc.l	$130003
	dc.l	$60003
	dc.l	$1010003
	dc.l	$190009
	dc.l	$A0008
	dc.l	$20023F
	dc.l	$680006
	dc.l	$7E30003
	dc.l	$60003
	dc.l	$60003
	dc.l	$40003
	dc.l	$60003
	dc.l	$80005
	dc.l	$50005
	dc.l	$50003
	dc.l	$2E0059
	dc.l	$3000B
	dc.l	$18000E
	dc.l	$60007
	dc.l	$36000C
	dc.l	$E000A
	dc.l	$30009
	dc.l	$60004
	dc.l	$730003
	dc.l	$F000B
	dc.l	$A0010
	dc.l	$30003
	dc.l	$1F0003
	dc.l	$30016
	dc.l	$1E0003
	dc.l	$3002A
	dc.l	$1B0021
	dc.l	$210005
	dc.l	$60003
	dc.l	$30005
	dc.l	$30003
	dc.l	$9002B
	dc.l	$30003
	dc.l	$30016
	dc.l	$80003
	dc.l	$F000A
	dc.l	$A000A
	dc.l	$180008
	dc.l	$90009
	dc.l	$900C2
	dc.l	$380003
	dc.l	$40003
	dc.l	$30004
	dc.l	$50003
	dc.l	$40006
	dc.l	$40004
	dc.l	$80003
	dc.l	$30003
	dc.l	$4000A
	dc.l	$30071
	dc.l	$50009
	dc.l	$190006
	dc.l	$90178
	dc.l	$30003
	dc.l	$1E0003
	dc.l	$80003
	dc.l	$870012
	dc.l	$3004D
	dc.l	$C0020
	dc.l	$B000A
	dc.l	$60004
	dc.l	$3C0003
	dc.l	$30005
	dc.l	$30005
	dc.l	$30005
	dc.l	$30005
	dc.l	$F0004
	dc.l	$4FFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$CCCCCCCC
	dc.l	$CCCCCCCC
	dc.l	$CCCCCCCC
	dc.l	$CCCCCCCC
	dc.l	$CCCCCCCC
	dc.l	$CCCCCCCC
_data_v2	dc.l	$78C
	dc.l	$F3810011
	dc.l	$C0003
	dc.l	$30003
	dc.l	$90003
	dc.l	$30002
	dc.l	$30003
	dc.l	$28D50005
	dc.l	$E30004
	dc.l	$40004
	dc.l	$30002
	dc.l	$B0070
	dc.l	$20003
	dc.l	$A0028
	dc.l	$30005
	dc.l	$F0014
	dc.l	$300057
	dc.l	$40002
	dc.l	$80003
	dc.l	$40004
	dc.l	$40004
	dc.l	$30004
	dc.l	$40004
	dc.l	$30004
	dc.l	$40004
	dc.l	$40004
	dc.l	$40003
	dc.l	$27C000C
	dc.l	$40016
	dc.l	$40004
	dc.l	$4002F
	dc.l	$30006
	dc.l	$370003
	dc.l	$40004
	dc.l	$40004
	dc.l	$50003
	dc.l	$C0004
	dc.l	$40015
	dc.l	$250014
	dc.l	$10000A
	dc.l	$90003
	dc.l	$30006
	dc.l	$30003
	dc.l	$70008
	dc.l	$30005
	dc.l	$B0008
	dc.l	$60006
	dc.l	$60006
	dc.l	$60006
	dc.l	$5A0021
	dc.l	$2C0003
	dc.l	$A0003
	dc.l	$1080005
	dc.l	$C0004
	dc.l	$40004
	dc.l	$70003
	dc.l	$30003
	dc.l	$30003
	dc.l	$60003
	dc.l	$30003
	dc.l	$20003
	dc.l	$20009
	dc.l	$30007
	dc.l	$30005
	dc.l	$30003
	dc.l	$60003
	dc.l	$60009
	dc.l	$50003
	dc.l	$30008
	dc.l	$50004
	dc.l	$60006
	dc.l	$50003
	dc.l	$30003
	dc.l	$B0003
	dc.l	$80005
	dc.l	$40006
	dc.l	$60005
	dc.l	$30003
	dc.l	$30011
	dc.l	$C0006
	dc.l	$40005
	dc.l	$30005
	dc.l	$30007
	dc.l	$50005
	dc.l	$40007
	dc.l	$70007
	dc.l	$70007
	dc.l	$53000A
	dc.l	$490012
	dc.l	$130005
	dc.l	$C30084
	dc.l	$2D00C3
	dc.l	$320056
	dc.l	$30078
	dc.l	$60052
	dc.l	$30018
	dc.l	$20005
	dc.l	$30002
	dc.l	$50002
	dc.l	$50003
	dc.l	$2000A
	dc.l	$30003
	dc.l	$30006
	dc.l	$100006
	dc.l	$40028
	dc.l	$5210003
	dc.l	$40003
	dc.l	$80007
	dc.l	$40041
	dc.l	$1C30003
	dc.l	$30005
	dc.l	$50091
	dc.l	$50004
	dc.l	$50004
	dc.l	$30002
	dc.l	$30008
	dc.l	$40007
	dc.l	$30003
	dc.l	$B0005
	dc.l	$110004
	dc.l	$500B5
	dc.l	$30003
	dc.l	$30003
	dc.l	$70009
	dc.l	$40003
	dc.l	$30004
	dc.l	$30002
	dc.l	$30002
	dc.l	$30005
	dc.l	$50004
	dc.l	$20003
	dc.l	$20003
	dc.l	$30003
	dc.l	$40003
	dc.l	$50003
	dc.l	$5D0011
	dc.l	$30009
	dc.l	$30002
	dc.l	$30002
	dc.l	$30005
	dc.l	$30005
	dc.l	$100007
	dc.l	$3000F
	dc.l	$50006
	dc.l	$50009
	dc.l	$40003
	dc.l	$90004
	dc.l	$60004
	dc.l	$30006
	dc.l	$8000F
	dc.l	$40005
	dc.l	$50003
	dc.l	$120003
	dc.l	$60005
	dc.l	$90004
	dc.l	$30009
	dc.l	$40006
	dc.l	$40003
	dc.l	$50003
	dc.l	$30006
	dc.l	$3000B
	dc.l	$5000C
	dc.l	$80015
	dc.l	$50003
	dc.l	$30003
	dc.l	$40005
	dc.l	$70003
	dc.l	$50003
	dc.l	$30003
	dc.l	$70003
	dc.l	$30003
	dc.l	$A0003
	dc.l	$80003
	dc.l	$40008
	dc.l	$30003
	dc.l	$30013
	dc.l	$70003
	dc.l	$60003
	dc.l	$60003
	dc.l	$20003
	dc.l	$20004
	dc.l	$40004
	dc.l	$40004
	dc.l	$50003
	dc.l	$30003
	dc.l	$80008
	dc.l	$40004
	dc.l	$1C0003
	dc.l	$3001F
	dc.l	$3F0003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$7D0002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$4E0002
	dc.l	$8B000E
	dc.l	$30003
	dc.l	$70005
	dc.l	$70005
	dc.l	$40003
	dc.l	$30004
	dc.l	$D0003
	dc.l	$B0014
	dc.l	$60005
	dc.l	$50005
	dc.l	$40004
	dc.l	$60005
	dc.l	$70004
	dc.l	$40003
	dc.l	$30003
	dc.l	$30003
	dc.l	$40021
	dc.l	$D0008
	dc.l	$B0013
	dc.l	$F001D
	dc.l	$50007
	dc.l	$30003
	dc.l	$160009
	dc.l	$D0003
	dc.l	$150003
	dc.l	$30011
	dc.l	$50007
	dc.l	$30015
	dc.l	$30003
	dc.l	$3000D
	dc.l	$30003
	dc.l	$30008
	dc.l	$2C0004
	dc.l	$200004
	dc.l	$270013
	dc.l	$14000A
	dc.l	$A0007
	dc.l	$50015
	dc.l	$90003
	dc.l	$30003
	dc.l	$1D0005
	dc.l	$30006
	dc.l	$30003
	dc.l	$890005
	dc.l	$70004
	dc.l	$D0004
	dc.l	$F0003
	dc.l	$60006
	dc.l	$50003
	dc.l	$70006
	dc.l	$4000C
	dc.l	$60004
	dc.l	$70005
	dc.l	$40006
	dc.l	$4000C
	dc.l	$A000C
	dc.l	$70005
	dc.l	$30003
	dc.l	$A000C
	dc.l	$60005
	dc.l	$D0003
	dc.l	$30004
	dc.l	$90003
	dc.l	$3000E
	dc.l	$60008
	dc.l	$40003
	dc.l	$30004
	dc.l	$30003
	dc.l	$6000D
	dc.l	$40004
	dc.l	$60003
	dc.l	$126F0003
	dc.l	$3C905
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$40002
	dc.l	$20002
	dc.l	$40002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$20002
	dc.l	$2A5000F
	dc.l	$50015
	dc.l	$90057
	dc.l	$30008
	dc.l	$30003
	dc.l	$30004
	dc.l	$30081
	dc.l	$160005
	dc.l	$80005
	dc.l	$80005
	dc.l	$40003
	dc.l	$1110003
	dc.l	$140012
	dc.l	$80009
	dc.l	$B006F
	dc.l	$1C70005
	dc.l	$80003
	dc.l	$30027
	dc.l	$850003
	dc.l	$160003
	dc.l	$70003
	dc.l	$20003
	dc.l	$2006B
	dc.l	$280003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30003
	dc.l	$30004
	dc.l	$40008
	dc.l	$7000C
	dc.l	$30004
	dc.l	$20003
	dc.l	$40005
	dc.l	$3000C
	dc.l	$30053
	dc.l	$30006
	dc.l	$30003
	dc.l	$480006
	dc.l	$20002
	dc.l	$1B000A
	dc.l	$B000B
	dc.l	$30003
	dc.l	$190004
	dc.l	$70005
	dc.l	$9003B
	dc.l	$1F001F
	dc.l	$40004
	dc.l	$40005
	dc.l	$E0009
	dc.l	$3005A
	dc.l	$40004
	dc.l	$30006
	dc.l	$40004
	dc.l	$8000C
	dc.l	$50004
	dc.l	$4000C
	dc.l	$60006
	dc.l	$50056
	dc.l	$150003
	dc.l	$6001D
	dc.l	$240037
	dc.l	$D0095
	dc.l	$3003B
	dc.l	$3009B
	dc.l	$3007B
	dc.l	$50005
	dc.l	$190004
	dc.l	$60006
	dc.l	$1D0006
	dc.l	$40007
	dc.l	$40009
	dc.l	$40003
	dc.l	$50009
	dc.l	$E0006
	dc.l	$140003
	dc.l	$C0003
	dc.l	$800ED
	dc.l	$B0006
	dc.l	$40006
	dc.l	$170006
	dc.l	$60006
	dc.l	$50005
	dc.l	$50003
	dc.l	$130003
	dc.l	$60003
	dc.l	$1010003
	dc.l	$190009
	dc.l	$A0008
	dc.l	$20023F
	dc.l	$680006
	dc.l	$7DF0003
	dc.l	$60003
	dc.l	$60003
	dc.l	$40003
	dc.l	$60003
	dc.l	$80005
	dc.l	$50005
	dc.l	$50003
	dc.l	$2E005A
	dc.l	$30007
	dc.l	$1C000E
	dc.l	$60007
	dc.l	$36000C
	dc.l	$E000A
	dc.l	$30009
	dc.l	$60004
	dc.l	$50003
	dc.l	$800003
	dc.l	$F000B
	dc.l	$A0010
	dc.l	$30003
	dc.l	$1F0003
	dc.l	$30016
	dc.l	$1E0003
	dc.l	$3002A
	dc.l	$1B0021
	dc.l	$210005
	dc.l	$60003
	dc.l	$30005
	dc.l	$30003
	dc.l	$9002B
	dc.l	$30003
	dc.l	$30016
	dc.l	$80003
	dc.l	$F000A
	dc.l	$A000A
	dc.l	$180008
	dc.l	$90009
	dc.l	$900C2
	dc.l	$380003
	dc.l	$40003
	dc.l	$30004
	dc.l	$50003
	dc.l	$40006
	dc.l	$40004
	dc.l	$80003
	dc.l	$30003
	dc.l	$4000A
	dc.l	$30071
	dc.l	$50009
	dc.l	$190006
	dc.l	$90178
	dc.l	$30003
	dc.l	$1E0003
	dc.l	$80003
	dc.l	$870012
	dc.l	$3004D
	dc.l	$C0020
	dc.l	$B000A
	dc.l	$60004
	dc.l	$3C0003
	dc.l	$30005
	dc.l	$30005
	dc.l	$30005
	dc.l	$30005
	dc.l	$F0004
	dc.l	$4FFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	$FFFFFFFF
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0

_tags	dc.l	WHDLTAG_CUSTOM1_GET
_c1	dc.l	0
	dc.l	WHDLTAG_ATTNFLAGS_GET
_attnflags
	dc.l	0
	dc.l	0
_resload	dc.l	0
_long	dc.l	0
current_file_position
	dc.l	0
current_file_size
	dc.l	0
current_file_name
	dc.l	0
sound_buffer
	dc.l	0
main_file_name
	dc.b	"EPIC",0
	end
