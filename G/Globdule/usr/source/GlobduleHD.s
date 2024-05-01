;*---------------------------------------------------------------------------
;  :Program.	Globdule.asm
;  :Contents.	Slave for "Globdule" from Psygnosis
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	07.01.99
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
	OUTPUT	Globdule.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC


;======================================================================



;CHIP_ONLY

CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		IFD	CHIP_ONLY
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ELSE
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	CHIP_ONLY	
	dc.l	0
	ELSE
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
_config
    dc.b    "C1:X:Trainer Infinite Lives:0;"
    dc.b    "C1:X:Trainer Infinite Energy:1;"
    dc.b    "C1:X:Trainer help skips levels:2;"
	dc.b	0

;============================================================================

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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

_name		dc.b	"Globdule"
    IFD CHIP_ONLY
    dc.b    " (DEBUG/CHIP mode)"
    ENDC
		dc.b	0
_copy		dc.b	"1993 Psygnosis",0
_info		dc.b	"adapted & fixed by Mr Larmer & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

KEYBOARD_CODE_LENGTH = 124  ; $CA-$4E
HIGHSCORE_TABLE_LENGTH = $DA
PAL_HI_OFFSET = $2d96c
NTSC_HI_OFFSET = $2d9de

IGNORE_JOY_DIRECTIONS
    include    ReadJoyPad.s
    
;======================================================================
start	;	A0 = resident loader
;======================================================================
 
        ;;move.w  #0,$DFF1DC   ; force NTSC
		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

        bsr _detect_controller_types
		
		move.l	_resload(pc),a2
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
        
		lea	$100.w,A0
		moveq	#0,D0
		move.l	#$400,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		move.l	#$400,D0
		jsr	resload_CRC16(a2)

		cmp.w	#$7F78,D0
		bne.w	.not_support

		; PAL/NTSC versions share the same boot

		lea	$100.w,A0
		move.l	#$400,D0
		move.l	#$1200,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		bsr	get_expmem
		move.l	d0,$B54.W	; extmem

		move.l	_resload(pc),a2
		lea	pl_boot(pc),a0
		sub.l	a1,a1
		jsr	resload_Patch(a2)

		lea	Tags(pc),a0
		jsr	resload_Control(a2)

		moveq	#0,d0
		move.l	_chiprevbits(pc),d1
		and.w	#15,d1
		cmp.w	#15,d1
		bne.b	.skip

		moveq	#-1,d0
.skip
		jmp	$100.w
.not_support
		subq.l	#8,a7
		pea	TDREASON_WRONGVER.w
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

get_expmem
	IFD	CHIP_ONLY	
	move.l	#CHIPMEMSIZE,d0
	ELSE
	move.l	_expmem(pc),d0
	ENDC
	rts

pl_boot
		PL_START
		PL_W	$10E,$6012		; skip set cache
		PL_NOP	$12C,2		; skip clear zero page
		PL_W	$140,$6006		; skip wrong access to CIA

		PL_NOP	$226,2
		PL_PS	$228,patch_main

		PL_P	$252,Load

		PL_R	$6C4		; skip check ext mem
		PL_R	$720		; skip drive ?
		PL_L	$76A,$70004E75	; skip drive ?
		PL_END

Tags
		dc.l	WHDLTAG_CHIPREVBITS_GET
_chiprevbits
		dc.l	0
		dc.l	0

;--------------------------------

