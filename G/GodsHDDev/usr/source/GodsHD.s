;*---------------------------------------------------------------------------
;  :Program.	gods.asm
;  :Contents.	Slave for "Gods"
;  :Author.	Wepl,JOTD
;  :Original.	v1 Bert Jahn <wepl@whdload.de>
;		v3 Edwin McLouth <an818@tcnet.org>
;  :Version.	$Id: Gods.asm 1.8 2004/01/16 08:49:59 wepl Exp wepl $
;  :History.	20.05.96
;		01.05.97 evaluated to ver 3
;			 support for second format
;			 highscores improved (now loading from disk if no file
;			 is available)
;		02.05.97 trainer added
;		04.06.97 soundtracker playback fixed
;			 Kick 3.1 bug fixed
;			 drive check disabled
;		05.06.97 better copylock fix
;		15.08.97 update for key management
;		14.07.98 byte write to aud1vol in intro fixed
;		15.07.98 cache problem on 68060 fixed
;		15.08.03 major rework
;       08.11.03 JOTD fixed SMC
;            enabled cache again
;            now game works with full optimizations on 68060 & WinUAE
;            (maybe except for the level 3 super-chest puzzle...)
;		14.01.04 support for NTSC version added
;       01.05.20 reduced chipmem usage to 512k
;                added trainer infinite lives
;                added safety on credits cheat
;                added in-game keys
;                added second button jump
;                added joypad controls pause/quit
;                sound fixes
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.16, vasm
;  :To Do;
;  - full joypad controls with up for jump
;  - trainer infinite energy

; shop version 2: access fault
; test dma sound
;---------------------------------------------------------------------------*

DEBUG=0
SAVECODE=0

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE whdmacros.i

	IFD	BARFLY
	OUTPUT	"Gods.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimizer warnings
	SUPER
	ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
        ; this used to be $82000 but why?
        ; there was an access fault writing to long $7FFFE
        ; fixing the access fault allows game to run with 512k exact
        IFD ONEMEG_CHIP
        dc.l    $100000
        ELSE
		dc.l	$80000			;ws_BaseMemSize
        ENDC
        
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem	
    IFD ONEMEG_CHIP
        dc.l	$0			;ws_ExpMem
    ELSE
        dc.l	$80000			;ws_ExpMem
    ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_crc
		dc.w	_config-_base		;ws_config

_config
	dc.b	"BW;"
    dc.b    "C1:X:Trainer Infinite Lives:0;"
    dc.b    "C2:B:Second/blue button jumps;"
    dc.b    "C4:B:Disable sound fixes;"
	dc.b	0

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"3.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_name		dc.b	"Gods"
        IFD ONEMEG_CHIP
        dc.b    " (one megabyte chip)"
        ENDC
        dc.b    0
_copy		dc.b	"1990 Bitmap Brothers",0
_info		dc.b	"adapted by Wepl",10
		dc.b	"fixes by JOTD",10,10
        dc.b    "Press HELP to add 10000 credits in shop",10
        dc.b    "Press F1 for giant jump",10
        dc.b    "Press F2 to freeze aliens",-1
        dc.b    "Thanks to Kroah for reverse-engineering",10
		dc.b	"Version "
        DECL_VERSION
		dc.b	0
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)				;save for later using
		move.l	a0,a3				;A3 = resload
        
        bsr _detect_controller_types		

	;enable cache
	;	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	;	move.l	#WCPUF_All,d1
	;	jsr	(resload_SetCPU,a3)
    IFD ONEMEG_CHIP
    lea _expmem(pc),a0
    move.l  #$80000,(a0)
    ENDC
    
	IFNE DEBUG
		lea	_cbaf(pc),a0
		lea	_cbaftag(pc),a1
		move.l	a0,(a1)
	ENDC
		lea	_tags(pc),a0
		jsr	(resload_Control,a3)

        move.l  _trainer(pc),d0
        beq.b   .notrainer
        ; no scoresave if infinite lives (well, game probably never
        ; ends then but maybe more bits in this trainer will be used
        ; in the future ...)
		lea	(_cheatused,pc),a0
		st	(a0)        
