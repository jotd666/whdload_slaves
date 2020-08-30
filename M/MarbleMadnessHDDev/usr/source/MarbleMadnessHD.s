;*---------------------------------------------------------------------------
;  :Program.	MarbleMadness.asm
;  :Contents.	Slave for "MarbleMadness"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
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
	OUTPUT	"MarbleMadness.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
;============================================================================

;DEBUG

; wondering why that game needs more than 512k when running on kickemu...
; it requires 512k on a real amiga since 1986. well...

	IFD	DEBUG
FASTMEMSIZE = $0
CHIPMEMSIZE	= $C0000
	ELSE
FASTMEMSIZE	= $40000
CHIPMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

STACKSIZE = 8000
SETPATCH
BLACKSCREEN

; the diskimage version allows to load the diskimage in RAM
; at once, and avoids constant disk access (ex: with CD32load)
; this is the base for the CD32 version with audio tracks
; it uses an image of the cracked version (cracked exe)

	IFD	DISKIMAGE
DISKSONBOOT
CBDOSLOADSEG
	ELSE
;
;DOSASSIGN
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
BOOTDOS
HDINIT
	ENDC
	
;============================================================================


slv_Version=17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	include 	kick13.s


;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name		dc.b	"Marble Madness"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1984-1986 Atari Games & Electronic Arts",0
slv_info		dc.b	"Installed & fixed by JOTD",10,10
			dc.b	"Version "
			DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
	dc.b	"BW;"
	dc.b    "C1:X:Trainer Infinite Time (ESC=game over):0;"
	dc.b    "C2:X:Sound effects only (no music):0;"
	dc.b    "C3:L:Start level:Practice,Beginner,Intermediate,Aerial,Silly,Ultimate;"			
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	even
	
intro:
	dc.b	"c/bootscr",0
introargs:
	dc.b	"c/splash"	; no linefeed or it doesn't work, buggy argument parsing for bootscr
introargs_end:
	dc.b	0
	even
	IFD	BOOTDOS
program:
	dc.b	"MarbleMadness!",0
args
	dc.b	10
args_end
	dc.b	0
	EVEN

	
_bootdos

	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
		

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
; useful when stubbing dos C wrappers
		lea	_dosbase(pc),a0
		move.l	a6,(a0)
		
; load intro screen

	lea	intro(pc),a0
	lea	(introargs,pc),a1
	sub.l	a5,a5
	move.l	#introargs_end-introargs,d0
	bsr	_load_exe

	move.l	_buttonwait(pc),d0
	beq.b	.skw
.lmbloop
	btst	#6,$bfe001
	bne.b	.lmbloop
.skw

; load main program
	lea	program(pc),a0
	lea	(args,pc),a1
	move.l	#args_end-args,d0
	lea	patch_exe(pc),a5
	bsr	_load_exe

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
	movem.l	d2/d7/a4,-(a7)
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
	ENDC
	
	IFD	CBDOSLOADSEG

get_tags:
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts
; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	movem.l	d7,-(a7)

	lsl.l	#2,d0
	move.l	d0,a0
	addq.l	#1,a0
	bsr	get_long

	cmp.l	#'c/bo',d0
	bne.b	.skip_intro
	
	move.l	d1,d7
	bsr	patch_intro
	bra.b	.noboot
	
.skip_intro
	cmp.l	#'Marb',D0
	bne.b	.skip
	bsr	get_tags
	
	move.l	_buttonwait(pc),d0
	beq.b	.skw
.lmbloop
	btst	#6,$bfe001
	bne.b	.lmbloop
.skw
	move.l	d1,d7	; so we can reuse the patch_exe routine
	bsr	patch_exe
.skip
.noboot
	movem.l	(a7)+,d7
	rts

_quit
	PEA	TDREASON_OK
	MOVE.L	_resload(PC),-(A7)
	add.l	#resload_Abort,(a7)
	rts

; < A0: address
; > D0: longword
get_long
	move.l	a0,-(a7)
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	move.l	(a7)+,a0
	rts
	

patch_intro:
	move.l	_resload(pc),a2
	move.l	d7,a1
	lea	pl_intro(pc),a0
	jsr	(resload_PatchSeg,a2)
	rts
	
