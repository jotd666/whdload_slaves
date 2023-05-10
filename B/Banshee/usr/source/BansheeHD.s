;*---------------------------------------------------------------------------
;  :Program.	BansheeHD.asm
;  :Contents.	Slave for "Banshee"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BansheeHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Banshee.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

SEGTRACKER
CHIP_ONLY
;============================================================================

CHIPMEMSIZE	= $1FF000
	IFD		CHIP_ONLY
FASTMEMSIZE	= $0000
	ELSE
FASTMEMSIZE = $80000	
	ENDC
	
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
CACHE
BOOTDOS
HISCORE_LEN = $F0
DUMMY_CD_DEVICE = 1
USE_DISK_NONVOLATILE_LIB = 1

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_Req68020|WHDLF_ReqAGA|WHDLF_NoKbd
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	kick31cd32.s
IGNORE_JOY_DIRECTIONS
	include	ReadJoyPad.s

;============================================================================



_assign_1
	dc.b	"Banshee1",0
_assign_2
	dc.b	"Banshee2",0
_assign_3
	dc.b	"Banshee3",0
_assign_4
	dc.b	"Banshee4",0
_assign_5
	dc.b	"Bans1",0
	
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"4.0"
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

slv_name		dc.b	"Banshee AGA/CD³²"
		IFD		CHIP_ONLY
		dc.b	" (debug/chip mode)"
		ENDC
		dc.b	0
slv_copy		dc.b	"1992 Core Design",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"Thanks to BTTR for disk images",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
;		dc.b    "C1:L:Start with lives:5,25,45;"			
;		dc.b    "C2:B:Infinite power weapons;"			
;		dc.b    "C3:B:Don't steal power weapons at level 89;"			
;        dc.b    "C4:X:Trainer Infinite Lives & Ammo:0;"
		dc.b	0

_intro:
	dc.b	"picture.exe",0
_program:
	dc.b	"bans.exe",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

