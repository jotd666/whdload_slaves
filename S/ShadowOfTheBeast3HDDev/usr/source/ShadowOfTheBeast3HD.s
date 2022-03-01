;*---------------------------------------------------------------------------
;  :Program.	Beast3.asm
;  :Contents.	Slave for "Shadow Of The Beast 3" from Psygnosis
;  :Author.	Mr.Larmer of Wanted Team / JOTD / StingRay
;  :History.	10.12.99
;		02.12.00 - by Galahad: intro patched (only ntsc version)
;               01.10.01 - by Bored Seal: intro patched for pal version, decrunch added
;		13.06.16 - by StingRay: 
;			   - code optimised
;			   - ByteKiller decruncher optimised and error check
;			     added
;			   - Bplcon0 color bit fixed (x4)
;			   - patch code converted to use patch lists
;			   - disk access in intro removed
;			   - byte write to volume register fixed (menu, levels
;			     game over)
;		15.06.16   - intro in PAL version works now, Galahad's loader
;			     was buggy and has been completely recoded!
;			   - "Insert Game Disk 1" screen disabled
;			   - Intro can be skipped with CUSTOM2
;       30.08.17  - by JOTD
;               - added CD32 pad controls
;               - added CD32/joystick auto detection routine to avoid button 2 => pause
;                 on 2-buttons joystick because of CD32 joypad read
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	PhxAss/Barfly/VASM
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;======================================================================



COMM_NONE = 0
COMM_PAUSE = 1
COMM_QUITGAME = 2
COMM_RESTART = 3

;DEBUG

; WHDLoad v18+ includes are not compatible with
; ASM-One/Pro so until I fix them this workaround must do

	IFEQ	1
	IFND	PL_IFC1

PL_IFC1		MACRO
		dc.w	1<<14+29
		ENDM
PL_IFC2		MACRO
		dc.w	1<<14+30
		ENDM
PL_ENDIF	MACRO
		dc.w	1<<14+40
		ENDM
	ENDC
	ENDC
	
; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM


	
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
	
base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		IFD	DEBUGSTING
		dc.w	_dir-base	; ws_CurrentDir
		ELSE
		dc.w	0		;ws_CurrentDir
		ENDC
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$58		;ws_keyexit = F9
_expmem:
		dc.l	0		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-base		;ws_config

_name		dc.b	'Shadow of the Beast 3'
			dc.b	0
_copy		dc.b	'1992 Psygnosis',0
_info		dc.b	'Installed and fixed by Mr.Larmer',10,10
		dc.b	'Joypad/2-button controls by JOTD',10
		dc.b	'Intro sequence fixed by StingRay',10
		dc.b	"Other fixes by StingRay",10,10
		dc.b	'Version '
		DECL_VERSION
		dc.b	-1
		dc.b	0

		IFD	DEBUGSTING
_dir		
		dc.b	"SOURCES:WHD_Slaves/Beast3/PAL",0
		ENDC

		even
_config
        dc.b    "BW;"
		dc.b	"C1:X:Infinite lives/retries:0;"
		dc.b	"C1:X:Enable original in-game keys:1;"
		dc.b	"C2:B:Enable second button for jump;"
		dc.b	"C4:B:Skip Intro;"
		dc.b	0

	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	0
	CNOP 0,2

IGNORE_JOY_DIRECTIONS	
	include	ReadJoyPad.s

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		move.l	a0,a2
		
		lea	_tags(pc),a0
		jsr	(resload_Control,a2)
		

		lea	$4000.w,A0
		moveq	#0,D0
		move.l	#$400,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		pea	Patch(pc)
		move.l	(A7)+,$128(A0)

		move.l	#$78004E75,$12C(A0)	; skip drive on

		move.w	#$4EF9,$26E(A0)
		pea	Load(pc)
		move.l	(A7)+,$270(A0)

		moveq.l #0,d0   ; exp start
		moveq.l #0,d1   ; exp size
        bsr _flushcache

		jmp	$C2(A0)

;--------------------------------

Patch	
    lea	PLBOOT(pc),a0		; stingray, 13-jun-2016: patch list!
	pea	$7c000
	move.l	(a7),a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts	


PLBOOT	PL_START
	PL_W	$136,$600a			; skip cache stuff
	
	PL_P	$242,Loader
	PL_P	$948,Decrunch			; relocate ByteKiller decruncher
	PL_P	$a30,Load2
	PL_R	$b40				; disable drive access
	PL_P	$dae,LoadDOS

    PL_IFBW
    PL_PSS $108,wait_ham,8

    PL_ENDIF
