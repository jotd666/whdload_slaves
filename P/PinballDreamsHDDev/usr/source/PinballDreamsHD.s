;*---------------------------------------------------------------------------
;  :Program.	PinballDreamsHD.s
;  :Contents.	Slave for "Pinball Dreams" from Digital Illusions
;  :Author.	Galahad of Fairlight
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	PhxAs, Barfly, Vasm
;  :To Do.
;*---------------------------------------------------------------------------
; Resourced by whdslave_resourcer
; a program written by JOTD in 2016
;
; todo: remaining issues
; score ignition pal BCD around $A0D0
;       steel wheel pal around $A1C0: W $A1BF $30: 3 billon score
;       beat box: W $A2F5 $30: 3 billion score
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"PinballDreams.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;CHIP_ONLY

EXPMEMSIZE = $50000

_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	17					; ws_version (was 15)
	dc.w	WHDLF_NoError|WHDLF_EmulTrap
	IFD	CHIP_ONLY
	dc.l	$80000+EXPMEMSIZE					; ws_basememsize
	ELSE
	dc.l	$80000					; ws_basememsize
	ENDC
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	_data-_base					; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	$0					; ws_keydebug
_keyexit
	dc.b	$59					; ws_keyexit
_expmem
	IFD	CHIP_ONLY
	dc.l	0
	ELSE
	dc.l	EXPMEMSIZE					; ws_expmem
	ENDC
	dc.w	_name-_base				; ws_name
	dc.w	_copy-_base				; ws_copy
	dc.w	_info-_base				; ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
;---
_config
	dc.b    "C1:B:Skip introduction;"
	dc.b    "C2:B:Full control by 2 joysticks;"

	dc.b	0

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.8"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_data   dc.b    'data',0
_name	dc.b	'--> Pinball Dreams <--'
		IFD	CHIP_ONLY
		dc.b 	" (DEBUG/CHIP mode)"
		ENDIF
		dc.b	0
_copy	dc.b	'1992 Digital Illusions',0
_info
    dc.b   '----------------------',10,'Installed and fixed by',10,'Galahad of Fairlight & JOTD',10
	dc.b	'----------------------',10,10
	dc.b	'Thanks to John Regent, Bert Jahn',10
	dc.b	'and Quietust for the images',10,10
	dc.b	'Thanks to Frank for the installer',10,'and icons'
	dc.b	10,10,'-----------------',10,'v'
	DECL_VERSION
	dc.b	10,'-----------------',0
	
_kickname   dc.b    0
;--- version id

    dc.b	0
    even


hi:
	dc.b	'HI00'
name:
	dc.b	'PROT',0
	even	
	include	ReadJoyPad.s
	
start:
	lea	$80000,A7
	
	LEA	_resload(PC),A1
	MOVE.L	A0,(A1)
	bsr	_detect_controller_types
	lea	event_queue(pc),a2
	lea	event_queue_pointer(pc),a0
	move.l	a2,(a0)
	
	IFD	CHIP_ONLY
	lea	_expmem(pc),a0
	move.l	#$80000,(a0)
	ENDC
	
	LEA	tags(PC),A0	
	MOVEA.L	_resload(PC),A2
	JSR	resload_Control(A2)
	LEA	name(PC),A0
	lea	$100,a1
	bsr	_LoadFile
	
	lea	depacka(pc),a0
	lea	$1ab6.w,a1
	move.l	a1,a3
	move.l	a0,a4
	move.w	#($1b4c-$1ab6)-1,d0
