
	;SECTION	Slave,CODE
	

	; WHDLoad slave for Jimmy White's Whirlwind Snooker
	; (c) 1998-2004 Halibut Software

	INCDIR	INCLUDE:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	hardware/custom.i
	INCLUDE	hardware/intbits.i
	INCLUDE	hardware/cia.i

CHIPMEM_SIZE = $80000
EXPMEM_SIZE = 0

;==========================================================================

	; WHDLoad slave header structure

_base:	SLAVE_HEADER		; ws_Security + ws_ID
	dc.w	16	; ws_Version
	dc.w	WHDLF_NoError|WHDLF_EmulTrap	; ws_flags
_basemem:	dc.l	CHIPMEM_SIZE	; ws_BaseMemSize
	dc.l	0	; ws_ExecInstall
	dc.w	_start-_base	; ws_GameLoader
	dc.w	_cwdname-_base	; ws_CurrentDir
	dc.w	0	; ws_DontCache
_keydebug:	dc.b	$58	; ws_keydebug
_keyexit:	dc.b	$59	; ws_keyexit
_expmem:	dc.l	EXPMEM_SIZE	; ws_ExpMem
	dc.w	_wsname-_base	; ws_name
	dc.w	_wscopy-_base	; ws_copy
	dc.w	_wsinfo-_base	; ws_info
	dc.w	0	; ws_kickname
	dc.l	0	; ws_kicksize
	dc.w	0	; ws_kickcrc

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"2.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
;-----

_cwdname:	dc.b	"data",0

_mainname:	dc.b	"Main",0

_wsname:	dc.b	"Jimmy White's Whirlwind Snooker",0
_wscopy:	dc.b	"1991 Archer Maclean",0
_wsinfo:	dc.b	10,"adapted by Girv & JOTD",10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0	
;==========================================================================

	dc.b	"$VER: JWWS WHDLoad Slave "
	DECL_VERSION
	dc.b	0
	EVEN

;==========================================================================

_start:
	bsr	_initialise
	move.l	_resload(pc),a2

	move.l	_vd_mainaddr(pc),a1
	move.l	a1,-(a7)
	cmp.l	#VD_FILE_BUF,a1
	beq.b	.already_loaded
	lea	_mainname(pc),a0	; load game code
	jsr	resload_LoadFileDecrunch(a2)
.already_loaded	
	move.l	_vd_p0_pl(pc),a0	; patch game code and start game
	lea	_base(pc),a1
	add.l	a1,a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jmp	resload_Patch(a2)

;-----

_p0_pl_v1:	PL_START
	PL_P	$27996,_p1	; intercept just before protection
	PL_NOP	$278ea,8	; remove execbase access
	PL_NOP	$28454,8	; remove anti-ar uneven cop2lc write
	PL_P	$285d8,_lev3_int	; patch level 3 interrupt handler
	PL_PS	$284fc,_lev4_int	; patch level 4 interrupt handler
	PL_W	$284fc+6,$4a41
	
	PL_PS	$404ea,enable_dma
	PL_PS	$4046a,audio_channel
	PL_PS	$404f6,audio_channel
	PL_P	$405da,soundtracker_loop
	
	PL_PSS	$402be,audio_channel_0_off,2
	PL_PSS	$40324,audio_channel_1_off,2
	PL_PSS	$4038c,audio_channel_2_off,2
	PL_PSS	$403f4,audio_channel_3_off,2
	
	PL_PSS	$39728,ack_interrupt,2
	PL_W	$39730,$4EF9	; kill keyboard code
	PL_PA	$3967a+2,level_2_triggered
	PL_PA	$3968a+2,keycode
	PL_P	$2860e,level_2_interrupt
	PL_ORW	$283ec+2,8	; enable keyboard
	
	PL_END

_p0_pl_v2:	PL_START
	PL_P	$279de,_p1
	PL_NOP	$27932,8
	PL_NOP	$2849c,8
	PL_P	$28620,_lev3_int
	PL_PS	$28544,_lev4_int
	PL_W	$28544+6,$4a41
	
	PL_PS	$40486,audio_channel
	PL_PS	$40512,audio_channel
	PL_PS	$40506,enable_dma
	PL_P	$405f6,soundtracker_loop
	
	PL_PSS	$402da,audio_channel_0_off,2
	PL_PSS	$40340,audio_channel_1_off,2
	PL_PSS	$403a8,audio_channel_2_off,2
	PL_PSS	$40410,audio_channel_3_off,2
	
	PL_PSS	$39770,ack_interrupt,2
	PL_W	$39778,$4EF9	; kill keyboard code
	PL_PA	$396c2+2,level_2_triggered
	PL_PA	$396d2+2,keycode
	PL_P	$28656,level_2_interrupt
	PL_ORW	$28434+2,8	; enable keyboard
	

	PL_END

