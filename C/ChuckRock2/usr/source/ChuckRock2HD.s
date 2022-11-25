; ChuckRock 2 slave by JOTD
;
; history:
; - v2.x: WHDLoad "native" code
; - v1.x: JST code emulated by WHDLoad macro system

; Assembled with Barfly

	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	hardware/custom.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	ChuckRock2.slave

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

;DEBUG = 1

	IFND	DEBUG
USE_FASTMEM
	ENDC

CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_DontCache
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config:
	dc.b    "C1:X:Trainer infinite lives:0;"			
	dc.b    "C2:X:second button jumps:0;"
	dc.b	0

_name		dc.b	"Chuck Rock 2 - Son Of Chuck"
		IFD	DEBUG
		dc.b	" (DEBUG MODE)"
		ENDC
		dc.b	0
_copy		dc.b	"1993 Core Design",0
_info		dc.b	"installed & fixed by JOTD",10,10
		dc.b	"Thanks go to Walter Gierholz and ANTHROX",10,10
		dc.b	"Type HELP or FWD+yellow to skip levels",10,10
		dc.b	"Version "
		DECL_VERSION
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
		dc.b	0


; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	0

		even

_start
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

	bsr	_detect_controller_type

	lea	CHIPMEMSIZE-$100,a7

	;enable cache
	move.l	#WCPUF_Base_NCS|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	;get tags
	;lea	(_tag,pc),a0
	;jsr	(resload_Control,a2)

	lea	$70000,a0
	move.l	#$D4800,d0
	move.l	#$6800,d1
	moveq.l	#1,d2
	jsr	(resload_DiskLoad,a2)

	pea	kb_interrupt(pc)
	move.l	(a7)+,$68.W		; set default keyboard interrupt

	lea	pl_70000(pc),a0
	lea	$70000,a1
	jsr	(resload_Patch,a2)

	JMP	$70000			;76: 4EF900070000

pl_70000:
	PL_START
	PL_PS	$5C,set_expmem
	PL_P	$6322,patch_prog
	PL_P	$5AF8,read_sectors

	; enable keyboard interrupt

	PL_W	$E8,$C018
	PL_W	$6584,$C018
	
	PL_END
	
; note that trampoline steel works with joystick up
; I'm leaving this as is, as it works nicely
; exp+A0A4

handle_jump
	; check caller, don't do anything if from menu
	move.l	(4,a7),a6
	sub.l	_expmem(pc),a6
	cmp.w	#$60dc,a6
	beq.b	.from_menu
	cmp.w	#$6570,a6
	beq.b	.from_menu
	LEA.L $00dff000,A6
	MOVE.W	12(A6),D0
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed
	bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	movem.l	d1,-(a7)
	move.l	joystick_state(pc),d1
	btst	#JPB_BTN_BLU,d1
	movem.l	(a7)+,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=0
.no_blue:
	RTS
.from_menu
	LEA.L $00dff000,A6
	MOVE.W	12(A6),D0
	rts
	
get_expmem
	IFND	USE_FASTMEM
	movem.l	a0,-(a7)
	lea	_expmem(pc),a0
	move.l	#CHIPMEMSIZE,(a0)
	move.l	(A0),A0
	movem.l	(a7)+,a0
	ENDC
	rts

kb_interrupt
	; I was not very lucky to pick A5 as a work register here
	; because I think A5 is used all the time even during the
	; VBLANK interrupt without being set by the interrupt
	; (the interrupt code relies on A5 to be set properly)
	; so if this kb routine is interrupted by the VBLANK
	; routine after A5 has been set to kb_value, unexpected
	; behaviour may occur.
	; that could not happen before because level 2 interrupt
	; was not enabled (quite the same problem in Gremlin car games)
	;
	; Furthermore, there is a game bug where they want to write
	; into ($68,A5) and they actually write to $68
	; This happens sometimes in the game, so afterwards if you
	; press a key, it crashes (same problem in Blastar, I wonder
	; if the programmers did not disable kb interrupts after having
	; too many problems)

	move.w	#$2700,SR

	; now we can safely destroy all the registers

	movem.l	d0/a5,-(a7)
	move.w	$DFF01E,d0
	btst	#3,d0
	beq.b	.nokb

	move.b	$bfec01,d0
	not.b	d0
	ror.b	#1,d0
	lea	kb_value(pc),a5
	move.b	d0,(a5)

	bclr	#3,$bfed01

	cmp.b	_keyexit(pc),D0
	bne	.noquit

	; *** still quits with NOVBRMOVE or 68000

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit

	bset	#6,$bfee01
	moveq	#2,d0
	bsr	_beamdelay	; handshake: 75 us minimum
	bclr	#6,$bfee01	

.nokb
	movem.l	(a7)+,d0/a5
	move.w	#8,$DFF09C
	rte

patch_prog:
	move.l	_expmem(pc),a0

;;;	move.l	A0,$24.W	; expansion memory stored here for the game

	movem.l	d0-a6,-(a7)

	move.l	_resload(pc),a2

	; *** if trainer, remove life substraction

	lea	pl_prog(pc),a0
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-a6
	jmp	(A0)

kbdelay:
	movem.l	D0,-(a7)
	moveq	#3,d0
	bsr	_beamdelay
	movem.l	(a7)+,d0
	move.b	#0,$BFEC01
	rts

kb_value
	dc.w	0


