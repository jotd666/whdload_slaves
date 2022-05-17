;*---------------------------------------------------------------------------
;  :Program.	SyndicateHD.asm
;  :Contents.	Slave for "Syndicate"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SyndicateHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"SyndicateECS.slave"
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
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000	
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
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
	IFD	CHIP_ONLY
CACHECHIPDATA		; test
	ELSE
CACHE
	ENDC
	
SEGTRACKER

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

;============================================================================

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
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name	dc.b	"Shuttle"
		IFD	CHIP_ONLY
		dc.b	" (CHIP/debug mode)"
		ENDC
		
			dc.b	0
slv_copy	dc.b	"1991 Vektor Grafix/Virgin",0
slv_info	dc.b	"adapted by Codetapper/Action! & JOTD",10,10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	
slv_config:
	dc.b	0
	

_program:
	dc.b	"shuttle",0
_args	
	dc.b	"",10
_args_end
	dc.b	0
_noargs
	dc.b	10
_noargs_end
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	pea	smc_trap_15(pc)
	move.l	(a7)+,$BC.W
	pea	smc_trap_14(pc)
	move.l	(a7)+,$80.W
	pea	smc_trap_01(pc)
	move.l	(a7)+,$84.W
	
	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$20000-$1BE78,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6

        ENDC
	
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

check_version
	lea	_program(pc),a0
	jsr	resload_GetFileSize(a2)
	lea		pl_main(pc),a0
	cmp.l	#342656,d0
	beq.b	.ok
	lea		pl_empty(pc),a0
	rts
.ok
	rts
wrongver
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
; < d7: seglist (APTR)

patch_main
	move.l	_resload(pc),a2
	bsr	check_version
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)

	rts

	
pl_empty
	PL_START
	
	PL_END

pl_main:
	PL_START
		

	; game believes it's running from HD
	PL_B	$0b360,$60
	
	; disable fastmem data block,
	; for some reason, allowing
	; to run with fast memory makes the game trigger
	; some sanity checks. Not happening if the fastmem
	; block is allocated in chip, or if the game is running
	; without whdload on WinUAE kick 3.9, but failing on a real
	; A1200 probably because fastmem is not located at the
	; same address so not really a whdload issue...
	; that's frustrating.
	; probably game internal memory allocation is failing...
	
	PL_L	$0b450,$70004E71
	
	; self-modifying code fixes
	PL_W	$0c92e,$4E4F
	PL_W	$02246,$4E40
	PL_W	$0226a,$4E40
	PL_W	$0235a,$4E40
	PL_W	$023aa,$4E40
	PL_W	$023f0,$4E40
	PL_W	$02486,$4E40
	PL_W	$024d6,$4E40
	PL_W	$0252a,$4E40
	PL_PS	$0c78a,fix_smc_1
	PL_PS	$0c7c4,fix_smc_2
	PL_PS	$0c826,fix_smc_3
	PL_PS	$0c88e,fix_smc_3
	PL_PS	$0d4ee,fix_smc_4
	PL_PS	$0d58a,fix_smc_5
	PL_PS	$0d642,fix_smc_6
	PL_PS	$0d718,fix_smc_4
	PL_PS	$0d7ca,fix_smc_5
	PL_PS	$0d8e8,fix_smc_6
	PL_PS	$0da32,fix_smc_5
	PL_PSS	$0ddf4,fix_smc_7,2

	
	;PL_PS	$0aff8,check_null
	; sanity checks that trigger only with fastmem...
	; removing some sanity checks allow to see
	; part of the demo then it crashes...
	;PL_NOP	$0afd8,2
	;PL_NOP	$AFFC,2
	;PL_R	$051ea
	
	; dbf delay for sound
	PL_PSS	$35e1c,soundtracker_loop,2
	
	; intercept music player load
	PL_W	$3f79a,$4E41
	
	PL_END

pl_music
	PL_START
	PL_P	$276,soundtracker_loop	; longer delay for dma sound
	PL_PSS	$3b0,dma_wait_1,2
	PL_PSS	$3da,dma_wait_1,2
	PL_END
	

dma_wait_1
	MOVE.W	26(A4),_custom+dmacon
soundtracker_loop
	move.w  d0,-(a7)
	move.w	#5,d0
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



fix_smc_1
	ROL.W	D2,D0			;0c78a: e578
	MOVE.W	D0,D1			;0c78c: 3200
	NOT.W	D1			;0c78e: 4641
	bra	_flushcache
fix_smc_2
	ROR.L	D2,D0			;0c7c4: e4b8
	MOVE.L	D0,D1			;0c7c6: 2200
	NOT.L	D1			;0c7c8: 4681
	bra	_flushcache
fix_smc_3
	OR.W	D4,D0			;0c826: 8044
	MOVE.W	D0,D1			;0c828: 3200
	NOT.W	D1			;0c82a: 4641
	bra	_flushcache
fix_smc_4
	CLR.W	D0			;0d4ee: 4240
	EORI.W	#$000f,D2		;0d4f0: 0a42000f
	bra	_flushcache
fix_smc_5
	NEG.W	D7			;0d58a: 4447
	ADD.W	D7,D7			;0d58c: de47
	ADD.W	D7,D2			;0d58e: d447
	bra	_flushcache
fix_smc_6
	NEG.W	D3			;0d642: 4443
	ADD.W	D3,D3			;0d644: d643
	ADD.W	D3,D2			;0d646: d443
	bra	_flushcache
fix_smc_7
	MOVEA.L	18(A0),A2		;0ddf4: 24680012
	MOVEA.L	22(A0),A3		;0ddf8: 26680016
	bra	_flushcache
	
smc_trap_01
.after_rte
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	a2,a1
	lea		pl_music(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	
	jsr	(a2)
	
	rte
	
smc_trap_15
	subq.w	#1,d5
	bsr	_flushcache
	rte
	
smc_trap_14
	move.l	a0,-(a7)
	lea		.after_rte(pc),a0
	move.l	a0,6(a7)
	move.l	(a7)+,a0
	rte
.after_rte
	bra	_flushcache
	
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
	move.l	a3,-(a7)
	jsr	(_LVOIoErr,a6)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
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

_tag		dc.l	WHDLTAG_CUSTOM1_GET
skip_intro	dc.l	0
		dc.l	0
vbl_counter
	dc.l	0
	END
