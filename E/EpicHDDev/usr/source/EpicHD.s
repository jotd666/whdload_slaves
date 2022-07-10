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

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoDivZero	;ws_flags
		dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit
_expmem		dc.l	$80000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	'Epic & Mission Disk',0
_copy		dc.b	'1992 Ocean',0
_info		dc.b	'fixed and installed by Graham and Wepl',$A
		dc.b	'on '
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	' V1.4',-1
		dc.b	'Entrycodes:',10
		dc.b	'2-AURIGA  3-CEPHEUS  4-APUS  5-MUSCA',10
		dc.b	'6-PYXIS  7-CETUS  8-FORNAX  9-CAELUM  10-CORVUS',10
		dc.b	'Warning: CEPHEUS will crash Epic!',0
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

	lea	$100,a0
	moveq	#-2,d0
	move.l	d0,(a0)
	move.l	a0,_custom+cop1lc

	ifeq 0
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
	endc

	lea	($800).w,a0
	move.w	#$15FF,d0
.clr	clr.l	(a0)+
	dbra	d0,.clr

	addq.w	#1,($406E).w

	move.l	#CACRF_EnableI,d0
	move.l	d0,d1
;	jsr	(resload_SetCACR,a2)

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
	PL_P	$b08,_setexp
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
	PL_PS	$2e,.copypatch
	PL_PS	$601e,_keyboard
	PL_W	$9152,$602e
	PL_PS	$9192,_patch_num
	PL_S	$9198,$a8
	PL_I	$9ac8
	PL_P	$24734,_snoopssp1
	PL_PS	$2718e,_bw1
	PL_PS	$271d2,_bw3
	PL_PS	$27244,_bw2
	PL_END

.copypatch	move.b	(a0)+,(a1)+
	dbra	d0,.copypatch

	lea	_plm1(pc),a0
	sub.l	a1,a1
	jsr	(resload_Patch,a2)

	movea.w	#$94,a1
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

_setexp	move.l	_expmem(pc),(a0)+		;expmem start
	;move.l	#$80000,(a0)+
	move.l	#$80000,(a0)+		;expmem length
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

_normalgame_v1	jsr	($610C).w
	lea	($864).w,a0
	move.l	#$2200,d0
	move.l	#$3000,d1
	moveq	#1,d2
	bsr.w	_diskload
	bsr.w	.patchmain
	jsr	($86C).w
	jsr	($898).w
	lea	($9C78).l,a0
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
	movea.l	(_long,pc),a0
	lea	(.copypatch,pc),a1
	move.w	#$4EB9,($2C,a0)
	move.l	a1,($2E,a0)
	lea	(_keyboard,pc),a1
	move.w	#$4EB9,($5FCE,a0)
	move.l	a1,($5FD0,a0)
	lea	($4000,a0),a2
	move.w	#$602E,($5152,a2)
	lea	(_patch_num,pc),a1
	move.w	#$4EB9,($5192,a2)
	move.l	a1,($5194,a2)
	move.w	#$60A6,($5198,a2)
	bsr.w	_loadhighs_v1
	jmp	(a0)

.setexp	lea	($9C78).l,a0
	move.l	#$80000,d0
	move.l	d0,(a0)
	jsr	($BD6).w
	jmp	($BE2).w

.copypatch	move.b	(a0)+,(a1)+
	dbra	d0,.copypatch
	bra.w	.patchmain

.copydata	movem.l	d0/a0/a1,-(sp)
	lea	(_data_v1,pc),a1
	move.w	#$1FF,d0
.copy	move.l	(a1)+,(a0)+
	dbra	d0,.copy
	movem.l	(sp)+,d0/a0/a1
	st	d0
	rts

.loadnum	movem.l	d0-d7/a0-a6,-(sp)
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

.patchmain	lea	($2384).w,a0
	move.w	#$1A,d0
.copyskip	move.w	#$6004,(a0)+
	dbra	d0,.copyskip
	lea	($193E).w,a0
	move.w	#$F8,d0
