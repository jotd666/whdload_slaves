	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


_base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError	;ws_flags
		dc.l	$200000
		dc.l	$0		;ws_ExecInstall
		dc.w	_start-_base	;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem
		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config

		dc.b	"BW;"
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C1:X:Trainer Infinite Energy:1;"
        dc.b    "C2:X:CD32 original joypad controls:0;"
        dc.b    "C3:X:Show penguin advert:0;"
		dc.b	0
		
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
_data		dc.b	'data',0
_name		dc.b	"James Pond 3 - Operation Starfish"
	dc.b	0
_copy		dc.b	"1994 Millenium",0
_info		dc.b	"Adapted by Bored Seal & JOTD",10,10
			dc.b	"Thanks to Walter Gierholz for supplying the original disks",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even
		;dc.b	'$VER: James Pond 3 AGA HD V1.0 (6-May-99) by Bored Seal',0,0
		even

	include	ReadJoyPad.s

; CD32
SAVELEN = 168
DATALEN = SAVELEN+$40
BOOT_ADDRESS = $80000


_start		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
	bsr	_detect_controller_types

		move.l	_resload(pc),a2
		lea	code_floppy(pc),a0			;load game data and unpack
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		bne	_floppy
_cd32
	lea	$1FF000,A7
	move.w	#$2700,SR
		
	move.l	_resload(pc),a2
	lea	(tag,pc),a0
	jsr	(resload_Control,a2)
	
	lea	BOOT_ADDRESS,a1
	lea	loadername(pc),A0
	jsr	resload_LoadFileDecrunch(a2)

	lea	BOOT_ADDRESS,a1
	lea	pl_boot(pc),a0
	jsr	resload_Patch(a2)


	jmp	BOOT_ADDRESS+$88


pl_boot:
	PL_START
	PL_W	$CA,$6010
	PL_P	$10E,PatchGame

	;;PL_STR0  $42DF,<    adapted by JOTD    >
	PL_STR0  $42FA,<      adapted by JOTD      >
	;;PL_STR0  $42FA,<    Look out for other prods>
	PL_END
	
PatchGame
	movem.l	d0-d1/a0-a2,-(a7)
	sub.l	a1,a1
	lea	pl_game(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	d0-d1/a0-a2,-(a7)
	jmp	$100.W
	
pl_game:
	PL_START
	PL_W	$174,$601A
	PL_PS	$1B2,read_file
	PL_PS	$1EA,read_file
	PL_P	$20A,patch_main
	PL_END

read_file:
	tst.w	D0
	bne	.exit
	movem.l	d1/a0-a2,-(a7)


	move.l	_resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)
	
	movem.l	(a7)+,d1/a0-a2
.exit
	moveq.l	#0,D0
	rts
patch_main
	move.l	buttonwait(pc),d0
	beq.b	.nobw
.loop
	btst	#6,$bfe001
	beq.b	.out
	btst	#7,$bfe001
	beq.b	.out
	bra.b	.loop
.out	
.nobw
	
	sub.l	a1,a1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$11CC00
	
SPAC = $53504143

