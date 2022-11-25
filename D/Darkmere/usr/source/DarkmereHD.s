;*---------------------------------------------------------------------------
;  :Program.	darkmere.asm
;  :Contents.	Slave for "Darkmere" from Core Design
;  :Author.	MiCK, Wepl
;  :Original	v1 Carlo Pirri
;  :Version.	$Id: Darkmere.Slave.asm 1.3 2016/02/18 22:24:28 wepl Exp wepl $
;  :History.	30.11.00 version 1.0 by MiCK
;		03.07.06 resourced and taglist fixed by Wepl
;			 some cleanup, decruncher replaced
;		14.02.16 fixed address error on 68000/10, issue #3302
;		17.02.16 uses patchlists now, quitkey for 68000 added, ws_config added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	exec/memory.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdmacros.i
	INCLUDE	hardware/custom.i

	IFD BARFLY
	OUTPUT	"wart:d/darkmere/Darkmere.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;CHIP_ONLY

    IFD CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = $1000
    ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $101000
    ENDC
    
    
;============================================================================

ws		SLAVE_HEADER
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_Flags
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	slv_GameLoader-ws	;ws_GameLoader
		dc.w	slv_CurrentDir-ws	;ws_CurrentDir
		dc.w	0			;ws_DontCache
		dc.b	0			;ws_keydebug
_quitkey	dc.b	$59			;ws_keyexit
_expmem
		dc.l	FASTMEMSIZE			;ws_ExpMem
		dc.w	slv_name-ws		;ws_name
		dc.w	slv_copy-ws		;ws_copy
		dc.w	slv_info-ws		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	slv_config-ws		;ws_config

    IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
    
slv_name	dc.b	'Darkmere'
        IFD CHIP_ONLY
        dc.b    " (DEBUG/CHIP mode)"
        ENDC
        dc.b    0
slv_copy	dc.b	'1992/93 Core Design',0
slv_info	dc.b	'installed by MiCK, Wepl, JOTD',10
		dc.b	"Version "
        DECL_VERSION
        dc.b    0
slv_config
    dc.b	"C1:X:infinite help:0;"
    dc.b    "C1:X:infinite magic:1;"
    dc.b    "C1:X:infinite energy:2;"
    dc.b	"C5:B:F9 toogles savegames from floppy;"
    dc.b    0
slv_CurrentDir	dc.b	'Data',0
_main		dc.b	'MAIN.BIN',0
_savedisk	dc.b	'SaveDisk',0
	EVEN
IGNORE_JOY_DIRECTIONS
    include ReadJoyPad.s

;============================================================================

slv_GameLoader
	lea	(_resload,pc),a1
	move.l	a0,(a1)
	movea.l	a0,a2

    lea     (_tag,pc),a0
    jsr     (resload_Control,a2)

    bsr _detect_controller_types
    
    ; check savedisk at startup, else it's not possible
    ; to create it if not present
    lea _savedisk(pc),a0
    moveq	#8,d0
	moveq	#0,d1
	lea $100.W,a1
	movea.l	(_resload,pc),a2
	jsr	(resload_LoadFileOffset,a2)

    ; install fake exec for AllocMem & AvailMem
    lea $1000.W,A6
    move.l  A6,4.W
    move.l  #$FF,d0
    move.l  #$DEADC0DE,d1   ; trash other vectors just in case...
.loop
    move.l  d1,-(a6)
    dbf d0,.loop
    move.l  4.W,a6
    lea (_LVOAllocMem,a6),a0
    move.w  #$4EF9,(a0)+
    pea fake_allocmem(pc)
    move.l  (a7)+,(a0)
    lea (_LVOAvailMem,a6),a0
    move.w  #$4EF9,(a0)+
    pea fake_availmem(pc)
    move.l  (a7)+,(a0)
        
	move.l	#(WCPUF_Base_WT|WCPUF_IC),d0
	move.l	#(WCPUF_Base|WCPUF_IC|WCPUF_DC),d1
	jsr	(resload_SetCPU,a2)

    
    ; chip already configured
    ; set fastmem. Note: in chip_only mode
    ; the fastmem size will be 0
    move.l  _expmem(pc),a3
    lea free_fastmem(pc),a0
    move.l  a3,(a0)+    ; start

    add.l   #FASTMEMSIZE-$1000,a3   ; minus stack
    move.l  a3,(a0) ; top

    ; fake the allocation of the executable
    move.l  #$23300,d0
    moveq.l #0,d1
    move.l  4,a6
    jsr (_LVOAllocMem,a6)
    move.l  d0,a3
    
	lea	(_main,pc),a0
	movea.l	a3,a1
	jsr	(resload_LoadFileDecrunch,a2)

	movea.l	a3,a0
	suba.l	a1,a1
	jsr	(resload_Relocate,a2)

	lea	(_pl_main,pc),a0
	move.l	a3,a1
	jsr	(resload_Patch,a2)

	lea	(_mainstart,pc),a1
	move.l	a3,(a1)

	clr.l	($DFF100).l
    move.l  _expmem(pc),A7
    add.l   #FASTMEMSIZE,A7 ; stack on top of fastmem
	jmp	($808,a3)