.notrainer
	;init vars
		move.w	#$400,a7
		add.l	_expmem(pc),a7
        clr.l   $28.W   ; not sure it's useful, not harmful :)
        
        ; without expmem the slave crashes miserably
		move.l	a7,$2c				;exp-mem at
	;	move.b	#1,$1c				;???
	;	move.b	#0,$1c				;JOTD

	;check pal/ntsc
		moveq	#0,d0				;offset
		move.l	#$400,d1			;size
		moveq	#1,d2				;disk
		lea	$1000,a0			;data
		jsr	(resload_DiskLoad,a3)
		move.l	#$400,d0			;size
		lea	$1000,a0			;data
		jsr	(resload_CRC16,a3)
		cmp.w	#$d8b9,d0
		beq	_pal
		cmp.w	#$c242,d0
		beq	_ntsc
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a3)

;============================================================================

MOFFSET = $4000 ; added by JOTD: loads lower to avoid having to use >512k chip

_ntsc		lea	(_mainoffset,pc),a0
		move.l	#$70c00,(a0)			;different than pal version
 	;load part 1
		move.l	#$53200,d0			;offset
		move.l	#$11800,d1			;size
		moveq	#1,d2				;disk
		lea	$70000-MOFFSET,a5			;A5 = first part
		move.l	a5,a0				;data
		jsr	(resload_DiskLoad,a3)
	IFNE SAVECODE
		move.l	#$11800,d0			;size
		lea	(.name,pc),a0
		move.l	a5,a1
		jsr	(resload_SaveFile,a3)
		bra	.saveok1
.name		dc.b	"loadpic",0
.saveok1
	ENDC
		bsr	_waitvb
		jsr	(a5)
		move.l	_resload(pc),a3

	;load intro
		move.l	#$3400,d0			;offset
		move.l	#$4fe00,d1			;size
		moveq	#1,d2				;disk
		move.l	$2c,a0				;data
		jsr	(resload_DiskLoad,a3)

		lea	$84,a0				;dest
		move.l	$2c,a2				;source
		bsr	decrunch

	IFNE SAVECODE
		move.l	a0,d0
		lea	(.intro,pc),a0
		sub.l	a1,a1
		jsr	(resload_SaveFile,a3)
		bra	.saveok
.intro		dc.b	"intro",0
.saveok
	ENDC

		lea	0,a0
		lea	$4000,a1
		bsr	_dbffix

		lea	(_pl_intro3,pc),a0
		sub.l	a1,a1
		jsr	(resload_Patch,a3)
		
		bsr	_waitvb
		jmp	$84.W

_pl_intro3	PL_START
		PL_P	$150,_main
		PL_S	$b5a,6				;setting ssp
		PL_S	$b94,$b9e-$b8e			;setting ssp
		PL_S	$d46,$1822-$d46
		PL_W	$3352,9				;byte write to audvol
		PL_END

;============================================================================

_pal
	;load part 1
		move.l	#$52a00,d0			;offset
		move.l	#$8000,d1			;size
		moveq	#1,d2				;disk
		lea	$76e00,a5			;A5 = first part
		move.l	a5,a0				;data
		jsr	(resload_DiskLoad,a3)
	IFNE SAVECODE
		move.l	#$8000,d0			;size
		lea	.name(pc),a0
		move.l	a5,a1
		jsr	(resload_SaveFile,a3)
		bra	.saveok1
.name		dc.b	"loadpic",0
.saveok1
	ENDC
		ret	$68(a5)				;skip delay
		bsr	_flushcache        
		bsr	_waitvb
		jsr	(a5)
		move.l	(_resload,pc),a3

	;load intro
		move.l	#$3400,d0			;offset
		move.l	#$4f600,d1			;size
		moveq	#1,d2				;disk
		move.l	$2c,a0				;data
		jsr	(resload_DiskLoad,a3)

		lea	$84,a0				;dest
		move.l	$2c,a2				;source
		bsr	decrunch

	IFNE SAVECODE
		move.l	a0,d0
		lea	.intro(pc),a0
		sub.l	a1,a1
		jsr	(resload_SaveFile,a3)
		bra	.saveok
.intro		dc.b	"intro",0
.saveok
	ENDC
		lea	0,a0
		lea	$4000,a1
		bsr	_dbffix

		lea	_pl_intro(pc),a0
		sub.l	a1,a1
		jsr	(resload_Patch,a3)
		
		move.l	_buttonwait(pc),d0
		beq	.nowait
		move.l	#250,d0
		jsr	(resload_Delay,a3)
.nowait
	IFNE DEBUG
		lea	$2940,a0
		moveq	#8,d0
		jsr	(resload_ProtectWrite,a3)
	ENDC

		bsr	_waitvb
        ; just after password info screen, v1
		jmp	$84