open_get_args
	MOVEM.L	16(A7),D1-D2
	move.l	D1,A0
.loop
	move.b	(a0),d1
	beq.b	.out
	cmp.b	#$A,d1
	bne.b	.cont
	MOVEM.L	16(A7),D1-D2
	;lea	introargs(pc),a0
	;move.l	a0,d1
	RTS
.cont
	addq.l	#1,a0
	bra.b	.loop
.out
	MOVEM.L	16(A7),D1-D2
	rts

pl_intro
	PL_START
	PL_PS	$1dac,open_get_args
	PL_END
	

	ENDC
	
patch_exe:
	move.l	d7,d1
	add.l	d1,d1
	add.l	d1,d1
	moveq.l	#3,d2
	bsr		get_section
	lea	$005D2-$224(a0),a2
	lea	game_state_address(pc),a4
	move.l	a2,(a4)
	
	move.l	_resload(pc),a2
	move.l	d7,a1
	lea	pl_main(pc),a0
	jsr	(resload_PatchSeg,a2)

	;disable cache
	move.l	#WCPUF_Exp_NCS,d0
	move.l	#WCPUF_Exp,d1
	jsr	(resload_SetCPU,a2)

	rts

pl_main
	PL_START
	; section 14
	PL_PS	$02CF0,key_control
	; section 61
	PL_W	$09910+$E6,$4E71
	PL_PS	$09910+$E8,fix_accessfault_level1
	; section 77, decrease seconds for both players	
	PL_PS	$0B566,seconds_count
	
	; section 90
	PL_L	$CF46,'Mous'
	PL_B	$CF4A,'e'

	PL_W	$CF56,"Jo"
	PL_B	$CF58,"y"
	PL_B	$CF59,$20
	; section 245
	PL_PS	$1E684,fix_accessfault_level5
	
	PL_PS	$033FA,set_start_level
		

	; section 336

	PL_IFC2
	PL_NOP	$1F384,4
	PL_ENDIF
	
	;;PL_PS	$2099A,ingame_loop
	
	PL_END
	; I had a hard time figuring out both A5 pointer origins, so let's bruteforce it
seconds_count
	movem.l	d1/a0/a1,-(a7)
	move.b	pause_flag(pc),d1
	beq.b	.unpause
	lea	pause_flag(pc),a0
	clr.b	(a0)
.wait
	btst.b	#6,$BFE001
	beq.b	.unpause
	btst.b	#7,$BFE001
	beq.b	.unpause
	bra.b	.wait
.unpause
	
	lea	player_seconds_table(pc),a0
	tst.l	(a0)
	bne.b	.first_slot_full
	; first slot zero: store this A5 value for later
	move.l	A5,(a0)
	bra.b	.all_slots_full
.first_slot_full
	addq.l	#4,a0
	tst.l	(a0)
	bne.b	.all_slots_full
	; second slot zero: store this A5 value for later
	move.l	A5,(a0)	
.all_slots_full
	MOVE	(A5),D0			;0B566: 3015	; red/blue player seconds count
	move.l	_infinte_time(pc),d1
	beq.b	.normal
	; not active if not enough seconds
	; leaves power to ESC button which sets seconds to 0
	; and that cannot happen any other way
	cmp.w	#5,d0
	bcs.b	.normal
	move.w	#100,d0
.normal
	SUBQ	#1,D0			;0B568: 5340	; sub seconds
.set
	MOVE	D0,(A5)			;0B56A: 3A80
	
	; on level select, add seconds bonus for both players, only once
	move.l	player_seconds_table+4(pc),d1
	beq.b	.noadd	; no second player/first time in the routine: do nothing

	moveq	#0,d1
	lea	seconds_bonus(pc),a0
	move.b	(a0),d1
	beq.b	.noadd
	clr.b	(a0)
	move.l	player_seconds_table(pc),a0
	add.w	d1,(a0)
	move.l	player_seconds_table+4(pc),a1
	cmp.l	a1,a0
	beq.b	.noadd	; no second player
	add.w	d1,(a1)
.noadd

	movem.l	(a7)+,d1/a0/a1
	RTS
	
	
