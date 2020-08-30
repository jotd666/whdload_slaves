;*---------------------------------------------------------------------------
;  :Program.	RiseOfTheRobotsHD.asm
;  :Contents.	Slave for "RiseOfTheRobots" from 
;  :Author.	JOTD
;  :Original	v1 jffabre@free.fr
;  :Version.	$Id: battleisle.asm 0.5 2000/11/26 21:13:41 jah Exp $
;  :History.	23.05.01 started
;		23.05.01 finished
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
	OUTPUT	"RiseOfTheRobotsECS.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

; number of floppy drives:
;	sets the number of floppy drives, valid values are 0-4.
;	0 means that the number is specified via option Custom1/N
NUMDRIVES=1

; protection state for floppy disks:
;	0 means 'write protected', 1 means 'read/write'
;	bit 0 means drive DF0:, bit 3 means drive DF3:
WPDRIVES=%1111

; disable fpu support:
;	results in a different task switching routine, if fpu is enabled also
;	the fpu status will be saved and restored.
;	for better compatibility and performance the fpu should be disabled
;NEEDFPU

; amount of memory available for the system
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
;FASTMEMSIZE	= $0

HDINIT
BOOTDOS
CACHE
DOSASSIGN
; kick 3.1 but no 68020 required
NO68020

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	
DECL_VERSION:MACRO
	dc.b	"1.4-C"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Rise Of The Robots",0
slv_copy		dc.b	"1993 Mirage",0
slv_info		dc.b	"Install/fix by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
    dc.b    0

assign
	dc.b	"ROR",0
program:
	dc.b	"Rise",0
args:
	dc.b	10
args_end
	dc.b	0
	even

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload

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

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0

; < d7: seglist (APTR)

patch_main
	lea	pl_main(pc),a0
	move.l	d7,a1
	addq.l	#4,a1
	jsr	resload_Patch(a2)
	rts

pl_main
	PL_START
	PL_L	$1AA,$70007000	; CACR
	PL_L	$1AE,$70007000	; VBR

	PL_L	$3e34a,'ROR:'			; HD path protection
	PL_L	$3e34a+4,0			; HD path protection
	PL_L	$3e34a+8,0			; HD path protection

;	PL_PS	$3F868,avoid_af_1	; AF 1
;	PL_PS	$3FB60,avoid_af_2	; AF 2
	PL_END

avoid_af_1:
	cmp.l	#$F000,D2
	bcc.b	.skipadd
	add.l	D2,A6
.skipadd
	bra	avoid_af_end
avoid_af_2:
	cmp.l	#$100000,D6
	bcc.b	.skipadd
	add.l	D6,A6
	bra	avoid_af_end

.skipadd
	moveq	#0,D2	; end loop
	add.l	#$17E,(A7)		; skip code
	rts

avoid_af_end
	move.b	(a6)+,(a1)
	lea	($30,a1),a1
	add.l	#2,(a7)
	rts

