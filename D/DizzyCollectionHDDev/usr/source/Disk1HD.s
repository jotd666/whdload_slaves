;8-Jan-2002: optimalizovan kod pro Kwik Snax, lepsi KeyHandler

		INCDIR	"Include:"
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i


_base		SLAVE_HEADER
		dc.w	17
		dc.w	WHDLF_NoError|WHDLF_EmulTrap
		dc.l	$80000
		dc.l	0
		dc.w	_Start-_base
		dc.w	dir-_base
		dc.w	0
_keydebug	dc.b	0
_keyexit	dc.b	$59
		dc.l	0
		dc.w	_name-_base
		dc.w	_copy-_base
		dc.w	_info-_base
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

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
	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	0


_config
        dc.b    "C1:B:infinite lives;"
        dc.b    "C2:B:second button jumps;"
		dc.b	0

dir		dc.b	"data",0
_name		dc.b	"Dizzy Collection [disk 1]",0
_copy		dc.b	"1991 Code Masters",0
_info		dc.b	"adapted by Bored Seal & JOTD",10,10
		dc.b	"Version "
        DECL_VERSION
        dc.b    0
    even
    
IGNORE_JOY_DIRECTIONS
    include     ReadJoyPad.s
    
_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2
        lea     (_tags,pc),a0
        jsr     (resload_Control,a2)

		lea	filename(pc),a0
		lea	$20000,a1
		bsr	LoadFile

		move.l	a1,-(sp)
		move.l	a1,a0
		move.l	d1,d0
		jsr     (resload_CRC16,a2)
		cmp.w	#$ef82,d0
		bne	Unsupported
		move.l	(sp)+,a1

    movem.l d0-d1/a0-a2,-(a7)
    lea pl_boot1(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2



		jsr	$3a(a1)

    movem.l d0-d1/a0-a2,-(a7)
    sub.l   a1,a1
    lea pl_boot2(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2

		jmp	$404.w

pl_boot1
        PL_START
		PL_P	$78,Decrunch
		PL_R	$76
        PL_END
        
pl_boot2
        PL_START
		PL_B	$e80,$60		;remove protection
		PL_R	$552	;block copylock

		PL_P	$13c4,Load
		PL_W	$1352,$6030

		PL_P	$1244,Decrunch

		PL_PA	$111e,Patch_Magic

		PL_P	$100,Patch_Food
		PL_W	$1180,$100

		PL_PA	$1204,Patch_Kwik
        PL_END
        
Patch_Magic    
    movem.l d0-d1/a0-a2,-(a7)
    bsr _detect_controller_types

    ; install key handler
LAB_0014:
	SUBA.L	A0,A0			;5c3d2: 91c8
	LEA	$58ab0,A1		;5c3d4: 43f9000
LAB_0015:
	CLR.B	(A0)+			;5c3da: 4218
	CMPA.L	A1,A0			;5c3dc: b1c9
	BNE.S	LAB_0015		;5c3de: 66fa
    
    lea    KeyHandler_magic(pc),a1
    move.l  a1,$68.W

    sub.l   a1,a1
    lea pl_magic(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2

   	jmp	$5c004

pl_magic
    PL_START
    PL_P	$644ac,Load
    PL_W	$6443a,$6030

    PL_S    $5c826,$5c874-$5c826    ; no need for expansion
    PL_R    $5c3d2      ; no memory clear
    PL_P    $5c2f6,read_joypad_vbl   ; no keyboard handling, read joypad instead
    PL_R    $5c3c4      ; hack keyboard handler to re-use in int2
    
    PL_CW	$5c690			;remove bad bplcon2 code
    PL_CW	$61afa
    PL_CW	$61b0c

    PL_P	$6479a,Decrunch

    ;;PL_NOP  $669c8,8
    ;;PL_S    $5c2cc,$5c2e8-$5c2cc
    
    PL_W    $5c084+2,$2000  ; all interrupts on
    PL_ORW  $5C08C+2,$8     ; re-enable keyboard interrupt
    PL_IFC1
    PL_W	$5d48c,$6002	;unlimited lives
    PL_ENDIF
    
    PL_IFC2
    PL_PS   $5c480,read_joystick_magic
    PL_S    $5c486,$5c490-$5c486
    PL_PS   $5d52c,test_jump

    PL_ENDIF
    PL_END

read_joypad_vbl
    move.l d0,-(a7)
    bsr _joystick
    move.l  joy1(pc),d0
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d0
    bne _quit
    
.noquit
    movem.l (a7)+,d0
    rts
 
test_jump
    move.l   d1,-(a7)
    move.l  joy1(pc),d1
	BTST	#JPB_BTN_BLU,d1
    movem.l (a7)+,d1
	bne.b   .jump		;5c488: 6606
    addq.l  #4,a7   ; pop
.jump
    rts


    
read_joystick_magic:
    move.l   d1,-(a7)
    move.l  joy1(pc),d1
	BTST	#JPB_BTN_RED,d1
	beq.S	.LAB_001C		;5c488: 6606
	MOVE.W	#$0001,$154.W
    ; read joystick
.LAB_001C:
    movem.l (a7)+,d1
    rts
    
        
Patch_Food
    movem.l d0-d1/a0-a2,-(a7)
    sub.l   a1,a1
    lea pl_food(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2

	jmp	$1000.W

pl_food
    PL_START
    PL_PS	$5a1a4,BeamDelay
    PL_P    $6794e,keyboard_food
    PL_IFC1
    PL_L	$112a,$6000FEE6
    PL_ENDIF
    PL_END

keyboard_food
	MOVE.W	D0,D1			;6794e: 3200
    ; handshake
	bsr	BeamDelay
    move.w  d1,d0
	BCLR	#6,$bfee01
    ; 68000 quitkey
    cmp.b   _keyexit(pc),d0
    beq _quit
	ANDI.W	#$007f,D1		;67950: 0241007f
	ANDI.W	#$0080,D0		;67954: 02400080
	LEA	$67978,A0		;67958: 41f9000
	MOVE.B	D0,0(A0,D1.W)		;6795e: 11801000    
	MOVEM.L	(A7)+,D0-D1/A0		;6796a: 4cdf0103
	MOVE.W	#$0008,$dff09c
	RTE				;67976: 4e73
    
Patch_Kwik    
    movem.l d0-d1/a0-a2,-(a7)
    lea keytable(pc),a1
    move.l  #$180,(a1)
    sub.l   a1,a1
    lea pl_kwik(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2

    jmp	$3ea.w

pl_kwik
    PL_START
    PL_PSS  $5d99e,BeamDelay,2 ;fix music for cache
    PL_PS   $5df20,BeamDelay

    PL_P	$3ccd4,KeyHandler

    PL_IFC1
    PL_W	$98c8,$6004
    PL_ENDIF
    PL_END

_quit
        pea	TDREASON_OK
        move.l	_resload(pc),-(a7)
        addq.l	#resload_Abort,(a7)
        rts

KeyHandler_magic
        movem.l	d0-d1/a0-a1,-(sp)
        bsr kh_common
        move.l  joy1(pc),d1
        btst    #JPB_BTN_REVERSE,d1
        beq.b   .noquit
        btst    #JPB_BTN_FORWARD,d1
        beq.b   .noquit
        move.b  #$45,d1
.noquit
        ; call a part of the original vblank
        ; routine that handles the keyboard
        jsr $5c370
        movem.l	(sp)+,d0-d1/a0-a1
		move.w	#8,$dff09c
		rte
    
KeyHandler	
        movem.l	d0/a0-a1,-(sp)
        bsr kh_common
        movem.l	(sp)+,d0/a0-a1
		move.w	#8,$dff09c
		rte

kh_common:
		lea	$bfec01,a0
		move.b	($100,a0),d0
		btst	#3,d0
		beq	.nokb
		moveq	#0,d0
		move.b	(a0),d0
		clr.b	(a0)
		ori.b	#$40,($200,a0)
		ror.b	#1,d0
		not.b	d0
        cmp.b   _keyexit(pc),d0
        beq   _quit

        move.l  keytable(pc),a1
        cmp.l   #0,a1
        beq.b   .zap
		bclr	#7,d0
		sne	(a1,d0.w)
.zap
		bsr	kb_delay
		andi.b	#$bf,$200(a0)
.nokb        
        rts

Load		bsr	LoadFile
		rte

LoadFile	movem.l	a0-a2,$150
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFile,a2)
		movem.l	$150,a0-a2
		move.l	d0,d1
		clr.l	d0
		rts
kb_delay
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
    rts
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

BeamDelay	moveq	#7,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0
BM_2		cmp.b	$dff006,d0
		beq	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
		rts

Unsupported	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

Decrunch	MOVE.L	D0,D1
		MOVEA.L	A0,A1
		MOVEA.L	A0,A2
		MOVE.L	(4,A1),D7
		LEA	(8,A1),A1
		MOVE.W	D1,D2
		LSR.L	#4,D1
		SUBQ.W	#1,D1
		BMI.B	lab16
lab1		MOVE.L	(A1)+,(A2)+
		MOVE.L	(A1)+,(A2)+
		MOVE.L	(A1)+,(A2)+
		MOVE.L	(A1)+,(A2)+
		DBRA	D1,lab1
lab16		ANDI.W	#15,D2
		SUBQ.W	#1,D2
		BMI.B	lab17
until3		MOVE.B	(A1)+,(A2)+
		DBRA	D2,until3
lab17		SUBQ.L	#8,D0
		ADDA.L	D0,A0
		LEA	(value1,PC),A5
		MOVE.L	D7,(A5)
		MOVEQ	#1,D4
		MOVEQ	#1,D5
		MOVEQ	#3,D6
		MOVEQ	#7,D7
		MOVEA.L	A3,A2
		MOVE.L	-(A0),D1
		TST.B	D1
		BEQ.B	lab15
		BSR.B	lab9
		SUB.L	D4,D1
		LSR.L	D1,D5
lab15		LSR.L	#8,D1
		ADDA.L	D1,A3
lab18		BSR.B	lab9
		BCS.B	lab6
		MOVEQ	#0,D2
lab14		MOVE.W	D4,D0
		BSR.B	lab10
		ADD.W	D1,D2
		CMP.W	D6,D1
		BEQ.B	lab14
lab13		MOVEQ	#7,D0
		BSR.B	lab10
		MOVE.B	D1,-(A3)
		DBRA	D2,lab13
		CMPA.L	A3,A2
		BCS.B	lab6
		RTS

lab9		LSR.L	D4,D5
		BEQ.B	lab12
		RTS

lab12		MOVE.L	-(A0),D5
		ROXR.L	D4,D5
		RTS

lab8		SUB.W	D4,D0
lab10		MOVEQ	#0,D1
until1		LSR.L	D4,D5
		BEQ.B	lab5
lab11		ROXL.L	D4,D1
		DBRA	D0,until1
		RTS

lab5		MOVE.L	-(A0),D5
		ROXR.L	D4,D5
		BRA.B	lab11

lab6		MOVE.W	D4,D0
		BSR.B	lab10
		MOVEQ	#0,D0
		MOVE.B	(A5,D1.W),D0
		MOVE.W	D1,D2
		CMP.W	D6,D2
		BNE.B	lab3
		BSR.B	lab9
		BCS.B	lab7
		MOVEQ	#7,D0
lab7		BSR.B	lab8
		MOVE.W	D1,D3
lab2		MOVEQ	#2,D0
		BSR.B	lab10
		ADD.W	D1,D2
		CMP.W	D7,D1
		BEQ.B	lab2
		BRA.B	lab4

lab3		BSR.B	lab8
		MOVE.W	D1,D3
lab4		ADD.W	D4,D2
until2		MOVE.B	(A3,D3.W),-(A3)
		DBRA	D2,until2
		CMPA.L	A3,A2
		BCS.B	lab18
		RTS
keytable
    dc.l    0
value1		dc.l	0
_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0,0
filename	dc.b	"VC",0
