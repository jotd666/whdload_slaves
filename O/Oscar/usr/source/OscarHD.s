;*---------------------------------------------------------------------------
;  :Program.	oscar.asm
;  :Contents.	Slave for "Oscar"
;  :Author.	wepl <wepl@whdload.de>, jotd
;  :Original.	v1 Desktop Dynamite <wepl@whdload.de>
;		v2
;		v3 CD³²
;		v4 CD³² Diggers Bundle
;  :Version.	$Id: oscar.asm 1.15 2006/05/07 19:41:34 wepl Exp wepl $
;  :History.	20.05.96
;		16.06.97 updated for slave version 2
;		15.08.97 update for key managment
;		15.07.98 cache on 68040+ disabled
;		08.05.99 adapted for WHDLoad 10.0, access faults removed
;		08.12.99 support for v2 added
;		16.01.00 support for v3 added
;		23.02.01 support for v4 added, underwater bug fixed
;		26.03.02 decruncher moved to fastmem
;		18.01.06 version bumped
;		10.11.19 fixed issue with some unbreakable walls (war level)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;  - add option for jump with 2nd button. Not that easy
;    because we have to detect when "up" is used for "jump"
;    it has other uses (swimming up, handling the mojo)
;  - add CD32 joypad controls (pause, quit...)

;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	libraries/lowlevel.i

	IFD BARFLY
    IFD AGA_VERSION
	OUTPUT	"wart:o/oscar/OscarAGA.Slave"
    ELSE
	OUTPUT	"wart:o/oscar/OscarECS.Slave"
    
    ENDC
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER					;disable supervisor warnings
	ENDC

	STRUCTURE	globals,$100
		LONG	_chipptr
		LONG	_clist
		LONG	_joystate
		BYTE	_decinit

;CHIP_ONLY

    IFD AGA_VERSION
CHIPMEMSIZE = $181000
FASTMEMSIZE = $1000
    ELSE
    IFD CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = $1000
    ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
    ENDC
    ENDC
    
;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	19			;ws_Version
    IFD AGA_VERSION
		dc.w	WHDLF_NoError|WHDLF_ClearMem|WHDLF_ReqAGA		;ws_flags
    ELSE
		dc.w	WHDLF_NoError|WHDLF_ClearMem		;ws_flags
    ENDC
_upchip		dc.l	CHIPMEMSIZE			;ws_BaseMemSize 
						;floppy vers need only $177000
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	FASTMEMSIZE			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config
;		dc.b	"BW;"
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C1:X:Trainer Infinite Energy:1;"
        dc.b    "C1:X:Instant enemy kill:2;"
        dc.b    "C1:X:Clapperboard at 1st oscar pick:3;"
        dc.b    "C2:B:second button jumps;"
		dc.b	0
                
;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC
	

DECL_VERSION:MACRO
	dc.b	"2.3"
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

_data		dc.b	"data",0
_name		dc.b	"Oscar "
    IFD AGA_VERSION
    dc.b    "(AGA/CD32)"
    ELSE
    dc.b    "(ECS)"
    IFD CHIP_ONLY
    dc.b    " (DEBUG MODE)"
    ENDC
    ENDIF
    
        dc.b    0
_copy		dc.b	"1993 Flair Software",0
_info		dc.b	"adapted by Wepl & JOTD",10
		dc.b	"version "
		DECL_VERSION
		dc.b	0
	EVEN


; adding this as vasm cannot auto relpc resload, so I forced it in my copy
; of the generic "keyboard.s". Since it's shared, and here _resload isn't pcrelative
; have to redefine the quit/debug functions. Fortunately keyboard.s allows that

_debug		pea	TDREASON_DEBUG.w
_quit		move.l	(_resload,pc),-(a7)		;no ',pc' because used absolut
		addq.l	#resload_Abort,(a7)
		rts
_exit		pea	TDREASON_OK.w
		bra	_quit
        
        IFD AGA_VERSION
		INCLUDE	whdload/keyboard.s
        ENDC
		INCLUDE ReadJoyPad.s
        
      