_pl_main	PL_START
		PL_P	$18D8,_decrunch
		PL_P	$1b00,_patchkb
        ; save from hard drive
		PL_P	$23A4,_save_cmd0
        
        PL_IFC5
		PL_PS	$bea6,_chkkb_floppysave
        PL_ELSE
		PL_PS	$bea6,_chkkb
        ; insert save disk
		PL_R	$33CC
        ; insert blank disk for format message
		PL_R	$33DC
        PL_ENDIF
        
        PL_IFC1X    0
        ; infinite help & magic
		PL_B	$4A1C,$4A
        PL_ENDIF
        PL_IFC1X    1
		PL_B	$4A42,$4A
        PL_ENDIF
        PL_IFC1X    2
		;PL_NOP	$fac0,10  ; NO! all characters are invincible !
        PL_PS   $12DC,reload_energy
        PL_ENDIF
        
		PL_L	$8FAE,$600008C8		;copy protection
		PL_W	$98FE,$6012		;copy protection
		PL_W	$9952,$601E		;copy protection
        ; access faults
		PL_PSS	$b232,_patch2,2
		PL_PSS	$b258,_patch3,2
		PL_PSS	$e158,_patch4,2
		PL_PSS	$e168,_patch5,2
		PL_PSS	$15FC4,_patchwait,2	;dbf loop
		PL_PSS	$15Fda,_patchwait,2	;dbf loop
		PL_PSS	$16712,_patchwait,2	;dbf loop
		PL_PSS	$16728,_patchwait,2	;dbf loop
		PL_PSS	$1734A,_patchwait,2	;dbf loop
		PL_STR	$18644,<VEUILLEZ  INTRODUIRETEUR>
		PL_B	$1869a,'L'
		PL_W	$186a2,'EU'
        
        ; avoid self-modifying code, thus avoid
        ; having to flush the caches all the time
        PL_PS   $afe2,blitter_smc_avoid

        ; proper blitwaits (some machines don't
        ; like simple btst loop, A1000 but also
        ; some A4000s !!)
        PL_PSS  $15d0,wait_blit,4
        PL_PSS  $16d2,wait_blit,4
        PL_PSS  $185a,wait_blit,4
        PL_PSS  $18aa,wait_blit,4
        PL_PSS  $18c8,wait_blit,4
        PL_PSS  $42c6,wait_blit,4
        PL_PSS  $42fe,wait_blit,4
        PL_PSS  $5686,wait_blit,4
        PL_PSS  $a9f0,wait_blit,4
        PL_PSS  $aa30,wait_blit,4
        PL_PSS  $ab2e,wait_blit,4
        PL_PSS  $ab74,wait_blit,4
        PL_PSS  $ab98,wait_blit,4
        PL_PSS  $b00e,wait_blit,4
        PL_PSS  $b03a,wait_blit,4
        PL_PSS  $b09e,wait_blit,4
        PL_PSS  $b492,wait_blit,4
        PL_PSS  $b74c,wait_blit,4
        PL_PSS  $c134,wait_blit,4
        PL_PSS  $c234,wait_blit,4
        PL_PSS  $c46c,wait_blit,4
        PL_PSS  $cea2,wait_blit,4
        PL_PSS  $ced8,wait_blit,4
        PL_PSS  $e416,wait_blit,4
        
        ; skip exec calls (Forbid/SuperState) and set stack
        PL_S    $80e,$10

                
        PL_S    $9e50,$9ea2-$9e50   ; skip some OS stuff               
        PL_B    $9fe8,$60   ; skip dos close
        
        ; vblank hook for joypad controls
        PL_PSS  $ba84,vblank_hook,4
		PL_END


TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d1
    beq.b   .nochange_\1
    move.b  #\2,d0
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    bset    #7,d0   ; released
.pressed_\1
    bsr keyhandler    
