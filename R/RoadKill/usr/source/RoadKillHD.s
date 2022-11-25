;*---------------------------------------------------------------------------
;  :Program.	RoadKillHD.asm
;  :Contents.	Slave for "RoadKill"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: RoadKillHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"RoadKill.slave"
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
HRTMON
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $100000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_Req68020|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'

	include	whdload/kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.2"
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

_assign1
	dc.b	"RoadKill1",0
_assign2
	dc.b	"RoadKill2",0
_assign3
	dc.b	"RoadKill3",0

slv_name		dc.b	"RoadKill AGA/CD��"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1993 Vision",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
	dc.b	"C1:X:invincibility:0;"
	dc.b	"C1:X:infinite missiles:1;"
	dc.b	"C1:X:infinite super-missiles:2;"
	dc.b	"C1:X:infinite retries:3;"
    dc.b    "C5:X:defaults to no previews:0;"
    dc.b    "C5:X:defaults to manual gears:1;"



		dc.b	0

_introanim
	dc.b	"RoadKillIntro.anim7",0
_program:
	dc.b	"RoadKill.exe",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

IGNORE_JOY_DIRECTIONS

	include	ReadJoyPad.s
	
_bootdos
	; saves registers (needed for BCPL stuff, global vector, ...)
		bsr	_detect_controller_types
		
		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tags,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		bsr	get_version
	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)



GETFILESIZE:MACRO
	movem.l	d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	lea	\1(pc),a0
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,d1/a0-a2
	ENDM

get_version
	GETFILESIZE	_program
	cmp.l	#423504,d0
	beq.b	.floppy
	cmp.l	#712988,d0
	beq.b	.cd32
	bra	wrong_version
.floppy
	lea	patch_floppy(pc),a5
	rts
.cd32
	lea	patch_cd32(pc),a5
	rts

wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


; < d7: seglist (APTR)

patch_cd32
	
	addq.l	#4,d7
	move.l	d7,a1
	IFD	CHIP_ONLY
	move.l	a1,$100.W
	ENDC
	
	; save score buffer address for later

	lea	save_address(pc),A0
	move.l	a1,(a0)
	add.l	#$797A,(a0)

	bsr	load_score

	; intercept the "save game" routine: a point of the
	; game (after a gameover) where hiscore can be saved

	move.l	_trainer(pc),d0
	bne.b	.trainer
	
	move.l	d7,a1
	add.l	#$A380,a1
	lea	save_game_jsr(pc),A0
	move.l	(A1),(A0)
	pea	save_hiscore(pc)
	move.l	(A7)+,(A1)
.trainer
	move.l	d7,a1

	; default: skip animation

	lea	pl_main_cd32_noanim(pc),a0

	GETFILESIZE	_introanim
	tst.l	d0
	beq.b	.sk
	; if anim file is there, don't skip the animation

	lea	pl_main_cd32(pc),a0
.sk
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	rts

; < d7: seglist (APTR)

patch_floppy
	addq.l	#4,d7
	move.l	d7,a1
	IFD	CHIP_ONLY
	move.l	a1,$100.W
	ENDC
	
	; save score buffer address for later

	lea	save_address(pc),A0
	move.l	a1,(a0)
	add.l	#$739A,(a0)

	bsr	load_score

	; intercept the "save game" routine: a point of the
	; game (after a gameover) where hiscore can be saved
	move.l	_trainer(pc),d0
	bne.b	.trainer

	move.l	d7,a1
	add.l	#$98C8,a1
	lea	save_game_jsr(pc),A0
	move.l	(A1),(A0)
	pea	save_hiscore(pc)
	move.l	(A7)+,(A1)
