
	;;OPT	O+,W-,CHKPC,P=68000

	; WHDLoad slave for Killing Cloud
	; (c) 2001-2002 Halibut Software

	INCDIR	INCLUDE:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;CHIP_ONLY


RELOC_ENABLED = 1
	IFD	RELOC_ENABLED
RELOC_MEM = $30000
	ELSE
RELOC_MEM = 0
	ENDC

;==========================================================================

	IFD	CHIP_ONLY
BASMEM_SIZE	equ	$80000+RELOC_MEM
EXPMEM_SIZE	equ	$8000
	ELSE
BASMEM_SIZE	equ	$80000
EXPMEM_SIZE	equ	$8000+RELOC_MEM
	
	ENDC
;==========================================================================

	; WHDLoad slave header structure

_base:	SLAVE_HEADER		;ws_Security + ws_ID
	dc.w	17	;ws_Version
	dc.w	WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_NoError	;ws_flags
	dc.l	BASMEM_SIZE	;ws__baseMemSize
	dc.l	0	;ws_ExecInstall
	dc.w	_start-_base	;ws_GameLoader
	dc.w	_cwdname-_base	;ws_CurrentDir
	dc.w	0
	dc.b	$58	;ws_keydebug
	dc.b	$59	;ws_keyexit
_expmem:	dc.l	EXPMEM_SIZE	;ws_ExpMem
	dc.w	_wsname-_base	;ws_name
	dc.w	_wscopy-_base	;ws_copy
	dc.w	_wsinfo-_base	;ws_info
	dc.w	0                       ;ws_kickname
	dc.l	0                       ;ws_kicksize
	dc.w	0                       ;ws_kickcrc
	dc.w	_config-_base		;ws_config
_config
	dc.b	"C3:B:enable cpu assisted blitter;"
    dc.b	0

;==========================================================================

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

	dc.b	"$VER: Killing Cloud WHDLoad slave "
	DECL_VERSION
	dc.b	0
	EVEN

;==========================================================================

_start:	bsr	_initialise

	IFD		RELOC_ENABLED
	lea		_reloc_base(pc),a0
	IFD		CHIP_ONLY
	add.l	#$80000,(a0)
	ELSE
	move.l	_expmem(pc),d0
	add.l	d0,(a0)
	ENDC
	ENDC
	
	bsr		check_version
	
	lea	$70000,a0	; load loader
	move.l	a0,-(a7)
	move.l       #$400,d0
	move.l       #$2800,d1
	moveq	#1,d2
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)

	
	lea	.p0_patchlist(pc),a0	; patch loader
	move.l	(a7),a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	rts		; start loader

;-----

.p0_patchlist:
	PL_START
	PL_W	$2,$2000	; keep interrupts enabled
	PL_W	$1a,0
	PL_P	$cc2,_trackload	; patch trackloader
	PL_R	$daa
	PL_PS	$6a,_p0_wait
	PL_P	$110,_p1	; game exec jump
	PL_END

check_version:
	MOVE.L	#VD_DISK_OFS,D0		;440: 203c00021ca0
	MOVE.L	#VD_DISK_LEN,D1		;446: 223c00002c00
	MOVEQ	#1,D2			;44c: 7401
	LEA	VD_DISK_BUF,A0		;44e: 41f900010000
	MOVEA.L	_resload(PC),A2		;454: 247a0192
	MOVEM.L	D1/A0/A2,-(A7)		;458: 48e740a0
	JSR	resload_DiskLoad(A2)			;45c: 4eaa0028
	MOVEM.L	(A7)+,D0/A0/A2		;460: 4cdf0501
	JSR	resload_CRC16(A2)			;464: 4eaa0030
	lea		main_patchlist(pc),a0
	lea		part2_patchlist(pc),a2
	lea		_vd_sfxwait(pc),a3
	lea		version(pc),a4
	cmp.w	#$38a2,d0
	beq.b	version_1
	cmp.w	#$fa18,d0
	beq.b	version_2
	bra	_badver
	