; fixes by stingray
	PL_ORW	$276+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$396+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$3b8+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$464+2,1<<9			; set Bplcon0 color bit

	PL_SA	$16c,$1e6			; skip "Insert Game Disk 1"

	PL_IFC4					
	PL_S	$142,6				; skip intro if CUSTOM4<>0
	PL_ELSE
	PL_PS	$142,Intro			; patch intro
	PL_ENDIF

	PL_END

wait_ham
.loop
	btst	#6,$bfe001
	beq.b	.out
	btst	#7,$bfe001
	beq.b	.out
	bra.b	.loop
.out
    ; I suppose clear copperlist colors
	MOVE.W	#$0000,2(A0)		;7c108: 317c00000002
	LEA	4(A0),A0		;7c10e: 41e80004
	DBF	D0,.out		;7c112: 51c8fff4
    rts
    
;--------------------------------

; all intro patches done by stingray, June 2016
; loader properly emulated, disk accesses disabled, full
; support for PAL and NTSC versions

Intro	lea	$8000,a1		; stingray, 13-jun-2016: patch list!
	lea	PLINTRO_PAL(pc),a0
	cmp.l	#$43faffbc,$42(a1)
	beq.b	.patch
	lea	PLINTRO_NTSC(pc),a0

.patch	move.l	a1,-(a7)
	move.l	_resload(pc),a2
	jmp	resload_Patch(a2)



PLINTRO_PAL
	PL_START
.O	= $3b00	; variables start $3b00 bytes before binary

	PL_SA	$4812-.O,$4828-.O	; skip drive access (drive on)
	PL_SA	$4830-.O,$4842-.O	; skip waiting for drive motor
	PL_SA	$484a-.O,$485c-.O	; don't step to track 0
	PL_R	$48ce-.O		; disable step
	PL_SA	$48ae-.O,$48b8-.O	; don't set side
	PL_PSA	$4912-.O,loadtrack,$4948-.O
	PL_SA	$4950-.O,$495c-.O	; fake DSKBLK interrupt
	PL_SA	$4964-.O,$4970-.O	; skip decoding pass 1
	PL_SA	$4976-.O,$4982-.O	; skip decoding pass 2
	PL_SA	$49a2-.O,$49cc-.O	; skip drive access
	PL_SA	$4988-.O,$4990-.O	; skip buggy "blitter busy" check
	PL_END


loadtrack
	move.l	#$1800,d1		; size
	move.w	$6d2(a5),d0		; track
	lsr.w	#1,d0
	mulu.w	d1,d0

	tst.w	$6ce(a5)		; side
	beq.b	.side1
	add.l	#80*$1800,d0
.side1


	move.l	$6d6(a5),a0		; destination
	add.l	d1,$6d6(a5)
	moveq	#1,d2
	move.l	_resload(pc),a2
	jmp	resload_DiskLoad(a2)



PLINTRO_NTSC
	PL_START
	PL_SA	$d7a,$d90		; skip drive access (drive on)
	PL_SA	$d98,$daa		; skip waiting for drive motor
	PL_SA	$db2,$dc4		; don't step to track 0
	PL_R	$e36			; disable step
	PL_SA	$e16,$e20		; don't set side
	PL_PSA	$e7a,loadtrack,$eb0
	PL_SA	$eb8,$ec4		; fake DSKBLK interrupt
	PL_SA	$ecc,$ed8		; skip decoding pass 1
	PL_SA	$ede,$eea		; skip decoding pass 2
	PL_SA	$f0a,$f2e		; skip drive access
	PL_SA	$ef0,$ef8		; skip buggy "blitter busy" check

	PL_SA	$3e,$52			; skip cache stuff
	PL_END


;--------------------------------


space_address = $29A


joypad_extra_controls:
	cmp.b	#$7F,space_address.W	; space pressed
	bne.b	.sksp
	lea	spaceemu(pc),A0
	tst.l	(A0)
	beq.b	.sksp
	clr.l	(A0)
	move.b	#$7E,space_address.W	; space released
.sksp

    move.l  joy_buttons(pc),d0
	tst.l	D0
	beq	int3_exit

	; ** alternate button: change weapon
	
    move.l  space_emu_bit(pc),d1
	btst	d1,D0
	beq.b	int3_exit

	lea	spaceemu(pc),A0
	move.l	#1,(A0)
	move.b	#$7F,space_address.W		; space pressed