_bootdos
	clr.l	$0.W


	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

	;for CD³² version
	
		bsr	_patch_cd32_libs
		bsr	_detect_controller_types
		
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign_1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_5(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load intro
		lea	_intro(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe
	;load main
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)



_emu_copylock:
	movem.l	D1/A0,-(A7)
	move.l	8(A7),A0	; return address: copylock start
	lea	$794(A0),A0	; aera to change (copylock+$79A)

	MOVE	#$0019,D1		;4DC: 323C0019
	MOVE.L	#$0005DB42,D0		;4E0: 203C0005DB42
.LAB_0002:
	MULU	#$0011,D0		;4E6: C0FC0011
	ADDQ.L	#1,D0			;4EA: 5280
	MOVE	D0,(A0)+		;4EC: 30C0
	DBF	D1,.LAB_0002		;4EE: 51C9FFF6


	move.l	#$CF3EED9B,D0
	move.l	D0,(A3)
	movem.l	(A7)+,D1/A0
	rts

pl_floppy:
	PL_START
	; fix access faults
	PL_PS	$0111a6,_move_a4_d0
	PL_PS	$011d1e,_move_a4_d3
	
    PL_PS	$011ce0,_move_a4_d6
    PL_PS	$0172d0,_move_a4_d6
    PL_PS	$0172fc,_move_a4_d6
    PL_PS	$01735c,_move_a4_d6
    PL_PS	$01828c,_move_a4_d6	
	PL_PS	$00857a,move_potgo_d2
	PL_PS	$07299e,_emu_copylock
	PL_L	$07299e+6,$600008AC		; skip to copylock end
	
	PL_END
	
; < d7: seglist

_patch_exe:
	movem.l	D0-D1/A0-A2,-(A7)	

	bsr	install_joy_reader

	move.l	_resload(pc),a2
	lea		pl_floppy(pc),a0
	move.l	d7,a1
	jsr		(resload_PatchSeg,a2)
	
	movem.l	(A7)+,D0-D1/A0-A2
	rts




;	lea	.move75(pc),a2
;	moveq.l	#6,D0
;	bsr	_hexsearch
;	cmp.l	#0,A0
;	beq.b	.sk5b
;
;	; CD³² version: any key pauses the game
;	; but quits immediately afterwards. This is stupid
;
;	move.w	#$6006,2(A0)
;.sk5b


	; save score buffer address for later

	; get_section 1
	; add $01b2d6
;	lea	_score_address(pc),a1
;	move.l	A0,(A1)

	; loads score

	bsr	_load_hiscore
.sk6
	move.l	(A3),A0	; next hunk: #2
	add.l	A0,A0
	add.l	A0,A0
	move.l	A0,A3
	move.l	(A3),A0	; next hunk: #3
	add.l	A0,A0
	add.l	A0,A0
	move.l	A0,A3
	move.l	A0,A1
	add.l	#2700,A1
	lea	.copylock(pc),a2
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.sk7

	addq.l	#2,A0
	move.w	#$4EB9,(A0)+
	pea	_emu_copylock(pc)
	move.l	(A7)+,(A0)+
	move.l	#$600008AC,(A0)+	; goto copylock end
.sk7


.move75
	dc.w	$670A
	dc.l	$13FC0075
.scorestart:
	dc.l	$20FF2032,$30303030
.rncdecrunch:
	dc.l	$48E7FFFC,$4FEFFE80
	dc.w	$244F

.copylock:
	dc.l	$42937004,$7200487A
	dc.w	$000A
.savehiscore:
	dc.l	$20BC0000,$0000217C,$0,$00045088

MOVEA4DX:MACRO
_move_a4_d\1:
	move.w	$8A(A0),D\1
	cmp.l	#-1,A4	; does the game try to access $FFFFFFFF address?
	beq.b	.avoid
	cmp.w	(A4),D\1
	rts
.avoid
	cmp.l	#0,A4	; so Z flag is cleared
	rts
	ENDM

	MOVEA4DX	0
	MOVEA4DX	3
	MOVEA4DX	6

install_joy_reader
	lea	old_int_3(pc),a0
	move.l	$6C.W,(a0)
	lea	joy_reader(pc),a0
	move.l	a0,$6C.W
	rts

joy_reader
	btst	#5,$dff01f
	beq.b	.skip

	; only VBL interrupt is of interest here

	movem.l	d0/a0,-(a7)
	bsr		_joystick
	lea	dff016_value(pc),a0
	move.l	joy1(pc),d0
	st.b	(a0)
	btst	#JPB_BTN_BLU,d0	; port 1
	bne.b	.no1
	bclr	#6,(a0)
.no1
	move.l	joy0(pc),d0
	btst	#JPB_BTN_BLU,d0	; port 1
	bne.b	.no0
	bclr	#2,(a0)
.no0
	movem.l	(a7)+,a0/d0
.skip
	move.l	old_int_3(pc),-(a7)
	rts
old_int_3
	dc.l	0
dff016_value
	dc.w	0

_save_hiscore:
	clr.l	(A0)		; stolen code

	tst.w	D1
	bne.B	.skip

	movem.l	D0-D1/A0-A2,-(A7)
	move.l	_score_address(pc),A1
	move.l	#HISCORE_LEN,D0
	lea	_savename(pc),A0
	move.l	_resload(pc),A2
	jsr	resload_SaveFile(a2)
	movem.l	(A7)+,D0-D1/A0-A2
.skip
	rts

_load_hiscore:
	movem.l	D0-D1/A0-A2,-(A7)
	move.l	_score_address(pc),A1
	move.l	#HISCORE_LEN,D0
	lea	_savename(pc),A0
	move.l	_resload(pc),A2
	jsr	resload_LoadFile(a2)

	movem.l	(A7)+,D0-D1/A0-A2
	rts


move_potgo_d2:
	move.b	dff016_value(pc),D2
	rts



;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

_hexsearch:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
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


_score_address:
	dc.l	0
_savename:
	dc.b	"banshee.hi",0
	even
_scorebuffer:
	dc.b	"SHIT"	; invalid hiscore
	ds.b	HISCORE_LEN-4,0


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
