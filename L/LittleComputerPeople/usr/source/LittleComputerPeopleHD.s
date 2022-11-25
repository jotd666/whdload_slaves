;*---------------------------------------------------------------------------
;  :Program.	LittleComputerPeopleHD.asm
;  :Contents.	Slave for "LittleComputerPeople"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: LittleComputerPeopleHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
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
	OUTPUT	"LittleComputerPeople.slave"
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
HRTMON
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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

_assign
	dc.b	"LCP",0

slv_name		dc.b	"Little Computer People"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1985/86 Activision",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"pet",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main_v1(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

PATCH_SECTION:MACRO
	move.l	_resload(pc),a2
	move.l	#\1,d2
	bsr	get_section
	lea	.pl_section_\1(pc),a0
	jsr	resload_Patch(a2)
	ENDM

patch_main_v1
	; removes protection

	PATCH_SECTION	41

	rts

.pl_section_41
	PL_START
	PL_P	$5F0,emu_protect
	PL_END


emu_protect
	move.l	#$1ADB,d0
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


_patch_alloc:
	movem.l	a0/a1,-(a7)

	move.l	$4.W,A0
	add.w	#_LVOAllocMem+2,a0
	lea	_alloc_save(pc),a1
	move.l	(a0),(a1)
	lea	_my_alloc(pc),a1
	move.l	a1,(a0)
	bsr	_flushcache

	movem.l	(a7)+,a0/a1
	rts

_rem_patch_alloc:
	movem.l	a0,-(a7)
	move.l	$4.W,A0
	add.w	#_LVOAllocMem+2,a0
	move.l	_alloc_save(pc),(A0)
	bsr	_flushcache

	move.l	(a7)+,a0
	rts

_my_alloc:
	bsr	change_memtype
.out
	move.l	_alloc_save(pc),-(A7)
	rts

_alloc_save
	dc.l	0


change_memtype
	movem.l	d2,-(a7)
	lea	.table_v1(pc),a0
.loop
	move.l	(a0)+,d2
	beq.b	.out
	cmp.l	d2,d0
	bne.b	.loop
	or.l	#MEMF_CHIP,d1	; chipmem flag on some blocks
.out
	movem.l	(a7)+,d2
	rts

.table_v1
	dc.l	$CB4
	dc.l	0

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
	bsr	_patch_alloc
	jsr	(_LVOLoadSeg,a6)
	bsr	_rem_patch_alloc
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
		blk.l	16,0
_stacksize
		dc.l	0

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