_pl_intro	PL_START
		PL_P	$150,_main
	;	PL_P	$22e,_main
	;	PL_P	$240,_loader
	;	PL_P	$aba,decrunch
		PL_S	$b54,6				;setting ssp
		PL_S	$b8e,$b9e-$b8e			;setting ssp
	;	PL_R	$1bbe				;blthog
	;	PL_R	$1c10				;blthog
	;	patchs	$a00-$84+$24f2,_stfix		;soundtracker
	;	patchs	$a00-$84+$250a,_stfix		;soundtracker
	;	PL_L	$27c0,$3b6e0002			;byte write from aud1vol
		PL_W	$27c4,9				;byte write to audvol
	;	PL_P	$2f1e,_blitwait			;blthog
	;	PL_S	$32f6,6				;blthog
		PL_END

;============================================================================

_main
	;preserve coplc
		lea	$a8,a0
		lea	$70000,a1
		move.l	a1,d0
.cplc		move.l	(a0)+,(a1)+
		bpl	.cplc
		move.l	d0,(cop1lc,a6)
		move.w	#$7fff,(intena,a6)

	;load main
		move.l	_mainoffset(pc),d0			;offset
	;	move.l	#$2cf5c,d1			;size v1
		move.l	#$2cf6c,d1			;size v2
	;	move.l	#$2ced8,d1			;size v3
		moveq	#1,d2				;disk
		move.l	$2c,a0				;data
		move.l	_resload(pc),a3
		jsr	(resload_DiskLoad,a3)

    
		lea	$84,a0				;dest
		move.l	$2c,a2				;source
		bsr	decrunch

	IFNE SAVECODE
		move.l	a0,-(a7)
		move.l	a0,d0
		lea	.name(pc),a0
		sub.l	a1,a1
		jsr	(resload_SaveFile,a3)
		move.l	(a7)+,a0
		bra	.saveok
.name		dc.b	"main",0,0
.saveok
	ENDC

	;check disk version
		move.l	a0,d0
		lea	$84,a0
		sub.l	a0,d0

    
		jsr	(resload_CRC16,a3)
        move.l  #$1e5a4+3,d1
		lea	_pl_main1(pc),a0
		cmp.w	#$9125,d0
		beq	.ok
        move.l  #$1e5ab,d1
		lea	_pl_main2(pc),a0
		cmp.w	#$cac1,d0
		beq	.ok
        move.l  #$1e549,d1
		lea	_pl_main3(pc),a0
		cmp.w	#$e09f,d0
		beq	.ok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a3)
.ok
        movem.l a0,-(a7)
		lea	$2000.W,a0
		lea	$20000,a1
		bsr	_fix_rts_nop_smc
        movem.l (a7)+,a0

        lea current_key_address(pc),a1
        move.l  d1,(a1)
        
		sub.l	a1,a1
		jsr	(resload_Patch,a3)


	IFNE DEBUG
		lea	$60,a0
		moveq	#4,d0
		jsr	(resload_ProtectWrite,a3)
		lea	$b04c,a0
		moveq	#4,d0
		jsr	(resload_ProtectWrite,a3)
		lea	$d158,a0
		moveq	#4,d0
		jsr	(resload_ProtectWrite,a3)
		lea	$f6bc,a0
		moveq	#4,d0
		jsr	(resload_ProtectWrite,a3)
		lea	$107f0,a0
		moveq	#4,d0
		jsr	(resload_ProtectWrite,a3)
	ENDC

	IFEQ 1
	;clear expmem
		move.l	$2c,a0
		move.w	#($80000-$400)/16-1,d0
.clr		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		dbf	d0,.clr
	ENDC
        ; LOADING GAME: main game is loaded
		jmp	$8a.w


; shared between v1 & v2

_pl_main	PL_START
		PL_P	$10,_fix_move_rts_l
		PL_P	$16,_fix_move_rts_w
		PL_P	$20,_fix_move_nop_l
		PL_P	$26,_fix_move_nop_w
		PL_L	$60,$b4863d88			;copylock
		PL_S	$2446,$6388-$2446		;copylock
		PL_W	$5250,$200			;bplcon0
		PL_PA	$62e8,_rom1
		PL_PA	$62f2,_rom2
		PL_L	$b04c,$5dc			;copylock
		PL_CL	$d158				;copylock

		PL_PS	$7BC0,_smc1			;JOTD
		PL_NOP	$7BC6,2				;JOTD

		PL_PS	$2B12,_smc2			;JOTD

        PL_IFC1X    0
        ; infinite lives
        PL_W    $39EE,$4A7C
        PL_ENDIF
		PL_END

