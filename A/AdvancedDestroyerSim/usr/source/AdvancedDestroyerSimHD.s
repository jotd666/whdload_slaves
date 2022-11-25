;*---------------------------------------------------------------------------
;  :Program.	AdvancedDestroyerSimHD.asm
;  :Contents.	Slave for "AdvancedDestroyerSim"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: AdvancedDestroyerSimHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"AdvancedDestroyerSim.slave"
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

	IFD	DEBUG
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

_assign
	dc.b	"AdvancedDestroyerSim",0

slv_name		dc.b	"Advanced Destroyer Simulator"
			IFD	DEBUG
			dc.b	" (DEBUG MODE)"
			ENDC
			dc.b	0
slv_copy		dc.b	"1991 Futura",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
			dc.b	"Thanks to EP for the crack",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"dt",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

_bootdos
;;	bsr	_beamdelay_calibration

	move.l	(_resload),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		bsr	get_version

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
	patch	$100,dbf_d0
	patch	$106,dbf_d6
	patch	$10C,dbf_d2

	moveq	#0,d2
	bsr	get_section
	lea	pl_main_0(pc),a0
	jsr	resload_Patch(a2)

	move.l	#10,d2
	bsr	get_section
	lea	pl_main_10(pc),a0
	jsr	resload_Patch(a2)


	rts

emu_3_nops:
	illegal
	rts

get_version:
	movem.l	d0-d1/a1,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#117812,D0
	beq.b	.c2151

	; SPS 2406 (exe size = 118380) is not supported yet

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.c2151
.out
	movem.l	(a7)+,d0-d1/a1
	rts

game_beam_delay
.LAB_061D:
	IFD	DEBUG
	btst	#6,$bfe001
	beq.b	.end
	ENDC

	MOVE.L	$dff004,D0		;0D140: 203900DFF004
	ANDI.L	#$0001FF00,D0		;0D146: 02800001FF00
	CMP.L	#$00003200,D0		;0D14C: B0BC00003200
	BLS	.LAB_061D		;0D152: 6300FFEC
	CMP.L	#$0000FA00,D0		;0D156: B0BC0000FA00
	BHI	.LAB_061D		;0D15C: 6200FFE2
	MOVE.L	D0,D1			;0D160: 2200
	SUBI.L	#$00000100,D1		;0D162: 048100000100
.LAB_061E:

	IFD	DEBUG
	btst	#6,$bfe001
	beq.b	.end
	ENDC

	MOVE.L	$dff004,D0		;0D140: 203900DFF004
	ANDI.L	#$0001FF00,D0		;0D16E: 02800001FF00
	CMP.L	D1,D0			;0D174: B081
	BNE	.LAB_061E		;0D176: 6600FFF0
.end
	RTS				;0D17A: 4E75

wait_toggle_vpos:
.wait
	BTST	#0,$dff005
	BEQ	.wait
	rts

.LAB_061C:
	BTST	#0,$dff005
	BNE	.LAB_061C
	RTS

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


pl_main_0
	PL_START

	; disk protection

	PL_L	$D016,$4E714E71
	PL_W	$D01A,$4E71
	PL_R	$D17C

	; other patches

	PL_L	$D280,$4EB80106
	PL_L	$D308,$4EB80100
;;	PL_PS	$D662,smc_1	; not reached?
	PL_P	$D9DC,wait_blit
	PL_P	$D9D2,wait_blit_dma
;	PL_PS	$D2A8,emu_3_nops
;	PL_PS	$D2EC,emu_3_nops
	PL_S	$D714,8
	PL_S	$D956,8
	PL_S	$D9D2,8
	PL_P	$D126,wait_toggle_vpos
	PL_P	$D140,game_beam_delay

;;	PL_P	$D7A2,do_blit_d2
;;	PL_BKPT	$D1FE
	PL_END

pl_main_10
	PL_START
	PL_L	$17252-$14244,$4EB8010C
	PL_P	$16D76-$14244,wait_blit
	PL_L	$15176-$14244,$4E714E71
	PL_PS	$1517A-$14244,wait_blit

	IFEQ	1
	PL_P	$16436-$14244,wait_blit_movem_d0a0
	PL_P	$15BE8-$14244,wait_blit_movem_d0a0
	PL_P	$15EA2-$14244,wait_blit_movem_d0a0
	PL_P	$16436-$14244,wait_blit_movem_d0a0
	PL_P	$16172-$14244,wait_blit_movem_d0a0
	PL_P	$164DA-$14244,wait_blit_movem_d2d7_a2a6
	ENDC

	PL_END

do_blit_d2
	move.w	D2,$DFF058	; original
	bsr	wait_blit
	rts

smc_1
	move.l	A0,-(a7)
	move.l	4(a7),a0		; return address
	move.b	0(A5,D2),$81-$6A(a0)	; modifies BRA
	move.l	(a7)+,A0
	addq.l	#2,(a7)
	bsr	_flushcache		; cache flush: avoids weird SMC effect
	rts

wait_blit_movem_d0a0
	movem.l	(a7)+,d0/a0	; original
	bsr	wait_blit
	rts
wait_blit_movem_d2d7_a2a6
	movem.l	(a7)+,d2-d7/a2-a6	; original
	bsr	wait_blit
	rts
	
wait_blit_dma
	bsr	wait_blit
	MOVE	#$0400,$dff096		;stop blthog
	RTS

dbf_d0
	bra	emulate_dbf

dbf_d2
	movem.l	d0,-(a7)
	move.l	d2,d0
	bsr	emulate_dbf
	movem.l	(a7)+,d0
	rts

dbf_d6
	movem.l	d0,-(a7)
	move.l	d6,d0
	bsr	emulate_dbf
	movem.l	(a7)+,d0
	rts


wait_blit
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
	rts

; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
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
	add.l	d7,d7
	add.l	d7,d7
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
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================


; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_beamdelay_calibration
	move.l	#10,d0	; 10 loops
	moveq	#0,d1
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	addq.l	#1,d1
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	lea	nb_ticks(pc),a0
	move.l	d1,(a0)
	rts

nb_ticks:
	dc.l	0

_beamdelay_active
	move.l  d1,-(a7)
	divu	#10,d0
.bd_loop0
	move.l	nb_ticks(pc),d1
.bd_loop1
	tst.b	$0
	subq.l	#1,d1
	bne.b	.bd_loop1
	dbf	d0,.bd_loop0
	move.l	(a7)+,d1
	rts

; < D0: value of D0 in line
; .x: DBF D0,x
emulate_dbf
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bra	_beamdelay