_p0_pl_v3:	PL_START
	PL_P	$27bfc,_p1
	PL_NOP	$27b4a,8
	PL_NOP	$28666,8
	PL_P	$287f2,_lev3_int
	PL_PS	$2870e,_lev4_int
	PL_W	$2870e+6,$4a41
	
	PL_PS	$406be,audio_channel
	PL_PS	$4074a,audio_channel
	PL_PS	$4073e,enable_dma
	PL_P	$4082e,soundtracker_loop
	
	PL_PSS	$40512,audio_channel_0_off,2
	PL_PSS	$40578,audio_channel_1_off,2
	PL_PSS	$405e0,audio_channel_2_off,2
	PL_PSS	$40648,audio_channel_3_off,2
	
	PL_PSS	$3993a,ack_interrupt,2
	PL_W	$39942,$4EF9	; kill keyboard code
	PL_PA	$3987e+2,level_2_triggered
	PL_PA	$3988e+2,keycode
	PL_P	$28828,level_2_interrupt
	PL_ORW	$285fe+2,8	; enable keyboard
	
	PL_END

_p0_pl_v4:	PL_START
	PL_P	$279ea,_p1
	PL_NOP	$2793e,8
	PL_NOP	$284a8,8
	PL_P	$2862c,_lev3_int
	PL_PS	$28550,_lev4_int
	PL_W	$28550+6,$4a41
	
	PL_PS	$404be,audio_channel
	PL_PS	$4054a,audio_channel
	PL_PS	$4053e,enable_dma
	PL_P	$4062e,soundtracker_loop
	
	PL_PSS	$40312,audio_channel_0_off,2
	PL_PSS	$40378,audio_channel_1_off,2
	PL_PSS	$403e0,audio_channel_2_off,2
	PL_PSS	$40448,audio_channel_3_off,2
	
	PL_PSS	$3977c,ack_interrupt,2
	PL_W	$39784,$4EF9	; kill keyboard code
	PL_PA	$396ce+2,level_2_triggered
	PL_PA	$396de+2,keycode
	PL_P	$28662,level_2_interrupt
	PL_ORW	$28440+2,8	; enable keyboard
	
	PL_END

;--------------------------------

_p1:
	; there are 2 patchlists, but it's not really necessary except maybe
	; for the side effects of RN copylock, well, no big deal
	move.l	a7,d0	; save game stack
	move.l	_basemem(pc),a7
	subq.l	#4,a7
	movem.l	d0-d7/a0-a6,-(a7)

	move.l	_vd_p1_pl(pc),a0	; patch game code
	lea	_base(pc),a1
	add.l	a1,a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-7/a0-6	; restore game stack
	move.l	d0,a7

	move.b	#%00001000,$bfde00	; required? not sure...
	move.l	$60.w,d0	; d0=RNC checksum
	move.l	_vd_postprot(pc),-(a7)	; back to game
	rts

;-----

_p1_pl_v1:	PL_START
	PL_L	$60,$33cabd50	; anti rnc
	PL_W	$3e8,$a9d0
	PL_L	$3b3da,$00017ac1	; anti checksum 2
	PL_P	$40a12,_csum3	; anti checksum 3
	PL_NOP	$11ed6,12	; anti manual protection
	PL_L	$1203c,$3228004a	;  move.w d1,$4a(a0)
	PL_P	$4a37e,_diskaccess	; intercept disk access
	
	PL_END

_p1_pl_v2:	PL_START
	PL_L	$60,$33cabd50
	PL_W	$3e8,$a9d0
	PL_L	$3b422,$00017c31
	PL_P	$40a2e,_csum3
	PL_NOP	$17340,12
	PL_L	$174da,$3228004a
	PL_P	$4a39e,_diskaccess

	PL_END

_p1_pl_v3:	PL_START
	PL_L	$60,$c3f4f0f4
	PL_W	$3e8,$a9d0
	PL_L	$3b636,$0001c2fc
	PL_P	$40c66,_csum3
	PL_NOP	$17524,12
	PL_L	$176be,$3228004a
	PL_P	$4a5de,_diskaccess

	PL_END

