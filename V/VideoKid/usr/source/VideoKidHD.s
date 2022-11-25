;*---------------------------------------------------------------------------
;  :Program.	VideoKid.asm
;  :Contents.	Slave for "Video Kid" from Gremlins
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	30.09.98
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
	OUTPUT	dh1:demos/videokid/VideoKid.slave
	OPT	O+ OG+			;enable optimizing
    ENDC
    
;CHIP_ONLY

    IFD CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = $0000    
    ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
    ENDC
;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$58		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem		dc.l	FASTMEMSIZE			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w    0     ; kickstart name
		dc.l    $0         ; kicksize
		dc.w    $0         ; kickcrc
		dc.w	slv_config-_base

slv_config:
		dc.b    "C1:X:infinite lives:0;"
		dc.b    "C1:X:infinite bombs:1;"
		dc.b    "C1:X:infinite energy:2;"
		dc.b    "C2:B:enable joypad controls;"
		dc.b    "C3:B:skip raster fix;"
		;dc.b    "C3:L:start level:1,2,3,4,5;"
		dc.b	0
        
DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	0
_name		dc.b	"Video Kid",0
_copy		dc.b	"1992 Gremlin",0
_info		dc.b	"Adapted by MrLarmer & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
    even
    
IGNORE_JOY_DIRECTIONS
    include     ReadJoyPad.s
    

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

        bsr _detect_controller_types
        
		lea	$80000,A7
        IFD CHIP_ONLY
		move.l	#$81000,d0		; ext mem
		ELSE
        move.l  _expmem(pc),d0
        add.l   #$1000,d0
        ENDC
        move.l  d0,$7C.W
        
		lea	$16960,A0
		move.l	#$1400,D0
		move.l	#$C800,D1
		moveq	#1,d2
		bsr.w	_LoadDisk
        move.l   _resload(pc),a2
	;get tags
        ;
		;lea	(tag,pc),a0
		;jsr	(resload_Control,a2)

        ;move.l  start_level(pc),d0
        ;move.w  d0,$20518		; level nr

        lea  pl_main(pc),a0
        sub.l    a1,a1
        jsr  (resload_Patch,a2)
       
        move.l  #$00E0,$100
		lea	$DFF000,A6
        jmp	$1696E

pl_main	
    PL_START
    PL_W	$1B16A,$6002		; remove stack at small ptr
    PL_PA	$1B60E,PatchIntro
    PL_W	$1B61E,$6002		; remove stack at small ptr
    PL_P	$221A8,ChangeDisk1
    PL_P	$221FC,ChangeDisk2
    PL_P	$225AE,Decrunch
    PL_P	$2295E,Load

    ; completely replace keyboard interrupt
    PL_PSS   $1b234,set_keyboard_interrupt,2
    
    PL_IFC3
    PL_ELSE
    ; replace raster beam sync
    PL_P   $1B722,beam_sync
    PL_ENDIF
    
    PL_IFC2
    ; second button for bombs
    PL_PSS  $20fd0,bomb_launch_test,2
    ; enable vertical blank interrupt
    PL_ORW  $1b244+2,$20
    ; hook into level 3
    PL_PS   $1C894,level3_interrupt_hook
    
    ;PL_PSS  $1b758,fire_test,2
    PL_PSS  $1ec64,fire_test,2
    PL_PSS  $1ed12,fire_test,2
    PL_PSS  $1ed34,fire_test,2
    PL_PSS  $1f304,fire_test,2
    PL_PSS  $1f5b4,fire_test,2
    PL_PSS  $21b04,fire_test,2
    PL_PSS  $21b24,fire_test,2
    PL_PSS  $221bc,fire_test,2
    PL_PSS  $22206,fire_test,2
    PL_PSS  $2221a,fire_test,2
    
    PL_PSS  $1b2b0,before_mainloop,2
    
    PL_ENDIF
    
    
    PL_IFC1X    0
    PL_B	$205D4,$4A		; lives
    PL_ENDIF
    
    PL_IFC1X    1
    PL_B	$21030,$4A		; bombs
    PL_ENDIF
    
    PL_IFC1X    2
    PL_B	$1E160,$4A		; energy
    PL_ENDIF


    PL_END
    
