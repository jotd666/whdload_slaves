;*---------------------------------------------------------------------------
;  :Program.	CombatAirPatrol.asm
;  :Contents.	Slave for "CombatAirPatrol"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
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
	OUTPUT	"CombatAirPatrol.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD	CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = 0
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;DOSASSIGN

;INITAGA
BOOTDOS
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 7000
CACHE
SEGTRACKER

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

;============================================================================

	include		"whdload/kick13.s"
	
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
slv_name		dc.b	"Combat Air Patrol"
        IFD CHIP_ONLY
        dc.b    "(DEBUG/CHIP mode)"
        ENDC
        
        dc.b    0
slv_copy		dc.b	"1993 Psygnosis",0
slv_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

slv_CurrentDir:
	dc.b	"data",0
slv_config:
        dc.b    "C1:X:Skip introduction:0;"
		dc.b	0
	even
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

_program:
	dc.b	"cap.amg",0
_intro:
	dc.b	"capintro",0
_introdir
	dc.b	"intro",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		move.l	skip_intro(pc),d0
		bne.b	.skipintro

	;lock intro directory

		lea	_introdir(pc),a1
		move.l	a1,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
		beq	_end3

		jsr	(_LVOCurrentDir,a6)
		move.l	d0,-(a7)

	;load exe
		lea	_intro(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			; file not found

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

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)
		
		move.l	(a7)+,d1
		jsr	(_LVOCurrentDir,a6)
.skipintro
	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			; file not found

		bsr	_patch_exe

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

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

_end
		pea	_program(pc)
        jsr	(_LVOIoErr,a6)
        move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_end2
		pea	_intro(pc)
        jsr	(_LVOIoErr,a6)
        move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
_end3
		pea	_introdir(pc)
        jsr	(_LVOIoErr,a6)
        move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_patch_exe
    move.l  d7,a1
    move.l  _resload(pc),a2
    lea pl_main(pc),a0
    jsr (resload_PatchSeg,a2)
    
	move.l	attnflags(pc),d0
	btst	#AFB_68020,d0
	beq	.68k

    move.l  d7,a1
    lea pl_main_020(pc),a0
    jsr (resload_PatchSeg,a2)

	lea	_trapjmp(pc),A0
	move.l	A0,$B8.W
 
.68k
    rts

pl_main_020:
    PL_START
    PL_W    $245ba,$4E4E
    PL_W    $251ac,$4E4E
    
    PL_PS   $35d94,flush_smc
    PL_END

flush_smc
    bsr _flushcache
    ; original code, changed a bit
	CLR.W	D0			;35d94: 4240
	MOVE.B	(A0)+,D0		;35d96: 1018
	bne.S	.return		;35d98: 6738
    addq.l  #4,a7
.return    
    rts
    
