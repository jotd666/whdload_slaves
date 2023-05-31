
	;;OPT	O+,W-,CHKPC,P=68000

	; WHDLoad slave for Killing Cloud
	; (c) 2001-2002 Halibut Software
	; heavily reworked by JOTD & paraj in 2022
	
	INCDIR	INCLUDE:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;CHIP_ONLY
ALLOC_DEBUG=0

; 5BAD4: dmacon write (extra sfx or music code)

;RELOC_ENABLED = 1  ; now set in makefile defines
	IFD	RELOC_ENABLED
RELOC_MEM = $80000
	ELSE
RELOC_MEM = 0
	ENDC

PROGRAM_START = $1000

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
_keyexit
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
	dc.b	"C1:B:Use original drawing code;"
	dc.b	"C2:B:Don't change fetch mode for AGA;"
	IFND	CHIP_ONLY
	dc.b	"C3:B:No fast RAM alloc;"
	ENDC
	dc.b	"C4:B:fast intro screens;"
	dc.b	"C5:B:Show FPS;"
    dc.b	0

;==========================================================================

DECL_VERSION:MACRO
	dc.b	"2.3"
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

_start:
        bsr	_initialise

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
	; no relocs for that version. Removing support
	IFND	RELOC_ENABLED
	cmp.w	#$fa18,d0
	beq.b	version_2
	ENDC
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
	lea		PROGRAM_START.W,a0
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
	IFNE	0
w 0 $819c $2C600-$819C
w 1 $81000 $719C
; when missing reloc found eg access at $27456
; use this to search unrelocated address in memory
; s 00027456
; should show up in $80000-$A0000 with CHIP_ONLY set

	ENDC
	move.l	_reloc_base(pc),a0
	lea		(-$1000,a0),a1	; reloc base -$1000

	
	move.l	main_patchlist(pc),a0
	jsr		resload_Patch(a2)

	; set CPU and cache options
	IFND	RELOC_ENABLED
	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
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
	PL_AL	$22392,$400			; remove nasty protection check if protection is skipped
	PL_NEXT		pl_main_common
pl_main_2
	PL_START
	PL_P	$17982,_tl_setdisk
	PL_PS	$17236,_fadewait	; remove manual protection
	PL_AL	$223d0,$400			; remove nasty protection check if protection is skipped
	PL_NEXT		pl_main_common
	
pl_main_common:
	PL_START
	PL_IFC4
	PL_NOP	$1807a,2
	PL_ENDIF
	
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
	
	; manually relocate vectors
	PL_PSS	$836a,set_interrupt_vectors,2
	
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

	PL_PS   $0d988,_flush_cache_0d988
	PL_IFC1
	PL_ELSE
	PL_P    $0d1c8,_cpu_draw_shape
	PL_ENDIF
	PL_IFC2
	PL_ELSE
	PL_PS   $08ba4,_use_fmode3
	PL_ENDIF

	IFD		RELOC_ENABLED
	PL_PS	$0f31c,fetch_word
	ENDC
	
	IFND	CHIP_ONLY
	PL_IFC3
	PL_ELSE
        PL_P    $08256,_faststack
	PL_P    $082e2,_alloc
	PL_P    $086aa,_free
	PL_ENDIF
	ENDC
	
	PL_IFC5
	PL_P    $08c7e,_update_fps_counter
	PL_ENDIF
;        PL_PS $0b03a,_debughalt

	PL_PSS	$9266,_keyboard_hook,6
	PL_END

;--------------------------------

set_interrupt_vectors
	LEA	$01090-PROGRAM_START,A0		;0836a: 41f81090
	add.l	_reloc_base(pc),a0
	LEA	$64.W,A1		;0836e: 43f80064
	rts
	

fetch_word:
	; this address is built from a byte stream
	MOVEA.L	D0,A0			;0f31c: 2040
	MOVEQ	#0,D2			;0f31e: 7400
	; apply dynamic relocation
	cmp.l	#$80000,a0
	bcc.b	.ok
	cmp.l	#$819c,a0
	bcs.b	.ok
	add.l	_reloc_base(pc),a0
	sub.w	#PROGRAM_START,a0
.ok
	MOVE.W	(A0),D2			;0f320: 3410
	rts
	