version_1
	lea	pl_main_1(pc),a1
	move.l	a1,(a0)
	lea	p2_patchlist_v1(pc),a1
	move.l	a1,(a2)
	move.l	#$5ba62,(a3)
	move.l	#1,(a4)
	rts
version_2
	lea	pl_main_2(pc),a1
	move.l	a1,(a0)
	lea	p2_patchlist_v2(pc),a1
	move.l	a1,(a2)
	move.l	#$5ba42,(a3)
	move.l	#2,(a4)
	rts
	

;--------------------------------


	; delay to display "vektor grafix" logo

_p0_wait:	jsr	$70166	; fade in logo
	bsr	_fadewait
	moveq	#-1,d0	; back to loader
	rts

;--------------------------------

_p1:	bsr	_fadewait	; finish off loader screen fade
	move.l	_resload(pc),a2
	jsr	$701c6

	movem.l	d0-7/a0-6,-(a7)

	IFD		RELOC_ENABLED
	
	; copy program
	
	move.l	_program_size(pc),d0
	lsr.l	#2,d0
	lea		$1000.W,a0
	move.l	_reloc_base(pc),A1
.copy
	move.l	(a0)+,(a1)+
	subq.l	#1,d0
	bne.b	.copy
	
	; load reloc table
	
	lea	_reloc_table_address(pc),a1
	lea		reloc_file_name_table(pc),a0
	
	move.l	version(pc),D0
	add.l	d0,d0
	add.w	(a0,d0.l),a0	; relative => absolute name
	jsr		resload_LoadFileDecrunch(a2)

	; relocate
	move.l	_reloc_base(pc),a0
	lea		(-$1000,a0),a1	; reloc base -$1000
	move.l	a1,d1
	lea	_reloc_table_address(pc),a1
.reloc
	move.l	(a1)+,d0
	beq.b	.end
	add.l	d1,(a0,d0.l)
	bra.b	.reloc
.end
	; now that we relocated, copy back the lower memory as there are
	; tables in the $1000-$819C zone
	move.l	_reloc_base(pc),a0
	lea		$1000,a1
	move.l	#($819C-$1000)/4,d0
.copy2
	move.l	(a0)+,(a1)+
	dbf		d0,.copy2
	ENDC
	; protect mem: 
	; w 0 $819c $2C600-$819C
	; w 1 $81000 $719C
	
	move.l	_reloc_base(pc),a0
	lea		(-$1000,a0),a1	; reloc base -$1000

	
	move.l	main_patchlist(pc),a0
	jsr		resload_Patch(a2)

	; set CPU and cache options
	IFND	RELOC_ENABLED
	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	resload_SetCPU(a2)
	ENDC
	
	movem.l	(a7)+,d0-7/a0-6
	move.l	_reloc_base(pc),-(a7)
	rts	; start game

;-----

P1PL_TXT1:	MACRO
	PL_NOP	\1,8	; remove smc movem
	PL_W	\2,$4e92	; $4e92=jsr (a2)
	PL_NOP	\2+2,14
	ENDM

pl_main_1
	PL_START
	PL_P	$17972,_tl_setdisk
	PL_PS	$17226,_fadewait	; remove manual protection

	PL_IFC3
	PL_PS	$d1f8,set_blit_custom_base
	PL_PSS	$0d288,do_the_blit_1,2
	PL_PSS	$0d2f4,do_the_blit_2,2
	
	PL_PS	$0c96a,load_table_a4_d4
	PL_PS	$d1ee,load_table_a4_d0
	PL_ENDIF
	
	PL_NEXT		pl_main_common
pl_main_2
	PL_START
	PL_P	$17982,_tl_setdisk
	PL_PS	$17236,_fadewait	; remove manual protection
	PL_NEXT		pl_main_common
	
