; Cadaver slave by JOTD
;
; history:
; - v2.1: TAB key toggles infinite energy if CUSTOM5=1
; - v2.0: supports v1.03-1/2, v0.01, original and payoff
; - v1.x: JST versions.
; - v0.x: floppy patch for v0.01

; version description:
; - v1.03-1: V1.03 1992,PAL without copy protection (still original)
; - v1.03-2: V1.03 1992,PAL with copylock and stackframe error
; - v0.01  : V0.01 1990     with copylock and stackframe error

; v1.03-1: 
;00014630 1039 00bf e001           MOVE.B $00bfe001,D0
;00014636 0800 0007                BTST.L #$0007,D0

; Assembled with Barfly

	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	Cadaver.slave


	ENDC
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

;LOW_MEMORY
;CHIP_ONLY

	IFD	LOW_MEMORY
CHIPMEMSIZE = $80000
FASTMEMSIZE = $0
	ELSE
	IFD	CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = $0	
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
	ENDC
	ENDC
	
DECL_VERSION:MACRO
	dc.b	"3.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	19			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_EmulLineF
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_DontCache
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
		dc.l	FASTMEMSIZE			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_name		dc.b	"Cadaver & The Payoff",0
_copy		dc.b	"1990-1992 The Bitmap Brothers",0
_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_config:
		dc.b	"BW;"
		dc.b    "C3:L:Level set:Original Game,The Payoff;"
		dc.b    "C1:X:free savegames:0;"			
		dc.b    "C1:X:energy drain - F5 off - F6 back on:1;"			
		dc.b	0

		dc.b	"$","VER: slave "
	DECL_VERSION

		even

F5_KEY = $54
F6_KEY = $55

IGNORE_JOY_PORT0
IGNORE_JOY_DIRECTIONS
	include	ReadJoyPad.s
	
_start	
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

	bsr		_detect_controller_types
	
	;enable cache
	move.l	#WCPUF_Base_NCS|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	;get tags
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	;check & compute version

	bsr	_check_version

	;change savename

	move.l	_level_set(pc),D0
	beq.b	.skip
	lea	_savever(pc),A0
	move.b	#'p',(A0)		; payoff saves
.skip

	lea	$7FF00,A7
	
	MOVE.W	#$0100,$00DFF096
	MOVE.W	#$0000,$00DFF180
	IFD		LOW_MEMORY
	CLR.B	$1C.W		; expansion memory flag that can remain at 0
	clr.l	$80.W		; expansion memory
	ELSE
	IFD	CHIP_ONLY
	; we're going to disregard the 1MB chip memory setup ($1C = 1)
	lea	_expmem(pc),a0
	move.l	#$80000,(a0)
	ENDC
	
	move.l	_expmem(pc),d0
	add.l	#$9C,d0			; so program offset matches chip program offset
	move.l	d0,$80.W		; expansion base (then moved to $28.W)
	move.b	#2,$1C.W		; with expansion
	ENDC
	
	move.l	#$21000,D0
	MOVE.L	D0,A5
	MOVE.L	D0,$84.W

	move.l	D0,A0		; buffer
	moveq.l	#1,D2		; disk 1
	MOVE.L	#$0600,D0	; offset
	MOVE.L	#$0A00,d1	; length
	move.l	_resload(pc),A2
	jsr	resload_DiskLoad(a2)

	
	lea	_pl_boot_v103(pc),A0
	move.l	_version(pc),D0
	cmp.l	#3,D0
	bne.b	.patch
	lea	_pl_boot_v001(pc),A0
.patch
	move.l	A5,A1
	jsr	(resload_Patch,A2)
	
	jmp	(A5)


_jumper1_v103:
	lea	$84.W,A0
	movem.l	D0/D1/A0-A2,-(A7)
	move.l	A0,A1
	lea	_pl_intro_loader_v103_1(pc),A0
	cmp.l	#$08c3000f,$94.W
	beq.b	.patch
	; probably version 1.03 #2
	lea	_pl_intro_loader_v103_2(pc),A0
.patch	
	movem.l	_resload(pc),A2
	jsr	(resload_Patch,A2)

	movem.l	(A7)+,D0/D1/A0-A2

	jmp	(A0)