_p1_pl_v4:	PL_START
	PL_L	$60,$33cabd50
	PL_W	$3e8,$a9d0
	PL_L	$3b42e,$00017d25
	PL_P	$40a66,_csum3
	PL_NOP	$11ef6,12
	PL_L	$12090,$3228004a
	PL_P	$4a3de,_diskaccess

	PL_END

;--------------------------------

enable_dma
	move.w	d0,_custom+dmacon
	bra.b	soundtracker_loop
	
audio_channel:
	move.w	d4,_custom+dmacon
	bra.b	soundtracker_loop

audio_channel_0_off
	move.w	#1,_custom+dmacon
	bra.b	soundtracker_loop
audio_channel_1_off
	move.w	#2,_custom+dmacon
	bra.b	soundtracker_loop
audio_channel_2_off
	move.w	#4,_custom+dmacon
	bra.b	soundtracker_loop
audio_channel_3_off
	move.w	#8,_custom+dmacon
soundtracker_loop
	move.w  d0,-(a7)
	move.w	#5,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
	rts 
;--------------------------------

	; fake checksum code

_csum3:	move.l	a0,-(a7)
	move.l	_vd_c3adr1(pc),a0
	move.w	_vd_c3val1+2(pc),(a0)
	move.l	_vd_c3adr2(pc),a0
	move.l	_vd_c3val2(pc),(a0)
	move.l	(a7)+,a0
	rts

;--------------------------------

level_2_interrupt

	movem.l	D0/A0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	lea		keycode(pc),a0
	move.b	d0,(a0)
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
	lea		level_2_triggered(pc),a0
	move.w	#8,(a0)
    cmp.b   _keyexit(pc),d0
    beq   _exit

	BSET	#$06,$1E01(A5)
	move.l	#2,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a0/a5
	move.w	#8,$dff09c
	rte

ack_interrupt
	move.l	a0,-(a7)
	lea		level_2_triggered(pc),a0
	clr.w	(a0)
	move.l	(a7)+,a0
	rts
	
;--------------------------------

	; fixed level 3 interrupt handling routine

_lev3_int:	movem.l	d0/a0,-(a7)

	lea	_custom,a0
	move.w	intreqr(a0),d0

	btst	#INTB_COPER,d0
	bne.s	.l3i_coper

	btst	#INTB_VERTB,d0
	bne.s	.l3i_vertb

	btst	#INTB_BLIT,d0
	bne.s	.l3i_blit

	and.w	#INTF_COPER|INTF_VERTB|INTF_BLIT,d0
	move.w	d0,intreq(a0)
	movem.l	(a7)+,d0/a0
	rte

;-----

.l3i_coper:	move.w	#INTF_COPER,intreq(a0)
	movem.l	(a7)+,d0/a0
	move.l	_vd_l3i_coper(pc),-(a7)
	rts

.l3i_vertb:	move.w	#INTF_VERTB,intreq(a0)
	movem.l	(a7)+,d0/a0
	move.l	_vd_l3i_vertb(pc),-(a7)
	rts

.l3i_blit:	move.w	#INTF_BLIT,intreq(a0)
	movem.l	(a7)+,d0/a0
	move.l	_vd_l3i_blit(pc),-(a7)
	rts

;--------------------------------

	; fixed level 4 interrupt handling routine

_lev4_int:	move.w	intreqr+_custom,d1
	and.w	#INTF_AUD3,d1
	rts

;--------------------------------

_diskaccess:	; disk access routine
	; d1 = start sector
	; d2 = no. of sectors
	; d3 = comand 0 = load
	;             1 = save
	;             2 = initialise
	; a0 = data source/dest
	; a1 = scratch memory

	movem.l	d1-7/a0-6,-(a7)

	; get address of function to call based on
	; command and start sector (only 6 combinations)

	cmp.w	#$6b4,d1	; access score file?
	seq	d1
	and.w	#4,d1	; d1 = 0 if accessing game file
			;    = 4 if accessing score file

	and.w	#3,d3	; d3 = 8*accessmode
	asl.w	#3,d3

	add.w	d1,d3	; d3 = (4*file)+(8*accessmode)=table index

	exg.l	a0,a1	; a1 = data address
			; a0 = scratch address
	move.l	_resload(pc),a2	; a2 = resloader
	move.l	#5632,d0	; d0 = data len (always the same)

	jsr	.da_jumptab(pc,d3.w)	; do the disk access

	movem.l	(a7)+,d1-7/a0-6	; all done
	moveq	#0,d0
	rts
