;*---------------------------------------------------------------------------
;  :Program.	castlemasterslave.asm
;  :Contents.	Slave for "Castle Master"
;  :Author.	Harry
;  :History.	20.10.1998/27.1.2001
;		04.09.11 Wepl: data directory added
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25
;  :To Do.
;---------------------------------------------------------------------------*

CRC_V1	= $6a43	;original with RN copylock (SPS447)
CRC_V2	= $a5d1	;rerelease (SPS2773)
CRC_V3  = $6f13 ;Amiga Games Compilation #1
CRC_V4  = $3F61; Virtual Reality Compilation (Together with the Crypt) (SPS612)
V_SPS447	= 1
V_SPS2773	= 2
V_COMPIL   = 3
V_SPS612     = 4

		INCDIR	Includes:
		INCLUDE	lvo/dos.i
		INCLUDE	lvo/exec.i
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
		
	IFD BARFLY

	

		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		SUPER

		OUTPUT	wart:c/castlemaster/CastleMaster.Slave
	ENDC


;============================================================================
;CHIP_ONLY

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000	
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

	IFND	CHIP_ONLY
BLACKSCREEN
	ENDC
	
;DISKSONBOOT
;DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 11000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE
	
SEGTRACKER

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

;============================================================================

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

slv_name	dc.b	"Castlemaster"
		IFD	CHIP_ONLY
		dc.b	" (CHIP/debug mode)"
		ENDC
		
			dc.b	0
slv_copy	dc.b	"1990 Incentive Software/Domark",0
slv_info	dc.b	"adapted by Harry/Wepl/JOTD",10,10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	
slv_config:
	dc.b	"C1:L:language:english,german;"
	dc.b	"C2:L:intro:show,skip select knight,skip select princess;"
	dc.b	"C3:B:Castle Master 2;"
	dc.b	0
	

;======================================================================


		dc.b	"$VER: Castlemaster_Slave "
	DECL_VERSION
		dc.b	0
		even

_program_memory
	dc.l	0

_bootdos
	MOVE.L	_resload(PC),A2
	MOVE.L	#$400,D0
	MOVEQ.L	#0,D1
	LEA.L	STFILE(PC),A0
	LEA.L	$30000,A1
	JSR	(resload_LoadFileOffset,a2)

	MOVE.L	#$400,D0
	LEA.L	$30000,A0
	jsr	(resload_CRC16,a2)

	LEA.L	VERSION(PC),A0
	CMP.W	#CRC_V1,D0
	BEQ.S	.V1
	CMP.W	#CRC_V2,D0
	BEQ.W	.V2
	CMP.W	#CRC_V3,D0
	BEQ.W	NOTSUPP
	CMP.W	#CRC_V4,D0
	BEQ.W	.V4
	BRA.W	NOTSUPP

.V1	MOVE.B	#V_SPS447,(A0)
	bra.s	.VA

.V2	MOVE.B	#V_SPS2773,(A0)
	bra.s	.VA

.V4	MOVE.B	#V_SPS612,(A0)
.VA
	IFND	CHIP_ONLY
	move.l	$4,a6
	move.l	#$6A000-$2C000,d0
	move.l	#MEMF_PUBLIC,d1
	jsr		_LVOAllocMem(a6)
	lea		_program_memory(pc),a0
	move.l	d0,(a0)
	bne.b	.ok
	illegal
.ok
	ENDC
	;get tags
	lea     (_tag,pc),a0
	jsr     (resload_Control,a2)
	move.l	_language_setting(pc),d0

	TST.L	D0
	BEQ.S	.NOVALUE
	CMP.W	#3,D0
	BHI.S	.NOVALUE
	ADD.W	#$43,D0
	LEA.L	LANGUAGE(PC),A0
	MOVE.B	D0,(A0)

.NOVALUE
	MOVE.L	$4.W,A6
	MOVEQ.L	#0,D0
	LEA	DOSNAM(PC),A1
	JSR	_LVOOpenLibrary(A6)
	MOVE.L	D0,A6

	LEA.L	STFILE(PC),A0
	MOVE.L	A0,D1
	JSR	_LVOLoadSeg(A6)
	LSL.L	#2,D0
	MOVE.L	D0,A1
	ADDQ.L	#4,A1


	MOVE.W	#$83E0,$DFF096
	MOVE.W	#$200,$DFF100

	MOVE.B	VERSION(PC),D0
	lea		pl_boot_447(pc),a0
	CMP.B	#V_SPS447,D0
	BEQ.S	.patch

	lea		pl_boot_2773(pc),a0
	CMP.B	#V_SPS2773,D0
	BEQ.S	.patch
	
	lea		pl_boot_612(pc),a0
	CMP.B	#V_SPS612,D0
	BEQ.S	.patch
	

		illegal
