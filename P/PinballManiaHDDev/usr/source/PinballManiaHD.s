;*---------------------------------------------------------------------------
;  :Program.	PinballManiaHD.asm
;  :Contents.	Slave for "PinballMania"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: PinballManiaHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/nonvolatile.i

	IFD	BARFLY
	OUTPUT	"PinballMania.slave"

	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;CHIP_ONLY
	IFD	CHIP_ONLY
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0
	ELSE
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $40000
	
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG	; without it access faults
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CBDOSLOADSEG
CACHE

; use built-in libs, not the ones on disk
INIT_LOWLEVEL
INIT_NONVOLATILE

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_NoKbd|WHDLF_ReqAGA|WHDLF_Req68020
slv_keyexit	= $5D	; num '*'


;============================================================================

IGNORE_JOY_PORT0

	INCLUDE	whdload/kick31.s
	INCLUDE	ReadJoyPad.s
	
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

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
	dc.b	$A,0

slv_name		dc.b	"Pinball Mania"
	IFD		CHIP_ONLY
	dc.B	" (debug/chip mode)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1995 21st Century Entertainment",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	
slv_config:
	dc.b    "C2:B:Full control by 2 joysticks;"
    ;dc.b	"C3:L:Start level:menu,tarantula,jail break,kick-off,jackpot;"
	dc.b	0

pmam_name
	dc.b	"PMAMx",0

program:
	dc.b	"mania",0
args		dc.b	10
args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment


; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg:
	move.l	d1,a3
	add.l	a3,a3
	add.l	a3,a3
	move.l	d0,a0
	add.l	a0,a0
	add.l	a0,a0

	cmp.b	#'P',1(a0)
	bne.b	.out		; not a patchable file
	cmp.b	#'0',5(a0)
	bne.b	.tables		; corrupt overlay exe shit
	; menu
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_menu(pc),a0
	lea	(4,a3),a1
	
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
.out
	rts

.tables:
	movem.l	d0-d1/a0-a2/a6,-(a7)
	; detect joypads, with interrupts disabled
	move.l	(4),a6
	jsr	_LVODisable(a6)
	bsr	_detect_controller_types
	jsr	_LVOEnable(a6)

	lea	event_queue(pc),a2
	lea	event_queue_pointer(pc),a0
	move.l	a2,(a0)
	
	lea	pl_tables(pc),a0
	lea	(4,a3),a1
	
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2/a6
	rts

pl_menu
	PL_START
	PL_L	$000fe,$70004E71	; VBR
	PL_END
	
pl_tables
	PL_START
	PL_PS	$1D8,patch_table
	PL_PS	$118,set_memory_type
	PL_END


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
	move.b	#$60,d3	; left shift
	bsr	test_button
	
	move.l	#JPB_BTN_FORWARD,d2
	move.b	#$61,d3	; right shift
	bsr	test_button

	move.l	#JPB_BTN_RED,d2
	move.b	#$50,d3	; F1: start
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


set_memory_type
	movem.l	D2/a0,-(a7)
	
	or.l	#MEMF_CLEAR,D1
	; relocate table program to fastmem for faster game
	moveq.l	#0,d2
	cmp.l	#$A1C8,d0
	beq.b	.main_prog
	addq.l	#1,d2
	cmp.l	#$A0A4,d0
	beq.b	.main_prog
	addq.l	#1,d2
	cmp.l	#$A0F4,d0
	beq.b	.main_prog
	addq.l	#1,d2
	cmp.l	#$A298,d0
	bne.b	.no_main_prog
.main_prog
	lea		table_index(pc),a0
	move.w	d2,(a0)
	IFND	CHIP_ONLY
	; remove chipmem requirement so game runs in fastmem
	bclr	#MEMB_CHIP,d1
	ENDC
.no_main_prog

	movem.l	(a7)+,d2/a0
	rts
	
patch_table
	
	movem.l	d0-d1/a0-a3,-(a7)
	add.l	A4,A4
	add.l	A4,A4
	addq.l	#4,a4
	
	move.w	table_index(pc),d0
	add.w	d0,d0
	lea		patchlist_table(pc),a1
	move.w	(a1,d0.w),a0
	add.l	a1,a0		; a0: patchlist
	
; table 1: skip access faults
	move.l	a4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)


	movem.l	(a7)+,d0-d1/a0-a3
	rts

patchlist_table
	dc.w	_pl_table1-patchlist_table
	dc.w	_pl_table2-patchlist_table
	dc.w	_pl_table3-patchlist_table
	dc.w	_pl_table4-patchlist_table
	
_pl_table1:
	PL_START
	PL_PSS	$2200,_fix_af_2,2
	PL_PSS	$e00,keyboard_hook,2
	PL_PS	$d94,vbl_hook
	PL_NEXT	_pl_table_common
	
_pl_table2:
	PL_START
	PL_PSS	$c76,keyboard_hook,2
	PL_PS	$bf2,vbl_hook
	PL_NEXT	_pl_table_common

_pl_table3:
	PL_START
	PL_PS	$33FA,_fix_af_1
	PL_PS	$341A,_fix_af_1
	PL_PS	$343A,_fix_af_1
	PL_NOP	$2090,2
	PL_PS	$2092,_fix_af_2
	PL_PS	$27A2,_fix_af_3
	
	PL_PSS	$c8a,keyboard_hook,2
	PL_PS	$c06,vbl_hook

	PL_NEXT	_pl_table_common

_pl_table4:
	PL_START
	PL_PSS	$c76,keyboard_hook,2
	PL_PS	$bf2,vbl_hook
	PL_NEXT	_pl_table_common
	
