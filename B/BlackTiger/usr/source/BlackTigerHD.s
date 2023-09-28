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
	OUTPUT	"BlackTiger.slave"
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

SCORESTART=$183C5
SCOREEND=$18430

;============================================================================

	IFD	DEBUG
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $10000
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
STACKSIZE = 5000

JSRLIB:MACRO
	jsr	_LVO\1(a6)
	ENDM

JMPLIB:MACRO
        jmp    _LVO\1(a6)
        ENDM

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s

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


slv_name	dc.b	"Black Tiger"
		IFD	DEBUG
		dc.b	"(DEBUG)"
		ENDC
		dc.b	0
slv_copy		dc.b	"1989 Capcom/U.S. Gold",0
slv_info		dc.b	"Install & fix by JOTD",10,10
		dc.b	"Thanks to Ralf for original JST install",10,10
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
	movem.l	(a7)+,a0-a2/a6/d0-d1

	jsr	($C,a4)		; calls bootblock

	; never reached
	moveq.l	#0,D0
	rts


_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

;---------------

pl_bootblock	PL_START
		PL_S	$8+$C,6	; skip stack set
		PL_P	$12C+$C,jmp_a6
		PL_END

pl_jmpa6
		PL_START
	;;	PL_S	$A5BE,6			; no stack reloc (stays in fastmem)
		PL_PS	$A632,_pre_jmpa0_1
		PL_PS	$A662,_pre_jmpa0_2
		PL_L	$A88A,$4EB80106		; dbf delay
		PL_P	$106,_emulate_dbf

		IFEQ	1
		; fixing that one crashes badly/corrupts the game for unknown reason
		PL_P	$10C,restore_code_2
		PL_L	$BAFC,$4EF8010C
		ENDC
		; fix SMC
		PL_P	$B810,restore_code
		
		PL_PS	$B7D8,set_rts
		PL_PS	$BA78,set_rts
		PL_PS	$BAA0,set_rts
		PL_PS	$BAE0,set_rts
		IFEQ	1
		PL_PS	$A8A0,jmp_a6_2
		
		PL_P	$0B820,jmp_a6_3
		PL_P	$0BB06,jmp_a6_3
		PL_P	$0BD54,jmp_a6_3
		PL_P	$0BF28,jmp_a6_3
		ENDC

		PL_END

pl_jmpa0_1
		PL_START
		PL_P	$100,_save_score	; "" ""
		PL_P	$106,_emulate_dbf
		PL_W	$FF62,0			; fixes weird access fault
		PL_L	$103DC,$70004E75	; removes protection
		PL_L	$11448,$4EF80100	; hiscore save
		PL_L	$101FE,$4EB80106	; dbf loop
		PL_L	$11518,$4EB80106	; dbf loop
		PL_L	$11548,$4EB80106	; dbf loop
		PL_END

		IFEQ	1
jmp_a6_3
	MOVEA.L	0(A6,D7),A6		;0B820: 2C767000	; patch
	cmp.l	#$4A790000,a6
	bne.b	.ok
	move.w	#$F00,$DFF180
	; A6 has been trashed by some buggy interrupt code? retry it
	lea	$B826,A6
	bra	jmp_a6_3
.ok
	JMP	(A6)			;0B824: 4ED6

jmp_a6_2
	add.w	d0,a6
	move.l	(a6),a6
	cmp.l	#$4A790000,a6
	bne.b	.ok
	move.w	#$F00,$DFF180
	; A6 has been trashed by some buggy interrupt code? retry it
	lea	$A8AA,a6
	bra.b	jmp_a6_2
.ok
	jmp	(a6)
	ENDC
	
_emulate_dbf:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts


_pre_jmpa0_1:
	move.l	$C31E,d1
	APPLY_PATCHLIST	jmpa0_1
	bsr	_load_scores
	rts

_pre_jmpa0_2:
	move.l	$C31E,d1
	rts

jmp_a6:
	APPLY_PATCHLIST	jmpa6
	sub.l	A2,A2
	sub.l	A4,A4
	jmp	(A6)

restore_code
	move.l	(0,a6,d7.w),a6
restore_code_2
	move.w	d6,(a6)		; SMC
	bra	_flushcache

set_rts
	move.w	(a6),d6
	move.w	#$4E75,(a6)	; SMC sets RTS
	bra	_flushcache

_load_scores:
	movem.l	D0-D1/A0-A2,-(A7)
	move.l	(_resload,pc),a2	
	lea	_scorename(pc),a0
	lea	SCORESTART,A1
	move.l	#SCOREEND-SCORESTART,D0
	moveq.l	#0,D1
	jsr	(resload_LoadFileOffset,a2)
	movem.l	(A7)+,D0-D1/A0-A2
	rts

_save_score:
	; save score

	movem.l	D0-D1/A0-A2,-(A7)
;	move.l	_custom5(pc),d0
;	bne.b	.skip		; don't save if trainer on

	move.l	(_resload,pc),a2	
	lea	_scorename(pc),a0
	lea	SCORESTART,A1
	move.l	#SCOREEND-SCORESTART,D0
	moveq.l	#0,D1
	jsr	(resload_SaveFileOffset,a2)

;.skip
	movem.l	(A7)+,D0-D1/A0-A2
	unlk	A6		; original code
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0
_scorename:
	dc.b	"blacktiger.high",0
	even

;============================================================================

	END
