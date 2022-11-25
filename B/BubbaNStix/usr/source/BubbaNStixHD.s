;*---------------------------------------------------------------------------
;  :Program.	BubbaNStixHD.asm
;  :Contents.	Slave for "BubbaNStix"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BubbaNStixHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;CHIP_ONLY
;============================================================================

    IFD CD32
	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
; needs a lot of chip because of intro exe
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $80000
	ENDC
    ELSE
	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $110000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
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
SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE
SEGTRACKER

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'


	include	whdload/kick13.s
    include ReadJoyPad.s
    
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"3.1"
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
_assign1
	dc.b	"Bubba1",0
_assign2
	dc.b	"Bubba2",0
	IFD	CD32
_assign3
	dc.b	"CD0",0
_assign4
	dc.b	"Bubba",0
	ENDC
slv_name		dc.b	"Bubba'N'Stix "
        IFD CHIP_ONLY
        dc.b    "(DEBUG/CHIP mode) "
        ENDC
		IFD CD32
		dc.b	"CD³²",0
		ELSE
		dc.b	"ECS",0
		ENDC
slv_copy		dc.b	"1993 Core Design",0
slv_info		dc.b	"adapted & fixed by JOTD",10
	IFD CD32
		dc.b	10,"Thanks to Henri Lange for CD image"
	ELSE
		dc.b	10,"Thanks to Bored Seal"
	ENDC
		dc.b	10,10,"Version "
        DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

	IFD  CD32
_intro:
	dc.b	"Intro",0
	ENDC
_program:
	dc.b	"Bubba",0
_args		dc.b	10
_args_end
	dc.b	0
slv_config
	dc.b    "C1:X:trainer infinite lives:0;"
	dc.b    "C1:X:trainer infinite energy:1;"
	dc.b    "C2:B:alternate joypad controls;"
    IFD CD32
	dc.b	"C5:B:skip intro;"
    ENDC
	dc.b	0	
	EVEN



_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)


	;enable cache
	;	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	;	move.l	#WCPUF_All,d1
	;	jsr	(resload_SetCPU,a2)


	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
	IFD     CD32
		lea	_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		move.l	skip_intro(pc),d0
		bne.b	.skipintro
		lea	_intro(pc),a0
        jsr (resload_GetFileSize,a2)
        cmp.l   #1247948,d0
        bne.b   _wrong_version
	;load exe
		lea	_intro(pc),a0
		lea _args(pc),a1
        move.l  #_args_end-_args,d0
        lea _patch_intro(pc),a5
        bsr _load_exe
.skipintro:
	ENDC

    bsr _detect_controller_types
    ; install vbl hook which counts vblank
    ; and also reads controllers
    lea old_level3_interrupt(pc),a0
    move.l  $6C.W,(a0)
    lea new_level3_interrupt(pc),a0
    move.l  a0,$6C.W

	;load exe
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        IFD CD32
        move.l  #$20000-$1B9F0,d0
        ELSE
        move.l  #$20000-$1B890,d0
        ENDC
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC
		lea	_program(pc),a0
        jsr (resload_GetFileSize,a2)
    IFD CD32
        cmp.l   #415024,d0
    ELSE
        cmp.l   #415612,d0
    ENDC
        bne.b   _wrong_version
		lea	_program(pc),a0
		lea _args(pc),a1
        move.l  #_args_end-_args,d0
        lea _patch_exe(pc),a5
        bsr _load_exe

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


_wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
    
_load_a5
	lea	$dff000,a5
	bra.b	_wait_blit
_load_a6
	lea	$dff000,a6
_wait_blit
	btst	#6,dmaconr+$dff000
	bne.b	_wait_blit
	rts

_wb_1:
	bsr.b	_wait_blit
	; stolen code
	ADD.L	(A0)+,D1		;0D30E: D298
	MOVE.L	D1,(A3)			;0D310: 2681 blit here
	MOVEA.L	(A0)+,A2		;0D312: 2458
	rts

    IFD CD32
_patch_intro:
    ; correct display parameters that are different in kick 13
    ; which trashes the display in the intro
    ; (values not in intro copperlist, but in system copperlist)
    
    lea _custom,a0
    ; turn off copper dma so we can hardcode strt/stop values
    move.w  #$0080,dmacon(a0)
    ; same values as in kick 3.1
    move.w  #$2C81,diwstrt(a0)
    move.w  #$22C1,diwstop(a0)
    move.w  #$0038,ddfstrt(a0)

	move.l	d7,a1    
	lea	_pl_intro(pc),a0
	jsr	resload_PatchSeg(a2)
	rts
_patch_exe:
    ; save a variable else we cannot patch
    move.l  d7,a1
    add.l   a1,a1
    add.l   a1,a1
    lea pause_var_address(pc),a0
    move.l  $4542+4+2(a1),(a0)


	move.l	d7,a1    
	lea	_pl_main(pc),a0
	jsr	resload_PatchSeg(a2)
    
	rts
    