.trainer
	
	move.l	d7,a1
	lea	pl_main_floppy(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	rts

load_score:
	GETFILESIZE	savename
	tst.l	d0
	beq.b	.skip

	; load the hiscore file in the original buffer if it exists

	move.l	save_address(pc),a1
	lea	savename(pc),a0
	move.l	_resload(pc),A2
	jsr	resload_LoadFile(a2)
.skip
	rts

pl_main_cd32_noanim
	PL_START
	PL_AL	$7D7C,$7FEC-$7D80	; skip intro anim sequence
	PL_NEXT	pl_main_cd32
	
pl_main_cd32
	PL_START
	
	PL_B	$94D6,$60	; no switch joystick/cd32
;;	PL_CW	$7D40		; default: joystick
	PL_IFC1X	0
	PL_NOP	$12492,6
	PL_NOP	$12628,6
	PL_NOP	$1275C,10
	PL_NOP	$12CE2,10
	PL_NOP	$159D2,6
	PL_NOP	$16368,10
	PL_ENDIF
	PL_IFC1X	1
	; no missile decrease
	PL_NOP	$15DC0,6
	; 4 missiles to start
	PL_W	$BF1A,4
	PL_ENDIF
	PL_IFC1X	2
	; super missiles cheat
	PL_NOP	$15CFE,6
	PL_W	$BF22,4
	PL_ENDIF
	PL_IFC1X	3
	; infinite retries
	PL_NOP	$d51a,6
	PL_ENDIF
	PL_IFC5X	0
	PL_W	$7D06,1		; no previews
	PL_ENDIF
	PL_IFC5X	1
	PL_W	$7D38,1		; manual gears
	PL_ENDIF

	PL_PS	$1518,read_joypad
	PL_S	$1518+6,$001560-$1518-6
	;;PL_PS	$1A2C6,vbl_hook
	PL_END

pl_main_floppy
	PL_START

	PL_B	$8AC8,$60	; no switch joystick/cd32
	PL_W	$0076F6,1
	
	PL_IFC1X	0
	PL_NOP	$0113A2,6
	PL_NOP	$011538,6
	PL_NOP	$01166C,10
	PL_NOP	$011BF2,10
	PL_NOP	$0148E2,6
	PL_NOP	$015278,10
	PL_ENDIF
	PL_IFC1X	1
	; no missile decrease
	PL_NOP	$014CD0,6
	; 4 missiles to start
	PL_W	$00B41E,4
	PL_ENDIF
	PL_IFC1X	2
	; super missiles cheat
	PL_NOP	$14C0E,6
	PL_W	$00B426,4
	PL_ENDIF
	PL_IFC1X	3
	; infinite retries
	PL_NOP	$C8CA,6
	PL_ENDIF
	PL_IFC5X	0
	PL_W	$0076AC,1		; no previews
	PL_ENDIF
	PL_IFC5X	1
	PL_W	$0076DE,1		; manual gears
	PL_ENDIF
	
	
	PL_PS	$1548,read_joypad
	PL_S	$1548+6,$001590-$1548-6
	;;PL_PS	$191D6,vbl_hook
	PL_END

	
read_joypad
	movem.l	D1,-(a7)
	moveq.l	#1,d0
	bsr	_read_joystick

	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noquit
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
	btst	#JPB_BTN_PLAY,d0
	beq.b	.noquit	
	pea	TDREASON_OK
	move.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)	
.noquit
	; blue acts same as green
	btst	#JPB_BTN_BLU,d0
	beq.b	.noblue
	bset	#JPB_BTN_GRN,d0
.noblue
	move.b	$BFEC01,d1
	ror.b	#1,d1
	not.b	d1
	cmp.b	#$4C,d1
	bne.b	.noup
	bset	#JPB_BTN_FORWARD,d0
.noup
	cmp.b	#$4D,d1
	bne.b	.nodown
	bset	#JPB_BTN_REVERSE,d0
.nodown
	cmp.b	#$40,d1
	bne.b	.nospace
	bset	#JPB_BTN_GRN,d0
.nospace
	cmp.b	#$19,d1
	bne.b	.nopause
	bset	#JPB_BTN_PLAY,d0
.nopause
	movem.l	(a7)+,d1
	rts

	
; we can trash d0 and a0 is loaded with HARDBASE (probably useless
; as the routine is just counting 1/50s ticks
;vbl_hook
;	bsr	actual_read_joypad
;	lea	button_state(pc),a0
;	move.l	d0,(a0)
;	lea	$dff000,a0	; orig
;	rts


button_state
	dc.l	0

save_hiscore:
	movem.l	D0-D1/A0-A2,-(A7)
	move.l	save_address(pc),A1
	move.l	#80,D0
	lea	savename(pc),A0
	move.l	_resload(pc),A2
	jsr	resload_SaveFile(a2)

	movem.l	(A7)+,D0-D1/A0-A2
	move.l	save_game_jsr(pc),-(A7)	; jump to original routine
	rts

;---------------

save_game_jsr:
	dc.l	0
save_address:
	dc.l	0	
savename:
	dc.b	"Highs",0
	even


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
control_block
		dc.w	100
_tags		dc.l	WHDLTAG_CUSTOM1_GET
_trainer		dc.l	0
		dc.l	0
_saveregs
		ds.l	16,0
_stacksize
		dc.l	0


;============================================================================

	END