_jumper1_v001:
	lea	$84.W,A0
	movem.l	D0/D1/A0-A2,-(A7)
	move.l	A0,A1
	lea	_pl_intro_loader_v001(pc),A0
	movem.l	_resload(pc),A2
	jsr	(resload_Patch,A2)

	movem.l	(A7)+,D0/D1/A0-A2

	jmp	(A0)

_diskload_1:
	moveq.l	#0,D0
	bra	_robread
	

_diskload_2:
	move.l	_level_set(pc),D0
	beq.b	.skip
	moveq.l	#1,D0		; will load on disk.3
.skip
	addq.l	#1,D0
	bsr	_robread

	; unpack routine at 11444 (v1.03_1)
	; packed data header: size + C66xxxxx
	rts


_check_version:
	lea	_version(pc),A3

	MOVE.L	_resload(PC),A2
	
	moveq.l	#1,D2		; disk 1
	move.l	#8,D1		; 8 bytes to read
	move.l	#$13A,D0	; offset $13A
	lea	-8(A7),A7
	move.l	A7,A0
	jsr	(resload_DiskLoad,a2)
	move.l	A7,A0
	cmp.l	#'V1.0',(A0)
	bne.b	.notv1
	cmp.l	#'3pal',4(A0)
	bne.b	.notv1

	; v1.03 detected, but there are at least 2 v1.03 around!!!

	moveq.l	#1,D2		; disk 1
	move.l	#2,D1		; 2 bytes to read
	move.l	#$2C0E,D0	; offset $2C0E
	move.l	A7,A0
	jsr	(resload_DiskLoad,a2)
	move.l	A7,A0
	cmp.w	#$EE4,(A0)
	bne.b	.v103_2
	move.l	#1,(A3)		; version 1, 1.03-1, I've lost it!
	bra.b	.exit
.v103_2	
	move.l	#2,(A3)		; version 1, 1.03-2
	bra.b	.exit
.notv1
	cmp.l	#'01  ',(A0)
	bne.b	.notv001	; unsupported right now
	
	move.l	#3,(A3)		; version 0.01
	bra.b	.exit

.notv001
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit
	lea	8(A7),A7
	rts

; *** gets the save/load number

_getsavenum:
	cmp.b	#1,D0
	bcs	.error
	cmp.b	#$A,D0
	bne	.notzero
	move.l	A0,-(sp)
	lea	_savenum(pc),A0
	move.b	#'0',(A0)
	move.l	(sp)+,A0
	rts
.notzero
	add.b	#'0',D0
	move.l	A0,-(sp)
	lea	_savenum(pc),A0
	move.b	D0,(A0)		; sets the correct filename
	move.l	(sp)+,A0
	sub.b	#'0',D0
	rts
.error
	move.b	#$C,D0		; to tell there's an error
	rts


; load first part

_loadgame_part1:
	movem.l	D0-D6/A0-A6,-(A7)
	move.l	#$4400,D0		; length
	move.l	#0,D1			; file offset
	bsr	_loadgame
	movem.l	(A7)+,D0-D6/A0-A6
	rts

; load second part

_loadgame_part2:
	movem.l	D0-D6/A0-A6,-(A7)
	move.l	#$9800,D0		; length
	move.l	#$4400,D1			; file offset
	bsr	_loadgame
	movem.l	(A7)+,D0-D6/A0-A6
	rts

; save first part

_savegame_part1:
	movem.l	D0-D6/A0-A6,-(A7)
	move.l	#$4400,D0		; length
	move.l	#0,D1			; file offset
	bsr	_savegame
	movem.l	(A7)+,D0-D6/A0-A6
	rts

; load second part

_savegame_part2:
	movem.l	D0-D6/A0-A6,-(A7)
	move.l	#$9800,D0		; length
	move.l	#$4400,D1			; file offset
	bsr	_savegame
	movem.l	(A7)+,D0-D6/A0-A6
	rts


; < A0: save data
; < D0: length
; < D1: offset

_savegame:
	move.l	A0,A1			; buffer
	lea	_savename(pc),A0	; name
	move.l	_resload(pc),A2
	jsr	resload_SaveFileOffset(a2)
	moveq.l	#0,D7		; always OK
	rts

; < A0: save data
; < D0: length
; < D1: offset

