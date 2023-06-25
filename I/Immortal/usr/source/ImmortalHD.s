;*---------------------------------------------------------------------------
;  :Program.	ImmortalHD.asm
;  :Contents.	Slave for "Immortal" from
;  :Author.	JOTD
;  :History.	28.01.05
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
; notes:

; after load breakpoint
;f $236AC
; before load ,read_sectors
;f $5A5C
; setting those 5 values in the memory allow to completely skip the protection
; those values have been found by comparing various memory dumps with and without the
; protection entered once, at various points/levels of the game
;
; 0001527E=0001 0001B025=001E 0001B076=0010 0001E833=000D 0001F6B8=0001
; only value 0001F6B8 set to 1 is enough. Others seem to produce nasty/strange
; side effects (like table appearing out of nowhere in the big level 1 trap room !)
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	Immortal.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;DEBUG
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000

KEYCODE_OFFSET = $1852
;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_NoDivZero|WHDLF_NoError|WHDLF_NoKbd	;ws_flags
		IFD	DEBUG
		dc.l	CHIPMEMSIZE+EXPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFND	DEBUG	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config
_config		dc.b	"C1:B:Infinite energy",0

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

_name		dc.b	"The Immortal"
	IFD	DEBUG
	dc.b	" (debug mode)"
	ENDC
		dc.b	0
_copy		dc.b	"1990 Electronic Arts",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Check the readme for joypad/keyboard controls",10,10

		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,0
	even

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2
	
	move.l	#$676,4.W
	moveq.l	#0,d4
	
	lea		third_button_maps_to(pc),a0
	move.l	#JPF_BTN_GRN,(a0)
	
	;get certificate
	lea	(custom_password,pc),a0
	moveq.l	#0,d1
	move.l	#15,d0
	jsr	(resload_GetCustom,a2)


restart_game:
	move	#$2700,SR
	lea	CHIPMEMSIZE-$10,a7
	lea	$DFF000,A6
	MOVE	#$7FFF,$9E(A6)		;0EC: 3D7C7FFF009A
	MOVE	#$7FFF,154(A6)		;0EC: 3D7C7FFF009A
	MOVE	#$7FFF,156(A6)		;0F2: 3D7C7FFF009C
	MOVE	#$8640,150(A6)		;0F8: 3D7C86400096
	
	bsr	_detect_controller_types

	move.l	#$A2C00,D0
	move.l	#$20000,D1
	moveq	#1,D2
	lea	$10000,A0
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)

	lea	pl_boot(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)

	bsr	get_extmem
	jmp	$10000


pl_boot
	PL_START
	PL_P	$11348,patch_loader
	PL_W	$11322,$6006	; remove a poke in ROM ????
	PL_END

get_extmem
	IFD	DEBUG
	move.l	#CHIPMEMSIZE,d0
	ELSE
	move.l	_expmem(pc),d0
	ENDC
	rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts



;--------------------------------

_resload	dc.l	0		;address of resident loader

; < D0: numbers of vertical positions to wait
beam_delay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