copy_depac:
	MOVE.B	(A1)+,(A0)+
	DBF	D0,copy_depac
		
	lea	pl_boot(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a3
	jsr	resload_Patch(a3)
	jmp	$100.W			;Execute Pinball Dreams!

start_menu
	movem.l	d0-d2/a0-a2,-(a7)
	lea	pl_main(pc),a0
	lea	$3000.W,A1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d2/a0-a2
	jsr	$3000.W
	move.w	#$78,$DFF09A
	rts
	
pl_boot
	PL_START
	PL_PSS	$2C4,start_menu,6
	PL_L	$15E,$600000d6		;Remove extra ram
	PL_R	$17fc		;Disk stuff!
	PL_R	$18c2		;Stop disk request
	PL_P	$1ab6,depacka
	PL_P	$104a,loader2
	PL_P	$1180,saver
	PL_END
pl_main
	PL_START
	PL_PS	$162,read_function_keys
	PL_IFC1
	; when intro is skipped, pressing a key 
	; other than space or function freezes the game...
	PL_NOP	$40234-$3000,2
	PL_ENDIF
	PL_END
		
read_function_keys
	; 68000 quitkey from menu
	move.b	$0.W,d0	; CIA_SDR is stored there, then cleared...
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
.noquit

	bsr _joystick
    move.l  joy1(pc),d0
    movem.l d1,-(a7)
    move.l  control_by_joy_directions(pc),d1
    movem.l (a7)+,d1
    bne.b   .joystick
	btst	#JPB_BTN_RED,d0
	bne.b	.ignition
	btst	#JPB_BTN_BLU,d0
	bne.b	.steel_wheel
	btst	#JPB_BTN_YEL,d0
	bne.b	.beat_box
	btst	#JPB_BTN_GRN,d0
	bne.b	.nightmare

	MOVE.B	$0.W,D0
	rts
.joystick
	btst	#JPB_BTN_LEFT,d0
	bne.b	.ignition
	btst	#JPB_BTN_RIGHT,d0
	bne.b	.steel_wheel
	btst	#JPB_BTN_DOWN,d0
	bne.b	.beat_box
	btst	#JPB_BTN_UP,d0
	bne.b	.nightmare

	MOVE.B	$0.W,D0
	rts

.ignition
	move.b	#$50,d0
	bra.b	.encode
.steel_wheel
	move.b	#$51,d0
	bra.b	.encode
.beat_box
	move.b	#$52,d0
	bra.b	.encode
.nightmare
	move.b	#$53,d0
	
.encode
    movem.l a0,-(a7)
	lea joy1(pc),a0
    clr.l   (a0)
    movem.l (a7)+,a0
    
	bset	#7,d0	; key up
	not.b	d0
	rol.b	#1,d0
	rts
	
;d0 = filename
;d1 = load address
;d2 = size

saver:
	movem.l	d0/a0-a2,-(a7)
	move.l	_expmem(pc),a0		;$80000
	move.l	a0,a1
	move.l	#$00010000,(a0)+
	move.l	#$2f000000,(a0)+
	move.w	#$00c0,(a0)+		;Header for hiscore!
	lea	$2f00.w,a2
	move.w	#$c0-1,d0
copy_hs:
	move.b	(a2)+,(a0)+
	dbra	d0,copy_hs		;Info copied!
	lea	name(pc),a0	
	moveq	#0,d0
	move.b	#202,d0
	lea	hi(pc),a2
	move.l	(a2),(a0)		;We made filename!	
	bsr	_SaveFile
	movem.l	(a7)+,d0/a0-a2
	rts

	
loader2:
	movem.l	d0-d1/a0-a6,-(a7)
	lea	name(pc),a0
	move.l	a0,a5
	move.l	d0,(a0)			;We now have filename!
	move.l	_expmem(pc),a1
	bsr	_LoadFile
	move.l	d0,d1
	move.l	d0,d7			;Specially for STEEL WHEEL!
	and.l	#$ffffff00,d1
	cmp.l	#$50447800,d1		;'PDx '
	bne.s	dont_stop
	movem.l	d0-d7/a0-a6,-(a7)	;Stop music / Stops crashing!
	moveq	#0,d0
	moveq	#1,d1

	jsr	$40012
waiting:
	tst.w	2.w
	bne.s	waiting
	move.w	#$20,$dff09a
	bsr	kill_sound
	clr.b	$7fff7
	movem.l	(a7)+,d0-d7/a0-a6	
	
dont_stop:
	lea	depack(pc),a4
next:	cmp.w	#1,(a1)			;Check ID
	bne.s	finished
	cmp.w	#2,(a1)
	bne.s	normal_stuff
	lea.l	$10(a1),a1		
normal_stuff:
	move.l	2(a1),a0		;Where to load file
	move.l	a0,(a4)
	move.l	6(a1),d0		;Size of file to transfer
	move.l	d0,4(a4)
	move.l	a1,a2
	lea	$a(a2),a2		;Data to transfer
	move.l	a2,a3
	add.l	d0,a3			;So we can check for next file!
	cmp.l	#$1000,a0		;If $1000, then game is attempting
	beq.s	trick			;to reinstall game loader!!
	cmp.l	#$3000,a0
	bne.s	copy_file
	cmp.w	#$6a,d0
	bne.s	copy_file
	addq.l	#6,a3			;Skip fake shit!
	bra.s	trick

copy_file:
	move.b	(a2)+,(a0)+
	subq.l	#1,d0
	bne.s	copy_file

	movem.l	d0-d7/a0-a6,-(a7)
	move.l	(a4),a0			
	cmp.l	#'PP20',(a0)
	bne.s	dont_depack	
	add.l	4(a4),a0		;Where end of depack data is
	move.l	(a4),a3
	addq.l	#8,a3
	move.l	a3,a5
	subq.l	#4,a5
	lea	store(pc),a2
	move.l	a3,(a2)	
	bsr	depacka			;PP20 Depacker!
dont_depack:
	movem.l	(a7)+,d0-d7/a0-a6
trick:
	MOVEA.L	A3,A1
	BRA.S	next

finished:
skip:	movem.l	(a7)+,d0-d1/a0-a6
	cmp.l	#'INTR',d0		;Seperate conditions for INTRO
	beq	execute_intro
	move.l	d0,d1
	and.l	#$ffffff00,d1
	cmp.l	#$50447800,d1		;'PDx '
	bne	not_game
		
	movem.l	d0-d7/a0-a6,-(a7)
	cmp.l	#'PDxA',d7
	bne.s	.not_ig
	; Ignition
	lea	ignition_table(pc),a0
	cmp.w	#$41f9,$73D8
	bne.b	.no1ntsc
	lea	ignition_ntsc_table(pc),a0
.no1ntsc
	bra	.patch_table
.not_ig
	cmp.l	#'PDxB',d7		;If loading STEEL WHEEL we need to
	bne.s	.not_sw			;do something protection-wise!!!
	; Steel Wheel

	LEA	data(PC),A0
	MOVEA.L	#$0007bf9c,A1
	CMPI.L	#$0000d7dc,$300a.W
	BNE.S	.LAB_0010
	SUBQ.L	#6,A1
	BRA.S	.LAB_0011
.LAB_0010:
	CMPI.L	#$0000d7c8,$300a.W
	BNE.S	.LAB_0011
	LEA	-26(A1),A1
.LAB_0011:
	MOVEQ	#115,D0
.copy_check:
	move.b	(a0)+,(a1)+
	dbra	d0,.copy_check

	MOVE.L	#$65f60426,$7fffc
	
	; remove a wait that blocks when quitting game on WinUAE
	; this should be done when quitting
	;; move.w	#$4E71,$3F60.W
	
	lea	steel_wheel_table(pc),a0
	cmp.w	#$41f9,$749e
	bne.b	.no2ntsc
	lea	steel_wheel_ntsc_table(pc),a0
.no2ntsc
	bra	.patch_table

.not_sw:
	cmp.l	#'PDxC',d7
	bne.b	.not_bb
	lea beatbox_table(pc),a0
	cmp.w	#$41f9,$75d4
	bne.b	.no3ntsc
	lea	beatbox_ntsc_table(pc),a0
.no3ntsc
	bra	.patch_table
	
.not_bb
	lea nightmare_table(pc),a0
	cmp.w	#$41f9,$7566
	bne.b	.no4ntsc
	lea	nightmare_ntsc_table(pc),a0
.no4ntsc
		
.patch_table:
    ; add vertical blank to enabled interrupts
    move.w  #$C038,$3110.W  ; the address is the same for all 4 tables, PAL or NTSC!
	; save sync flag address	
	move.l	(a0)+,a1
	move.l	(2,a1),d0
	lea	sync_flag_value(pc),a2
	move.l	d0,(a2)+
	
	move.l	#$4E714EB9,(a1)
	pea	joypad_controls(pc)
	move.l	(a7)+,(4,a1)
	; now hook on level 3 interrupt
    lea -$10(a1),a1
    move.w  #$4EF9,(a1)+
    pea level3_interrupt(pc)
    move.l  (a7)+,(a1)
    
    ; store other values
	move.l	(a0)+,(a2)+
	move.l	(a0)+,(a2)+
	move.l	(a0)+,(a2)+
	
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
.launch_table
	; just before a table starts
	; $3000 is the base address of tables
	; now test some locations to know which table it is
	
	JSR	$3000.W
	BSR	kill_sound
	MOVEM.L	(A7)+,D0-D7/A0-A6
	RTS
	   
	
ignition_table:
	dc.l	$3F32	; +$3000 insert in game loop, near MOVE.W	#$0010,INTREQ
	dc.l	$9d8b	; value written after MOVE.B	CIAA_SDR,D0 / BSET	#6,CIAA_CRA
	dc.l	$73f2	; keyboard routine, near CMP.B	#$4d,D0
	dc.l	$cee0	; copperlist to watch
steel_wheel_table
	dc.l	$3f5a,$9e45,$74b8,$d9e8
beatbox_table
	dc.l	$3f5a,$9f7b,$75ee,$d6a2
nightmare_table
	dc.l	$3f5a,$9ecd,$7580,$da18


ignition_ntsc_table:
	dc.l	$3f32	; +$3000 insert in game loop, near MOVE.W	#$0010,INTREQ
	dc.l	$9d71	; value written after MOVE.B	CIAA_SDR,D0 / BSET	#6,CIAA_CRA
	dc.l	$73d8	; keyboard routine, near CMP.B	#$4d,D0
	dc.l	$ceca	; copperlist to watch
steel_wheel_ntsc_table
	dc.l	$3f5a,$9e2b,$749e,$d9ce
beatbox_ntsc_table
	dc.l	$3f5a,$9f61,$75d4,$d688
nightmare_ntsc_table
	dc.l	$3f5a,$9eb3,$7566,$d9fe

; those variables must remain contiguous
sync_flag_value:
	dc.l	0
key_code_address:
	dc.l	0
update_controls_address:
	dc.l	0
copper_address_to_check:
	dc.l	0
; end of contiguous area

level3_interrupt
    movem.l d0/a0,-(a7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    beq.b   .copper
    ; block ALL interrupts
    move.w  #$4000,_custom+intena
    ; this is VBL, read joypad here, seems to cause trouble if done
    ; somewhere else, because reading potentiometers are better done
    ; at the start of the vertical blank, or else they could be not available
    bsr _joystick
    move.l  control_by_joy_directions(pc),d0
    beq.b   .nojoy0
    moveq	#0,d0
	bsr	_read_joystick

    lea	joy0(pc),a0
    move.l	d0,(a0)		
.nojoy0
    move.w  #$20,_custom+intreq
    move.w  #$C000,_custom+intena   ; enable interrupts again
    bra.b   .out
.copper
    move.l  sync_flag_value(pc),a0
    st  (a0)        ; game sets sync flag here
    move.w  #$10,_custom+intreq
.out
    movem.l (a7)+,d0/a0
    RTE
joypad_controls:
	movem.l	d0/a0/a1,-(a7)
	move.l	sync_flag_value(pc),a0
	move.l	copper_address_to_check(pc),a1
.wait
	; avoid lockup on table fadeout (winuae only?)
	; breaks the loop if this copperlist color value is fully black
	; (lockup occurred on fadeout)
	tst.w	(a1)
	beq.b	.break
	; original sync loop
	tst.b	(a0)
	beq.b	.wait
.break
	
	move.l	key_code_address(pc),a0
	move.b	(a0),d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
.noquit
    move.l  control_by_joy_directions(pc),d0
    bne.b   .forcejoycheck
	move.b	controller_joypad_1(pc),d0
	beq.b	.zap		; no need to check joypad...
.forcejoycheck
	moveq.l	#0,D0
	bsr.b	read_controls
	tst.b	D0
	beq.b	.zap
	movem.l	d1-d7/a2-a6,-(a7)
	move.l	key_code_address(pc),a3
	move.b	d0,(A3)
	move.l	update_controls_address(pc),a3
	jsr		(a3)	; update controls because a key was pressed/released
	movem.l	(a7)+,d1-d7/a2-a6
.zap
	movem.l	(a7)+,d0/a0/a1
	RTS


; < D0: joypad bits
; < D1: previous joypad bits
; < D2: bit to test
; < D3: keycode to set
; < A0: pointer on the pointer on the event buffer

test_button:
	btst	D2,D0
	bne.b	.pressed
	; not pressed: was it pressed before?
	btst	D2,D1
	beq.b	.out	; was not pressed earlier
	; just released: add "released" to keycode
	or.b	#$80,d3
	bsr	post_event
	rts
	
.pressed
	btst	D2,D1
	bne.b	.out	; was pressed before
	; just pressed: return keycode as-is
	bsr	post_event
	rts
.out
	rts
post_event
	move.l	(a0),a1
	; encodes it as it comes out of keyboard register
	not.b	d3
	rol.b	#1,d3
	; and push it in the "event queue"
	move.b	d3,(a1)+
	; and store pointer
	move.l	a1,(a0)
	rts

	
; in/out: D0 set to key code if pad presses
read_controls:
	movem.l	d0-d4/a0-a2,-(a7)
	lea	.previous_state_1(pc),a0
	move.l	(a0),d1
	move.l  joy1(pc),d0
	move.l	d0,(a0)		; save previous values for next time


	lea	event_queue_pointer(pc),a0

	move.l	#JPB_BTN_BLU,d2
	move.b	#$61,d3	; right shift
	bsr	test_button

	move.l	#JPB_BTN_LEFT,d2
	move.b	#$60,d3	; left shift
	bsr	test_button

	move.l	#JPB_BTN_DOWN,d2
	move.b	#$4D,d3	; pull spring
	bsr	test_button
	
	
	move.l	#JPB_BTN_UP,d2
	move.b	#$40,d3	; space: nudge up
	bsr	test_button
	
	move.l	#JPB_BTN_PLAY,d2
	move.b	#$19,d3	; p: pause
	bsr	test_button
    

	move.l	#JPB_BTN_REVERSE,d2
	move.b	#$64,d3	; left alt
	bsr	test_button
	
	move.l	#JPB_BTN_FORWARD,d2
	move.b	#$65,d3	; right alt
	bsr	test_button

	move.l	#JPB_BTN_RED,d2
	move.b	#$43,d3	; adds a player
	bsr	test_button
	
	
	move.l	#JPB_BTN_GRN,d2
	move.b	#$45,d3	; ESC
	bsr	test_button
	
	move.l	#JPB_BTN_YEL,d2
	move.b	#$15,d3	; Y
	bsr	test_button
	

    move.l  control_by_joy_directions(pc),d4
    beq.b   .nojoy
    
	move.l	#JPB_BTN_RIGHT,d2
	move.b	#$65,d3	; right alt
	bsr	test_button

    movem.l a0,-(a7)
	lea	.previous_state_0(pc),a0
	move.l	(a0),d1
	move.l  joy0(pc),d0
	move.l	d0,(a0)		; save previous values for next time
    movem.l (a7)+,a0
    
	move.l	#JPB_BTN_LEFT,d2
	move.b	#$15,d3	; Y
	bsr	test_button
	move.l	#JPB_BTN_RIGHT,d2
	move.b	#$36,d3	; N
	bsr	test_button
	move.l	#JPB_BTN_RED,d2
	move.b	#$45,d3	; ESC
	bsr	test_button
    
.nojoy
	; test if queue is empty
	lea	event_queue(pc),a2
	move.l	(a0),a1
	cmp.l	a1,a2
	beq.b	.queue_empty
	; process one event at a time
	; set value so D0 changes when exits
	move.b	-(a1),3(A7)
	move.l	a1,(a0)	; store the changed pointer
.queue_empty
	movem.l	(a7)+,d0-d4/a0-a2
	rts

.previous_state_0
	dc.l	0
.previous_state_1
	dc.l	0

load_music:
	lea	pl_intro_music(pc),a0
	lea	$40000,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	jsr	$40006
    rts
    
execute_intro:
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	skip_intro(pc),d0
	bne.b	.skip
	lea	pl_intro(pc),a0
	lea	$3000,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
    

    bsr load_music
	jsr	$3000.w
.skip
	movem.l	(a7)+,d0-d7/a0-a6	
	rts
not_game:
	cmp.l	#'SMUS',d0
	bne.s	not_music
	movem.l	d0-d7/a0-a6,-(a7)
	bsr load_music
	movem.l	(a7)+,d0-d7/a0-a6		
not_music:
	rts
pl_intro
	PL_START
	PL_PSS	$54,test_lmb,2
	PL_END
pl_intro_music
	PL_START
	PL_PSS	$17A,soundtracker_loop,2
	PL_PSS	$190,soundtracker_loop,2
	PL_PSS	$41A,soundtracker_loop,2
	PL_PSS	$430,soundtracker_loop,2
	PL_PSS	$B1A,soundtracker_loop,2
	PL_PSS	$B30,soundtracker_loop,2
	PL_END
soundtracker_loop
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
	move.w	(a7)+,d0
	rts 	
test_lmb:
	BTST.B #$0006,$00bfe001
	bne.b	.not_clicked	
	rts
.not_clicked:
	; also test joy fire
	BTST.B #$0007,$00bfe001
	rts
	
kill_sound:
	movem.l	d0/a0,-(a7)
	moveq	#0,d0
	lea	$dff000,a0
	move.w	d0,$a8(a0)
	move.w	d0,$b8(a0)
	move.w	d0,$c8(a0)
	move.w	d0,$d8(a0)
	move.w	#$f,$96(a0)
	movem.l	(a7)+,d0/a0
	rts		;3b6: 4e75


;---------------------------------------------
; STEEL WHEEL seperate protection
; Quite a clever idea, but not very well done!
 ;---------------------------------------------
 data:
	incbin	pd_checksum.bin
data_end:
data_len	=	data_end-data

depack:
	dc.l	0,0
store:
	dc.l	0
_resload:
	dc.l	0
	
_LoadFile:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		lea	si(pc),a0
		move.l	d0,(a0)
		movem.l	(a7)+,d0-d1/a0-a2
		rts
	

_SaveFile:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)
au:		movem.l	(a7)+,d0-d1/a0-a2
		rts

depacka:
	dcb.b	$1b4c-$1ab6
si:
	dc.l	0
	; the queue can hold 30 events, more than enough
event_queue:
	dcb.b	32
event_queue_pointer:
	dc.l	0


tags		dc.l	WHDLTAG_CUSTOM1_GET
skip_intro	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
control_by_joy_directions	dc.l	0
		dc.l	0
		
	