;*---------------------------------------------------------------------------
;  :Program.	BoppinHD.asm
;  :Contents.	Slave for "Boppin"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BoppinHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"CrazyCars3.slave"
	IFND	CHIP_ONLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE
NO68020

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	kick13.s
    include ReadJoyPad.s
    
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.1"
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

assign1
	dc.b	"CCDAT",0
assign2
	dc.b	"CCIII",0

slv_name		dc.b	"Crazy Cars 3"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1992 Titus",0
slv_info		dc.b	"adapted by Harry & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

intro:
    dc.b    "anim",0
program:
	dc.b	"cciii",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	dc.b    "C1:X:trainer start with 9.000.000$:0;"
	dc.b    "C1:X:trainer infinite boosts:1;"
	dc.b    "C1:X:trainer no damage:2;"
	dc.b    "C1:X:trainer always have night vision:3;"
	dc.b    "C3:B:disable blitter waits;"
	dc.b    "C4:L:start division:4,3,2,1;"
	dc.b    "C5:B:skip introduction;"
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN


_bootdos
		clr.l	$0.W

        bsr _detect_controller_types
        
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload
        lea	(tag,pc),a0
        jsr	(resload_Control,a2)

	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
        
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$04888,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

    
	;assigns
		lea	assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

        move.l  skip_intro_flag(pc),d0
        bne.b   .skip_intro
		lea	intro(pc),a0
        jsr (resload_GetFileSize,a2)
        tst.l   d0
        beq.b   .skip_intro
        
		lea	intro(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_intro(pc),a5
		bsr	load_exe
        
.skip_intro
	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

patch_intro
	lea	pl_intro(pc),a0
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)
    rts
    
pl_intro:
    PL_START
    PL_R       $dfc     ; floppy led/motor stuff
    PL_END
; < d7: seglist (APTR)

patch_main
	bsr	get_version 
    ; set start division
    move.l  d7,a1
    add.l   a1,a1
    add.l   a1,a1
    addq.l  #4,a1
    add.l   #$FB42,a1
    move.l  #4,d0
    sub.l  start_division(pc),d0
    move.w  d0,(a1)
    
    lea vbl_hook_2(pc),a0
    lea orig_vbl(pc),a1
    move.l  $6C.W,(A1)
    move.l  a0,$6C.W
	lea	pl_main(pc),a0
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)
.skip
	rts

; apply on SEGMENTS
pl_main
    PL_START
    ; useless
    ;;PL_PS   $42A,fix_dmacon_write
    
    PL_P    $11FEA,skip_floppy_stuff
    ; no need to load a patched GUNN file, patch directly from here
    PL_P    $0010a,skip_gunn_protection
    PL_IFC3
    PL_ELSE
    ; fix blitter errors (map)
    PL_PS    $01fe2,wait_blitter_d0
    PL_PS    $02c5c,wait_blitter_d0
    PL_PS    $02eba,wait_blitter_d0        
    ; fix blitter errors (drivers)
	PL_PS    $02c3a,wait_blitter_drivers

    ; other blit fixes aren't very useful
    ; there's still a problem on fast machines
    ; in drivers screen
