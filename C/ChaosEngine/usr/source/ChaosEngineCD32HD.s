;*---------------------------------------------------------------------------
;  :Program.	ChaosEngineHD.asm
;  :Contents.	Slave for "ChaosEngine"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ChaosEngineHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"ChaosEngineCD32.slave"
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
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $1C0000
FASTMEMSIZE	= $100000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
INITAGA
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'


DUMMY_CD_DEVICE = 1

;USE_DISK_LOWLEVEL_LIB

USE_DISK_NONVOLATILE_LIB    ; not used anyway

;============================================================================

	INCLUDE	kick31cd32.s
    include shared.s
    
;============================================================================



	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$0

_assign1
	dc.b	"CD0",0
_assign2
	dc.b	"ChaosEngine",0

slv_name		dc.b	"Chaos Engine CD³²"
			IFD	CHIP_ONLY
			dc.b	"(DEBUG/CHIP MODE)"
			ENDC
			dc.b	0
slv_copy		dc.b	"1994 The Bitmap Brothers",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
			dc.b	"CD³² emulation keys:",10,10
			dc.b	"Player 1",10
			dc.b	"P: pause",10
			dc.b	"SPC: special weapon",10
			dc.b	"L-shift: green",10
			dc.b	"R-shift: yellow",10
			dc.b	"[When paused] SPC+both ALTs: quit",10,10
			dc.b	"Player 2: keys 567890",10,10
	    dc.b	'use CUSTOM= to set the 12-char level password on startup',10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
    
slv_config
    dc.b    "BW;"
    dc.b    "C1:X:Trainer Infinite Energy:0;"
    dc.b    "C1:X:Trainer 99 Lives:1;"
	dc.b	0
exe_message:
	dc.b	"The file ""data/ACHAOS"" is still RNC-packed",10
	dc.b	"Please use XFDDecrunch on it or re-install",0

	EVEN

_program:
	dc.b	"ACHAOS",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN
_language:
	dc.l	0
;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	_resload(pc),a2		;A2 = resload
    
    ;get password
    lea	(password,pc),a0
    moveq.l	#0,d1
    move.l	#13,d0
    jsr	(resload_GetCustom,a2)

	;open doslib
    lea	(_dosname,pc),a1
    move.l	(4),a6
    jsr	(_LVOOldOpenLibrary,a6)
    move.l	d0,a6			;A6 = dosbase

	;assigns
    lea	_assign1(pc),a0
    sub.l	a1,a1
    bsr	_dos_assign

    bsr	_patch_cd32_libs
    bsr	force_joysticks
	
	;load exe


		lea	_program(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)

		cmp.l	#92800,D0
		bne.b	.no_packed

		pea	exe_message(pc)
		pea	TDREASON_FAILMSG
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

.no_packed
		cmp.l	#696364,D0
		beq.b	.ok

		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.ok
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

patch_main
	IFD	CHIP_ONLY
    move.l  d7,$110.W
    add.l   #4,$110.W
    ELSE
	bsr	reloc_chip_data
	ENDC
	addq.l	#4,d7
	move.l	d7,a1
 
    movem.l a1,-(a7)
    add.l #$10056,a1
    bsr restore_password
    movem.l (a7)+,a1

	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)
	rts

; make-up for the game bug: calls the routine without the tag id
; and it doesn't work (you'd have to disconnect mouse from port 0)

force_joysticks:
	movem.l	d0-a6,-(a7)
	lea	.lowlevel_name(pc),a1
	moveq	#0,d0
	move.l	$4.W,a6
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	bne		.1
	illegal
.1:
	move.l	d0,a6

	lea	.joytag(pc),a1
	moveq	#0,d0
	jsr	_LVOSetJoyPortAttrsA(a6)

	lea	.joytag(pc),a1
	moveq	#1,d0
	jsr	_LVOSetJoyPortAttrsA(a6)

	movem.l	(a7)+,d0-a6
	rts

.joytag
	dc.l	SJA_Type
	dc.l	SJA_TYPE_GAMECTLR
	dc.l	0
.lowlevel_name
	dc.b	"lowlevel.library",0
	even


CHIP_DATA_OFFSET = $2BE22 ; $A49DC
CHIP_DATA_SIZE = $A77FC-CHIP_DATA_OFFSET

; < D7: seglist

reloc_chip_data:
	movem.l	D0-A6,-(a7)
	move.l	$4.W,a6
	moveq.l	#MEMF_CHIP,d1
	move.l	#CHIP_DATA_SIZE,d0
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	bne.b	.okalloc
	ILLEGAL
.okalloc
	; first, relocate

	move.l	d0,a3		; start of chipmem

	move.l	d7,a1
	addq.l	#4,a1
	add.l	#CHIP_DATA_OFFSET,a1	; offset to change
	sub.l	a3,a1		; a1: offset to substract

	lea	offsets(pc),a0
	move.l	d7,a2
	addq.l	#4,a2
.reloc:
	move.l	(a0)+,d0
	bmi.b	.out

	move.l	(a2,d0.l),d1
	cmp.l	#CHIPMEMSIZE,d1
	bcc.b	.ok
	ILLEGAL		; to early detect double entry in list
.ok
	move.l	(a2,d0.l),d1

	sub.l	a1,d1
	move.l	d1,(a2,d0.l)
	bra.b	.reloc