_pl_main1	PL_START
		PL_CL	$f6bc				;copylock
		PL_CL	$107f0				;copylock
		PL_R	$1d8f2				;checking drives
		PL_R	$1d962				;drives off
		PL_P	$1d9de,_loader
	;	PL_P	$1e392,_dbfd1
		PL_I	$1e392
		PL_P	$1e25c,decrunch
		PL_S	$39f8a,$39f92-$39f8a		;writing ssp

		PL_PS	$1D00A,_vbi1
		PL_P	$1D04E,_vbi2

		PL_PS	$3378,_smc31_v1			;JOTD
		PL_PS	$33B6,_smc32_v1			;JOTD

		PL_PS	$B4B6,_smc41_v1
		PL_PS	$B4DA,_smc42_v1

		PL_PS	$132B6,_smc5_v1
		PL_PS	$13738,_smc5_v1

        PL_IFC4
        PL_ELSE
        PL_PS   $1FFE8,_dma_off_1
        PL_PS   $20218,_dma_off_1
        PL_PS   $1FF3E,_dma_off_1
        PL_PS   $1fe70,_dma_off_1
        PL_PS   $1FC94,_dma_off_2
        PL_ENDIF

        PL_PSS  $13714,avoid_af,2

        PL_IFC2
        PL_PS   $120A0,jump_left
        PL_PS   $12360,jump_right
        PL_PS   $11b66,left_right_on_ladder ; climbing down, left
        PL_PS   $11ae4,left_right_on_ladder ; climbing down, right
        PL_PS   $11d66,left_right_on_ladder ; climbing up, left
        PL_PS   $11dec,left_right_on_ladder ; climbing up, right
        PL_ENDIF
        
        PL_PS   $1e3a6,read_fire

		PL_NEXT	_pl_main

_pl_main2	PL_START
		PL_CL	$f6bc+4				;copylock
		PL_CL	$107f0+4			;copylock
		PL_R	$1d8f6				;checking drives
		PL_P	$1d9e2,_loader
		PL_P	$1e260,decrunch
	;	PL_P	$1e396,_dbfd1
		PL_I	$1e396
		PL_S	$39f8e,$39f92-$39f8a		;writing ssp

		PL_PS	$1D00E,_vbi1
		PL_P	$1D052,_vbi2

		PL_PS	$3378,_smc31_v2			;JOTD
		PL_PS	$33B6,_smc32_v2			;JOTD

		PL_PS	$B4B6,_smc41_v2
		PL_PS	$B4DA,_smc42_v2

		PL_PS	$132BA,_smc5_v2
		PL_PS	$1373C,_smc5_v2
        
        PL_IFC4
        PL_ELSE
        PL_PS   $1fe74,_dma_off_1
        PL_PS   $1ff42,_dma_off_1
        PL_PS   $1ffec,_dma_off_1
        PL_PS   $2021c,_dma_off_1
        PL_PS   $1fc98,_dma_off_2
        PL_ENDIF
        PL_PSS  $13718,avoid_af,2
        
        PL_IFC2
        PL_PS   $11ae8,left_right_on_ladder ; climbing down, right
        PL_PS   $11b6a,left_right_on_ladder ; climbing down, left
        PL_PS   $11d6a,left_right_on_ladder ; climbing up, left
        PL_PS   $11df0,left_right_on_ladder ; climbing up, right
        PL_PS   $120a4,jump_left
        PL_PS   $12364,jump_right
        PL_ENDIF
        
        PL_PS   $1e3aa,read_fire

		PL_NEXT	_pl_main

