

;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"Smarty.Slave"
    
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER					;disable supervisor warnings
	ENDC


;CHIP_ONLY


    IFD CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = $000
    ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
    ENDC

    
;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	19			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem		;ws_flags
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
        dc.b    "C1:X:Trainer infinite Lives:0;"
        dc.b    "C1:X:Trainer infinite power-ups:1;"
        dc.b    "C1:X:Trainer one key completes level:2;"
        dc.b    "C2:B:second button jumps;"
;        dc.b    "C3:L:start world:Papupata's Temple,Sandman's mines,Kalinkalia,Otto's Factory,Nightmare's Castle;"
;        dc.b    "C4:L:start sublevel:1,2,3,4,5;"
        dc.b    "C5:B:skip introduction;"
		dc.b	0
                
;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC
	

DECL_VERSION:MACRO
	dc.b	"1.1"
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
_name		dc.b	"Smarty and the Nasty Gluttons"
    IFD CHIP_ONLY
    dc.b    " (DEBUG MODE)"
    ENDC

    
        dc.b    0
_copy		dc.b	"2020 Eero Tunkelo",0
_info		dc.b	"adapted by JOTD",10
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
       
IGNORE_JOY_DIRECTIONS
		INCLUDE ReadJoyPad.s
        
BOOTADDR = $5000
     
;============================================================================
_Start		;	A0 = resident loader
;============================================================================
	;save resload base
        lea (_resload,pc),a1
		move.l	a0,(a1)			;save
		move.l	a0,a2	
        
		;get tags
		lea	(_tag,pc),a0
		move.l	_resload(pc),a2
		jsr	(resload_Control,a2)

    IFD CHIP_ONLY
        lea $80000,a1
        lea  _expmem(pc),a0
        move.l  a1,(a0)
    ELSE
        move.l  _expmem(pc),a1
    ENDC

    move.l  #$80000,$90.W   ; end of chip
    move.l  a1,$8C.W        ; start of expmem
    
	bsr	_detect_controller_types

    lea _bootprg(pc),a0
    lea $5000.W,a1
    jsr resload_Decrunch(a2)
    
    lea pl_boot(pc),a0
    lea BOOTADDR,a1
    jsr resload_Patch(a2)

    jmp BOOTADDR

jump_400
    movem.l d0-d1/a1-a2,-(a7)
    move.l  _resload(pc),a2
    lea pl_400(pc),a0
    lea $400.W,a1
    jsr resload_Patch(a2)
    movem.l (a7)+,d0-d1/a1-a2
    lea $7be00,a0       ; original
    rts

jump_2C000_intro
    movem.l d0-d1/a1-a2,-(a7)
    move.l  _resload(pc),a2
    lea highscores(pc),a0
    jsr (resload_GetFileSize,a2)
    tst.l   d0
    beq.b   .nohigh
    
    lea highscores(pc),a0
    ; replace the default highscore table
    ; later copied in $140E
    lea $2E51E,a1   
    jsr (resload_LoadFile,a2)
.nohigh
    lea pl_2C000_intro(pc),a0
    lea $2C000,a1
    jsr resload_Patch(a2)
    movem.l (a7)+,d0-d1/a1-a2
    jmp $2C000
    
jump_2C000_multipart
    ; game doesn't have a keyboard interrupt
    ; neither it reads the keyboard in any way
    ; so there's no pause or quit
    pea keyboard_interrupt(pc)
    move.l  (a7)+,$68.W

    movem.l d0-d1/a1-a2,-(a7)
    move.l  _resload(pc),a2
    lea $2C000,a1
    cmp.w   #$5339,($3F84,a1)
    bne.b   .no_main
    lea pl_2C000_game(pc),a0
    jsr resload_Patch(a2)
    bra   .out
.no_main
    cmp.w   #$41F9,($370,a1)
    bne.b   .no_map
    lea pl_2C000_map(pc),a0
    jsr resload_Patch(a2)
    bra   .out
.no_map
    cmp.l   #$1400,($24,a1)
    bne.b   .no_after_intro
    lea pl_2C000_after_intro(pc),a0
    jsr resload_Patch(a2)
    bra   .out