;============================================================================
_Start		;	A0 = resident loader
;============================================================================
	;save resload base
		lea		(_resload,pc),a1
		move.l	a0,(a1)			;save
		move.l	a0,a5				;A5 = resload
		sf	(_decinit)			;decruncher not init

    IFD AGA_VERSION
	;set start address for emulated exec.AllocMem
		move.l	#$400,(_chipptr)
		move.l	(_chipptr),a1			;address
    ELSE
    IFD CHIP_ONLY
        lea $80000,a1
        lea  _expmem(pc),a0
        move.l  a1,(a0)
    ELSE
        move.l  _expmem(pc),a1
    ENDC
    ENDC
	;load main
		lea	(_exe,pc),a0			;name
		move.l	a1,a4				;A4 = expmem
		jsr	(resload_LoadFileDecrunch,a5)
	;relocate main
		move.l	a4,a0				;address
		sub.l	a1,a1				;taglist
		jsr	(resload_Relocate,a5)
		add.l	d0,(_chipptr)
        IFD AGA_VERSION
	;set stackpointers (AGA)
		move.l	(_expmem,pc),a7
		add.w	#$ff0,a7
		lea	(-$400,a7),a0
		move	a0,usp
	;check version & apply patches
        lea (flag_addresses_v1,pc),a1
		lea	(_pexe1,pc),a0			;patchlist
		cmp.l	#$2f2d4,d0
		beq	.patch
        lea (flag_addresses_v2,pc),a1
		lea	(_pexe2,pc),a0			;patchlist
		cmp.l	#$2cf58,d0
		beq	.patch
        lea (flag_addresses_v3,pc),a1
		lea	(_pexe3,pc),a0			;patchlist
		cmp.l	#$a80d8,d0
		beq	.patch
        lea (flag_addresses_v4,pc),a1
		lea	(_pexe4,pc),a0			;patchlist
		cmp.l	#$300a0,d0
		beq	.patch
        ELSE
        lea (flag_addresses_v5,pc),a1
        move.l  a4,d1
        add.l   d1,(a1)     ; add expbase
        add.l   d1,(4,a1)     ; add expbase
		lea	(_pexe5,pc),a0			;patchlist
        cmp.l	#$30E88,d0
		bne	.wrongver
        ; ECS version is completely different, doesn't use OS at all
        lea flag_addresses(pc),a3
        move.l  a1,(a3)
        move.l	a4,a1				;address
        jsr	(resload_Patch,a5)
        ; skip relocation phase
        jmp ($76,a4)
.wrongver
        ENDC
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a5)
		
.patch
    lea flag_addresses(pc),a3
    move.l  a1,(a3)
    move.l	a4,a1				;address
	jsr	(resload_Patch,a5)

    IFD AGA_VERSION
	;init ints
		lea	(_vbi,pc),a0
		move.l	a0,($6c)
		bsr	_SetupKeyboard			;required for cd versions
    ENDC
    
	;init dma
		lea	(_clist),a0
		move.l	#-2,(a0)
		move.l	a0,(_custom+cop1lc)

	;start main
		bsr	_detect_controller_types

		move	#0,sr
		jmp	($3e,a4)

; on Whdload CD, version 1 and 2 are swapped

_pexe1		PL_START
		PL_P	$8b4e,_allocmem			;emulate
		PL_S	$276,$2a8-$276			;disable os-stuff
		PL_P	$7b1a,_loader
		PL_PS	$8dfc,_decrunch
		PL_W	$1ce2,$e841			;lsr.w  -> asr.w
		PL_W	$1ce4,$c3fc			;mulu   -> muls
		PL_PS	$1cfc,fix_af_add_d1_1		;adda.l -> unsigned adda.w
		PL_W	$1e0e,$e841			;lsr.w  -> asr.w
		PL_W	$1e10,$c3fc			;mulu   -> muls
		PL_PS	$1e28,fix_af_add_d1_2			;adda.l -> unsigned adda.w
		PL_S	$9764,$99fc-$9764		;copylock
		PL_PS	$23fa2,_dbf1
		PL_PS	$23fb8,_dbf1
		PL_PS	$246e2,_dbf1
		PL_PS	$246f8,_dbf1
		PL_PS	$2558a,_dbf0
		PL_PS	$255ee,_dbf1

        
		PL_IFC1X 0
		PL_S	$290E,$20-$E
		PL_S	$2dc6,$2dee-$2dc6
		PL_ENDIF
		PL_IFC1X	1
        PL_W $01a92,$4A79
        PL_W $05a66,$4A79
        PL_W $06738,$4A79
        PL_W $067d4,$4A79		
		PL_ENDIF
		; JOTD second button jumps
		PL_IFC2
		PL_PS	$B664,control_joypad
		PL_ELSE
		PL_PS	$B664,control_joystick
		PL_ENDIF