int3_exit
	move.w	#$20,(intreq,A6)
	MOVEM.L	(A7)+,D2-D7/A0-A5	;07bd6: 4cdf3ffc
	MOVE.L	(A7)+,D1		;07bda: 221f
	MOVE.L	(A7)+,D0		;07bdc: 201f
	MOVEA.L	(A7)+,A6		;07bde: 2c5f
	RTE				;07be0: 4e73



joypad_meta_controls:
	cmp.b	#$7F,space_address.W	; space pressed
	bne.b	.sksp
	lea	spaceemu(pc),A0
	tst.l	(A0)
	beq.b	.sksp
	clr.l	(A0)
	move.b	#$7E,space_address.W	; space released
.sksp

    move.l  joy_buttons(pc),d0
	tst.l	D0
	beq	int3_exit
	lea	command(pc),A0

	; ** alternate button: change weapon
	
    move.l  space_emu_bit(pc),d1
	btst	d1,D0
	beq.b	.1

	lea	spaceemu(pc),A0
	move.l	#1,(A0)
	move.b	#$7F,space_address.W		; space pressed
	bra.b   int3_exit

	; ** start: pause
.1
	btst	#JPB_BTN_PLAY,D0
	beq.b	.2

	move.w	#COMM_PAUSE,(A0)
	bra.b	int3_exit

	; ** forward: cheat on
.2

	btst	#JPB_BTN_FORWARD,D0
	beq.b	.3
	btst	#JPB_BTN_REVERSE,D0
	beq.b	.3ok
	; BWD+FWD at the same time: quit game: TODO
	move.w	#COMM_QUITGAME,(A0)
	bra.b	int3_exit
.3ok
    move.l  cheat_bits(pc),d1
    btst    #1,d1
    beq.b   int3_exit
    ; only active when cheat keys are on
	move.b	#1,$2CB.W   ; cheat on
	bra	int3_exit

	; ** back: cheat off

.3
	btst	#JPB_BTN_REVERSE,D0
	beq.b	.4
	clr.b	$2CB.W
	bra	int3_exit

	; *** green+yellow: restart part
.4
	btst	#JPB_BTN_GRN,D0
	beq.b	.5
	btst	#JPB_BTN_YEL,D0
	beq.b	.5

	move.w	#COMM_RESTART,(A0)
	;bra	.exit
.5

    bra   int3_exit
    
JoyPatch:
	move.w	D0,-(sp)
.loop
	move.w	command(pc),D0
	bne.b	.action
.cont
	tst.b	($30E).W
	beq.b	.loop
	move.w	(sp)+,D0
	rts

.action
	move.w	A0,-(sp)
	lea	command(pc),A0
	clr.w	(A0)
	move.w	(sp)+,A0	

	cmp.w	#COMM_RESTART,D0
	beq.b	.rest

	cmp.w	#COMM_PAUSE,D0
	beq.b	.pause
	
	cmp.w	#COMM_QUITGAME,D0
	beq.b	.quitgame

	move.w	(sp)+,D0
	bra.b	.cont

.weapon
	move.w	(sp)+,D0
	jmp	($7E0C).W	

.pause
	move.w	(sp)+,D0
	jmp	($7DF4).W	
.rest
	move.w	(sp)+,D0
	jmp	($7E68).W
.quitgame
	move.w	(sp)+,D0
	jmp	($7E52).W	


;--------------------------------
Loader		lea	$70000,a0
		pea	Patch2(pc)
		move.l	(A7)+,$6C(a0)

		move.w	#$4EF9,$70(a0)
		pea	LoadPsyFile(pc)
		move.l	(sp)+,$72(a0)
		bsr	_flushcache
		jmp	(a0)

Patch2		cmp.b	#$11,$494.w
		beq.b	NTSC

		move.b	#$60,$48A.w	; skip region check using display mode (PAL or NTSC)
		move.l	#$4E714EF9,$6C0.w
		pea	Patch3_PAL(pc)
		move.l	(A7)+,$6C4.w

		move.w	#$4E75,$716.w	; drive off skip

		move.w	#$4EF9,$A5A.w
		pea	LoadPsyFile(pc)
		move.l	(sp)+,$A5C.w

		bra.w	game_patched


NTSC		move.w	#$4E71,$48A.w	; skip region check using display mode (PAL or NTSC)

		move.l	#$4E714EF9,$6C4.w
		pea	Patch3_NTSC(pc)
		move.l	(A7)+,$6C8.w

		move.w	#$4E75,$71A.w	; drive off skip

		move.w	#$4EF9,$A5E.w
		pea	LoadPsyFile(pc)
		move.l	(A7)+,$A60.w
		
