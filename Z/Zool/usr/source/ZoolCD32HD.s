;*---------------------------------------------------------------------------
;  :Program.	
;  :Contents.	Slave for
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id:  1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"ZoolCD32.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $00000
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;DOSASSIGN
BOOTDOS
;DEBUG
INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
CACHE
CBKEYBOARD
FORCEPAL

; uses the next kick31cd32.s & cddevice.s
; (upgrade from whdload package)

DUMMY_CD_DEVICE = 1
; when not set, uses the replacement lowlevel emulation by JOTD/Psygore
;USE_DISK_LOWLEVEL_LIB
; when not set, uses the new nonvolatile emulation by Wepl
;USE_DISK_NONVOLATILE_LIB

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick31cd32.s
	
;============================================================================

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

;_assign1
;	dc.b	"CD0",0

slv_name		dc.b	"Zool (CD³²)",0
slv_copy		dc.b	"1992 Gremlin",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"FWD+BWD quits the current game",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"zool",0
_args		dc.b	10
_args_end
	dc.b	0
slv_config:
		dc.b    "C1:L:controls:CD32 original,red fires blue/green jumps,1-button joystick;"			
		dc.b    "C2:B:99% sweets;"
		dc.b	"C3:B:infinite lives;"
		dc.b	"C4:B:infinite energy and time;"
		dc.b	0
	EVEN


;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W
	lea	OSM_JOYPAD1KEYS+3(pc),a0
	; P for pause, fwd+bwd mapped to ESC
	move.b	#$19,(A0)+
	move.b	#$45,(A0)+
	move.b	#$45,(A0)+

	bsr	_nonvolatile_init
	
	move.l	(_resload,pc),a2		;A2 = resload
	lea	_wtags(pc),a0
	jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		; enable lowlevel/nonvolatile emulation
		bsr	_patch_cd32_libs

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

patch_exe:
	move.l	_resload(pc),a2
	move.l	d7,a1
	move.l	_controls(pc),d0
	cmp.b	#1,d0
	beq.b	.inverted		; "classic" fire on red, jump on blue+green
	cmp.b	#2,d0
	beq.b	.standard		; "classic" fire on red, jump on up
; default: do nothing
.just_add_blue
	lea	pl_original_controls(pc),a0
	bra.b	.patch
.inverted
	lea	pl_inverted_controls(pc),a0
	bra.b	.patch
.standard
	lea	pl_standard_controls(pc),a0	
.patch
	jsr	(resload_PatchSeg,a2)
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1
	;;move.l	a1,$0.W
	
	lea	time_address(pc),a0
	lea	($4e2,a1),a2
	move.l	a2,(a0)
	lea	lives_address(pc),a0
	move.l	a1,a2
	add.l	#$023560,a2
	move.l	a2,(a0)
	lea	raw_key_code_address(pc),a0
	lea	($003f1e,a1),a2
	move.l	a2,(a0)

	
	pea		fix_smc_jsr(pc)
	move.l	(a7)+,$BC.W	; trap #15 emulates JSR with SMC
	pea		fix_smc_2(pc)
	move.l	(a7)+,$B8.W	; trap #14
	rts
OFFSET_FIRE = $AC4E
OFFSET_JUMP = $00ac5e+2

_cb_keyboard
	movem.l	a0,-(a7)
	move.l	raw_key_code_address(pc),a0
	move.b	d2,(a0)
	movem.l	(a7)+,a0
	RTS
	
	
pl_original_controls
	PL_START
	; allow blue button to fire too so game can be played
	; with a 2-button joystick
	PL_L	OFFSET_FIRE,JPF_BUTTON_GREEN|JPF_BUTTON_BLUE
	PL_NEXT	pl_main
	
pl_inverted_controls
	PL_START
	; allow blue button to jump too so game can be played
	; with a 2-button joystick
	PL_L	OFFSET_JUMP,JPF_BUTTON_GREEN|JPF_BUTTON_BLUE
	PL_L	OFFSET_FIRE,JPF_BUTTON_RED
	PL_NEXT	pl_main