.no_after_intro
    cmp.l   #$10194,($16,a1)
    bne.b   .no_subgame_items
    lea pl_2C000_subgame_items(pc),a0
    jsr resload_Patch(a2)
    bra   .out
.no_subgame_items
    cmp.l   #$554e4eb4,($156,a1)
    bne.b   .no_subgame_select
    lea pl_2C000_subgame_select(pc),a0
    jsr resload_Patch(a2)
    bra   .out    
.no_subgame_select
    cmp.l   #$10194,($1A,a1)
    bne.b   .no_subgame_lives
    lea pl_2C000_subgame_lives(pc),a0
    jsr resload_Patch(a2)
    bra   .out
.no_subgame_lives
    cmp.l   #$0c2d0018,($5c,a1)
    bne.b   .no_end_game
    lea pl_2C000_end_game(pc),a0
    jsr resload_Patch(a2)
    bra   .out
.no_end_game:
    nop

.out
    bsr _flushcache
    movem.l (a7)+,d0-d1/a1-a2
    jmp $2C000

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
    
pl_boot
    PL_START
    PL_PS  $6A,jump_400
    PL_P   $8A,jump_2C000_intro
	PL_END
    
pl_400
    PL_START
    PL_P  $336,read_sectors
    PL_P  $79a,write_track
    ;;PL_P  $754,read_track
    
    PL_P  $AB6,jump_2C000_multipart
    PL_PS $7E,read_file_hook
    ; skip floppy CIA shit
    PL_NOP  $40,6
    PL_R    $50
    PL_R    $220
    PL_R    $23E
	PL_END

pl_2C000_end_game:
    PL_START
    PL_ORW  $58,8   ; keyboard interrupt added
    PL_END
    
pl_2C000_intro:
    PL_START
    PL_IFC5
    PL_NOP  $10c,2
    PL_NOP  $116,2
    PL_ENDIF
    PL_END
    
pl_2C000_after_intro:
    PL_START
    PL_PSS  $22,init_1400_vars,2
    ; enable level 2 interrupt during title
    PL_ORW  $8A,8
    PL_END
    
pl_2C000_subgame_select:
    PL_START
    ;;PL_PS   $156,subgame_jump
    PL_PS   $1B8,subgame_subprog_patch
    PL_END
    
pl_2C000_map:
    PL_START
    ; fixes trashed display because double buffering
    ; bitplane switch happens in the middle of a frame
    ; on fast machines
    PL_PS   $370,wait_eof
    PL_END
    
pl_2C000_game:
    PL_START
    PL_IFC1X    0
    PL_NOP  $2FF84-$2C000,$6
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $312d6-$2C000,$10   ; shoes
    PL_NOP  $31300-$2C000,$10   ; earthquakes
    PL_NOP  $31398-$2C000,2     ; dog
    PL_NOP  $313a0-$2C000,6
    PL_ENDIF
    PL_IFC1X    2
    PL_NOP  $30036-$2C000,2
    PL_ENDIF
    
    PL_PSS  $3028e-$2C000,read_joy_button,2
    PL_IFC2
    PL_PSS  $30246-$2C000,read_joy_directions,2
    PL_ENDIF
    ; change copper-only interrupt to enable keyboard
    PL_PS    $2c082-$2C000,install_interrupts
    PL_PS    $31486-$2C000,install_interrupts
    ; no need to enable VBLANK, there's a busy loop
    PL_P    $317EA-$2C000,wait_vblank
    PL_END

pl_2C000_subgame_items:
    PL_START
    PL_PS   $14,jsr_10194
    
    PL_PSS  $2c246-$2C000,read_joy_button,2
    PL_IFC2
    PL_PSS  $2D3D4-$2C000,read_joy_directions_subitems,2
    PL_ENDIF
    PL_P    $2d55c-$2C000,wait_vblank
    
    ; enable keyboard interrupt (for pause)
    PL_ORW  $2c692-$2C000,8
    PL_END
    
