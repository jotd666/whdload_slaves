;*---------------------------------------------------------------------------
;  :Program.	ThePatricianHD.asm
;  :Contents.	Slave for "ThePatrician"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ThePatricianHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Patrician.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $50000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 32000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM


slv_name		dc.b	"The Patrician / Der Patrizier",0
slv_copy		dc.b	"1992-1993 Ascon",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
			dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program_uk:
	dc.b	"Patrician",0
program_de:
	dc.b	"Patrizier",0
_args		dc.b	10
_args_end
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	$A,$D,0

	EVEN

program_name
	dc.l	0
program_patch
	dc.l	0

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

		bsr	detect_version

		move.l	program_name(pc),a0
		lea	patch_main(pc),a5
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

detect_version
		lea	program_uk(pc),a0
		move.l	a0,d1
		move.l	a0,a3
		move.l	#ACCESS_READ,d2
		jsr	_LVOLock(a6)
		move.l	d0,d1
		beq.b	.german
		jsr	_LVOUnLock(a6)
		bra.b	.out
.german
		lea	program_de(pc),a0
		move.l	a0,a3
		move.l	#ACCESS_READ,d2
		jsr	_LVOLock(a6)
		move.l	d0,d1
		beq.b	.notfound
		jsr	_LVOUnLock(a6)
.out
		lea	program_name(pc),a1
		move.l	a3,(a1)
		move.l	a3,a0
		jsr	resload_GetFileSize(a2)
		lea	pl_main_uk_1(pc),a3
		cmp.l	#229528,d0		; uk
		beq.b	.found
		lea	pl_main_de_1(pc),a3
		cmp.l	#229856,d0		; de v1
		beq.b	.found
		lea	pl_main_de_2(pc),a3
		cmp.l	#230596,d0		; de v2
		beq.b	.found
		lea	pl_main_de_4(pc),a3
		cmp.l	#230720,d0		; de v2
		beq.b	.found
		lea	pl_main_fr_1(pc),a3
		cmp.l	#232200,d0		; de v2
		beq.b	.found
		lea	pl_main_de_3(pc),a3
		cmp.l	#229844,d0
		beq.b	.found

		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.found
		lea	program_patch(pc),a1
		move.l	a3,(a1)
		rts
.notfound
		pea	.exenotfound(pc)
		pea	TDREASON_FAILMSG
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)
.exenotfound
	dc.b	"Neither 'Patrician' or 'Patrizier' files have been found",0
	even

; < d7: seglist (APTR)

patch_main
	move.l	d7,a1
	add.l	#4,a1

	move.l	program_patch(pc),a0
	jsr	resload_Patch(a2)

	rts

pl_main_fr_1
	PL_START

	PL_PS	$03E7E,fix_open_failed_0
	PL_PS	$03DFC,fix_open_failed_1
	PL_PS	$1ECBE,fix_open_failed_2
	PL_PS	$1EDB2,fix_open_failed_3
	PL_PS	$1EE16,fix_open_failed_4

	PL_PS	$1D5F0,fix_bra_smc
	PL_PS	$1D962,fix_bra_smc
	PL_PS	$1DD70,fix_bra_smc

	PL_PS	$278,fix_copperlist_1
	PL_PS	$ACE,fix_protection

	PL_PS	$1E97E,fix_dbf_d5
	PL_PS	$1EA04,fix_dbf_d5

	PL_END


pl_main_uk_1
	PL_START

	PL_PS	$03DFC,fix_open_failed_1
	PL_PS	$03E7E,fix_open_failed_0
	PL_PS	$1ECBE,fix_open_failed_2
	PL_PS	$1EDB2,fix_open_failed_3
	PL_PS	$1EE16,fix_open_failed_4

	PL_PS	$1D2BC,fix_bra_smc
	PL_PS	$1D62E,fix_bra_smc
	PL_PS	$1DA3C,fix_bra_smc

	PL_PS	$278,fix_copperlist_1
	PL_PS	$ACE,fix_protection

	PL_PS	$1E64A,fix_dbf_d5
	PL_PS	$1E6D0,fix_dbf_d5

;;	PL_PS	$1F3D0,patch_tfmx
	PL_END

pl_main_de_1
	PL_START

	PL_PS	$03C78,fix_open_failed_1
	PL_PS	$03D02,fix_open_failed_0
	PL_PS	$1EB9A,fix_open_failed_2
	PL_PS	$1EC8E,fix_open_failed_3
	PL_PS	$1ECFA,fix_open_failed_4

	PL_PS	$1D2E0,fix_bra_smc
	PL_PS	$1D652,fix_bra_smc
	PL_PS	$1DA60,fix_bra_smc

	PL_PS	$25A,fix_copperlist_1
	PL_PS	$A8E,fix_protection

	PL_PS	$1E66E,fix_dbf_d5
	PL_PS	$1E6F4,fix_dbf_d5

	PL_END


