	
; 2016-02-15 ws_config added

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	"wart:br/brianthelion/BrianTheLion_AGA.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_ReqAGA
		dc.l	$200000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0   ; $C0000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
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
    
_name		dc.b	"Brian The Lion AGA",0
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

MAINLOOP_FLAG = 4
MAINPROG_START = $d4
MENUPROG_START = $d8


IGNORE_JOY_DIRECTIONS
    include    ReadJoyPad.s
CHEAT_TEST = $4d723b50
    include     shared.s
    
_Start	
        lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2
        lea     (_tags,pc),a0
        jsr     (resload_Control,a2)

		move.l  #CACRF_EnableI,d0
		move.l  d0,d1
		jsr     (resload_SetCACR,a2)

		move.l	#$154000,$d4		;available memory
        ;; almost works, main sprite should be in chip, though...
		;;move.l	_expmem(pc),MAINPROG_START		;available memory
		move.l	#$64000,MENUPROG_START

		moveq	#$11,d0
		moveq	#6,d1
		lea	$64000+$edc00,a1    ; 151C00
		move.l	a1,a6
		bsr	Loader_Sub

		move.l	a1,-(sp)
		move.l	a1,a0
		move.l	#$11*$200,d0
		jsr     (resload_CRC16,a2)
		move.l	(sp)+,a1
		cmp.w	#$cda5,d0		;original release
		beq	V2
		cmp.w	#$be51,d0		;Computer Combat Pack
		bne	Unsupported

V1		lea	patchlist_v1(pc),a0
_patch
        move.l	a6,a1
		jsr	resload_Patch(a2)

		jmp	(a6)

V2		lea	patchlist_v2(pc),a0
		bra	_patch

patchlist_v1	PL_START
		PL_P	$280,Loader
		PL_W	$12a,$4e73		;disk access
		PL_W	$1a8,$6012
		PL_R	$6ac
		PL_PS	$1e0,InsDisk
		PL_B	$1bc,$60		;diskside test
		PL_PS	$bc,Patch_v1
		PL_END
		
patchlist_v2	PL_START
		PL_P	$26a,Loader
		PL_W	$11a,$4e73		;disk access
		PL_W	$192,$6012
		PL_R	$696
		PL_PS	$1ca,InsDisk
		PL_B	$1a6,$60
		PL_PS	$a6,Patch_v2
        PL_P    $c6,jump_a4000_logo_v2
        PL_P    $E4,jump_a4000_language_select_v2
        PL_PS   $72,jump_64000_menu_v2
        PL_PS   $82,jump_way_forward_v2
		PL_END

Patch_v1	
        bsr	Patch_Main
		move.l	d0,(a2)+		;original instructions
		move.w	d0,(a2)+
		jmp	(a1)

Patch_v2	bsr	Patch_Main
		move.l	MAINPROG_START,a1
		jmp	(a1)

    
pl_a4000_language_select_v2    ; v2
    PL_START
    PL_P    $34,jump_64000_language_select_v2
    PL_END
    
pl_a4000_logo_v2    ; v2
    PL_START
    PL_P    $18,jump_64000_logo_v2
    PL_END

pl_menu_v2:
    PL_START
    PL_PS   $1894,password_test    
    PL_END

jump_way_forward_v2
   MOVEA.L MENUPROG_START,A1
   bsr  _flushcache
   JMP (A1)

    
jump_64000_menu_v2
   MOVEA.L MENUPROG_START,A1
   movem.l  d0-d1/a0-a2,-(a7)
   lea  pl_menu_v2(pc),a0
   move.l   _resload(pc),a2
   jsr  (resload_Patch,a2)
   movem.l  (a7)+,d0-d1/a0-a2
   JMP (A1)

jump_a4000_logo_v2
	ADDA.L	#$00040000,A1		;151ce4: d3fc00040000
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    lea pl_a4000_logo_v2(pc),a0
    jsr resload_Patch(a2)
    movem.l (a7)+,d0-d1/a0-a2
	JMP	(A1)			;151cea: 4ed1

    
jump_a4000_language_select_v2
	ADDA.L	#$00040000,A1		;151ce4: d3fc00040000
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    lea pl_a4000_language_select_v2(pc),a0
    jsr resload_Patch(a2)
    movem.l (a7)+,d0-d1/a0-a2
	JMP	(A1)			;151cea: 4ed1

jump_64000_language_select_v2
    bsr _flushcache
   MOVEA.L MENUPROG_START,A0
   JMP (A0)
   
jump_64000_logo_v2
   bsr  _flushcache
   MOVEA.L MENUPROG_START,A0
   JMP (A0)



Patch_Main	
        ;cmp.l	#$c41a4,$17a528		;data check, probably useless
		;bne	ok

		movem.l	a0-a2,-(sp)

        bsr _detect_controller_types

		move.l	MAINPROG_START,a1
        move.l  a1,d1
        lea addresses(pc),a0
        tst.l   (a0)
        bne.b   .already_corrected
        ; 2 entries + marker
        add.l   d1,(a0)+
        add.l   d1,(a0)+
        add.l   d1,(a0)+