patch_loader:
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_loader1(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	
	add.l	#$145F6,A0
	jmp	(A0)

pl_loader1
	PL_START
	PL_P	$5A5C,read_sectors
	PL_R	$620A

	PL_PS	$26970,read_ciasdr

	PL_PSS	$2698E,delay,2
	

	PL_PS	$2462A,WaitD6
	PL_PS	$24642,WaitD6
	PL_PS	$2465A,WaitD6

	PL_PS	$271d2,sound_dma_1
	PL_PS	$272c0,sound_dma_2
	PL_PS	$273b0,sound_dma_3
	PL_PS	$274a0,sound_dma_4
		
	PL_PSS	$26134,read_alphanum,2
	PL_PSS	$11f68,set_space_press,2
	
;;	PL_P	$269f4,store_key_code

	
	; hook on the virtual machine for the trainer
	; and also the protection
	PL_IFC1
	; crack+trainer
	PL_PS	$10EC6,check_energy_dec
	PL_ELSE
	; just crack
	PL_PS	$10EC6,virtual_machine_hook
	PL_ENDIF
	
	; disable blthog to speed up blitter vs cpu
	;PL_NOP	$24080,6
	
	; remove protection (all inputs pass the protection)
	; (adapted from a crack from Black Hawk/Paradox)
	; this isn't needed anymore: a better crack is to set the game
	; state as if the protection has already been entered once
	;PL_B	$101C5,$22
	;PL_B	$1043C,$4
	;PL_W	$1F770,$0B38

	PL_END

; this code is called within a keyboard interrupt
; it's not very useful to simulate keypresses, then...
store_key_code
	MOVE.B	D0,(KEYCODE_OFFSET,A4)		;269f4: 19401852
	RTS				;269f8: 4e75

; part of the virtual machine used to write to game internal variables
; this is highly sensitive.

; 13C0E.B: energy bar, derived from 172BE which contains energy *16 + something
; (which is used for something else, do not change)
; ex: if energy bar contains $5, "base" energy can contain $53, if $E => $E3 and so on
; changing energy bar doesn't do anything useful.

check_energy_dec:
	cmp.l	#$172BE,D5
	bne.b	virtual_machine_hook
	; max the value, not touching the lower 4 bits
	or.b	#$F0,d0		; or.b   #$20,d0 also works, the energy goes low but never too low
	
	; hook, does nothing except 1) original code and 2) setting the right values
	; so the protection questions never pop up
virtual_machine_hook:
	MOVEA.L D5,A0
    MOVE.B D0,(A0)
	move.b  #1,$1F6B8	; tells that the protection has been entered once
.ok

    MOVE.W (A5)+,D5
	rts

; < D1.W: start sector (offset / $200)
; < D2.W: number of sectors (len / $200)
; < A0: destination address

read_sectors:
	movem.l	A0-A1/D0-D4,-(a7)
	and.w	#$FFFF,D1
	and.w	#$FFFF,D2
	moveq	#0,D3

	moveq	#0,D0
	cmp.w	#2,D1
	bne.b	.load
	cmp.w	#2,D2
	bne.b	.load
	move.l	diskcount(pc),D0
	cmp.l	#2,D0
	beq	.load
	
	lea	diskcount(pc),a1
	addq.l	#1,(a1)

	bsr	_flushcache

.load
	move.l	diskcount(pc),D0
	cmp.l	#2,D0
	beq	.disk2
	moveq	#0,D0
	bra.b	.call
.disk2
	moveq.l	#1,D0
.call
	cmp.w	#$370,D1
	bcs	.normal_start		; normal if D1 below $370
	add.l	#22,D1		; skips 2 tracks if D1 above $370
	bra.b	.read
.normal_start
	moveq.l	#0,D4
	; normal start (below $370) but with length, we could end up reading in 2 parts
	move.w	D1,D4
	add.w	D2,D4	; offset at end
	cmp.w	#$370,D4
	bcs.b	.read	; end below 370: skip
	
	; cornercase: read first part normally until sector $370
	; reduce D2 so it reads until $370

	movem.l	d0/d2,-(a7)
	move.w	#$370,D2
	sub.w	d1,d2	; compute the number of sectors below $370 to read
	move.w	d2,d4	; save the number of sectors read for later
	bsr	read_rob_sectors
	
	movem.l	(a7)+,d0/d2
	
	; now reduce D2 by the amount just read
	sub.w	d4,d2
	; and adjust start address
	lsl.l	#8,D4
	add.l	D4,D4
	add.l	D4,A0
	
	move.w	#$370+22,D1	; reads from $370+22
.read
	bsr	read_rob_sectors
	movem.l	(a7)+,A0-A1/D0-D4
	moveq	#0,D0
	rts

	
IGNORE_JOY_DIRECTIONS
	include	ReadJoyPad.s

