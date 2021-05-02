;
; 2016-02-14 fixed for 68000, $40... must be cleared
;	     ws_config added
; 2016-02-15 quitkey for 68000 added (title/main)
;	     caches enabled

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	"wart:br/brianthelion/BrianTheLion_OCS.Slave"
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
EXPMEMSIZE = 0
    ELSE
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000
    ENDC
    
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEMSIZE			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

MAINLOOP_FLAG = 4

    
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
_name		dc.b	"Brian The Lion"
            IFD CHIP_ONLY
            dc.b    " (DEBUG/CHIP mode)"
            ENDC
            dc.b    0
_copy		dc.b	"1994 Psygnosis",0
_info		dc.b	"adapted by Bored Seal, Wepl & JOTD",10
		DECL_VERSION
        dc.b    0
_config		
        dc.b	"C1:X:trainer unlimited lives:0;"
        dc.b	"C1:X:trainer unlimited energy:1;"
        dc.b	"C2:B:second button jumps;"
        dc.b    0
		even
IGNORE_JOY_DIRECTIONS
    include    ReadJoyPad.s
CHEAT_TEST = $4d72733b    
    include     shared.s
_Start		
        lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2
        lea     (_tags,pc),a0
        jsr     (resload_Control,a2)

        IFD CHIP_ONLY
        lea _expmem(pc),a0
        move.l  #$80000,(a0)
        ENDC
        
		move.l  #CACRF_EnableI,d0
		move.l  d0,d1
		jsr     (resload_SetCACR,a2)

		lea	$40,a0
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		move.l	_expmem(pc),$d4		; expansion memory
		move.l	#$800,$d8

		moveq	#$10,d0
		moveq	#6,d1
        move.l  _expmem(pc),a1
		add.l   #$7d600,a1
		bsr	Loader_Sub

		move.l	a1,-(sp)
		move.l	a1,a0
		move.l	#$10*$200,d0
		jsr     (resload_CRC16,a2)
		cmp.w	#$1379,d0		;Computer Combat Pack
		bne	Unsupported
		move.l	(sp),a1


        lea pl_boot(pc),a0
        jsr (resload_Patch,a2)
		move.l	(sp)+,a1
        
		jmp	(a1)

pl_boot
    PL_START
    PL_P    $256,Loader
    PL_W    $100,$4E73
    PL_R    $682
    PL_W    $17E,$6012
    PL_PS   $1B6,InsDisk
    PL_B    $192,$60
    PL_PS   $C6A,SnoopFix
    PL_PS   $7e,PatchTitle
    PL_PS   $c4,PatchGame    
    PL_END
    
; the title

PatchTitle	
        movem.l d0-d1/a0-a2,-(a7)
        move.l  _resload(pc),a2
        lea pl_title(pc),a0
        jsr (resload_Patch,a2)
        movem.l (a7)+,d0-d1/a0-a2
		jsr	(a1)
		moveq	#2,d0
		moveq	#0,d1
		rts

pl_title
    PL_START
    PL_PS   $02014-$800,password_test
    PL_PS   $fc82,_keyb1
    PL_END
    
; the main game

PatchGame	
		movem.l	d0-d1/a0-a2,-(sp)

        bsr _detect_controller_types

        move.l  _expmem(pc),a1
        move.l  a1,a2
        add.l   #$26220,a2
        
        cmp.l	#$2116e,(a2)
		bne.b   .skip

        lea  addresses(pc),a0  ; keyboard table
        tst.l   (a0)
        bne.b   .ok
        move.l  a1,d0
        add.l   d0,(a0)+
        add.l   d0,(a0)+
        add.l   d0,(a0)+
.ok
		move.l	(_resload,pc),a2
        lea pl_main(pc),a0
        jsr (resload_Patch,a2)

.skip	
	
        movem.l	(sp)+,d0-d1/a0-a2
        move.l	d1,(a2)+		;original instructions
		move.w	d1,(a2)+
		jmp	(a1)

_keyb1		move.b	$bfec01,d0
		move.b	d0,d1
		not.b	d1
		ror.b	#1,d1
		cmp.b	_keyexit(pc),d1
		beq	_quit
		rts


InsDisk		move.l	a1,-(sp)
		lea	disknum(pc),a1
		move.b	d2,(a1)
		move.l	(sp)+,a1
		rts