_loadgame:
	move.l	D0,D5
	move.l	D1,D6

	move.l	A0,A1			; buffer
	lea	_savename(pc),A0	; name
	move.l	_resload(pc),A2		; resident loader

	; first check if file is there

	movem.l	D1/A0-A1,-(a7)
	jsr	resload_GetFileSize(a2)
	movem.l	(A7)+,D1/A0-A1
	moveq.l	#-1,D7
	tst.l	D0
	beq.b	.out			; not there: error

	; file is there, load it

	move.l	D5,D0
	move.l	D6,D1
	jsr	resload_LoadFileOffset(a2)
	moveq.l	#0,D7
.out
	rts

_copylock:
	movem.l	(A7)+,D6-D7/A1/A3
	bsr	.cont		; necessary to get the stack at the proper value...
.cont
	eor.l	#$DC84624B,(A0)		; protection: access fault at jumping monsters

	; emulate the LINE-F by hand
	;
	; the copylock ended by an actual LINE-F, but
	; later it would trigger a kind of stackframe error because
	; the game thinks (because no stackframe on 68000) that
	; there is only 2 bytes to pop (the SR value), whereas there are 4
	; on 68020 and higher

	; another case where the protection fucks up the game on 68020+...

	; jumps line-f vector with 68000-like RTE stack frame
	move.w	#$2700,-(A7)
	move.l	$2C.W,-(A7)		; line-f vector
	rts

; ----------------------------------------------

_do_buttonwait
.loop
	btst	#6,$bfe001
	beq.b	.out
	btst	#7,$bfe001
	beq.b	.out
	bra.b	.loop
.out
	rts
	
; ----------------------------------------------