; < D0: disk number
; < D1: sector start (*$200)
; < D2: length in sectors (*$200)
; < A0: destination buffer
; > D0: 0 (OK)

read_rob_sectors
	movem.l	d1-d2/a0-a2,-(A7)

	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.readnothing		; length=0: out

	exg.l	d0,d2
	addq.l	#1,d2	; disk number

	exg.l	d0,d1
	
	ext.l	d0
	lsl.l	#7,d0
	lsl.l	#2,d0
	ext.l	d1
	lsl.l	#7,d1			;diskoffset
	lsl.l	#2,d1
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)
.readnothing
	movem.l	(a7)+,d1-d2/a0-a2
	moveq	#0,d0
	rts


	
; 68000 quit key
read_ciasdr
	move.b	$bfec01,d0
	movem.l	d0-d1/a0-a1,-(a7)
	not.b	d0
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit
	; quitkey works for 68000
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	cmp.b	#$58,d0
	bne.b	.norestart
	bsr	kb_ack
	move.l	_resload(pc),a2
	lea	diskcount(pc),a0
	clr.l	(a0)	
	bra	restart_game
.norestart
	cmp.b	#$51,d0
	bcs.b	.nofunc
	cmp.b	#$58,d0
	bcc.b	.nofunc
	sub.b	#$51,d0	; 0 => F2... and so on until F8
	lea	level_table(pc),a1
	and.w	#$FF,d0
	add.w	d0,d0
	moveq.l	#0,d1
	move.w	(a1,d0),d1
	add.l	d1,a1
	; a0 points on a level code
	; cancel effect of function key (same as numbers)
	clr.b	(3,A7)
	bra.b	.pinject
.nofunc
	cmp.b	#$42,d0
	bne.b	.nopwd_inject
	; from CUSTOM tooltype
	lea custom_password(pc),a1
.pinject
	lea	password_to_inject(pc),a0
	move.l	a1,(a0)
.nopwd_inject
	movem.l	(a7)+,d0-d1/a0-a1
	rts

kb_ack:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beam_delay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
	rts
	
set_space_press:
	MOVE.B	6292(A4),D0		;11f68: 102c1894
	; keyboard OR joystick
	movem.l	a0/a1,-(a7)
	movem.l	d0/d1,-(a7)
	
	moveq.l	#1,d0
	bsr	_read_joystick
	lea		prev_joy_state(pc),a0
	move.l	(a0),d1	; previous joystate
	move.l	d0,(a0)	; store current joystate
	
	btst	#JPB_BTN_BLU,d0
	beq.b	.noblue
	st.b	(3,A7)	; set D0.B when restored
.noblue
	btst	#JPB_BTN_GRN,d0
	beq.b	.nogreen
	btst	#JPB_BTN_GRN,d1
	bne.b	.nogreen
	; simulate CTRL+S
	move.b	#$13,$1852(A4)
.nogreen
	btst	#JPB_BTN_YEL,d0
	beq.b	.noyellow
	btst	#JPB_BTN_YEL,d1
	bne.b	.noyellow
	lea	password_to_inject(pc),a0
	lea custom_password(pc),a1
	move.l	a1,(a0)
.noyellow
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nofwd
	btst	#JPB_BTN_FORWARD,d1
	bne.b	.nofwd
	; one level up
	lea	level_counter(pc),a0
	cmp.w	#6,(a0)
	beq.b	.nofwd
	add.w	#1,(a0)
	bsr	.inject_a0
.nofwd
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nobwd
	btst	#JPB_BTN_REVERSE,d1
	bne.b	.nobwd
	; one level down
	lea	level_counter(pc),a0
	cmp.w	#0,(a0)
	beq.b	.nobwd
	sub.w	#1,(a0)
	bsr	.inject_a0
