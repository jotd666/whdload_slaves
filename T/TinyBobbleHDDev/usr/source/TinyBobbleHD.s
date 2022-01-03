; slave for "Tiny Bobble"
;
; history
; - first release used kickstart emulation
; - next release got rid of kickstart but failed
;   relocating exec hunks properly, resulting in some
;   (not all) trashed graphics due to improper blits from fastmem
; - last update fixed that chunk reloc: game runs properly

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
        INCLUDE	exec/memory.i
        INCLUDE	lvo/exec.i

		IFD BARFLY
		OUTPUT	"TinyBobble.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC


;CHIP_ONLY

STACKSIZE = $1000
EXECSIZE = $6A000

    IFD CHIP_ONLY
CHIPMEM = $E0000
EXPMEM = STACKSIZE*2

    ELSE
CHIPMEM = $80000
EXPMEM = $70000+STACKSIZE*2
    ENDC
    
;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem 		;ws_flags
		dc.l	CHIPMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
; add $1000 so game doesn't go access fault by overwriting
; top of stack...
_expmem		dc.l	EXPMEM+$1000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
		
;============================================================================
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.3"
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
	
_name		dc.b	"Tiny Bobble"
    IFD CHIP_ONLY
    dc.b    " (DEBUG/CHIP MODE)"
    ENDC
    dc.b    0
_copy		dc.b	"2020 pink^abyss",0
_info		dc.b	"adapted by JOTD",10
		dc.b	"trained by Ross",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_data		dc.b	"data",0
program:
	dc.b	"aYs_tinybobble",0

_config
    dc.b    "C1:X:trainer infinite lives:0;"
    dc.b    "C2:X:blue/second button jumps player 1:0;"
    dc.b    "C2:X:blue/second button jumps player 2:1;"
        ;dc.b    "C3:B:keep LMB as quit button;"
		dc.b	0

		EVEN

IGNORE_JOY_DIRECTIONS
    include     ReadJoyPad.s


