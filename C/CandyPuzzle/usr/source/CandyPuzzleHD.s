;*---------------------------------------------------------------------------
;  :Program.	CandyPuzzleHD.asm
;  :Contents.	Slave for "CandyPuzzle"
;  :Author.	JOTD, from Wepl sources
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9, Vasm
;  :To Do.
;---------------------------------------------------------------------------*

; a possible bug in the game prevents from using fast memory
; if fastmem is set, pressing fire presses fire for all players

CHIP_ONLY

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"CandyPuzzle.slave"

	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

    IFD CHIP_ONLY
CHIPMEMSIZE	= $1EF000
FASTMEMSIZE	= $00000    
    ELSE
CHIPMEMSIZE	= $1EF000
FASTMEMSIZE	= $80000
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
HDINIT
;DEBUG
INITAGA
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
BOOTDOS
;SETPATCH
;;FORCEPAL
USE_DISK_LOWLEVEL_LIB       ; lowlevel is not used
;USE_DISK_NONVOLATILE_LIB       ; nonvolatile is used for highscore?

CACHE
SEGTRACKER
DUMMY_CD_DEVICE     ; game accesses cd device
IGNORE_JOY_DIRECTIONS
;;USE_VBL_HOOK

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_ReqAGA|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCDIR	Sources:whdload
	INCLUDE	kick31cd32.s
    include readjoypad.s
    
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.0"
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
	dc.b	"bobble",0
_env_assign
	dc.b	"ENV",0

slv_name		dc.b	"Candy Puzzle CD³²"
    IFD CHIP_ONLY
    ;;dc.b    " (DEBUG/CHIP ONLY)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1995 C.D. Express",0
slv_info		dc.b	"adapted by JOTD",10,10
        dc.b    "Press SPACE/forward to add credits",10,10
			dc.b	"Version "
			DECL_VERSION
            dc.b    0
slv_config
	dc.b    "C1:X:99 credits:0;"
    dc.b	0
    
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_envpath:
	dc.b	"ram:",0

_bobble:
    dc.b    "bobble",0
_program:
	dc.b	"bobble/setup",0
_program2:
	dc.b	"bobble/digi1.exe",0

    
_args		dc.b	"J CANDY.CFG",10
_args_end
	dc.b	0
	EVEN

;============================================================================


	;initialize kickstart and environment
_bootdos
	clr.l	$0.W
    bsr _detect_controller_types
    
    IFD USE_VBL_HOOK
    ; install joypad read in vblank
    lea old_vbl(pc),a0
    move.l  $6C,(a0)
    pea vbl_hook(pc)
    move.l  (a7)+,$6C
    ENDC
    
	move.l	(_resload,pc),a2		;A2 = resload


	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_env_assign(pc),a0
		lea	_envpath(pc),a1
		bsr	_dos_assign

		lea	_assign1(pc),a0
		lea _bobble(pc),a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found

	;patch here
		bsr	_patchexe

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;do NOT remove exe
;		move.l	d7,d1
;		jsr	(_LVOUnLoadSeg,a6)

	;load exe
		lea	_program2(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found

	;patch here
		bsr	_patchdigi
	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6
 
        rts

_end
	jsr	(_LVOIoErr,a6)
	move.l	a1,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_patchexe:
    move.l  _resload(pc),a2
	lea	_pl_bobble(pc),a0
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)

	; just patch for nonvolatile & lowlevel libs

    bsr _patch_cd32_libs

	rts
_patchdigi:
    move.l  _resload(pc),a2
	lea	_pl_digi(pc),a0
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)

	rts

    IFD USE_VBL_HOOK
vbl_hook
    btst    #5,_custom+intreqr+1
    beq.b   .novbl
    bsr _read_joysticks_buttons
.novbl
    move.l  old_vbl(pc),-(a7)
    rts
    ENDC

set_credits:
    move.w  #99,d0
    rts
    

    
read_joy_buttons
    and.w   #$FFFF,d0
    beq.b   .nospace
    move.b  $BFEC01,d1
    not.b   d1
    ror.b   #1,d1
    cmp.b   #$40,d1
    bne.b   .nospace
    moveq.l #0,d0
    bset    #JPB_BTN_FORWARD,d0
    bra.b   .end
.nospace

    IFD USE_VBL_HOOK
    lea joy0_buttons(pc),a0 ; a0 is trashed
    lsl.w   #2,d0
    move.l  (a0,d0.w),d0
    ELSE
    bsr _read_joystick
    ENDC
    
