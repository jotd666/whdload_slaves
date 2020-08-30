;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;DEBUG

	IFD BARFLY
	OUTPUT	"Dune.Slave"
	IFND	DEBUG
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


	IFD	DEBUG
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 2
WPDRIVES	= %1111

BLACKSCREEN
;
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
;STACKSIZE = 6000
	IFD	FLOPPY_VERSION
CBDOSLOADSEG
DISKSONBOOT
TRDCHANGEDISK
	ELSE
BOOTDOS
HDINIT
HD_Cyls = 10000		; game believes it runs from HD
	ENDC
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_NoKbd|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick13.s

;============================================================================

	IFD	BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC


DECL_VERSION:MACRO
	dc.b	"3.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name		dc.b	"Dune"
		IFD	DEBUG
		dc.b	" (DEBUG MODE)"
		ENDC
		dc.b	0
slv_copy		dc.b	"1992 Cryo",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir
	IFND	FLOPPY_VERSION
	dc.b	"data"
	ENDC
	dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION

	dc.b	0

	EVEN

	IFD	CBDOSLOADSEG
; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	
	addq.l	#4,d1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#'d',1(A0)
	bne.b	.skip
	cmp.b	#'u',2(A0)
	bne.b	.skip

	bsr	install_vectors

	move.l	d1,a1
	bsr	get_version
	move.l	_resload(pc),a2
	movem.l	d0-d1/a0-a1,-(a7)
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a1
.skip
	rts
	ENDC
	
CHECK_VER:MACRO
	cmp.l	#$22402C79,$\1(a1)
	beq.b	.\2
	ENDM

VERSION_PL:MACRO
.\1
	lea	pl_\1(pc),a0
	bra	.out
	ENDM
	
install_vectors:
	pea	fix_smc_xxx(pc)
	move.l	(a7)+,$B4.W
	pea	fix_smc_move(pc)
	move.l	(a7)+,$B8.W
	pea	fix_smc_jsr(pc)
	move.l	(a7)+,$BC.W
	
	patch	$100,emulate_dbf_d0
	patch	$106,emulate_dbf_d2
	rts
	
get_version:
	movem.l	d0-d1/a1,-(a7)
	add.l	#$10000,a1

	CHECK_VER	16E8,french
	CHECK_VER	16F4,italian
	CHECK_VER	16F8,english
	CHECK_VER	170a,other_english
	
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	VERSION_PL	french
	VERSION_PL	italian
	VERSION_PL	english
	VERSION_PL	other_english


.out
	movem.l	(a7)+,d0-d1/a1
	rts
.progname
	dc.b	"dune",0
	even

	; a "new" version

pl_other_english
	PL_START
	PL_PS	$0903a,fix_intro_af
	PL_P	$1170a,quit
	PL_B	$129c2,$60	; protection
	PL_B	$11cde,$60	; protection

	; empty dbf loops

	PL_L	$12b3a,$4EB80106
	PL_L	$12f5a,$4EB80100
	PL_L	$12f76,$4EB80100

	; SMC (easy)

	PL_W	$10f5e,$4E4E	; move.w	#x,d0
	PL_W	$10fd4,$4E4F	; JSR	$x
	PL_W	$10740,$4E4F	; JSR	$x

	; SMC (tough)

	PL_W	$13bca,$4E4D
	PL_W	$13bd4,$4E4D
	PL_W	$13be2,$4E4D
	PL_W	$13bf0,$4E4D
	PL_W	$13bfe,$4E4D

	IFD	FLOPPY_VERSION

	PL_PS	$125e6,swap_disks
	ENDC
	PL_END

	; IPF 2393
