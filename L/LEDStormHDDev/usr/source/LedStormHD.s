;*---------------------------------------------------------------------------
;  :Program.	LedStormHD.asm
;  :Contents.	Slave for "LedStorm"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: LedStormHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;;CHIP_ONLY

	IFD BARFLY
	OUTPUT	"LedStorm.slave"
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

;============================================================================


	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $00000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;DOSASSIGN
;INITAGA
HDINIT
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 2000
;BOOTDOS
CACHE
CBDOSLOADSEG

; offset between my resourced version (using old decrypt) and actual offsets
DECRYPT_BASE = $1B710

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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
	dc.b	0

slv_name		dc.b	"L.E.D Storm"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
		dc.b	0
slv_copy	dc.b	"1988 Capcom/Software Creations",0
slv_info	dc.b	"adapted by Dr Zarkov & JOTD",10,10
		dc.b	"Thanks to CFou! for his generic CopyLock decoder",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
		dc.b    "BW;"
		dc.b    "C1:B:Infinite energy;"
		dc.b    "C5:B:No speed limiting;"
		dc.b	0
	even
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a0
	cmp.b	#3,(a0)
	bne.b	.noled

	add.l	d1,d1
	add.l	d1,d1
	move.l	d1,d7

	bsr	patch_main
.noled
	rts


;_Calculate_D5
;_WaitAfterFound

patch_main
	moveq	#0,d2
	bsr	get_section

	move.l	4(a1),d0
	cmp.l	#'Prot',d0
	bne.b	.no_prot

	; RN protected executable

	move.l	a1,a6
	; call CFou! "generic" code
	bsr	_RNDecryptionGeneric