_pl_intro:
    PL_S    0,$20       ; skip freeanim shit
    PL_S    $26,$32-$26       ; skip cachecontrol shit
    PL_S    $9A,$B8-$9A       ; skip lowlevel lib open/close
    PL_NOP  $00016a,4    ; opendev
    PL_NOP  $0002a2,4    ; closedev
    
    ; skip CD32 cddevice calls
    PL_R    $000634      ; sendio
    PL_R    $000664      ; sendio
    PL_R    $000690      ; sendio
    PL_R    $0006c0      ; abortio
	PL_END
    
_pl_main:
	PL_START
	PL_R	$83F8		; drive stuff
	PL_PS	$1548,_load_a5	; wait blit problem
	PL_PS	$3BAC,_load_a6	; wait blit problem
	PL_PS	$49D4,_load_a6
	PL_PS	$D30E,_wb_1
    
    ; infinite lives
    PL_IFC1X    0
    PL_NOP      $09454,2
    PL_ENDIF
    PL_IFC1X    1
    PL_PSS      $09414,reset_energy,2
    PL_ENDIF

    ; tell that standard joystick connected (this enables
    ; the floppy version joystick read routine, that we can patch
    ; easily)
    PL_P    $06bfc,fake_joypad_read

    PL_IFC2
    ; alternate controls: yellow to throw, blue to jump
    PL_PSS  $063ca,read_throw_button_alternate,6
    PL_PSS  $063ac,read_joystick_directions_and_fire1,4
    
    ; force 2-3 button control no matter what
    PL_S    $0ab82,$0aba8-$0ab82
    PL_NOP  $038be,8
    PL_STR0 $03c08,<3 BUTTON CD32 PAD>
    PL_ELSE
    ; if original controls selected, 2 button, use cd32/joy2
    ; read routine or non-CD32 joypads aren't going to work
    PL_PSS  $063ca,read_throw_button_classic,6
    PL_PS   $063b0,read_fire
    PL_ENDIF

    ; re-instate play for pause, rev+fwd for esc
    PL_PSS  $04504,pause_esc_levelskip_test,2
    PL_PS   $04542,unpause_loop
    
    ; skip CD32 cddevice calls
    PL_S    $06354,$063a6-$06354    ; doio
    PL_R    $06b2e      ; sendio
    PL_R    $06b5e      ; sendio
    PL_R    $06b96      ; sendio
    PL_NOP  $06bea,4    ; abortio
    PL_NOP  $06878,4    ; opendev
    PL_NOP  $082b0,4    ; closedev
    ; skip lowlevel close
    PL_NOP  $06796,4
    
	PL_END
;    	MOVE.B	D0,joypad_control_bits		;0abd0: 13c000008e47
; $40: up
; $8: right
; $4: left
; $1: fire 2 (jump)
; $2: down
; $80: fire 1

fake_joypad_read
    move.l  #$30000000,d0   ; joystick (not joypad)
    rts
    ELSE
    

    
COPYLOCK_ID = $38891291


_patch_exe:

	move.l	d7,a1
	move.l	#COPYLOCK_ID,$F4.W  ; probably not needed

	lea	_pl_ecs(pc),a0
	jsr	resload_PatchSeg(a2)

    move.l  d7,a1
    add.l   a1,a1
    add.l   a1,a1
    lea pause_var_address(pc),a0
    move.l  $03ba8+4+2(a1),(a0)
	rts

_pl_ecs:
	PL_START
	PL_S	$0,$391E	; skip copylock call entirely

    PL_P    $37d4,end_unpack
    
	PL_R	$7A16		; drive stuff
	PL_PS	$0BFC,_load_a5	; wait blit problem
	PL_PS	$325A,_load_a6	; wait blit problem
	PL_PS	$4052,_load_a6
	PL_PS	$C718,_wb_1

    ; infinite lives
    PL_IFC1X    0
    PL_NOP      $08870,2
    PL_ENDIF
    PL_IFC1X    1
    PL_PSS      $8830,reset_energy,2
    PL_ENDIF
    PL_IFC2
    ; alternate controls: yellow to throw, blue to jump
    PL_PSS  $05a0c,read_throw_button_alternate,6
    PL_PSS  $059ee,read_joystick_directions_and_fire1,4
    ; force 2-3 button control no matter what
    PL_S    $09f92,$09fbe-$09f92
    PL_NOP  $02f78,8
    PL_STR0 $032a6,<3 BUTTON CD32 PAD>
    PL_ELSE
    ; if original controls selected, 2 button, use cd32/joy2
    ; read routine or non-CD32 joypads aren't going to work
    PL_PSS  $05a0c,read_throw_button_classic,6
    PL_PS   $59F2,read_fire
    PL_ENDIF

    ; re-instate play for pause, rev+fwd for esc
    PL_PSS  $03b6a,pause_esc_levelskip_test,2
    PL_PS   $03ba8,unpause_loop

    ; write the key in the copylock routine (chip segment)
    ; required else it crashes at the first boss because of a
    ; sneaky protection test at JSR	-2(A4,D0.W)		;0e75a: 4eb400fe
    ; on code that installs on the fly (without cache flush which is baaaaad)
    ; and destroys A4 value if fails
    ;+$13EA0 207a d29c                MOVEA.L (PC,$d29c) == $0003113e [00077400],A0
    ;+$13EA4 0ca8 3889 1291 4098      CMP.L #$38891291,(A0,$4098) == $0007b498 [38891291]
    ;+$13EAC 56c0                     SNE.B D0 (F)
    ;+$13EAE 4880                     EXT.W D0
    ;+$13EB0 d8c0                     ADDA.W D0,A4
    ;+$13EB2 4e75                     RTS

    PL_L    $5b48c,COPYLOCK_ID

	PL_END
    ENDC
    
