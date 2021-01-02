;*---------------------------------------------------------------------------
;  :Program.	MoktarHD.asm
;  :Contents.	Slave for "Moktar"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: MoktarHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"Moktar.slave"
	IFND	CHIP_ONLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

; infinite level 1 1BCF9 23105
; ladders: level 3
;============================================================================
; scroll/Y: 0001BDC7=00D8 0001BDCF=00D8
; Y no scroll (at start) 0003F16C=00CC 0003F1F0=00CC 0003F274=00CC 0003F2F8=00CC

	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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

assign
	dc.b	"df0",0

slv_name		dc.b	"Moktar / Titus The Fox"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1991-1992 Titus",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Set CUSTOM3=2/14 (Titus) 15 (Moktar) for start level",10
			dc.b	10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"main",0
args		dc.b	"r",10
args_end
	dc.b	0
slv_config
	dc.b    "C1:X:Trainer Infinite lives:0;"
	dc.b    "C1:X:Trainer Infinite energy:1;"
	dc.b    "C2:B:2nd button jumps;"
	dc.b    "C3:L:Start level:1 - On the foxy trail,2 - Looking for clues,3 - Road works ahead,4 - Going underground,5 - Flaming Catacombes,6 - Coming to town,7 - Foxys den,"
    dc.b    "8 - On the road to Marrakesh,9 - Home of the Pharaos,10 - Desert experience,11 - Walls of sand,12 - A beacon of hope,"
    dc.b    "13 - A pipe dream,14 - Going home,15 - Arrival in Paris (Moktar only);"			
    dc.b    "C4:B:preserve original level codes;"
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN
	include	ReadJoyPad.s
	
_bootdos
		bsr	_detect_controller_types
        
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)


patch_main
	movem.l	d0-d7/a0-a3,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#98568,D0
	beq.b	moktar_v1

	cmp.l	#98276,d0
	beq.b	moktar_v2

	cmp.l	#99108,d0
	beq.b	titus_fox

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
moktar_v1
	move.l	#$D45E-$33A4,d3
	move.l	#$10,D4
	move.l	#$516-8,d5
	lea	pl_v1(pc),a0
	bra.b	generic_patch
	

moktar_v2
	move.l	#$D2F6-$32D0,d3
	move.l	#$10,D4
	move.l	#$514-8,d5
	lea	pl_v2(pc),a0
	bra.b	generic_patch


titus_fox
	lea	pl_titus(pc),a0
	move.l	#$D648-$3414,d3 ; start level value on section 3
	move.l	#$0F,D4     ; one level is missing
	move.l	#$516-8,d5
	;;bra	generic_patch
	
generic_patch
	moveq	#1,d2
	bsr	get_section
	add.l	d5,a1
	lea		ladder_position_address(pc),a3
	move.l	a1,(a3)
    ;;move.l  a1,$100.W
	
	move.l	start_level(pc),d0
	beq	.nostart
	addq.l	#1,d0
	cmp.l	d4,d0
	bcc.b	.nostart	; too high
	moveq	#3,d2
	bsr	get_section
	add.l	d3,A1
	move.w	d0,(a1)	; set start level
.nostart
	move.l	d7,d0
	lsr.l	#2,d0
	move.l	d0,a1
	jsr	resload_PatchSeg(a2)
	movem.l	(a7)+,d0-d7/a0-a3
	rts
	

patch_dbf
	move.l	#$190,d0
	bsr	emulate_dbf
	add.l	#2,(A7)
	rts


; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
	rts

read_joy_directions_jump_up:
	bsr	read_joy_directions
	move.w	$DFF00C,D0
	rts
	
read_joy_directions:
	movem.l	d1-d3/a0-a1/a5,-(a7)
	lea	button_states(pc),a0
	lea	previous_button_states(pc),a1
	move.l	(a0),(a1)		; save previous state
	moveq.l	#1,d0
	bsr	_read_joystick
	move.l	d0,(a0)
	
	; quit slave
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nq
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nq
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nq
	bra		QUIT
.nq	

	;;move.l	key_table(pc),a5
	
	btst	#JPB_BTN_PLAY,d0
	beq.b	.no_pause

	; custom pause, as it's as easy as plugging unpause
.waitrel
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	bne.b	.waitrel
.waitpress
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	beq.b	.waitpress
.waitrel2
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	beq.b	.no_pause
	
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nq2
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nq2
	bra		QUIT
.nq2
	
	bra.b	.waitrel2
	
.no_pause
	move.l	previous_button_states(pc),d1
	move.l	button_states(pc),d0
	
;	btst	#JPB_BTN_YEL,d0	; yellow on?
;	beq.b	.noyel
;	btst	#JPB_BTN_YEL,d1	; was it pressed previously?
;	bne.b	.noyel
	; first time pressed: filter on/off
;	nop
	;;eor.b	#1,($35B-$2B4,a5)
;.noyel


	; F2: quits
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noquit
	nop
.noquit

	
	movem.l	(a7)+,d1-d3/a0-a1/a5
	RTS
	
_read_joystick_port_1
	moveq.l	#1,d0
	bsr	_read_joystick
	rts
	
read_fire_button
    movem.l d1,-(a7)
    move.l	button_states(pc),d1
    btst    #JPB_BTN_RED,d1
    seq     d0      ; d0 is at zero upon enter, if not pressed, set all bits to 1
    movem.l (a7)+,d1
    rts