_pl_table_common
	PL_START
	PL_L	$2e2,$70004E71		; VBR
	PL_END
	
vbl_hook
	AND.W	$dff01c,D0		;30d94: c07900
	move.w	D0,-(a7)
	btst	#5,d0
	beq.b	.out
	; read the joypad
    ; this is VBL, read joypad here, seems to cause trouble if done
    ; somewhere else, because reading potentiometers are better done
    ; at the start of the vertical blank, or else they could be not available
	move.l	D1,-(a7)
    bsr _joystick
	move.l	(a7)+,d1
    move.l  control_by_joy_directions(pc),d0
    beq.b   .out
    moveq	#0,d0
	bsr	_read_joystick
	move.l	a0,-(a7)
    lea	joy0(pc),a0
    move.l	d0,(a0)
	move.l	(a7)+,a0
	
.out
	move.w	(a7)+,d0
	btst	#5,d0
	rts
	
keyboard_hook:
	BTST	#3,D0			;30e00: 08000003
	bne.b	.key_pressed	; key pressed: do nothing
	; key not pressed but are joypad buttons pressed/released
	moveq.l	#0,D0
	bsr	read_controls
	tst.b	D0
	beq.b	.no_key_pressed
	addq.l	#6,(a7)
	rts
.no_key_pressed
	addq.l	#4,a7	; pop up stack
.key_pressed
	rts
	
_fix_af_1:
	move.l	a0,d0
	bmi.b	.skip

	moveq	#0,d0
	move.w	(a0),d0
	lsl.w	#4,d0
	rts
.skip
	moveq	#0,d0
	rts

_fix_af_2:
	movem.l	d0,-(a7)
	move.l	($10,a3),d0
	and.l	#$1FFFFF,d0
	move.l	d0,a5
	move.w	(-4,a5),d1
	movem.l	(a7)+,d0
	rts

_fix_af_3:
	movem.l	d0,-(a7)
	move.l	a1,d0
	and.l	#$1FFFFF,d0
	move.l	d0,a1
	addq.l	#8,a1		; orig
	lea	12(a2),a2	; orig
	movem.l	(a7)+,d0
	rts
	
; remove VBR read on first segment of files pinball



_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		move.l	_resload(pc),a2
		jsr	(resload_Control,a2)

	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	IFD	CHIP_ONLY
	move.l	A6,-(a7)
	move.l	4,a6
	move.l	#$30000-$00025890,d0
	;move.l	#$30000-$00025890+($10000-$e938),d0  ; align menu
	move.l	#MEMF_CHIP,D1
	jsr		_LVOAllocMem(a6)
	move.l	(a7)+,a6
	ENDC
	
	;load exe
		lea	args(pc),a1
		move.l	#args_end-args,d0

		move.l	start_table(pc),d0
		beq.b	.ok
		lea	pmam_name(pc),a0
		add.b	#'0',d0
		move.b	d0,4(a0)	; PMAM1,2,3,4...
		sub.l	a5,a5		; patch is done though cb_dosloadseg
		bra.b	.load
.ok
		lea	program(pc),a0
		lea	_patch_mania(pc),a5
.load
		bsr	_load_exe

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)


_patch_mania:
	move.l	d7,a1
	addq.l	#4,a1
	lea	_pl_mania(pc),a0
	jsr	resload_Patch(a2)
	rts

_pl_mania:
	PL_START
	PL_PS	$812,_sort_scores
	PL_END

; < a2: score buffer

_sort_scores:
	; the scores are not sorted properly when stored
	; bubblesort them now

	movem.l	d0-d7/a0-a1/a3,-(a7)
	lea	8(a2),a3	; start
	moveq	#3,d4
.loop0
	move.l	a3,a0
	moveq	#2,d0		; repeat 3 times
.loop1
	move.l	d0,d1		; repeat d0 times
	lea	12(a0),a1	; start (ptr 2)

.loop2
	cmp.l	a0,a1
	beq.b	.skip		; same item

	move.l	4(a0),d2	; hiscore1 (BCD)
	move.l	4(a1),d3	; hiscore2
	cmp.l	d3,d2
	bcs.b	.swap
	bne.b	.skip

	; Most sig. scores are equal, test lowest

	move.l	8(a0),d2	; hiscore1 (BCD)
	move.l	8(a1),d3	; hiscore2
	cmp.l	d3,d2
	bcc.b	.skip		; d2 >= d3

	; swap both scores and names
.swap
	move.l	8(a0),-(a7)
	move.l	4(a0),-(a7)
	move.l	(a0),-(a7)

	move.l	(a1),(a0)
	move.l	4(a1),4(a0)
	move.l	8(a1),8(a0)

	move.l	(a7)+,(a1)
	move.l	(a7)+,4(a1)
	move.l	(a7)+,8(a1)

.skip
	lea	12(a1),a1	; next score
	dbf	d1,.loop2

	lea	12(a0),a0	; next score
	dbf	d0,.loop1

	lea	12*4(a3),a3	; next table
	dbf	d4,.loop0

	movem.l	(a7)+,d0-d7/a0-a1/a3

	; original code

	jsr	_LVOStoreNV(a6)
	tst.l	d0
	rts


tag		
	dc.l	WHDLTAG_CUSTOM2_GET
control_by_joy_directions
	dc.l	0
	dc.l	WHDLTAG_CUSTOM3_GET
start_table	dc.l	0
		dc.l	0

table_index
	dc.w	0
	; the queue can hold 30 events, more than enough
event_queue:
	ds.b	32
event_queue_pointer:
	dc.l	0
	
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
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
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

;============================================================================

	END