pl_main
	PL_START
	PL_IFC1X    0
    PL_NOP  $135b42,4
    PL_B    $135b46,$60
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $135a36,4
    PL_B    $135a3a,$60
    PL_ENDIF
    
	PL_P	$112000,read_file
	
	PL_PS	$143BF4,SaveOk
	PL_PS	$143C38,SaveOk

	PL_PS	$139736,start_with_most_buttons
	; *** installs kb patch
	PL_PS	$13972E,kbread
	; changes read joypad routine so
	; - it's 2-button joystick compatible
	; - it can redirect "up" to jump if needed
	; - it can use keys to emulate joypad
	; - we can quit with rev+fwd+play
	PL_PS	$139878,emulate_joypad_controls
	; skip the whole original joypad read, store D0 result
	PL_S	$139878+6,$1398f6-$139878-6
	; start with yellow button (now that fire has been remapped
	; to yellow, so we can start the game with red
	PL_IFC2
	PL_ELSE
	

	; *** changes START into SPACE
	PL_STR	$11F9FF,<SPACE>
	PL_STR	$11FB3B,<SPACE>
	PL_STR	$12013C,<SPACE>

;	PL_L	$11F9FF,SPAC
;	PL_B	$11F9FF+4,$45
;	PL_L	$11FB3B,SPAC
;	PL_B	$11FB3B+4,$45
;	PL_L	$12013C,SPAC
;	PL_B	$12013C+4,$45

	; *** changes YELLOW into FIRE in pause menu

	PL_STR	$120110,<*ESC* TO RETRY AREA >
	PL_ENDIF
	
	; *** reinstalls my exception handler

;;;	PL_P	$15A866,RestoreTraps

	; *** $144708: load game (low level)
	; *** $14477C: save game (low level)

	; *** we save at a higher level
	; *** in and from RAM:

	PL_P	$143F9A,LoadGame
	PL_P	$143FBA,SaveGame

	; *** to be able to load scores

	PL_PS	$143C16,GetScore
	PL_PS	$135806,ClearScore

	; *** decrunch in fastmem (fake PP20 file)

	PL_P	$139660,Decrunch
	
	PL_IFC3
	
	PL_ELSE
	; skip the unskippable penguin add
	PL_NOP	$0011F970,6
	
	PL_ENDIF
	PL_END
	
start_with_most_buttons:
	btst	#7,$bfe001
	beq.b	.start
	btst	#5,d0
	beq.b	.nofire
.start
	bset	#6,d0	; simulates green which starts game
.nofire
	; original
	MOVE.B	D0,$76c4.W
	RTS
	

; < D0: numbers of vertical positions to wait

; < D0: joypad status. The bits aren't the same as normal joypad
; we can scratch A0, D1, D2 as game already preserves them

; if 2 button joystick set, yellow becomes fire
; space toggles run by simulating forward

emulate_joypad_controls
	moveq	#1,d0
	bsr	_read_joystick
	; Play+Forward+Reverse 	- Quit
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noquit
	btst	#JPB_BTN_GRN,d0
	beq.b	.nolskip
	bsr	skip_level_cd32
.nolskip    
    
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
	btst	#JPB_BTN_YEL,d0
	beq.b	.noquit
	bra	_exit
.noquit
	move.b	$BFEC01,d1
	ror.b	#1,d1
	not.b	d1
	lea	space_pressed(pc),a0
	cmp.b	#$40,d1
	bne.b	.nospace
	tst.b	(a0)
	bne.b	.notfirstspacepress	; already pressed: ignore
	st.b	(a0)
	lea	run_mode(pc),a0
	eor.b	#1,(a0)		; toggle run
	bra.b	.notfirstspacepress
.nospace
	clr.b	(a0)
.notfirstspacepress
	cmp.b	#$60,d1
	bne.b	.noshift
	bset	#JPB_BTN_GRN,d0
.noshift
	cmp.b	#$45,d1
	bne.b	.noesc
	bset	#JPB_BTN_YEL,d0
.noesc
	cmp.b	#$19,d1
	bne.b	.nopause
	bset	#JPB_BTN_PLAY,d0
.nopause
	move.b	run_mode(pc),d2
	beq.b	.norun
	bset	#JPB_BTN_FORWARD,d0
.norun
	move.b	controller_joypad_1(pc),d2
	bne.b	.real_joypad
	; non-joypad: red becomes yellow
	btst	#JPB_BTN_RED,d0
	beq.b	.real_joypad
	bclr	#JPB_BTN_RED,d0
	bset	#JPB_BTN_YEL,d0
.real_joypad
	move.l	joypad_controls(pc),d2
	bne.b	.nothing_to_do
	; joystick controls: we're going to check "up" and trigger
	; blue button if set
	btst	#JPB_BTN_BLU,d0
	beq.b	.noblu
	; blue button: cancel it, enable green instead (run)
	bclr	#JPB_BTN_BLU,d0
	bset	#JPB_BTN_GRN,d0	
.noblu
	btst	#JPB_BTN_RED,d0
	beq.b	.nored
	; also activate to yellow
	bset	#JPB_BTN_YEL,d0	
.nored
	btst	#JPB_BTN_UP,d0
	beq.b	.nothing_to_do
	bset	#JPB_BTN_BLU,d0	
.nothing_to_do:

	; convert to game bitset
	lsr.l	#8,d0
	lsr.l	#8,d0
	lsr.l	#1,d0
	rts
	
;        JPB_BTN_PLAY	= $11
;        JPB_BTN_REVERSE	= $12
;        JPB_BTN_FORWARD	= $13
;        JPB_BTN_GRN	= $14
;        JPB_BTN_YEL	= $15
;        JPB_BTN_RED	= $16
;        JPB_BTN_BLU	= $17
; return status match with a small shift (9 bits), normal: it's
; the same routine...
;
; blue:   $4000
; red:    $2000
; yellow: $1000
; green:  $0800
; fwd:    $0400
; rev:    $0200
; pause:  $0100


	
emubut2:
	move.w	$DFF016,D2
	move.l	D0,-(sp)
	move.b	but3emu(pc),D0
	bne	.flash
	btst	#14,D2
	bne	.noflash
	bset	#14,D2		; clears 2nd button
.flash
	ori.b	#$40,D4		; emulates 3rd button
.noflash
	move.b	but2emu(pc),D0
	beq	.nospace
	bclr	#14,D2		; emulates 2nd button
.nospace
	btst	#7,$BFE001	; fire pressed
	bne	.nofire
	ori.b	#$20,D4		; emulates yellow button (fight+quit when pause)
.nofire

	move.l	(sp)+,D0
	rts

kbread:
	movem.l	d0/d1/a0/a5,-(a7)
	LEA	$00BFD000,A5		; cia-a base
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.out
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
	
	move.l	d0,d1	
	BSET	#$06,$1E01(A5)
	moveq.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key
	move.l	d1,d0
	
	lea	but2emu(pc),A0
	clr.b	(A0)

	cmp.b	#$4E,D0		; ->
	bne	.notadvlev

	cmp.b	#$2B,$29A9.W
	bcc	.nospace	; >=$2B -> skip

	addq.b	#1,$29A9.W
	addq.b	#1,$29AB.W

	bra	.nospace


.notadvlev
	cmp.b	#$4F,D0		; <-
	bne	.notrevlev

	tst.b	$29A9.W
	beq	.nospace	; =0 -> skip

	subq.b	#1,$29A9.W
	subq.b	#1,$29AB.W


	bra	.nospace
.notrevlev

	cmp.b	#$40,D0		; SPACE pressed?
	bne	.nospace

	st.b	(A0)
.nospace

	cmp.b	#$44,D0		; RETURN pressed?
	bne	.noret

	bsr	skip_level_cd32
.noret

	cmp.b	_keyexit(pc),D0
	beq	_exit
.out
	movem.l	(a7)+,d0/d1/a0/a5

	move.w	$DFF00C,D0	; original game
	rts

skip_level_cd32
	st.b	$7FA6		; completes level
	st.b	$7C8A		; completes level
	clr.b	$7B1F		; no revisit
	st.b	$7BC5		; allow save
	rts
	
SaveOk:
	movem.l	D1-D2,-(sp)
	move.w	$DFF000+joy1dat,D1
	move.w	D1,D2
	lsr.w	#1,D1
	eor.w	D2,D1

	btst	#8,D1
	movem.l	(sp)+,D1-D2
	bne	up

	lea	$9E954,A0
	rts			; fire pressed: do save/load
up:
	lea	4(A7),A7
	jmp	$143BB0

ClearScore:
	movem.l	a0,-(a7)
	lea	GameLoaded(pc),a0
	tst.b	(a0)
	bne	.sk
	clr.l	$7F78.L		; clear score on beginning of game
.sk
	clr.b	(a0)
	movem.l	(a7)+,a0
	rts

GetScore:
	movem.l	D0/A1,-(sp)
	moveq	#0,D0
	move.w	$807E,D0
	lea	scorebuffer(pc),A1
	add.l	d0,d0
	add.l	d0,d0
	move.l	(A1,D0.L),$7F78.W	; restore score

	lea	GameLoaded(pc),a1
	st.b	(a1)		; to tell not to clear the score

	movem.l	(sp)+,D0/A1
	JMP	$143972		; original game

LoadGame:
	movem.l	A0-A1,-(sp)
	lea	savebuffer(pc),A0
	lea	$9E954,A1
	move.b	#SAVELEN-1,D0
.copy
	move.b	(A0)+,(A1)+
	dbf	D0,.copy
	movem.l	(sp)+,A0-A1

	moveq.l	#0,D0		; always OK
	tst.l	D0
	rts

SaveGame:
	movem.l	A0-A1,-(sp)	
	lea	savebuffer(pc),A1
	lea	$9E954,A0
	move.b	#SAVELEN-1,D0
.copy
	move.b	(A0)+,(A1)+
	dbf	D0,.copy

	moveq.l	#0,D0
	move.w	$807E,D0	; # of save

	lea	scorebuffer(pc),A1
	add.l	d0,d0
	add.l	d0,d0
	move.l	$7F78.W,(A1,D0.L)

	bsr	WriteSaves

	movem.l	(sp)+,A0-A1

	moveq.l	#0,D0		; always OK
	tst.l	D0
	rts
	
ReadSaves:
	movem.l	D0-D1/A0-A2,-(A7)
	lea	savename(pc),A0
	lea	savebuffer(pc),A1
	move.l	_resload(pc),a2
	jsr	(resload_LoadFile,a2)
	movem.l	(a7)+,D0-D1/A0-A2
	rts

WriteSaves:
	movem.l	D0-D1/A0-A2,-(A7)
	lea	savename(pc),A0
	lea	savebuffer(pc),A1
	move.l	#DATALEN,D0		; size
	move.l	_resload(pc),a2
	jsr	(resload_SaveFile,a2)
	movem.l	(a7)+,D0-D1/A0-A2
	rts


_exit
		pea	TDREASON_OK
        move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
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
			
_floppy:
		lea	code_floppy(pc),a1			;load game data and unpack
		lea	$11c400,a2		;no need to load boot tracks
		bsr	LoadFile
		move.l	a2,a0
		lea	$11c800,a1
		bsr	Decrunch
		
		lea	data(pc),a1
		lea	$31d2c,a2
		bsr	LoadFile
		move.l	a2,a0
		lea	$3212c,a1
		bsr	Decrunch

		move.l	_resload(pc),a2
		sub.l	a1,a1
		lea	pl_floppy(pc),a0
		jsr	resload_Patch(a2)
		jmp	$11c800

pl_floppy
	PL_START
	PL_IFC1X    0
    PL_NOP  $1359C0,4       ; lives: 07d39
    PL_B    $1359C4,$60
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $1358b4,4
    PL_B    $1358b8,$60
    PL_ENDIF

    PL_PS   $11c9c8,_quit_test
    
	PL_PS	$1593ac,GetFileSize
	PL_W	$1593b8,$600a
	PL_R	$15a8fe		;remove disk check
	PL_P	$15a944,LoadFiles
	PL_P	$143f04,LoadSaves
	PL_P	$143fde,SaveSaves
	PL_P	$1392fe,Decrunch
	PL_PS	$125806,Fix
	
    PL_PS   $11c95e,vbl_hook
    PL_S    $11c964,$90-$64 ; skip debugger trigger code
    
    PL_IFC2
    PL_PS   $13e2bc,ingame_hook
    PL_PS   $13945a,test_joy_fire_1
    PL_PS   $13946e,test_joy_fire_RED
    PL_PS   $1393b8,test_joy_directions
    PL_ELSE
    PL_PS   $13945a,test_joy_fire_RED
    PL_PS   $13946e,test_joy_fire_BLU
    PL_ENDIF
    
    ;;PL_PS   $1394ca,pause_test_floppy
    PL_NOP  $139466,8       ; set POTGO
    PL_NOP  $139480,8       ; reset POTGO
    
	PL_IFC3
	
	PL_ELSE
	; skip the unskippable penguin add
	PL_NOP	$11f5dc,12
	PL_ENDIF
	
	PL_END

ingame_hook
    move.l  a0,-(a7)
    lea ingame_flag(pc),a0
    st.b    (a0)
    move.l  (a7)+,a0
    CMP.W	$7678.W,D1		;13e2bc: b2790000
    rts
    
pause_test_floppy
    CMPI.B	#$19,D4
    beq.b   .branch
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    movem.l	(a7)+,d0
    beq.b   .nobranch
    move.w  #$F00,$DFF180
.branch
    add.l   #$e6-$d0,(a7)   ; pause
.nobranch
    rts
    
test_joy_directions
	MOVE.W	_custom+joy1dat,D0		;1393b8: 303900dff00c
    move.b  ingame_flag(pc),d1
    beq.b   .not_in_game    ; from menu: don't redirect up
    
    move.l  joy1(pc),d1
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,D0
	btst	#9,D0
	beq.b	.noneed
	bset	#8,D0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,D0
	btst	#9,D0
	bne.b	.no_blue
	bset	#8,D0	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
.not_in_game:
    ; reset the flag
    move.l  a0,-(a7)
    lea ingame_flag(pc),a0
    clr.b    (a0)
    move.l  (a7)+,a0
    rts
    
TEST_JOY_FIRE:MACRO
test_joy_fire_\1:
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_\1,d0
    movem.l (a7)+,d0
    rts
    ENDM
    
    TEST_JOY_FIRE   YEL
    TEST_JOY_FIRE   BLU
    TEST_JOY_FIRE   RED

test_joy_fire_1
    movem.l d0,-(a7)
    move.b  ingame_flag(pc),d0
    bne.b   .ingame
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts
    
.ingame
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_YEL,d0
    movem.l (a7)+,d0
    rts

FLOPPY_CURRENT_KEY = $80BD
vbl_hook
	moveq	#1,d0
    movem.l d1,-(a7)
	bsr	_read_joystick
    movem.l (a7)+,d1
    lea joy1(pc),a0
    move.l  d0,(a0)
    ; skip level forward+grn
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noquit
	btst	#JPB_BTN_GRN,d0
	beq.b	.nolskip
	bsr	skip_level_floppy
.nolskip
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
    move.b  #$45,FLOPPY_CURRENT_KEY      ; ESC
    
	; Yellow+Forward+Reverse 	- Quit

	btst	#JPB_BTN_YEL,d0
	beq.b	.noquit
	bra	_exit
.noquit
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause
    move.b  #$19,FLOPPY_CURRENT_KEY
.nopause
	rts
    
skip_level_floppy
	st.b	$7f9a		; completes level
	st.b	$7c7e		; completes level
	clr.b	$7b13		; no revisit
	st.b	$7bb9		; allow save
	rts

; quit key with 68000
_quit_test:
    MOVE.B	D0,FLOPPY_CURRENT_KEY
    cmp.b   _keyexit(pc),d0
    beq _exit
	cmp.b	#$44,D0		; RETURN pressed?
	bne	.noret

	bsr	skip_level_floppy
.noret

    rts
    
	
Fix		move.l	d0,-(sp)		;24bit adressing fix
		move.l	a2,d0
		and.l	#$00FFFFFF,d0
		move.l	d0,a2
		move.l	(sp)+,d0
		move.b	$299a,d6
		rts


LoadFiles	bsr	LoadFile		;game files loader
		clr.b	$14(a0)			;this adress must be 0 = ok result
		rts

LoadSaves	lea	saves(pc),a1		;load game position - emulation
		bsr	GetFileSize		;is there already savegame file?
		tst.l	d1
		beq	CreateSaves		;if no -> create it
		lea	$9e954,a2		;if yes -> load savegame into memory
LoadFile	movem.l d0-d6/a0-a2,-(sp)
		move.l	a1,a0
		move.l	a2,a1
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFile,a2)
		movem.l	(sp)+,d0-d6/a0-a2
		rts