pl_2C000_subgame_lives:
    PL_START
    PL_PS   $18,jsr_10194
    
    PL_PSS  $7e,read_joy_button,2

    PL_P    $2d382-$2C000,wait_vblank
    
    PL_PS   $412,jsr_10190
    
    ; enable keyboard interrupt (for pause)
    ;PL_ORW  $2c692-$2C000,8
    PL_END

pl_subgame_subprog:
    PL_START
    PL_L    $3c32a-$3C0D4,$70004E73 ; no VBR read (is it used?)
    ; enable keyboard interrupt (for pause)
    PL_ORW  $3c324-$3C0D4,8
    PL_END
    
pl_subgame_subprog_items:
    PL_START
    ; enable keyboard interrupt (for pause)
    PL_ORW  $103F2-$10190,8
    PL_END

HIGH_SCORE_TRACK = 25
TRACK_SIZE = $1600
    
; < A0: data to write
; < A1: MFM buffer???
; < D1: track number (not sector: D1*$1600 = offset)
; < D0: ??
; > D0: length written? return 1: OK

; 0000140E 594C 4CDA 1D4C 4A46 46DA 193C 414E 49DA  YLL..LJFF..<ANI.
; 0000141E 1388 4620 45DA 09C4 4B41 57DA 03E8   ..F E...KAW.....

;0000140E 594C 4CDA 1D4C 414E 49DA 1388 4620 45DA  YLL..LANI...F E.
;0000141E 09C4 4B41 57DA 03E8 4152 55DA 00FA   ..KAW...ARU.....

; I wanted to write the scores to disk but 1) that doesn't seem trivial
; what the interface is for this routine and 2) highscores are passed in A1
; and the length is $1E so a better solution is to write a separate file
; and read it at the proper moment at startup

write_track:
	MOVEM.L	D1-D7/A0-A6,-(A7)	;0b9a: 48e77ffe
    move.l  _trainer(pc),d0
    bne.b   .out
    cmp.l   #HIGH_SCORE_TRACK,d1
    bne.b   .unsupported
	MOVEA.L	_resload(PC),A2		;0c8: 247a0188  
    lea highscores(pc),a0
    move.l  #$1E,d0   ; size
	JSR	resload_SaveFile(A2)
.out
	MOVEM.L	(A7)+,D1-D7/A0-A6
    moveq.l #1,d0
    rts
.unsupported
    ; should not happen
    ILLEGAL
    ILLEGAL
   
subgame_subprog_patch
    ; code is in 3c0d4
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    lea pl_subgame_subprog(pc),a0
    lea $3c0d4,a1
    jsr resload_Patch(a2) ; Temp, to log in filelog
    movem.l (a7)+,d0-d1/a0-a2   
	LEA	$2c7c6,A0		;2c1b8: 41f9000
    rts

jsr_10190
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    lea pl_subgame_subprog_items(pc),a0
    lea $10190,a1
    jsr resload_Patch(a2) ; Temp, to log in filelog
    movem.l (a7)+,d0-d1/a0-a2   
    jmp $10190
    
jsr_10194
    bsr _flushcache
    jmp $10194

read_file_hook
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    jsr resload_GetFileSize(a2) ; Temp, to log in filelog
    movem.l (a7)+,d0-d1/a0-a2   
    rts
    
init_1400_vars
    clr.l   $1400
    move.l  _level(pc),d0
    mulu.w  #5,d0
    add.l  _sublevel(pc),d0
    move.b  d0,$1401
    move.b  d0,$1402
    rts
    
install_interrupts:
;    pea keyboard_interrupt(pc)
;    move.l  (a7)+,$68.W
    MOVE.W	#$8018,152(A6)		;2c082: 3d7c80100098
    rts

wait_eof
    ; make sure that beam position is low enough
    ; else map display is trashed depending on CPU speed
    move.l  d1,a0
.wait
	move.l	$dff004,d1
	and.l	#$1ff00,d1
	cmp.l	#300<<8,d1
	bne.b	.wait
    move.l  a0,d1
    lea $2CBB2,a0   ; original
    rts
 
wait_vblank
    ; A6 = DFF002
    movem.l d1/a0,-(a7)