;		PL_IFC3
;		PL_R	$CF02
;		PL_ENDIF
        PL_IFC1X    2
        ; instant enemy kills instead of 3 times
        PL_W    $67f4,$426D ; jumping
        PL_W    $6a4e,$426D ; toy
        PL_ENDIF
        PL_IFC1X    3
        PL_W  $12c32,$4279    ; first oscar picked: find the clapperboard!
        PL_ENDIF
		

		PL_END
        

    
_pexe2		PL_START
		PL_P	$8b56,_allocmem			;emulate
		PL_S	$276,$2a8-$276			;disable os-stuff
		PL_P	$7b22,_loader
		PL_PS	$8e04,_decrunch
		PL_W	$1cbc,$e841			;lsr.w  -> asr.w
		PL_W	$1cbe,$c3fc			;mulu   -> muls
		PL_PS	$1cd6,fix_af_add_d1_1		;adda.l -> unsigned adda.w
		PL_W	$1de8,$e841			;lsr.w  -> asr.w
		PL_W	$1dea,$c3fc			;mulu   -> muls
		PL_PS	$1e02,fix_af_add_d1_2			;adda.l -> unsigned adda.w
		PL_S	$976c,$9a04-$976c		;copylock
		PL_PS	$21c26,_dbf1
		PL_PS	$21c3c,_dbf1
		PL_PS	$22366,_dbf1
		PL_PS	$2237c,_dbf1
		PL_PS	$2320e,_dbf0
		PL_PS	$23272,_dbf1
		
		PL_IFC1X 0
		PL_S	$2916,$28-$16
		PL_S	$2dce,$2df6-$2dce
		PL_ENDIF
		PL_IFC1X	1
        PL_W $01a6c,$4A79
        PL_W $05a6e,$4A79
        PL_W $06740,$4A79
        PL_W $067dc,$4A79		
		PL_ENDIF
        PL_IFC1X    2
        ; instant enemy kills instead of 3 times
        PL_W    $67fc,$426D ; jumping
        PL_W    $6A56,$426D ; toy
        PL_ENDIF
		; JOTD second button jumps
		PL_IFC2
		PL_PS	$b66c,control_joypad
        PL_ELSE
        PL_PS   $B66c,control_joystick
		PL_ENDIF
        PL_IFC1X    3
        PL_W  $10880,$4279    ; first oscar picked: find the clapperboard!
        PL_ENDIF
		PL_END