.nochange_\1
    ENDM
    
vblank_hook:
    movem.l D0-D1/A1,-(a7)
    moveq.l #1,d0   ; port 1
    lea prev_buttons_state(pc),a1
    move.l  (a1),d1
    bsr _read_joystick
    bclr    #JPB_BTN_RED,d0 ; ignore fire
    cmp.l   d0,d1
    beq   .nochange
    move.l  d0,(a1) ; store for next time
    eor.l   d0,d1   ; D1: only changes have set bits

    TEST_BUTTON BLU,$40
    TEST_BUTTON PLAY,$19
    TEST_BUTTON YEL,$01
    TEST_BUTTON GRN,$02
    TEST_BUTTON REVERSE,$03
    TEST_BUTTON FORWARD,$04
    
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .nochange
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .nochange
    btst    #JPB_BTN_YEL,d0
    bne     _quit
    
.nochange
    movem.l (a7)+,D0-D1/A1
    ; original code
	TST.L	D0			;dba84: 4a80
	BEQ.W	.skip		;dba86: 67000006
	MOVEA.L	D0,A6			;dba8a: 2c40
	JSR	(A6)			;dba8c: 4e96
.skip:
    rts
 
    ; call original keyboard handler (level 2)
keyhandler
    pea .ret(pc)

	MOVEM.L	D0-D1/A1-A2,-(a7)	;dbed2: 4cdf0603    
    not.b   D0
    rol.b   #1,d0
    move.l  _mainstart(pc),a1
    add.l   #$bea0,a1
    jmp (a1)
.ret
    rts
    
reload_energy
    move.w  #$960,34(a0)    ; set max health
    MOVEQ	#0,D0			;d12dc: 7000
	MOVE.B	9(A0),D0		;d12de: 10280009
    RTS
    
    ; AllocMem/AvailMem emulation. No need to go full kickemu
    ; since the game never frees the memory it allocates,
    ; making implementation of AllocMem & AvailMem (almost)
    ; trivial. Well, I have added fastmem support to OSEmu so
    ; I can assure you that is trivial in comparison!
    
fake_allocmem
    move.l  d2,-(a7)
    move.l  d1,d2
    and.l   #MEMF_CHIP+MEMF_FAST,d2 ; keep only those
    btst    #MEMB_CHIP,d2
    beq.b   .fast
.chip
    lea free_chipmem(pc),a0
    bra.b .alloc
.fast
    lea free_fastmem(pc),a0
.alloc
    ; round size on 4 bytes
    move.l  d0,d1
    and.b   #$FC,d1
    cmp.b   d0,d1
    beq.b   .aligned
    addq.l  #4,d1
    move.l  d1,d0       ; new size rounded on 4 bytes
.aligned
    ; get available memory
    move.l  (4,a0),d1
    sub.l   (a0),d1
    cmp.l   d0,d1
    bcs.b   .not_enough
    ; enough memory available, allocate
    move.l  d0,d1   ; size
    move.l  (a0),d0 ; address
    add.l   d1,(a0) ; update memory start
    move.l  (a7)+,d2
    rts
    
.not_enough
    tst.l   d2
    bne.b   .out
    ; no particular memory required: perform a second pass
    ; with chipmem
    move.l  #MEMF_CHIP,d2
    bra.b   .chip
.out
    moveq.l #0,d0
    move.l  (a7)+,d2
    rts
    
    ; we're ignoring MEMF_LARGEST, assuming free memory is all contiguous
fake_availmem
    btst    #MEMB_CHIP,d1
    beq.b   .fast
    lea free_chipmem(pc),a0
    bra.b .calc
.fast
    lea free_fastmem(pc),a0
.calc
    move.l  (4,a0),d0
    sub.l   (a0),d0
    rts

free_chipmem:
    dc.l    $1000   ; start
    dc.l    CHIPMEMSIZE

    
    ; initialized dynamically at startup
free_fastmem
    dc.l    0   ; start
    dc.l    0   ; top
    

    
blitter_smc_avoid:
    MOVE.W	D2,bltdmod(A5)  ; original
    ; now at return address we have the value to set to bltcon0
    ; we can trash d0 as it is restored right afterwards
    move.l  a0,d0
    move.l  (a7),a0
    move.w  (a0),bltcon0(A5)
    move.l  d0,a0   ; restore a0
    addq.l  #4,(a7) ; skip the rest of the instruction
    rts
    
    
