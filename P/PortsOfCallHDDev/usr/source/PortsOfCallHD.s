;*---------------------------------------------------------------------------
;  :Program.	PortsOfCallHD.asm
;  :Contents.	Slave for "PortsOfCall"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: PortsOfCallHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"PortsOfCall.slave"
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
HRTMON
CHIPMEMSIZE	= $C0000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
SEGTRACKER
CACHE
;;FONTHEIGHT = 8

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

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


_assign
	dc.b	"PortsOfCall",0

slv_name		dc.b	"Ports Of Call"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/Chip MODE)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1989 International Software Development",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"PortsOfCall",0
_program_german:
	dc.b	"PortsOfCallG",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$VER: slave "
	DECL_VERSION
	EVEN


GETFILESIZE:MACRO
	movem.l	d1/a0/a1/a2,-(a7)
	move.l	_resload(pc),a2
	lea	\1(pc),a0
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,d1/a0/a1/a2
    tst.l   d0
	ENDM
    
_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
;		lea	_assign(pc),a0
;		sub.l	a1,a1
;		bsr	_dos_assign

		lea	_program(pc),a0
        GETFILESIZE _program
        bne.b   .ok
	;load exe
		lea	_program_german(pc),a0
        GETFILESIZE _program_german
.ok
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)



patch_main
	move.l	d7,a1
	GETFILESIZE	_program
	cmp.l	#177784,d0
	beq.b	.rerelease      ; or crack!
	cmp.l	#178996,d0
	beq.b	.v1
    tst.l   d0
    bne.b   wrong_version
    GETFILESIZE	_program_german
	cmp.l	#179944,d0
	beq.b	.german
	bra	wrong_version
.rerelease
	rts
.v1
	lea	pl_v1(pc),a0
	jsr	resload_PatchSeg(a2)
	rts
.german
	lea	pl_german(pc),a0
	jsr	resload_PatchSeg(a2)
	rts

pl_v1
	PL_START
	PL_B	$38B2,$60	; protection removed (thanks LockPick)
	PL_END
pl_german
	PL_START
	PL_B	$393c,$60	; protection removed (thanks LockPick)
	PL_END

wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
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
    ; quit, as unloading exe seems to crash (corrupt memlist?)
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

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

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