_pl_main3	PL_START
		PL_P	$10,_fix_move_rts_l
		PL_P	$16,_fix_move_rts_w
		PL_P	$20,_fix_move_nop_l
		PL_P	$26,_fix_move_nop_w
		PL_W	$5228,$200			;bplcon0
		PL_PA	$62c0,_rom1
		PL_PA	$62ca,_rom2
		PL_PS	$7b98,_smc1			;JOTD
		PL_NOP	$7b9e,2				;JOTD
		PL_R	$1d894				;checking drives
		PL_P	$1d980,_loader
		PL_P	$1e1fe,decrunch
		PL_I	$1e334
		PL_S	$39f24,$39f92-$39f8a		;writing ssp
        
        PL_IFC1X    0
        ; infinite lives
        PL_W    $039C6,$4A7C
        PL_ENDIF

        PL_IFC4
        PL_ELSE
        PL_PS   $1fe0a,_dma_off_1
        PL_PS   $1fed8,_dma_off_1
        PL_PS   $1ff82,_dma_off_1
        PL_PS   $201b2,_dma_off_1
        PL_PS   $1fc26,_dma_off_2
        PL_ENDIF
        PL_PSS  $136a4,avoid_af,2

        PL_IFC2
        PL_PS   $11a74,left_right_on_ladder ; climbing down, right
        PL_PS   $11af6,left_right_on_ladder ; climbing down, left
        PL_PS   $11cf6,left_right_on_ladder ; climbing up, left
        PL_PS   $11d7c,left_right_on_ladder ; climbing up, right
        PL_PS   $12030,jump_left
        PL_PS   $122f0,jump_right
        PL_ENDIF
        
        PL_PS   $1e348,read_fire
        
		PL_END

_rom1		dc.b	$64				;values from rom 1.3
_rom2		dc.b	$ff				;values from rom 1.3

joystick_bits = $226

JUMPLR:MACRO
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    btst    #JPB_BTN_BLU,d0
    movem.l (a7)+,d0
    beq.b   .noblue
    ; blue is pressed, facing left
    bset    #\1,joystick_bits
    bset    #0,joystick_bits    ; up too
    tst.b   joystick_bits   ; clears Z
.noblue
    ; noblue: Z is set
    rts
    ENDM
    
read_fire
    movem.l d0/d1/a0,-(a7)
    move.l  joy1(pc),d1
    bsr _joystick
    move.l  joy1(pc),d0
    move.l  current_key_address(pc),a0
    ; pause
    btst    #JPB_BTN_PLAY,d0
    beq.b   .noplay
    btst    #JPB_BTN_PLAY,d1
    bne.b   .noplay
    move.b  #$20,(a0)
.noplay    
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noesc
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noesc
    btst    #JPB_BTN_YEL,d0
    bne     _exit
    move.b  #$1B,(a0)
.noesc   
    ; original fire test
    btst    #JPB_BTN_RED,d0
    beq.b   .nofire
    ; cancel current key, trick to avoid double esc
    clr.b   (a0)
    movem.l (a7)+,d0/d1/a0
    move.b  #$40,d0
    rts
.nofire:
    movem.l (a7)+,d0/d1/a0
    move.b  #$C0,D0
    rts
    
jump_left:
    JUMPLR  2
jump_right:
    JUMPLR  3
    
left_right_on_ladder
    bclr    #0,joystick_bits    ; UP
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    btst    #JPB_BTN_BLU,d0
    movem.l (a7)+,d0
    beq.b   .noblue
    bset    #0,joystick_bits    ; UP
.noblue
    btst    #0,joystick_bits    ; UP
    rts
    

avoid_af
    clr.l   ($41FE,a1)
    cmp.l   #$79cfe,a1
    bcc.b   .noclr
    ; avoid access fault long write to $7FFFE
    clr.l   ($62FE,a1)
.noclr
    rts
_dma_on_1
	MOVE.W	#$0001,6(A0)		;1ff66: 317c00010006
    MOVE.W (A4),(dmacon,a5)
    bra     _dma_wait
        
; 0001FD20 397c 0002 000e           MOVE.W #$0002,(A4,$000e) == $000203ea [0002]
; 0001FD26 3b54 0096                MOVE.W (A4) [8002],(A5,$0096) == $00dff096

_dma_off_2
    MOVE.W ($0002,A1),(dmacon,A0)
    bra     _dma_wait
        

       
_dma_off_1
    MOVE.W (2,A4),(dmacon,a5)
_dma_wait
    movem.l d0,-(a7)
	move.w	#4,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	movem.l (a7)+,d0
	rts
    
_smc1		bsr	_flushcache
		MOVE	4(A5),D2	;original
		CMPI	#$0007,D2	;original
		rts

_smc2		
		MOVE	d0,$BC1A	;original
		bsr	_flushcache
		rts

_smc31_v1
		move.l	#$33B6,$139D6	;original
		bsr	_flushcache
		addq.l	#4,(a7)
		rts
_smc32_v1
		move.l	#$2BD6,$139D6	;original
		bsr	_flushcache
		addq.l	#4,(a7)
		rts