pl_standard_controls
	PL_START
	; 1-button joystick
	PL_L	OFFSET_FIRE,JPF_BUTTON_RED
	PL_L	OFFSET_JUMP,JPF_JOY_UP
	PL_NEXT	pl_main
pl_main
	PL_START
	; soundtracker dbf delay 
	PL_PSS	$2f5e,emulate_soundtracker_dbf,2
	PL_PSS	$2F72,emulate_soundtracker_dbf,2
	; self-modifying code
	PL_W	$abd4,$4E4F
	PL_PS	$b98c,fix_smc_1
	PL_W	$1b308,$4E4E
	
	PL_PS	$00ac70,check_left_and_fwd_bwd
	; fix access fault ???
	PL_L	$005f44,$DFF1FC
	; skip country check
	PL_B	$0086b4,$60
	PL_IFC2
	PL_NOP	$12fefa,4		; no highscore saving if you cheat
	PL_NOP	$01d6aa,4		; 99% sweets
	PL_ENDIF
	PL_IFC3
	PL_NOP	$12fefa,4		; no highscore saving if you cheat
	PL_W	$00cf70,$4ABC	; SUB => TST: infinite lives
	PL_ENDIF
	PL_IFC4
	PL_NOP	$12fefa,4		; no highscore saving if you cheat
	PL_NOP	$01ac4a,6		; infinite energy
	PL_NOP	$006220,6		; infinite time
	PL_ENDIF
	; enable original cheat/level skip
	PL_B	$a328,$FF
	PL_NOP	$CF94,6

	;PL_L	$00f37a+2,2		; level number - 1 (doesn't seem to work)
	;PL_L	$00f38a+2,3		; level section - 1

	PL_END

fix_smc_1:
	MOVEA	#$0020,A2		;: original
	MOVEQ	#0,D3			;00b990: 7600
	bra	_flushcache
	; from trap
fix_smc_2:
	MOVE.W	(A6),D1		; original
	bsr	_flushcache
	RTE
	
check_left_and_fwd_bwd:
	BTST	#JPB_BUTTON_FORWARD,D1		;00ac88: 028100080000
	beq.b	.nofwd
	BTST	#JPB_BUTTON_REVERSE,D1		;00ac88: 028100080000
	beq.b	.nofwd
	; simulate ESC
	movem.l	a0,-(a7)
	
	; set time to zero
	move.l	time_address(pc),a0
	clr.l	(a0)
	move.l	lives_address(pc),a0
	clr.l	(a0)
	movem.l	(a7)+,a0
.nofwd
	; original
	ANDI.L	#JPF_BUTTON_PLAY,D1
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

; < D0: value of D0 in line
; .x: DBF D0,x
emulate_soundtracker_dbf
	move.l	#7,D0
	bsr	beamdelay
	move.w	#$FFFF,d0
	rts	


fix_smc_jsr:
	; tricky: first, recover from the RTE

	movem.l	A0/A1,-(A7)
	move.l	10(A7),A0	; return PC
	lea	.return_address(pc),a1
	move.l	a0,(a1)		; save return address for later on
	lea	.jsr_address(pc),a1
	move.l	(a0),(a1)	; save jsr address for later on
	lea	.recov(pc),a1
	move.l	a1,10(a7)	; change return PC
	movem.l	(A7)+,A0/A1
	rte
.recov
	; now we're in user mode: first push return address
	
	move.l	.return_address(pc),-(a7)
	addq.l	#4,(a7)		; skip JSR operand
	
	; then push JSR operand
	move.l	.jsr_address(pc),-(a7)

	; go
	rts
	
.return_address
	dc.l	0
.jsr_address
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
	jsr	(a5)
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
time_address
	dc.l	0
lives_address
	dc.l	0
raw_key_code_address
	dc.l	0
	
_wtags		
		dc.l	WHDLTAG_CUSTOM1_GET
_controls		dc.l	0
	dc.l	0
;============================================================================

	END
