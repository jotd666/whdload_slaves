;*---------------------------------------------------------------------------
;  :Program.	WatchTowerHD.asm
;  :Contents.	Slave for "WatchTower"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: WatchTowerHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"WatchTower.slave"
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

	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $1FF000
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

	include	whdload/kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.2"
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
assign1
	dc.b	"WT1",0
assign2
	dc.b	"WT2",0
assign3
	dc.b	"WT3",0

slv_name		dc.b	"WatchTower"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1996 OTM/Cyberarts",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C2:X:Trainer Infinite Grenades:0;"
        dc.b    "C3:X:Trainer Infinite Time:0;"
		dc.b    "C4:L:Start level:1,2,3,4,5,6;"		
		dc.b    "C5:X:keep original slow fade in & out:0;"		
		dc.b	0

_program:
	dc.b	"WatchTower",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
	bsr	_detect_controller_types

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_main
	move.l	d7,a1
	addq.l	#4,a1
	move.l	_start_level(pc),d0
	move.b	d0,$640E(a1)
	
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)
	rts

fix_protection
	move.l	(0,a0,d1.l),d0	; not really necessary...
	rts


; original $1FF00: slow as hell
FADE_SPEED = $3F00

pl_main
	PL_START

	PL_IFC5
	PL_ELSE
	; fast fade-in/fade-out
	PL_L	$8D0,FADE_SPEED
	PL_L	$8BC,FADE_SPEED
	PL_L	$F2C,FADE_SPEED
	PL_ENDIF
	; VBR access
	PL_L	$1BC92,$70004E73

	; joypad hooks
	PL_PSS	$12396,player_1_grenade,2
	PL_PSS	$1261a,player_2_grenade,2
	PL_PSS	$0d3de,pause_test,2
	PL_PSS	$0d410,quit_test,2
	
	; protection

	PL_B	$9BC,$60	; don't wait for the code
	PL_PSS	$A86,fix_protection,2
	
	PL_IFC1
	PL_B	$641E,1	; infinite lives
	PL_ENDIF
	PL_IFC2
	PL_B	$641F,1	; infinite grenades
	PL_ENDIF
	PL_IFC3
	PL_B	$6420,1	; infinite time
	PL_ENDIF
	PL_END
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

IGNORE_JOY_DIRECTIONS
	include	ReadJoyPad.s

BUTTON_KEY_TEST:MACRO
	CMPI.B	#\1,$bfec01  ; CIAA_SDR
	beq	.by_keyboard
	movem.l	d0,-(a7)
	move.l	joy\3_buttons(pc),d0
	not.l	d0	; negative logic to match condition codes expected on return
	btst	#\2,d0
	movem.l	(a7)+,d0
.by_keyboard:
	rts
	ENDM

quit_test
	; read both joypads
	bsr	_read_joysticks_buttons

	CMPI.B	#$75,$bfec01  ; CIAA_SDR
	beq	.by_keyboard
	movem.l	d0,-(a7)
	move.l	joy1_buttons(pc),d0
	not.l	d0	; negative logic to match condition codes expected on return
	btst	#JPB_BTN_PLAY,d0
	bne.b	.nope
	btst	#JPB_BTN_FORWARD,d0
	bne.b	.nope
	btst	#JPB_BTN_REVERSE,d0
	bne.b	.nope
	btst	#JPB_BTN_RED,d0
	bne.b	.noexitwb
	
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noexitwb
	; test again to reset flag
	btst	#JPB_BTN_REVERSE,d0
.nope
	movem.l	(a7)+,d0
.by_keyboard:
	rts


pause_test:
	BUTTON_KEY_TEST	$7F,JPB_BTN_PLAY,1


player_2_grenade:
	BUTTON_KEY_TEST	$35,JPB_BTN_BLU,0

player_1_grenade:
	BUTTON_KEY_TEST	$37,JPB_BTN_BLU,1
	
	
_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

_tag		dc.l	WHDLTAG_CUSTOM4_GET
_start_level	dc.l	0
		dc.l	0

;============================================================================

	END
