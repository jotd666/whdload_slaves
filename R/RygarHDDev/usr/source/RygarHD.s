
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	exec/exec.i

;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"Rygar.slave"
	IFND	CHIP_ONLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


	IFD	CHIP_ONLY
CHIPMEMSIZE	= $1E0000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $1E0000
FASTMEMSIZE	= $40000
	ENDC


_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem|WHDLF_ReqAGA|WHDLF_Req68020	;ws_flags
		IFND	CHIP_ONLY
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+FASTMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	datadir-_base		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFND	CHIP_ONLY	
	dc.l	FASTMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config
        dc.b    "C1:B:trainer - infinite lives;"
		dc.b	0
		even
		
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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

;============================================================================

_name		dc.b	"Rygar"
			dc.b	0
_copy		dc.b	"2019 Seismic Minds",0
_info		dc.b	"adapted by JOTD",10,10
		dc.b	"play+reverse+forward quits to workbench",10
		dc.b	"play pauses",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
datadir:
	dc.b	"data",0

program:
	dc.b	"rygar.exe",0


; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

	include "ReadJoyButtons.s"
	
start
	lea	_resload(pc),a2
	move.l	a0,(a2)
	
	bsr	_detect_controller_type
	
	clr.l	$0.W
	; install fake interrupt handler
	; game only uses level 6 interrupt
	pea	int3(pc)
	move.l	(a7)+,$6C.W
	pea	int2(pc)
	move.l	(a7)+,$68.W
	
	move.w	#$C028,_custom+intena
	

	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
	;	lea	(tag,pc),a0
	;	jsr	(resload_Control,a2)
	
		bsr	check_version 
	;load exe
		lea	program(pc),a0
		lea	base_address(pc),a1
		IFD		CHIP_ONLY
		move.l	#$100,(a1)
		ELSE
		move.l	_expmem(pc),(a1)
		ENDC
		move.l	base_address(pc),a1
		jsr	(resload_LoadFile,a2)
		
		move.l	base_address(pc),a0
		clr.l   -(a7)                   ;TAG_DONE
		move.l  a7,a1                   ;tags
		move.l  (_resload,pc),a2
		jsr     (resload_Relocate,a2)
		lea		start_memory(pc),a0

		; fast or chip, the chip alloc location doesn't change
		; that's on purpose because...
		; setting it to $100 when fastmem is used trashes the game...
		and.l	#$FFFFF000,d0
		add.l	#$1000,d0	; start of free memory chip after program
		add.l	d0,(a0)
		
		add.w   #4,a7
		
		move.l	base_address(pc),a1
		move.l	(_resload,pc),a2
		lea	pl_main(pc),a0
		jsr	(resload_Patch,a2)
		move.l	base_address(pc),a1
		jmp	(A1)
		
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)
		
check_version:
	movem.l	d0-d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#190920,D0	; final
	beq.b	.ok
	cmp.l	#0,D0
	beq.b	.ok		; let LoadSeg fail if file not found


	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.ok
	movem.l	(a7)+,d0-d1/a1
	rts
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts


	; proper keyboard interrupt
int2
	movem.l	D0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
.noquit
	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a5
	move.w	#8,$dff09c
	rte

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


int3
	; enable level 2 interrupt from level 3 interrupt
	; dirty but generic (game turns that off at some point)
	; enabling it again allows quitkey to work properly
	move.w	#$8008,intena+_custom
	; ack ints and exit
	; game doesn't use any interrupt except level 6
	move.w	#$70,intreq+_custom
	rte
	
vblank_hook
	lea	_custom,a5		; stolen from game
	; enable level 2 interrupts
	move.w	#$8008,(intena,a5)
	; read joypad
	bsr	_update_buttons_status
	
	rts

fix_af:
	cmp.l	#$8000,d2
	bcs	.no_af
	moveq.w	#0,d0
	rts
.no_af
	MOVE.B	(0,A0,D2.W),D0		;01014: 10302000
	EXT.W	D0			;01018: 4880
	rts
clear_sdr:
	movem.l	d1,-(a7)
	; check if quit
	NOT.B	D1
	ROR.B	#1,D1		; raw key code here
	cmp.b	_keyexit(pc),d1
	bne.b	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