pl_main_common:
	PL_START
	; fix <$8000 addresses that were accessed PC-relative
	; into short leas (lower part of memory < $81something cannot
	; be relocated because of the short addressing)
	PL_L	$0a364,$4df86c12
	PL_L	$0a3d8,$4df86c12
	PL_L	$0a4a4,$45f86be6
	PL_L	$0a548,$41f86c12
	PL_L	$0a578,$41f86c12
	
	;PL_PSS	$82bc,set_end_program_memory_limits,2
	;PL_S	$082b4,$d2-$b4
	
	PL_W	$81aa,0	; keep interrupts enabled
	PL_P	$9606,_trackload	; patch trackloader
	;PL_VDNOP	_vd_manprot,6

	PL_PS	$c27c,_txt1_setrender	; patch text printing smc
	P1PL_TXT1	$c28e,$c2a6
	P1PL_TXT1	$c2c2,$c2e0
	P1PL_TXT1	$c2ca,$c2f8
	P1PL_TXT1	$c31c,$c342
	P1PL_TXT1	$c324,$c362
	P1PL_TXT1	$c37e,$c3aa
	P1PL_TXT1	$c386,$c3ca
	PL_PSS	$c414,_txt2_setrender,26
	PL_PSS	$c448,_txt2_render,10

	PL_PSS	$c938,_smc1_setrender,10	; patch line drawing smc
	PL_P	$ca2e,_smc1_rendera
	PL_P	$cc46,_smc1_renderb

	PL_END

load_table_a4_d0:
	bsr.b	load_table_a4
	ADD.W	D0,D0			;0c96e: d844
	rts
load_table_a4_d4:
	bsr.b	load_table_a4
	ADD.W	D4,D4			;0c96e: d844
	rts
	
load_table_a4
	LEA	$18e8.W,A4		;0c96a: 49f818e8
	move.w	d0,-(a7)
	move.b	blitter_active(pc),d0
	bne.b	.real_blitter
	add.l	_reloc_base(pc),a4
	sub.w	#$1000,a4
.real_blitter
	move.w	(a7)+,d0
	rts
	
set_blit_custom_base
	lea		blitter_active(pc),a5
	eor.b	#1,(a5)		; toggle
	beq.b	.real
	; cpu
	lea		blitter_struct(pc),a5
	rts
.real
	lea		_custom,a5
	rts
	
blitter_active:
	dc.w	0
blitter_struct
	ds.b	BlitterState_SIZEOF,0
	
do_the_blit_1
	MOVE.W	D0,bltdmod(A5)		;0d288: 3b400066
	; main blit of most 3D (filled polygons)
	; without that write, only cockpit and bitmaps are displayed
	; nothing is filled or erased,
	; only lines appear on the display
	bra.b	do_the_blit_end


do_the_blit_2
	MOVE.L	A1,bltdpt(A5)		;0d2f4: 2b490054
	
do_the_blit_end
	MOVE.W	D4,bltsize(A5)		;0d2f8: 3b440058
	cmp.l	#_custom,a5
	beq.b	.out	; real blit
	exg.l	a5,a0
	bsr		blt_wait
	exg.l	a0,a5
.out
	rts


	include	K:\jff\AmigaHD\PROJETS\GameRelocs\utils\cpu_blitter.s
	
;set_end_program_memory_limits
;	MOVEA.L	$01006.W,A0		;082bc: 20781006	; after this program
;	sub.l	_reloc_base(pc),a0
;	lea		($1000,a0),a0
;	MOVE.L	$0100a.W,D0		;082c0: 2038100a
;	rts
	
;--------------------------------

_p2:	movem.l	d0-7/a0-6,-(a7)

	move.l	_vd_sfxwait(pc),a0	; do we need to patch?
	cmp.l	#$51c8fffe,4(a0)
	bne.s	.p2_done

	move.l	part2_patchlist(pc),a0	; apply patches
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)

.p2_done:	movem.l	(a7)+,d0-7/a0-6
	rts

;-----

_vd_sfxwait
	dc.l	0
	
p2_patchlist_v1:
	PL_START
	PL_P	$5ba62,_sfxwait	; patch dbf delay loop
	PL_END

p2_patchlist_v2:
	PL_START
	PL_P	$5ba42,_sfxwait	; patch dbf delay loop
	PL_END

;--------------------------------

	dc.b	"tell me why you always do those crayzy things that you do",0
	EVEN

;--------------------------------