;    PL_PS    $0ebea,wait_blitter_d5
;    PL_PS    $0ec70,wait_blitter_d5
;    PL_PS    $0ecfa,wait_blitter_d5
;    PL_PS    $0ede2,wait_blitter_d5
;    PL_PS    $0eeca,wait_blitter_d5
;    PL_PS    $0efb6,wait_blitter_d5
;    PL_PS    $0f046,wait_blitter_d5
;    PL_PS    $0f0d6,wait_blitter_d5
;    PL_PS    $0f16a,wait_blitter_d5
;    PL_PS    $0f25c,wait_blitter_d5
;    PL_PS    $0f34e,wait_blitter_d5
;    PL_PS    $0f444,wait_blitter_d5
;    PL_PS    $0f4de,wait_blitter_d5
;    PL_PS    $0f64c,wait_blitter_d5
;
;    PL_PS    $0f6b8,wait_blitter_d1
;    PL_PS    $0f54a,wait_blitter_d1
;
    ; replace possibly buggy blitterwait routine
    ; see https://eab.abime.net/showthread.php?p=1422388#post1422388
    PL_PSS  $02b34,skip_wait_blitter,4
    PL_PSS  $0e952,skip_wait_blitter,4
    PL_PSS  $0eba6,skip_wait_blitter,4
    PL_PSS  $0ec28,skip_wait_blitter,4
    PL_PSS  $0ecb2,skip_wait_blitter,4
    PL_PSS  $0eda2,skip_wait_blitter,4
    PL_PSS  $0ee86,skip_wait_blitter,4
    PL_PSS  $0ef72,skip_wait_blitter,4
    PL_PSS  $0f002,skip_wait_blitter,4
    PL_PSS  $0f08e,skip_wait_blitter,4
    PL_PSS  $0f122,skip_wait_blitter,4
    PL_PSS  $0f21c,skip_wait_blitter,4
    PL_PSS  $0f30a,skip_wait_blitter,4
    PL_PSS  $0f400,skip_wait_blitter,4
    PL_PSS  $0f486,skip_wait_blitter,4
    PL_PSS  $0f51a,skip_wait_blitter,4
    PL_PSS  $0f5fc,skip_wait_blitter,4
    PL_PSS  $0f688,skip_wait_blitter,4
    PL_ENDIF
    PL_PSS  $02bc2,vbl_hook,2

    PL_PS   $046fa,fix_copperlist
    
    PL_PS   $05188,start_boost_test
    PL_PSS  $11EBC,fire_button_test,2
    PL_PS   $5198,night_vision_test
    
    PL_PSS   $0517c,quit_test,6
    PL_PS   $5152,pause_test
    PL_S    $5158,$517C-$5158
    
    PL_IFC1X    0
    ; start with a lot of money
    PL_L    $0fabc,9000000
    PL_ENDIF
    PL_IFC1X    1
    ; infinite boost
    PL_NOP  $55DA,2
    PL_NOP  $55e8,4
    PL_ENDIF
    PL_IFC1X    2
    ; no damage at all
    PL_NOP  $084ce,4
    ; infinite damage: not working from race, just from
    ; shop: so not really useful
    ;;PL_NOP  $10fde,4
    
    PL_ENDIF
    PL_IFC1X    3
    PL_NOP  $05196,2
    PL_ENDIF
       
    PL_END
    
fix_copperlist
    movem.l a0,-(a7)
    move.l  d0,a0
    ; copy copper 1 pointer to copper 2 else it points
    ; to $12345678 ....
    
    move.w  6(a0),14(a0)
    move.w  10(a0),18(a0)
    movem.l (a7)+,a0
    MOVE.L	D0,$dff080  ; 360FA
    RTS
   
fix_dmacon_write
	MOVE.W	D0,_custom+dmacon		;0042a: 33c000dff096
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
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
	rts 
    