pl_french
	PL_START
	PL_PS	$902E,fix_intro_af
	PL_P	$116E8,quit
	PL_B	$12914,$60	; protection
	PL_B	$11C34,$60

	; empty dbf loops

	PL_L	$12A8C,$4EB80106
	PL_L	$12EAC,$4EB80100
	PL_L	$12EC8,$4EB80100

	; SMC (easy)

	PL_W	$10F38,$4E4E	; move.w	#x,d0
	PL_W	$10FAE,$4E4F	; JSR	$x
	PL_W	$1071A,$4E4F	; JSR	$x

	; SMC (tough)

	PL_W	$13B58,$4E4D
	PL_W	$13B62,$4E4D
	PL_W	$13B70,$4E4D
	PL_W	$13B7E,$4E4D
	PL_W	$13B8C,$4E4D

	IFD	FLOPPY_VERSION

	PL_PS	$12538,swap_disks
	ENDC
	PL_END

; also german

pl_english
	PL_START
	PL_B	$12924,$60	; protection
	PL_B	$11C44,$60
	PL_P	$116F8,quit
	PL_PS	$903E,fix_intro_af
	IFD	FLOPPY_VERSION
	PL_PS	$12548,swap_disks
	ENDC
	
	; empty DBFs

	PL_L	$12A9C,$4EB80106
	PL_L	$12EBC,$4EB80100
	PL_L	$12ED8,$4EB80100

	; SMC

	PL_W	$10F48,$4E4E	; move.w	#x,d0
	PL_W	$10FBE,$4E4F	; JSR	$x
	PL_W	$1072A,$4E4F	; JSR	$x

	; SMC (tough)

	PL_W	$13B68,$4E4D
	PL_W	$13B72,$4E4D
	PL_W	$13B80,$4E4D
	PL_W	$13B8E,$4E4D
	PL_W	$13B9C,$4E4D

	PL_END

pl_italian
	PL_START
	PL_PS	$903E,fix_intro_af
	PL_P	$116F4,quit
	IFD	FLOPPY_VERSION
	PL_PS	$1251E,swap_disks
	ENDC
	PL_B	$128FA,$60	; protection
	PL_B	$11C1A,$60

	; empty DBFs

	PL_L	$12A72,$4EB80106
	PL_L	$12E92,$4EB80100
	PL_L	$12EAE,$4EB80100

	; SMC

	PL_W	$10F48,$4E4E
	PL_W	$10FBE,$4E4F
	PL_W	$1072A,$4E4F
	
	; SMC (tough)

	PL_W	$13B2E,$4E4D
	PL_W	$13B38,$4E4D
	PL_W	$13B46,$4E4D
	PL_W	$13B54,$4E4D
	PL_W	$13B62,$4E4D

	PL_END

	IFD	FLOPPY_VERSION

; wait a little bit in both cases, avoids some race condition
; somewhere making the game crash
; not very elegant stuff, but works fine during game!!!
fix_race_condition
	beq.b	.ok	; result from a compare memory (relocated) <=> D5
	moveq	#-1,d5
	bra.b	.cont
.ok
	moveq	#0,d5
.cont
	movem.l	d0,-(a7)

	; just wait a little bit to avoid race condition
	; experimental but fixes it!!!
	move.l	#10,d0
	bsr	_beamdelay
	movem.l	(a7)+,d0

	MOVEM.L	(A7)+,D5/D7
	tst	d5		; so Z is preserved / original code
	RTS
	ENDC
	
;.close_lib:	; french: offset $116E8  uk $116F8
;	dc.l	$22402C79,4,$4EAEFE62
;.afintro:	; french: offset $902E, uk $903E
;	dc.l	$363C0002,$53897200,$10191E19
;
;.swap_disks:	; french: offset $12538, uk $12548
;	dc.l	$9481B43C,$00C865C6


fix_intro_af:
	move.w	#2,D3	; original
	move.l	A1,-(A7)
	tst.l	(A7)+
	beq.b	.avoid
	subq.l	#1,A1
	rts
.avoid:
	moveq	#2,d1
	addq.l	#4,A7	; pops up the stack, skips rest of the code
	rts