set_start_level
	move.l	_start_level(pc),d0
	movem.l	a0/a1,-(a7)
	; reset table (in case we switch from 2 players to 1 player)
	
	bsr	set_seconds_to_zero
	
	lea	player_seconds_table(pc),a0
	clr.l	(a0)+
	clr.l	(a0)
	
	lea	seconds_bonus_table(pc),a1
	lea	seconds_bonus(pc),a0
	move.b	(a1,d0.w),(a0)
	movem.l	(a7)+,a0/a1
	rts

set_seconds_to_zero
	move.l	player_seconds_table(pc),a0
	cmp.l	#0,a0
	beq.b	.skip
	clr.w	(a0)
	move.l	player_seconds_table+4(pc),a0
	cmp.l	#0,a0
	beq	.skip
	clr.w	(a0)
.skip
	rts
	; preserving more than D0 & A0 breaks the game
	; that's what I call shaving the stack too close...
	; even like that it crashes, so relocating the stack somewhere else
	; just for that routine (I feel that there are some issues with the code,
	; like returning references to local variables, calling this function, then trying to useful
	; those references. Works until the stack is used... classic error.
key_control:
	move.l	A7,$104.W
	lea	.local_stack(pc),a7
	movem.l	D0/A0,-(A7)
	move.b	$BFEC01,D0
	not.b	D0
	ror.b	#1,D0
	move.b	#0,$BFEC01	; we're the only ones reading this
	lea		old_sdr_value(pc),a0
	cmp.b	(a0),d0
	beq	.skip		; same key as previously: skip
	move.b	d0,(a0)
	cmp.b	#$45,D0	
	bne.b	.noesc
	; set seconds to 0 for both players
	bsr	set_seconds_to_zero

	
	bra	.skip
.noesc
	cmp.b	#$50,D0		; F1
	bne.b	.noadd
	; add 10 seconds for each player
	lea	seconds_bonus(pc),a0
	move.b	#10,(a0)
	bra	.skip

.noadd
	;;IFD	DEBUG
	cmp.b	#$5F,D0		; HELP
	bne.b	.nohelp
	; that doesn't work, because none of the players gets the
	; "player ended race" flag, so skips to next level without any
	; active player...
	move.l	game_state_address(pc),a0
	move.w	#3,(a0)		; level completed
.nohelp
	;;ENDC
	cmp.b	#$19,D0		; HELP
	bne.b	.nopause
	lea	pause_flag(pc),a0
	st.b	(a0)
.nopause
.skip
	movem.l	(A7)+,D0/A0
	move.l	$104.W,A7
	lea	$100.W,A0	; original game
	rts

	ds.l	$100
.local_stack:

fix_accessfault_level1:
	move.l	D0,-(a7)
	move.l	A4,D0
	bmi.b	.avoid
.move
	move.b	(A4),-(A3)
	move.b	(2,A4),($24,A3)
	move.l	(A7)+,D0
	rts
.avoid
	lea	.zeros(pc),A4
	bra.b	.move
.zeros:
	dc.l	0,0,0,0

; < d1 seglist
; < d2 section #
; > a0 segment
get_section
	move.l	d1,a0
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a0),a0
	add.l	a0,a0
	add.l	a0,a0
	dbf	d2,.loop
.out
	addq.l	#4,a0
	rts
; access fault at mad level (5), when a bird hits the marble

fix_accessfault_level5:
	cmp.l	#-1,A0
	beq.b	.bypass

	move.b	(A0),D1
	ext.w	D1
	ext.l	D1
.bypass:
	addq.l	#4,A7
	movem.l	(A7)+,D2-D7/A2-A5
	unlk	A6
	rts

;---------------

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_infinte_time	dc.l	0
	dc.l	WHDLTAG_BUTTONWAIT_GET
_buttonwait
	dc.l	0
	dc.l	WHDLTAG_CUSTOM3_GET
_start_level	dc.l	0
	dc.l	0
_dosbase
	dc.l	0
game_state_address:
	dc.l	0
player_seconds_table
	dc.l	0,0
seconds_bonus:
	dc.b	0
pause_flag
	dc.b	0
seconds_bonus_table:
	dc.b	0,0,40,50,55,60,65
old_sdr_value:
	dc.b	0

	even


;============================================================================

	END