;-----
	; disk access routines
	; all called with:
	;	d0=data len
	;	a0=scratch memory
	;	a1=data source/dest
	;	a2=resloader base

	OPT O-,W+
.da_jumptab:	bra	.da_loadgame
	bra	.da_loadscore
	bra	.da_savegame
	bra	.da_savescore
	bra	.da_initgame
	bra	.da_initscore
	OPT O+,W-

;-----

.da_loadgame:
	lea	.da_gamefnam(pc),a0	; load saved game file
	movem.l	a0-1,-(a7)	; does file exist?
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,a0-1
	cmp.l	#5632,d0
	beq.s	.dalg_load

	lea	.da_igdata(pc),a0	; decrunch initial data
	jmp	resload_Decrunch(a2)

.dalg_load:	jmp	resload_LoadFileDecrunch(a2) ; load file



.da_loadscore:
	lea	.da_scorefnam(pc),a0	; load saved scores file
	movem.l	a0-1,-(a7)	; does file exist?
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,a0-1
	cmp.l	#5632,d0
	beq.s	.dals_load

	lea	.da_isdata(pc),a0	; decrunch initial data
	jmp	resload_Decrunch(a2)

.dals_load:	jmp	resload_LoadFileDecrunch(a2)

;-----

.da_savegame:
	lea	.da_gamefnam(pc),a0	; save game position
	jmp	resload_SaveFile(a2)

.da_savescore:
	lea	.da_scorefnam(pc),a0	; save scores
	jmp	resload_SaveFile(a2)

;-----

.da_initgame:
	movem.l	d0/a0,-(a7)	; (re)initialise saved game file
	move.l	a0,a1
	lea	.da_igdata(pc),a0
	jsr	resload_Decrunch(a2)
	movem.l	(a7)+,d0/a1
	bra.s	.da_savegame

;-----

.da_initscore:
	movem.l	d0/a0,-(a7)	; (re)initialise scores file
	move.l	a0,a1
	lea	.da_isdata(pc),a0
	jsr	resload_Decrunch(a2)
	movem.l	(a7)+,d0/a1
	bra.s	.da_savescore

;-----

.da_igdata:	INCBIN	SaveDat.6CA.RNC
	EVEN

.da_isdata:	INCBIN	SaveDat.6B4.RNC
	EVEN

.da_gamefnam:
	dc.b	"SaveDat.6CA",0
.da_scorefnam:
	dc.b	"SaveDat.6B4",0
	EVEN

;--------------------------------
;--------------------------------

_initialise:	movem.l	d0-d7/a0-a6,-(a7)

	lea	_resload(pc),a1	; save resloader address
	move.l	a0,(a1)

;	lea	_ctl_tags(pc),a0	; get config tags
;	move.l	_resload(pc),a2
;	jsr	resload_Control(a2)

	LEA	VD_FILE_BUF,A1		;44e: 41f900010000
	lea	VD_FILE_NAM(pc),a0
	MOVEA.L	_resload(PC),A2		;454: 247a0192
	MOVEM.L	D0/A1,-(A7)		;458: 48e740a0
	JSR	resload_LoadFileDecrunch(A2)			;45c: 4eaa0028
	MOVEM.L	(A7)+,D0/A0		;460: 4cdf0501
	move.l	#VD_FILE_LEN,d0
	JSR	resload_CRC16(A2)			;464: 4eaa0030
	cmp.w	#$f5d9,d0
	beq.b	version_1
	cmp.w	#$fa92,d0
	beq.b	version_2
	cmp.w	#$8886,d0
	beq.b	version_3
	cmp.w	#$e147,d0
	beq.b	version_4
	bra.b	_badver
	
version_1
	bsr	_setvars_version_1
	bra.b	setver
version_2
	bsr	_setvars_version_2
	bra.b	setver
version_3
	bsr	_setvars_version_3
	bra.b	setver
version_4
	bsr	_setvars_version_4
setver


	movem.l	(a7)+,d0-d7/a0-a6
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
	addq.l	#resload_Abort,(a7)
	rts

;--------------------------------

	; version dependencies

VD_FILE_NAM:	dc.b "Main",0
	EVEN