patch_main
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	lea	pl_main(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	move.w	$22(a5),d0
	jmp	$1304.w

pl_main
	PL_START
	PL_PS	$1336,patch1
	PL_END

;--------------------------------


patch1
	movem.l	d0-d2/a0-a4,-(a7)
	bsr	get_expmem
    lea borrowed_code(pc),a3
	move.l	_resload(pc),a2
	move.l	d0,a0

	cmp.w	#$4EB9,$1130(a0)
	beq.b	.ntsc
.pal
    move.l  #PAL_HI_OFFSET,d1
    add.l   #$204e,d0
	move.l	#$F3AE,d2
	lea	pl_pal(pc),a0
	bra.b	.do
.ntsc
    move.l  #NTSC_HI_OFFSET,d1
    add.l   #$209c,d0
	move.l	#$f422,d2
	lea	pl_ntsc(pc),a0
.do
    bsr load_hiscores
    move.l  d0,a4
    move.l  #KEYBOARD_CODE_LENGTH-1,d0
.copy
    move.b  (a4)+,(a3)+
    dbf d0,.copy
   
	bsr	get_expmem	
	add.l	d0,d2
	lea	level_flag_address(pc),a1
	move.l	d2,(a1)
	move.l	d0,a1

	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d2/a0-a4

	move.l	$1512.w,a0
	jmp	(a6)

    
save_hiscores
    MOVE.W	#$000a,D2		;8b186: 343c000a
	MOVE.W	#$0020,D1		;8b18a: 323c0020  
    
	movem.l	d0-d1/a0-a2,-(a7)
    move.l  hiscores_address(pc),a1
    lea highscores(pc),a0
    move.l  _resload(pc),a2
    move.l  #HIGHSCORE_TABLE_LENGTH,d0
    jsr (resload_SaveFile,a2)
	movem.l	(a7)+,d0-d2/a0-a1
    rts
    
load_hiscores
	movem.l	d0-d2/a0-a1,-(a7)
    move.l  d1,d2
	bsr	get_expmem	
    add.l   d0,d2
    ; compute & save hiscores address
    lea hiscores_address(pc),a0
    move.l  d2,(a0)

    lea highscores(pc),a0
    jsr (resload_GetFileSize,a2)
    tst.l   d0
    beq.b   .out

    move.l  d2,a1
    lea hiscores_address(pc),a0
    lea highscores(pc),a0
    jsr (resload_LoadFile,a2)    
.out
	movem.l	(a7)+,d0-d2/a0-a1
    rts
    ; pal lives 0008F443=0030 00091FC3=0030 00092047=0030
pl_pal
	PL_START
    ; skip manual protection    
    ;PL_NOP  $104C,6
    ;PL_NOP  $2986,4         ; no wait for password
	;PL_B	$2984,$41		; set "A" so password is not empty else no password at end of level

    ; show protection
	;PL_W	$299C,$6034		; all protection codes work
	PL_PSS	$299a,copy_correct_password,2
	
	PL_PS   $2030,kb_hook
    PL_PSS  $1ece,vbl_hook,2
    PL_PS   $733e,test_fire
    PL_S    $7344,8  

    PL_IFC1
    PL_IFC1X    0
    PL_NOP  $3372,2 ; infinite lives
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $5fca,2 ; infinite energy
    PL_ENDIF
    PL_ELSE
    PL_PSS   $b186,save_hiscores,2
    PL_ENDIF
	PL_END


pl_ntsc
	PL_START
    ; skip manual protection screen, no password at end of level 1!!!    
    ; so we can't do this
    ;;PL_NOP  $104C,6         
	;PL_W	$29EA,$6034		; all protection codes work
	PL_PSS	$29e8,copy_correct_password,2
	
	PL_R	$1130			; skip country check
	PL_PS   $207e,kb_hook
    PL_PSS  $1f1c,vbl_hook,2
    PL_PS   $739a,test_fire
    PL_S    $739a+6,8

    PL_IFC1
    PL_IFC1X    0
    PL_NOP  $33ce,2 ; infinite lives
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $6026,2 ; infinite energy
    PL_ENDIF
    PL_ELSE
    PL_PSS   $af62,save_hiscores,2
    PL_ENDIF


	PL_END

TEST_BUTTON:MACRO
    move.b  #\2,d1  ; pressed: put keycode
    btst    #JPB_BTN_\1,d2
    beq.b   .nochange_\1
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    bset    #7,d1
.pressed_\1    
    ; call copy of the original keyboard handler processing
    ; (store keycode in 3 different ways)
    bsr     put_keycode
.nochange_\1
    ENDM

copy_correct_password:
	move.L	(A1)+,(A0)+		;8299a: b388
	move.W	(A1)+,(A0)+		;829a0: b348
	clr.b	d0		; set Z flag
	rts
	
test_fire:
    move.l  joy1(pc),d0
    btst    #JPB_BTN_RED,d0
    sne d0
    ext.w   d0    
    rts
    
vbl_hook
    movem.l d0-d2/a0-a1,-(a7)
    ; don't waste cycles reading input at 50Hz, game
    ; updates are 25Hz
    lea alternate_input_read(pc),a0
    move.b  (a0),d0
    bchg    #0,d0
    move.b  d0,(a0)
    bne   .nochange
    
    lea prev_buttons_state(pc),a0
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_joystick
    move.l  joy1(pc),d0
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; xor to d2 to get what has changed quickly
    move.l  d0,d2
    eor.l   d1,d2
    beq   .nochange   ; cheap-o test just in case no input has changed
    ; d2 bears changed bits (buttons pressed/released)
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noesc
    TEST_BUTTON FORWARD,$45
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noesc
    btst    #JPB_BTN_YEL,d0
    bne _quit
.noesc
    TEST_BUTTON BLU,$40     ; switch fruit
    TEST_BUTTON GRN,$50
    TEST_BUTTON YEL,$51
    TEST_BUTTON PLAY,$19     ; pause
.nochange    
    movem.l (a7)+,d0-d2/a0-a1
    MOVE.W	#$0020,$dff09c  ; original code
    rts

    
    
kb_hook:
    move.l d1,-(a7)
    ror.b   #1,d1
    not.b   d1
	
    cmp.b   _keyexit(pc),d1
    beq.b   _quit
    cmp.b   #$5F,d1
    bne.b	.nolskip
	move.l	trainer(pc),d1
	btst	#2,d1
	beq.b	.nolskip
	; skip level
	move.l	a0,-(a7)
	move.l	level_flag_address(pc),a0
	move.l	#$FFFF0001,(a0)	; end level + completed
	move.l	(a7)+,a0
.nolskip:
    move.l (a7)+,d1
    MOVE.B	#$40,3584(A0)
    rts

_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts        
;--------------------------------

Load
	movem.l	d0-a6,-(a7)

	jsr	$5BC.w			; init regs

	move.l	a1,$14(a5)		; dest
.again
	move.l	$10(a5),a0
	moveq	#0,d0
	move.l	#$1600,d1
	lea	DiskNr(pc),a1
	moveq	#0,d2
	move.w	(a1),d2
	bsr.w	_LoadDisk		; load dir

	movea.l	$10(a5),a0
	lea	$1000(a0),a0
	lea	$D00.w,a1
	move.w	#$17F,d0
.loop
	move.l	(a0)+,(a1)+
	dbra	D0,.loop

;		movea.l	$10(a5),a0
;		clr.w	$14C0(a0)
;		jsr	$A84.w			; calculate checksum
;		cmp.w	$11C0.w,d0
;		bne.b	bug

	move.l	$20(a7),a0		; file name
	jsr	$852.w			; find filename
	tst.l	d0
	bmi.b	.changedisk

	move.l	d1,d0
	swap	d0
	move.w	d0,$18(a5)
		and.l	#$FFF,d0
		add.l	#11,d0
		mulu	#512,d0
		move.l	d1,d2
		lsr.w	#8,d1
		and.l	#$FF,d1
		mulu	#512,d1
		and.l	#$FF,d2
		add.l	d2,d2
		add.l	d2,d1
		move.l	$24(a7),a0
		lea	DiskNr(pc),a1
		moveq	#0,d2
		move.w	(a1),d2
		bsr.w	_LoadDisk

		tst.w	$18(a5)
		bpl.b	.skip
		bsr.b	Decrunch
.skip
		movem.l	(a7)+,d0-a6
		moveq	#0,D0
		rte
.changedisk
		lea	DiskNr(pc),a1
		moveq	#1,d2
		cmp.w	(a1),d2
		bne.b	.skip2
		move.w	#2,(a1)
		bra.w	.again
.skip2
		move.w	#1,(a1)
		bra.w	.again

DiskNr		dc.w	1

;--------------------------------

Decrunch
	movea.l	$14(A5),A0
	movea.l	$10(A5),A1
	movem.l	D0/D2-D7/A0-A6,-(SP)
	movea.l	A1,A2
	move.l	$140(A0),D0
	move.l	$144(A0),D1
	addq.l	#1,D0
	addq.l	#1,D1
	andi.l	#$FFFFFFFE,D0
	andi.l	#$FFFFFFFE,D1
	lea	3(A0,D0.L),A3
	lea	1(A0,D1.L),A4
lbC0009C6:
	move.b	-(A4),-(A3)
	cmpa.l	A0,A4
	bge.b	lbC0009C6
	addq.l	#1,A3
	movea.l	A0,A1
	movea.l	A3,A0
	movea.l	A2,A5
	lea	$40(A0),A3
	moveq	#7,D7
	movea.l	A0,A6
	bsr.b	lbC000A0E
	move.l	$140(A0),D0
	move.l	D0,D1
	moveq	#7,D7
	lea	$148(A0),A6
lbC0009EA:
	movea.l	A5,A2
lbC0009EC:
	move.w	(A2)+,D3
	bpl.b	lbC000A02
	addq.w	#1,D7
	andi.w	#7,D7
	bne.b	lbC0009FA
	move.b	(A6)+,D4
lbC0009FA:
	btst	D7,D4
	beq.b	lbC0009EC
	suba.w	D3,A2
	bra.b	lbC0009EC

lbC000A02:
	move.b	D3,(A1)+
	subq.l	#1,D0
	bne.b	lbC0009EA
	movem.l	(SP)+,D0/D2-D7/A0-A6
	rts

lbC000A0E:
	addq.w	#1,D7
	andi.w	#7,D7
	bne.b	lbC000A18
	move.b	(A6)+,D4
lbC000A18:
	btst	D7,D4
	bne.b	lbC000A22
	clr.b	(A2)+
	move.b	(A3)+,(A2)+
	rts

lbC000A22:
	move.l	A2,-(SP)
	addq.l	#2,A2
	bsr.b	lbC000A0E
	movea.l	(SP)+,A4
	move.l	A2,D3
	sub.l	A4,D3
	neg.w	D3
	addq.w	#2,D3
	move.w	D3,(A4)
	bra.b	lbC000A0E

;--------------------------------

_resload	dc.l	0		;address of resident loader

put_keycode:
    MOVE.L	D0,-(A7)
borrowed_code:
    ds.b    KEYBOARD_CODE_LENGTH
    MOVE.L	(A7)+,D0
    rts
    
prev_buttons_state
    dc.l    0
alternate_input_read
    dc.w    0
;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
hiscores_address
        dc.l    0
_tag		dc.l	WHDLTAG_CUSTOM1_GET
trainer	dc.l	0

		dc.l	0
level_flag_address
			dc.l	0
highscores:
    dc.b    "Globdule.high",0
    
;======================================================================

	END