_jumper_title_v001
	sub.l	a1,a1
	lea	_pl_title_v001(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	
	; title is loaded from $2484 to +$237*$200
	jmp	$49020

; ----------------------------------------------

_jumper_title_v103_1
	sub.l	a1,a1
	lea	_pl_title_v103_1(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	
	; title is loaded from $2484 to +$237*$200
	jmp	$4904e
	
; ----------------------------------------------

_jumper_title_v103_2
	sub.l	a1,a1
	lea	_pl_title_v103_2(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	
	; title is loaded from $2484 to +$237*$200
	jmp	$49014
	
; ----------------------------------------------

_main_v103_1:
	; load the last chunk of data/code
	bsr		_diskload_1

	; now relocate decrunch routine and patch main
	IFND	LOW_MEMORY
	lea	_pl_main_v103_1_base(pc),a1	
	ENDC
	lea	_pl_main_v103_1(pc),A0
	lea	$116B6,A3
	
	bra	_main_patch
	
_main_v103_2:
	; load the last chunk of data/code
	bsr		_diskload_1
	
	IFND	LOW_MEMORY
	lea	_pl_main_v103_2_base(pc),a1
	ENDC
	lea	_pl_main_v103_2(pc),A0
	lea	$11682,A3
	
	bra.b	_main_patch
	nop
_main_v001:
	; load the last chunk of data/code
	bsr		_diskload_1
	
	; now relocate decrunch routine and patch main
	lea	_pl_main_v001(pc),A0
	lea	$11686,A3
	IFND	LOW_MEMORY
	lea	_pl_main_v001_base(pc),a1
	ENDC
	
	bra.b	_main_patch
	nop
	; shared between all versions
	; < A3: address/offset of unpacking routine
	; < A0: patchlist
_main_patch
	movem.l	D0/D1/A0-A3,-(A7)
	
	IFD	LOW_MEMORY
	
	; decrunch routine relocated only if low memory
	; (else it's using fastmem anyway)
.common
	lea	_decrunch_data(pc),A1
	move.l	#368/4,D0
.copy
	move.l	(A3)+,(A1)+
	dbf	D0,.copy
	ENDC

	; patch

	movem.l	_resload(pc),A2
	
	IFD	LOW_MEMORY
	sub.l	A1,A1
	ELSE
	; apply base patch
	move.l	a0,-(a7)
	move.l	a1,a0		; patchlist
	sub.l	a1,a1
	
	move.l	(a7)+,a0
	; this is actually expansion memory
	move.l	_expmem(pc),a1
	ENDC
	
	jsr	(resload_Patch,A2)
	movem.l	(A7)+,D0/D1/A0-A3
	; jump to game
	RTS
	
; ----------------------------------------------


; Rob Northen track loading routine
; < A0: buffer
; < D0: disk number
; < D1: sector offset (*$200)
; < D2: sector length (*$200)
; < D3: command (ignored)
; > D0: 0 if ok (which is all the time :))

_robread:
	movem.l	d1-d3/a0-a2,-(A7)
	and.b	#$FF,D3
	bne.b	.exit

	move.l	d0,d3		; disk number stored
	
	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.exit		; length=0: out

	move.l	D1,D0
	ext.l	d0
	lsl.l	#7,d0			;diskoffset
	lsl.l	#2,d0

	move.l	D2,D1			;len to read
	ext.l	d1
	lsl.l	#7,d1
	lsl.l	#2,d1

	move.l	D3,D2
	addq.l	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)
.exit
	movem.l	(A7)+,d1-d3/a0-a2
	moveq.l	#0,D0
	rts


_flushcache:
	move.l	A2,-(A7)
	move.l	(_resload,pc),a2
	jsr	(resload_FlushCache,a2)
	move.l	(A7)+,A2
	rts

; those just mask addresses up to $80000. I wonder 
; if this is the proper solution!!

_fix_access_fault_1:
	move.l	D2,-(A7)
	bsr		fix_a0_address
	move.w	(A0),D0
	move.l	(a7)+,D2

	move.l	($AC,A5),A0
	rts

_fix_access_fault_2:
	lea	($EFA,A5),A1
	moveq.l	#0,D1
	bsr		fix_a0_address
	rts

fix_a0_address
	move.l	A0,D2
	move.l	d0,-(a7)
	move.l	_expmem(pc),d0
	cmp.l	d2,d0
	bcc.b	.filter	; below expmem: do mask
	add.l	#$80000,d0
	cmp.l	d2,d0
	bcs.b	.filter	; above expmem: do mask
	move.l	(a7)+,d0
	; do nothing
	rts
	
.filter
	move.l	(a7)+,d0
	and.l	#$0007FFFF,D2
	move.l	D2,A0
	rts
	
; happens in french mode, when reading a book sometimes
; in that case game goes out of chipmem bounds!
; that does not happen at the same place for english language

_fix_access_fault_3
	cmp.l	#$7FFFF,a1
	bcc.b	.normal		; already starting in expansion mem, don't do anything
.loop
	cmp.l	#$7FFFF,a1
	bcc.b	.out
	move.b	(a0)+,(a1)+
	dbf	D0,.loop
.out
	rts
.normal
	move.b	(a0)+,(a1)+
	dbf	D0,.normal
	rts
	
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

KBINT_MACRO:MACRO
_kbint_v\1:
	tst.b	d0
	beq.b	.orig
	cmp.b	_keyexit(pc),d0
	beq	_quit

	; quit with quit key (useful if NOVBRMOVE is set or if 68000)


	cmp.b	#F5_KEY,d0
	beq.b	.ok
	cmp.b	#F6_KEY,d0
	bne.b	.nok
.ok
	movem.l	d1/A0,-(A7)
	move.l	_trainer(pc),d1
	btst	#1,d1
	beq.b	.skip
	; toggle infinite energy

	cmp.b	#F5_KEY,d0
	beq.b	.infinite
	move.w	#$F00,$DFF180
	move.l	#$3B410496,d1
	bra.b	.flush
.infinite
	move.w	#$F0,$DFF180
	move.l	#$4E714E71,d1	; NOPNOP
.flush
	lea	\2,a0
	IFND	LOW_MEMORY
	add.l	_expmem(pc),a0
	ENDC
	move.l	d0,(a0)
	bsr	_flushcache
.skip
	movem.l	(A7)+,d1/a0
	; save current key value
.nok
.orig
	btst	#0,($d00,a0)	; stolen code
	rts
	ENDM

	KBINT_MACRO	001,$10872
	KBINT_MACRO	103_v1,$108CC
	KBINT_MACRO	103_v2,$1086E

;	eor.l	#$75304AE7,$10872	; NOPNOP ^ MOVE.W D1,($496,A5)

kbint_hook_intro:
	cmp.b	_keyexit(pc),d0
	beq	_quit
	; original
	TST.B	D0			;0c1e: 4a00
	BPL.S	.s		;0c20: 6a02
	MOVEQ	#0,D0			;0c22: 7000
.s:
	rts

	
dma_off
	MOVE.W	2(A4),dmacon(A5)	; original
;	bra		soundtracker_loop
soundtracker_loop
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
	
; ----------------------------------------------

; to patch bootblock

_pl_boot_v103:
		PL_START
		PL_P	$54,_jumper1_v103
		PL_P	$60,_diskload_1	; $4E56FFDC
		PL_END
_pl_boot_v001:
		PL_START
		PL_P	$54,_jumper1_v001
		PL_P	$5C,_diskload_1	; $4E56FFDC
		PL_END

; in order to load intro, middleware to load everything

_pl_intro_loader_v103_1:
		PL_START
		; skip setting exception vectors
		PL_S	$09ba-$84,$9B0-$992
		; PAL region lock that fails on winuae
		; combined with optional buttonwait if set
		
		PL_IFBW
		PL_PSS	$f1C-$84,_do_buttonwait,4
		PL_ELSE
		PL_NOP	$f24-$84,2
		PL_ENDIF

		PL_P	$98-$84,_diskload_1
		
		; title
		PL_P	$0fb2-$84,_jumper_title_v103_1
		; quitkey on 68000 during title sequence
		PL_PS	$0cda-$84,kbint_hook_intro
		
		PL_END
		
; in order to load intro, middleware to load everything

_pl_intro_loader_v103_2:
		PL_START
		; skip setting exception vectors
		PL_S	$0902-$84,$9B0-$992
		; PAL region lock that fails on winuae
		; combined with optional buttonwait if set
		
		PL_IFBW
		PL_PSS	$0e5c-$84,_do_buttonwait,4
		PL_ELSE
		PL_NOP	$0e64-$84,2
		PL_ENDIF

		PL_P	$98-$84,_diskload_1
		
		; title
		PL_P	$0ef2-$84,_jumper_title_v103_2
		; quitkey on 68000 during title sequence
		PL_PS	$0c1e-$84,kbint_hook_intro
		
		PL_END
		
_pl_intro_loader_v001:
		PL_START
		; skip setting exception vectors
		PL_S	$0992-$84,$9B0-$992
		; PAL region lock that fails on winuae
		; combined with optional buttonwait if set
		PL_IFBW
		PL_PSS	$ee2-$84,_do_buttonwait,4
		PL_ELSE
		PL_NOP	$eea-$84,2
		PL_ENDIF
		
		
		; disk load
		PL_P	$94-$84,_diskload_1
		; title
		PL_P	$0f78-$84,_jumper_title_v001
		; quitkey on 68000 during title sequence
		PL_PS	$0ca4-$84,kbint_hook_intro
		PL_END

_pl_title_v001:
	PL_START
	PL_PS	$48c4c,dma_off
	; intercept after game is loaded / just before last data load
	PL_P	$4912E,_main_v001
	PL_END
	
_pl_title_v103_1:
	PL_START
	PL_PS	$48c7a,dma_off
	; intercept after game is loaded / just before last data load
	PL_P	$4916c,_main_v103_1
	PL_END
	
_pl_title_v103_2:
	PL_START
	PL_PS	$48c4c,dma_off
	; intercept after game is loaded / just before last data load
	PL_P	$4911a,_main_v103_2
	PL_END
	
; right after intro (main program)
; v1.03, unprotected

_pl_main_v103_1:
		PL_START
		PL_S	$144f2,$50e-$4F2		; skip vector setup
		PL_PS	$1482C,_kbint_v103_v1
		PL_P	$13B96,_diskload_2
		
		IFD		LOW_MEMORY
		PL_P	$116B6,_decrunch_data
		PL_PS	$1cf44,dma_off		; sound fix
		ENDC
		
		PL_NOP	$14598,8			; don't turn off sprites all the time
		PL_PS	$B444,_getsavenum	; 6700003C *0C000001

		PL_PS	$B34A,_savegame_part1
		PL_PS	$B388,_savegame_part2
		PL_PS	$B4D6,_loadgame_part1
		PL_PS	$B57C,_loadgame_part2

		PL_PS	$FA88,_fix_access_fault_1
		PL_PS	$FA9E,_fix_access_fault_2
		PL_PS	$112BE,_fix_access_fault_3
		
		;;PL_P	$11444,save_unpacked_file

		PL_IFC1X	0
		; saving game doesn't cost money
		PL_NOP	$DC64,4
		PL_B	$DC14,$60
		PL_ENDIF
		
		PL_PSS	$1458c,vbl_hook,2
		PL_PS	$0685e,test_keys_1
		PL_PSS	$092e6,test_keys_2,2		; map
		
		PL_PS	$0a3d2,regulate_map_scroll

		PL_END


	
; right after intro (main program)
; v1.03 protected by copylock

_pl_main_v103_2:
		PL_START
		PL_S	$14406,$22-$6		; skip vector setup
		PL_PS	$1473E,_kbint_v103_v2
		PL_P	$13B62,_diskload_2
		
		IFD	LOW_MEMORY
		PL_P	$11682,_decrunch_data
		;PL_PS	$1cf44,dma_off		; sound fix
		ENDC
		
		PL_PS	$B3FE,_getsavenum	; 6700003C *0C000001
	
		PL_P	$10ED6,_copylock

		PL_PS	$FA2A,_fix_access_fault_1
		PL_PS	$FA40,_fix_access_fault_2
		PL_PS	$1128A,_fix_access_fault_3
		
		PL_PS	$B308,_savegame_part1
		PL_PS	$B342,_savegame_part2
		PL_PS	$B484,_loadgame_part1
		PL_PS	$B51E,_loadgame_part2

		
		PL_IFC1X	0
		PL_NOP	$DC06,4
		PL_B	$DBB6,$60
		PL_ENDIF
		
		PL_PSS	$144a0,vbl_hook,2
		PL_PS	$0685e,test_keys_1
		PL_PSS	$092e6,test_keys_2,2		; map
		
		PL_PS	$0a3d2,regulate_map_scroll
		
		PL_END

_pl_main_v001_base:
_pl_main_v103_1_base:
_pl_main_v103_2_base:
		PL_START
		PL_PS	$22d0e,dma_off		; sound fix (in chip, if fastmem)
		PL_END
		
		
_pl_main_v001:
		PL_START
		PL_S	$1449a,$B6-$9A		; skip vector setup
		PL_PS	$147C8,_kbint_v001
		PL_P	$13B62,_diskload_2
		
		IFD	LOW_MEMORY
		PL_P	$11686,_decrunch_data
		PL_PS	$1cedc,dma_off		; sound fix
		ENDC
		
		PL_PS	$B400,_getsavenum	; 6700003C *0C000001

		PL_P	$10EDA,_copylock

		PL_PS	$FA2E,_fix_access_fault_1
		PL_PS	$FA44,_fix_access_fault_2
		PL_PS	$1128E,_fix_access_fault_3
		
		PL_PS	$B30A,_savegame_part1
		PL_PS	$B344,_savegame_part2
		PL_PS	$B486,_loadgame_part1
		PL_PS	$B520,_loadgame_part2


		PL_IFC1X	0
		PL_NOP	$DC0A,4
		PL_B	$DBBA,$60
		PL_ENDIF
		
		PL_PSS	$14532,vbl_hook,2
		PL_PS	$0685e,test_keys_1
		PL_PSS	$092e8,test_keys_2,2		; map
				
		PL_PS	$0a3d4,regulate_map_scroll
		PL_END


; ----------------------------------------------------------------------

regulate_map_scroll
    movem.l d0-d1/a0,-(a7)
    moveq.l #1,d1       ; the bigger the longer the wait
    lea vbl_counter(pc),a0
    move.w  (a0),d0
    cmp.w   #10,d0
    bcc.b   .nowait     ; first time called/lost sync/pause/whatever
    ; wait till at least x vblanks passed after last zeroing
.wait
    cmp.w   (a0),d1
    bcc.b   .wait
.nowait
    clr.w   (a0)
    movem.l (a7)+,d0-d1/a0
	; original
	MOVE.W	1220(A5),1134(A5)
	rts
	
; ----------------------------------------------------------------------

test_keys_1
	moveq.l	#0,d0
test_keys
	MOVE.B	3130(A5),D0	; stolen
	beq.b	.no_key
	cmp.b	#$60,d0		; no key
	bne.b	.real_key
.no_key
	move.l	a0,-(a7)
	lea	_current_fake_key(pc),a0
	move.b	(a0),d0
	clr.b	(a0)
	move.l	(a7)+,a0
.real_key
	rts
	
test_keys_2
	bsr.b		test_keys
	cmp.b	#$51,d0		; stolen
	rts
	
; ----------------------------------------------------------------------

TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d1
    beq.b   .nochange_\1
    move.b  #\2,d3
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    clr.b	d3   ; released
.pressed_\1
    move.b  d3,(a1) ; store keycode
.nochange_\1
    ENDM
	
vbl_hook
	btst	#5,_custom+intreqr+1
	beq	.out
	; vertical blank, read joypad
	movem.l d0-d3/a0-a1,-(a7)
	; vblank interrupt
    ; add to counter
    lea vbl_counter(pc),a0
    addq.w  #1,(a0)
    ; read joystick/mouse
    lea prev_buttons_state(pc),a0
    lea	_current_fake_key(pc),a1
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_read_joystick
    cmp.l   d0,d1
    beq.b   .nochange   ; cheap-o test just in case no input has changed
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; xor to d1 to get what has changed quickly
    eor.l   d0,d1
    ; d1 bears changed bits (buttons pressed/released)
    TEST_BUTTON REVERSE,$33	; C (clears messages)
    TEST_BUTTON FORWARD,$50	; F1 (map)
    TEST_BUTTON BLU,$40		; space
    TEST_BUTTON YEL,$25		; H
    TEST_BUTTON GRN,$44		; return
    TEST_BUTTON PLAY,$19	; pause
.nochange    
.novbl
    movem.l (a7)+,d0-d3/a0-a1
	addq.l	#2,(a7)		; skip beq test
.out
	rts
	
; ----------------------------------------------------------------------

_decrunch_data:
	ds.b	$200,0
_savename:
	dc.b	"saves/savegame_"
_savever:
	dc.b	"o."		; o for original, p for payoff
_savenum:
	dc.b	"0",0
_current_fake_key
	dc.b	0
	even
prev_buttons_state
	dc.l	0
	
_tag		dc.l	WHDLTAG_CUSTOM3_GET
_level_set	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_trainer	dc.l	0


		dc.l	0

vbl_counter
	dc.l	0
_resload:
	dc.l	0
_version:
	dc.l	0


; ----------------------------------------------------------------------
; code below is not used in slave release

	IFD	XXXXXXX	
	; I believe I had added this to be able to rip data. Now it causes an issue
	; when the file number is too high. It also writes unnecessary files to disk
	; commenting it out just in case I need it again

save_unpacked_file
	move.l	a5,-(a7)
	lea	.sd(pc),a4
	move.l	a1,(a4)+
	move.l	d0,(a4)+

	move.l	a3,a4	; packed data
	move.l	a1,$11A26	; output address?
	move.l	D0,$11A2A	; unpacked length
	jsr	$1145C
	move.l	(a7)+,a5

	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	lea	.savecount(pc),a0
	addq.b	#1,(a0)
	lea	.savename(pc),a0
	move.l	.sd(pc),a1
	move.l	.sd+4(pc),d0
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	rts

.sd	
	dc.l	0,0
.savename
	dc.b	"cadrip_"
.savecount
	
	dc.b	"0.bin",0
	even
	; code used to break the copylock
	; !!!!!! to use: set NOCACHE and NOMMU tooltype
	; as writing into whdload VBR causes access faults
	
_copylock_debug:
	bsr	_install_newtrace

	movem.l	(A7)+,D6-D7/A1/A3
	jsr	(A2)
	rts


_install_newtrace:
	mc68020
	movec	VBR,A1
	mc68000
	lea	_old_whd_trace(pc),A3
	move.l	$24(A1),(A3)
	lea	_newtrace_checkpc(pc),A3
	move.l	A3,$24(A1)

	lea	_old_whd_illegal(pc),A3
	move.l	$24(A1),(A3)
	lea	_newillegal(pc),A3
	move.l	A3,$10(A1)

	bsr	_flushcache
	rts

_newtrace_checkpc:
	move.l	D0,$4.W
	move.l	2(A7),D0
;;	cmp.l	#$28C8C,D0	; end
	cmp.l	#$28BB8,D0	; EOR (A6)
	bne.b	.out
	dc.w	$AAAA	; line-A
.out:
	move.l	$4.W,D0
_newtrace:
	move.l	$24.W,-(A7)
	rts


_newillegal:
	; works only once

	move.l	A1,-(A7)
	mc68020
	movec	VBR,A1
	mc68000
	move.l	_old_whd_illegal(pc),$10(A1)	; restore old whd value
	move.l	(A7)+,A1
	bsr	_flushcache
	move.l	$10.W,-(A7)
	rts
		
_old_whd_trace:
	dc.l	0
_old_whd_illegal:
	dc.l	0
	ENDC
