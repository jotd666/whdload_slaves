;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"StarRay.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $10000	; 0 -> crash because bootblock read trashes SSP !!
NUMDRIVES	= 1
WPDRIVES	= %1111

DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
BOOTBLOCK

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick13.s

;============================================================================

DECL_VERSION:MACRO
	dc.b	"3.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name		dc.b	"StarRay",0
slv_copy		dc.b	"1988 Logotron",0
slv_info		dc.b	"adapted by JOTD",10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	0
slv_config:
        dc.b    "C1:X:Infinite energy & smart bombs:0;"
		dc.b	0
	EVEN


;============================================================================
; bootblock from "Disk.1" has been loaded, no dos.library available

; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock:
	movem.l	d0-d1/a0-a2,-(a7)
	
	bsr	_detect_controller_types
	
	move.l	a4,a1
	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	($c,a4)

pl_boot
	PL_START
	PL_P	$2E,jumper
	PL_END

jumper
	move.w	$7F0E4,d0
	cmp.w	#$4EF9,d0
	beq.b	.v1

	move.w	$7F3CE,d0
	cmp.w	#$4EF9,d0
	beq.b	.v2

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.v1
	patch	$7F0E4,patch_loader_v1
	bra.b	.go
.v2
	patch	$7F3CE,patch_loader_v2
.go
	bsr	_flushcache
	jmp	$7F000

patch_loader_v1
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_loader_v1(pc),a0
	lea	$38000,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$38000

patch_loader_v2
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_loader_v2(pc),a0
	lea	$38000,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	lea	_trd_disk(pc),a0
	move.b	#2,(a0)			; switch to game disk

	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$38000

pl_loader_v1
	PL_START
	PL_PS	$42C,check_for_keyboard
;;	PL_PS	$426,kb_interrupt
;;	PL_W	$42C,$6004

	PL_PS	$2476,joy_button_2

	PL_IFC1
	; infinite smart bombs
	PL_NOP	$3C5F4-$38000,6
	; infinite energy
	PL_NOP	$3BD60-$38000,6	; collision
	PL_NOP	$3BDE0-$38000,8 ; shots
	PL_ENDIF
	PL_END

pl_loader_v2
	PL_START
	PL_S	$B6,$10		; skip "insert disk" request
	PL_NEXT	pl_loader_v1	; same code

check_for_keyboard:
	CMP.B $0003a48a,D0
	bne.b	.keypress
	; no key press: check if joypad pressed
	movem.l	D0,-(a7)
	move.l	joy1(pc),d0
	btst	#JPB_BTN_PLAY,d0
	movem.l	(a7)+,d0
.keypress
	rts

joy_button_2
	; emulate POTGO with joypad read routine
	movem.l	d0,-(a7)
	move.w	#-1,d2
	bsr	_joystick
	move.l	joy0(pc),d0
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_b2_0
	bclr	#10,d2		; right mouse button
.no_b2_0:
	move.l	joy1(pc),d0
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_b2_1
	bclr	#14,d2		; second button
.no_b2_1:
	; quit to wb with fwd+rev+play
	btst		#JPB_BTN_REVERSE,d0
	beq		.exit
	btst		#JPB_BTN_FORWARD,d0
	beq		.exit
	btst		#JPB_BTN_PLAY,d0
	beq		.exit
	pea     TDREASON_OK
    move.l  (_resload,pc),-(a7)
    add.l   #resload_Abort,(a7)
    rts	
.exit
	movem.l	(a7)+,d0
	rts
	

		
	; old code, only button 2 was supported
	;move.w	$dff016,d2	; orig	
	;move.w	#$CC01,$dff034	; ack, fixes 2nd button press on joystick
	;rts

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

quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

	IFEQ	1
kb_interrupt:
	move.b	$BFEC01,D0

	movem.l	D0/D1,-(sp)
	moveq.l	#0,D1

	move.b	$BFEC01,D0
	not.b	D0
	ror.b	#1,D0


	cmp.b	#$40,D0
	bne	.nospace
	moveq	#1,D1
.nospace
	cmp.b	#$45,D0
	bne	.noesc
	moveq	#1,D1
.noesc
	btst	#3,$BFED01
	beq.b	.exit

	move.b	#$0,$BFED01

	bset	#$06,$BFEE01
	moveq.l	#3,D0
	bsr	beamdelay
	bclr	#$06,$BFEE01		; acknowledge keyboard
	move.w	#$8,$DFF000+intreq
.exit
	tst.l	D1
	movem.l	(sp)+,D0/D1
	rts
	ENDC

	include	"ReadJoyPad.s"
	
;============================================================================

	END

