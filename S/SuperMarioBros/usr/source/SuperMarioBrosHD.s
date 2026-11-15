;*---------------------------------------------------------------------------
;  :Program.	BlackTigerHD.asm
;  :Contents.	Slave for "Black Tiger" from US Gold
;  :Author.	JOTD
;  :Original	v1 JOTD
;  :History.	23.05.01 started
;		11.02.05 rework
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"SuperMarioBros.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

APPLY_PATCHLIST:MACRO
	movem.l	A0-A2/D0-D1,-(A7)
	sub.l	A1,A1
	lea	pl_\1(pc),A0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(A7)+,A0-A2/D0-D1
	ENDM


;============================================================================

	IFD	DEBUG
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;HRTMON
DISKSONBOOT
BOOTBLOCK
;HDINIT
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
;STACKSIZE = 5000



;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_EmulPriv
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s

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


slv_name	dc.b	"Super Mario Bros"
		IFD	DEBUG
		dc.b	"(DEBUG)"
		ENDC
		dc.b	0
slv_copy		dc.b	"2026 AgnusCopperfield^SSB",0
slv_info		dc.b	"Install by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	$A,$D,0

		even

;============================================================================

	;initialize kickstart and environment


_bootblock:
	movem.l	a0-a2/a6/d0-d1,-(A7)

	;get tags
	lea	(_tag,pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Control,a2)

	; sets cache in chip memory to speedup the game

	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	lea	pl_bootblock(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	
	move.l	#$10000-$5BE8,d0
	move.l	#MEMF_CHIP,d1 
	move.l	4,A6
	jsr		_LVOAllocMem(a6)
	movem.l	(a7)+,a0-a2/a6/d0-d1

	jsr	($C,a4)		; calls bootblock

	; never reached
	moveq.l	#0,D0
	rts

go:
	MOVEA.L	A4,A1			;62: 224c
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	lea	512(a3),a1
	lea	boot_base(pc),a0
	move.l	a1,(a0)
	lea	pl_boot(pc),a0
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	JMP	512(A3)			;64: 4eab0200
	
run_prog:
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	lea	(a3,d2.L),a1
	lea	pl_prog(pc),a0
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	
	MOVEA.L	A4,A1			;101e8: 224c
	jmp	(0,A3,D2.L)		;101ea: 4eb32800
	
	
run_main:
	move.l	boot_base(pc),a2
	add.w 	#$228,a2
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	move.l	a3,a1
	lea	pl_main(pc),a0
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp		(a3)
	
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

jump_code:
	MOVEA.L	D2,A1			;13046: 2242
	MOVEA.L	(A1),A1			;13048: 2251
	JMP	(A1)			;1304a: 4e91

check_quitkey:
	move.b	$bfec01,d0
	NOT.B	D0			;47f70b34: 4600
	ROR.B	#1,D0			;47f70b36: e218
	cmp.b	_keyexit(pc),d0
	beq		_quit

	rts



patch_game:
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	move.l	a0,a1
	lea	pl_game(pc),a0
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts
run_another:
	MOVE.L	#$43504231,D1		;24376: 223c43504231
	MOVE.L	#$00018a84,D2		;2437c: 243c00018a84
	MOVEA.L	D3,A0			;24382: 2043
	bsr	patch_game
	JMP	(A0)			;24384: 4ed0

run_another2:
	MOVE.L	#$43504231,D1		;24412: 223c43504231
	MOVE.L	#$00018a84,D2		;24418: 243c00018a84
	LEA	$14400,A4		;2441e: 49f9000
	MOVEA.L	D3,A0			;24424: 2043
	bsr	patch_game
	JMP	(A0)			;24426: 4ed0

;---------------

pl_bootblock:
	PL_START
	PL_PS	$62,go
	PL_END

pl_game:
	PL_START
	PL_PSS	$30b2e,check_quitkey,4
	PL_END
	
pl_boot:
	PL_START
	PL_L	$2C0,$91C84E71	; read VBR => A0=0
	PL_W	$2d2,$4E73		; skip PCR/CACR shit
	PL_PS	$152,run_main
	PL_PS	$1e8,run_prog
	PL_END
	
pl_main:
	PL_START
	PL_L	$3672-$a00,$70004E71	; read VBR => A0=0
	PL_B	$3680-$a00,$60		; skip PCR/CACR shit
	PL_R	$3a78-$a00	; skip VBR,PCR/CACR shit
	PL_W	$3576-$a00,$7000
	PL_NOP	$3578-$a00,4
	PL_END

pl_prog:
	PL_START
	PL_NOP		$2423a-$23dec,6					; remove zero vbr (again!)
	PL_S		$24238-$23dec,$24272-$24238		; skip 680x0 detection & VBR (again!)
	PL_P		$2434a-$23dec,run_another
	PL_P		$243e6-$23dec,run_another2
	PL_END
	
_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0
boot_base:
	dc.l	0