_chkkb_floppysave
		ror.b	#1,d0
		not.b	d0
		cmp.b	(_quitkey,pc),d0
		beq	_quit
        cmp.b   #$58,d0 ; F9 toggle
        bne.b   .nosaveswap
        move.l A0,-(a7)
        lea saveload_from_floppy(pc),a0
        eor.l   #1,(a0)
        tst.l   (a0)
        beq.b   .hd 
        move.w  #$F00,$dff180
        bra.b   .end
.hd
        move.w  #$0F0,$dff180
.end
        move.l  (a7)+,a0
.nosaveswap        
		tst.b	d0
		rts

_chkkb
		ror.b	#1,d0
		not.b	d0
		cmp.b	(_quitkey,pc),d0
		beq	_quit
.nosaveswap        
		tst.b	d0
		rts
        
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a0
		jmp	(resload_Abort,a0)



lbC0002F6	movem.l	(sp)+,d0/a0/a1
	rts

wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
    
_flush	tst.b	($DFF002).l
.wait	tst.b	($BFE001).l
	btst	#6,($DFF002).l
	bne.b	.wait
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	(_resload,pc),a2
	jsr	(resload_FlushCache,a2)
	movem.l	(sp)+,d0-d7/a0-a6
	rts

_patchwait	moveq	#6,d0
.l1	move.w	d0,-(sp)
	move.b	($DFF006).l,d0
.l2	cmp.b	($DFF006).l,d0
	beq.b	.l2
	move.w	(sp)+,d0
	dbra	d0,.l1
	rts

; old slave by Mick used a 24 bit mask to
; "filter" out wrong $FFFF002 address. But that
; prevents using fastmem for the game, and moreover
; the bogus address is ALWAYS $FFFF0002 so let's just
; skip negative addresses...

_patch4	movea.l	(2,a1),a2
	move.l	d0,-(sp)
    bsr sanitize_a2
	move.l	(sp)+,d0
	move.l	(2,a2),d7
	rts

_patch5	movea.l	(2,a0),a2
	move.l	d0,-(sp)
    bsr sanitize_a2
	move.l	(sp)+,d0
	move.l	(2,a2),d7
	rts

_patch2
    move.l	d0,-(sp)
    bsr sanitize_a2
	move.l	(sp)+,d0
	move.w	(6,a2),d0
	move.w	(10,a2),d1
	rts

_patch3	move.l	d0,-(sp)
    bsr sanitize_a4
	move.l	(sp)+,d0
	move.w	(6,a4),d4
	move.w	(10,a4),d5
	rts

sanitize_a2
    move.l  a2,d0
    bpl.b   .okay
    lea     _zeroes(pc),a2
.okay
    rts
    
sanitize_a4
    move.l  a4,d0
    bpl.b   .okay
    lea     _zeroes(pc),a4
.okay
    rts
    
_patchkb	move.b	#$7F,($BFD100).l
	cmpi.w	#5,d0
	beq.b	_key5
	cmpi.w	#7,d0
	beq.b	_key7
	cmpi.w	#8,d0
	beq.w	_key8
	cmpi.w	#6,d0
	beq.w	_key6
	tst.w	d0
	beq.w	_key0
	bra.w	_keyany

_key5	movem.l	a0/a1,-(sp)
	addq.l	#4,a0
	lea	(_adr_key5,pc),a1
	move.l	a0,(a1)
	movem.l	(sp)+,a0/a1
	moveq	#1,d0
	rts

_key7	movem.l	d0-d7/a0-a6,-(sp)
	move.l	(_adr_key8,pc),d2
	cmp.l	d1,d2
	beq.b	.414
	tst.l	(a1)
	beq.b	.402
	cmpi.w	#$4550,(a1)
	bne.b	.end
.402	moveq	#8,d0
	moveq	#0,d1
	movea.l	(_adr_key5,pc),a0
	movea.l	(_resload,pc),a2
	jsr	(resload_LoadFileOffset,a2)
	bra.b	.end

.414	movea.l	(_adr_key5,pc),a0
	move.l	d1,d0
	movea.l	(_mainstart,pc),a3
	adda.l	#$A5B6,a3
	move.l	(a3),d1
	movea.l	(_resload,pc),a2
	jsr	(resload_LoadFileOffset,a2)
	movea.l	(_mainstart,pc),a0
	adda.l	#$A5B6,a0
	clr.l	(a0)
	clr.l	(4,a0)
.end	movem.l	(sp)+,d0-d7/a0-a6
_key6	rts