_keyboard_hook
	; missing 75us handshake time
	moveq	#2,d1		; waste that register, it's preserved
	bsr	beamdelay
	NOT.B	D0			;0926e: 4600
	ROR.B	#1,D0			;09270: e218
	cmp.b	_keyexit(pc),d0
	beq	_exit
	MOVE.B	#$19,$bfee01
	rts
	
; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d1,-(a7)
    move.b	$dff006,d1	; VPOS
.bd_loop2
	cmp.b	$dff006,d1
	beq.s	.bd_loop2
	move.w	(a7)+,d1
	dbf	d1,.bd_loop1
	rts
	
        IFNE ALLOC_DEBUG
SerPutchar:
        btst.b  #13-8,$dff000+serdatr
        move.l  d0,-(sp)
        and.w   #$ff,d0
        or.w    #$100,d0       ; stop bit
        move.w  d0,$dff030
        move.l  (sp)+,d0
        rts
	
SerPutMsg:
        movem.l  d0/a0,-(sp)
spLoop:
        move.b  (a0)+,d0
        beq     spDone
        bsr     SerPutchar
        bra     spLoop
spDone:
        movem.l  (sp)+,d0/a0
        rts
SerPutCrLf:
        move.l  d0,-(sp)
        moveq   #13,d0
        bsr     SerPutchar
        moveq   #10,d0
        bsr     SerPutchar
        move.l  (sp)+,d0
        rts
SerPutSpace:
        move.l  d0,-(sp)
        moveq   #' ',d0
        bsr     SerPutchar
        move.l  (sp)+,d0
        rts
SerPutNum:
        movem.l d0-d2,-(sp)
        move.l  d0,d1
        moveq   #7,d2
spnLoop:
        rol.l   #4,d1
        move.w  d1,d0
        and.b   #$f,d0
        add.b   #$30,d0
        cmp.b   #$39,d0
        ble.b   spnPrint
        add.b   #39,d0
spnPrint:
        bsr     SerPutchar
        dbf     d2,spnLoop
        movem.l (sp)+,d0-d2
        rts

PRINT_MSG macro
        move.l  a0,-(sp)
        lea     .msg\@(pc),a0
        bsr     SerPutMsg
        move.l  (sp)+,a0
        bra .out\@
.msg\@:
        dc.b \1
        dc.b 0
        even
.out\@:
        endm
PRINT_NUM macro
        move.l  d0,-(sp)
        move.l  \1,d0
        bsr     SerPutNum
        move.l  (sp)+,d0
        endm
PRINT_NL macro
        bsr SerPutCrLf
        endm
PR macro
        PRINT_MSG <\1,'='>
        PRINT_NUM \2
        PRINT_NL
        endm
_debughalt:
        PRINT_MSG "Halting at PC="
        move.l  d0,-(sp)
        move.l  4(sp),d0
        sub.l   _expmem(pc),d0
        PRINT_NUM d0
        move.l  (sp)+,d0
        PRINT_NL
        PR "D0",d0
        PR "D1",d1
        PR "D2",d2
        PR "D3",d3
        PR "D4",d4
        PR "D5",d5
        PR "D6",d6
        PR "D7",d7
        PR "A0",a0
        PR "A1",a1
        PR "A2",a2
        PR "A3",a3
        PR "A4",a4
        PR "A5",a5
        PR "A6",a6
        PR "A7",a7
.x:     bra .x
        ENDC ; ALLOC_DEBUG
_faststack:
        move.w  #$4000,intena+$dff000
        move.l  usp,a0
        add.l   _expmem(pc),a0
        move.l  a0,usp
        ; Relocating SSP to fast mem gives issues (keyboard not working; sequence when entering plane skipped)
        move.l  _expmem(pc),a0
        add.l   #$1000,a0
        move.l  a0,sp
        move.w  #$c000,intena+$dff000
	ANDI.W	#$dfff,SR		;08256: 027cdfff
	MOVE.W	#$8400,$dff096;DMACON		;0825a: 33fc840000dff096
	;JMP	lb_17118		;08262: 4ef900017118
        move.l  _expmem(pc),a0
        add.l   #$17118,a0
        jmp     (a0)