.nobwd
	btst	#JPB_BTN_PLAY,d0
	beq.b	.noplay
	; test play+bwd+fwd: quit game
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nogameover
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nogameover
	; if fire is pressed, quit slave
	btst	#JPB_BTN_RED,d1
	beq.b	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	; simulate CTRL+R
	move.b	#$12,$1852(A4)
.nogameover
.noplay

	movem.l	(a7)+,d0/d1
	movem.l	(a7)+,a0/a1
	
	LEA	8052(A4),A5		;11f6c: 4bec1f74 original code
	rts
	
.inject_a0
	movem.l	d2-d3,-(a7)
	move.w	(a0),d2
	lea	level_table(pc),a1
	and.w	#$FF,d2
	add.w	d2,d2
	moveq.l	#0,d3
	move.w	(a1,d2),d3
	add.l	d3,a1
	; a0 points on a level code
	lea	password_to_inject(pc),a0
	move.l	a1,(a0)
	movem.l	(a7)+,d2-d3	
	rts
	
read_alphanum:
	; read alphanum characters: during the password enter
	; and when game runs (but not while in the inventory)
	movem.l	d0/a0-a1,-(a7)
	lea	password_to_inject(pc),a0
	move.l	(a0),d0
	beq.b	.nopass
	
	; some letters have to be injected
	move.l	(a0),a1
	move.b	(a1)+,(KEYCODE_OFFSET,A4)
	bne.b	.valid
	;;move.b	#$D,(KEYCODE_OFFSET,A4)	; RETURN
	; end of string: cancel the pointer
	sub.l	a1,a1
.valid
	; store back pointer value (or NULL)
	move.l	a1,(a0)
.nopass

	movem.l	(a7)+,d0/a0-a1
	; original code
    MOVE.B (KEYCODE_OFFSET,A4),d0
    CLR.W (KEYCODE_OFFSET,A4)

	RTS
	



; the DBF delay before sound DMA set is rather useless,
; on the other hand the DBF delay after setting sound DMA is needed

sound_dma_1:
	move.w	#$1,dmacon(A5)
	bra	wait_sound
sound_dma_2:
	move.w	#$2,dmacon(A5)
	bra	wait_sound
sound_dma_3:
	move.w	#$4,dmacon(A5)
	bra	wait_sound
sound_dma_4:
	move.w	#$8,dmacon(A5)
	bra	wait_sound

wait_sound:
	movem.l	D0,-(A7)
	moveq.l	#6,D0
	bsr	beam_delay
	movem.l	(A7)+,D0	
	rts
	

delay:
	move.l	D0,-(sp)
	move.w	#$12C,D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beam_delay
	move.l	(sp)+,D0
	rts

WaitD6:
	move.l	D0,-(sp)
	moveq	#0,D0
	move.w	D6,D0
	divu.w	#$30,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beam_delay
	move.l	(sp)+,D0
	rts
diskcount
	dc.l	0
password_to_inject
	dc.l	0
prev_joy_state:
	dc.l	0
current_password_counter:
	dc.b	0


custom_password:
	ds.b	16,0
	even

		
level_counter:
	dc.w	0
	
level_table:
		dc.w	.level2-level_table
		dc.w	.level3-level_table
		dc.w	.level4-level_table
		dc.w	.level5-level_table
		dc.w	.level6-level_table
		dc.w	.level7-level_table
		dc.w	.level8-level_table
		dc.w	0
		
SOMEDELS:MACRO
	dc.b	$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
	ENDM
	
.level2:
	SOMEDELS
	dc.b	"cddff10006f70",0
.level3:
	SOMEDELS
	dc.b	"f47ef21000e10",0
.level4:
	SOMEDELS
	dc.b	"b5fff31001eb0",0
.level5:
	SOMEDELS
	dc.b	"94bfb43000eb0",0
.level6:
	SOMEDELS
	dc.b	"563ff53010a41",0
.level7:
	SOMEDELS
	dc.b	"c250f63010ac1",0
.level8:
	SOMEDELS
	dc.b	"a890b730178c1",0