; CD32
_pexe3		PL_START
		PL_P	$76fc,_allocmem			;emulate
		PL_S	$200,$254-$200			;disable os-stuff
	;	PL_W	$b48e,$4e73			;jmp to org vbi -> rte
		PL_S	$750e,$86-$e			;skip os-restore
		PL_S	$75a8,10			;skip open
		PL_PS	$75de,_loadercd
		PL_S	$7630,14+$14			;skip os-save
		PL_PS	$330,_enabledma
		PL_W	$199c,$e841			;lsr.w  -> asr.w
		PL_W	$199e,$c3fc			;mulu   -> muls
		PL_PS	$19b0,fix_af_add_d1_1		;adda.l -> unsigned adda.w
		PL_W	$1ac2,$e841			;lsr.w  -> asr.w
		PL_W	$1ac4,$c3fc			;mulu   -> muls
		PL_PS	$1ad6,fix_af_add_d1_2			;adda.l -> unsigned adda.w
		PL_PS	$2d8fc,_dbf1
		PL_PS	$2d912,_dbf1
		PL_PS	$2e03c,_dbf1
		PL_PS	$2e052,_dbf1
		PL_PS	$2eed2,_dbf0
		PL_PS	$2ef36,_dbf1

		PL_IFC1X 0
		PL_S	$258e,$25a0-$258e
		PL_S	$02a16,$2a3e-$2a16
		PL_ENDIF
		PL_IFC1X	1
        PL_W $01752,$4A79
        PL_W $05658,$4A79
        PL_W $0628e,$4A79
        PL_W $0632a,$4A79		
        PL_W $09d2c,$4A79		
		PL_ENDIF	
        PL_IFC1X    2
        ; instant enemy kills instead of 3 times
        PL_W    $634a,$426D ; jumping
        PL_W    $659e,$426D ; toy
        PL_ENDIF
		PL_IFC2
		PL_PS	$b09a,control_joypad
        PL_ELSE
        PL_PS   $b09a,control_joystick
		PL_ENDIF

        PL_IFC1X    3
        PL_W  $1CA10,$4279    ; first oscar picked: find the clapperboard!
        PL_ENDIF
		PL_END
		
; CD32 (oscar+diggers bundle)
_pexe4		PL_START
		PL_S	$3e,$b4-$3e			;skip os
		PL_PS	$b4,_getlang
		PL_P	$89ec,_allocmem			;emulate
		PL_S	$2e0,$326-$2e0			;disable os-stuff
		PL_S	$797a,$cc-$7a			;skip os-restore
		PL_S	$79ee,10			;skip open
		PL_PS	$7a24,_loadercd
		PL_S	$7a54,$68-$54			;skip os-save
		PL_W	$1ccc,$e841			;lsr.w  -> asr.w
		PL_W	$1cce,$c3fc			;mulu   -> muls
		PL_PS	$1ce6,fix_af_add_d1_1			;adda.l -> unsigned adda.w
		PL_W	$1df8,$e841			;lsr.w  -> asr.w
		PL_W	$1dfa,$c3fc			;mulu   -> muls
		PL_PS	$1e12,fix_af_add_d1_2			;adda.l -> unsigned adda.w
		PL_R	$b5c0				;cd.device
		PL_R	$b614				;cd.device
        PL_IFC2
		PL_PS	$afe2,_readpad_v4			;lowlevel.ReadJoyPort
        PL_ELSE
		PL_PS	$afe2,_readjoy_v4			;lowlevel.ReadJoyPort
        PL_ENDIF
        ; those are just used for pause/unpause
		PL_PS	$b01e,_readjoy_v4			;lowlevel.ReadJoyPort
		PL_PS	$b03a,_readjoy_v4			;lowlevel.ReadJoyPort
		PL_PS	$b060,_readjoy_v4			;lowlevel.ReadJoyPort
		PL_PS	$b088,_readjoy_v4			;lowlevel.ReadJoyPort
		PL_PS	$22e0c,_dbf1
		PL_PS	$22e22,_dbf1
		PL_PS	$2354c,_dbf1
		PL_PS	$23562,_dbf1
		PL_PS	$243f4,_dbf0
		PL_PS	$24458,_dbf1
		PL_IFC1X 0
		PL_S	$02876,$02888-$02876
		PL_S	$02d54,$02d7c-$02d54
		PL_ENDIF
		PL_IFC1X	1
        PL_W $01a5e,$4A79
        PL_W $05a24,$4A79
        PL_W $066f6,$4A79
        PL_W $06792,$4A79		
        PL_W $09bd0,$4A79		
		PL_ENDIF	
        PL_IFC1X    2
        ; instant enemy kills instead of 3 times
        PL_W    $067b2,$426D ; jumping
        PL_W    $06a0c,$426D ; toy
        PL_ENDIF
        PL_IFC1X    3
        PL_W  $10662,$4279    ; first oscar picked: find the clapperboard!
        PL_ENDIF
		PL_END