; thanks to robinsonb5@eab for the idea		
read_joy_directions_jump_button:
	bsr	read_joy_directions
	movem.l	d1/a0,-(a7)
	move.l	button_states(pc),d0
	moveq.l	#0,d1
	move.w	$DFF00C,D1
	move.l	ladder_position_address(pc),a0
	cmp.w	#4,(a0)		; on ladder already?
	beq.b	.no_blue
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d1
	btst	#9,d1
	beq.b	.noneed
	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	move.l	d1,d0
	movem.l	(a7)+,d1/a0
	RTS
	
; difficult to find a non-relocated 6-bytes length section in this program...
mainloop_hook:

	; original code, adapted to emulate the BEQ thing
	CMPI.W	#$0010,D0		;0d848: 0c400010
	BEQ.S	.skip		;0d84c: 6710
	rts
.skip
	add.l	#$10,(A7)	; emulate BEQ
	rts
    
    
pl_v1
	PL_START
	; section 3
	PL_B	$CC4C,$60	; skip protection test
	PL_W	$CC4C-50,$6004	; skip disk hw access
	PL_PS	$75B8,patch_dbf
	PL_IFC1X	0
	; infinite energy
	PL_NOP	$98F4,6
	PL_ENDIF
	PL_IFC1X	1
	PL_NOP	$DE78,2
	PL_ENDIF
	; jump: 2nd button
	PL_IFC2
	PL_PS	$49c4,read_joy_directions_jump_button
	PL_PS	$4a20,read_joy_directions_jump_button
	PL_ELSE
	PL_PS	$49c4,read_joy_directions_jump_up
	PL_PS	$4a20,read_joy_directions_jump_up
	PL_ENDIF
	; mainloop hook
	PL_PS	$d848,mainloop_hook
    
    ; fire button
    PL_PS   $04ad0,read_fire_button
    
    PL_IFC4
    PL_ELSE
    PL_DATA    $1154,80
    dc.b    "0001-0002-0003-0004-0005-0006-0007-0008-0009-0010-0011-0012-0013-0014-0015-0016",0    
    PL_ENDIF
	PL_END

pl_v2
	PL_START
	PL_B	$CD00,$60	; skip protection test
	PL_W	$CD00-50,$6004	; skip disk hw access
	PL_PS	$752C,patch_dbf
	PL_IFC1X	0
	PL_NOP	$98DC,8
	PL_ENDIF
	PL_IFC1X	1
	PL_NOP	$DFCA,2
	PL_ENDIF
	; jump: 2nd button
	PL_IFC2
	PL_PS	$048f0,read_joy_directions_jump_button
	PL_PS	$0494c,read_joy_directions_jump_button
	PL_ELSE
	PL_PS	$048f0,read_joy_directions_jump_up
	PL_PS	$0494c,read_joy_directions_jump_up
	PL_ENDIF
    ; fire button
    PL_PS   $04a00,read_fire_button
    
    PL_IFC4
    PL_ELSE
    PL_DATA    $1150,80
    dc.b    "0001-0002-0003-0004-0005-0006-0007-0008-0009-0010-0011-0012-0013-0014-0015-0016",0    
    PL_ENDIF
	PL_END

pl_titus
	PL_START
	PL_B	$CE34,$60	; skip protection test
	PL_W	$CE02,$6004	; skip disk hw access
	PL_PS	$7628,patch_dbf

	PL_IFC1X	0
	PL_NOP	$9ABC,6
	PL_ENDIF
	PL_IFC1X	1
	PL_NOP	$E062,2
	PL_ENDIF
	PL_IFC2
	PL_PS	$04a34,read_joy_directions_jump_button
	PL_PS	$04a90,read_joy_directions_jump_button
	PL_ELSE
	PL_PS	$04a34,read_joy_directions_jump_up
	PL_PS	$04a90,read_joy_directions_jump_up
	PL_ENDIF

    PL_PS   $04b40,read_fire_button
    
    PL_IFC4
    PL_ELSE
    PL_DATA    $1154,80
    ; the 15th level was scrapped, 0015 is the code for the end sequence
    dc.b    "0001-0002-0003-0004-0005-0006-0007-0008-0009-0010-0011-0012-0013-0014-0000-0015",0    
    PL_ENDIF
	PL_END

emulate_dbf
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.w	#$FFFF,d0
	rts

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

	bsr	update_task_seglist

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

update_task_seglist
	movem.l	d0/a0/a6,-(a7)
	move.l	$4,A6
	sub.l	a1,a1
	jsr	(_LVOFindTask,a6)
	move.l	d0,a0
	move.l	pr_CLI(a0),d0
	asl.l	#2,d0
	move.l	d0,a0

	; store loaded segments in current task

	move.l	d7,cli_Module(a0)

	movem.l	(a7)+,d0/a0/a6
	rts

QUIT	pea	(TDREASON_OK).w
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
tag
		dc.l	WHDLTAG_CUSTOM3_GET
start_level
		dc.l	0
		dc.l	0
;--------------------------------
button_states
	dc.l	0
previous_button_states
	dc.l	0
ladder_position_address
	dc.l	0
;============================================================================

	END
