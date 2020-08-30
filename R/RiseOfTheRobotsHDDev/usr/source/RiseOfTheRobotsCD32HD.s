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
	INCLUDE	lvo/intuition.i
	INCLUDE	dos/dos.i

	IFD BARFLY
	OUTPUT	"RiseOfTheRobotsCD32.slave"
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

INITAGA
HDINIT
BOOTDOS
DOSASSIGN
CACHE
IOCACHE = 10000

;DUMMY_CD_DEVICE
;USE_DISK_LOWLEVEL_LIB
USE_DISK_NONVOLATILE_LIB	; makes slave shorter

; amount of memory available for the system
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $80000

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


	INCLUDE	kick31cd32.s

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
	
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Rise Of The Robots CD³²",0
slv_copy		dc.b	"1994 Mirage",0
slv_info		dc.b	"Install/fix by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

cd0_assign
	dc.b	"cd0",0	; REQUIRED!
ram_assign
	dc.b	"ram",0

_program:
	dc.b	"boot",0
_args:
	dc.b	10,0
	even

;============================================================================

	;initialize kickstart and environment

_bootdos		
		move.l	(_resload,pc),a2	;a2 = resload

		; set P = pause (instead of some function key)

		lea	OSM_JOYPAD1KEYS+2(pc),a0
		move.w	#$1919,(A0)+
		move.w	#$1919,(A0)+
		lea	OSM_JOYPAD0KEYS+2(pc),a0
		move.w	#$1919,(A0)+
		move.w	#$1919,(A0)+

		bsr	_patch_cd32_libs

		bsr	openwindow

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		lea	cd0_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		lea	ram_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
		

	;load exe
		lea	_program(pc),a0
		lea	patch_main(pc),a5
		moveq	#1,d0
		lea	_args(pc),a1
		bsr	_load_exe

_exit
	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


patch_main
	move.l	d7,a1
	addq.l	#4,a1
	lea	patchlist(pc),a0
	jsr	resload_Patch(a2)
	rts


patchlist:
	PL_START
	; remove CACR/VBR handling

	PL_L	$204,$70007000	; CACR = 0 in D0
	PL_L	$208,$70007000	; VBR = 0 in D0

	; access faults/crashes

	PL_PS	$3F860,avoid_af_1	; AF 1
	PL_PS	$3FB58,avoid_af_2	; AF 2

	; remove CIA hack

	PL_W	$48A1E,$6006

	; open file

;;	PL_PS	$3F2BA,open_file
	PL_END

	IFEQ	1
open_file
	MOVE.L	#$000003ED,D2
	btst	#6,$bfe001
	bne.b	.sk
	illegal
.sk
	rts
	ENDC

avoid_af_1:
	cmp.l	#$F000,D2
	bcc.b	.skipadd
	add.l	D2,A6
	bra	avoid_af_end
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

;---------------

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
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
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d0-a6,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	movem.l	(a7)+,d0-a6
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
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


openwindow:
	movem.l	d0-a6,-(a7)
	lea	.intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	lea	.newscreen_struct(pc),A0
	jsr	_LVOOpenScreen(A6)

	lea	.newwindow_struct(pc),A0
	move.l	D0,$1E(A0)	; nw_Screen

	jsr	_LVOOpenWindow(A6)
	movem.l	(a7)+,d0-a6
	rts

.newscreen_struct:
	dc.w	0,0
	dc.w	320,200
	dc.w	2
	dc.b	1,0
	dc.W	0
	dc.W	0
	dc.l	0	; no font
	dc.l	0	; no title
	dc.l	0
	dc.l	0
.newwindow_struct:
	dc.w	0,0
	dc.w	320,200
	dc.w	0
	dc.l	0,0,0,0
	dc.l	0	; no title
	dc.l	0,0
	dc.w	10,10,320,200
	dc.w	0

.intname:
	dc.b	"intuition.library",0
	even