_alloc:
        movem.l d2/a6,-(a7)
        IFNE ALLOC_DEBUG
        PRINT_MSG "Alloc PC=$"
        move.l  8(sp),d2
        sub.l   _expmem(pc),d2
        PRINT_NUM d2
        PRINT_MSG " Size=$"
        PRINT_NUM d0
        ENDC
	MOVE.W	$0101c.W,D2		;082e6: 3438101c
	MOVEQ	#4,D1			;082ea: 7204
	SUBA.L	A0,A0			;082ec: 91c8
        move.l  _expmem(pc),a6
        add.l   #$086f2,a6
	JSR	(a6)    		;082ee: 4eb9000086f2
        move.l  8(sp),d2 ; return address
        sub.l   _expmem(pc),d2
        lea     .whitelist(pc),a6
.l:
        move.l  (a6)+,d0
        beq.b   .na
        cmp.l   d0,d2
        bne.b   .l
        add.l   _expmem(pc),a0
.na:
        IFNE ALLOC_DEBUG
        PRINT_MSG " -> $"
        PRINT_NUM a0
        PRINT_NL
        ENDC
	MOVE.L	A0,D0			;082f4: 2008
	BNE.S	.ok              	;082f6: 6602
	MOVEQ	#-3,D0			;082f8: 70fd
.ok:
        ; flags (probably N) must be set on exit
        movem.l (a7)+,d2/a6
        rts
.whitelist:
        dc.l $0aa46     ; Main shape structure/edge lists
        ;dc.l $0e59a
        ;dc.l $0eaba ; TODO - Some kind of resize? seems to join blocks together somehow
        ;dc.l $14582 ; TODO
        dc.l $145aa
        dc.l $1412e
        dc.l $153be
        dc.l $16bc6
        dc.l $1e9a2
        dc.l 0 ; end
_free:
        IFNE ALLOC_DEBUG
        PRINT_MSG "Free  PC=$"
        move.l  4(sp),d0 ; always called with return address=$8324, so go up once on stack
        sub.l   _expmem(pc),d0
        PRINT_NUM d0
        PRINT_MSG " Ptr=$"
        PRINT_NUM a0
        PRINT_NL
        ENDC ; ALLOC_DEBUG
        move.l  _expmem(pc),a1
        cmpa.l  a1,a0
        blt.b   .notexp
        suba.l  a1,a0
.notexp:
        add.l   #$086b2,a1
        ; orig code + jump back
        movem.l a2-a3,-(sp)
        move.l  -8(a0),d0
        jmp     (a1)
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

_smc1_setrenderd0:
	move.l	d4,-(a7)	; set smc1 rendering for colour d0
	move.l	d0,d4
	bsr.s	_smc1_setrender
	move.l	(a7)+,d4
	lea	$1808.w,a3
	move.w	d0,d1
	rts

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


_initialise:	movem.l	d0-7/a0-6,-(a7)
        IFNE ALLOC_DEBUG
        move.w  #30,serper+$dff000
        ENDC

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
screenw=320
screenh=200
nbpl=4

bplrowwords=screenw/16
bplrowbytes=bplrowwords*2
rowdelta=bplrowbytes*nbpl

;--------------------------------
; FPS counter

onedigit macro
        divu.w  #10,d0
        swap    d0
        moveq   #$f,d1
        and.l   d0,d1
        bsr     _drawdigit
        clr.w   d0
        swap    d0
        endm

_update_fps_counter:
        movem.l d0-d7/a0-a6,-(sp)
        move.l  (a0),a2

        ; Read CIAB tod
        moveq   #0,d0
        move.b  $bfda00,d0
        swap    d0
        move.b  $bfd900,d0
        lsl.w   #8,d0
        move.b  $bfd800,d0
        lea     _last_time(pc),a0
        move.l  (a0),d1
        move.l  d0,(a0)
        sub.l   d1,d0
        ; d0=delta

        move.l  $11bc+2,a2
        move.l  (a2),d1
        beq     .out
        move.l  d1,a2

        move.l  d0,d1
        beq     .out

        move.l  #50*100*312,d0
        divu    d1,d0
        and.l   #$ffff,d0
        lea     (bplrowbytes-1,a2),a2
        onedigit
        onedigit
        moveq   #10,d1
        bsr     _drawdigit
        onedigit
        onedigit

.out:
        movem.l (sp)+,d0-d7/a0-a6

        ; Original code:
	SF	$011cc+2.W		;08c7e: 51f811ce
	RTS				;08c82: 4e75

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