vbl_hook_2
    movem.l D0,-(A7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    beq.b   .novbl
    bsr _joystick
.novbl
    movem.l (a7)+,d0
    move.l  orig_vbl(pc),-(a7)
    rts

vbl_hook
    bsr _joystick
	ADDQ.W	#1,-7974(A4)		;02bc2: 526ce0da
	SUBQ.B	#1,-27008(A4)		;02bc6: 532c9680
    RTS

night_vision_test
    movem.l d1/a0,-(a7)
    move.l  prev_joy1(pc),d1
    btst    #JPB_BTN_GRN,d1
    bne.b   .keytest        ; already pressed
    move.l  joy1(pc),d1
    btst    #JPB_BTN_GRN,d1
    beq.b   .keytest
    ; button has just been pressed: toggle night vision
    bchg.b   #0,5039(a4)
.keytest
	MOVEQ	#0,D0			;05198: 7000
	MOVE.B	5039(A4),D0		;0519a: 102c13af
    lea prev_joy1(pc),a0
    move.l  joy1(pc),(a0)
    movem.l (a7)+,d1/a0
    rts



    
;0003A3D7=00C2 0003BAC3=0027 0003BAD3=0027 0003BADF=0027 0003D6F7=00C2

wait_blitter_drivers
    LEA	$dff040,A3		;02c3a: 47f900
    bra.b wait_blitter
    
wait_blitter_d0
	MOVE.W	D0,_custom+bltsize
    bra.b wait_blitter
wait_blitter_d1
	MOVE.W	D1,_custom+bltsize
    bra.b wait_blitter
wait_blitter_d5
	MOVE.W	D5,_custom+bltsize
wait_blitter
	BTST	#6,_custom+dmaconr
.wait
	BTST	#6,_custom+dmaconr
	BNE.S	.wait
    rts    
skip_wait_blitter
    rts
fire_button_test:
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0    
    rts
    
pause_keypress_5004 = 5004

PLAYTEST:MACRO
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    ENDM
    
pause_test
    movem.l d0,-(a7)
    ; first test for pause
    PLAYTEST
    bne.b   .unpressedloop
	TST.B	pause_keypress_5004(A4)		;05152: 4a2c138c
	BEQ	.nopause		;05156: 6724
    
    ; F10 pressed, now wait for F10 to be released
.unpressedloop:
    PLAYTEST
    bne.b   .unpressedloop
	TST.B	pause_keypress_5004(A4)		;05158: 4a2c138c
	BEQ.S	.LAB_0238    ;0515c: 670c
.stillpressed    
    ; pause
	MOVE.B	4869(A4),D0		;0515e: 102c1305
	OR.B	4868(A4),D0		;05162: 802c1304
	BEQ.S	.LAB_0238		;05166: 6702
	BRA.S	.unpressedloop		;05168: 60ee
    ; pause was pressed then released: pause
.LAB_0238:
    PLAYTEST
    bne.b   .nopause
	TST.B	pause_keypress_5004(A4)		;0516a: 4a2c138c
	BNE.S	.nopause		;0516e: 670c
.stillpressed2
	MOVE.B	4869(A4),D0		;05170: 102c1305
	OR.B	4868(A4),D0		;05174: 802c1304
	BNE.S	.nopause		;05178: 6602
	BRA.S	.LAB_0238		;0517a: 60ee
.nopause:
.playunpress:
    PLAYTEST
    bne.b   .playunpress
    movem.l (a7)+,d0
    rts
    
quit_test:
    movem.l d0,-(a7)
   ; F5: quit race
    move.l  joy1(pc),d0  
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .norev 
    btst    #JPB_BTN_FORWARD,d0    
    beq.b   .norev 
    btst    #JPB_BTN_YEL,d0    
    beq.b   .noyel
    bra _quit
.norev
	TST.B	4881(A4)		;0517c: 4a2c1311 F5 keycode
	BEQ.S	.noquit		;05180: 6706
.noyel
    ; this cheat makes you win the challenge and lose the races
    ; useful only when I tried to figure out where division number
    ; was stored without playing the game, now not very useful
    IFD    CHALLENGE_CHEAT
    btst    #JPB_BTN_GRN,d0
    beq.b   .quit
    move.w  #10,4456(a4)    ; distance to be run
    move.w  #1,2100(a4)    ; distance done
    bra.b   .noquit
    ENDC
.quit
	MOVE.W	#$0001,-4(A5)		;05182: 3b7c0001fffc
.noquit:
    movem.l (a7)+,d0
    rts
    

quit_race_test
    movem.l d0,-(a7)
    ; first pause test with joypad
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    beq.b   .nopause
    ; paused: wait for release
.waitunpress1
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .waitunpress1
.waitpress
    ; wait for press
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    beq.b   .waitpress
.waitunpress2
    ; unpaused: wait for unpress to avoid immediate pause
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .waitunpress2
.nopause
    movem.l (a7)+,d0

    ; now quit test
	TST.B	4881(A4)		;0517c: 4a2c1311
	BNE.S	.quit		;0518c: 6704
    movem.l d0,-(a7)
    move.l  joy1(pc),d0  
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit    
    btst    #JPB_BTN_FORWARD,d0
.noquit    
    movem.l (a7)+,d0
    beq.b   .out
.quit
    MOVE.W	#$0001,-4(A5)   ; set quit flag
.out
    rts
    
start_boost_test:
	TST.B	4897(A4)		;05188: 4a2c1321
	BNE.S	.start		;0518c: 6704
    movem.l d0,-(a7)
    move.l  joy1(pc),d0    
    btst    #JPB_BTN_BLU,d0
    movem.l (a7)+,d0
    bne.b   .start
    addq.l  #4,(a7) ; skip boost activate
.start
    rts
    
    
    
skip_gunn_protection:
	;;MOVEM.L	D1-D7/A0-A6,-(A7)	;0000: 48e77ffe
	LEA	16896(A0),A0		;0004: 41e84200
    ; copy $200 bytes important stuff in memory
    ; if not there, game will crash when race starts
	LEA	GUNN_crack_data(PC),A1		;0008: 43fa01f6
	MOVE.W	#$01ff,D0		;000c: 303c01ff
LAB_0001:
	MOVE.B	(A1)+,(A0)+		;0010: 10d9
	DBF	D0,LAB_0001		;0012: 51c8fffc
	;;MOVE.L	#$00005366,D0		;0016: 203c00005366 ; disk checksum
	;;MOVEM.L	(A7)+,D1-D7/A0-A6	;001c: 4cdf7ffe
    
	CLR.W	D0			;0012e: 4240
	MOVEM.L	(A7)+,D4-D7/A2-A3	;00130: 4cdf0cf0
	UNLK	A5			;00134: 4e5d
	RTS				;00136: 4e75
    
skip_floppy_stuff:
	MOVEM.L	(A7)+,D0-D1/A0		;12004: 4cdf0103
	UNLK	A5			;12008: 4e5d
	RTS				;1200a: 4e75
    
GUNN_crack_data:
	dc.b	$02,$00,$01,$e3,$01,$c9,$01,$b1,$01,$9c,$01,$89,$01,$78,$01,$68
	dc.b	$01,$59,$01,$4c,$01,$40,$01,$34,$01,$29,$01,$1f,$01,$16,$01,$0d
	dc.b	$01,$05,$00,$fd,$00,$f6,$00,$ef,$00,$e8,$00,$e2,$00,$dc,$00,$d7
	dc.b	$00,$d1,$00,$cc,$00,$c8,$00,$c3,$00,$bf,$00,$ba,$00,$b6,$4e,$4e
	dc.b	$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e
	dc.b	$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e
	dc.b	$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e
	dc.b	$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e
	dc.b	$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e
	dc.b	$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$48,$09,$09,$09,$09,$09,$09
	dc.b	$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09
	dc.b	$09,$09,$09,$0f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f1,$41,$41,$40,$19
	dc.b	$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09
	dc.b	$09,$09,$09,$09,$09,$09,$09,$09,$0f,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	$ff,$ff,$ff,$ff,$f0,$a1,$a1,$fe,$4f,$00,$01,$02,$70,$1d,$4e,$4e
	dc.b	$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e
	dc.b	$4e,$4e,$4e,$4e,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$a1,$a1,$a1,$fb,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	dc.b	$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41

    
get_version:
	movem.l	d1/a0/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#$1BD0C,D0
	beq.b	.original
    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.original
	moveq	#1,d0
    bra.b   .out
    nop


.out
	movem.l	(a7)+,d1/a0/a1
	rts



; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)

	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)

	;get tags
    move.l  _resload(pc),a2
    lea (segments,pc),a0
    move.l  d7,(a0)
    lea	(tagseg,pc),a0
	jsr	(resload_Control,a2)


	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

	;remove exe

	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
orig_vbl
    dc.l    0
tag
		dc.l	WHDLTAG_CUSTOM5_GET
skip_intro_flag	dc.l	0
		dc.l	WHDLTAG_CUSTOM4_GET
start_division	dc.l	0
    dc.l    0
tagseg
        dc.l    WHDLTAG_DBGSEG_SET
segments:
		dc.l	0
		dc.l	0
prev_joy1   dc.l    0

;============================================================================

	END