.out
	; then copy the data with corrected relocs into chipmem

	move.l	d7,a1
	addq.l	#4,a1
	
	add.l	#CHIP_DATA_OFFSET,a1	; offset to change
	move.l	#CHIP_DATA_SIZE/4,d1
.copycl
	move.l	(a1)+,(a3)+
	subq.l	#1,d1
	bne.b	.copycl

	bsr	_flushcache
	movem.l	(a7)+,d0-a6
	rts

program_start
	dc.l	0

offsets:
	dc.l	$01860+2	; 6
	dc.l	$0188C+2	; 6
	dc.l	$0573E+2	; 6
	dc.l	$05754+2	; 6
	dc.l	$05770+2	; 6
	dc.l	$05788+2	; 6
	dc.l	$0579A+2	; 6
	dc.l	$057A4+2	; 6
	dc.l	$057D6+2	; 6
	dc.l	$0580C+2	; 6
	dc.l	$05820+2	; 6
	dc.l	$05D46+2	; 6
	dc.l	$0180A+2	; 6
	dc.l	$028C8+2	; 6
	dc.l	$0298A+2	; 6
	dc.l	$03572+2	; 6
	dc.l	$05672+2	; 6
	dc.l	$0569A+2	; 6
	dc.l	$056A8+2	; 6
	dc.l	$057B2+2	; 6
	dc.l	$058BC+2	; 6
	dc.l	$058EA+2	; 6
	dc.l	$05924+2	; 6
	dc.l	$0592C+2	; 6
	dc.l	$0593E+2	; 6
	dc.l	$0597E+2	; 6
	dc.l	$059AC+2	; 6
	dc.l	$059BA+2	; 6
	dc.l	$059CC+2	; 6
	dc.l	$059DA+2	; 6
	dc.l	$05A18+2	; 6
	dc.l	$05A40+2	; 6
	dc.l	$05A4E+2	; 6
	dc.l	$05A8C+2	; 6
	dc.l	$05AB4+2	; 6
	dc.l	$05AC0+2	; 6
	dc.l	$05D4C+2	; 6
	dc.l	$0AFD0+2	; 6
	dc.l	$0B118+2	; 6
	dc.l	$0B1BA+2	; 6
	dc.l	$0B266+2	; 6
	dc.l	$0B354+2	; 6
	dc.l	$0B448+2	; 6
	dc.l	$0B748+2	; 6
	dc.l	$0D394+2	; 6
	dc.l	$0D3A8+2	; 6
	dc.l	$0D3FE+2	; 6
	dc.l	$0D45C+2	; 6
	dc.l	$0D47C+2	; 6
	dc.l	$0D4D4+2	; 6
	dc.l	$0D526+2	; 6
	dc.l	$0D546+2	; 6
	dc.l	$0D596+2	; 6
	dc.l	$0E930+2	; 6
	dc.l	$0E96C+2	; 6
	dc.l	$0F01C+2	; 6
	dc.l	$123C2+2	; 6
	dc.l	$1FFB0+2	; 6
	dc.l	$1FFB8+2	; 6


	dc.l	$01800+2	; 6
	dc.l	$0181A+2	; 6
	dc.l	$01848+2	; 6
	dc.l	$0185A+2	; 6
	dc.l	$01874+2	; 6
	dc.l	$01886+2	; 6
	dc.l	$0564C+2	; 6
	dc.l	$056C0+2	; 6
	dc.l	$058A2+2	; 6
	dc.l	$05902+2	; 6
	dc.l	$059F2+2	; 6
	dc.l	$05A66+2	; 6
	dc.l	$10E4E+2	; 6
	dc.l	$10E84+2	; 6
	dc.l	$11D1A+2	; 6
	dc.l	$11D86+2	; 6
	dc.l	$11F2E+2	; 6
	dc.l	$1D72C+2	; 6
	dc.l	$285DE+2	; 6

	dc.l	-1

pl_main
	PL_START
	PL_S	$20,$4		; skip CACR setting
	PL_S	$548,$50-$48	; skip read joypad 3 times
	PL_S	$4F6,$FE-$F6	; """"

	; game is ok with blitwaits, but CD32 specific intro is not

	PL_PS	$848C,wait_blit_1

	PL_PS	$601A,wait_blit_2
	PL_PS	$6204,wait_blit_2
	PL_PS	$627E,wait_blit_2
    
    ; else game lockups if intro is left running
    ; (checks for CD IO or something)
    PL_NOP  $829A,2
    
    PL_IFC1X    0
    PL_NOP  $01D1A,6
    PL_ENDIF
    PL_IFC1X    1
    PL_PSS  $024E0,set_lives,2
    PL_ENDIF
    
    PL_IFBW
    PL_PS    $4E54,_level_loaded
    PL_ENDIF
    
	PL_END

wait_blit_1
	bsr	wait_blit
	move.w       #8,($66,a3)	; original
	rts

wait_blit_2
	bsr	wait_blit
	move	d1,70(a3)
	move	d1,68(a3)
	moveq	#0,d1
	rts

wait_blit

.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
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

	add.l	d7,d7
	add.l	d7,d7

    
	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	a4-a6/d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a4-a6/d7
.skip
	;call
	move.l	d7,a1

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

; dummy symbol to be able to include some shared routines in shared.s
_joystick:
    rts
    
;============================================================================