; ECS version
_pexe5		PL_START
    PL_P    $7C92,read_file
 ;;   PL_NOP  $9E56,2     ; password protection, completely skipped below
    
		PL_W	$01d3e,$e841			;lsr.w  -> asr.w
		PL_W	$01d40,$c3fc			;mulu   -> muls
		PL_PS	$01d58,fix_af_add_d1_1		;adda.l -> unsigned adda.w
		PL_W	$01e6a,$e841			;lsr.w  -> asr.w
		PL_W	$01e6c,$c3fc			;mulu   -> muls
		PL_PS	$01e84,fix_af_add_d1_2			;adda.l -> unsigned adda.w
		PL_S	$09bf8,$09e5c-$09bf8		;skip password protection
		PL_PS	$22634,_dbf1
		PL_PS	$2264a,_dbf1
		PL_PS	$22d74,_dbf1
		PL_PS	$22d8a,_dbf1
		PL_PS	$2a278,_dbf0
		PL_PS	$2a2dc,_dbf1
		
        PL_PS   $C1AA,keyboard_interrupt_ecs    ; quit on 68000
        ; pause with joypad
        PL_PSS  $24ea,pause_test_ecs,4
        PL_PSS  $2504,pre_unpause_release,2
        PL_PSS  $251C,unpause,2
        PL_PS   $2532,wait_play_released_ecs
        
		PL_IFC1X 0
		PL_S	$029ac,$20-$E
		PL_S	$02e9a,$02ec2-$02e9a
		PL_ENDIF
		PL_IFC1X	1
        PL_W $01aee,$4A79
        PL_W $05b66,$4A79
        PL_W $067be,$4A79
        PL_W $0685a,$4A79		
		PL_ENDIF
		; JOTD second button jumps
		PL_IFC2
		PL_PS	$0c080,control_joypad
		PL_ELSE
		PL_PS	$0c080,control_joystick
		PL_ENDIF

        PL_IFC1X    2
        ; instant enemy kills instead of 3 times
        PL_W    $0687a,$426D ; jumping
        PL_W    $06ad4,$426D ; toy
        PL_ENDIF
        PL_IFC1X    3
        PL_W  $11284,$4279    ; first oscar picked: find the clapperboard!
        PL_ENDIF
        
        PL_END
; parts added by JOTD

; pause test is always not trivial to code because you have to
; take 2 conditions into consideration: keyboard and joypad
; with handling of "released" state else game pauses right after
; being unpaused. This usually causes a lot of headaches with the
; AND and OR, and inverted conditions.

pause_test_ecs
    movem.l a0,-(a7)
    move.l  _expmem(pc),a0
    add.l   #$30552,a0
    move.b  (a0),d0
    cmp.b   #$cd,d0
    movem.l (a7)+,a0
    beq.b   .p_pressed
    ; check if joypad PLAY is pressed
    movem.l d0,-(a7)
    move.l  _joystate,d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .pause_pressed
    moveq.l #1,d0   ; clear Z
    movem.l (a7)+,d0
.p_pressed   
    rts
.pause_pressed
    cmp.b   d0,d0; set Z
    movem.l (a7)+,d0
    rts

pre_unpause_release:
	ANDI.W	#$007f,D0		;02504: 0240007f
	CMP.B	#$4d,D0			;02508: b03c004d
    beq.b   .p_still_pressed
    bsr test_pause_joy
.p_still_pressed
    rts
unpause:
    bsr test_pause_joy
    beq.b   .pause_pressed
	ANDI.W	#$007f,D0		;0251c: 0240007f
	CMP.B	#$7f,D0			;02508: b03c004d
    rts
.pause_pressed
    ; flip Z
    EORI    #4,CCR
    rts
    
test_pause_joy
    movem.l d0/a0,-(a7)
    bsr wait_vbl
	moveq.l	#1,d0
	bsr	_read_joystick		; returns state in D0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .pause_pressed
    moveq.l #1,d0   ; clear Z
.out
    movem.l (a7)+,d0/a0
    rts
.pause_pressed
    cmp.b   d0,d0; set Z
    bra.b   .out

wait_play_released_ecs:
    movem.l d0/a0,-(a7)