pl_main
    PL_START
	PL_PS   $29fb6,_keyb1

	PL_W    $2621e,$6004		;remove manual check
    PL_W    $5258,$3000		;fix access fault in underwater level
    PL_P    $26966,Decrunch
    PL_PS   $2c346,AccessFault  ;fix AF at boss in Way Forward level

    PL_PS   $8FA,level3_hook
    
    PL_IFC1X    1
    PL_W	$4664,$4a6d		;unlimited energy
    PL_W	$86fc,$4a6d		;unlimited energy, lava
    PL_ENDIF
    PL_IFC1X    0
    PL_W	$056c,$6006		;unlimited lives
    PL_ENDIF

    PL_PS   $0f6,main_loop

    PL_IFC2
    PL_PS   $6cd2,read_joy1dat_d0
    PL_ENDIF

;		move.w	#$6004,$80a2e		;developer hack to set 9 lives/hits at the start
;		move.w	#$6004,$80a34
;		move.w	#$6004,$80f1e
;		move.w	#9,$b1a78+$1c0
;		move.w	#9,$b1a78+$1c2    

    PL_END

    
level3_hook:
    movem.l d0-d3/a0-a1,-(a7)
    lea prev_buttons_state(pc),a0
    
    move.l  addresses+4(pc),a1  ; keyboard table
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_read_joystick
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; xor to d2 to get what has changed quickly
    move.l  d0,d2
    eor.l   d1,d2
    beq.b   .nochange   ; cheap-o test just in case no input has changed
    clr.w   d3
    ; d2 bears changed bits (buttons pressed/released)
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .no_esc
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .no_quit
    btst    #JPB_BTN_YEL,d0
    bne   _quit
.no_quit
    TEST_BUTTON FORWARD,$45
.no_esc
    TEST_BUTTON PLAY,$19     ; pause
.nochange    
   
    ; original
    move.l  addresses+8(pc),a0
	TST.W	(a0)
    movem.l (a7)+,d0-d3/a0-a1
    rts
addresses
    dc.l    0       ; marker
    dc.l    $2a1e4 ; keyboard table
    dc.l    $31bf2 ; address to test

SnoopFix	move.w	$1e(a6),d0
		and.w	#$20,d0
		beq	SnoopFix
		rts

Loader		bsr	Loader_Sub
		rte

Loader_Sub	movem.l a0-a2/d0-d3,-(sp)
		move.l	a1,a0
		mulu.w	#$200,d0
		mulu.w	#$200,d1
		exg.l	d0,d1
		moveq	#1,d2
		add.b	disknum(pc),d2
	;	bset	#31,d2			;dump files
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)
		movem.l (sp)+,a0-a2/d0-d3
		rts



AccessFault
        move.l  _expmem(pc),a6
        add.l   #$31c32,a6
        
		patch	$85e,DecrunchX
        bsr _flushcache

		rts

DecrunchX	bsr	Decrunch	;decrunch Way Forward level and patch

		cmp.l	#$20700000,$bbaa	;just a check, probably useless
		bne	donotpatch
       movem.l  d0-d1/a0-a2,-(a7)
       lea  pl_way_forward(pc),a0
       move.l   _resload(pc),a2
       jsr  (resload_Patch,a2)
       movem.l  (a7)+,d0-d1/a0-a2

        patch   $400,AcFix 	;Way Forward patch


donotpatch	rts

AcFix		movea.l	(a0,d0.w),a0

		move.l	a0,d0
		and.l	#$000FFFFF,d0
		move.l	d0,a0
		rts
wf_key
    MOVE.B	$bfec01,D0		;0d87e: 103900
    not.b   d0
    ror.b   #1,d0
    cmp.b   _keyexit(pc),d0
    beq _quit
    rts
    
pl_way_forward:
    PL_START
    PL_PSS   $D87E-$8500,wf_key,4
    PL_L    $BBAA-$8500,$4eb80400
    PL_IFC1X    0
    PL_L    $6f3aa-$8500,$4eb80400
    PL_W    $991a-$8500,$4A79 ; energy, enemies
    PL_W    $092fa-$8500,$4A79 ; energy, scenery
    PL_ENDIF
    PL_IFC1X    1
    PL_W    $0992a-$8500,$4A79 ; lives, enemies
    PL_W    $0930a-$8500,$4A79 ; lives, scenery
    PL_ENDIF
    PL_END

prev_buttons_state
    dc.l    0
_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0,0
disknum		dc.b	0
cheat:
     dc.b   $4d,$72,$73,$3b,$54,$75,$72,$6e,$69,$70,0
     