game_patched
		pea	Patch_X(pc)
		move.l	(sp)+,$416.w

	move.w	#$6002,$42E.w	; skip set priv. viol. vector
		bsr	_flushcache
		jmp	$400.w

Patch_X
		; just before title screens (reflections / sotb title)
		movem.l	d0-d1/a0-a2,-(a7)
		lea	pl_post_intro(pc),a0
		lea	$70000,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		jmp	$7001a


pl_post_intro:
	PL_START
	PL_IFC4
	; skip reflections & sotb title screens
	PL_S	$15E,$23A-$15E		
	PL_ENDIF
	PL_END
_flushcache
	move.l	a2,-(sp)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(sp)+,a2
	rts
	
FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


Patch3_PAL:
	jsr	$702E0
	bra.b	go

Patch3_NTSC:
	jsr	$702E4
go	
    
	movem.l	D0-D1/A0-A2,-(a7)
    ; decide between cd32 joypad and joystick
	bsr	_detect_controller_types
    ; just in case of a third button joystick, set to green
    lea third_button_maps_to(pc),a0
    move.l  #JPF_BTN_GRN,(a0)

    ; force joystick
    ;lea controller_joypad_1(pc),a0
    ;clr.b   (a0)
   
    lea space_emu_bit(pc),a0
    move.l  second_button_jumps(pc),d0
    beq.b   .blujumps
    move.l  #JPB_BTN_GRN,(a0)
    bra.b   .patch
.blujumps
    move.l  #JPB_BTN_BLU,(a0)

