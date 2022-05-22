
		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

;======================================================================


;======================================================================

		IFD BARFLY
		IFD AGA
		OUTPUT	"wart:mo/mortalkombat2/MortalKombat2AGA.slave"
		ELSE
		OUTPUT	"wart:mo/mortalkombat2/MortalKombat2.slave"
		ENDC
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

; this game doesn't like 32 bit memory
; 3 slaves are provided
; 512k chip, 1.5MB 24 bit other
; 1MB chip
; 2MB chip
	
	IFD	ONE_MEG_CHIP
CHIPMEMSIZE = $100000
FASTMEMSIZE = $180000	; only 1MB is used but needs alignment
	ENDC

	IFD	HALF_MEG_CHIP
CHIPMEMSIZE = $80000
FASTMEMSIZE = $200000	; only 1.5MB is used but needs alignment
	ENDC
;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	FASTMEMSIZE+$1000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
;---
	dc.w	slv_config-_base
	
slv_config:
        dc.b    "C1:X:infinite energy P2:0;"
        dc.b    "C1:X:infinite energy P1:1;"
        dc.b    "C1:X:one hit kills P2:2;"
        dc.b    "C1:X:one hit kills P1:3;"
        dc.b    "C1:X:infinite time:4;"
        dc.b    "C1:X:in game cheat menu:5;"
        dc.b    "C1:X:bloodless mode:6;"
        dc.b    "C2:X:2 button control by default:0;"
		dc.b	0
	
;============================================================================
	IFD	BARFLY
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_name		dc.b	"Mortal Kombat 2"
		IFD ONE_MEG_CHIP
		dc.b	" (1Mb chip)"
		ENDC
		dc.b	0
_copy		dc.b	"1994 Acclaim",0
_info		dc.b	"Installed by Codetapper/Action! & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	-1,"Greetings to Mr Larmer, Mick, Jean-François Fabre,"
		dc.b	10,"and to Carlo Pirri, Chris Vella and Mad-Matt"
		dc.b	10,"for supplying the originals!",0
_Disk1		dc.b	"Disk.1",0
_CrackDiskNum	dc.b	1
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		IFD	CHIP_ONLY
		lea		_expmem(pc),a0
		move.l	#$80000,(a0)
		lea		CHIPMEMSIZE-$100,a7
		ELSE
		move.l	_expmem(pc),a7
		add.l	#FASTMEMSIZE+$F00,a7		
		ENDC
	


