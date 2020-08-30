;*---------------------------------------------------------------------------
;  :Program.	ZoolAGAHD.asm
;  :Contents.	Slave for "Zool AGA" from Gremlin
;  :Author.	JOTD
;  :History.	28.01.05
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	ZoolAGA.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_ReqAGA|WHDLF_EmulTrap	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
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

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

IGNORE_JOY_DIRECTIONS

DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Zool (AGA)"
		dc.b	0
_copy		dc.b	"1992 Gremlin Graphics",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_config
    ;;dc.b    "C2:X:Use 2nd button for jump:0;"
    dc.b    "C1:X:Infinite lives:0;"
	dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

BASE_ADDRESS = $70000
SCORES_ADDRESS_AGA = $3922

	include	ReadJoyPad.s
	
; AGA: lives at 223D7

;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	a0,a2
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

		bsr	_detect_controller_types
		
		lea	CHIPMEMSIZE-$100,a7
		move	#$2700,SR
		move.w	#$7FFF,$DFF09A

		; load & version check

		lea	BASE_ADDRESS,A0
		move.l	#$0,D0		; offset
		move.l	#$1800,D1		; length
		moveq	#1,D2
		bsr	_loaddisk
		lea	BASE_ADDRESS,A0
		move.l	#$1800,d0
		jsr	resload_CRC16(a2)

		lea	pl_boot_aga(pc),a0
		cmp.l	#$C0A6,d0
		beq.b	.patch


		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.patch
		lea	BASE_ADDRESS,A1
		jsr	resload_Patch(a2)

		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2

		jmp	BASE_ADDRESS



pl_boot_aga
	PL_START

	PL_B	$26,$60		; skip white to black fadein

	; set color burst

	PL_ORW	$2D8,$200
	PL_ORW	$3A0,$200
	PL_ORW	$478,$200

	; NIBREAD #1

	PL_P	$656,ReadTrack_AGA
	PL_P	$668,NibRead_AGA

	; decrunch in fastmem

	PL_P	$552,fungus_decrunch

	; cancel some disk-related code

	PL_P	$6D4,SetDMACON	
	PL_R	$736
	PL_R	$762

	; Lay in the new patch

	PL_P	$1D2,patch_main

	; Set the kbint & fix keyboard

	PL_PS	$BC4,KbInt1_AGA
	PL_PS	$BCA,AckKb
	PL_NOP	$BD6,4

	; remove wait on chupa chups logo, we saw it
	; a lot already :)
	
	PL_NOP	$12C,4
	
	PL_END


kb_routine_aga
	move.b	kb_value(pc),d0
	cmp.b	#$CD,d0
	beq.b	.nokb

	MOVE.B	D0,12463(A5)		; stolen

	move.l	A0,-(a7)
	lea	kb_value(pc),a0
	move.b	#$CD,(a0)			; "acknowledge" kb
	move.l	(a7)+,A0
.nokb
	add.l	#$52,(a7)	; skip the rest
	rts

kb_value
	dc.w	$CDCD

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

;decrunch
;	movem.l	d0-d1/a0-a2,-(a7)
;	move.l	_resload(pc),a2
;	jsr	resload_Decrunch(a2)
;	movem.l	(a7)+,d0-d1/a0-a2
;	bsr	_flushcache
;	rts
	

swap_disks:
	movem.l	D0/A0,-(A7)
	lea	currdisk(PC),A0
	move.w	(A0),D0
	beq	.setto1
	moveq.l	#0,D0
	bra	.setvar
.setto1
	moveq.l	#1,D0
.setvar
	move.w	D0,(A0)
	movem.l	(A7)+,D0/A0
	rts

AckKb:
	bset	#6,$BFEE01
	move.l	d0,-(a7)
	moveq.l	#2,d0
	bsr	_beamdelay
	move.l	(a7)+,d0
	bclr	#6,$BFEE01
	rts

patch_main
	movem.l	d0-a6,-(a7)

	pea		fix_smc_jsr(pc)
	move.l	(a7)+,$BC.W	; trap #15 emulates JSR with SMC


	; patch DMACONR write (for snoop)

	lea	$B900,A0
	lea	$1E000,A1