.already_corrected
        
		lea	pl_game(pc),a0
        
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

        movem.l	(sp)+,a0-a2
		rts

pl_game	PL_START
		PL_W	$17a526-$154000,$6004		;skip manual protection
		PL_P	$17a54c-$154000,Decrunch	;Power Packer decruncher
		PL_W	$5a72,$3000		;fix access fault in bonus underwater level
		PL_PS	$180efe-$154000,AccessFault	;fix access fault with boss in Way Forward level
		PL_P	$960,Int64		;improved interrupts
		PL_P	$7edea-$54000,Int68
		PL_P	$8ae,Int6c_20
		PL_PS	$8be,Int6c_10

        PL_PS   $8a2,level3_hook
        ;;PL_PS   $926,read_fire_1
        PL_IFC2
        PL_PS   $8DC,read_joy1dat_d0
        PL_ENDIF
        
        PL_PS   $0fa,main_loop
        
;		PL_W	$18a574+$1c8,9		;developer trick - set 9 lives
;		PL_W	$18a574+$1ca,9		;developer trick - set 9 hits
;		PL_W	$154a06,$6004		;disable game set 3 lives/2 hits
;		PL_W	$154a0c,$6004

        PL_IFC1X    0
		PL_W	$576,$6006		;unlimited lives (except Way Forward Level)
        PL_ENDIF
        PL_IFC1X    1
		PL_W	$4e7a,$4a6d		;unlimited energy
        PL_W    $CF56-$4000,$4a6d   ; unlimited energy - lava
        PL_ENDIF
		PL_END


    
read_fire_1
    move.l  d0,-(a7)
    move.l  prev_buttons_state(pc),d0
    btst    #JPB_BTN_RED,d0
    seq     d1
    move.l  (a7)+,d0
    rts


level3_hook:
    movem.l d0-d3/a0-a1,-(a7)
    lea prev_buttons_state(pc),a0
    lea addresses(pc),a1
    
    move.l  addresses+8(pc),a1  ; keyboard table
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
    movem.l (a7)+,d0-d3/a0-a1
    move.l  addresses+4(pc),-(a7)
    rts

addresses
    dc.l    0   ; marker: if != 0 then already fixed
    dc.l    $17f490-$154000 ; return from level 3 hook
    dc.l    $17edf8-$154000 ; keyboard table
    
AccessFault	lea	$18a736,a6

		move.w	#$4ef9,$6405e
		pea	DecrunchX(pc)
		move.l	(sp)+,$64060
		rts

Int64		movem.l	(sp)+,d0-d7/a0-a6
		move.w	#1,$dff09c
		move.w	#1,$dff09c
		rte

Int68		movem.l	(sp)+,d0/d1/a0/a1
		move.w	#8,$dff09c
		move.w	#8,$dff09c
		rte

Int6c_20	movem.l	(sp)+,d0-d7/a0-a6
		move.w	#$20,$dff09c
		move.w	#$20,$dff09c
		rte

Int6c_10	move.w	#$10,$dff09c
		move.w	#$10,$dff09c
		rts

InsDisk		move.l	a1,-(sp)
		lea	disknum(pc),a1
		move.b	d2,(a1)
		move.l	(sp)+,a1
		rts

Loader		bsr	Loader_Sub
		rte

Loader_Sub	movem.l a0-a2/d0-d3,-(sp)
		move.l	a1,a0
		mulu.w	#$200,d0
		mulu.w	#$200,d1
		exg.l	d0,d1
		lea	disknum(pc),a1
		move.b	(a1),d2
		add.b	#1,d2
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)
		movem.l (sp)+,a0-a2/d0-d3
		rts

    
DecrunchX	bsr	Decrunch	;decrunch Way Forward level and patch

		cmp.l	#$20700000,$6f3aa-$6BD00(a1)	;just a check, probably useless
		bne	donotpatch
        patch   $400,AcFix 	;Way Forward patch
        
       movem.l  d0-d1/a0-a2,-(a7)
       lea  pl_way_forward(pc),a0
       move.l   _resload(pc),a2
       jsr  (resload_Patch,a2)
       movem.l  (a7)+,d0-d1/a0-a2
           

donotpatch	rts


AcFix		movea.l	(a0,d0.w),a0

		move.l	a0,d0
		and.l	#$000FFFFF,d0
		move.l	d0,a0
		rts


pl_way_forward:
    PL_START
    PL_IFC1X    0
    PL_L    $6f3aa-$6BD00,$4eb80400
    PL_W    $6D11A-$6BD00,$4A79 ; energy, enemies
    PL_W    $6CAFA-$6BD00,$4A79 ; energy, scenery
    PL_ENDIF
    PL_IFC1X    1
    PL_W    $6D12A-$6BD00,$4A79 ; lives, enemies
    PL_W    $6CB0A-$6BD00,$4A79 ; lives, scenery
    PL_ENDIF
    PL_END



prev_buttons_state
    dc.l    0
_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0,0
disknum		dc.b	0
    even

cheat:
     dc.b   $4d,$72,$3b,$50,$75,$6d,$70,$6b,$69,$6e,0   ; MrPumpkin...