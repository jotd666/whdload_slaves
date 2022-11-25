;*---------------------------------------------------------------------------
;  :Program.	AdventureConstructionSetHD.asm
;  :Contents.	Slave for "AdventureConstructionSet"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: AdventureConstructionSetHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"AdventureConstructionSet.slave"
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
CHIPMEMSIZE	= $C0000
FASTMEMSIZE	= $0000

	IFD	DEBUG
HRTMON
IOCACHE		= 10000
	ELSE
BLACKSCREEN
IOCACHE		= 160000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 8000
BOOTDOS
CACHE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


; game needs executable name (bcpl stuff) to run properly

BOOTFILENAME	MACRO
	dc.b	"ACS",0
	ENDM

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

_assign1
	dc.b	"ACS",0
_assign2
	dc.b	"DF0",0
_assign3
	dc.b	"DF1",0

userdata0:
	dc.b	"userdata0",0
userdata1:
	dc.b	"userdata1",0

slv_name		dc.b	"Adventure Construction Set"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1986 Electronic Arts",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"ACS.EXE",0
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
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		lea	userdata0(pc),a1
		bsr	_dos_assign
		lea	_assign3(pc),a0
		lea	userdata1(pc),a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_acs(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_acs
	move.l	#3,d2
	bsr	get_section
	sub.l	#$38C,a1
	lea	pl_acs_s3(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	#6,d2
	bsr	get_section
	sub.l	#$A10,a1
	lea	pl_acs_s6(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	#7,d2
	bsr	get_section
	sub.l	#$A34,a1
	lea	pl_acs_s7(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts

run_segment
	lsl.l	#2,d1
	bsr	patch_segment
	move.l	d1,a1
	jsr	(a1)
	rts

patch_segment
	movem.l	d0-d2/d7/a0-a2,-(a7)
	move.l	d1,d7
	subq.l	#4,d7

	move.w	.next_time_protect(pc),d2
	bne.b	.protection

	move.l	#8,d2
	bsr	get_section
	cmp.l	#$20BC5731,8(a1)
	bne.b	.no_zzz

	lea	.next_time_protect(pc),a0
	st.b	(a0)

	lea	pl_zzz_s8(pc),a0
	sub.l	#$BEC,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

.no_zzz
	movem.l	(a7)+,d0-d2/d7/a0-a2
	rts
.protection
	lea	.next_time_protect(pc),a0
	clr.b	(a0)

	move.l	#2,d2
	bsr	get_section

	; replace disk read by memory changer

	move.w	#$4EB9,$350-$328(a1)
	pea	emulate_protection(pc)
	move.l	(a7)+,$352-$328(a1)
	bsr	_flushcache

	bra.b	.no_zzz
.next_time_protect
	dc.w	0

; < d7: seglist
; < a0: address to reach
; > a1: section
; > d0: section #

get_closest_section
	movem.l	d1/d2,-(a7)
	moveq	#0,d0
	move.l	d7,a1
.loop
	cmp.l	a0,a1
	bcc.b	.toofar

	move.l	(a1),a1
	cmp.l	#0,a1
	beq.b	.error
	add.l	a1,a1
	add.l	a1,a1

	addq.l	#1,d0
	bra.b	.loop
.toofar
	subq.l	#1,d0
	move.l	d0,d2
	bsr	get_section
	movem.l	(a7)+,d1/d2
	rts
.error
	illegal

PL_FIX1:MACRO
	PL_L	\1,$2F3C00FC
	PL_L	\1+4,$00004E71
	PL_L	\1+8,$4E714E71
	PL_W	\1+12,$4E71
	ENDM
PL_FIX2:MACRO
	PL_L	\1,$2F3C00FC
	PL_L	\1+4,$00004E71
	ENDM


pl_acs_s3
	PL_START
	PL_S	$4B2,6	; skip VHPOS read
	PL_END

pl_acs_s6
	PL_START
	PL_PS	$A24,run_segment
	PL_END

pl_acs_s7
	PL_START

	PL_FIX1	$C24

	PL_FIX2	$C60
	PL_FIX2	$C98
	PL_FIX2	$CB6
	PL_FIX2	$CCC

	PL_END

pl_zzz_s8
	PL_START

	PL_FIX1	$DDC

	PL_FIX2	$E18
	PL_FIX2	$E50
	PL_FIX2	$E6E
	PL_FIX2	$E84

	PL_END

emulate_protection:
	movem.l	a0/a1,-(a7)
	sub.l	#$B3E,a0	; a0=$18000

	move.l	a1,$b4a(a0)
;;	move.l	#$8d500000,$b4c(a0)
	move.l	#$00000000,$b50(a0)
	move.l	#$04b09269,$b54(a0)

	sub.l	#$D50,a1	; a1=$18000
	move.l	#$00000004,$d50(a1)
	move.l	#$00000002,$d54(a1)
	move.l	#$00000001,$d58(a1)
	move.l	#$00000001,$d5c(a1)
	move.l	#$05000000,$da8(a1)
	move.l	#$00000001,$dac(a1)
	movem.l	(a7)+,a0/a1
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
	cmp.l	#0,a1
	beq.b	.end
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
.end
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

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