CreateSaves	jsr	$143f92			;create blank savegames
		jsr	$143CDC			;with game routines
		bra	SaveSaves		;and save it

SaveSaves	movem.l	d0/a0-a2,-(sp)
		move.l	#$AFF,d0
		lea	saves(pc),a0
		lea	$9e954,a1
		movea.l	(_resload,pc),a2
		jsr	(resload_SaveFile,a2)
		movem.l	(sp)+,d0/a0-a2
		move.b	#1,$7b47		;yes, save done
		rts

GetFileSize	movem.l	d0/a0-a2,-(sp)
		move.l	a1,a0
		move.l  (_resload,pc),a2
		jsr     (resload_GetFileSize,a2)
		move.l	d0,d1
		movem.l	(sp)+,d0/a0-a2
		rts

Decrunch:
	MOVEM.L	D1-D7/A0-A5,-(A7)	;00: 48E77FFC
	PEA	dec_0011(PC)		;04: 487A00AC
	LEA	4(A0),A4		;08: 49E80004
	ADDA.L	(A0),A0			;0C: D1D0
	MOVEA.L	A1,A3			;0E: 2649
	MOVEQ	#3,D6			;10: 7C03
	MOVEQ	#1,D4			;12: 7801
	MOVEQ	#7,D7			;14: 7E07
	MOVEQ	#1,D5			;16: 7A01
	MOVEA.L	A3,A2			;18: 244B
	MOVE.L	-(A0),D1		;1A: 2220
	TST.B	D1			;1C: 4A01
	BEQ.S	dec_0000		;1E: 6706
	BSR.S	dec_0004		;20: 612A
	SUB.L	D4,D1			;22: 9284
	LSR.L	D1,D5			;24: E2AD