.end
    ; shift by 17 bits to match game routine
    swap    d0
    lsr.l   #1,d0
    rts
    
write_d2_to_d1:
    ; I don't know what it does, but it's certainly not necessary
    cmp.l   #$80000B,d1
    bne.b   .ok
    rts 
.ok
	MOVEA.L	D1,A0			;186a0: 2041
	CMPI.W	#$0002,D0		;186a2: 0c400002
	BHI.W	LAB_053B		;186a6: 6200000e
	BEQ.W	LAB_053A		;186aa: 67000006
	MOVE.B	D2,(A0)			;186ae: 1082
	RTS				;186b0: 4e75
LAB_053A:
	MOVE.W	D2,(A0)			;186b2: 3082
	RTS				;186b4: 4e75
LAB_053B:
	CMPI.W	#$0007,D0		;186b6: 0c400007
	BEQ.W	LAB_053C		;186ba: 67000006
	MOVE.L	D2,(A0)			;186be: 2082
	RTS				;186c0: 4e75
LAB_053C:
	MOVEA.L	D2,A1			;186c2: 2242
	MOVE.L	-(A2),D0		;186c4: 2022
	BEQ.W	LAB_053E		;186c6: 6700000a
LAB_053D:
	MOVE.B	(A1)+,(A0)+		;186ca: 10d9
	SUBQ.L	#1,D0			;186cc: 5380
	BNE.W	LAB_053D		;186ce: 6600fffa
LAB_053E:
	CLR.B	(A0)			;186d2: 4210
	RTS				;186d4: 4e75

read_d0_from_d1    
    cmp.l   #$800003,d1
    bne.b   .ok
    moveq.l #0,d0
    rts 
.ok
	MOVEA.L	D1,A0			;1865c: 2041
	CMPI.W	#$0002,D0		;1865e: 0c400002
	BHI.W	LAB_0534		;18662: 6200000e
	BEQ.W	LAB_0533		;18666: 67000006
	MOVE.B	(A0),D0			;1866a: 1010
	RTS				;1866c: 4e75
LAB_0533:
	MOVE.W	(A0),D0			;1866e: 3010
	RTS				;18670: 4e75
LAB_0534:
	CMPI.W	#$0007,D0		;18672: 0c400007
	BEQ.W	LAB_0535		;18676: 67000006
	MOVE.L	(A0),D0			;1867a: 2010
	RTS				;1867c: 4e75
LAB_0535:
	MOVEA.L	D1,A0			;1867e: 2041
	MOVEQ	#-1,D0			;18680: 70ff
LAB_0536:
	ADDQ.L	#1,D0			;18682: 5280
	MOVE.B	(A0)+,(A3)+		;18684: 16d8
	BNE.W	LAB_0536		;18686: 6600fffa
	SUBQ.W	#1,A3			;1868a: 534b
	RTS				;1868c: 4e75
    
_pl_bobble:
	PL_START
    ; remove hardware check
    ; it's really dirty
	PL_L    $2176+2,$BFE001
    PL_L    $00ce+2,$bfe001
	PL_END


_pl_digi:
	PL_START
    ; remove hardware check???
    ; strange as the "patched" version runs on CD32 without those
    ; patches. I had to add them to avoid access fault on invalid address
    ; actually this seems related to credit insertion. The read part returns 0
    ; all the time now and it works properly (like reading in ghost $800003 address)
    PL_P    $186A0,write_d2_to_d1
    PL_P    $1865c,read_d0_from_d1
    PL_P    $2205a,read_joy_buttons

    PL_IFC1X    0
    PL_PS   $0a242,set_credits
    PL_PS   $0c18a,set_credits
    PL_PS   $0c234,set_credits
    PL_PS   $0c514,set_credits
    PL_PS   $0c542,set_credits
    PL_PS   $0c5a0,set_credits
    PL_PS   $0c5e2,set_credits
    PL_PS   $0c706,set_credits
    PL_PS   $0cdee,set_credits
    PL_PS   $0d2f4,set_credits
    PL_PS   $0d91c,set_credits
    PL_PS   $11162,set_credits
    PL_PS   $111a6,set_credits
    PL_PS   $11430,set_credits
    PL_PS   $12044,set_credits
    PL_ENDIF

	PL_END
      
old_vbl
    dc.l    0