;*---------------------------------------------------------------------------
;  :Program.	PiratesGoldCD32HD.asm
;  :Contents.	Slave for "PiratesGoldCD32" from 
;  :Author.	JOTD
;  :Original	v1
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
	OUTPUT	"PiratesCD32.slave"
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

INITAGA
INIT_AUDIO
BOOTDOS
HDINIT

; calculate minimal amount of free memory
;	if the symbol MEMFREE is defined after each call to exec.AllocMem the
;	size of the largest free memory chunk will be calculated and saved at
;	the specified address if lower than the previous saved value (chipmem
;	at MEMFREE, fastmem at MEMFREE+4)
;MEMFREE=$100

; amount of memory available for the system
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
;FASTMEMSIZE	= $0
CACHE
STACKSIZE = 16384

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Pirates! (Gold) AGA/CD³²",0
slv_copy		dc.b	"1993 Microprose",0
slv_info		dc.b	"Install/fix by JOTD",10
		dc.b	"Version 2.2 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0

_exename_english:
	dc.b	"pirates",0
_exename_german:
	dc.b	"pirates_german",0
_arguments:
	dc.b	10,0
	even

_bootdos
	move.l	(_resload,pc),a2	;a2 = resload

	;get tags
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)
		
	bsr	_patch_cd32_libs

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load program

	lea	_exename_english(pc),A0

	move.l	_language(pc),D1
	cmp.b	#3,D1
	bne.b	.nogerman

	lea	_exename_german(pc),A0
	
.nogerman
	moveq	#1,d0
	lea	_arguments(pc),a1
	lea	patch_main(pc),a5
	bsr	_load_exe

	rts


patch_main
	move.l	d7,a5
	addq.l	#4,a5
	move.w	#$604E,$2494(a5)	; fix access fault
	move.b	#$60,$7E6(A5)		; remove need for open icon library
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

;---------------

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_LANG_GET
_language	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	0


;============================================================================

	END