; patches a double blitwait pattern like
;    LAB_0840:
;    	BTST	#6,DMACONR		;115c4: 0839000600dff002
;    	BNE.S	LAB_0840		;115cc: 66f6
;    LAB_0841:
;    	BTST	#6,DMACONR		;115ce: 0839000600dff002
;    	BNE.S	LAB_0841		;115d6: 66f6
;
; the problem with that pattern is that the blitwait is incorrect
; for some machines (which probably explains that it's repeated)
; and thus the double blitwait has to be added, but then it's inefficient
; on machines that don't have the blitwait bug
;
; patching those 2 loops makes the code faster
 
PL_BLT:MACRO
    PL_PS   \1,_waitblit
    PL_S    \1+6,$d8-$ca
    ENDM
    
pl_main:
    PL_START
    ; skip debug crap checking 'eddy' in $C
    PL_S    $37012,$2a-$12
    ; skip cacr tampering
    PL_S    $2b186,$c2-$86
    ; no PAL force or fmode zero
    PL_S    $2b13e,$4a-$3e
    PL_S    $2b172,$4a-$3e
    ; blitter waits
    PL_PS   $1d768,_waitblit1
    
    PL_BLT  $11588
    PL_BLT  $11592
    PL_BLT  $1159c
    PL_BLT  $115a6
    PL_BLT  $115b0
    PL_BLT  $115ba
    PL_BLT  $115c4
    PL_BLT  $11880
    PL_BLT  $118e6
    PL_BLT  $174e4
    PL_BLT  $1752c
    PL_BLT  $1d6d8
    PL_BLT  $2a51a
    PL_BLT  $2a5c2
    PL_BLT  $2a5f6
    PL_BLT  $2a626
    PL_BLT  $2a656
    PL_BLT  $2a68a
    PL_BLT  $2a6c0
    PL_BLT  $2a6f2
    PL_BLT  $2a724
    PL_BLT  $2a75e
    PL_BLT  $2a794
    PL_BLT  $2a7c6
    PL_BLT  $2a7fe
    PL_BLT  $2a832
    PL_BLT  $2a868
    PL_BLT  $2a8a0
    PL_BLT  $2a8d2
    PL_BLT  $2a902
    PL_BLT  $2a938
    PL_BLT  $2a968
    PL_BLT  $2a998
    PL_BLT  $2a9cc
    PL_BLT  $2aa02
    PL_BLT  $2aa34
    PL_BLT  $2aa68
    PL_BLT  $2aa9e
    PL_BLT  $2aad0
    PL_BLT  $2ab0a
    PL_BLT  $2ab40
    PL_BLT  $2ab78
    PL_BLT  $2abac
    PL_BLT  $2abe4
    PL_BLT  $2ac16
    PL_BLT  $2ac4a
    PL_BLT  $2ac80
    PL_BLT  $2acb4
    PL_BLT  $2acea
    PL_BLT  $2ad24
    PL_BLT  $2ad5c
    PL_BLT  $2ad90
    PL_BLT  $2adc8
    PL_BLT  $2cdc4
    PL_BLT  $2ce0e
    PL_BLT  $2ce74
    PL_BLT  $2cece
    PL_BLT  $2cf0e
    PL_BLT  $2cf80
    PL_BLT  $2cfac
    PL_BLT  $2cffe
    PL_BLT  $2d02a
    PL_BLT  $2d070
    PL_BLT  $335b2
    PL_BLT  $33608
    PL_BLT  $3365a
    PL_BLT  $3460c
    PL_BLT  $3466c
    PL_BLT  $346a2
    PL_BLT  $3470e
    PL_BLT  $3473a
    PL_BLT  $347e6
    PL_BLT  $34850
    PL_BLT  $348c0
    PL_BLT  $3493c
    PL_BLT  $34980
    PL_BLT  $349c4
    PL_BLT  $34a0e
    PL_BLT  $34a52
    PL_BLT  $34a9c
    PL_BLT  $34ae0
    PL_BLT  $34b34
    PL_BLT  $34b76
    PL_BLT  $34bbc
    PL_BLT  $34be8
    PL_BLT  $34c3e
    PL_BLT  $34c68
    PL_BLT  $34c92
    PL_BLT  $34cd6
    PL_BLT  $34d28
    PL_BLT  $34d54
    PL_BLT  $34daa
    PL_BLT  $34dd4
    PL_BLT  $34dfe
    PL_BLT  $3502a
    PL_BLT  $3507e
    PL_BLT  $35136
    PL_BLT  $351ba
    PL_BLT  $351f6
    PL_BLT  $3524c
    PL_BLT  $35292
    PL_BLT  $352fc
    PL_BLT  $3532a
    PL_BLT  $35382
    PL_BLT  $35480
    PL_BLT  $354f6
    PL_BLT  $35520
    PL_BLT  $3556c
    PL_BLT  $355e0
    PL_BLT  $3560a
    PL_BLT  $35652
    PL_BLT  $356c2
    PL_BLT  $356ec
    PL_BLT  $35734
    PL_BLT  $35798
    PL_BLT  $357d6
    PL_BLT  $35838
    PL_BLT  $3587e
    PL_BLT  $358e4
    PL_BLT  $35996
    PL_BLT  $359f0
    PL_BLT  $35a1e
    PL_BLT  $35a76
    PL_BLT  $35a9c
    PL_BLT  $35afa
    PL_BLT  $372ae

    
    ; protection
    PL_L    $16b12,$10C14E71
    ; disk banging
    PL_R    $37724
    ; keyboard
    PL_PSS   $2b368,_kbint,8
    ; fix that smc on 68k too because it's just stupid
    PL_NOP  $36080,6            ; don't change operand
    PL_L    $36098,$C2434E71    ; and.w d3,d1 because d3 is the value!
    
    PL_END

_andd1
	move.l	A0,-(a7)
	move.l	6(A7),A0
	and.w	(A0),D1
	move.l	(A7)+,A0
	addq.l	#2,2(A7)
	rte

_waitblit1:
	bsr	_waitblit
	move.w	#$1F0,($40,A0)
	rts


_waitblit:
	BTST	#6,dmaconr+_custom
.wait
	BTST	#6,dmaconr+_custom
	BNE.S	.wait
	rts

; corrects SMC $4EF9(address changing all the time)
; fixes color flashes

_trapjmp
	move.l	A0,-(A7)
	move.l	6(A7),A0	; return address
	move.l	(A0),6(A7)	; RTE -> JMP address
	move.l	(A7)+,A0
	rte

_kbint:
	move.b	$BFEC01,D0
	move.l	D0,-(A7)
	ror.b	#1,D0
	not.b	D0
	cmp.b	_keyexit(pc),D0
	beq	_quit
.skip
	bset	#6,$BFEE01
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	move.l	(A7)+,D0
	rts


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

_tag		dc.l	WHDLTAG_CUSTOM1_GET
skip_intro	dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
attnflags
	dc.l	0
		dc.l	0

	END