.patch
	
	move.l	a1,a3
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	
	IFD CHIP_ONLY
	movem.l a6,-(a7)
	move.l	$4.w,a6
	move.l  #$10000-$C250-$10,d0	; align
	move.l  #MEMF_CHIP,d1
	jsr _LVOAllocMem(a6)
	movem.l (a7)+,a6
	ENDC
	
	SUB.L	A0,A0
	MOVEQ.L	#0,D0
	JSR	(A3)

	ILLEGAL

pl_boot_447
	PL_START
	PL_S	$80,$f0-$80		; skip language select
	PL_PS	$1A4,PATCHINTRO
	PL_END
	
pl_boot_2773
	PL_START
	PL_W	$68,$74
	PL_PS	$18a,PATCHINTRO
	PL_END
	
pl_boot_612
	PL_START
	PL_IFC3
	PL_W	$76,$7032	; CM 2
	PL_W	$190,$7032	; CM 2
	PL_ELSE
	PL_W	$76,$7031	; first opus
	PL_W	$190,$7031	; first opus
	PL_ENDIF
	PL_PS	$18A,PATCHINTRO_612
	
	PL_S	$78,$be-$78		; skip version select
	PL_END

PI_MACRO:MACRO
	lea		pl_intro_\1(pc),a0
	CMP.B	#V_SPS\1,D0
	beq.b	.patch
	ENDM
	
PATCHINTRO_612
	lea		pl_intro_612(pc),a0
	bra.b	_do_patch_intro
	
PATCHINTRO
	MOVE.B	VERSION(PC),D0
	PI_MACRO	447
	PI_MACRO	2773
	illegal
.patch
	MOVEQ.L	#0,D0
	MOVE.B	LANGUAGE(PC),D0
			;ORG:	MOVE.B	LANGUAGE,D0 - $44-46 D,E,F
_do_patch_intro
	MOVEM.L	D0/D1/A0-A2,-(A7)
	move.l	_resload(pc),a2
	move.l	a6,a1
	jsr		resload_Patch(a2)
	MOVEM.L	(A7)+,D0/D1/A0-A2

	RTS

pl_intro_447
	PL_START
	PL_PS	$B88,PATCHMAIN
	PL_PSS	$1228,soundtracker_loop,2
	PL_W	$2606,$E3D6		;PROTECTION INTRO
	PL_PS	$a54,set_program_address
	PL_PS	$e44,kbint_hook	
	PL_END
	
pl_intro_2773
	PL_START
	PL_PS	$1e6,PATCHMAIN
	PL_PSS	$866,soundtracker_loop,2
	PL_PS	$b8,set_program_address
	PL_PS	$4a8,kbint_hook
	; skip intro & character select
	PL_IFC2
	PL_S	$22,$40-$22
	PL_ENDIF
	
	PL_END
	
pl_intro_612
	PL_START
	PL_IFC3
	PL_PS	$24a,PATCHMAIN_612_2
	PL_ELSE
	PL_PS	$24a,PATCHMAIN_612_1
	PL_ENDIF
	PL_PSS	$b00,soundtracker_loop,2
	IFND	CHIP_ONLY
	PL_PS	$d4,set_program_address
	ELSE
	; hack align main on $2C000
	PL_L	$D6,2000+$2C000-$2B584
	ENDC
	PL_PS	$71c,kbint_hook
	PL_I	$1b0		; file not found: crash
	
	; skip intro & character select
	PL_IFC2
	PL_S	$28,$5C-$28
	PL_ENDIF
	PL_END
	
set_program_address
	IFD		CHIP_ONLY
	; hack, memory isn't even allocated!, seems to work with 447/2773
	; and allows to debug the game easily
	lea		$80000,a0
	ELSE
	; set a block of fast memory
	move.l	_program_memory(pc),a0
	ENDC
	rts
	