_smc1_setrender:
	movem.l	d4/a0-1,-(a7)	; set smc1 rendering for colour d4

	lea	_smc1_rendertab(pc),a0
	lea	_smc1_renderptra(pc),a1
	and.w	#15,d4
	asl.w	#2,d4

	move.l	0(a0,d4.w),(a1)+
	move.l	16*4(a0,d4.w),(a1)+

	movem.l	(a7)+,d4/a0-1
	rts

;----------

_smc1_rendera:
	move.l	_smc1_renderptra(pc),-(a7)
	rts

_smc1_renderb:
	move.l	_smc1_renderptrb(pc),-(a7)
	rts

;----------

_smc1_rendertab:
	ds.l	32
	
_smc1_renderptra:
	dc.l	0
_smc1_renderptrb:
	dc.l	0

_smc1_rendercode:
	INCBIN	smc1.RNC
	EVEN

;--------------------------------

_txt1_setrender:
	cmp.w	#$4e75,14(a0)
	beq.s	.t1sr_tableok

	movem.l	d0-7/a0-6,-(a7)

	moveq	#16-1,d0
.t1sr_fixtabloop:
	move.l	4(a0),2(a0)
	move.l	8(a0),6(a0)
	move.l	12(a0),10(a0)
	move.w	#$4e75,14(a0)
	lea	16(a0),a0
	dbf	d0,.t1sr_fixtabloop

	move.l	_resload(pc),a0
	jsr	resload_FlushCache(a0)

	movem.l	(a7)+,d0-7/a0-6

.t1sr_tableok:
	lea	0(a0,d3.w),a2
	rts

;--------------------------------

_txt2_setrender:
	movem.l	d0-7/a0-6,-(a7)

	and.w	#3,d0
	asl.w	#2,d0
	move.l	_txt2_rendertab(pc,d0.w),d0
	lea	_base(pc),a0
	add.l	a0,d0
	lea	_txt2_renderptr(pc),a0
	move.l	d0,(a0)

	movem.l	(a7)+,d0-7/a0-6
	rts

;----------

_txt2_rendertab:
	dc.l	_txt2_r0-_base,_txt2_r1-_base,_txt2_r2-_base,_txt2_r3-_base

_txt2_renderptr:
	dc.l	0

;----------

_txt2_render:
	move.w	(a1),d0
	move.l	_txt2_renderptr(pc),-(a7)
	rts

;----------

_txt2_r3:	or.w	$78(a1),d0
_txt2_r2:	or.w	$50(a1),d0
_txt2_r1:	or.w	$28(a1),d0
_txt2_r0:	rts

;--------------------------------

_fadewait:	movem.l	d0-7/a0-6,-(a7)
	moveq	#10,d0
	move.l	_resload(pc),a2
	jsr	resload_Delay(a2)
	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------------------

	; replacement for dbf loop delay in soundfx routine
	; tuneable via CUSTOM1

_sfxwait:	movem.l	d1/a0,-(a7)
	lea	vhposr+_custom,a0
	move.l	_ct_ct1(pc),d1
.dw_loop1:	move.b	(a0),d0
.dw_loop2:	cmp.b	(a0),d0
	beq.s	.dw_loop2
	dbf	d1,.dw_loop1
	movem.l	(a7)+,d1/a0
	move.w	#$ffff,d0
	rts

;--------------------------------

	; >d4=sector number
	; >d5=number of sectors
	; >a2=address

_trackload:	movem.l	d0-7/a0-6,-(a7)

	move.b	_disknum+3(pc),d2
	cmp.b	#1,d2
	bne.s	.tl_notdisk1
	cmp.w	#1,d4
	ble.s	.tl_dir
	addq.w	#4,d4
.tl_notdisk1:
	move.w	d4,d0
	mulu	#512,d0	
	move.w	d5,d1
	mulu	#512,d1	
	move.l	a2,a0
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)

	bsr	_p2	; (re)patch code that can change after a disk load

	movem.l	(a7)+,d0-7/a0-6
	moveq	#0,d0
	rts

.tl_dir	movem.l	(a7)+,d0-7/a0-6
	move.l	#$ff383038,d0
	rts

;----------

