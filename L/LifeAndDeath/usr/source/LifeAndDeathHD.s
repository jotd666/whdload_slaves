;*---------------------------------------------------------------------------
;  :Program.	LifeAndDeathHD.asm
;  :Contents.	Slave for "LifeAndDeath"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: LifeAndDeathHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"LifeAndDeath.slave"
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
FASTMEMSIZE  = 0
HRTMON
	ELSE
CHIPMEMSIZE	= $C0000
FASTMEMSIZE	= $40000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
STACKSIZE = 6000
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_NoKbd
slv_keyexit	= $5D	; num '*'

;============================================================================

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

_assign1
	dc.b	"Life&Death-I",0
_assign2
	dc.b	"Life&Death-II",0

slv_name	dc.b	"Life & Death",0
slv_copy	dc.b	"1991 The Software Toolworks / Mindscape",0
slv_info	dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Thanks to Tony Aksnes & Mad-Matt/Action for images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program1:
	dc.b	"boot.code",0
_program2:
	dc.b	"manual.code",0
_program3:
	dc.b	"loader.code",0
_program4:
	dc.b	"hospital.code",0
_program5:
	dc.b	"appendecectomy.code",0
_program6:
	dc.b	"aneurysm.code",0

_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	bsr	install_kb_handler

	move.l	_resload(pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe (boot)
		lea	_program1(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe

.lmb1
		btst	#6,$bfe001
		bne.b	.lmb1

		lea	_program1(pc),a0
		jsr	resload_GetFileSize(a2)
		cmp.l	#880,d0
		beq.b	.v1
		cmp.l	#740,d0
		beq.b	.v2

		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

.v1
	;load exe
		lea	_program2(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_manual_v1(pc),a5
		bsr	_load_exe

.lmb2
		btst	#6,$bfe001
		bne.b	.lmb2

	;load exe
		lea	_program3(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_loader_v1(pc),a5
		bsr	_load_exe
		bra	_quit

.v2
	;load exe
		lea	_program2(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_manual_v2(pc),a5
		bsr	_load_exe

.lmb3
		btst	#6,$bfe001
		bne.b	.lmb3

	;load exe
		lea	_program3(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_loader_v2(pc),a5
		bsr	_load_exe

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)



read_keyboard
	move.b	key_value(pc),d0
	rts

; ------------- Version #1 (SPS 1126) ---------------

_patch_manual_v1:
	lea	_pl_manual_v1(pc),a0
	jsr	resload_Patch(a2)
	rts

_pl_manual_v1:
	PL_START
	PL_S	$24E,$10	; skip access fault
	PL_R	$362		; skip access fault
	PL_END

_patch_loader_v1:
	patch	$100,_emulate_dbf
	addq.l	#4,a1
	lea	_pl_loader_v1(pc),a0
	jsr	resload_Patch(a2)
	rts

_pl_loader_v1
	PL_START
	PL_PS	$50,_patch_hospital_v1
	PL_PS	$EA,_patch_appendix_v1
	PL_PS	$15A,_patch_aneurysm_v1
	PL_L	$6C2,$4EB80100
	PL_END

; < D0: seglist

_patch_hospital_v1
	tst.l	d0
	beq.b	.notfound
	movem.l	d0-a6,-(a7)
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a1
	addq.l	#4,a1
	lea	_pl_hospital_v1(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

.notfound
	pea	_program4(pc)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


_pl_hospital_v1
	PL_START
	; avoids access fault (write to $E0040 & $E0042)

	PL_R	$72E

	; codewheel copy-protection

	PL_W	$2BEA,$4E71

	; keyboard fix

	PL_PS	$382C,read_keyboard

	; active cpu loops

	PL_L	$0234,$4EB80100
	PL_L	$3752,$4EB80100

	; blitter waits (fixes font problem in WinUAE / fast CPUs)

	PL_PS	$DB4,wait_blit_1
	PL_PS	$B30,wait_blit_2
	PL_END

wait_blit_2
	addq.l	#2,(A7)
	move.w	#$802,$DFF058
	bra	wait_blit

wait_blit_1
	move	D3,$DFF058
	bra	wait_blit

wait_blit
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
	rts

; < D0: seglist

_patch_appendix_v1
	tst.l	d0
	beq.b	.notfound
	movem.l	d0-a6,-(a7)
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a1
	addq.l	#4,a1
	lea	_pl_appendix_v1(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

.notfound
	pea	_program5(pc)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_pl_appendix_v1
	PL_START
	; avoids access fault (write to $E0040 & $E0042)

	PL_R	$5BDA

	; fix active cpu loops

	PL_L	$5714,$4EB80100
	PL_L	$58BC,$4EB80100
	PL_L	$85F8,$4EB80100

	PL_END

; < D0: seglist

_patch_aneurysm_v1
	tst.l	d0
	beq.b	.notfound
	movem.l	d0-a6,-(a7)
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a1
	addq.l	#4,a1
	lea	_pl_aneurysm_v1(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

.notfound
	pea	_program6(pc)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_pl_aneurysm_v1
	PL_START
	; avoids access fault (write to $E0040 & $E0042)

	PL_R	$5EA2

	; fix active cpu loops

	PL_L	$59D4,$4EB80100
	PL_L	$59F6,$4EB80100
	PL_L	$8598,$4EB80100

	PL_END

; ------------- Version #2 ---------------

; < a1: seglist

_patch_manual_v2:
	lea	_pl_manual_v2(pc),a0
	jsr	resload_Patch(a2)
	rts

_pl_manual_v2:
	PL_START
	PL_L	$9E,$4E714E71	; skip disk copy warning message
	PL_R	$402		; skip access fault
	PL_END

_patch_loader_v2:
	patch	$100,_emulate_dbf
	addq.l	#4,a1
	lea	_pl_loader_v2(pc),a0
	jsr	resload_Patch(a2)
	rts

_pl_loader_v2
	PL_START
	PL_PS	$D4,_patch_hospital_v2
	PL_PS	$186,_patch_appendix_v2
	PL_PS	$1EC,_patch_aneurysm_v2
	PL_L	$76C,$4EB80100
	PL_END

; < D0: seglist

_patch_hospital_v2
	tst.l	d0
	beq.b	.notfound
	movem.l	d0-a6,-(a7)
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a1
	addq.l	#4,a1
	lea	_pl_hospital_v2(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

.notfound
	pea	_program4(pc)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


_pl_hospital_v2
	PL_START
	; avoids access fault (write to $E0040 & $E0042)

	PL_R	$1BD8

	; codewheel copy-protection

	PL_W	$40A4,$4E71

	; keyboard fix

	PL_PS	$4CE6,read_keyboard

	; active cpu loops

	PL_L	$167E,$4EB80100
	PL_L	$4C0C,$4EB80100

	; blitter waits (fixes font problem in WinUAE / fast CPUs)

	PL_PS	$225E,wait_blit_1
	PL_PS	$1FDA,wait_blit_2

	PL_END


; < D0: seglist

_patch_appendix_v2
	tst.l	d0
	beq.b	.notfound
	movem.l	d0-a6,-(a7)
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a1
	addq.l	#4,a1
	lea	_pl_appendix_v2(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

.notfound
	pea	_program5(pc)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_pl_appendix_v2
	PL_START
	; avoids access fault (write to $E0040 & $E0042)

	PL_R	$2EAC

	; fix active cpu loops

	PL_L	$2A48,$4EB80100
	PL_L	$2BF2,$4EB80100
	PL_L	$5794,$4EB80100

	PL_END

; < D0: seglist

_patch_aneurysm_v2
	tst.l	d0
	beq.b	.notfound
	movem.l	d0-a6,-(a7)
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a1
	addq.l	#4,a1
	lea	_pl_aneurysm_v2(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

.notfound
	pea	_program6(pc)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_pl_aneurysm_v2
	PL_START
	; avoids access fault (write to $E0040 & $E0042)

	PL_R	$30C6

	; fix active cpu loops

	PL_L	$2C5C,$4EB80100
	PL_L	$2C7E,$4EB80100
	PL_L	$567A,$4EB80100

	PL_END


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
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	jsr	(a5)
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

install_kb_handler
	lea	.read_kb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.read_kb:
	movem.l	D0/A0,-(A7)

	lea	key_value(pc),a0

	move.b	$bfeC01,(a0)

	bset	#6,$BFEE01
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0/A0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0


_emulate_dbf
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
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

key_value
	dc.b	0