;======================================================================
_start						;a0 = resident loader
;======================================================================
        lea _custom,a6
        move.w  #$7FFF,dmacon(a6)
        move.l  #$FFFFFFFE,$100.W
        move.l  #$100,cop1lc(a6)
        move.w  #$200,bplcon0(a6)
        
        
		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

        ; install fake exec for AllocMem & AvailMem
        lea $1000.W,A6
        move.l  A6,4.W
        move.l  #$FF,d0
        move.l  #$4AFC4AFC,d1   ; trash other vectors just in case...
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
        lea (_LVOCopyMem,a6),a0
        move.w  #$4EF9,(a0)+
        pea fake_copymem(pc)
        move.l  (a7)+,(a0)
    
    
        ;;bsr _SetupKeyboard
        bsr _detect_controller_types
        lea controller_joypad_0(pc),a0
        clr.b   (a0)        ; no need to read port 0 extra buttons...
        

        ; chip already configured
        ; set fastmem. Note: in chip_only mode
        ; the fastmem size will be 0
        move.l  _expmem(pc),a3        
        lea free_fastmem(pc),a0
        move.l  a3,(a0)+    ; start

        add.l   #EXPMEM-STACKSIZE*2,a3   ; minus stack
        move.l  a3,(a0) ; top

        move.l  _expmem(pc),A7
        add.l   #EXPMEM,A7 ; ssp stack on top of fastmem
        move.l  A7,A0        
        sub.l   #STACKSIZE,A0   ; usb stack just below
        move.l  A0,USP
        move.w  #0,SR
        
        ; now allocate memory for executable
        move.l  #EXECSIZE,d0
        move.l  #0,d1
        move.l  4,a6
        jsr (_LVOAllocMem,a6)
        
        addq.l  #8,d0
        lea game_address(pc),a0        
        move.l  d0,(a0)

        lea	tag(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		
		lea	program(pc),a0	;Load main file
		move.l	game_address(pc),a1
        sub.l   #8,a1   ; for segments + align
		move.l	a1,a5
		bsr	_LoadFile
        bsr	_Relocate
        ; patch decrunch

        move.l  game_address(pc),d0
        subq.l  #4,d0
        lsr.l   #2,d0
        move.l  d0,a1
        lea pl_boot(pc),a0
        jsr resload_PatchSeg(a2)      
 		move.l	game_address(pc),-(a7)
        rts

pl_boot
	PL_START
    PL_P    $BC,end_unpack
    PL_S    $8,$40-$8
	PL_END

pl_main
	PL_START
    ; skip OS shit
    PL_S    $86,$B8-$86
    PL_S    $218,$23E-$218
    PL_S    $2DA,$2FA-$2DA
    
    ;PL_PS   $0c8,alloc_chipmem_1
    ;PL_PS   $50A,alloc_chipmem_2
    ;PL_PS   $106,alloc_fastmem
    ;PL_S    $1c0,$01e0-$1c0
    ;PL_S    $0152,$0272-$0252
    
    ; skip read at $F0FF60
    PL_S    $01800,$16
    PL_W    $01820,$588f
    PL_S    $01822,$16
    PL_R    $0253E
    PL_R    $0a380
    PL_S    $17f52,$68-$52
    PL_NOP  $19a04,6
    PL_S    $19a0e,$1A-$E
    ; remove vbr read & other MMU registers shit
    PL_NOP  $36E,6
    PL_B  $00374,$60
    ; quit
    PL_P    $5f4,_quit  ; not a normal quit
    PL_P    $1892,_quit
    ; vbl hook
    PL_PSS  $2602,vbl_hook,2
    ; keyboard hook
    PL_PS   $2448,keyboard
    ; joystick
    PL_PS   $ba3C,read_fire
    PL_PS   $ba92,read_fire
    ; 2nd button jumps
    PL_IFC2
    PL_PS   $B9FE,second_button
    PL_ENDIF
    
    ; pause
    PL_PS   $1F850,wait_pause_quit
    PL_PSS  $1f5c8,pause_test,2
    PL_PS   $1F7F0,read_joypad_pause
    PL_PS   $1F85C,exit_vpos_loop
    PL_PS   $1f870,exit_vpos_loop
    
    ; hiscore save & load
    PL_PS    $1803e,load_highs
    PL_PSS   $11736,save_highs,2
	
	PL_IFC1X	0
	PL_NOP	$1e7a2,2	; infinite lives (thanks Ross)
	PL_ENDIF
	
    PL_END

wait_tof
.w:
	MOVE.L	$dff004,D0		;3f856: 203900
	ANDI.L	#$0001ff00,D0		;3f85c: 02800001ff00
	CMPI.L	#$0,D0		;3f862: 0c8000013700
	BNE.S	.w		;3f868: 67ec
    rts
    
read_joypad_pause
; wait top of frame to read the buttons
    bsr wait_tof
    bsr _read_joysticks_buttons
    
    MOVE.W	A5,D6			;3f7f0: 3c0d
	BTST	#0,D7			;3f7f2: 08070000
    rts
    
load_highs
    movem.l d0-d1/a0-a3,-(a7)
    move.l  loaded_highscore(pc),d0
    tst.l   d0
    bne   .noload
    ; no highscore loaded: load it now
    move.l  _resload(pc),a3
    lea highname(pc),a0
    jsr (resload_GetFileSize,a3)
    tst.l   d0
    beq.b   .noload
    lea loaded_highscore(pc),a1
    lea highname(pc),a0
    jsr (resload_LoadFile,a3)
    ; store loaded hiscore in location
    move.l  loaded_highscore(pc),(6240+6,A2)
.noload        
    movem.l (a7)+,d0-d1/a0-a3
    MOVE.W	#$0003,(6440,A2)    ; original code
    RTS
    

    ; this is called quite a lot, so it's a save/load routine
save_highs
    movem.l d0-d1/a0-a3,-(a7)
         
.loaded
    lea highname(pc),a0
    lea	(6240,A2),a1
    move.l  (a1),d0
    ; don't save if same highscore as already loaded
    cmp.l   loaded_highscore(pc),d0
    beq.b   .nosave
    move.l  _resload(pc),a3
    moveq.l #4,d0
    jsr (resload_SaveFile,a3)
.nosave
    movem.l (a7)+,d0-d1/a0-a3
    ; original
	TST.B	(-8,A5)			;31736: 4a2dfff8
    bne.b   .out
	add.l   #$d24-$73c,(a7) ; emulate branch
.out
    rts
    
exit_vpos_loop
    ANDI.L	#$0001ff00,D0
    movem.l  d0,-(a7)
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_PLAY,d0
    movem.l  (a7)+,d0  
    bne.b   .exit
    rts
.exit
    move.l  #$13700,d0
    rts
    
pause_test
    cmp.b   #$CD,d0
    beq.b   .branch
    
    movem.l  d0,-(a7)
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d0
    bne     _quit
    
.noquit
    btst    #JPB_BTN_PLAY,d0
    movem.l  (a7)+,d0  
    bne.b   .wait_and_branch
    rts
.branch
    add.l   #$79e-$5ce,(a7)
    rts
.wait_and_branch
    bsr wait_play_released
    bra.b   .branch
    
wait_pause_quit
    cmp.b   #$CD,d0
    beq.b   .branch
    
    movem.l  d0,-(a7)
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_PLAY,d0
    movem.l  (a7)+,d0  
    bne.b   .wait_and_branch2
    rts
.branch
    add.l   #$88-$56,(a7)
    rts
    
.wait_and_branch
    bsr wait_play_released
    bra.b   .branch
        
.wait_and_branch2
    move.l  d0,-(a7)
.wait
    bsr wait_tof
    bsr _read_joysticks_buttons
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .wait
    move.l  (a7)+,d0
    bra.b   .branch
    
wait_play_released    
    move.l  d0,-(a7)
.wait
    move.l  joy1_buttons(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .wait
    move.l  (a7)+,d0
    rts
    
; < A1: DFF00A or DFF00C
second_button:
    MOVE.W	(A1),D3

	; using 2nd button data, tamper with JOYxDAT value
	movem.l	d2/a0,-(a7)
    
    move.l  button_config(pc),d2
	lea	joy0_buttons(pc),a0
    cmp.l   #$DFF00A,a1
    beq.b   .port0
    ; port 1, check if active
    btst    #0,d2
    beq.b   .no_blue
    lea	joy1_buttons(pc),a0
.port0
    btst    #1,d2
    beq.b   .no_blue
.test
	move.l	(a0),d2	; read buttons values
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d3
	btst	#9,d3
	beq.b	.noneed
	bset	#8,d3	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d2
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d3
	btst	#9,d3
	bne.b	.no_blue
	bset	#8,d3	; xor 8 and 9 yields 1 cos bit9=0
.no_blue:
	movem.l	(a7)+,d2/a0

	MOVE.W	D3,D2			;2ba00: 3403
	LSL.W	#1,D2			;2ba02: e34a

	RTS    
read_fire
    st   d0
    move.l d1,-(a7)
    move.l  joy1_buttons(pc),d1
    btst    #JPB_BTN_RED,d1
    beq.b   .nofire1
    bclr    #7,d0
.nofire1
    move.l  joy0_buttons(pc),d1
    btst    #JPB_BTN_RED,d1
    beq.b   .nofire0
    bclr    #6,d0
.nofire0
    move.l  (a7)+,d1
    rts
    
; 000C37DE=0003 000CC1C8=0002 000CC1CA=0003
; 000CC1E2=0034 000CC232=0002 000CC234=0003 000CC24C=0034
; 000CC29C=0002 000CC29E=0003 000CC2B6=0034 000CC50A=0003
; 000CC5A4=0003 000CD05E=0002 >
    
    ; not really super-helpful as game already has "ESC"
    ; as a quit key
keyboard:
	MOVE.B	$bfec01,D1		;22448: 123900
    movem.l d1,-(a7)
    ror.b   #1,d1
    not.b   d1
    cmp.b   _keyexit(pc),d1
    beq _quit
    movem.l (a7)+,d1
    RTS
    
vbl_hook
    bsr _read_joysticks_buttons
    ; cheap-o way to check if A0 is 0
    ; (can fail if you're not lucky)
	CMPA.W	#$0000,A0		;22602: b0fc0000
	BEQ.S	LAB_0115		;22606: 6702
	JSR	(A0)			;22608: 4e90
LAB_0115:
    rts
    
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
 
jump_decrunch
    jmp (a4)
    
CIAA_PRA = $bfe001
CIAA_SDR = $BFEC01



end_unpack
    lea (4,a3),a1
    move.l  _resload(pc),a2
    lea (4,a3),a1
    lea pl_main(pc),a0
    jsr (resload_Patch,a2)
    jmp (4,a3)

    
    ;include whdload/keyboard.s

;======================================================================
_LoadFile	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Relocate	movem.l	d0-d1/a0-a2,-(sp)
		move.l	a5,a0
        clr.l   -(a7)                   ;TAG_DONE
        pea     -1                      ;true
        pea     WHDLTAG_LOADSEG
    IFND CHIP_ONLY        
        move.l  #$1000,-(a7)       ;chip area
        pea     WHDLTAG_CHIPPTR        
    ENDC
        pea     8                       ;8 byte alignment
        pea     WHDLTAG_ALIGN
        move.l  a7,a1                   ;tags		move.l	_resload(pc),a2
		jsr	resload_Relocate(a2)
    IFND CHIP_ONLY        
        add.w   #7*4,a7
    ELSE
        add.w   #5*4,a7
    ENDC
        movem.l	(sp)+,d0-d1/a0-a2
		rts

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

    IFEQ    1
    ; temp compute free memory
    lea free_chipmem(pc),a0
    move.l  (4,a0),$100
    move.l  (a0),d2
    sub.l   d2,$100
    lea free_fastmem(pc),a0
    move.l  (4,a0),$104
    move.l  (a0),d2
    sub.l  d2,$104
    ENDC
    

    move.l  (a7)+,d2
    

    tst.l   d0
    rts
    
.not_enough
    tst.l   d2
    bne.b   .out
    ; no particular memory required: perform a second pass
    ; with chipmem
    move.l  #MEMF_CHIP,d2
    bra   .chip
.out
    moveq.l #0,d0
    move.l  (a7)+,d2
    rts

fake_copymem
    movem.l d2-d3,-(a7)
    ; borrowed from JST code :)
	cmp.l	A0,A1
	beq.b	.exit		; same regions: out
	bcs.b	.copyfwd	; A1 < A0: copy from start

	tst.l	D0
	beq.b	.exit		; length 0: out

	; here A0 > A1, copy from end

	add.l	D0,A0		; adds length to A0
	cmp.l	A0,A1
	bcc.b	.cancopyfwd	; A0+D0<=A1: can copy forward (optimized)
	add.l	D0,A1		; adds length to A1 too

.copybwd:
	move.b	-(A0),-(A1)
	subq.l	#1,D0
	bne.b	.copybwd

.exit
    movem.l (a7)+,d2-d3
    rts
.cancopyfwd:
	sub.l	D0,A0		; restores A0 from A0+D0 operation
.copyfwd:
	move.l	A0,D1
	btst	#0,D1
	bne.b	.fwdbytecopy	; src odd: byte copy
	move.l	A1,D1
	btst	#0,D1
	bne.b	.fwdbytecopy	; dest odd: byte copy

	move.l	D0,D2
	lsr.l	#4,D2		; divides by 16
	move.l	D2,D3
	beq.b	.fwdbytecopy	; < 16: byte copy

.fwd4longcopy
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	subq.l	#1,D2
	bne.b	.fwd4longcopy

	lsl.l	#4,D3		; #of bytes*16 again
	sub.l	D3,D0		; remainder of 16 division

.fwdbytecopy:
	tst.l	D0
	beq.b	.exit
.fwdbytecopy_loop:
	move.b	(A0)+,(A1)+
	subq.l	#1,D0
	bne.b	.fwdbytecopy_loop
	bra.b	.exit
    
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
    IFD CHIP_ONLY
    dc.l    $1000   ; start
    ELSE
    dc.l    $15000  ; chip hunk comes first
    ENDC
    dc.l    CHIPMEM

    
    ; initialized dynamically at startup
free_fastmem
    dc.l    0   ; start
    dc.l    0   ; top
    

		
		
;======================================================================
_resload	dc.l	0			;Resident loader
game_address
    dc.l    0
    
tag
		dc.l	WHDLTAG_CUSTOM2_GET
button_config	dc.l	0
    dc.l    0
        dc.l   0
;======================================================================

_quit		pea	TDREASON_OK
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
prev_joy1   dc.l    0
loaded_highscore
    dc.l    0
highname
    dc.b    "highscore",0
		END