dec_0000:
	LSR.L	#8,D1			;26: E089
	ADDA.L	D1,A3			;28: D7C1
	MOVEA.L	D1,A5			;2A: 2A41
dec_0001:
	BSR.S	dec_0004		;2C: 611E
	BCS.S	dec_000B		;2E: 653E
	MOVEQ	#0,D2			;30: 7400
dec_0002:
	MOVE	D4,D0			;32: 3004
	BSR.S	dec_0007		;34: 6124
	ADD	D1,D2			;36: D441
	CMP	D6,D1			;38: B246
	BEQ.S	dec_0002		;3A: 67F6
dec_0003:
	MOVEQ	#7,D0			;3C: 7007
	BSR.S	dec_0007		;3E: 611A
	MOVE.B	D1,-(A3)		;40: 1701
	DBF	D2,dec_0003		;42: 51CAFFF8
	CMPA.L	A3,A2			;46: B5CB
	BCS.S	dec_000B		;48: 6524
	RTS				;4A: 4E75
dec_0004:
	LSR.L	D4,D5			;4C: E8AD
	BEQ.S	dec_0005		;4E: 6702
	RTS				;50: 4E75
dec_0005:
	MOVE.L	-(A0),D5		;52: 2A20
	ROXR.L	D4,D5			;54: E8B5
	RTS				;56: 4E75