.noquit
	move.l	_current_buttons_state(pc),d1
	btst	#JPB_BTN_REVERSE,d1
	beq.b	.no_quit
	btst	#JPB_BTN_FORWARD,d1
	beq.b	.no_quit
	btst	#JPB_BTN_PLAY,d1
	bne	_quit
.no_quit
	btst	#JPB_BTN_PLAY,d1
	beq.b	.no_pause
	move.b	#$19,d1
	NOT.B	D1
	ROL.B	#1,D1		; raw key code here
	move.l	D1,(A7)	; inject pause
.no_pause
	movem.l	(a7)+,d1
	; original
	MOVE.B	#$50,(256,A0)		;03fb8: 117c00500100
	clr.b	(-256,a0)
	rts

second_button_test
	movem.l	d0,-(a7)
	move.l	_current_buttons_state(pc),d0
	not.l	d0	; inverted logic to match original BTST.B #$000e,$00dff016
	btst	#JPB_BTN_BLU,d0
	movem.l	(a7)+,d0
	RTS
	
init_game_hook:
	; init nb lives
	MOVE.W	#$0002,(21542,A4)	;1b9f6: 397c00025426
	rts
	
pl_main
	PL_START
	; remove VBR/return 0 when asked
	PL_P	$03b0c,get_zero_vbr
	PL_P	$03c60,get_zero_vbr
	PL_P	$03d92,get_zero_vbr
	
	; trainer infinite lines
	PL_IFC1
	PL_NOP	$877c,4
	PL_NOP	$88f0,4
	PL_ENDIF
	
	; typo in title
	PL_STR	$22CF4,<ARY WARRIOR >
	PL_P	$F4,read_file
	; fix access fault when D2
	PL_PS	$01014,fix_af
	
	; for some reason 1) level2 interrupt is off and
	; 2) level2 intrequest is off
	PL_PS	$3da6,vblank_hook
	PL_NOP	$3fa2,2
	PL_W	$3fae,$3280		; clear last pressed key
	PL_PS	$3FB8,clear_sdr
	
	; completely disable second button read, we'll use joypad routine
	; for that
	PL_R	$765e
	PL_NOP	$1bacc,8
	PL_PSS	$5498,second_button_test,2
	
	
	;;PL_PS	$1B9F6,init_game_hook
	
	; the following patches are there to make the game
	; independent from the operating system

	; remove LoadView calls
	PL_R	$3B76
	PL_R	$3BB4
	PL_R	$3C26
	; get vbr returns zero without having to call Supervisor
	PL_L	$03aec,$70004E75
	PL_L	$03c44,$70004E75
	; avoids the call, but lets the game install vbl handler
	PL_W	$3d72,$7000
	PL_S	$03d74,$7E-$74
	
	PL_W	$3c68,$7000
	PL_S	$3C6A,$03c74-$3C6A
	
	; fake doslib, so D0 != 0
	PL_L	$5230,$70FF4E75
	; no more messages printed
	PL_R	$524E
	
	; emulate allocmem
	PL_P	$5218,allocmem
	; make sure noone calls those syscalls
	PL_I	$5226		; freemem
	PL_I	$5272
	PL_I	$f26a
	PL_I	$f27a
	PL_I	$f2a4
	PL_I	$f2b4
	PL_I	$f2c8
	; no more Forbid or CloseLibrary
	PL_R	$3be0
	PL_R	$5240
	
	; jump to game startup immediately
	PL_S	$0,$9A

	
	PL_END
read_file
	tst.l	d0
	bmi.b	.skip	; motor or something

	; now read file
	movem.l	d0-d1/a0-a2,-(a7)
	exg.l	a0,a1
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)
	tst.l	d0	; clears zero flag
	movem.l	(a7)+,d0-d1/a0-a2
.skip
	rts	


	
get_zero_vbr:
	moveq.l	#0,d0
	rte
	
	
_resload
	dc.l	0

allocmem
	movem.l	d3,-(a7)
	move.l	d0,d3
	; align occupied space on $10 bytes
	and.b	#$F0,d3
	cmp.l	d0,d3
	beq.b	.noneed
	add.l	#$10,d3
.noneed
	lea	start_memory(pc),a0
	move.l	(a0),d0
	add.l	D3,(a0)		; add size (aligned)
	movem.l	(a7)+,d3
	rts

start_memory
	dc.l	0
	
base_address
	dc.l	0
	
tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0

;============================================================================

	END