_smc31_v2
		move.l	#$33B6,$139DA	;original
		bsr	_flushcache
		addq.l	#4,(a7)
		rts
_smc32_v2
		move.l	#$2BD6,$139DA	;original
		bsr	_flushcache
		addq.l	#4,(a7)
		rts

_smc41_v1
		move	#$59,$17434
		bsr	_flushcache
		addq.l	#2,(a7)
		rts

RESTORE_A7_RTS:MACRO
	movem.l	a0,-(a7)
	lea	.jmp(pc),a0
	move.l	4(a7),(a0)
	movem.l	(a7)+,a0
	addq.l	#4,a7
	move	(a7)+,\1
	bsr	_flushcache
	move.l	.jmp(pc),-(a7)
	rts
.jmp
	dc.l	0
	ENDM

_smc42_v1
		RESTORE_A7_RTS	$17434

_smc41_v2
		move	#$59,$17438
		bsr	_flushcache
		addq.l	#2,(a7)
		rts

_smc42_v2
		RESTORE_A7_RTS	$17438

_smc5_v1
		RESTORE_A7_RTS	$1CFBC

_smc5_v2
		RESTORE_A7_RTS	$1CFC0

_vbi1
		bne.b	.sk
		add.l	#$52-$14,(a7)
.sk
		rts

_vbi2
		move.w	#$20,$dff09c
		movem.l	(a7)+,d0-a6
		rte

_fix_rts_nop_smc
.loop
	move.l	(a0),d0
	cmp.l	#$33FC4E75,d0
	beq.b	.movertslong
	cmp.l	#$31FC4E75,d0
	beq.b	.movertsword
	cmp.l	#$33FC4E71,d0
	beq.b	.movenoplong
	cmp.l	#$31FC4E71,d0
	beq.b	.movenopword
	addq.l	#2,a0
	cmp.l	a0,a1
	bne.b	.loop
	rts

.movertslong
	move.l	#$4EB80010,(a0)+
	bra.b	.loop
.movertsword
	move.l	#$4EB80016,(a0)+
	bra.b	.loop
.movenoplong
	move.l	#$4EB80020,(a0)+
	bra.b	.loop
.movenopword
	move.l	#$4EB80026,(a0)+
	bra.b	.loop


FIX_MOVE_L:MACRO
;;	move.w	#$F00,$dff180
	move.l	a0,-(a7)
	move.l	4(a7),a0
	move.l	(a0),a0
	move.w	#\1,(a0)
	move.l	(a7)+,a0
	addq.l	#4,(a7)
	bsr	_flushcache
	rts
	ENDM

FIX_MOVE_W:MACRO
;;	move.w	#$F00,$dff180
	move.l	a0,-(a7)
	move.l	4(a7),a0
	move.l	d0,-(a7)
	moveq	#0,d0
	move.w	(a0),d0
	move.l	d0,a0
	move.w	#\1,(a0)
	move.l	(a7)+,d0
	move.l	(a7)+,a0
	addq.l	#2,(a7)
	bra	_flushcache
	ENDM

_fix_move_rts_l
	FIX_MOVE_L	$4E75

_fix_move_rts_w
	FIX_MOVE_W	$4E75

_fix_move_nop_l
	FIX_MOVE_L	$4E71

_fix_move_nop_w
	FIX_MOVE_W	$4E71

_flushcache
	move.l	_resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts
	
;--------------------------------
; d1 startblock
; d2 blockcount
; d3 mode  bit0=0 read  bit0=1 write
; a0 destination

_loader		btst	#0,d3				;read or write ?
		bne	_savehighs			;only highscores

		moveq	#1,d0
		cmp.l	d0,d1
		bne	.0
		cmp.l	d0,d2
		beq	_loadhighs
.0
		movem.l	d1-d3/a0-a2,-(a7)

		cmp.l	#$7ba80,a0
		bne	.1
		lea	(.disk,pc),a1
		move.w	#2,(a1)				;from this point only disk 2
.1
		mulu	#512,d1				;start on disk
		move.l	d1,d0				;offset
		mulu	#512,d2				;amount of blocks
		move.l	d2,d1				;size
		moveq	#0,d2
		move.w	(.disk,pc),d2			;disk
		move.l	(_resload,pc),a2
		
		jsr	(resload_DiskLoad,a2)
		
		bsr	_kinit
        
		movem.l	(a7)+,d1-d3/a0-a2
		moveq	#0,d0
		rts

.disk		dc.w	1

;--------------------------------