dec_0006:
	SUB	D4,D0			;58: 9044
dec_0007:
	MOVEQ	#0,D1			;5A: 7200
dec_0008:
	LSR.L	D4,D5			;5C: E8AD
	BEQ.S	dec_000A		;5E: 6708
dec_0009:
	ROXL.L	D4,D1			;60: E9B1
	DBF	D0,dec_0008		;62: 51C8FFF8
	RTS				;66: 4E75
dec_000A:
	MOVE.L	-(A0),D5		;68: 2A20
	ROXR.L	D4,D5			;6A: E8B5
	BRA.S	dec_0009		;6C: 60F2
dec_000B:
	MOVE	D4,D0			;6E: 3004
	BSR.S	dec_0007		;70: 61E8
	MOVEQ	#0,D0			;72: 7000
	MOVE.B	0(A4,D1.W),D0		;74: 10341000
	MOVE	D1,D2			;78: 3401
	CMP	D6,D2			;7A: B446
	BNE.S	dec_000E		;7C: 6616
	BSR.S	dec_0004		;7E: 61CC
	BCS.S	dec_000C		;80: 6502
	MOVEQ	#7,D0			;82: 7007
dec_000C:
	BSR.S	dec_0006		;84: 61D2
	MOVE	D1,D3			;86: 3601
