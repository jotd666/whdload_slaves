;*---------------------------------------------------------------------------
;  :Program.	MoktarHD.asm
;  :Contents.	Slave for "Moktar"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: MoktarHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;DEBUG
	IFD BARFLY
	OUTPUT	"Moktar.slave"
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

; infinite level 1 1BCF9 23105

;============================================================================


	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
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

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

assign
	dc.b	"df0",0

slv_name		dc.b	"Moktar / Titus The Fox"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1991-1992 Titus",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Set CUSTOM1=1 for infinite lives",10
			dc.b	"Set CUSTOM2=1 for infinite energy",10
			dc.b	"Set CUSTOM3=2/14 (Titus) 15 (Moktar) for start level",10
			dc.b	10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"main",0
args		dc.b	"r",10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

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
	movem.l	d0-d1/a0-a2,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#98568,D0
	beq	moktar_v1

	cmp.l	#98276,d0
	beq	moktar_v2

	cmp.l	#99108,d0
	beq	titus_fox



	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

titus_fox
	move.l	start_level(pc),d0
	beq	.nostart
	cmp.l	#$0F,d0
	bcc.b	.nostart	; too high
	moveq	#3,d2
	bsr	get_section
	add.l	#$D648-$3414,A1
	move.w	d0,(a1)	; set start level
.nostart

	move.l	infinite_lives(pc),d0
	beq.b	.nolives

	moveq	#3,d2
	bsr	get_section
	lea	pl_infinite_lives_titus(pc),a0
	jsr	resload_Patch(a2)
.nolives
	move.l	infinite_nrj(pc),d0
	beq.b	.nonrj
	moveq	#3,d2
	bsr	get_section
	lea	pl_infinite_nrj_titus(pc),a0
	jsr	resload_Patch(a2)
.nonrj
	moveq	#3,d2
	bsr	get_section
	lea	pl_section3_titus(pc),a0
	jsr	resload_Patch(a2)
	bra	out

moktar_v1	
	move.l	start_level(pc),d0
	beq	.nostart
	cmp.l	#$10,d0
	bcc.b	.nostart	; too high
	moveq	#3,d2
	bsr	get_section
	add.l	#$D45E-$33A4,A1
	move.w	d0,(a1)	; set start level
.nostart

	move.l	infinite_lives(pc),d0
	beq.b	.nolives

	moveq	#3,d2
	bsr	get_section
	lea	pl_infinite_lives_v1(pc),a0
	jsr	resload_Patch(a2)
.nolives
	move.l	infinite_nrj(pc),d0
	beq.b	.nonrj
	moveq	#3,d2
	bsr	get_section
	lea	pl_infinite_nrj_v1(pc),a0
	jsr	resload_Patch(a2)
.nonrj
	moveq	#3,d2
	bsr	get_section
	lea	pl_section3_v1(pc),a0
	jsr	resload_Patch(a2)
	bra	out

moktar_v2
	move.l	start_level(pc),d0
	beq	.nostart
	cmp.l	#$10,d0
	bcc.b	.nostart	; too high
	moveq	#3,d2
	bsr	get_section
	add.l	#$D2F6-$32D0,A1
	move.w	d0,(a1)	; set start level
.nostart

	move.l	infinite_lives(pc),d0
	beq.b	.nolives

	moveq	#3,d2
	bsr	get_section
	lea	pl_infinite_lives_v2(pc),a0
	jsr	resload_Patch(a2)
.nolives
	move.l	infinite_nrj(pc),d0
	beq.b	.nonrj
	moveq	#3,d2
	bsr	get_section
	lea	pl_infinite_nrj_v2(pc),a0
	jsr	resload_Patch(a2)
.nonrj
	moveq	#3,d2
	bsr	get_section
	lea	pl_section3_v2(pc),a0
	jsr	resload_Patch(a2)
	bra.b	out
out
	movem.l	(a7)+,d0-d1/a0-a2
	rts

patch_dbf
	move.l	#$190,d0
	bsr	emulate_dbf
	add.l	#2,(A7)
	rts


pl_infinite_lives_v1
	PL_START
	PL_W	$DE78-$33A4,$4E71
	PL_END

pl_infinite_nrj_v1
	PL_START
	PL_L	$98F4-$33A4,$4E714E71
	PL_W	$98F8-$33A4,$4E71
	PL_NEXT	pl_infinite_lives_v1

pl_section3_v1
	PL_START
	PL_B	$CC4C-$33A4,$60	; skip protection test
	PL_W	$CC4C-$33A4-50,$6004	; skip disk hw access
	PL_PS	$75B8-$33A4,patch_dbf
	PL_END

pl_infinite_lives_v2
	PL_START
	PL_W	$DFCA-$32D0,$4E71
	PL_END

pl_infinite_nrj_v2
	PL_START
	PL_L	$98DC-$32D0,$4E714E71
	PL_L	$98E0-$32D0,$4E714E71
	PL_NEXT	pl_infinite_lives_v2

pl_section3_v2
	PL_START
	PL_B	$CD00-$32D0,$60	; skip protection test
	PL_W	$CD00-$32D0-50,$6004	; skip disk hw access
	PL_PS	$752C-$32D0,patch_dbf
	PL_END

pl_infinite_lives_titus
	PL_START
	PL_W	$E062-$3414,$4E71
	PL_END

pl_infinite_nrj_titus
	PL_START
	PL_L	$9ABC-$3414,$4E714E71
	PL_W	$9AC0-$3414,$4E71
	PL_NEXT	pl_infinite_lives_titus

pl_section3_titus
	PL_START
	PL_B	$CE34-$3414,$60	; skip protection test
	PL_W	$CE02-$3414,$6004	; skip disk hw access
	PL_PS	$7628-$3414,patch_dbf
	PL_END

emulate_dbf
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.w	#$FFFF,d0
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

	bsr	update_task_seglist

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

update_task_seglist
	movem.l	d0/a0/a6,-(a7)
	move.l	$4,A6
	sub.l	a1,a1
	jsr	(_LVOFindTask,a6)
	move.l	d0,a0
	move.l	pr_CLI(a0),d0
	asl.l	#2,d0
	move.l	d0,a0

	; store loaded segments in current task

	move.l	d7,cli_Module(a0)

	movem.l	(a7)+,d0/a0/a6
	rts

tag
		dc.l	WHDLTAG_CUSTOM1_GET
infinite_lives
		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
infinite_nrj
		dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
start_level
		dc.l	0
		dc.l	0

;============================================================================

	END