before_mainloop
    clr.b   current_rawkey  ; so bwd+fwd can't have been remembered
    jsr $1dbf2
    jmp $2256c
    
; set keyboard interrupt, game part
; also changes address for rawkey storage
; (so we can reuse the same routine for intro & game)
set_keyboard_interrupt:
    move.l  a0,-(a7)
    lea  current_rawkey_address(pc),a0
    move.l  #current_rawkey,(a0)
    lea keyboard_interrupt(pc),a0
    move.l  a0,$68.W
    move.l  (a7)+,a0
    rts
    

;--------------------------------

PatchIntro
    
    movem.l d0-d1/a0-a2,-(a7)
    lea  pl_intro(pc),a0
    sub.l    a1,a1
    move.l   _resload(pc),a2
    jsr  (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2

    jmp	$25D78

pl_intro
    PL_START
    PL_B	$269DC,$60		; skip check protection code
    PL_B	$26A22,$60		; skip check protection code    
    PL_NOP  $269f0,2        ; skip keypress
    ; completely replace keyboard interrupt
    PL_PA   $7498a+2,keyboard_interrupt
    PL_END
  
current_rawkey = $1d748
pause_flag = $1e776
special_case_beamwait = $1e562
current_context = $1e54c
level_completed_flag = $217a6

beam_sync:
	MOVE.W	6(A6),D0		;1b722: 302e0006
	LSR.W	#8,D0			;1b726: e048
	ANDI.B	#$ff,D0			;1b728: 020000ff
	TST.W	special_case_beamwait		;1b72c: 4a790001e562
	BNE.S	.LAB_0063		;1b732: 6608
    ; default beamsync
	CMPI.W	#$00D9,D0		;1b734: was $99, added $40 so no beamrace effect
	BNE.S	beam_sync		;1b738: 66e8
	BRA.S	.LAB_0064		;1b73a: 6014
.LAB_0063:
    ; beamsync depending on level? something else?
	MOVE.W	current_context,D1		;1b73c: 32390001e54c
	ASR.W	#1,D1			;1b742: e241
	ANDI.W	#$00fe,D1		;1b744: 024100fe
	MOVE.W	beamwait_table(PC,D1.W),D1	;1b748: 323b1020
    add.w   #$40,d1     ; fix
	CMP.W	D1,D0			;1b74c: b041
	BNE.S	beam_sync		;1b74e: 66d2
.LAB_0064:
	TST.W	pause_flag		;1b750: 4a790001e776
	BEQ.S	.out		;1b756: 6710
	move.l  joy1(pc),d0
    btst    #JPB_BTN_RED,d0
	beq.S	.out		;1b760: 6606
	CLR.W	pause_flag		;1b762: 42790001e776
.out:
	RTS				;1b768: 4e75
beamwait_table:
	DC.W	$008F,$0087,$0094,$0094,$0094,$0094

    
    
    ; this version can do overscan beamwait, but is not useful here
    ; waiting too much makes horiz scrolling flash
    IFEQ    1
beam_sync:
	MOVE.L	4(A6),D0		;1b722: 302e0006
	and.l	#$1ff00,d0
	TST.W	special_case_beamwait		;1b72c: 4a790001e562
	BNE.S	.LAB_0063		;1b732: 6608
    ; default beamsync
	;cmp.l	#$12F<<8,d0
    move.l  $100,d1
	cmp.l	d1,d0
	BNE.S	beam_sync		;1b738: 66e8
	BRA.S	.LAB_0064		;1b73a: 6014
.LAB_0063:
    ; beamsync depending on level? something else?
	MOVE.W	current_context,D1		;1b73c: 32390001e54c
	ASR.W	#1,D1			;1b742: e241
	ANDI.W	#$00fe,D1		;1b744: 024100fe
    add.w   d1,d1
	MOVE.L	beamwait_table(PC,D1.W),D1	;1b748: 323b1020
	CMP.L	D1,D0			;1b74c: b041
	BNE.S	beam_sync		;1b74e: 66d2
.LAB_0064:
	TST.W	pause_flag		;1b750: 4a790001e776
	BEQ.S	.out		;1b756: 6710
	move.l  joy1(pc),d0
    btst    #JPB_BTN_RED,d0
	beq.S	.out		;1b760: 6606
	CLR.W	pause_flag		;1b762: 42790001e776
.out:
	RTS				;1b768: 4e75
beamwait_table:
	DC.L	$8F00,$8700,$9400,$9400,$9400,$9400
    ENDC
    
    
WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
	rts


level3_interrupt_hook
    move.w  _custom+intreqr,d0
    btst    #5,D0
    bne.b   .vbl
    ; copperlist: return
	MOVE.W	$1e57c,D0		;1c894: 3039000
    rts    
.vbl
    ; vblank: take over
    ; read joypad
    lea .prev_joy(pc),a0
    move.l  (a0),d1
    bsr _joystick
    move.l  joy1(pc),d0
    move.l  d0,(a0)
    
    btst    #JPB_BTN_PLAY,d0
    beq.b   .noplay
    btst    #JPB_BTN_PLAY,d1
    bne.b   .noplay  ; was pressed
    eor.w  #1,pause_flag       ; toggle pause flag
.noplay
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .nofwd
    btst    #JPB_BTN_GRN,d0
    beq.b   .nolskip
    move.w  #1,level_completed_flag
.nolskip
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .nofwd
    btst    #JPB_BTN_YEL,d0
    bne   quit
        
    ; quit current game
    move.b  #$45,current_rawkey
.nofwd
    ; original return to program
    addq.l  #4,a7 ; pop stack
	MOVEM.L	(A7)+,D0-D7/A0-A5	;1c8e2: 4cdf3fff
	MOVE.W	#$0020,_custom+intreq		;1c8e8: 3d7c0010009c
	RTE				;1c8ee: 4e73
    

.prev_joy:
    dc.l    0
    
fire_test
    movem.l  d0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0 
    movem.l (a7)+,d0
    rts

bomb_launch_test
    ; test keyboard
	CMPI.B	#$40,current_rawkey		;20fd0: 0c3900400001d748
    beq .launch
    ; not keyboard: test blue button
    movem.l  d0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_BLU,d0 
    movem.l (a7)+,d0
.launch
    rts
    
;--------------------------------
; completely replace keyboard interrupt

keyboard_interrupt
	BTST.B #$0003,$00bfed01
	BEQ.S	.nokey		;1d704: 6738
	MOVEM.L	D0-D1/A0,-(A7)		;1d706: 48e7c080
	MOVE.B	$bfec01,D0		;1d70a: 103900bfec01
	NOT.B	D0			;1d730: 4600
	ROR.B	#1,D0			;1d732: e218
    cmp.b   _keyexit(pc),d0
    beq.b   quit
    move.l  current_rawkey_address(pc),a0
	MOVE.B	D0,(a0)       ; game location for rawkey  

    ; in-game only
    cmp.l   #current_rawkey,a0
    bne.b   .nolevelskip
    cmp.b   #$5F,current_rawkey
    bne.b   .nolevelskip
    move.w  #1,level_completed_flag
.nolevelskip

	BSET	#$06,$bfee01
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$bfee01	; acknowledge key
    
	MOVEM.L	(A7)+,D0-D1/A0		;1d73a: 4cdf0103
.nokey:
	MOVE.W	#$0008,_custom+intreq		;1d73e: 33fc000800dff09c
	RTE				;1d746: 4e73


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

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

    
;--------------------------------

ChangeDisk1
		move.l	A0,-(A7)

		lea	DiskNr(pc),A0
		move.w	#1,(A0)

		move.l	(A7)+,A0
		rts
ChangeDisk2
		move.l	A0,-(A7)

		lea	DiskNr(pc),A0
		move.w	#2,(A0)

		move.l	(A7)+,A0
		rts

;--------------------------------

; Byte Killer optimized decrunch procedure

Decrunch
		movem.l	(A0)+,D0-D1/D5
		movea.l	A1,A2
		add.l	D0,A0
		add.l	D1,A2
		move.l	-(A0),D0

		eor.l	D0,D5
lbC000012
		lsr.l	#1,D0
		beq.s	lbC000040
lbC000016
		bcs.s	lbC000078
		moveq	#7,D1
		moveq	#1,D3
		lsr.l	#1,D0
		beq.s	lbC000044
lbC000020
		bcs.s	lbC00009A
		moveq	#2,D1
		clr.w	D4
lbC000026
		bsr.s	lbC00005E
		move.w	D2,D3
		add.w	D4,D3
lbC00002C
		moveq	#7,D1
lbC00002E
		lsr.l	#1,D0
		beq.s	lbC000048
lbC000032
		addx.b	D2,D2
		dbra	D1,lbC00002E
		move.b	D2,-(A2)
		dbra	D3,lbC00002C
		bra.s	lbC0000A4

lbC000040
		bsr.s	lbC000052
		bra.s	lbC000016

lbC000044
		bsr.s	lbC000052
		bra.s	lbC000020

lbC000048
		bsr.s	lbC000052
		bra.s	lbC000032

lbC00004C
		moveq	#7,D1
		moveq	#8,D4
		bra.s	lbC000026

lbC000052
		move.l	-(A0),D0
		eor.l	D0,D5
		roxr.l	#1,D0
		bset	#$1F,D0
		rts

lbC00005E
		clr.w	D2
lbC000060
		lsr.l	#1,D0
		beq.s	lbC00006C
lbC000064
		addx.w	D2,D2
		dbra	D1,lbC000060
		rts

lbC00006C
		move.l	-(A0),D0
		eor.l	D0,D5
		roxr.l	#1,D0
		bset	#$1F,D0
		bra.s	lbC000064

lbC000078
		moveq	#1,D1
		bsr.s	lbC00005E
		cmpi.b	#2,D2
		blt.s	lbC000092
		cmpi.b	#3,D2
		beq.s	lbC00004C
		moveq	#7,D1
		bsr.s	lbC00005E
		move.w	D2,D3
		moveq	#11,D1
		bra.s	lbC00009A

lbC000092
		moveq	#8,D1
		add.w	D2,D1
		addq.w	#2,D2
		move.w	D2,D3
lbC00009A
		bsr.s	lbC00005E
lbC00009C
		move.b	-1(A2,D2.W),-(A2)
		dbra	D3,lbC00009C
lbC0000A4
		cmpa.l	A2,A1
		blt.w	lbC000012
		move.l	D5,D0
		rts

;--------------------------------

Load
		movem.l	d0-a6,-(A7)

		lea	DiskNr(pc),A1
		cmp.w	#1,(A1)
		beq.b	disk1

		tst.w	d2
		bne.b	side2

		addq.w	#1,D0
		bra.b	skip2
side2
		cmp.w	#37,D0
		bhi.b	high

		add.w	#79,D0
		bra.b	skip2
high
		add.w	#79-4,D0
		bra.b	skip2
disk1
		subq.w	#1,D0
		tst.w	d2
		beq.b	skip2

		add.w	#79,D0
skip2
		mulu	#$1400,D0
		mulu	#$1400,D1

		moveq	#0,D2
		move.w	(A1),D2

		bsr.b	_LoadDisk

		movem.l	(A7)+,d0-a6

		moveq	#0,D4
		rts

DiskNr		dc.w	1

tag		dc.l	WHDLTAG_CUSTOM3_GET
start_level		dc.l	0
		dc.l	0
        
current_rawkey_address
    dc.l    $74de4      ; value in intro kb interrupt
;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================

	END