dec_000D:
	MOVEQ	#2,D0			;88: 7002
	BSR.S	dec_0007		;8A: 61CE
	ADD	D1,D2			;8C: D441
	CMP	D7,D1			;8E: B247
	BEQ.S	dec_000D		;90: 67F6
	BRA.S	dec_000F		;92: 6004
dec_000E:
	BSR.S	dec_0006		;94: 61C2
	MOVE	D1,D3			;96: 3601
dec_000F:
	ADD	D4,D2			;98: D444
dec_0010:
	MOVE.B	0(A3,D3.W),-(A3)	;9A: 17333000
	MOVE	D3,-(A7)		;9E: 3F03
	ANDI	#$000F,D3		;A0: 0243000F
	MOVE	(A7)+,D3		;A4: 361F
	DBF	D2,dec_0010		;A6: 51CAFFF2
	CMPA.L	A3,A2			;AA: B5CB
	BCS	dec_0001		;AC: 6500FF7E
	RTS				;B0: 4E75
dec_0011:
	MOVE.L	A5,D0			;B2: 200D
	MOVEM.L	(A7)+,D1-D7/A0-A5	;B4: 4CDF3FFE
	RTS				;B8: 4E75



; cd32
tag		dc.l	WHDLTAG_BUTTONWAIT_GET
buttonwait:		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
trainer	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
joypad_controls
		dc.l	0
		dc.l	0
scorebuffer:
	ds.l	$10,0
but2emu:
	dc.l	0
but3emu:
	dc.l	0
_resload
	dc.l	0
	cnop	0,4
savebuffer:
	ds.b	SAVELEN,0
space_pressed
	dc.b	0
run_mode
	dc.b	0

loadername:
	dc.b	"Loader",0
progname:
	dc.b	"Code.bin",0
savename:
	dc.b	"jp3.sav",0
spacestr:
	dc.b	"SPACE",0
reloc_name:
	ds.b	$30,0
GameLoaded:
	dc.b	0
ingame_flag
    dc.b    0
    
; floppy
code_floppy		dc.b	'CODE',0
data		dc.b	'DATA',0
saves		dc.b	'SAVEGAME',0