reset_energy
	MOVEP.L	D2,0(A2)		;08830: 05ca0000
	MOVEP.L	D3,8(A2)		;08834: 07ca0008
	move.w  #6,(a0)     ; 6 energy points
    rts
    
unpause_loop
    move.l d1,-(a7)
    move.l  a0,d1
    move.l  pause_var_address(pc),a0
    clr.b   (a0)
    move.l  d1,a0
    move.l  joy1(pc),d1
    btst    #JPB_BTN_RED,d1
    movem.l (a7)+,d1
    beq.b   .dont_exit_loop
    addq.l  #6,(a7) ; exit loop
.dont_exit_loop
    rts
    
pause_esc_levelskip_test
	BEQ.b   .nokey
.out

	CMPI.B	#$a1,D0			;04508: 0c0000e6
    beq.b   .nohelp
    ; to skip a level it's easy: just pop the stack
    addq.l  #4,a7
.nohelp
	CMPI.B	#$e6,D0			;04508: 0c0000e6
    rts
.nokey
; no key pressed, test the joypad
    move.l d1,-(a7)
    move.l  joy1(pc),d1
    btst    #JPB_BTN_PLAY,d1
    beq.b   .noplay
    move.b  #$e6,d0
    bra.b   .rout
.noplay
    btst    #JPB_BTN_FORWARD,d1
    beq.b   .noesc
    btst    #JPB_BTN_GRN,d1
    beq.b   .nolskip
    ; to skip a level it's easy: just pop the stack
    addq.l  #8,a7
    rts
.nolskip
    btst    #JPB_BTN_REVERSE,d1
    beq.b   .noesc
    move.b  #$ba,d0
    bra.b   .rout
.noesc  
    move.l (a7)+,d1
    add.l   #$50,(a7)
    rts
.rout
    move.l (a7)+,d1
    bra.b   .out
    
read_joystick_directions_and_fire1
    movem.l D2,-(a7)
    move.l  joy1(pc),d2
	move.l	$DFF00A,D0
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed
	bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d2
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
    ; now red button
    st  d1
    btst    #JPB_BTN_RED,d2
    beq.b   .nofire
    bclr    #7,d1   ; simulate CIAA_PRA
.nofire
    movem.l (a7)+,d2
    rts

read_fire
    movem.l D0,-(a7)
    move.l  joy1(pc),d0
    st  d1
    btst    #JPB_BTN_RED,d0
    beq.b   .nofire
    bclr    #7,d1   ; simulate CIAA_PRA
.nofire
    movem.l (a7)+,d0
    rts

read_throw_button_classic
    movem.l D0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_BLU,d0
    movem.l (a7)+,d0
    rts
    
read_throw_button_alternate
    movem.l D0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_YEL,d0
    movem.l (a7)+,d0
    rts
    
    
end_unpack
    ; some hidden code is sometimes unpacked in memory
    ; better flush the cache or maybe it could lead to issues.
    ; (this is here we could remove the stealthy protection check but no
    ; need since the proper value is at the proper address)
    bsr _flushcache
    ; d1 is 0, ensure Z flag is set else title screen & music are skipped!!
    ; (calling flushcache preserves registers but not CCR)      
    tst.l   d1
	MOVEM.L	(A7)+,D0-D7/A0-A6	;037d4: 4cdf7fff
    rts
    

    
; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
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
	movem.l	a3-a6/d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a3-a6/d7
.skip
	;call


	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	move.l	d7,a1
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

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



new_level3_interrupt
    movem.l d0/a0,-(a7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    beq.b   .novbl
    ; vblank interrupt, read joystick/mouse
    bsr _joystick
    move.l  joy1(pc),d0
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .novbl
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .novbl
    btst    #JPB_BTN_YEL,d0
    bne   _quit
.novbl
    movem.l (a7)+,d0/a0
    move.l  old_level3_interrupt(pc),-(a7)
    rts
    
old_level3_interrupt
    dc.l    0
pause_var_address
    dc.l    0

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
skip_intro	dc.l	0
		dc.l	0

;============================================================================