_key8	cmp.l	(a1),d1
	beq.b	.save
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	(_adr_key5,pc),a0
	movea.l	(_resload,pc),a2
	jsr	(resload_LoadFileOffset,a2)
	movem.l	(sp)+,d0-d7/a0-a6
	rts

.save	move.l	a0,-(sp)
	lea	(_adr_key8,pc),a0
	move.l	(4,a1),(a0)
	movea.l	(sp)+,a0
	rts

_key0	movem.l	d0-d7/a0-a6,-(sp)
	addq.l	#4,a0
	movea.l	(_resload,pc),a2
	jsr	(resload_LoadFile,a2)
	movem.l	(sp)+,d0-d7/a0-a6
	moveq	#0,d0
	rts

_keyany	movem.l	a0/a1,-(sp)
	lea	(_adr_keymain,pc),a0
	movea.l	(_mainstart,pc),a1
	lea	($1B06,a1),a1
	move.l	a1,(a0)
	movem.l	(sp)+,a0/a1
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	d0,d6
	move.l	(_adr_keymain,pc),-(sp)
	rts

_save_cmd0      
    ; respect this register save to be able to use floppy save
	movem.l	d1-d7/a0-a5,-(sp)
    
    move.l  saveload_from_floppy(pc),d7
    cmpi.w	#1,d3
	beq.b	_save_cmd_write
	cmpi.w	#2,d3
	beq.b	_save_cmd_format
    ; load
    btst    #0,d7
    bne   _bypass ; from floppy
    
	movea.l	a0,a1
	lea	(_savedisk,pc),a0
	move.w	d2,d0
	mulu.w	#$200,d0
	mulu.w	#$200,d1
	tst.l	d0
	beq.b	.empty
	movea.l	(_resload,pc),a2
	jsr	(resload_LoadFileOffset,a2)
.empty
    bra _saveload_exit

_save_cmd_write
    tst    d7
    bne.b   _bypass ; from floppy
	movea.l	a0,a1
	lea	(_savedisk,pc),a0
	move.w	d2,d0
	mulu.w	#$200,d0
	mulu.w	#$200,d1
	moveq	#1,d2
	movea.l	(_resload,pc),a2
	jsr	(resload_SaveFileOffset,a2)
	bra _saveload_exit

_save_cmd_format
    tst    d7
    bne.b   _bypass ; from floppy
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d3
.loop	move.l	#$A200,d0
	move.l	d3,d1
	lea	($200).w,a1
	lea	(_savedisk,pc),a0
	moveq	#1,d2
	movea.l	(_resload,pc),a2
	jsr	(resload_SaveFileOffset,a2)
	add.l	#$A200,d3
	cmpi.l	#$6F600,d3
	bne.b	.loop
_saveload_exit
	movem.l	(sp)+,d1-d7/a0-a5
	moveq	#0,d0
	rts

_bypass
    move.l  _mainstart(pc),a5
    LINK.W	A6,#-36
    jmp   ($23AC,a5)    ; original floppy routine
    
_decrunch
	movem.l	d1/a0-a2,-(a7)
	bsr	lbC000706
	cmp.l	#"RNC"<<8,d0
	beq	.copy
	subq.l	#4,a0
	move.l	(_resload,pc),a2
	jsr	(resload_Decrunch,a2)
.end	movem.l	(a7)+,d1/a0-a2
	rts

.ill	illegal

.copy	move.l	a0,d0
	btst	#0,d0
	bne	.ill
	move.l	a1,d0
	btst	#0,d0
	bne	.ill
	bsr	lbC000706
	move.l	d0,d1
	addq.l	#3,d1
	lsr.l	#2,d1
.cl	move.l	(a0)+,(a1)+
	dbf	d1,.cl
	sub.l	#$10000,d1
	bcc	.copy
	bra	.end

lbC000706	moveq	#3,d1
lbC000708	lsl.l	#8,d0
	move.b	(a0)+,d0
	dbra	d1,lbC000708
	rts

saveload_from_floppy	dc.l	0
_resload	dc.l	0
_mainstart	dc.l	0
_adr_keymain	dc.l	0
_adr_key5	dc.l	0
_adr_key8	dc.l	0
_tag		
		dc.l	WHDLTAG_CUSTOM5_GET
allow_floppy_save	dc.l	0
		dc.l	0
		dc.l	0
prev_buttons_state  
		dc.l	0      
_zeroes:
    ds.l    $100,0
	END

