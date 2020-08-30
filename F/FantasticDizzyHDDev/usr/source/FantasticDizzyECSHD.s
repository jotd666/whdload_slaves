;V1.0 (03-Jan-2002)

	INCDIR	Include:
	INCLUDE	whdload.i
	include	whdmacros.i
    

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

;CHIPONLY = 1
    IFD CHIPONLY
BASEMEMSIZE = $100000
EXPMEMSIZE = 0
    ELSE
BASEMEMSIZE = $80000
EXPMEMSIZE = $80000
    ENDC
    
_base		SLAVE_HEADER
		dc.w	17
		dc.w	WHDLF_NoError|WHDLF_EmulTrap
		dc.l	BASEMEMSIZE
		dc.l	0
		dc.w	_Start-_base
		dc.w	dir-_base
		dc.w	0
_keydebug	dc.b	0
_keyexit	dc.b	$5D
_expmem
		dc.l	EXPMEMSIZE
		dc.w	_name-_base
		dc.w	_copy-_base
		dc.w	_info-_base
		dc.w    0     ; kickstart name
		dc.l    $0         ; kicksize
		dc.w    $0         ; kickcrc
		dc.w	slv_config-_base


slv_config:
    dc.b    "C1:X:Infinite lives:0;"
	dc.b	0

dir		dc.b	"data",0
_name		dc.b	"Fantastic Adventures of Dizzy (ECS)"
    IFD CHIPONLY
    dc.b    " (DEBUG/CHIP MODE)"
    ENDC
    dc.b    0
    
_copy		dc.b	"1993 Code Masters",0
_info		dc.b	"Adapted by Bored Seal & JOTD",10
		DECL_VERSION
        dc.b    0
		even

_get_expmem
    IFD CHIPONLY
    lea $80000,a1
    ELSE
    move.l  _expmem(pc),a1
    ENDC
    rts
    
_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2


		lea	filename(pc),a0
		lea	$7fe0,a1
		move.l	a1,a5
		jsr     (resload_LoadFile,a2)
		
		move.l	#'IMP!',(a5)
		move.l	a5,a0
		move.l	a5,a1
		bsr	Decrunch

        bsr _get_expmem
        move.l  a1,a4 	;set expansion memory
        
		lea	_intro(pc),a0
		suba.l	a1,a1
		jsr     (resload_Patch,a2)

		suba.l	a5,a5
		jmp	$8010

PatchGame	lea	_game(pc),a0
        bsr _get_expmem
		move.l	a1,a6
		move.l	_resload(pc),a2
		jsr     (resload_Patch,a2)
	
        jmp	$20(a6)

_intro		PL_START
		PL_P	$a76a,LoadFile
		PL_P	$a606,Decrunch
		PL_P	$962e,Copylock		;remove copylocks
		PL_PA	$81a4,Copylock2
		PL_PA	$a31e,Copylock2
		PL_NOP	$81aa,2
		PL_NOP	$a324,2
		PL_W	$94a0,$601e		;don't wait for button
		PL_PA	$818c,PicWait		;wait for title
		PL_P	$8236,PatchGame
        PL_PS   $84A0,keyboard  ; quitkey on 68000
        PL_PS   $84BE,handshake
        PL_S    $84BE+6,$4FA-$4BE
		PL_END

_game		PL_START
    PL_P	$c242,LoadFile      ; offset ($C222)
    PL_NOP	$f256,2	;remove copylock in bubble subgame (offset $0f236)
    PL_NOP	$dfde,2	;remove copylock in archery subgame (offset $0dfbe)
    PL_PS	$19caa,Copylock3	;remove copylock after Zack is killed
    PL_P	$a98e,Decrunch      ; offset $0a96e
    
    PL_PS   $882,keyboard  ; quitkey on 68000
    PL_PS   $8A0,handshake
    PL_S    $8A6,$8DC-$8A6
    PL_IFC1
    PL_W	$16d68,$6002	;unlimited lives
    PL_W	$17252,$6002        
    PL_ENDIF

    ; dma wait (sound)
    PL_PS   $1a65c,dma_wait_off
    PL_PSS  $1A728,dma_wait_on,2
        
        
	PL_END
dma_wait_on
	ORI.W	#$8000,D7		;: 00478000
	MOVE.W	D7,(150,A6)		;01b456: 3d470096
    bra dw
dma_wait_off
  	MOVE.W	D5,150(A6)		;1a63c: 3d450096
	OR.W	D5,D7			;1a640: 8e45
dw:    
	move.w  d0,-(a7)
	move.w	#4,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
    
    RTS
keyboard:
    MOVE.B $00bfec01,D0
    movem.w d0,-(a7)
    ror.b   #1,d0
    not.b   d0
    cmp.b   _keyexit(pc),d0
    movem.w (a7)+,d0    ; movem preserves flags
    bne.b   .noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit    
    rts    
    
handshake:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
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

PicWait		bsr	LoadFile
		waitbutton
		rts

Copylock3	moveq	#0,d0
		moveq	#0,d1
		move.l	#$347C2B8E,d5
		rts

Copylock2	jsr	$a5c4
		MOVE.L	#$309D8027,D6
		MOVE.L	#$347C2B8E,D7
		MOVE.L	#$1800000,D0
		MOVEQ	#-2,D1
		suba.l	a0,a0
		MOVE.L	D0,(A0)+
		MOVE.L	D1,(A0)
		SWAP	D7
		MOVE.L	D7,D5
		RTS

Copylock	move.l	#$347C2B8E,d5
		lea	$1A6,a0
		move.l	d5,(a0)
		move.l	d5,$F4
		move.l	d5,$7FEC6
		move.l	d5,$7FF04
		move.l	D5,$7FFC6
		rts

LoadFile	movem.l	a0-a2/d0-d1,-(sp)
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFile,a2)
		movem.l	(sp)+,a0-a2/d0-d1
		rts

Decrunch	movem.l	a0-a2,-(sp)
		move.l	(_resload,pc),a2
		jsr	(resload_Decrunch,a2)
		movem.l	(sp)+,a0-a2
		rts

_resload	dc.l	0

filename	dc.b	"intro.dat",0