_loadhighs	movem.l	d1/a0-a2,-(a7)
		lea	(_savename,pc),a0
		move.l	(_resload,pc),a2
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		beq	.image
.file		move.l	(4,a7),a1			;address
		lea	(_savename,pc),a0			;filename
		jsr	(resload_LoadFile,a2)
		bra	.end
.image		move.l	#512,d0				;offset
		move.l	d0,d1				;len
		moveq	#2,d2				;disk
		move.l	(4,a7),a0			;address
		jsr	(resload_DiskLoad,a2)
.end		movem.l	(a7)+,d1/a0-a2
		moveq	#0,d0
		rts

_savehighs	movem.l	d1-d2/a0-a2,-(a7)
		move.b	(_cheatused,pc),d0
		bne	.end
		move.l	#512,d0				;len
		move.l	a0,a1				;address
		lea	(_savename,pc),a0			;filename
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFile,a2)
.end		movem.l	(a7)+,d1-d2/a0-a2
		moveq	#0,d0
		rts

_savename	dc.b	"highs",0

;--------------------------------

_kinit		movem.l	a0-a1,-(a7)
		lea	(_keyboard,pc),a1
		cmp.l	$68,a1
		beq	.q
        
		lea	(_realint68,pc),a0
		move.l	$68,(a0)
		move.l	a1,$68
.q		movem.l	(a7)+,a0-a1
		rts

_realint68	dc.l	0

_keyboard	move.l	d0,-(a7)
		move.b	$bfec01,d0
		ror.b	#1,d0
		not.b	d0
        
; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f

		cmp.b	(_keydebug,pc),d0
		bne	.1
		move.l	(a7)+,d0
		move.w	(a7),(6,a7)			;sr
		move.l	(2,a7),(a7)			;pc
		clr.w	(4,a7)				;ext.l sr
		bra	_debug				;coredump & quit
.1
		cmp.b	(_keyexit,pc),d0
		beq	_exit				;exit
		cmp.b   #$50,d0 ; F1
        bne.b   .11
;        btst    #3,$19D
;        bne.b   .11     ; else locks up game if pressed when jumping
        move.w  #1000,$220.W    ; giant jump
		bsr _cheat_has_been_used
.11
		cmp.b   #$51,d0 ; F2
        bne.b   .12
        move.w  #170,$306.W    ; freeze aliens
		bsr _cheat_has_been_used
.12
		cmp.b	#$5f,d0				;help
		bne	.2        
        cmp.l   #300000,$1FC.W
        bcc.b   .2  ; too much money crashes the display/game
		add.l	#10000,$1fc			;some more money
		bsr _cheat_has_been_used
.2
		move.l	(a7)+,d0
		move.l	(_realint68,pc),-(a7)		;enter orginal rou.
		rts
        
current_key_address:
    dc.l    0
    
_cheat_has_been_used
    movem.l a0,-(a7)
    lea	(_cheatused,pc),a0
    st	(a0)
    movem.l (a7)+,a0
    rts
;--------------------------------

_waitvb		waitvb
		rts

;--------------------------------
; a0=destination a2=source

decrunch	move.l	_attn(pc),d0
		btst	#AFB_68020,d0
		bne	decrunch20

.0	moveq	#0,d0
	movea.l	a0,a1
	move.b	(1,a2),d0
	lsl.w	#8,d0
	move.b	(a2),d0
	addq.w	#2,a2
	tst.w	d0
	beq	_flushcache
	add.l	a2,d0
.000900	cmp.l	a2,d0
	bls.b	.0
	moveq	#0,d1
	move.b	(a2)+,d1
	bmi.b	.000914
	subq.w	#1,d1
.00090C	move.b	(a2)+,(a0)+
	dbra	d1,.00090C
	bra.b	.000900

.000914	cmpi.b	#$FF,d1
	beq.b	.000936
	andi.b	#$7F,d1
.00091E	move.b	(1,a2),d2
	lsl.w	#8,d2
	move.b	(a2),d2
	addq.w	#2,a2
	lea	(a1,d2.w),a6
	subq.w	#1,d1
.00092E	move.b	(a6)+,(a0)+
	dbra	d1,.00092E
	bra.b	.000900

.000936	move.b	(1,a2),d1
	lsl.w	#8,d1
	move.b	(a2),d1
	addq.w	#2,a2
	bra.b	.00091E

decrunch20

.0	moveq	#0,d0
	movea.l	a0,a1
	move.w	(a2)+,d0
	ror.w	#8,d0
	beq	_flushcache
	add.l	a2,d0
