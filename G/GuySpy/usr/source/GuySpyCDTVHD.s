;*---------------------------------------------------------------------------
;  :Program.	GuySpyCDTVHD.asm
;  :Contents.	Slave for "GuySpyCDTV" from 
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
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"GuySpyCDTV.slave"
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

; enable fpu support:
;	results in a different task switching routine, if fpu is enabled also
;	the fpu status will be saved and restored.
;	for better compatibility and performance the fpu should be disabled
;NEEDFPU

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

; amount of memory available for the system
CHIPMEMSIZE	= $C0000
FASTMEMSIZE	= $40000


PATCH_DIRECTORY_STUFF = 0

;============================================================================

KICKSIZE	= $40000
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_EmulTrap	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
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

_data		dc.b	"data",0
_name		dc.b	"GuySpy CDTV",0
_copy		dc.b	"1993 ReadySoft",0
_info		dc.b	"Install/fix by JOTD",10,10
		dc.b	"Thanks for Tony Aksnes for the original",10,10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0

_exename:
	dc.b	"GuySpy",0
_arguments:
	dc.b	10,0
	even

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

_bootearly
	bsr	_patchkb

	move.l	(_resload,pc),a2	;a2 = resload

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
	bsr	_patch_cdtv

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

PATCH_IO:MACRO
	move.l	$4.W,a0
	add.w	#_LVO\1+2,a0
	lea	.\1_save\@(pc),a1
	move.l	(a0),(a1)
	lea	.\1\@(pc),a1
	move.l	a1,(a0)
	bra.b	.cont\@
.\1_save\@:
	dc.l	0
.\1\@:
	lea	_fake_cdtvbase(pc),A0
	cmp.l	IO_DEVICE(a1),A0
	beq.b	.ignore\@
	cmp.l	#$B0DEB0DE,IO_DEVICE(a1)
	beq.b	_handle_bookmark
	; ignore (cdtv.device)
.ignore\@
	moveq.l	#0,D0
	rts
.org\@
	move.l	.\1_save\@(pc),-(A7)
	rts
.cont\@
	ENDM

_handle_bookmark:
	movem.l	A1/A2,-(a7)
	move.l	_resload(pc),a2

	move.w	$1C(a1),d0	; command
	cmp.w	#13,d0		; create
	beq.b	.out		; creation always OK

	cmp.w	#CMD_READ,d0
	beq.b	.read_bookmark
	cmp.w	#CMD_WRITE,d0
	beq.b	.write_bookmark
	
	illegal
.out
	movem.l	(A7)+,A1/A2
	moveq.l	#0,D0
	clr.b	$1F(a1)
	rts

.read_bookmark:
	lea	.bookmark_name(pc),a0
	move.l	IO_LENGTH(a1),d0
	moveq.l	#0,D1
	move.l	IO_DATA(a1),a1
	jsr	resload_LoadFileOffset(a2)
	bra.b	.out	

.write_bookmark:
	lea	.bookmark_name(pc),a0
	move.l	IO_LENGTH(a1),d0
	moveq.l	#0,D1
	move.l	IO_DATA(a1),a1
	jsr	resload_SaveFileOffset(a2)
	bra.b	.out	
	
.bookmark_name:
	dc.b	"gamesave",0
	even

_patch_cdtv:
	move.l	4.W,a0
	add.w	#_LVOOpenDevice+2,a0
	lea	_opendev_save_2(pc),a1
	move.l	(a0),(a1)
	lea	_opendev_2(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOCloseDevice+2,a0
	lea	_closedev_save_2(pc),a1
	move.l	(a0),(a1)
	lea	_closedev_2(pc),a1
	move.l	a1,(a0)

	PATCH_IO	DoIO
	PATCH_IO	SendIO
	PATCH_IO	CheckIO
	PATCH_IO	WaitIO
	PATCH_IO	AbortIO

	rts

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

;---------------

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	0
_seglist:
	dc.l	0
_opendev_save_2:
	dc.l	0
_closedev_save_2:
	dc.l	0

;============================================================================

	INCLUDE	kickproc.s
	INCLUDE	kickdos.s
	INCLUDE	kick13.s

;============================================================================

_closedev_2:
	move.l	IO_DEVICE(a1),D0
	lea	_fake_cdtvbase(pc),a0
	cmp.l	a0,d0
	beq.b	.out
	cmp.l	#$B0DEB0DE,D0
	beq.b	.out

.org
	move.l	_closedev_save_2(pc),-(a7)
	rts

.out
	moveq	#0,D0
	rts

_opendev_2:
	movem.l	D0,-(a7)
	GETLONG	A0,D0
	cmp.l	#'cdtv',D0
	beq.b	.cdtv
	cmp.l	#'book',D0
	beq.b	.bookmark
	bra.b	.org

	; cdtv device
.cdtv
	pea	_fake_cdtvbase(pc)
	move.l	(A7)+,IO_DEVICE(a1)
.exit
	movem.l	(A7)+,D0
	moveq.l	#0,D0
	rts

.org
	movem.l	(A7)+,D0
	move.l	_opendev_save_2(pc),-(a7)
	rts

.bookmark:
	move.l	#$B0DEB0DE,IO_DEVICE(a1)
	bra.b	.exit

; all functions do nothing

	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
_fake_cdtvbase:
	illegal


_patchkb
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

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

	END