.w
    ; wait until play is released
    bsr wait_vbl
	moveq.l	#1,d0
	bsr	_read_joystick		; returns state in D0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .w
    ; original code
    move.l  _expmem(pc),a0
    add.l   #$2ff66,a0
    clr.w   (a0)
    movem.l (a7)+,d0/a0
    rts
    
wait_vbl:
	; wait for VBL
	lea	$DFF000,a0
	move.w	#$7FFF,intreq(a0)
.wait
	move.w	intreqr(a0),d0
	btst	#5,d0
	beq.b	.wait
	rts
    
keyboard_interrupt_ecs
    MOVE.B $00bfec01,D0
    movem.l d0,-(a7)
    ror.b   #1,d0
    not.b   d0
    cmp.b   _keyexit(pc),d0
    beq   _exit
    movem.l (a7)+,d0
    rts

    
read_file
    movem.l a0-a2,-(a7)
    move.l  (_resload,pc),a2
    addq.l  #4,a0
    jsr (resload_LoadFileDecrunch,a2)
    move.l  d0,d1   ; length
    moveq.l #0,d0   ; no error
    movem.l (a7)+,a0-a2
    rts
; fix access faults properly
; (changing ADD.L to ADD.W only works if D1<0x7FFF else sign breaks
; the game logic and it's not possible for instance to break the wall underwater)

fix_af_add_d1_1:
	and.l	#$FFFF,d1
	ADDA.L	D1,A0			;01ce6: d1c1
	MOVE.W	(1024,A0),D0		;01ce8: 30280400
	rts
	
fix_af_add_d1_2:
	and.l	#$FFFF,d1
	ADDA.L	D1,A0			;01e12: d1c1
	MOVEQ	#0,D0			;01e14: 7000
	MOVE.B	(A0),D0			;01e16: 1010
	rts

read_joy:
	movem.l	d0,-(a7)
	moveq.l	#1,d0
	bsr	_read_joystick		; returns state in D0
	move.l	d0,_joystate
	movem.l	(a7)+,d0
	rts
	
control_joystick
	bsr	read_joy
	move.w	_custom+joy1dat,d0
    rts
    
; joypad
control_joypad
	movem.l	d1/a0-a1,-(a7)    
	bsr	read_joy
	move.l	_joystate,d1
	move.w	_custom+joy1dat,d0
    ; if we're firing the toy, ignore second button
    btst    #JPB_BTN_RED,d1
    bne.b   .no_blue
    ; if we're on dry ground, ignore "up"
    ; in any situation, second button is active
    ; (this is for the special case where the character is in water
    ; up to the waist so jumping and going up is the same)
    move.l  flag_addresses(pc),a0
    move.l  (a0)+,a1
	TST.W	(a1)
	BNE.S	.noneed		;03aa2: 6608
    move.l  (a0)+,a1
	TST.W	(a1)
	BEQ.S	.jump		;03aaa: 6734
    ; water
    bra.b   .noneed
.jump    
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed
	bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=0
.no_blue
	movem.l	(a7)+,d1/a0-a1
	rts


flag_addresses:
    dc.l    0
flag_addresses_v1:
    dc.l    $2e12a+$400,$2e150+$400
flag_addresses_v2:
    dc.l    $2bdae+$400,$2bdd4+$400
flag_addresses_v3:
    dc.l    $9ac0c+$400,$9ac2e+$400
flag_addresses_v4:
    dc.l    $2cf94+$400,$2cfba+$400
flag_addresses_v5:
    dc.l    $2fea8,$2fece
    
 
;--------------------------------

_getlang	clr.l	-(a7)
		clr.l	-(a7)
		pea	WHDLTAG_LANG_GET
		move.l	a7,a0
		move.l	(_resload,pc),a1
		jsr	(resload_Control,a1)
		addq.l	#4,a7
		move.l	(a7)+,d0
		addq.l	#4,a7
		rts

;--------------------------------

; smaller delay for sound off just before sound on
_dbf0		movem.l	d0-d1,-(a7)
		moveq	#1,d1
.1		move.b	($dff006),d0
.2		cmp.b	($dff006),d0
		beq	.2
		dbf	d1,.1
		movem.l	(a7)+,d0-d1
		addq.l	#2,(a7)
		rts
; was 9 loops, 7 loops are okay for most sounds        
_dbf1	movem.l	d0-d1,-(a7)
		moveq	#6,d1
.1		move.b	($dff006),d0
.2		cmp.b	($dff006),d0
		beq	.2
		dbf	d1,.1
		movem.l	(a7)+,d0-d1
		addq.l	#2,(a7)
		rts

;--------------------------------

_vbi		move.w	#INTF_VERTB,(_custom+intreq)
		rte

;--------------------------------

_allocmem	addq.l	#7,d0				;round up
		and.b	#$f8,d0

		move.l	(_chipptr),a1
		add.l	d0,(_chipptr)
	IFEQ 1
		move.l	(_chipptr),d1
		cmp.l	(_upchip,pc),d1
		blo	.0
		illegal
.0
	ENDC
		move.l	a1,a0
		lsr.l	#3,d0
.clr		clr.l	(a0)+
		clr.l	(a0)+
		subq.l	#1,d0
		bne	.clr
		move.l	a1,d0
		rts

;--------------------------------

_loader		addq.l	#4,a0				;skip "df0:"
		move.l	a2,-(a7)
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFileDecrunch,a2)
		move.l	(a7)+,a2
		moveq	#0,d0				;return code
		rts

