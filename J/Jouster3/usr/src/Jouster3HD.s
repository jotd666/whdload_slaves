;*---------------------------------------------------------------------------
;  :Program.	Jouster3HD.asm
;  :Contents.	Slave for "Jouster3" from 
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
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"Jouster3.slave"
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
NOFPU

; enable SetPatch
;	include all patches (nearly all) done by the SetPatch program, usually
;	that is not neccessary and disabling that option makes the Slave
;	around 400 bytes shorter
;SETPATCH

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

; amount of memory available for the system
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $80000
;FASTMEMSIZE	= $0

PATCH_DIRECTORY_STUFF = 1
INIT_MATHFFP = 1
ENABLE_DISK_LIBRARIES = 1
MAIN_PROCESS_QUITS = 1

;============================================================================

KICKSIZE	= $80000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	"Jouster 3",0
_copy		dc.b	"199? Pawprint/Matt Westfall",0
_info		dc.b	"Adapted by JOTD",10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0

_exename:
	dc.b	"Jouster3",0
_arguments:
	dc.b	10,0
	even

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

_bootearly	move.l	(_resload,pc),a2	;a2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
		
	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
		

	;redirect exec calls to use kickdos with doslib

	bsr	DosLibInit

	;load program

	lea	_exename(pc),A0

	bsr	LoadSegList

	lea	_seglist(pc),A0
	move.l	D0,(A0)		; saves seglist for later use
	
	LSL.L	#2,D0		; BPTR -> APTR
	MOVE.L	D0,A5
	ADDQ.L	#4,A5		; A5: first segment (code start segment)

	bsr	_openwindow

	;disable cache
	move.l	_resload(pc),A2
	move.l	#WCPUF_Exp_NCS,d0
	move.l	#WCPUF_Exp,d1
	jsr	(resload_SetCPU,a2)

	lea	_arguments(pc),a0
	move.l	_seglist(pc),D0
	move.l	#8000,D1	; stack size
	bsr	StartDosProcess

	;quit
.quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


_openwindow:
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

	rts

.newscreen_struct:
	dc.w	0,0
	dc.w	320,200
	dc.w	2
	dc.w	1,0
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

;---------------

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	0
_seglist:
	dc.l	0

;============================================================================

	INCLUDE	osemu:kickproc.s
	INCLUDE	osemu:kickdos.s
	INCLUDE	osemu:kick31.s

;============================================================================

	END