.wait
	MOVE.W	intreqr-2(A6),D0		;317ea: 302e001c
	BTST	#5,D0			;317ee: 08000005
	BEQ.S	.wait		;317f2: 67f6
    ; read joystick at start of vblank interrupt
    lea joy1_prev_buttons(pc),a0
    move.l  joy1(pc),d1
    move.l  d1,(a0)
    
	moveq	#1,d0
	bsr	_read_joystick
    
	lea	joy1(pc),a0
	move.l	d0,(a0)
    
    ; quit to wb ?
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .no_quitwb
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .no_quitwb
    btst    #JPB_BTN_YEL,d0
    bne     _exit
    
.no_quitwb
    ; pause ?
    btst    #JPB_BTN_PLAY,d0
    beq.b   .no_play
    btst    #JPB_BTN_PLAY,d1
    bne.b   .no_play
    ; just pressed
    lea pause_flag(pc),a0
    bchg  #0,(a0)
.no_play:
    move.b  pause_flag(pc),d0
    bne.b   .wait

    movem.l (a7)+,d1/a0
    
	MOVE.W	#$0020,intreq-2(A6)		;317f4: 3d7c0020009a
	RTS				;317fa: 4e75


keyboard_interrupt
	movem.l	D0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here

    cmp.b   _keyexit(pc),d0
    beq   _exit

    cmp.b   #$19,d0     ; P: pause
    bne.b   .nopause
    movem.l a0,-(a7)
    lea pause_flag(pc),a0
    bchg    #0,(a0)     ; toggle
    movem.l (a7)+,a0
.nopause
	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a5
	move.w	#8,$dff09c
	rte


; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
    
read_joy_directions_subitems
    movem.l d2,-(a7)
    movem.l d0/a0,-(a7)
    move.l  joy1(pc),d0
	move.w	$DFF00C,D2
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,D2
	btst	#9,D2
	beq.b	.noneed
	bset	#8,D2	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,D2
	btst	#9,D2
	bne.b	.no_blue
	bset	#8,D2	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	movem.l	(a7)+,d0/a0
;;	MOVE.B	D2,D1		;3024a: 122e000b
    lsr.w   #8,d2
	MOVE.B	D2,D0		;30246: 102e000a
	ANDI.B	#$03,D0			;2d3d8: 02000003
    movem.l (a7)+,d2
    rts


read_joy_directions
    movem.l d2,-(a7)
    movem.l d0/a0,-(a7)
    move.l  joy1(pc),d0
	move.w	$DFF00C,D2
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,D2
	btst	#9,D2
	beq.b	.noneed
	bset	#8,D2	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,D2
	btst	#9,D2
	bne.b	.no_blue
	bset	#8,D2	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	movem.l	(a7)+,d0/a0
	MOVE.B	D2,D1		;3024a: 122e000b
    lsr.w   #8,d2
	MOVE.B	D2,D0		;30246: 102e000a
    movem.l (a7)+,d2
    rts
    
read_joy_button
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts
    
    
read_joy_button_2

; < D0: sector number
; < D1: size
; < A1: destination
read_sectors:
    movem.l d0-d2/a0-a3,-(a7)
    move.l  a1,a0       ; this is destination
	moveq.L	#1,D2		; disk 1
    and.l   #$FFFF,d0
    and.l   #$FFFF,d0
    lsl.l   #8,d0
    add.l   d0,d0       ; sector number * 512 = offset
	MOVEA.L	_resload(PC),A2		;0c8: 247a0188    
	JSR	resload_DiskLoad(A2)
    movem.l (a7)+,d0-d2/a0-a3
    moveq.l #0,d0   ; clear N flag

    rts
    
_resload
    dc.l    0
_tag
        dc.l	WHDLTAG_CUSTOM3_GET
_level	dc.l	0
		dc.l	WHDLTAG_CUSTOM4_GET
_sublevel	dc.l	0
    dc.l   WHDLTAG_CUSTOM1_GET
_trainer
    dc.l    0
	dc.l	0	; END    
_bootprg:
    incbin  "smarty5000.bin"
    even
joy1_prev_buttons
    dc.l    0
pause_flag
    dc.b    0
highscores
    dc.b    "highs",0
    even


        
    