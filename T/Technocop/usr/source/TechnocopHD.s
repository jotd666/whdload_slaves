;*---------------------------------------------------------------------------
;  :Program.	Technocop.asm
;  :Contents.	Slave for "Technocop"
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
	OUTPUT	"Technocop.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0000
NUMDRIVES	= 1
WPDRIVES	= %1111

;BLACKSCREEN
;DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s



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
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

_assign
	dc.b	"Technocop",0

slv_name		dc.b	"TechnoCop",0
slv_copy		dc.b	"1988 US-Gold/Imagexcel",0
slv_info		dc.b	"adapted/fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to Carlo/Captain HIT for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program_v1:
	dc.b	"Technocop",0
_program_v2:
	dc.b	"car.iff",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment


_bootdos
	move.l	_resload(pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase


	;load exe
		lea	_program_v1(pc),a0
		jsr	resload_GetFileSize(a2)
		cmp.l	#112116,d0
		beq.b	.version1
		lea	_program_v2(pc),a0
		jsr	resload_GetFileSize(a2)
		cmp.l	#109192,d0
		beq.b	.version2
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.version2
		lea	_program_v2(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

		move.l	d7,a3
		add.l	a3,a3
		add.l	a3,a3
		move.l	a3,a4
		add.l	#$10000,a4
		bsr	_autopatch_dfe000

		move.l	a3,a1
		lea	_pl_dfe000_v2(pc),a0
		jsr	resload_Patch(a2)
		bra	.runit
.version1:
	;assigns
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		lea	_program_v1(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

		move.l	d7,a2
		add.l	a2,a2
		add.l	a2,a2
		addq.l	#4,a2
		move.l	a2,d1
		add.l	#$2D888-$178C8,a2
		pea	_decryption(pc)
		bsr	_save_and_patch
		addq.l	#4,A7

		bsr	_fix1

	;call
.runit
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

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

.end		moveq	#0,d0
		rts


_decryption:
.loop
	move.w	(a0)+,d0
	eor.w	d0,(a1)+
	subq.l	#1,d1
	cmp.w	#$283,d1
	beq.b	.notzone
	cmp.w	#$282,d1
	beq.b	.restore
	cmp.w	#$FFFF,d1
	bne.b	.loop
	
	addq.l	#2,(A7)		; skip rest of DBF

	move.l	A2,-(A7)
	move.l	4(A7),A2	; return address
	add.l	#$16E,a2
	pea	_decryption_2(pc)
	bsr	_save_and_patch
	addq.l	#4,A7
	move.l	(A7)+,A2

	bsr	_flushcache
	rts


.notzone
	add.l	#$50C,(A7)	; do some special stuff
	rts

.restore
	; restore original code (or else there will be cyclic errors)

	move.l	A2,-(A7)
	move.l	4(A7),A2
	bsr	_restore_org
	move.l	(A7)+,A2
	bra.b	.loop

_decryption_2:
	move.l	A2,-(A7)
	move.l	4(A7),A2
	bsr	_restore_org
	move.l	(A7)+,A2

.lab0000
	MOVE	(A0)+,D1
	MOVEQ	#15,D4
.lab0001:
	MOVEQ	#0,D2
	LSL	#1,D1
	ROXR	#1,D2
	EOR	D2,D0
	LSL	#1,D0
	BCC.S	.lab0002
	MOVE.L	26732(A1),D3
	EOR	D3,D0
.lab0002:
	DBF	D4,.lab0001
	DBF	D5,.lab0000
	MOVE	#$016A,D2
.lab0003:
	MOVE	(A0)+,D1
	ADD	D0,D1
	EOR	D1,(A0)
	DBF	D2,.lab0003
	add.l	#$2C,(A7)

	move.l	A0,-(A7)
	move.l	4(A7),A0	; return address
	sub.l	#$16168,A0	; start of the program
	bsr	_fix2		; fix differences before/after disk stuff
	bsr	_patchmain	; patch our stuff
	move.l	(A7)+,A0

	add.l	#$26C,(A7)	; skip all the disk/decrypting/checksum stuff

	bsr	_flushcache
	RTS

; < A0: program start ($178C8)

_patchmain
	movem.l	D0-D7/A1-A6,-(A7)
	move.l	A0,A3

	move.l	a3,a1
	lea	_pl_dfe000_v1(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	; now, harder, scan the code till we find some interesting patterns

	move.l	A3,A4
	add.l	#$10000,A4
	
	bsr	_autopatch_dfe000

	movem.l	(A7)+,D0-D7/A1-A6
	rts


_pl_dfe000_v1:
	PL_START
	PL_W	$18342-$178C8,$4
	PL_W	$18A16-$178C8,$4
	PL_W	$1932C-$178C8,$C
	PL_P	$1831E-$178C8,_blitwait
	PL_P	$25388-$178C8,_blitwait
	PL_END


_pl_dfe000_v2:
	PL_START
	PL_W	$19FFE-$18EAC,$4
	PL_W	$1992A-$18EAC,$4
	PL_W	$1A928-$18EAC,$C
	PL_P	$26984-$18EAC,_blitwait
	PL_P	$19906-$18EAC,_blitwait
	PL_END

; < A3: start
; < A4: end

_autopatch_dfe000
	movem.l	D0-D7/A1-A6,-(A7)
.loop
	cmp.l	a3,a4
	beq.b	.out
	move.w	(a3)+,d0

	cmp.w	#$3D7C,d0	; move.w  #xx,($xx,a6)
	bne.b	.nomovewi

	move.w	2(a3),d1
	bsr	.check_f01xx
	bne.b	.loop

	; operand OK, patch

	add.w	#$1000,2(a3)
	bra.b	.loop
.nomovewi
	cmp.w	#$2D79,d0	; move.l  xx,($xx,a6)
	bne.b	.nomovel

	move.w	4(a3),d1
	bsr	.check_f01xx
	bne.b	.loop

	; operand OK, patch

	add.w	#$1000,4(a3)
	bra.b	.loop

.nomovel

	move.w	(a3),d1
	bsr	.check_f01xx
	bne.b	.loop

	; operand is $F[01]xx, now check instruction

	move.w	-2(a3),d1
	cmp.w	#$426E,d1
	beq.b	.clr		; clr  ($xx,a6)

	and.w	#$FFF8,d1
	cmp.w	#$3D40,d1
	beq.b	.wdx		; move.w Dx,($xx,a6)
	cmp.w	#$2D48,d1
	beq.b	.lax		; move.l Ax,($xx,a6)
	bra.b	.loop

.clr
.wdx
.lax
	add.w	#$1000,(a3)	
	
	bra.b	.loop

.out
	movem.l	(A7)+,D0-D7/A1-A6
	rts

; < D1: operand
;   D0-D1: scratch
; > CCR: EQ if OK

.check_f01xx:
	move.w	d1,d0
	and.w	#$0E00,d1
	bne.b	.fail
	move.l	d0,d1
	and.w	#$F000,d1
	cmp.w	#$F000,d1
;	bne.b	.fail
.fail
	rts

_blitwait
	TST.B	dmaconr+_custom
	BTST	#6,dmaconr+_custom
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+_custom
	BNE.S	.wait
	TST.B	dmaconr+_custom
.end
	rts

; < A2: return address

_save_and_patch:
	move.l	A3,-(A7)
	lea	_last_saved(pc),a3
	move.l	(A2),(A3)+
	move.w	4(A2),(A3)
	move.l	(A7)+,A3

	move.w	#$4EB9,(A2)+
	move.l	4(A7),(A2)
	bsr	_flushcache
	rts

; < A2: return address

_restore_org:
	nop
	subq.l	#6,A2
	move.l	_last_saved(pc),(a2)+
	move.w	_last_saved+4(pc),(a2)+
	bsr	_flushcache
	rts

_last_saved:
	dc.l	0,0

;============================================================================


;============================================================================

	include	"binfixes.s"
	END