.000900	cmp.l	a2,d0
	bls.b	.0
	moveq	#0,d1
	move.b	(a2)+,d1
	bmi.b	.000914
	subq.w	#1,d1
.00090C	move.b	(a2)+,(a0)+
	dbra	d1,.00090C
	bra.b	.000900

.000914	cmpi.b	#$FF,d1
	beq.b	.000936
	andi.b	#$7F,d1
.00091E	move.w	(a2)+,d2
	ror.w	#8,d2
	lea	(a1,d2.w),a6
	subq.w	#1,d1
.00092E	move.b	(a6)+,(a0)+
	dbra	d1,.00092E
	bra.b	.000900

.000936	move.w	(a2)+,d1
	ror.w	#8,d1
	bra.b	.00091E

;--------------------------------

_resload	dc.l	0				;address of resident loader
_mainoffset	dc.l	$5aa00				;this is pal version value
_tags		dc.l	WHDLTAG_BUTTONWAIT_GET
_buttonwait	dc.l	0
        dc.l    WHDLTAG_CUSTOM1_GET
_trainer
        dc.l    0
		dc.l	WHDLTAG_ATTNFLAGS_GET
_attn		dc.l	0
	IFNE DEBUG
		dc.l	WHDLTAG_CBAF_SET
_cbaftag	dc.l	0
	ENDC
		dc.l	0
_cheatused	dc.b	0
	EVEN

;--------------------------------

_exit		pea	TDREASON_OK.w
		bra	_end
_debug		pea	TDREASON_DEBUG.w
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

	IFNE DEBUG
_cbaf		cmp.l	#$b5a,a0
		beq	.ok
		cmp.l	#$b64,a0
		beq	.ok
		cmp.l	#$3098,a0
		beq	.ok
		cmp.l	#$309e,a0
		beq	.ok
		moveq	#0,d0
		rts
.ok		moveq	#1,d0
		rts
	ENDC

;======================================================================

	INCLUDE	dbffix.s
    include ReadJoyPad.s
    
;======================================================================

	END

;version 1 amiga:

;$19C.W: player state (mask)
; 00 facing left
; 01 facing right
; 1A facing back
; 0E ladder
; 08 jumping left
; 09 jumping right

;$1D4.W: current level 1,2,3,4
;$220.W: giant jump timer. $5000: lasts a loooong time
;$224.W: nb lives
;$226.W: joystick bits
;  bit 0: up
;  bit 2: left
;  bit 3: right

;$230.W: is world completed 0/1
;$23A.W: is fighting guardian 0/1/2
;$2a6.W: death animation counter ($FFFF: alive)
;$27a.W: game quit
;$1E0/$1E2: pos X,Y

; stop music (end of world)
;;00012D06 660c                     BNE.B #$0c == $00012d14 (T)
;00012D08 31fc 0001 0230           MOVE.W #$0001,$0230 [0001] ; stop cd play
;00012D0E 4cdf 0101                MOVEM.L (A7)+,D0/A0
; restart music (next world starts)
;000131DE 4278 0230                CLR.W $0230
;000131E2 701f                     MOVE.L #$1f,D0
; player killed
;00003B6A 4278 02a6                CLR.W $02a6
;00003B6E 4a78 02a6                TST.W $02a6 [0000]
; quit game
;?????
; level starts
;00002B86 323c 007f                MOVE.W #$007f,D1
;00002B8A 303c 0009                MOVE.W #$0009,D0
; player respawns
;000038BE 4240                     CLR.W D0
;000038C0 4eb9 0001 d23a           JSR $0001d23a
;000038C6 31fc 0018 0c96           MOVE.W #$0018,$0c96 [0018]
;000038CC 31fc 0001 0216           MOVE.W #$0001,$0216 [0001]

; world end
;?????
; guardian

;BeginQuest: $2452.W
;GameWon: $2F12.W

;GameLoop address: $2C20 (similar code at $0000FC2E)
;00002C20 4eb9 0001 6e3e           JSR $00016e3e
;00002C26 6100 0a12                BSR.W #$0a12 == $0000363a
;00002C2A 4678 0196                NOT.W $0196 [0000]

;Screen_MainMenu address:
; 000063A6 4278 02f4                CLR.W $02f4
; 000063AA 4eb9 0000 f514           JSR $0000f514

; trigger level end
; f $2F0E
; g
; g $2F12