VD_FILE_LEN:	equ	$1400
VD_FILE_BUF:	equ	$5ed0

;-----


_vd_p0_pl:	    dc.l	0
_vd_p1_pl:	    dc.l	0
_vd_mainaddr:   dc.l	0
_vd_postprot:   dc.l	0
_vd_c3adr1:	    dc.l	0
_vd_c3val1:	    dc.l	0
_vd_c3adr2:	    dc.l	0
_vd_c3val2:	    dc.l	0
_vd_l3i_coper:  dc.l	0
_vd_l3i_vertb:  dc.l	0
_vd_l3i_blit:   dc.l	0


;-----

RELOC_MOVEL:MACRO
		lea	\2(pc),a0
		move.l	#\1,(a0)
		ENDM


_setvars_version_1; v1 original (SPS513)

	RELOC_MOVEL	_p0_pl_v1-_base,_vd_p0_pl  
	RELOC_MOVEL	_p1_pl_v1-_base,_vd_p1_pl  
	RELOC_MOVEL	$00005ed0,_vd_mainaddr
	RELOC_MOVEL	$000282e6,_vd_postprot
	RELOC_MOVEL	$00004f82,_vd_c3adr1
	RELOC_MOVEL	$0000f8c1,_vd_c3val1
	RELOC_MOVEL	$00040092,_vd_c3adr2
	RELOC_MOVEL	$00000001,_vd_c3val2
	RELOC_MOVEL	$00039ce8,_vd_l3i_coper
	RELOC_MOVEL	$00027794,_vd_l3i_vertb
	RELOC_MOVEL	$0002861a,_vd_l3i_blit
	rts

_setvars_version_2; v2 beau jolly
	RELOC_MOVEL	_p0_pl_v2-_base,_vd_p0_pl  
	RELOC_MOVEL	_p1_pl_v2-_base,_vd_p1_pl  
	RELOC_MOVEL	$00005ed0,_vd_mainaddr
	RELOC_MOVEL	$0002832e,_vd_postprot
	RELOC_MOVEL	$00004f82,_vd_c3adr1
	RELOC_MOVEL	$0000f9e3,_vd_c3val1
	RELOC_MOVEL	$000400ae,_vd_c3adr2
	RELOC_MOVEL	$00000001,_vd_c3val2
	RELOC_MOVEL	$00039d30,_vd_l3i_coper
	RELOC_MOVEL	$000277dc,_vd_l3i_vertb
	RELOC_MOVEL	$00028662,_vd_l3i_blit
	rts
	
_setvars_version_3; v3 hit squad
	RELOC_MOVEL	_p0_pl_v3-_base,_vd_p0_pl  
	RELOC_MOVEL	_p1_pl_v3-_base,_vd_p1_pl  
	RELOC_MOVEL	$00005ed2,_vd_mainaddr
	RELOC_MOVEL	$000284f8,_vd_postprot
	RELOC_MOVEL	$00004f82,_vd_c3adr1
	RELOC_MOVEL	$00002cd0,_vd_c3val1
	RELOC_MOVEL	$000402e6,_vd_c3adr2
	RELOC_MOVEL	$00000001,_vd_c3val2
	RELOC_MOVEL	$00039f44,_vd_l3i_coper
	RELOC_MOVEL	$000279f2,_vd_l3i_vertb
	RELOC_MOVEL	$00028834,_vd_l3i_blit
	rts
	
_setvars_version_4; v4 virgin
	RELOC_MOVEL	_p0_pl_v4-_base,_vd_p0_pl  
	RELOC_MOVEL	_p1_pl_v4-_base,_vd_p1_pl  
	RELOC_MOVEL	$00005ed0,_vd_mainaddr
	RELOC_MOVEL	$0002833a,_vd_postprot
	RELOC_MOVEL	$00004f82,_vd_c3adr1
	RELOC_MOVEL	$0000fdc5,_vd_c3val1
	RELOC_MOVEL	$000400e6,_vd_c3adr2
	RELOC_MOVEL	$00000001,_vd_c3val2
	RELOC_MOVEL	$00039d3c,_vd_l3i_coper
	RELOC_MOVEL	$000277e8,_vd_l3i_vertb
	RELOC_MOVEL	$0002866e,_vd_l3i_blit
	rts
	

;--------------------------------

_resload:    dc.l 0
level_2_triggered
	dc.w	0
keycode
	dc.b	0
;-----




	EVEN

;--------------------------------
