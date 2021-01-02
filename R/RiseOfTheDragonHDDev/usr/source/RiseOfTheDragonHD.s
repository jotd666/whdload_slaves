;*---------------------------------------------------------------------------
;  :Program.	RiseOfTheDragonHD.asm
;  :Contents.	Slave for "RiseOfTheDragon"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: RiseOfTheDragonHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"RiseOfTheDragon.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
;DOSASSIGN
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 3000
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
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_assign
	dc.b	"RiseOfTheDragon",0

slv_name		dc.b	"Rise Of The Dragon",0
slv_copy		dc.b	"1992 Dynamix",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program_name_english:
	dc.b	"Dragon",0
program_name_german:
	dc.b	"Drachen",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	old_\1(pc),a0
	move.l	A1,(A0)+

	move.l	A6,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)		; moves to d0_value_xxx

	move.w	#$4EF9,(A1)+	
	pea	new_int_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
new_int_\1:
	move.l	d0_value_\1(pc),d0
	bra	new_\1
old_\1:
	dc.l	0
d0_value_\1
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
	ENDM

_bootdos
		clr.l	$0.W

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

		lea	program_name_english(pc),a0
		bsr	check_file_exists
		tst.l	d0
		beq.b	.load

		lea	program_name_german(pc),a0
		bsr	check_file_exists
		tst.l	d0
		beq.b	.load

.load
		lea	program_name(pc),a1
		move.l	a0,(a1)

		lea	emptyfile(pc),a0
		bsr	must_exist

		PATCH_DOSLIB_OFFSET	DeleteFile
		PATCH_DOSLIB_OFFSET	Open

	;load exe
		move.l	program_name(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

new_DeleteFile
	bsr	isempty
	bne.b	.skip
	move.l	old_DeleteFile(pc),-(a7)
	rts
.skip
	moveq	#-1,d0
	rts

new_Open
	cmp.l	#MODE_OLDFILE,d2
	beq.b	.normal

	bsr	isempty
	beq.b	.normal
	move.l	#MODE_OLDFILE,d2	; NEWFILE -> OLDFILE avoids writing to disk
.normal
	move.l	old_Open(pc),-(a7)
	rts

; < d1 filename
; > Z flag set if normal file

isempty:
	movem.l	d0/a0/a1,-(a7)
	move.l	d1,a0
	lea	emptyfile(pc),a1
.goend
	move.b	(a0)+,d0
	bne.b	.goend
.skipcol
	cmp.l	a0,d1
	beq.b	.out
	move.b	-1(a0),d0	
	cmp.b	#':',d0
	beq.b	.loop
	cmp.b	#'/',d0
	beq.b	.loop

	subq.l	#1,a0
	bra.b	.skipcol
.loop
	move.b	(a0)+,d0
	beq.b	.end
	cmp.b	(a1)+,d0
	beq.b	.loop
.end
	tst.b	(a1)
	bne.b	.fail

	moveq	#-1,d0		; success
	bra.b	.out
	; fake file deletion/creation
.fail
	moveq	#0,d0
.out
	tst.l	d0
	movem.l	(a7)+,d0/a0/a1
	rts

emptyfile
	DC.B	"DYNAMIX_.___",0,0
	even

; < d7: seglist (APTR)

patch_main
	bsr	get_version
	moveq	#0,d2
	bsr	get_section
	jsr	resload_Patch(a2)
	rts


VERSION_PL:MACRO
.\1
	lea	pl_\1_seg0(pc),a0
	bra.b	.out
	ENDM

get_version:
	movem.l	d0-d1/a1,-(a7)
	move.l	program_name(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#228584,D0
	beq.b	.german

	cmp.l	#228108,d0
	beq.b	.english

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	VERSION_PL	german
	VERSION_PL	english


.out
	movem.l	(a7)+,d0-d1/a1
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

pl_english_seg0
	PL_START
	PL_PS	$217BE,kb_delay
	PL_END
pl_german_seg0
	PL_START
	PL_PS	$2339e,kb_delay
	PL_END

	IFEQ	1
pl_english_seg5
	PL_START
	; replaces empty "DYNAMIX_.___" temporary filename
	; by a filename in RAM: so disk is not written onto
	; without any reason when restoring a game

	PL_L	$1092,'RAM:'
	PL_END
	ENDC

kb_delay:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	add.l	#$800-$7C4,(a7)
	rts

; < a6: dosbase
; < a0: filename
; > d0: 0: exists, -1: error

check_file_exists
	movem.l	d1/a0-a1/a3,-(a7)
	move.l	a0,d1
	move.l	a0,a3
	move.l	#ACCESS_READ,d2
	jsr	_LVOLock(a6)
	move.l	d0,d1
	beq.b	.error
	jsr	_LVOUnLock(a6)
	moveq	#0,d0
	bra.b	.out
.error
	moveq	#-1,d0	
	bra.b	.out
.out
	movem.l	(a7)+,d1/a0-a1/a3
	rts

; < A0 filename
; < A6 dosbase

must_exist
	movem.l	d0,-(a7)
	bsr	check_file_exists
	tst.l	d0
	bne	.error
	movem.l	(a7)+,d0
	rts

.error
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
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

program_name
	dc.l	0
_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