.patch
	move.l	_resload(pc),a2
	lea	pl_main(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,D0-D1/A0-A2

	jmp	$256.W

; $67772 decrunch
pl_main
	PL_START

    ; Mr Larmer original patches
	PL_W	$857E,$6016	; drive off skip
	PL_R    $6A848	; drive off skip
	PL_P    $6B4A8,LoadPsyFile

	; *** remove a mask of the memory zone
	; *** which overrides some of the memory (jotd)
	PL_W	$4AFC,$6024
	
    ; wait on mission screen
    PL_PS   $6B39E,.wait_button 
	; *** installs the quit patch (jotd)

	PL_PS	$7BEE,kbint2

    PL_IFC1X    0
    PL_W    $758A,$4a38
    PL_ENDIF
    
	; *** activates the original cheat keys (jotd)
	; (in the key test routine)
    PL_IFC1X    1
	PL_NOP	$7D2C,2
	PL_ENDIF

	; *** patch for joypad (jotd)
    ; *** install joystick/joypad read


	PL_P	$7BD0,joypad_meta_controls
	PL_P	$7778,JoyPatch

    
    PL_PSS  $7bc0,read_fire,2

    PL_IFC2
    PL_PSS   $07b72,.vbl_hook_1,2
    PL_PS   $05c64,is_jump_because_up

    PL_ELSE
    PL_PSS  $07b72,.vbl_hook_2,2    
    PL_ENDIF
    
    
; stingray, 13-jun-2016
	PL_PS	$5632,.fixreplays
	PL_PS	$6a9f2,.fixreplay_gameover

	PL_END




.vbl_hook_1
	bsr.b	.read_joy
	bra	joypad_button_jump
.vbl_hook_2
	bsr.b	.read_joy
	bra	joypad_up_jump

.read_joy
    ; read once
	moveq.l	#1,D0	; port 1
	bsr	_read_joystick
.store
    lea joy_buttons(pc),a0
    move.l  d0,(a0)
    rts

  
.wait_button
    JSR $0000ad62
.loopw
	btst	#6,$bfe001
	beq.b	.out
	btst	#7,$bfe001
	beq.b	.outw
	bra.b	.loopw
.outw
    rts
    
.fixreplay_gameover
	pea	FixAudXVol(pc)
	move.w	#$4ef9,$b624
	move.l	(a7)+,$b624+2
	bsr	_flushcache
	jmp	$b000


.fixreplays
	move.l	$2e6.w,a0

	cmp.l	#$b000,a0
	bne.b	.out

	movem.l	d0/a0,-(a7)
	move.l	#$b62c,d0
	cmp.l	#$1b6e0003,$b62c
	beq.b	.fix
	move.l	#$b68a,d0
	cmp.l	#$1b6e0003,$b68a
	beq.b	.fix

.return	movem.l	(a7)+,d0/a0
	
	


.out	jmp	(a0)

.fix	move.l	d0,a0
	pea	FixAudXVol(pc)
	move.w	#$4ef9,(a0)+
	move.l	(a7)+,(a0)
	bsr	_flushcache
	bra.b	.return

is_jump_because_up
    ; when demo is running if we cancel the jump
    ; this leads to the character going off bounds
    ; and crashes the machine!! (remove the test
    ; for a good laugh)
    tst.b   $8e2
    bmi.b   .blu    
	movem.l	d1,-(a7)
	move.l	joy_buttons(pc),d1
    btst    #JPB_BTN_BLU,d1
    movem.l (a7)+,d1
    bne.b   .blu
    ; do nothing
    addq.l  #4,a7
    rts
.blu:
	MOVE.B	#$01,$29C.W ; original
    rts
    
    
joypad_up_jump:
    MOVE.W	joy1dat(A6),D0		;07b72: 302e000c    original
	BTST	#9,D0			;07b76: 08000009        original
    RTS

joypad_button_jump:
    MOVE.W	joy1dat(A6),D0		;07b72: 302e000c    original

	movem.l	d1,-(a7)
	move.l	joy_buttons(pc),d1

    ; if not on ladder:
    ; - second button emulates "up" so the character jumps
    ; - "up" is still active, because there's the case
    ;   where character is on the ground but is facing a ladder
    
    tst.b   $27D.W  ; on ladder?
	bne.b	.no_blue
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
;	bclr	#8,d1
;	btst	#9,d1
;	beq.b	.noneed
;	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
;.noneed
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,D0
	btst	#9,D0
	bne.b	.no_blue
	bset	#8,D0	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	movem.l	(a7)+,d1
    
	BTST	#9,D0			;07b76: 08000009        original
    RTS
    
    
read_fire
    movem.l d0,-(a7)
    move.l  joy_buttons(pc),d0
    not.l   d0  ; CIA fire has inverted logic
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts

kbint2:
	move.b	$BFEC01,D0
	move.l	D0,-(sp)
	ror.b	#1,D0
	not.b	D0
	cmp.b	_keyexit(pc),D0	; raw keycode for F5
	beq	_quit
	move.l	(sp)+,D0
	tst.b	$BFEC01
	rts

_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
	rts
	
LoadPsyFile	movem.l	d0-a6,-(a7)
		lea	Dir(pc),A1

		cmp.w	#5,D1
		bne.b	.skip

		move.l	#$3000,D0
		move.l	#$1000,D1

		move.l	A0,(A1)

		lea	DiskNr(pc),a1
		moveq	#2,d3
		cmp.l	#'f40'<<8,d2
		bne.b	.skip2
		moveq	#3,d3
.skip2
		move.w	d3,(a1)

		moveq	#0,d2
		move.w	(a1),D2

		bsr.w	_LoadDisk

		bra.b	.exit
.skip
		move.l	(A1),A2
		lea	$C00(A2),A3
		moveq	#0,D0
		moveq	#0,D1
		moveq	#0,D2
.loop
		movem.l	A0/A2,-(A7)
.loop2
		move.b	(A0)+,D0
 		move.b	(A2)+,D1
		cmp.b	D0,D1
		bne.b	.next
		tst.b	D0
		bne.b	.loop2
		bra.b	.ok
.next
		movem.l	(A7)+,A0/A2
		addq.b	#1,D2
		lea	$10(A2),A2
		bra.b	.loop
.ok
		movem.l	(A7)+,A0/A2

		move.l	$24(A7),A0		;dest

		move.l	#$400,D1		; track length

		move.l	$C(A2),D3		; file length
		lea	(A3),A4

		cmp.l	D1,D3
		blo.b	.loop5
		sub.l	D1,D3
		bra.b	.loop3
.loop5
		move.l	d3,d1
		moveq	#0,d3
.loop3
		cmp.b	(A4)+,D2		; search file number
		bne.b	.loop3
		move.l	A4,D0
		subq.l	#1,D0
		sub.l	A3,D0
		mulu	#$400,D0

		lea	DiskNr(pc),a1
		move.l	d2,-(A7)
		moveq	#0,d2
		move.w	(a1),D2

		bsr.w	_LoadDisk
		move.l	(a7)+,d2

		add.l	D1,a0
		tst.l	d3
		beq.b	.exit
		cmp.l	D1,D3
		bhi.b	.loop4
		move.l	D3,D1
		moveq	#0,D3
		bra.b	.loop3
.loop4
		sub.l	D1,D3
		bra.b	.loop3
.exit
		movem.l	(A7)+,d0-a6
		moveq	#0,D0
		rts

Dir		dc.l	0
DiskNr		dc.w	2

;--------------------------------
;a0 = Load at
;d0 = Start
;d1 = Length
Load2
		movem.l	d0-d2/a0-a1,-(a7)
		cmp.l	#$1800,D0
		bne.s	other_file
offset:		move.l	#$34800-$1800,d1	;Size of part 1.0
		moveq	#1,d2			;Disk 1
		bsr.s	_LoadDisk											
		add.l	offset+2(pc),a0
		move.l	#$34800+$43800,d0		
		move.l	#$4934c-$33000,d1
		bra.s	Skip

other_file:	add.l	#$43800,d0		;Get correct offset!
Skip:		moveq	#1,D2
		bsr.b	_LoadDisk
		movem.l	(A7)+,d0-d2/a0-a1
		moveq	#0,D0
		rts

LoadDOS		movem.l	d0-a6,-(a7)
		moveq	#0,D0
		move.w	D1,D0
		mulu	#512,D0
		moveq	#0,D1
		move.w	D2,D1
		mulu	#512,D1
		moveq	#2,D2
		bsr.b	_LoadDisk
		movem.l	(A7)+,d0-a6
		moveq	#0,D0
		rts

Load		movem.l	d0-a6,-(a7)
		move.l	#$A6800,D0
		move.l	#$3000,D1
		moveq	#1,D2
		bsr.b	_LoadDisk
		movem.l	(A7)+,d0-a6
		moveq	#0,D4
		rts

_resload	dc.l	0

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts



; Bytekiller decruncher
; resourced and adapted by stingray
;
Decrunch
BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	_resload(pc),a0
	jmp	resload_Abort(a0)


.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

.decrunch
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d5
	move.l	a1,a2
	add.l	d0,a0
	add.l	d1,a2
	move.l	-(a0),d0
	eor.l	d0,d5
.loop	lsr.l	#1,d0
	bne.b	.nonew1
	bsr.b	.nextlong
.nonew1	bcs.b	.getcmd

	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	.nonew2
	bsr.b	.nextlong
.nonew2	bcs.b	.copyunpacked

; data is packed, unpack and copy
	moveq	#3,d1			; next 3 bits: length of packed data
	clr.w	d4

; d1: number of bits to get from stream
; d4: length
.packed	bsr.b	.getbits
	move.w	d2,d3
	add.w	d4,d3
.copypacked
	moveq	#8-1,d1
.getbyte
	lsr.l	#1,d0
	bne.b	.nonew3
	bsr.b	.nextlong
.nonew3	addx.l	d2,d2
	dbf	d1,.getbyte

	move.b	d2,-(a2)
	dbf	d3,.copypacked
	bra.b	.next

.ispacked
	moveq	#8,d1
	moveq	#8,d4
	bra.b	.packed

.getcmd	moveq	#2,d1			; next 2 bits: command
	bsr.b	.getbits
	cmp.b	#2,d2			; %10: unpacked data follows
	blt.b	.notpacked
	cmp.b	#3,d2			; %11: packed data follows
	beq.b	.ispacked

; %10
	moveq	#8,d1			; next byte:
	bsr.b	.getbits		; length of unpacked data
	move.w	d2,d3			; length -> d3
	moveq	#12,d1
	bra.b	.copyunpacked

; %00 or %01
.notpacked
	moveq	#9,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3

.copyunpacked
	bsr.b	.getbits		; get offset (d2)
;.copy	subq.w	#1,a2
;	move.b	(a2,d2.w),(a2)
;	dbf	d3,.copy

; optimised version of the code above
	subq.w	#1,d2
.copy	move.b	(a2,d2.w),-(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.b	.loop
	rts

.nextlong
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

; d1.w: number of bits to get
; ----
; d2.l: bit stream

.getbits
	subq.w	#1,d1
	clr.w	d2
.getbit	lsr.l	#1,d0
	bne.b	.nonew
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts



_tags
;		dc.l	WHDLTAG_MONITOR_GET
;_mon		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
cheat_bits
        dc.l    0
		dc.l	WHDLTAG_CUSTOM2_GET
second_button_jumps
		dc.l	WHDLTAG_CUSTOM3_GET
full_joypad_controls
		dc.l	0

		dc.l	0
space_emu_bit
    dc.l    0
spaceemu:
	dc.l	0
joy_buttons
	dc.l	0
command
	dc.w	0
actual_controller_joypad_1:
	dc.b	$FF
    