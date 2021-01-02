;*---------------------------------------------------------------------------
;  :Program.	wildwestworld.asm
;  :Contents.	Slave for "Wild West World" from Software 2000
;  :Author.	Wepl
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
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"Gunship2000AGA.slave"
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
FASTMEMSIZE	= $100000
NUMDRIVES	= 1
WPDRIVES	= %1111
;DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
INITAGA
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
CBDOSLOADSEG
BOOTDOS
STACKSIZE = 13000
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_dsk1
	dc.b	"gs_dsk1",0
_dsk2
	dc.b	"gs_dsk2",0
_dsk3
	dc.b	"gs_dsk3",0
_dsk4
	dc.b	"gs_dsk4",0
_env
	dc.b	"ENV",0


DECL_VERSION:MACRO
	incbin	"slave_version"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

slv_name		dc.b	"Gunship 2000 AGA",0
slv_copy		dc.b	"1993 Microprose",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Gunship 2000",0
_args		dc.b	10
_args_end
	dc.b	0
	cnop	0,4
_rampath:
	dc.b	"RAM:",0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

	EVEN


;============================================================================

	;initialize kickstart and environment

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	clr.l	0

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	bsr	.strip_colon
	cmp.b	#'g',(A0)
	bne.b	.nomain
	cmp.b	#'s',1(A0)
	bne.b	.nomain
	cmp.b	#'2',2(A0)
	beq.b	.gs2_run
	tst.b	2(a0)
	bne.b	.nomain

	; gs file

	bsr	.patch_gs_segments
	bra.b	.noboot

	; gs2.run file
.gs2_run
	cmp.b	#'.',3(A0)
	bne.b	.nomain
	bsr	.patch_gs2_run_segments
	bra.b	.noboot

.nomain:
	cmp.b	#'G',(A0)
	bne.b	.noboot
	cmp.b	#'u',1(A0)
	bne.b	.noboot
	move.l	d1,d7
	bsr	_patch_exe
.noboot
	rts

.strip_colon
	addq.l	#1,a0
	movem.l	a0,-(a7)
.loop
	move.b	(a0)+,d0
	beq.b	.fail
	cmp.b	#':',d0
	bne.b	.loop
	addq.l	#4,a7
	rts	
.fail
	movem.l	(a7)+,a0
	rts

; file "gs"

.patch_gs_segments:
	move.l	d1,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1

	patch	$D0,crack

	lea	pl_gs(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	rts

; file "gs2.run"

.patch_gs2_run_segments:
	move.l	d1,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1
	lea	pl_gs2_run(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	rts

pl_gs
	PL_START
	PL_L	$4970,$4EB800D0	; crack
	PL_END

pl_gs2_run
	PL_START
	PL_L	$12780,$4E714E71	; remove WaitTOF before LoadView
	PL_PS	$12834,set_copperlist
;;	PL_P	$13E6A,quit
	PL_END

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

set_copperlist
	move.l	#$FFFFFFFE,0.W	; fixes hazard on copjmp2 to 0

	; code below actually not needed, but could be useful to fix
	; some copperlist entries

	movem.l	a0,-(a7)
	move.l	4(a7),a0	; return address
	move.l	2(a0),a0	; copperlist variable
	lea	$dff000,a5
	move.l	(a0),$80(a5)
	tst.w	$88(a5)
	movem.l	(a7)+,a0
	addq.l	#4,a7
	rts

crack
	; d7 contains the code to enter
	; a1 contains the string of the code entered by the user

	cmp.b	#':',(a1)
	beq.b	.notyet

	; wait till the user entered 5 digits (or else it does not work)

	movem.l	a0/d1/d2,-(a7)
	MOVE.L	D7,D1			;00: 2207
	LSR	#1,D1			;02: E249
	MOVEQ	#0,D2			;04: 7400
	MOVE	D1,D2			;06: 3401
	MOVEQ	#0,D1			;08: 7200
	MOVE	D7,D1			;0A: 3207
	ADD.L	D2,D1			; code

	MOVE.L	D1,-4(a5)		; replace code entered by the user

	move.l	a1,a0
	bsr	codetostring

	movem.l	(a7)+,a0/d1/d2

.notyet
	MOVE.L	-4(A5),D0	; code entered by the user
	RTS

codetostring:
	DIVU	#$2710,D1
	ADDI.B	#$30,D1
	MOVE.B	D1,(A0)+
	SWAP	D1
	EXT.L	D1
	DIVU	#$03E8,D1
	ADDI.B	#$30,D1
	MOVE.B	D1,(A0)+
	SWAP	D1
	EXT.L	D1
	DIVU	#$0064,D1
	ADDI.B	#$30,D1
	MOVE.B	D1,(A0)+
	SWAP	D1
	EXT.L	D1
	DIVU	#$000A,D1
	ADDI.B	#$30,D1
	MOVE.B	D1,(A0)+
	SWAP	D1
	ADDI.B	#$30,D1
	MOVE.B	D1,(A0)
	RTS				;124: 4E75

_bootdos	move.l	(_resload),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		lea	_env(pc),a0
		lea	_rampath(pc),a1
		bsr	_dos_assign
	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end
	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1

		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check

		movem.l	d0/d7/a2/a6,-(a7)

		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		addq.l	#4,a1
		jsr	(a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

.end		moveq	#0,d0
		rts


_patch_exe:
	move.l	_resload(pc),a2
	move.l	d7,A1
	add.l	A1,A1
	add.l	A1,A1
	addq.l	#4,A1
	cmp.w	#$2C79,$66C(A1)
	beq.b	.ecs
	cmp.w	#$2C79,$512(A1)
	beq.b	.aga

	; wrong version

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.ecs
	lea	_pl_gs2000_ecs(pc),a0
	bra.b	.patch
.aga
	lea	_pl_gs2000_aga(pc),a0
	bra.b	.patch

.patch
	jsr	resload_Patch(a2)
	rts

_pl_gs2000_ecs:
	PL_START
	PL_P	$66C,move1d0rts
	PL_P	$78E,move1d0rts
	PL_END
_pl_gs2000_aga:
	PL_START
	PL_S	$122,$3E-$22		; skip test for "Install Gunship 2000"
	PL_S	$16C,$F4-$6C
;	PL_P	$512,assign_it
;	PL_P	$512,move1d0rts
;	PL_P	$634,move1d0rts
	PL_END

assign_it:
	move.l	a5,a0
	sub.l	a1,a1
move1d0rts
	moveq.l	#1,D0
	rts

;============================================================================

	END