.no_prot
	lea	pl_section0(pc),a0
	moveq	#0,d2
	bsr	get_section
	
	; this game uses only variables and jumps, it's very
	; difficult to patch something without overwriting a relocation
	; so we have to save them beforehand... tedious.
	
	lea	($1F4D2-DECRYPT_BASE,a1),a3
	lea	vbl_counter_address(pc),a2
	move.l	a3,(a2)
	
	lea	($1BBAA-DECRYPT_BASE,a1),a3
	lea	pre_game_loop_address(pc),a2
	move.l	(2,a3),(a2)
	lea	($20434-DECRYPT_BASE,a1),a3
	
	lea	pre_mission_loop_address(pc),a2
	move.l	($6002,a3),(a2)
	
	lea	($21868-DECRYPT_BASE,a1),a3
	lea	highscore_table_address(pc),a2
	move.l	a3,(a2)
	
	lea	($212F8-DECRYPT_BASE,a1),a3
	lea	after_highscore_input_address(pc),a2
	move.l	(2,a3),(a2)
	
	move.l	_resload(pc),a2
	lea	highscore_name(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.noscores
	
	move.l	highscore_table_address(pc),a1
	lea	highscore_name(pc),a0
	jsr	resload_LoadFile(a2)
.noscores
	lea	pl_section0(pc),a0
	moveq	#0,d2
	bsr	get_section
	jsr	resload_Patch(a2)
	rts
	
	; same patches for cracked & crypted version
pl_section0
	PL_START
;;	PL_L	$32,$4E714E71	; remove infinite loop on CloseWorkbench
	PL_PS	$AF92,dbf_d3_96
	PL_W	$3A76,$4200	; snoop
	PL_PS	$6F46,wait_blit_clr_bltamod	; blitwait
	
	PL_IFBW
	PL_PS	$1B994-DECRYPT_BASE,title_wait
	PL_ENDIF
	
	PL_IFC1
	PL_NOP	$1E2B0-DECRYPT_BASE,8
	PL_NOP	$1E2C2-DECRYPT_BASE,8
	PL_ELSE
	PL_P	$212F8-DECRYPT_BASE,save_highscores
	PL_ENDIF
	
	PL_IFC5
	PL_ELSE
	PL_PS	$26434-DECRYPT_BASE,reset_mission_loop_counter
	PL_PS	$1BBAA-DECRYPT_BASE,reset_game_loop_counter
	PL_PS	$2643A-DECRYPT_BASE,force_vbl_wait_mission		; mission display
	PL_PS	$1BBB6-DECRYPT_BASE,force_vbl_wait_game		; game loop
	
	PL_ENDIF
	PL_END

	
save_highscores:
	; save highs
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	highscore_table_address(pc),a1
	lea	highscore_name(pc),a0
	move.l	_resload(pc),a2
	move.l	#$46,d0
	jsr	(resload_SaveFile,a2)
	
	move.l	after_highscore_input_address(pc),a0
	clr.b	(a0)	; doing what game does
	
	movem.l	(a7)+,d0-d1/a0-a2
	

	rts
	
reset_mission_loop_counter
	bsr	reset_last_counter
	movem.l	a0,-(a7)
	move.l	pre_mission_loop_address(pc),a0
	clr.b	(a0)
	movem.l	(a7)+,a0
	rts
reset_game_loop_counter:
	bsr	reset_last_counter
	move.l	pre_game_loop_address(pc),-(a7)
	rts
	
force_vbl_wait_mission
	bsr	wait_till_next_vbl
.w:
	CMPI.B	#$C8,$DFF006
	BNE.B	.w		;28FD8: 6600FFF6
	rts
	
WAIT_EVERY_NTH_TIME = 1
	
force_vbl_wait_game
	lea	.nb(pc),a0
	add.w	#1,(a0)
	cmp.w	#WAIT_EVERY_NTH_TIME,(a0)
	bne.b	.w
	clr.w	(a0)
	bsr	wait_till_next_vbl
.w:
	CMPI.B	#$C8,$DFF006
	BNE.B	.w		;28FD8: 6600FFF6
	rts
.nb
	dc.w	0
	
; why is the game/menu display so fast when the CMPI.B	#$C8,$DFF006
; code is called?
; my theory is that game expects that a VBL happens while CPU is doing stuff,
; then syncs on the next VBL (25 fps)
; BUT if the CPU is fast enough, the sync happens on the first VBL, doubling the speed
; and making text unreadable/game unplayable
; adding another sync would probably do the trick, but would make game slower on slow machines
; we need to wait more, but only if the VBL hasn't changed enough

; call this before menu & game loops
; or next time the current VBL will be completely
; unrelated to previous "last_counter" value
; writing 0 to "last_counter" makes wait inactive the first time
; but it doesn't matter much as long as it's regulated most of the time

reset_last_counter:
	movem.l	a0,-(a7)
	lea	last_counter(pc),a0
	clr.w	(a0)
	movem.l	(a7)+,a0
	rts

wait_till_next_vbl:
	movem.l	d0/a0/a1,-(a7)
	lea	last_counter(pc),a0
	move.l	vbl_counter_address(pc),a1
	
	move.w	(a0),d0
	beq.b	.first
	
	lea	last_counter(pc),a0
	tst.l	d0
	beq.b	.first
	bmi.b	.first	; reset before it wraps
	add.l	#1,d0
	; wait 1 VBL
.wait
;	move.w	#$0F0,$DFF180
	cmp.w	(a1),d0
	bcc.b	.wait
;	move.w	#$0,$DFF180
.first
	; store current counter
	move.w	(A1),(a0)
.avoid
	movem.l	(a7)+,d0/a0/a1
	rts
	
last_counter
	dc.w	0
	
title_wait:
.loop
	btst	#6,$bfe001
	beq.b	.out
	btst	#7,$bfe001
	beq.b	.out
	bra.b	.loop
.out
	MOVE.L	#$000000EF,D1		;1B994: 223C000000EF
	rts
	
wait_blit_clr_bltamod
	bsr	wait_blit
	move.w	#0,$dff064
	rts

wait_blit
	TST.B	dmaconr+$DFF000
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts

dbf_d3_96
	move.l	d0,-(a7)
	moveq.l	#4,d0
	bsr	beamdelay
	move.l	(a7)+,d0
	move.w	#$FFFF,d3
	add.l	#4,(a7)
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

vbl_counter_address
	dc.l	0
pre_game_loop_address
	dc.l	0
pre_mission_loop_address
	dc.l	0
after_highscore_input_address	
	dc.l	0
highscore_table_address	
	dc.l	0

_led = 1	; enable Led Storm mode

	include	RNDecryptionGeneric.s

highscore_name:
	dc.b	"highs",0
	
;============================================================================