.loop
	lea	setdmacon_string(pc),A2
	moveq	#8,D0
	bsr	hex_search
	cmp.l	#0,A0
	beq.b	.exit
	move.w	#$6006,(A0)
	bra.b	.loop
.exit

	lea	pl_menu(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	; ** loads hiscore

	bsr	load_hiscore_aga

	movem.l	(a7)+,d0-a6

	jmp	$1002.W

pl_menu
	PL_START
	; *** patch load

	PL_P	$502E,ReadTrack_AGA
	PL_P	$503C,NibRead_AGA

	; *** patck kb+quitkey

	PL_PS	$5A02,KbInt2_AGA
	PL_PS	$5A08,AckKb
	PL_NOP	$5A14,4

	; *** patch load (2)

	PL_P	$521C,ReadTrack2_AGA

	; *** remove dskrdy/led code

	PL_R	$5172
	PL_R	$5104
	PL_R	$50DC
	PL_R	$50A6
	PL_R	$5140
	PL_W	$87E4,$6066
	
	; fix access fault: wrong register write
	PL_L	$06da8+4,$DFF1FC
	
	; *** decrunch

	PL_P	$5B3A,fungus_decrunch

	; *** disk swap

	PL_PS	$89CE,swap_disks
	PL_W	$89D4,$600E

	; *** remove protection

	PL_W	$6BDC,$6038
	PL_W	$6BA8,$606C

	; *** expansion memory
	
	PL_P	$6804,GetExpMem

	; ** fix color burst fix

	PL_ORW	$70478,$200

	; ** insert trap to fix color burst

	PL_PSS	$6958,SetCopper_1,4
	PL_PSS	$90F2,SetCopper_2,4
	PL_PSS	$9746,SetCopper_3,4
	PL_PSS	$89B2,SetCopper_4,4
	PL_PSS	$D8D8,SetCopper_4,4
	PL_PSS	$DC48,SetCopper_4,4
	PL_PSS	$7218,SetCopper_5,4

	; ** install hiscore save

	PL_P	$E612,save_hiscore_aga

	; ** patch dbf loops

	PL_P	$100,emulate_dbf
	PL_L	$406A,$4EB80100
	PL_L	$407E,$4EB80100
	PL_L	$882E,$4EB80100
	; remove strange data write inside a loop...
	; probably never reached, but...
	PL_NOP	$06af8,8
	PL_PSS	$06c28,empty_loop,2
	
	; patch self-modifying code that trashes the gfx
	PL_W	$aed2,$4E4F
	PL_PS	$B818,fix_smc_1
	PL_PS	$BBB6,fix_smc_2
	
	PL_PS	$86F2,after_game_code_copy
	
	PL_B	$0a61c,$FF	; enable cheat keys
	
	; second button joystick
	; needs more fixing for wall climb
	; like CD32 version does. ATM it's unusable
	;PL_IFC1
	;PL_PSS	$10BC,test_for_joy_up,$d4-$c2
	;PL_NOP	$102a,6		; no UP when diagonals
	;PL_ENDIF
	PL_END	
	
after_game_code_copy:
	ST	$14F8.W
	movem.l	d0-d1/A0-A2,-(a7)
	lea	pl_main(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/A0-A2
	rts
	
pl_main
	PL_START
	PL_IFC1
	PL_W	$D0FE,$4AB9	; subq => TST
	PL_ENDIF
	; access fault at level 4-1 when jumping left
	PL_PS	$1b066,avoid_af
	PL_END
	
avoid_af:
	; without this masking game reads in the > $100000
	; zone for the first time at world 4.
	; In AGA with $200000 chip this isn't really a problem
	; but first access is read, not write, so it's probably
	; a bug. Why increasing memory to 2MB chip just for this??
	and.l	#$7FFFF,d2
	move.b       (0,a0,d2.l),d3                 ;$00157ff6
	add.w        d3,d3
	rts
	
test_for_joy_up:
	moveq.l	#1,d0
	bsr	_read_joystick
	bchg	#JPB_BTN_BLU,D0
	btst	#JPB_BTN_BLU,D0
	
	; return with Z=0: up
	rts
	
empty_loop:
	move.w	#1000,d0
	bsr	_beamdelay
	rts
	
fix_smc_1:
	bsr	_flushcache
	MOVE.W	D5,D0			;0b818: 3005
	SUB.W	D4,D0			;0b81a: 9044
	TST.W	D0			;0b81c: 4a40
	RTS
fix_smc_2:
	MOVEA.L	#$00000020,A2		;0bbb6: 247c00000020
	bra	_flushcache
	
fix_smc_jsr:
	; tricky: first, recover from the RTE

	movem.l	A0/A1,-(A7)
	move.l	10(A7),A0	; return PC
	lea	.return_address(pc),a1
	move.l	a0,(a1)		; save return address for later on
	lea	.jsr_address(pc),a1
	move.l	(a0),(a1)	; save jsr address for later on
	lea	.recov(pc),a1
	move.l	a1,10(a7)	; change return PC
	movem.l	(A7)+,A0/A1
	rte
.recov
	; now we're in user mode: first push return address
	
	move.l	.return_address(pc),-(a7)
	addq.l	#4,(a7)		; skip JSR operand
	
	; then push JSR operand
	move.l	.jsr_address(pc),-(a7)

	; go
	rts
	
.return_address
	dc.l	0
.jsr_address
	dc.l	0

setdmacon_string:
	dc.l	$08F90006,$DFF002
GetExpMem:
	move.l	#$80000,D2
	jmp	$6860.W

emulate_dbf:
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts

load_hiscore_aga:
	movem.l	d0-d1/a0-a2,-(a7)
	lea	scores_name(pc),A0
	move.l	_resload(pc),a2
	jsr	(resload_GetFileSize,a2)
	tst.l	d0
	beq.b	.noscores
	lea	SCORES_ADDRESS_AGA,A1
	lea	scores_name(pc),A0
	jsr	(resload_LoadFile,a2)
.noscores
	movem.l	(a7)+,d0-d1/a0-a2
	rts

save_hiscore_aga:
	move.w	#$F,$DFF096	; stolen code

	movem.l	d0-d1/a0-a2,-(a7)
	lea	SCORES_ADDRESS_AGA,A1
	lea	scores_name(pc),A0
	move.l	_resload(pc),a2
	move.l	#$110-$16,D0
	jsr	(resload_SaveFile,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts


SET_COLOR_BURST:MACRO
	move.l	\1,D0
	or.w	#$0200,D0
	move.l	D0,\1
	ENDM


SetCopper_1:
	SET_COLOR_BURST	$1EB82
	SET_COLOR_BURST	$1EC5A
	SET_COLOR_BURST	$C884
	SET_COLOR_BURST	$8B32
	move.l	#$1EB7E,$DFF080
	rts

SetCopper_2:
	SET_COLOR_BURST	$8650
	SET_COLOR_BURST	$8578
	move.l	#$8580,$DFF080
	rts

SetCopper_3:
	SET_COLOR_BURST	$985C
	move.l	#$978C,$DFF080
	rts

SetCopper_4:
	SET_COLOR_BURST	$8650
	move.l	#$8580,$DFF080
	rts
	
SetCopper_5:
	SET_COLOR_BURST	$C470
	SET_COLOR_BURST	$C4C4
	SET_COLOR_BURST	$C514
	move.l	#$c334,$DFF080
	rts

WaitBlit:
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
	rts

; *** read track ($1800 bytes) AGA version
; in: D0: track (substract 2)
;     A0: buffer

ReadTrack_AGA:
	movem.l	d0-a6,-(a7)
	moveq.l	#0,D1
	move.w	#$1800,D1
	bsr	NibRead_AGA
	
	movem.l	(a7)+,d0-a6
	rts
	
; *** read track ($1800 bytes) AGA version
; in: D0: track (substract 2)
;     $3820(A4): buffer

ReadTrack2_AGA:
	movem.l	d0-a6,-(a7)
	moveq.l	#0,D1
	move.w	#$1800,D1
	lea	$3820(A4),A0
	bsr	NibRead_AGA
	movem.l	(a7)+,d0-a6
	rts


NibRead_AGA:
	bsr	CommonNibRead
	rts

; ReadRoutine (common)
; D1: Length in bytes
; D0: Track number (-2 in our loader)
; A0: Buffer

CommonNibRead:
	movem.l	d0-a6,-(a7)
	and.l	#$FFFF,D1
	subq.l	#$2,D0		; Substract the track offset

	tst.l	D1
	beq	ReadNothing

	; *** D0 * $1800

	mulu.w	#$C,D0
	lsl.l	#8,D0
	add.l	D0,D0	; D0*=512*12

	move.l	_resload(pc),a2
	move.w	currdisk(PC),D2
	addq.l	#1,d2
	jsr	(resload_DiskLoad,a2)

ReadNothing:
	movem.l	(a7)+,d0-a6
	rts

SetDMACON:
	move.w	#$20,dmacon+_custom
	move.w	#$8210,dmacon+_custom
	rts	

KbInt1_AGA:
	move.b	D0,$70B88
quit_test
	cmp.b	_keyexit(pc),d0
	beq	quit
	rts

fungus_decrunch
	movem.l	d0-a6,-(a7)
	; whdload does not support FUNGUS

		move.l	#'*FUN',d0		;Fungus decruncher
		move.l	#'GUS*',d1
_Dec_1		cmp.l	(a0)+,d0
		beq.b	_Dec_2
		cmp.l	(a0)+,d0
		bne.b	_Dec_1
_Dec_2		cmp.l	(a0)+,d1
		bne.b	_Dec_1
		subq.w	#8,a0
		movea.l	-(a0),a2
		adda.l	a1,a2
		move.l	-(a0),d0
		move.l	-(a0),d4
		move.l	-(a0),d5
		move.l	-(a0),d6
		move.l	-(a0),d7
_Dec_3		add.l	d0,d0
		bne.b	_Dec_4
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_4		bcs.w	_Dec_11
		moveq	#3,d1
		moveq	#0,d3
		add.l	d0,d0
		bne.b	_Dec_5
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_5		bcs.b	_Dec_7
		moveq	#1,d3
		moveq	#8,d1
		bra.w	_Dec_15

_Dec_6		moveq	#8,d1
		moveq	#8,d3
_Dec_7		bsr.w	_Dec_18
		add.w	d2,d3
_Dec_8		moveq	#7,d1
_Dec_9		add.l	d0,d0
		bne.b	_Dec_10
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_10		addx.w	d2,d2
		dbra	d1,_Dec_9
		move.b	d2,-(a2)
		dbra	d3,_Dec_8
		bra.w	_Dec_17

_Dec_11		moveq	#0,d2
		add.l	d0,d0
		bne.b	_Dec_12
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_12		addx.w	d2,d2
		add.l	d0,d0
		bne.b	_Dec_13
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_13		addx.w	d2,d2
		cmp.b	#2,d2
		blt.b	_Dec_14
		cmp.b	#3,d2
		beq.b	_Dec_6
		moveq	#8,d1
		bsr.w	_Dec_18
		move.w	d2,d3
		move.w	#12,d1
		bra.w	_Dec_15

_Dec_14		moveq	#2,d3
		add.w	d2,d3
		move.w	#9,d1
		add.w	d2,d1
_Dec_15		bsr.w	_Dec_18
		lea	(1,a2,d2.w),a3
_Dec_16		move.b	-(a3),-(a2)
		dbra	d3,_Dec_16
_Dec_17		cmpa.l	a2,a1
		blt.w	_Dec_3

		movem.l	(a7)+,d0-a6
		rts

_Dec_18		subq.w	#1,d1
		clr.w	d2
_Dec_19		add.l	d0,d0
		bne.b	_Dec_20
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_20		addx.w	d2,d2
		dbra	d1,_Dec_19
		rts

.FUN_0000:
	incbin	"fungusdec.bin"
	rts

KbInt2_AGA:
	move.b	D0,$59C6.W
	bra	quit_test

currdisk:
	dc.w	0
currtrack:
	dc.w	0


scores_name:
	dc.b	"highs",0

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

;--------------------------------

_resload	dc.l	0		;address of resident loader

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_loaddisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts


;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

hex_search:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts
