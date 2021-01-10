;*---------------------------------------------------------------------------
;  :Author.	JOTD
;  :History.	
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	MasterAxe.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

USE_FASTMEM

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError	;ws_flags
		dc.l	$180000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem	
	dc.l	0
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
_config
    dc.b	0
    
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
    
_name		dc.b	"Master Axe"
		dc.b	0
_copy		dc.b	"1994 Epic",0
_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$VER: slave "
	DECL_VERSION
    dc.b    0
	even


    
;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

;		move.l	a0,a2
;		lea	(_tag,pc),a0
;		jsr	(resload_Control,a2)

        move.l  _resload(pc),a2
        lea $c0.W,a1
        lea bootname(pc),a0
        jsr (resload_LoadFileDecrunch,a2)
        
        lea pl_boot(pc),a0
        sub.l   a1,a1
        jsr (resload_Patch,a2)
        
        jmp $C0.W
        ; relocate stack in fastmem (Bert)
;		move.l  _expmem(pc),d0
;        add.l   #$1000,d0
;        move.l  d0,a7

		; load & version check

read_file:
	movem.l	d0-d1/a0-a2,-(sp)
	addq.l	#4,A0		; skip 'DFx:'
    move.l  _resload(pc),a2
    jsr     (resload_LoadFile,a2)
    movem.l	(a7)+,d0-d1/a0-a2
    moveq.l #0,d0
    rts
    

RNCDecrunch
	movem.l	d0-d1/a0-a2,-(sp)
    move.l  _resload(pc),a2
    jsr     (resload_Decrunch,a2)
	cmp.l	#$2C790000,$120218
	bne.b	.skipp1
    lea pl_prog1(pc),a0
    sub.l   a1,a1
    jsr (resload_Patch,a2)
    bra.b   .skipp2
.skipp1
	cmp.l	#$2C790000,$1202AC
	bne.b	.skipp2
    lea pl_prog2(pc),a0
    sub.l   a1,a1
    jsr (resload_Patch,a2)
.skipp2
    movem.l	(a7)+,d0-d1/a0-a2
    rts
    
pl_prog1:
    PL_START
	PL_W	$120218,$6010
	PL_W	$120238,$6016
    PL_PS   $00120436,quit_hook
    PL_PSS  $121A8C,dma_wait,2
    
    PL_END
pl_prog2:
    PL_START
	PL_W	$1202AC,$6010
	PL_W	$1202CC,$6016
    PL_PSS  $00121206,dma_wait,2
    PL_PS   $0000491A,quit_hook_2
    PL_END

dma_wait
	move.w	#6,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts 

quit_hook:
    LEA.L $00dff000,A5
    bra.b   quit_common
quit_hook_2
    MOVE.W $00dff01e,D0
quit_common    
	move.l	D1,-(sp)
	move.b	($BFEC01),D1
	ror.b	#1,D1
	not.b	D1
	cmp.b	_keyexit(pc),D1
	beq     _quit	
	move.l	(sp)+,D1
	rts
 
KbInt:
	move.b	($BFEC01),D1
	move.l	D1,-(sp)
	ror.b	#1,D1
	not.b	D1
	cmp.b	_keyexit(pc),D1
	beq     _quit	
	move.l	(sp)+,D1
	rts

FlushNJump:
	;JSRGEN	FlushCachesHard
	JMP	($1201AE)
    
pl_boot
	PL_START
	PL_P	$4BFC,read_file	; file read
	PL_PS	$44C0,KbInt		; quit key
	PL_P	$E17E,RNCDecrunch	; decrunch in fastmem
	PL_PS	$654,FlushNJump	; flush caches + reset sprites
	PL_W	$592,$603A			; removes trash system code
	PL_END

    
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

;--------------------------------

_resload	dc.l	0		;address of resident loader

bootname:
	dc.b	"qmxa500.RNC",0