pl_prog

	PL_START
	; trainer
	PL_IFC1
	PL_B	$D59E,$4A
	PL_ENDIF
	
	; 2nd button jumps
	PL_IFC2
	PL_PSS	$A0A4,handle_jump,4
	PL_ENDIF
	
	; read joypad buttons
	PL_PS	$9F52,read_joy_buttons
	
	; enable keyboard interrupt during intro and menu

	PL_W	$3F98,$C018
	PL_W	$9CB8,$C018
	PL_W	$122A6,$C018
	PL_W	$35556,$C018

	; patch interrupt
	
	PL_PS	$9DC6,wait_vbi
	PL_PS	$357E8,wait_vbi

	; removes protection

	PL_B	$AD8C,$60
	PL_W	$70,$6004

	; patch floppy routine

	PL_P	$34F3E,read_sectors

	; patch keyboard interrupt : level skip
	; (quitkey is not required because it is tested
	; in the main kb routine)

	PL_P	$BF3C,kbint

	; disk change

	PL_PS	$11F46,disk_change

	; set disk 1

	PL_PS	$3F12,set_disk_1

	; fix programming bug that conflicts with keyboard interrupt vector!!
	; maybe it fixes another game bug, I don't know

	PL_L	$D4EE,$3B7C0000
	PL_L	$D4F2,$00684E71	; move.w #0,$68 -> move.w #0,($68,A5)

	; fix blitter wait 1
	PL_PS	$A14E,move_9f00000_40
	PL_END
	
read_joy_buttons
	movem.l	a0/d0,-(a7)
	bsr	_read_joystick_port_1
	lea	joystick_state(pc),a0
	move.l	d0,(a0)
	; test for ESC = BWD/FWD
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noquit
	btst	#JPB_BTN_YEL,D0
	beq.b	.nolskip
	bsr	level_skip
.nolskip
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
	MOVE.W	#$0001,588(A5)	; game quit
.noquit
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause
	; we're going to handle pause from here
	; as putting the keycode doesn't work
	bsr	paused
.nopause
	movem.l	(a7)+,a0/d0
	; original code
	MOVE.W	#$0020,156(A6)
	rts
	
paused:
	movem.l	a0/d0,-(a7)
.test_release
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	bne.b	.test_release
	; pause has been released, now wait for press
.test_unpause
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	beq.b	.noplay
.wait_unpress
	; play pressed: out, after unpress
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	beq.b	.out
	bra.b	.wait_unpress
.noplay
	CMPI.B	#$19,586(A5)
	beq.b	.out
	bra.b	.test_unpause
.out
	lea	joystick_state(pc),a0
	move.l	d0,(a0)
	movem.l	(a7)+,a0/d0
	rts
	
move_9f00000_40
	bsr	wait_blit
	move.l	#$9F00000,($40,a6)
	add.l	#2,(A7)
	rts

move_ffffffff_44
	bsr	wait_blit
	move.l	#-1,($44,a6)
	add.l	#2,(A7)
	rts


wait_blit
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
	rts

set_expmem:
	bsr	get_expmem
	move.l	_expmem(pc),$76342
	rts

wait_vbi
.loop
	btst	#5,intreqr+1(a6)
	beq.b	.loop
	move.w	#$20,intreq(a6)
	addq.l	#2,(a7)
	rts

disk_change:
	move.l	A0,-(sp)
	lea	current_disk(pc),A0
	move.l	#0,(a0)

	cmp.l	#'CR2B',(A4)		; wished disk
	bne	not.2
	move.l	#1,(a0)
not.2
	move.l	(sp)+,A0
	bra	read_sectors		; load track


set_disk_1:
	move.l	A0,-(sp)
	lea	current_disk(pc),A0
	move.l	#0,(a0)
	move.l	(sp)+,A0
	bra	read_sectors		; load track


kbint:
	move.b	kb_value(pc),d0

	; clears value

	move.l	a0,-(a7)
	lea	kb_value(pc),a0
	clr.b	(a0)
	move.l	(a7)+,a0

	cmp.b	#$5F,D0
	bne	.nolskip
	; skip level with HELP
	bsr	level_skip
; whaaaat????
;	cmp.b	#$4A,$14EA(A1)
;	bne	.2
;	move.w	#$50,$174(A5)
;	bra	.exit
;.2
	move.w	#0,$174(A5)
.nolskip
	
.exit
	; write keycode, stolen
	move.b	d0,($24A,A5)	
	rts
	
level_skip
	move.w	#2,$254(A5)
	rts
	
read_sectors:
	move.l	current_disk(pc),D0
	bsr	_robread
	tst.l	D0
	rts

current_disk:
	dc.l	0

; ----------------------------------------------


; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

; Rob Northen track loading routine
; < A0: buffer
; < D0: disk number
; < D1: sector offset (*$200)
; < D2: sector length (*$200)
; < D3: command (ignored)
; > D0: 0 if ok (which is all the time :))

_robread:
	movem.l	d1-d3/a0-a2,-(A7)
	and.b	#$FF,D3
	bne.b	.exit

	move.l	d0,d3		; disk number stored
	
	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.exit		; length=0: out

	move.l	D1,D0
	ext.l	d0
	lsl.l	#7,d0			;diskoffset
	lsl.l	#2,d0

	move.l	D2,D1			;len to read
	ext.l	d1
	lsl.l	#7,d1
	lsl.l	#2,d1

	move.l	D3,D2
	addq.l	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)
.exit
	movem.l	(A7)+,d1-d3/a0-a2
	moveq.l	#0,D0
	rts

_resload
	dc.l	0

_tag

	dc.l	0
joystick_state
	dc.l	0
	
	include ReadPort1JoyButtons.s
	