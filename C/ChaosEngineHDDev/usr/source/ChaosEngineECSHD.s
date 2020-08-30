;*---------------------------------------------------------------------------
;  :Program.	chaosengine.asm
;  :Contents.	Slave for ChaosEngine
;  :Author.	BJ
;  :Version.	$Id: chaosengine.asm 1.2 1999/07/07 22:45:33 jah Exp jah $
;  :History.	20.05.96
;		23.05.97
;		08.08.97 new slave version, wmode killed
;		31.08.97 new keyboard style
;		07.07.99 support for second version added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

    IFD     BARFLY
	OUTPUT	wart:c/chaosengine/ChaosEngine.Slave
	BOPT	O+ OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
    ENDC
    
;;CHIP_ONLY = 1

    IFD CHIP_ONLY
CHIPMEMSIZE = $FF000
FASTMEMSIZE = 0
    ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $7F000    
    ENDC
    
	STRUCTURE	globals,$200
		LONG	_resload
		WORD	_dchk
		WORD	_disk

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
_upchip		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l    0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	$58			;ws_keydebug = F9
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	FASTMEMSIZE			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

;============================================================================
    include ReadJoyPad.s
    include shared.s
;============================================================================


_config
    dc.b    "BW;"
    dc.b    "C1:X:Trainer Infinite Energy:0;"
    dc.b    "C1:X:Trainer 99 Lives:1;"
	dc.b	0

;============================================================================



_name		dc.b	"The Chaos Engine",0
_copy		dc.b	"1992-3 The Bitmap Brothers",0
_info		dc.b	"installed by Wepl & JOTD",10,10
	    dc.b	'use CUSTOM= to set the 12-char level password on startup',10,10
		dc.b	"Version "
        DECL_VERSION
		dc.b	0
    even


;======================================================================
_Start		;	A0 = resident loader
;======================================================================

		move.l	a0,(_resload)		;save for later using
		move.w	#0,(_dchk)
		move.w	#1,(_disk)


		move.l	(_resload),a3
		move.l	#CACRF_EnableI,d0	;enable instruction cache
		move.l	d0,d1    		;mask
		jsr	(resload_SetCACR,a3)

        ;get password
        lea	(password,pc),a0
        moveq.l	#0,d1
        move.l	#13,d0
        jsr	(resload_GetCustom,a3)

		move.l	#$9c00,d0		;offset	 $3400 for not enough mem
		move.l	#$15c00,d1		;size
		moveq	#1,d2			;disk
		bsr _get_expmem
        move.l  a0,a4
		jsr	(resload_DiskLoad,a3)
		
        ; compute CRC before decrunch & relocate else it will vary
 		move.l  a4,a0
		move.l	#$10000,d0
		move.l	(_resload),a3
		jsr	(resload_CRC16,a3)
        move.l  d0,d5
        
        IFD     CHIP_ONLY
		clr.l	$8.W			;lower bound fastmem
        ELSE
        move.l  a4,$8.W
        ENDC
		move.l	(_upchip,pc),$14.W		;uppper bound chipmem
		move.l	#3,$24			;flags
		
		clr.l	$94			;AccessFault $cccccccc pc=9ff9c
		
		MOVE.L	$0020(A4),D0
		ADD.L	D0,D0
		ADD.L	D0,D0
		LEA	$002C(A4,D0.L),A1
		CLR.L	(A1)
		MOVE.L	A1,D0
		LSR.L	#2,D0
		MOVE.L	D0,$0020(A4)

		move.l	#$4e714e71,$24+$1d0(a4)
        jsr (resload_FlushCache,a3)
		Jsr	$0024+4(A4)		;decrunch + relocate
		

        
        lea $b6fa,a1
        lea pl_v1(pc),a0
		cmp.w	#$5512,d5
		beq	.patch
        lea $B700,a1
        lea pl_sps106(pc),a0
		cmp.w	#$A91A,d5
		beq	.patch
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a3)
.patch
        add.l   a4,a1
        bsr restore_password

        move.l  a4,a1
        jsr (resload_Patch,a3)
		jmp	$24+$1ec(a4)		;start the dance


; non SPS version    
pl_v1:
    PL_START
    PL_P    $4f5e,_loader
	PL_P    $a3ec,_cl
    PL_PS   $c504,_kbint_ecs_v1
    PL_IFC1
    PL_NOP  $756,6
    PL_PSS   $e76,set_lives,2
    PL_ENDIF
    
    PL_PS   $38e6,_level3_interrupt_hook

    PL_IFBW
    PL_PS    $32b6,_level_loaded
    PL_ENDIF
    
    PL_NEXT pl_common

pl_sps106:
    PL_START
    PL_P    $4f64,_loader
	PL_P    $a3f2,_cl
    PL_PS   $c500,_kbint_ecs_sps106
    PL_IFC1X 0
    PL_NOP  $756,6
    PL_ENDIF
    PL_IFC1X 1
    PL_PSS   $e7c,set_lives,2
    PL_ENDIF
    

    PL_PS   $38ec,_level3_interrupt_hook
    
    PL_IFBW
    PL_PS    $32bc,_level_loaded
    PL_ENDIF
    PL_NEXT pl_common
   
pl_common
    PL_START
    PL_PS   $5FE,_joypad_buttons_loop_ecs
    PL_PS   $7fc,_pause_test_ecs
    PL_PS   $886,_pause_test_ecs
    PL_PS   $89e,_pause_test_ecs
    PL_PS   $896,_pause_test_ecs
    PL_END



    JOY_FUNCS    ecs,2045

    
_kbint_ecs_sps106:
	MOVE.B	#$01,3072(A0)		;8c500: original
    bra.b   _kbint_common
_kbint_ecs_v1
    ORI.B	#$40,3584(A0)
_kbint_common
	movem.l	d0,-(a7)
    ror.b	#1,d0
    not.b	d0

; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f

    cmp.b	(_keyexit,pc),d0
    beq	_exit			;exit

    movem.l	(a7)+,d0
    rts    

_previous_joystate_1
      dc.l  0
_previous_joystate_0
      dc.l  0
      
;--------------------------------
; copylock emulation: store signature in $100 then skip it
_cl		add.w	#$9c4,a7
		move.l	#$711e7e0c,$100
		rts

_get_expmem:
    IFD CHIP_ONLY
    lea $80000,a0
    ELSE
    move.l  _expmem(pc),a0
    ENDC
    rts
    
_loader		movem.l	d1-d3/a0-a2,-(a7)

        ; re-detect controllers plugged in at each load
        bsr _detect_controller_types

		moveq	#0,d3
		cmp.w	#$16,d1		;accessing disk-id (chaos special)
		bne	.go
		move.w	(_dchk),d3
		not.w	d3
		bne	.go
		
		lea	(_disk),a1
		addq.w	#1,(a1)
		move.w	(a1),d3
		cmp.w	#3,d3
		bne	.g1
		move.w	#1,(a1)
.g1		moveq	#0,d3

.go		move.w	d3,(_dchk)

		mulu	#512,d1		;start on disk
		move.l	d1,d0		;offset
		mulu	#512,d2		;amount of blocks
		move.l	d2,d1		;size
		moveq	#0,d2
		move.w	(_disk),d2	;disk
		move.l	(_resload),a2
		jsr	(resload_DiskLoad,a2)
		movem.l	(a7)+,d1-d3/a0-a2
		moveq	#0,d0

		rts

_exit		pea	TDREASON_OK.w
		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts
;--------------------------------


;======================================================================
    