.copyrts	move.w	#$4E75,(a0)+
	dbra	d0,.copyrts
	move.w	#$4E71,($18BA).w
	lea	(.setexp,pc),a0
	move.w	#$4EF9,($B06).w
	move.l	a0,($B08).w
	lea	(.loadnum,pc),a0
	move.w	#$4EF9,($1B30).w
	move.l	a0,($1B32).w
	lea	(.copydata,pc),a0
	move.w	#$4EF9,($902).w
	move.l	a0,($904).w
	move.w	#$603E,($2338).w
	lea	(_savehighs,pc),a0
	move.w	#$4EF9,($1D80).w
	move.l	a0,($1D82).w
	suba.l	a1,a1
	bra.w	patch_intrts

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
	lea	($9C78).l,a0
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
	movea.l	(_long,pc),a0
	lea	(_copypatch_v2,pc),a1
	move.w	#$4EB9,($2C,a0)
	move.l	a1,($2E,a0)
	lea	(_keyboard,pc),a1
	move.w	#$4EB9,($6022,a0)
	move.l	a1,($6024,a0)
	lea	($4000,a0),a2
	move.w	#$602E,($51A2,a2)
	lea	(_patch_num,pc),a1
	move.w	#$4EB9,($51E2,a2)
	move.l	a1,($51E4,a2)
	move.w	#$60A6,($51E8,a2)
	bsr.w	_loadhighs_v2
	jmp	(a0)

_setexp_v2	lea	($9C78).l,a0
	move.l	#$80000,d0
	move.l	d0,(a0)
	jsr	($CC8).w
	jmp	($CD6).w

_copypatch_v2	move.b	(a0)+,(a1)+
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

_loadnum_v2	movem.l	d0-d7/a0-a6,-(sp)
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

_patchmain_v2	lea	($249A).w,a0
	move.w	#10,d0
.copyskip	move.w	#$6004,(a0)+
	dbra	d0,.copyskip
	lea	($1A54).w,a0
	move.w	#$F8,d0
.copyrts	move.w	#$4E75,(a0)+
	dbra	d0,.copyrts
	move.w	#$4E71,($19CE).w
	lea	(_setexp_v2,pc),a0
	move.w	#$4EF9,($B84).w
	move.l	a0,($B86).w
	lea	(_loadnum_v2,pc),a0
	move.w	#$4EF9,($1C46).w
	move.l	a0,($1C48).w
	lea	(_copydata_v2,pc),a0
	move.w	#$4EF9,($90A).w
	move.l	a0,($90C).w
	move.w	#$603E,($244E).w
	lea	(_savehighs,pc),a0
	move.w	#$4EF9,($1E96).w
	move.l	a0,($1E96).w
	movea.w	#$14A,a1
patch_intrts	move.l	#$4E714EB9,d0
	lea	(_intrts1,pc),a0
	move.l	d0,($2486,a1)
	move.l	a0,($248A,a1)
	lea	(_intrts2,pc),a0
	move.l	d0,($2498,a1)
	move.l	a0,($249C,a1)
	lea	(_intrts4,pc),a0
	move.l	d0,($24A4,a1)
	move.l	a0,($24A8,a1)
	lea	(_intrts8,pc),a0
	move.l	d0,($24BE,a1)
	move.l	a0,($24C2,a1)
	move.l	d0,($24CA,a1)
	move.l	a0,($24CE,a1)
	lea	(_intrts40,pc),a0
	move.l	d0,($24F0,a1)
	move.l	a0,($24F4,a1)
	lea	(_intrts20,pc),a0
	move.l	d0,($2500,a1)
	move.l	a0,($2504,a1)
	lea	(_intrts10,pc),a0
	move.l	d0,($2514,a1)
	move.l	a0,($2518,a1)
	lea	(_intrts800,pc),a0
	move.l	d0,($2544,a1)
	move.l	a0,($2548,a1)
	lea	(_intrts1000,pc),a0
	move.l	d0,($2550,a1)
	move.l	a0,($2554,a1)
	lea	(_intrts2000,pc),a0
	move.l	d0,($2576,a1)
	move.l	a0,($257A,a1)
	move.l	d0,($2582,a1)
	move.l	a0,($2586,a1)
	lea	(_intrts4000,pc),a0
	move.l	d0,($258E,a1)
	move.l	a0,($2592,a1)
	rts

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
	cmp.b	#$78,d2
	beq.w	_abort_ok
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
	dc.l	0
_resload	dc.l	0
_long	dc.l	0

	end