_tl_setdisk:	movem.l	d0/a0,-(a7)
	move.b	$12f0.w,d0
	sub.b	#"A"-1,d0
	lea	_disknum(pc),a0
	move.b	d0,3(a0)
	move.l	_reloc_base(pc),a0
	add.l	#$9eec-$1000,a0
	move.b	d0,(a0)
	movem.l	(a7)+,d0/a0
	moveq	#0,d0
	rts

;--------------------------------

_initialise:	movem.l	d0-7/a0-6,-(a7)

	lea	_resload(pc),a1	; save resloader address
	move.l	a0,(a1)

	lea	_ctl_tags(pc),a0	; get config tags
	move.l	_resload(pc),a2
	jsr	resload_Control(a2)


	; decrunch & initialise smc rendering code replacement

	move.l	_expmem(pc),a1
	IFND	CHIP_ONLY
	add.l	#RELOC_MEM,a1
	ENDC
	lea		_smc_chunks(pc),a0
	move.l	a1,(a0)
	lea	_smc1_rendercode(pc),a0	; decrunch it to expmem
	move.l	_resload(pc),a2
	jsr	resload_Decrunch(a2)

	move.l	_smc_chunks(pc),a0	; init pointers to each instance
	lea	32(a0),a0	; a0=offset list / base
	lea	_smc1_rendertab(pc),a1	; a1=pointer table
	moveq	#32-1,d7
	move.l	a0,d6
.ini_smc1:	move.l	(a0)+,d0	; get offset, add base, store pointer
	add.l	d6,d0
	move.l	d0,(a1)+
	dbf	d7,.ini_smc1

	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------------------

_badver:	and.l	#$ffff,d0
	pea	0.l
	pea	0.l
	pea	TDREASON_WRONGVER.l
	bra.s	_abort

_debug:	pea	0.l
	pea	0.l
	pea	TDREASON_DEBUG.l
	bra.s	_abort

_exit:       pea	TDREASON_OK.l

_abort:      move.l	_resload(pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

;--------------------------------

	; version dependencies

VD_DISK_OFS:	equ	$2c00
VD_DISK_LEN:	equ	$10800
VD_DISK_BUF:	equ	$10000

;-----



	;VD_VERSION	1,$38a2	; v1: imageworks
;	dc.l	$17972	; _vd_setdsk
;	dc.l	$17226	; _vd_manprot
;	dc.l	$5ba62	; _vd_sfxwait
;
;	;VD_VERSION	2,$fa18	; v2: jst install, imageworks/mirrorsoft
;	dc.l	$17982	; _vd_setdsk
;	dc.l	$17236	; _vd_manprot
;	dc.l	$5ba42	; _vd_sfxwait


;--------------------------------

_resload:    dc.l 0

;-----

_ctl_tags:	dc.l	WHDLTAG_VERSION_GET
_ct_ver:	dc.l	0
	dc.l	WHDLTAG_REVISION_GET
_ct_rev:	dc.l	0
	dc.l	WHDLTAG_CUSTOM1_GET
_ct_ct1:	dc.l	0
	dc.l	0

;-----

_disknum:	dc.l	1	; current disk number

main_patchlist
	dc.l	0
part2_patchlist
	dc.l	0
_reloc_base
	dc.l	$1000
_program_size
	dc.l	$2b800
version
	dc.l	0
	
_smc_chunks
	dc.l	0
;-----

reloc_v1
	dc.b	"KillingCloud_v1.reloc",0
_cwdname:	dc.b	"data",0
_wsname:	dc.b	"The Killing Cloud"
	IFD	CHIP_ONLY
	dc.b	" (chip/debug mode)"
	ENDC
			dc.b	0
_wscopy:	dc.b	"1991 Vektor Grafix",0
_wsinfo:	dc.b	10,"adapted by Girv & JOTD",10
	DECL_VERSION
	dc.b	0
	EVEN
	IFD	RELOC_ENABLED
reloc_file_name_table
	dc.w	0
	dc.w	reloc_v1-reloc_file_name_table

_reloc_table_address
	ds.b	13000
	ENDC
;--------------------------------