_decrunch	bset	#0,(_decinit)
		bne	.initok
		movem.l	d0/a0-a1,-(a7)
		move.l	(12,a7),a0
		move.l	(_expmem,pc),a1
		move.w	#($9266-$8e02)/4-1,d0
.cp		move.l	(a0)+,(a1)+
		dbf	d0,.cp
		move.l	(_resload,pc),a0
		jsr	(resload_FlushCache,a0)
		movem.l	(a7)+,d0/a0-a1

.initok		addq.l	#4,a7
		cmp.l	#"TSM!",(a0)
		bne	.rts

		movem.l	d0-d7/a0-a6,-(a7)
		addq.l	#4,a0
		move.l	(_expmem,pc),-(a7)
.rts		rts

_loadercd	addq.l	#6,a0				;skip "Oscar:"
		move.l	d2,a1
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFileDecrunch,a2)
		add.l	#14,(a7)
		rts

;--------------------------------

_enabledma	move.w	#$c028,(intena,a6)
		waitvb	a6
		move.w	#$86e0!DMAF_RASTER,(dmacon,a6)
		rts

;--------------------------------
_readjoy_v4
	moveq.l	#1,d0
	bra	_read_joystick		; returns state in D0

_readpad_v4
    movem.l	d1/a0-a1,-(a7)
	moveq.l	#1,d0
	bsr	_read_joystick		; returns state in D0
    ; if we're on dry ground, ignore "up"
    ; in any situation, second button is active
    ; (this is for the special case where the character is in water
    ; up to the waist so jumping and going up is the same)
    move.l  flag_addresses(pc),a0
    move.l  (a0)+,a1
	TST.W	(a1)
	BNE.S	.noneed		;03aa2: 6608
    move.l  (a0)+,a1
	TST.W	(a1)
	BEQ.S	.jump		;03aaa: 6734
    ; water
    bra.b   .noneed
    
.jump    
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
    bclr    #JPB_BTN_UP,d0
.noneed
	bclr	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
    bset    #JPB_BTN_UP,d0
.no_blue
    move.b  $BFEC01,d1
    not.b   d1
    ror.b   #1,d1
    cmp.b   #$19,d1
    bne.b   .nopause
    bset    #JPB_BTN_PLAY,d0    ; P: pause
.nopause
    ; avoid to jump using those buttons. There's already BLUE
	bclr	#JPB_BTN_REVERSE,d0
	bclr	#JPB_BTN_FORWARD,d0

	movem.l	(a7)+,d1/a0-a1
	rts

;--------------------------------

_exe		dc.b	"exe",0
_resload:
	dc.l	0



;============================================================================

	END