fix_smc_xxx
	move.l	d1,d0	; stolen

	movem.l	d2/A0/A1,-(A7)
	move.l	14(A7),A0	; return PC
	move.w	(A0),d2		; instruction to "emulate"
	cmp.w	#$4E71,d2
	beq.b	.nop
	cmp.w	#$4680,d2
	beq.b	.notl

	and.w	#$FF00,d2
	cmp.w	#$7000,d2
	beq.b	.moveqd0

	move.w	(A0),d2		; instruction to "emulate"
	illegal	; i don't remember if reached or not!!
.abcdd0d7
	abcd.b	d0,d7
	bra.b	.nop
.moveqd0
	moveq	#0,d0
	move.b	1(a0),d0
	ext.w	d0
	ext.l	d0
	bra.b	.nop
.notl
	not.l	d0
.nop
	movem.l	(A7)+,d2/A0/A1
	addq.l	#2,2(a7)	; skip "emulated" instruction
	rte
	
fix_smc_move:
	movem.l	A0/A1,-(A7)
	move.l	10(A7),A0	; return PC
	move.w	(A0),d0		; value of the operand, store in D0
	movem.l	(A7)+,A0/A1
	add.l	#2,2(A7)
	rte

fix_smc_jsr:
	; first, recover from the RTE

	movem.l	A0/A1,-(A7)
	move.l	10(A7),A0	; return PC
	lea	.return_address(pc),a1
	move.l	a0,(a1)		; save return address for later on
	lea	.jsr_address(pc),a1
	move.l	(a0),(a1)	; save jsr address for later on
	lea	.recov(pc),a1
	move.l	a1,10(a7)	; change return PC
	movem.l	(A7)+,A0/A1
	rte
.recov
	; now we're in user mode: first push return address
	
	move.l	.return_address(pc),-(a7)
	addq.l	#4,(a7)		; skip JSR operand
	
	; then push JSR operand
	move.l	.jsr_address(pc),-(a7)

	; go
	rts
	
.return_address
	dc.l	0
.jsr_address
	dc.l	0

quit
	PEA	TDREASON_OK
	MOVE.L	_resload(PC),-(A7)
	add.l	#resload_Abort,(a7)
	rts

	IFD	FLOPPY_VERSION

swap_disks:
	movem.l	D0/d1/A0/a1/A6,-(A7)
	move.b	_trd_disk(pc),d0
	cmp.b	#$01,D0
	bne.b	.2
	moveq	#0,d0
	moveq	#3,d1
	bsr	_trd_changedisk
	moveq	#1,d0
	moveq	#4,d1
	bsr	_trd_changedisk
	bra.b	.out
.2
	moveq	#0,d0
	moveq	#1,d1
	bsr	_trd_changedisk
	moveq	#1,d0
	moveq	#2,d1
	bsr	_trd_changedisk
	
.out
	movem.l	(A7)+,D0/d1/A0/a1/A6

	; stolen code
	sub.l	d1,d2
	cmp.b	#$C8,D2
	rts
	ENDC

emulate_dbf_d2:
	move.l	d0,-(a7)
	move.l	d2,d0
	bsr	emulate_dbf_d0
	move.l	(a7)+,d0
	rts

emulate_dbf_d0:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	move.w	#-1,d0
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

	IFD	BOOTDOS

program:
	dc.b	"dune",0
args		dc.b	10
args_end
	dc.b	0
	even
	
_bootdos
		clr.l	$0.W
		bsr	install_vectors
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	lea	program(pc),A0
	jsr	resload_GetFileSize(a2)

	cmp.l	#200000,D0
	bcs.b	.ok

	; happens when installation is interrupted
	; executable is appended to itself
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.ok
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
;		lea	assign(pc),a0
;		sub.l	a1,a1
;		bsr	_dos_assign

	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_main
	move.l	_resload(pc),a2
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	d7,a1
	addq.l	#4,a1
	bsr	get_version
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a1
	rts
;	lea	version(pc),a0
;	move.l	d0,(a0)

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
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
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
	ENDC
	