kbint_hook
	move.l	d0,-(a7)
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq		_quit
	move.l	(a7)+,d0
	bclr	#0,d0
	rts
	
get_character
	move.l	_character_setting(pc),d2
	beq.b	.no_change
	move.l	d2,d1		; set character
	add.b	#'0',d1
.no_change
	rts
	
PATCHMAIN_612_1
	ext.w	d1	; $31 or $32 (character)
		
	MOVEM.L	D0/D1/A0-A2,-(A7)
	move.l	a6,a1
	lea		pl_main_612_1(pc),a0
	move.l	_resload(pc),a2
	jsr		(resload_Patch,a2)
	MOVEM.L	(A7)+,D0/D1/A0-A2
	bsr		get_character
	
	jmp	28(A6)
	
PATCHMAIN_612_2
	ext.w	d1	; $31 or $32 (character)
		
	MOVEM.L	D0/D1/A0-A2,-(A7)
	move.l	a6,a1
	lea		pl_main_612_2(pc),a0
	move.l	_resload(pc),a2
	jsr		(resload_Patch,a2)
	MOVEM.L	(A7)+,D0/D1/A0-A2
	bsr		get_character
	
	jmp	28(A6)
	
PATCHMAIN
	MOVE.B	VERSION(PC),D7
	lea		pl_main_447(pc),a0
	CMP.B	#V_SPS447,D7
	beq.S	.PVA
	lea		pl_main_2773(pc),a0
	CMP.B	#V_SPS2773,D7
	beq.S	.PVA
	ILLEGAL
	
.PVA
	MOVEM.L	D0/D1/A0-A2,-(A7)
	move.l	a6,a1
	move.l	_resload(pc),a2
	jsr		(resload_Patch,a2)
	MOVEM.L	(A7)+,D0/D1/A0-A2

	; here: D0 = language ($45=english)
	; D1 = character ($31=prince, $32=princess)
	bsr		get_character
	MOVEQ.L	#-1,D7
	RTS

pl_main_447
	PL_START
	PL_S	$8584,$8f20-$8584	; skip copylock
	PL_PSS	$74f4,soundtracker_loop,2
	PL_PS	$2746,skip_access_fault
	PL_S	$274C,$58-$4C
	PL_PS	$8304,kbint_hook
	PL_END
	
pl_main_612_1
	PL_START
	PL_S	$34550-$2C000,$34eec-$34550	; skip copylock
	PL_PSS	$334d0-$2C000,soundtracker_loop,2
	PL_PS	$342d0-$2C000,kbint_hook
	PL_END
	
pl_main_612_2
	PL_START
	PL_S	$33fc0-$2C000,$3495c-$33fc0	; skip copylock
	PL_PSS	$334d0-$2C000,soundtracker_loop,2
	PL_PS	$33d40-$2C000,kbint_hook
	PL_END
	
pl_main_2773
	PL_START
	PL_PSS	$7df8,soundtracker_loop,2
	PL_PS	$83f2,kbint_hook
	PL_END

	;MOVE.L	#$C944C944,$2D58(A6)	;PROTECTION MAIN
	;MOVE.L	#$60000992,$2D5C(A6)	; WTF remainder of harry code
	
	; this code is completely buggy, it reads the first instrument name
	; as a pointer, triggering access fault
	; (other versions don't have this issue)
skip_access_fault
	cmp.l	#$636D4A26,a0		; soundtracker module header
	beq.b	.zout
	MOVE.L	(A0)+,D1		;82746: 2218
	ADDQ.W	#2,A0			;82748: 5448
	DBF	D0,LAB_015C		;8274a: 51c80006
	rts		;8274e: 60000008
.zout
	sub.l	a0,a0
	rts
	
LAB_015C:
	ADDA.L	D1,A0			;82752: d1c1
	BRA.B	skip_access_fault
	
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

soundtracker_loop
	move.w  d0,-(a7)
	move.w	#7,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
	rts 

;version	dc.w	0	;version of disks
STFILE	DC.B	'cm',0
	EVEN
DOSNAM	DC.B	'dos.library',0
	EVEN
LANGUAGE
	DC.B	$45
VERSION	dc.b	0
	EVEN

NOTSUPP
	PEA	TDREASON_WRONGVER
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
	
_tag		dc.l	WHDLTAG_CUSTOM1_GET
_language_setting	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_character_setting	dc.l	0
		dc.l	0
