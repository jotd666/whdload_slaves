;*---------------------------------------------------------------------------
;  :Program.	FA18InterceptorHD.asm
;  :Contents.	Slave for "FA18Interceptor" from 
;  :Author.	JOTD
;  :Original	
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
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"F-18Interceptor.slave"
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

; enable SetPatch
;	include all patches (nearly all) done by the SetPatch program, usually
;	that is not neccessary and disabling that option makes the Slave
;	around 400 bytes shorter
SETPATCH

; enable debug support for hrtmon:
;	hrtmon reads to much from the stackframe if entered, if the ssp is at
;	the end hrtmon will create a access fault.
;	for better compatibility this option should be disabled
;HRTMON

; calculate minimal amount of free memory
;	if the symbol MEMFREE is defined after each call to exec.AllocMem the
;	size of the largest free memory chunk will be calculated and saved at
;	the specified address if lower than the previous saved value (chipmem
;	at MEMFREE, fastmem at MEMFREE+4)
;MEMFREE=$100

HDINIT
DOSASSIGN
BLACKSCREEN
BOOTDOS
CACHE

; amount of memory available for the system
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $50000
;CHIPMEMSIZE	= $100000
;FASTMEMSIZE	= $0000

; protection removal: offset  1ce70 : 13fc00ff -> 13fc0001
; 40A54 end of line

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"F/A-18 Interceptor",0
slv_copy		dc.b	"1988 Intellisoft/Electronic Arts",0
slv_info		dc.b	"Install & fix by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_assign1:
	dc.b	"DF0",0
_assign2:
	dc.b	"F18",0

_program:
	dc.b	"f-18 interceptor",0
_args:
	dc.b	10
_args_end:
	dc.b	0
	even

;============================================================================

	;initialize kickstart and environment

_bootdos
		move.l	(_resload,pc),a2	;a2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
		

	; stores most significant quadbit for later

	move.b	_expmem(pc),d0
	and.b	#$F0,D0
	lea	_msq(pc),A0
	move.b	D0,(A0)

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

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patchexe(pc),a5
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

_patchexe
	movem.l	D0-A6,-(A7)

	move.l	d7,d1		; seglist

	; remain compatible with unit-a crack, well spread

	pea	_unita_trap0(pc)
	move.l	(a7)+,$80.W

	; section 1: cpu dependent loop

	move.w	#0,d2
	bsr	.get_section
	add.l	#$8E2,a0
	move.w	#$4EB9,(a0)+
	pea	_emulate_empty_loop(pc)
	move.l	(a7)+,(a0)

	; section 20: protection

	move.w	#20,d2
	bsr	.get_section
	add.l	#$71C-$274,a0

	move.b	#1,$73-$58(A0)		; flag telling that protection was passed

	; section 8: access fault #1

	move.w	#8,d2
	bsr	.get_section
	add.l	#$D7C-$1D8,a0

	cmp.l	#$22584A51,(a0)
	bne	_wrong_version

	move.l	#$4EB80100,(A0)
	patch	$100,_fix_af_1

	; section 9: access fault #2

	move.w	#9,d2
	bsr	.get_section
	add.l	#$1462-$AEC,a0

	move.l	#$4EB80106,6(A0)
	patch	$106,_fix_af_2

	movem.l	(A7)+,D0-A6
	rts

; < d1 seglist
; < d2 section #
; > a0 segment
.get_section
	move.l	d1,a0
	subq	#1,d2
	bmi.b	.exit
.loop
	move.l	(a0),a0
	add.l	a0,a0
	add.l	a0,a0
	dbf	d2,.loop
.exit
	addq.l	#4,a0
	rts

_unita_trap0
	moveq	#0,d0
	RTE

; must be a while(i++<10000); or something like that in C

_emulate_empty_loop:
	add.l	#10,(a7)	; skip rest of active cpu loop
	rts

	move.l	(8,a6),d0
	divu	#10,d0
	swap	d0
	clr	d0
	swap	d0
	bsr	_beamdelay
	add.l	#10,(a7)	; skip rest of active cpu loop
	rts

_fix_af_1
	movem.l	D0,-(A7)
	move.l	(A0)+,d0
	move.l	d0,a1
	rol.l	#8,D0
	tst.b	D0
	beq.b	.ok
	or.b	_msq(pc),d0
	ror.l	#8,D0
	move.l	D0,A1
.ok
	movem.l	(A7)+,D0
	tst.w	(A1)	; stolen code
	rts

_fix_af_2
	movem.l	D0,-(A7)
	move.l	(2,A1),d0
	move.l	d0,a2
	rol.l	#8,D0
	tst.b	D0
	beq.b	.ok
	or.b	_msq(pc),d0
	ror.l	#8,D0
	move.l	D0,A2
.ok
	movem.l	(A7)+,D0
	rts

_wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

;---------------

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	0
_seglist:
	dc.l	0
_msq:
	dc.w	0
_saveregs
		blk.l	16,0
_stacksize
		dc.l	0

;============================================================================


;============================================================================

	END