_restart	
		move.l	_resload(pc),a2
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

		lea	_Disk1(pc),a0
		jsr	resload_GetFileSize(a2)
		
		
		; empty copperlist in $100
		move.l	#$fffffffe,$100
		move.l	#$100,$dff084

		cmp.l	#970752,d0		;Check for original
		bne	_Crack

		lea	_LoadFileStart(pc),a0	;Source
		lea	$10000,a1		;Destination
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_Decrunch(a2)

	
		bsr		setup_expansion
		

		lea	_PL_OrigBoot(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		jmp	$2a(a5)			;Start game

_PL_OrigBoot	PL_START
		PL_S	$44,6			;skip setting sp
		PL_W	$bc,$2200		;Colour bit fix (was $2020)
		PL_P	$296,_OrigMain		;Patch main
		PL_B	$58e,4	; number of memory chunks
		IFD	ONE_MEG_CHIP
		PL_B	$568,$46		; code in $1000a does that: 1MB chip OK
		ENDC
		
		
		PL_S	$242,$A		; skip kill 32 bit expansion
		
		PL_P	$80,jump_relocated_boot
		
		PL_P	$bbe,_Loader
		PL_P	$fd4,_Decrunch
		PL_END

;======================================================================

setup_expansion
		lea		$594(a5),a1
		IFD	HALF_MEG_CHIP	
		; cannot use patch, insert
		; memory locations dynamically
		move.l	_expmem(pc),d0
		; align on $80000 boundary
		; if not done, game graphics are borked
		add.l	#$80000,d0
		and.l	#$FFF80000,d0
		;clr.w	d0		; align, like the game does (not enough)
		REPT	3
		move.l	d0,(a1)+
		add.l	#$80000,d0
		ENDR
		ELSE
		; chip first
		move.l	#$80000,(a1)+
		move.l	_expmem(pc),d0
		; align on $80000 boundary
		; if not done, game graphics are borked
		add.l	#$80000,d0
		and.l	#$FFF80000,d0
		;clr.w	d0		; align, like the game does (not enough)
		REPT	2
		move.l	d0,(a1)+
		add.l	#$80000,d0
		ENDR
		ENDC
		rts
		
;======================================================================

; located in 60000, jumps in $60086
jump_relocated_boot
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	SUBA.L	A1,A2			;10080: 95c9
	; jumps here, just relocated
	JMP	0(A0,A2.L)		;10082: 4ef0a800
	
;======================================================================

_OrigMain	movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_OrigMain(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2

		move.w	#0,d0			;Attn flags
		move.w	d0,d1
		; A0-A3 contains memory blocks
		jmp	$4200.w

_PL_OrigMain	PL_START
		PL_S	$4216,4			;setting sp
		PL_S	$4200+$6d76,4		;setting sp
		PL_S	$42d0,$42d6-$42d0	;move.b #0,($200,a0)
;		PL_PS	$4756,_Copperlist	;move.l #$486,($80,a6)
;		PL_W	$475c,$4e71

		; remove expansion memory alignment
		; this works but if we use unaligned memory then
		; some characters are trashed
		;;PL_NOP	$4e4a,2

		PL_PS	$4ee6,_Keyboard		;Detect quit key
		PL_PS	$4f38,_Keyboard		;Detect quit key
		PL_W	$9dca,$7404		;moveq #1,d2 -> moveq #4,d2
		PL_PS	$9dde,_DiskChange
		PL_B	$9dea,$60
		PL_R	$9f7c			;Loading blank file
		PL_P	$a020,_Loader		;RNC loader
		PL_P	$a4a0,_Decrunch		;RNC decruncher
		PL_L	$a6b2,$203c6aa1		;Copylock called: $33454 jsr $a6b2
		PL_L	$a6b6,$8aaf21fc
		PL_L	$a6ba,$6aa18aaf
		PL_L	$a6be,$1d064e75
		PL_P	$b0a0,_Copylock
		
		PL_P	$05120,fix_2nd_button
		
		PL_IFC1X	4
		PL_NOP	$13cd0,2
		PL_ENDIF
		
		PL_IFC1		; no need to enable it if no trainer
		PL_PS	$15CFC,energy_trainer
		PL_ENDIF
		
		PL_IFC2X	0
		PL_P	$33454,change_settings
		PL_ENDIF
		
		PL_IFC1X	5
		PL_PSS	$BB46,set_cheat,2
		PL_ENDIF
		
		PL_IFC1X	6
		PL_PSS	$0bb24,set_fiona_mode,2
		PL_ENDIF
		
		PL_PS	$05638,fix_sound_af
		PL_END

;======================================================================

fix_sound_af:
	cmp.l	#CHIPMEMSIZE,a1
	bcs.b	.ok
	; exit routine immediately
	move.l	(a7)+,a0
	addq.l	#4,a7
	rts
	
.ok
	MOVE.W	2(A1),2(A2)
	rts
	
;======================================================================

set_fiona_mode:
	move.w	#1,$40d2.W	; enable bloodless menu
	CLR.W	$40d4.W
	rts
	
set_cheat:
	move.w	#1,$40c6.W	; enable diagnostics menu
	CLR.W	$40c8.W
	rts
	
;======================================================================

energy_trainer
	move.l	d0,-(a7)
	move.l	_trainer(pc),d0
	cmp.l	#$1F5E,a0
	bne.b	.no_p1
	btst	#1,d0
	beq.b	.no_i1	; also cpu
	move.w	#$78,d1	; full energy
.no_i1
	btst	#3,d0
	beq.b	.out
	clr.w	d1		; instant player kill
	bra.b	.out
.no_p1
	cmp.l	#$2044,a0
	bne.b	.out
	btst	#0,d0
	beq.b	.no_i2
	move.w	#$78,d1	; full energy
.no_i2
	btst	#2,d0
	beq.b	.out
	clr.w	d1		; instant player kill
.out
	move.l	(a7)+,d0
	MOVE.W	D1,26(A0)		;15cfc: 3141001a
	TST.W	D1			;15d00: 4a41
	rts
	
;======================================================================

fix_2nd_button
	; ack potgo, needed with some 2-button joysticks
	move.w	#$FF01,_custom+potgo
	; original game
	move.w	#$20,_custom+intreq
	rte
	
;======================================================================

change_settings
	move.w	#$8101,$138C.W	; 2-button joypads
	JMP	$a6b2

;======================================================================

_Crack		move.l	#$400,d0
		move.l	#$1200,d1
		moveq	#1,d2
		lea	$10000,a0
		move.l	a0,a5
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		
		lea	_PL_BootCrack(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		jmp	$2a(a5)			;Start game

_PL_BootCrack	PL_START
		PL_S	$44,6			;setting sp
		PL_W	$bc,$2200		;Colour bit fix (was $2020)
		PL_P	$296,_CrackMain		;Patch main
		PL_B	$58e,4	 	; number of memory chunks
		IFD		ONE_MEG_CHIP
		PL_B	$568,$46
		ENDC
		

		PL_P	$ca2,_CrackLoader
		PL_P	$fd4,_Decrunch
		PL_END

;======================================================================

_CrackMain	movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_CrackMain(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2

		move.w	#0,d0			;Attn flags
		move.w	d0,d1
		jmp	$4200.w

_PL_CrackMain	PL_START
		PL_S	$4216,4			;setting sp
		PL_S	$4200+$6d76,4		;setting sp
		PL_S	$42d0,$42d6-$42d0	;move.b #0,($200,a0)
		PL_PS	$4ee6,_Keyboard		;Detect quit key
		PL_PS	$4f38,_Keyboard		;Detect quit key
		PL_R	$9f7c			;Loading blank file
		PL_P	$a0f0,_CrackLoader	;RNC loader
		PL_P	$a4a0,_Decrunch		;RNC decruncher
		PL_L	$a6b2,$203c6aa1		;Copylock called: $33454 jsr $a6b2
		PL_L	$a6b6,$8aaf21fc
		PL_L	$a6ba,$6aa18aaf
		PL_L	$a6be,$1d064e75
		PL_P	$b0a0,_Copylock
		PL_END

;======================================================================
;
;_Copperlist	move.l	#$fffffffe,$438
;		move.l	#$fffffffe,$4b2
;
;		move.l	#$486,($80,a6)		;Stolen code
;		rts
;
;_cbswitch	move.l	#$100,(cop2lc+_custom)	;Required for save games :)
;		move.w	#$ffff,(bltafwm+_custom)
;		move.w	#$ffff,(bltalwm+_custom)
;		jmp	(a0)
;
;======================================================================

_Copylock	movem.l	d0-a7,-(a7)
		move.l	#$3d742cf1,(a7)
		move.l	(a7),$60.w
		lea	8(a7),a0
		lea	$24(a7),a1
		move.l	#$955e7551,d0		;Decryption ID
		moveq	#2,d2
		move.l	d0,d3
		lsl.l	#2,d0
.loop		move.l	(a0)+,d1
		sub.l   d0,d1
		move.l  d1,(a1)+
		add.l   d0,d0
		addq.b  #1,d2
		cmp.b   #8,d2
		bne.s   .loop
		move.l  d3,(a1)+
		movem.l (a7)+,d0-a0
		rts

;======================================================================

_CrackLoader	cmp.l	#$1600,d5		;Offset for table of each disk
		bne	_DoCrackLoad

		lea	_CrackDiskNum(pc),a1
		move.b	d1,(a1)

_DoCrackLoad	movem.l	d1-d2/a0-a2,-(sp)	;d5 = offset, d6 = length, a0 = buffer
		cmp.w	#0,d6			;Skip dummy loads
		beq	_CrackLoadDone
		move.l	d5,d0			;d0 = Offset (bytes)
		move.l	d6,d1			;d1 = Length (bytes)
		moveq	#0,d2
		move.b	_CrackDiskNum(pc),d2	;d2 = Disk number
		move.l  _resload(pc),a2
		jsr	resload_DiskLoad(a2)
_CrackLoadDone	moveq	#0,d0
		movem.l	(sp)+,d1-d2/a0-a2
		rts

;======================================================================

_DiskChange	addq.w	#1,$582
		cmp.w	#3,$582
		bcs	_Not1stDisk
		clr.w	$582
_Not1stDisk	rts

;======================================================================

_Loader		movem.l	d1-d2/a0-a2,-(sp)	;d0 = drive, d1 = offset, d2 = blocks, a0 = buffer
		cmp.w	#0,d1			;Skip dummy loads
		beq	_LoadDone
		exg.l	d0,d1
		exg.l	d1,d2
		sub.l	#24,d0
		mulu	#$200,d0		;d0 = Offset (bytes)
		mulu	#$200,d1		;d1 = Length (bytes)
		addq	#1,d2			;d2 = Disk number
	;	bset	#31,d2			;dump loaded files
		move.l  _resload(pc),a2
		jsr	resload_DiskLoad(a2)
_LoadDone	moveq	#0,d0
		movem.l	(sp)+,d1-d2/a0-a2
		rts

;======================================================================

_Keyboard	cmp.b	_keyexit(pc),d0
		beq	_exit

		bset	#6,($e00,a0)		;Stolen code
		rts

;======================================================================

SHIFT_OFFSET = -$80
UNPACKED_LEN = $8C00
WRONG_ADDRESS = $77400

_Decrunch
	movem.l	d1-d7/a0-a6,-(sp)
	
	IFD		HALF_MEG_CHIP
	; game loads data at $77400 but decrunched length
	; makes the end at exactly $80000, which makes the
	; decruncher trigger an access fault just after $80000 if
	; chipmem is just 512k (no impact for 1MB)
	; (decruncher bug reads 3 or 4 bytes too much after the limit)
	; so we move the data and move it back afterwards
	cmp.l	#WRONG_ADDRESS,a0
	bne	.no_access_fault

	; let's move the unpacked data just before
	move.l	a0,a2
	move.l	4(a2),d0	; unpacked length
	cmp.l	#UNPACKED_LEN,d0
	bne	.no_access_fault
	move.l	8(a2),d0	; packed length

	
	lea	(SHIFT_OFFSET,a2),a3	; there's some room there
	lsr.w	#2,d0
	add.l	#10,d0
.copy
	move.l	(a2)+,(a3)+
	dbf		d0,.copy
	lea	(SHIFT_OFFSET,a0),a0	; source
	; same dest
	move.l	a0,a1
	move.l	_resload(pc),a2
	jsr		resload_Decrunch(a2)
	; now move memory back
	lea		WRONG_ADDRESS+UNPACKED_LEN,a1	; final dest (end)
	lea		(SHIFT_OFFSET,a1),a0			; source (end)
	move.w	#UNPACKED_LEN/4-1,d1
.copy2
	move.l	-(a0),-(a1)
	dbf		d1,.copy2
	bra.b	.out
.no_access_fault
	ENDC	
	
	move.l	_resload(pc),a2
	jsr		resload_Decrunch(a2)

.out
	movem.l	(sp)+,d1-d7/a0-a6
	rts
	
	movem.l	d0-d7/a0-a6,-(sp)
		lea	(-$180,sp),sp
		movea.l	sp,a2
		bsr.w	_ReadLong
		moveq	#0,d1
		cmpi.l	#$524E4301,d0
		bne.w	_Rob_15
		bsr.w	_ReadLong
		move.l	d0,($180,sp)
		lea	(10,a0),a3
		movea.l	a1,a5
		lea	(a5,d0.l),a6
		bsr.w	_ReadLong
		lea	(a3,d0.l),a4
		clr.w	-(sp)
		cmpa.l	a4,a5
		bcc.b	_Rob_6
		moveq	#0,d0
		move.b	(-2,a3),d0
		lea	(a6,d0.l),a0
		cmpa.l	a4,a0
		bls.b	_Rob_6
		addq.w	#2,sp
		move.l	a4,d0
		btst	#0,d0
		beq.b	_Rob_1
		addq.w	#1,a4
		addq.w	#1,a0
_Rob_1		move.l	a0,d0
		btst	#0,d0
		beq.b	_Rob_2
		addq.w	#1,a0
_Rob_2		moveq	#0,d0
_Rob_3		cmpa.l	a0,a6
		beq.b	_Rob_4
		move.b	-(a0),d1
		move.w	d1,-(sp)
		addq.b	#1,d0
		bra.b	_Rob_3

_Rob_4		move.w	d0,-(sp)
		adda.l	d0,a0
_Rob_5		lea	(-$20,a4),a4
		movem.l	(a4),d0-d7
		movem.l	d0-d7,-(a0)
		cmpa.l	a3,a4
		bhi.b	_Rob_5
		suba.l	a4,a3
		adda.l	a0,a3
_Rob_6		moveq	#0,d7
		move.b	(1,a3),d6
		rol.w	#8,d6
		move.b	(a3),d6
		moveq	#2,d0
		moveq	#2,d1
		bsr.w	_Rob_21
_Rob_7		movea.l	a2,a0
		bsr.w	_Rob_24
		lea	($80,a2),a0
		bsr.w	_Rob_24
		lea	($100,a2),a0
		bsr.w	_Rob_24
		moveq	#-1,d0
		moveq	#$10,d1
		bsr.w	_Rob_21
		move.w	d0,d4
		subq.w	#1,d4
		bra.b	_Rob_10

_Rob_8		lea	($80,a2),a0
		moveq	#0,d0
		bsr.w	_Rob_17
		neg.l	d0
		lea	(-1,a5,d0.l),a1
		lea	($100,a2),a0
		bsr.w	_Rob_17
		move.b	(a1)+,(a5)+
_Rob_9		move.b	(a1)+,(a5)+
		dbra	d0,_Rob_9
_Rob_10		movea.l	a2,a0
		bsr.w	_Rob_17
		subq.w	#1,d0
		bmi.b	_Rob_12
_Rob_11		move.b	(a3)+,(a5)+
		dbra	d0,_Rob_11
		move.b	(1,a3),d0
		rol.w	#8,d0
		move.b	(a3),d0
		lsl.l	d7,d0
		moveq	#1,d1
		lsl.w	d7,d1
		subq.w	#1,d1
		and.l	d1,d6
		or.l	d0,d6
_Rob_12		dbra	d4,_Rob_8
		cmpa.l	a6,a5
		bcs.b	_Rob_7
		move.w	(sp)+,d0
		beq.b	_Rob_14
_Rob_13		move.w	(sp)+,d1
		move.b	d1,(a5)+
		subq.b	#1,d0
		bne.b	_Rob_13
_Rob_14		bra.b	_Rob_16

_Rob_15		move.l	d1,($180,sp)
_Rob_16		lea	($180,sp),sp
		movem.l	(sp)+,d0-d7/a0-a6
		rts

_Rob_17		move.w	(a0)+,d0
		and.w	d6,d0
		sub.w	(a0)+,d0
		bne.b	_Rob_17
		move.b	($3C,a0),d1
		sub.b	d1,d7
		bge.b	_Rob_18
		bsr.b	_Rob_23
_Rob_18		lsr.l	d1,d6
		move.b	($3D,a0),d0
		cmpi.b	#2,d0
		blt.b	_Rob_20
		subq.b	#1,d0
		move.b	d0,d1
		move.b	d0,d2
		move.w	($3E,a0),d0
		and.w	d6,d0
		sub.b	d1,d7
		bge.b	_Rob_19
		bsr.b	_Rob_23
_Rob_19		lsr.l	d1,d6
		bset	d2,d0
_Rob_20		rts

_Rob_21		and.w	d6,d0
		sub.b	d1,d7
		bge.b	_Rob_22
		bsr.b	_Rob_23
_Rob_22		lsr.l	d1,d6
		rts

_Rob_23		add.b	d1,d7
		lsr.l	d7,d6
		swap	d6
		addq.w	#4,a3
		move.b	-(a3),d6
		rol.w	#8,d6
		move.b	-(a3),d6
		swap	d6
		sub.b	d7,d1
		moveq	#$10,d7
		sub.b	d1,d7
		rts

_ReadLong	moveq	#3,d1
_ReadByte	lsl.l	#8,d0
		move.b	(a0)+,d0
		dbra	d1,_ReadByte
		rts

_Rob_24		moveq	#$1F,d0
		moveq	#5,d1
		bsr.b	_Rob_21
		subq.w	#1,d0
		bmi.b	_Rob_30
		move.w	d0,d2
		move.w	d0,d3
		lea	(-$10,sp),sp
		movea.l	sp,a1
_Rob_25		moveq	#15,d0
		moveq	#4,d1
		bsr.b	_Rob_21
		move.b	d0,(a1)+
		dbra	d2,_Rob_25
		moveq	#1,d0
		ror.l	#1,d0
		moveq	#1,d1
		moveq	#0,d2
		movem.l	d5-d7,-(sp)
_Rob_26		move.w	d3,d4
		lea	(12,sp),a1
_Rob_27		cmp.b	(a1)+,d1
		bne.b	_Rob_29
		moveq	#1,d5
		lsl.w	d1,d5
		subq.w	#1,d5
		move.w	d5,(a0)+
		move.l	d2,d5
		swap	d5
		move.w	d1,d7
		subq.w	#1,d7
_Rob_28		roxl.w	#1,d5
		roxr.w	#1,d6
		dbra	d7,_Rob_28
		moveq	#$10,d5
		sub.b	d1,d5
		lsr.w	d5,d6
		move.w	d6,(a0)+
		move.b	d1,($3C,a0)
		move.b	d3,d5
		sub.b	d4,d5
		move.b	d5,($3D,a0)
		moveq	#1,d6
		subq.b	#1,d5
		lsl.w	d5,d6
		subq.w	#1,d6
		move.w	d6,($3E,a0)
		add.l	d0,d2
_Rob_29		dbra	d4,_Rob_27
		lsr.l	#1,d0
		addq.b	#1,d1
		cmpi.b	#$11,d1
		bne.b	_Rob_26
		movem.l	(sp)+,d5-d7
		lea	($10,sp),sp
_Rob_30		rts

;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_trainer	dc.l	0
		
		dc.l	0
		
wrong_memory_message
	dc.b	"512k chipmem slave needs 24-bit expansion memory",0
	even
	
_LoadFileStart	dc.l	$524E4301,$1200,$FBE,$6F18670B,$101A411
		dc.l	$112ABB73,$87353333,$43648426,$64A82A40,$E08E6100
		dc.l	$3686708,$43FA0560,$12BC0046,$41C1657E,$8074025D
		dc.l	$8F2C5C5E,$5250B0A9,$FFFC6702,$22C057CA,$FFF04DF9
		dc.l	$DFF0D0,$E2FC2700,$3D7C7FFF,$9A9693,$94164F02
		dc.l	$B1078000,$41060000,$BB13FFAE,$B3FC0005,$EE00630E
		dc.l	$AE940612,$6206A1,$74074CE5,$48E700C0,$303C047F
		dc.l	$20D951C8,$EA3D4CDF,$30045FA,$895C9,$4EF0A84B
		dc.l	$D0D4420F,$9F42983D,$4B157910,$8F352215,$36621C8
		dc.l	$6CE132,$7EA7FC20,$2D4800,$80426E00,$88DC4520
		dc.l	$20014B46,$1026841,$40B5A08,$90E00A2C,$81008E32
		dc.l	$CA380092,$D0009448,$20F4C100,$90CB4900,$9C0841C0
		dc.l	$D0A59A01,$CB152C1A,$35398390,$414301F6,$C40660F
		dc.l	$8ED4F868,$2128684,$1A190508,$97F4CC08,$A47E0304
		dc.l	$6220184E,$6A043A51,$CFFFF849,$11169228,$DAF0880A
		dc.l	$EFBA8C6A,$2670A01,$66F06000,$FF2E3D79,$1B91C784
		dc.l	$BA4DB541,$F8040043,$D7C44E31,$70007218,$740C7600
		dc.l	$283C6D26,$467AF8C0,$310F0A3A,$661EDDBC,$1F064100
		dc.l	$C0C4107,$806DE82F,$BC85234B,$2CD64FA2,$2E00282F
		dc.l	$2F012F07,$94C17212,$11171CC8,$565C4606,$201FA108
		dc.l	$A2D145F4,$76170AF4,$CA6380FC,$AA488C10,$AA602C13
		dc.l	$A40C586D,$64AA805,$92660C13,$69064842,$CB3100FA
		dc.l	$6113D1DA,$253F073E,$5A829A28,$30002029,$85DB2200
		dc.l	$244A36EA,$890E7302,$82001FFF,$FF068255,$B5FFE28A
		dc.l	$E08A1719,$2828960C,$84FDA863,$AC959BB,$42144A8
		dc.l	$D5204463,$6D63AE42,$3A210964,$3E1F4A40,$57CFFFA8
		dc.l	$EAED670C,$50DE02BA,$C81B8AE2,$594B164C,$D00F0043
		dc.l	$AFA42049,$20450D4A,$282604D3,$28203A02,$D4287832
		dc.l	$2C01284E,$756A7E02,$C6A66699,$19A9341,$8E76F374
		dc.l	$CC99725E,$8FC2EC8,$DA0C7994,$A36710B4,$94050936
		dc.l	$E67432DA,$EC0F2EBE,$6B6B8032,$39021141,$3E049
		dc.l	$94D5014E,$7579CFCE,$60FE1C20,$4BCE49BF,$E001082D
		dc.l	$BB6A8A1B,$660408C0,$B86B06,$6ECDE758,$77B1EAF9
		dc.l	$EA9D53D,$6E018061,$C002CE18,$734DF242,$6E8B5DCE
		dc.l	$72CC8DFC,$4240E6A4,$F180721F,$3CC051C9,$FFFCE0F6
		dc.l	$72022060,$2108D860,$61224A80,$A32B00,$6A866114
		dc.l	$18F000F8,$2F239E07,$D0D56A04,$201F48E7,$60C02C06
		dc.l	$8A4EAEFF,$3AC90F06,$85352833,$1F643FA,$E521247
		dc.l	$C200E8E,$ED0F8E3D,$F724ED00,$2C7C0138,$67A2712
		dc.l	$1848816B,$A9A4112,$D8241B60,$C141844,$41C2ECDC
		dc.l	$D40E5345,$6AE0D2FC,$1F4043E9,$FFCCFFD4,$3E065247
		dc.l	$CE7C5293,$C7D0BE00,$288D7CC0,$94B02F08,$1EFB8052
		dc.l	$50205F33,$FCD6B46B,$FE9C4E73,$303A016E,$B07A016A
		dc.l	$67FAB67B,$770D88D4,$746166,$C5708524,$3C66E4F2
		dc.l	$283C331D,$7C007E06,$360210C0,$10D52BDF,$30FCFFFE
		dc.l	$50770182,$30C38432,$3E24902,$41077730,$C1D6440C
		dc.l	$4723F16E,$4964447,$3B524032,$EFAA6E1C,$D0DE6847
		dc.l	$CC4844E8,$4C4842E8,$5A0C4260,$6660434,$3C06066F
		dc.l	$AE398B1E,$3019302F,$855D769B,$C87863E0,$E27307E4
		dc.l	$4E1EE69F,$9C1409AB,$DF011B29,$F06AB209,$9915A5FE
		dc.l	$47AF8895,$8A43F34B,$AC47EB14,$BC901018,$67340430
		dc.l	$2933096F,$4551E07,$610460E8,$F874452E,$D294004A
		dc.l	$406B16D4,$C0700612,$9245EA26,$E1020BF4,$FEE85289
		dc.l	$FEBDA99,$56455249,$46590044,$49534B4F,$4B00F4EC
		dc.l	$524F525B,$31204D,$45474142,$59544520,$4F462052
		dc.l	$414D1580,$45515549,$59F84400,$5443B015,$494E53B9
		dc.l	$E542020,$66C61247,$544F4630,$8D085458,$5D58E4B4
		dc.l	$E1887205,$E99848E7,$C00035BA,$CC680F61,$FF764C
		dc.l	$DF0003DB,$52C36A8A,$8BFD0136,$FB3D5952,$4E43935E
		dc.l	$964E9E0,$60B2955,$4A154D33,$9890A12A,$6665424
		dc.l	$33335426,$84083DE0,$F1DB46F0,$E84D9C0F,$5C494C42
		dc.l	$4DBCED48,$449C1D00,$14012D21,$CDCD17E2,$7BC3F608
		dc.l	$1013DC7,$434D4150,$8AFE0CFA,$ADFFAF29,$17FF424F
		dc.l	$4459DB0C,$1FF77B79,$C0F35C94,$3FFE030,$FEDA3103
		dc.l	$FA00F86D,$1E01F276,$2C040010,$40682104,$17600F01
		dc.l	$5F573FD6,$CDFFFCBC,$43FF8000,$FEC05AF0,$16AD0783
		dc.l	$1102FAFB,$9559081B,$591303C0,$12383BAF,$7FFC0F8
		dc.l	$D1E2807F,$E0B41C0F,$C2A0ED7C,$FD000B08,$20996F
		dc.l	$C6ED4080,$10AEC010,$DBC07C0,$99010FFF,$D94AF000
		dc.l	$1F079CC0,$4D1F082A,$E09DF40A,$10008090,$DF5398F6
		dc.l	$3A10E370,$3B9E0FC0,$C2351FFE,$FCFA899B,$796333F
		dc.l	$910D668,$302B20,$19BA705,$10041608,$40B8231F
		dc.l	$C0B44803,$CE582BC0,$1037032,$7FB6B481,$19D44605
		dc.l	$20EFF240,$2C840FB3,$31AF3F61,$A67FFC07,$4419970D
		dc.l	$A698FF25,$CBD82401,$80088746,$CB660220,$576BF986
		dc.l	$79177FC5,$4CB29736,$C1E42F04,$6303802C,$1BF15F04
		dc.l	$4AB169B2,$24EA027C,$4B101EDB,$BBBBFA1,$8001DFDD
		dc.l	$103FFC14,$ABF56F40,$BF4DFA18,$320540A3,$AC20B102
		dc.l	$440024A,$F7801B03,$38F39FF0,$71C4E2D,$F8B06280
		dc.l	$15E09603,$4592304,$473719C,$67E91003,$10B9228B
		dc.l	$BE214B07,$3664433E,$FFF0221F,$1FD9B708,$FD520A08
		dc.l	$4A664,$894A820,$8D1A0F69,$4D3F6445,$FF90CD0D
		dc.l	$F2013F10,$520464E6,$E510C002,$D142100A,$D94090D7
		dc.l	$1E84551E,$7FFE8681,$14F27BC8,$C721F86F,$A21A0821
		dc.l	$2D2620A8,$A0840D2A,$3C0EA437,$3C820A0F,$802AE8F3
		dc.l	$5182420E,$F358B4CC,$59024039,$5301168E,$98577878
		dc.l	$CCD4FC45,$CF401,$E3A87984,$5221FE75,$BA01028B
		dc.l	$6152D061,$8A0FF01E,$A9DC70C2,$1C7747E6,$160203C3
		dc.l	$2955FA31,$ECDF7204,$88802016,$13010401,$45FA4E4C
		dc.l	$C0C35C1C,$FE0B398,$1FC7300F,$30F8889,$7698B9FD
		dc.l	$8B0110F4,$80D7E107,$801DF1B2,$C041A48E,$9BC3131E
		dc.l	$EFAA0879,$D0B2052,$C521631B,$20041021,$4323DF7C
		dc.l	$7DCD500F,$65C938,$866A0381,$A9893FF8,$1F3C7A11
		dc.l	$362A69D7,$4C0C40F4,$C0657057,$191E07CD,$96E91D3F
		dc.l	$F058B321,$E27841D3,$144764CD,$A35580FD,$7DA0084
		dc.l	$A0093C78,$BAA90E01,$36A09DBF,$7FA057,$F042FF6D
		dc.l	$51102BB,$9131EB04,$807F4DD4,$464D7870,$D4D51C1A
		dc.l	$F086BAD8,$A4FC43D4,$E06B0A84,$FDBC3D22,$ADA607A2
		dc.l	$AD0CB602,$1061AFF0,$91993803,$B0D5E059,$C2C0A6B4
		dc.l	$FB45C951,$1F26DB44,$499F310,$FC21C704,$20F800B9
		dc.l	$9145EFFE,$FF1342BF,$E007FC70,$73C0EB9,$F40DCB51
		dc.l	$DB100802,$88D15C69,$29F731AF,$36186FE,$F0F261B6
		dc.l	$2AF08179,$A801732D,$501C481,$901C2093,$65400B9C
		dc.l	$10A1851A,$F99BBC0,$2707FFE0,$FFC93B7,$3C003E
		dc.l	$1DCA3373,$73F35E34,$E9C50910,$C446AC1E,$F3C0DC09
		dc.l	$C00F8D78,$F440F29,$F3472120,$DD7628C5,$46D843C
		dc.l	$D0B38022,$21B340BB,$D0E000F0,$734E42FD,$856E0240
		dc.l	$1069739B,$E4B0B603,$80100183,$8E1A78E7,$3947841F
		dc.l	$6E3E0725,$CBE0067D,$4ECB84FC,$B72380A3,$C5E8D02
		dc.l	$17DE1E91,$F0AFC8FE,$915EA271,$B8E18ABC,$3278FC15
		dc.l	$8B044CE5,$20FDD5C5,$613620F7,$A50E1B92,$23078003
		dc.l	$FCB43D16,$EFF0003,$FEE83302,$6BCD0104,$D516BD94
		dc.l	$4ED20186,$EE40900A,$3C0B4B9,$DF9FDBB2,$19CA3252
		dc.l	$D2D00067,$6204CD75,$60882CD,$EB740828,$E7A838E0
		dc.l	$2550AC00,$4CA403F0,$C2AF66B9,$80E0671E,$3228735
		dc.l	$FE03360C,$8AAA36F,$8C402103,$A2F96794,$F001E43
		dc.l	$3E04FE5,$F117563,$E803CAB,$A3FC223D,$669A0920
		dc.l	$F34380F7,$418FF001,$8020FE1D,$E0E001B,$51C3F59
		dc.l	$13E03F80,$B952A326,$A3E7D8E4,$D40D423B,$40FE38A0
		dc.l	$696FDD01,$AAD196C9,$10C99581,$BC781942,$1532B0A5
		dc.l	$F05C2780,$727A7FE6,$388900A5,$5B1F28B4,$2EDB1D38
		dc.l	$B5E2D4D0,$A5401C12,$50B48951,$2080812,$20A21480
		dc.l	$96FD8035,$33A52FF,$87FFFF18,$3BEB941F,$8D7110AB
		dc.l	$F3FCEAE4,$CE719308,$F400E999,$31FEF333,$FFBB01FE
		dc.l	$36243830,$78701C7C,$18785F9E,$5E73383C,$1844100E
		dc.l	$C64044C2,$EF8E783C,$40402C6,$8C1D8BD9,$B49F6470
		dc.l	$CCD82C60,$30C824CC,$384C3C6C,$E0F03CCC,$307CCCC0
		dc.l	$EEE63CAF,$1E48C7CC,$F04C4C46,$C6CC0C0F,$D24C300C
		dc.l	$C483860,$844CC6C,$4C646CC0,$C060BE90,$CF8C0FE
		dc.l	$E664CC64,$4CC030CC,$CCC66CD8,$1810328B,$27D45BA9
		dc.l	$8980C79,$584CF860,$4CD8D840,$FCD8C9F0,$C0D6F664
		dc.l	$F85A2460,$A7CDD638,$7830303C,$8332E430,$E6EC563D
		dc.l	$FC0CCC10,$C418FC7A,$37F0DCA2,$763D6E08,$D8C0C6DE
		dc.l	$4C1CC8F8,$6BD6FEB0,$29602031,$506B7309,$393160F0
		dc.l	$59DA1330,$FDCCFFC0,$FFCC1130,$D86583C6,$CED592D0
		dc.l	$E30C78EE,$6C3085B3,$4BBAFF78,$25FCF8A7,$ED698FEF
		dc.l	$47E0CCF8,$78F8FCC0,$78BD6C70,$C67CC6C6,$78C074CC
		dc.l	$E9653073,$E130FCA1,$5E73667F,$FC4E56FF,$DE3A0002
		dc.l	$4500033D,$453CFD3D,$41FFE03D,$42FFE23D,$43FFE42D
		dc.l	$44FFEE2D,$48FFE62D,$49FFEAE4,$58E2EC98,$C7015240
		dc.l	$3D40FFF2,$70003602,$6721861E,$D641B67C,$7806EB8
		dc.l	$158C48C1,$82A5030C,$6E4F95F2,$6702D241,$22A1F448
		dc.l	$E17EF694,$B164302E,$CC25720C,$9240B26E,$D2356F04
		dc.l	$322EA552,$F8615E66,$282615E2,$90E70AF8,$671EE2B6
		dc.l	$CEF8E188,$D080D1AE,$C1542F8,$84F6F2D1,$C5DDF460
		dc.l	$BE2FA483,$2EE201F,$67207200,$7F24F43D,$9DE249C2
		dc.l	$3BBCD2DA,$DB0BFFFC,$2F410026,$4E5E4A80,$4CDF3FFE
		dc.l	$4E757A02,$76792BBF,$1F8701D,$83965DB,$7D26FB38
		dc.l	$67282AA3,$1EA204D,$224D700B,$D0FC040A,$4258D259
		dc.l	$D1D70038,$7B4BC857,$4D611A98,$9C906712,$183770CC
		dc.l	$F401BC46,$6EE07DC1,$51CDFFB4,$60644359,$3B337C40
		dc.l	$92480,$10009664,$D7BE409E,$40059523,$48002063
		dc.l	$3903819C,$14537E7E,$33FC998B,$81CF2435,$62FEC7EE
		dc.l	$36A33E09,$C4F3F77E,$8297AE6,$1F660ABA,$5C6466F2
		dc.l	$70FF6002,$70004FE2,$27A32C3,$96B2B9B6,$5BCF6C16
		dc.l	$E2FA4D2F,$FC24FA9B,$E635945E,$78B667A6,$C06306F0
		dc.l	$6C9E78D0,$7E85AE9E,$EA258E0C,$55489167,$D18A41ED
		dc.l	$20182218,$28055BF,$84028126,$9BD08080,$81222EA6
		dc.l	$E408C19A,$55B38026,$4840B0,$F5665CE0,$4838A3FB
		dc.l	$66540211,$F76D2212,$F9D253A4,$B0016C16,$680DB9D5
		dc.l	$5CB64066,$3C224A61,$7A45EA83,$2E52626E,$DA3A3630
		dc.l	$1D720074,$7E550E3,$1151CA24,$94D241DB,$C1319BFA
		dc.l	$812C0C3F,$B5FF7269,$DD59ABF6,$C61B1B37,$1991D67C
		dc.l	$9A0BB8A8,$7884AB0C,$7267064A,$6D74AD67,$F45ABC80
		dc.l	$A05632FF,$2418B580,$D78C68EC,$FAA01D22,$A4924180
		dc.l	$414CDF01,$62E93F8,$E0707F45,$E8F94926,$3C3DB428
		dc.l	$D8BAF560,$241AC283,$C483D281,$8282B384,$22C42801
		dc.l	$8AC3EC0F,$3707B034,$3F00FFBD,$E90CDED0,$4041FB00
		dc.l	$504A506A,$2611630,$17E248E2,$D090ACEB,$472FF44
		dc.l	$40616A30,$9F602872,$55768804,$EDB0518C,$102F0170
		dc.l	$6A21FF61,$52221F32,$58EA82BB,$5DD00E42,$50611013
		dc.l	$C0D169BB,$15B5DF86,$3F011039,$62F68BAD,$7F5437DE
		dc.l	$56010380,$5701667E,$E21A10DE,$82833DD,$67040880
		dc.l	$23246,$D14A0067,$2A88D261,$CC4A016B,$C6F01E4
		dc.l	$39007629,$9C31C7C9,$70036148,$301F5300,$66D28F67
		dc.l	$33FC047B,$B34A6EFF,$E46A1E13,$7213C198,$F531C156
		dc.l	$8001811E,$C201C1C7,$AE814D7F,$E9088146,$55B7DAD4
		dc.l	$7064D080,$611E7E94,$BFDE4679,$F6538066,$F0187FC3
		dc.l	$8B1C6718,$13FC5B62,$631B0E0C,$CCD43CDB,$9031D5B1
		dc.l	$B3AF820E,$73FFFE4F,$EFFE8024,$4F3A7172,$C8045
		dc.l	$9A6D94E0,$3BFEEFE5,$622F4001,$8047E800,$A2A494D
		dc.l	$F50802F3,$15049F3,$4267BB37,$4FBB9985,$372BF1E2
		dc.l	$41F6B1CC,$633E7615,$C07CBD6,$BCE61604,$524C5248
		dc.l	$200802C6,$5CF8ABBD,$C867AD7B,$3F015200,$60F43F00
		dc.l	$D1C049EC,$FFE04C09,$5E84D3FF,$48E0FF00,$B9CB62F0
		dc.l	$97CCD7C8,$7E001C2B,$E15E1C13,$700272BB,$B840C500
		dc.l	$C4204AEE,$41EA00A5,$74C0B8E6,$1A64EE1,$5ADE70FF
		dc.l	$7210A638,$534460,$203DE870,$26FA6044,$804381CB
		dc.l	$FF15D752,$1AD91AC0,$5D866D44,$53406B1A,$1ADB7EC8
		dc.l	$1038F758,$1013EFA8,$7201EF69,$5341CC81,$8C801B67
		dc.l	$DD92BABB,$CE659030,$1F98C832,$1F1AC1AA,$77F86004
		dc.l	$2F41FEBA,$4FEF0188,$9D7F56EA,$3018C046,$9058743F
		dc.l	$1228003C,$9E016C82,$E330E2AE,$103D0C00,$1B79382A
		dc.l	$16120014,$301E2E,$3EA65ED4,$B8120592,$36F68204
		dc.l	$35CEA9E3,$DE01EEAE,$4846584B,$1C2360D4,$2392077E
		dc.l	$109E9DB8,$DC827203,$E1881018,$B359ACDA,$1F720561
		dc.l	$CAAAD27C,$34003600,$DB79A8CB,$4F700F72,$461B612
		dc.l	$C0CEAD7A,$C3F67001,$E29874C4,$F6816B07,$380343
		dc.l	$EF000CB2,$19663A7A,$1E36D53,$4530C52A,$248453E
		dc.l	$15347E3,$55E25669,$97FA7A10,$9A01EA6E,$30C6EB75
		dc.l	$FDEF3C1A,$39A0411,$450F4DAF,$BB05EB6E,$53463146
		dc.l	$42F3D473,$BBC0E288,$52010C01,$1166AE,$2D46E066
		dc.l	$BA0010A0,$B6DFBF01,0
		END