;--------------------------------
; Flush cache for SMC done from function at $0d78e
;
_flush_cache_0d988:
        movem.l d0-d1/a0-a2,-(sp)
        move.l  _resload(pc),a2
        jsr     resload_FlushCache(a2)
        movem.l (sp)+,d0-d1/a0-a2
        ; original code
	MOVEQ	#-16,D2			;0d988: 74f0
	MOVE.W	D1,D3			;0d98a: 3601
	MOVE.W	D0,D1			;0d98c: 3200
        rts

;--------------------------------
; AGA fetch modes
;
_use_fmode3:
        btst.b  #9-8,vposr(a0)
        beq.b   .noaga
        move.w  #3,fmode(a0)
        move.w  #$38,ddfstrt(a0)
        move.w  #$b8,ddfstop(a0)
.noaga:
        ; Original instruction
        MOVE.W  #$8300,dmacon(A0) ;08ba4: 317c83000096
        rts


;--------------------------------
; CPU drawing routines

; y=0 is at the bottom of the screen
        rsreset
d_x0            rs.w 1 ; 0
d_y0            rs.w 1 ; 2
d_x1            rs.w 1 ; 4
d_y1            rs.w 1 ; 6
                rs.w 1 ; 8
                rs.w 1 ; 10
                rs.w 1 ; 12
                rs.w 1 ; 14
d_rectflag      rs.b 1 ; 16
d_nodrawflag    rs.b 1 ; 17
d_startxl       rs.l 1 ; 18
d_stopxl        rs.l 1 ; 22
                       ; 26


        ; \1 = mask register
DoMasked macro
        move.l  \1,d0
        not.l   d0
        move.l  3*bplrowbytes(a0),d3
        move.l  d7,d4
        and.l   \1,d4
        and.l   d0,d3
        or.l    d3,d4
        move.l  d4,3*bplrowbytes(a0)

        move.l  2*bplrowbytes(a0),d3
        move.l  d6,d4
        and.l   \1,d4
        and.l   d0,d3
        or.l    d3,d4
        move.l  d4,2*bplrowbytes(a0)

        move.l  1*bplrowbytes(a0),d3
        move.l  a3,d4
        and.l   \1,d4
        and.l   d0,d3
        or.l    d3,d4
        move.l  d4,1*bplrowbytes(a0)

        move.l  (a0),d3
        move.l  a2,d4
        and.l   \1,d4
        and.l   d0,d3
        or.l    d3,d4
        move.l  d4,(a0)+
        endm

DoRow macro
        ifeq \1
        and.l   d1,d2
        DoMasked d2
        else
        DoMasked d1
        rept (\1-1)
        move.l  d7,3*bplrowbytes(a0)
        move.l  d6,2*bplrowbytes(a0)
        move.l  a3,1*bplrowbytes(a0)
        move.l  a2,(a0)+
        endr
        DoMasked d2
        endc
        endm

MakeRowFunc macro
RowFunc\<n>
        DoRow n
        rts
        endm
n set 0
        rept bplrowwords/2
        MakeRowFunc
n set n+1
        endr

MakeRectFunc macro
RectFunc\<n>
.yloop:
        move.l  a1,a0
        DoRow   n
        lea     -rowdelta(a1),a1
        dbf     d5,.yloop
        rts
        endm
n set 0
        rept bplrowwords/2
        MakeRectFunc
n set n+1
        endr

_cpu_draw_shape:
        tst.b   d_nodrawflag(a0)
        beq.b   .DoDraw
        rts
.DoDraw:
        movem.l	d0-d7/a0/a2-a6,-(a7)

	move.w  d_y0(a0),d1
        move.w  d_y1(a0),d5
        sub.w   d1,d5

        move.w  #screenh-1,d2
        sub.w   d1,d2
        mulu.w  #rowdelta,d2
	move.l  (a2),a1
        lea     (a1,d2.w),a1

        ; expand d0 -> a2/a3/d6/d7 bitplane masks
        lsr.w   #1,d0
        subx.l  d6,d6
        move.l  d6,a2
        lsr.w   #1,d0
        subx.l  d6,d6
        move.l  d6,a3
        lsr.w   #1,d0
        subx.l  d6,d6
        lsr.w   #1,d0
        subx.l  d7,d7

        tst.b   d_rectflag(a0)
        bne     .DrawRect

        move.l  d_startxl(a0),a4
        move.l  d_stopxl(a0),a5