pl_main_de_2
	PL_START
	PL_PS	$03D4A,fix_open_failed_1
	PL_PS	$03DCC,fix_open_failed_0
	PL_PS	$1EDD0,fix_open_failed_2
	PL_PS	$1EEC4,fix_open_failed_3
	PL_PS	$1EF28,fix_open_failed_4

	PL_PS	$1D3CE,fix_bra_smc
	PL_PS	$1D740,fix_bra_smc
	PL_PS	$1DB4E,fix_bra_smc

	PL_PS	$278,fix_copperlist_1
	PL_PS	$AD2,fix_protection

	PL_PS	$1E75C,fix_dbf_d5
	PL_PS	$1E7E2,fix_dbf_d5

	PL_END

pl_main_de_3
	PL_START
	PL_PS	$03C78,fix_open_failed_1
	PL_PS	$03D02,fix_open_failed_0
	PL_PS	$1EB94,fix_open_failed_2
	PL_PS	$1EC88,fix_open_failed_3
	PL_PS	$1ECF4,fix_open_failed_4

	PL_PS	$1D2DA,fix_bra_smc
	PL_PS	$1D64C,fix_bra_smc
	PL_PS	$1DA5A,fix_bra_smc

	PL_PS	$25A,fix_copperlist_1
	PL_PS	$A8E,fix_protection

	PL_PS	$1E668,fix_dbf_d5
	PL_PS	$1E6EE,fix_dbf_d5

	PL_END

pl_main_de_4
	PL_START
	PL_PS	$03D48,fix_open_failed_1
	PL_PS	$03DC8,fix_open_failed_0
	PL_PS	$1ED7E,fix_open_failed_2
	PL_PS	$1EE72,fix_open_failed_3
	PL_PS	$1EED6,fix_open_failed_4

	PL_PS	$1D3C4,fix_bra_smc
	PL_PS	$1D736,fix_bra_smc
	PL_PS	$1DB44,fix_bra_smc

	PL_PS	$278,fix_copperlist_1
	PL_PS	$AD2,fix_protection

	PL_PS	$1E752,fix_dbf_d5
	PL_PS	$1E7D8,fix_dbf_d5

	PL_END


fix_open_failed_0
	move.l	#$000FFFFF,d3
	tst.l	d0
	bne.b	.ok
	add.l	#$26,(a7)
.ok
	rts

fix_open_failed_1
	move.l	#$000FFFFF,d3
	tst.l	d0
	bne.b	.ok
	moveq	#1,d0
	ILLEGAL
.ok
	rts

fix_open_failed_2
	moveq.l	#$4,d3
	tst.l	d0
	bne.b	.ok
	moveq	#2,d0
	ILLEGAL
.ok
	rts

fix_open_failed_3
	move.l	#$000FFFFF,d3
	tst.l	d0
	bne.b	.ok
	moveq	#3,d0
	ILLEGAL
.ok
	rts

fix_open_failed_4
	move.l	#$000FFFFF,d3
	tst.l	d0
	bne.b	.ok
	moveq	#4,d0
	ILLEGAL
.ok
	rts

fix_bra_smc
	bsr	_flushcache	; fixes SMC issues on 68060
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	rts

fix_dbf_d5
	move.l	#$3E8/$28,d5
; < d5: numbers of vertical positions to wait
.bd_loop1
	move.w  d5,-(a7)
        move.b	$dff006,d5	; VPOS
.bd_loop2
	cmp.b	$dff006,d5
	beq.s	.bd_loop2
	move.w	(a7)+,d5
	dbf	d5,.bd_loop1
	addq.l	#4,(a7)
	rts

fix_copperlist_1
	move.l	(a7),a0
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	-22(a0),a0	; copperlist start
	move.l	(a0),a1
	lea	pl_copperlist_1(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	
	MOVE.W	#$83F0,$DFF096	; start copper DMA
	add.l	#2,(a7)
	rts

; fixes SNOOP errors

pl_copperlist_1
	PL_START
	PL_W	$1DA-$CC,$5300		; colorburst
	PL_L	$544-$42C,$0044FFFF
	PL_L	$548-$42C,$0046FFFF
	PL_L	$54C-$42C,$FFFFFFFE	; end of copperlist
	PL_END

fix_protection
.copy
	move.b	(a0)+,(a1)+
	bpl.b	.copy

	add.l	#12,(a7)
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
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
