
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;USE_CHIPMEM

	IFD BARFLY
	OUTPUT	"FantasticDizzyAGA.slave"
	IFND	USE_CHIPMEM
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-			;disable mul optimizing
	BOPT	ODe-			;disable mul optimizing
	BOPT	OD07-			;disable move.? #0,EA to clr.? EA 
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD	USE_CHIPMEM
HRTMON
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;INITAGA
HDINIT
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'

IGNORE_JOY_DIRECTIONS
EXTSGFONT

	include	whdload/kick13.s
	include ReadJoyPad.s
	include savegame.s
	
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


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

slv_config:
    dc.b    "C1:X:Infinite lives:0;"
    dc.b    "C2:X:Blue button jumps:0;"
    dc.b    "C3:L:Start with lives:2,3,4,5;"
	dc.b	0
	
slv_name		dc.b	"Fantastic Adventures of Dizzy (AGA)"
	IFD	USE_CHIPMEM
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1994 Codemasters",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"load/save gfx fix by ross",10,10
		dc.b	"Use CD pad forward to show inventory (Shift)",10
		dc.b	"Use CD pad reverse to show menu (ESC)",10
		
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"FANTASTIC_DIZZY",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
		clr.l	$0.W

		bsr	_detect_controller_types
		
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload

		
		
	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)

	; allocate room for savegame screen
		move.l	#$2800,D0
		move.l	#MEMF_CHIP,d1
		move.l	(4),a6
		jsr		(_LVOAllocMem,a6)
		lea	_save_screen(pc),a0
		move.l	d0,(a0)
		
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		bsr	check_version 
	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_exe(pc),a5
		bsr	load_exe
	;quit
_quit	pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)
		
check_version:
	movem.l	d0-d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#485716,D0
	beq.b	.ok
	cmp.l	#0,D0
	beq.b	.ok		; let LoadSeg fail if file not found


	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.ok
	movem.l	(a7)+,d0-d1/a1
	rts
; < d7: seglist (APTR)

patch_exe
    IFD USE_CHIPMEM
    move.l  d7,a1
    add.l   a1,a1
    add.l   a1,a1
    addq.l  #4,a1
    move.l  a1,$100.W
    ENDC
    
	move.l	(_resload,pc),a2
	lea	pl_main(pc),a0
	move.l	d7,a1
	jsr	(resload_PatchSeg,a2)
	
	move.l	start_nb_lives(pc),d0
	beq.b	.skip
	addq.l	#2,d0
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	lea	($0053d2+4,a1),a1
	move.w	d0,(a1)
.skip
	rts
	
pl_main
	PL_START
	; VBR,A0 => 0=>A0
	PL_L	$0004aa,$91C84E71
	; pause test
	PL_PS	$00c314,pause_test
	; quitkey even with novbrmove
	PL_PS	$DB6,keyboard
	PL_PS	$172ae,shift_test
	PL_IFC1
	; infinite lives
	PL_NOP	$016526,4
	PL_NOP	$0169e8,4
	PL_ENDIF
	; game load/save
	PL_P	$0190f0,save_game
	PL_P	$019108,load_game
	PL_NOP	$0140ae,2		; savegame is ALWAYS available
	PL_IFC2
    PL_PSS  $000eea,read_controls,6
	PL_ENDIF
    
    ; dma wait (sound)
    ;;PL_PS   $1a63c,dma_wait  ECS offset!
    PL_PS   $01b386,dma_wait_off
    PL_PSS  $01b452,dma_wait_on,2
	PL_END

read_controls:
    MOVE.W	(12,A6),D0    
    movem.l d1-d2,-(a7)
    bsr _read_joysticks_buttons
 	move.b	in_game_flag(pc),d2
	move.l  joy1_buttons(pc),d1
    beq.b   .no_blue
   
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed
	bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
    not.l   d1      ; inverted logic
    btst    #JPB_BTN_RED,d1
    movem.l (a7)+,d1-d2
    rts
    