.LineLoop:
        move.w  (a4)+,d0 ; startx
        move.w  (a5)+,d2 ; stopx

        moveq   #-32,d1
        move.w  d0,d3
        and.w   d1,d3   ;d3=x0&-32
        move.w  d2,d4
        and.w   d1,d4   ;d4=x1&-32
        eor.w   d3,d0   ;d0=x0&31
        eor.w   d4,d2   ;d2=x1&31
        sub.w   d3,d4
        blt     .NextLine
        lsr.w   #5,d4   ; d4=number of longwords (non-inclusive)
        moveq   #-1,d1
        lsr.l   d0,d1   ; d1=fwm
        move.l  d2,d0
        moveq   #1,d2
        ror.l   #1,d2   ; d2=$80000000
        asr.l   d0,d2   ; d2=lwm
        lsr.w   #3,d3   ; byte offset of starting word
        lea     (a1,d3.w),a0   ; adjust destination

        ; d1=fwm/d2=lwm/d4=xcount/d5=ycount/a0=dest
        add.w   d4,d4
        move.w  RowFuncTable(pc,d4.w),d4
        jsr     RowFuncTable(pc,d4.w)
.NextLine:
        lea     -rowdelta(a1),a1
        dbf     d5,.LineLoop
        bra     .Out

.DrawRect:
        ; a0=draw struct a1=dest,a2-a5 bitplane masks,d5=count for dbf
        move.w  d_x0(a0),d0
        move.w  d_x1(a0),d2

        moveq   #-32,d1
        move.w  d0,d3
        and.w   d1,d3   ;d3=x0&-32
        move.w  d2,d4
        and.w   d1,d4   ;d4=x1&-32
        eor.w   d3,d0   ;d0=x0&31
        eor.w   d4,d2   ;d2=x1&31
        sub.w   d3,d4
        lsr.w   #5,d4   ; d4=number of longwords (non-inclusive)
        moveq   #-1,d1
        lsr.l   d0,d1   ; d1=fwm
        move.l  d2,d0
        moveq   #1,d2
        ror.l   #1,d2   ; d2=$80000000
        asr.l   d0,d2   ; d2=lwm
        lsr.w   #3,d3   ; byte offset of starting word
        add.w   d3,a1   ; adjust destination

        ; d1=fwm/d2=lwm/d4=xcount/d5=ycount/a0=dest
        add.w   d4,d4
        move.w  RectFuncTable(pc,d4.w),d4
        jsr     RectFuncTable(pc,d4.w)
.Out:
	movem.l	(a7)+,d0-d7/a0/a2-a6
        rts

RectTableEntry macro
        dc.w    RectFunc\<n>-RectFuncTable
        endm

RectFuncTable:
n set 0
        rept bplrowwords/2
        RectTableEntry
n set n+1
        endr

RowTableEntry macro
        dc.w    RowFunc\<n>-RowFuncTable
        endm

RowFuncTable:
n set 0
        rept bplrowwords/2
        RowTableEntry
n set n+1
        endr

;--------------------------------

	; version dependencies

VD_DISK_OFS:	equ	$2c00
VD_DISK_LEN:	equ	$10800
VD_DISK_BUF:	equ	$10000

;-----



	;VD_VERSION	1,$38a2	; v1: imageworks
	dc.l	$17972	; _vd_setdsk
	dc.l	$17226	; _vd_manprot
	dc.l	$5ba62	; _vd_sfxwait

	;VD_VERSION	2,$fa18	; v2: jst install, imageworks/mirrorsoft
	dc.l	$17982	; _vd_setdsk
	dc.l	$17236	; _vd_manprot
	dc.l	$5ba42	; _vd_sfxwait


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
	dc.l	PROGRAM_START
_program_size
	dc.l	$2b800
version
	dc.l	0
	
_smc_chunks
	dc.l	0
;-----

_last_time
        dc.l    0
;-----
reloc_v1
	dc.b	"KillingCloud_v1.reloc",0
_cwdname:	dc.b	"data",0
_wsname:	dc.b	"The Killing Cloud"
			IFD		CHIP_ONLY
			dc.b	" (chip/debug mode)"
			ENDC
			dc.b	0
_wscopy:	dc.b	"1991 Vektor Grafix",0
_wsinfo:	dc.b	10,"adapted by Girv, JOTD & paraj",10
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