dma_wait_on
	ORI.W	#$8000,D7		;: 00478000
	MOVE.W	D7,(150,A6)		;01b456: 3d470096
    bra dw
dma_wait_off
  	MOVE.W	D5,150(A6)		;1a63c: 3d450096
	OR.W	D5,D7			;1a640: 8e45
dw:    
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
    
    RTS
    
	
TEST_BUTTON_AS_KEY:MACRO
	btst	#JPB_BTN_\1,d0
	beq.b	.nopress_\1
	; button is pressed. Is this the first time?
	btst	#JPB_BTN_\1,d1
	bne.b	.out_\1
	; first time button press
	MOVE.B	#\2,d2
	ST.B	(204+\2,A5)
	bra.b	.out_\1
.nopress_\1
    ; button isn't pressed. Was it just released ?
	btst	#JPB_BTN_\1,d1
	beq.b	.out_\1
	; player just released play button
	CLR.B	(204+\2,A5)
.out_\1
	ENDM
	
SAVEGAME_SIZE = $5118

; < A0: save game data
; < A1: buffer to save into (we'll use it as screen buffer :))

save_game:
	move.l	#SAVEGAME_SIZE,d0			;savegame size
	;;lea	$3e900,a0		;address of savegame already in A0
	move.l _save_screen(pc),a1		;free mem for screen
	movem.l	D0-D7/A0-A6,-(a7)
	lea	(_savename,pc),a2	;name of savegame file
	bsr	_sg_save
	movem.l	(a7)+,D0-D7/A0-A6
	RTS

; < A0: save game data
; < A1: buffer to save into (we'll use it as screen buffer :))

load_game
	movem.l	D0-D7/A0-A6,-(a7)
	MOVE.W	#SAVEGAME_SIZE,D0		;019108: 303c5119
	lea	(_savename,pc),a2	;name of savegame file
	move.l _save_screen(pc),a1		;free mem for screen
	bsr	_sg_load
	movem.l	(a7)+,D0-D7/A0-A6
	RTS				;019112: 4e75
	
read_buttons:
	movem.l	d0-d2/a0,-(a7)
	moveq.l	#0,d2
	lea	previous_button_state(pc),a0
	move.l	(a0),d1
	;;bsr	_read_joysticks_buttons
	move.l  joy1_buttons(pc),d0
    
	; d0: current button state
	; d1: previous button state
	TEST_BUTTON_AS_KEY	PLAY,$19
	TEST_BUTTON_AS_KEY	REVERSE,$45
	TEST_BUTTON_AS_KEY	FORWARD,$60

	
	tst.b	d2
	beq.b	.nopress
	move.b	d2,(338,A5)		;00c314: 0c2d00190152
.nopress
	move.l	d0,(a0)
	movem.l	(a7)+,d0-d2/a0
	rts

shift_test:
	lea	in_game_flag(pc),a0
	st.b	(a0)
	bsr	read_buttons
	LEA	(300,A5),A0		;0172ae: 41ed012c
	TST.B	(A0)+			;0172b2: 4a18
	rts
	
pause_test:
	bsr	read_buttons
	CMPI.B	#$19,(338,A5)		;00c314: 0c2d00190152
	rts

previous_button_state
	dc.l	0
	
in_game_flag:
	dc.b	0
	even
	
keyboard:
	ROR.B	#1,D0			;000db6: e218
	MOVEQ	#0,D1			;000db8: 7200
	MOVE.B	D0,D1			;000dba: 1200
	cmp.b	_keyexit(pc),d0
	beq.b	_exit

	rts

_exit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
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
	movem.l	d2/a4,-(a7)
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
_save_screen
	dc.l	0
tag		dc.l	WHDLTAG_CUSTOM3_GET
start_nb_lives	dc.l	0
		dc.l	0

_savename
	dc.b	"saves",0
_font		INCBIN	xen_8.bin

		
;============================================================================

	END
