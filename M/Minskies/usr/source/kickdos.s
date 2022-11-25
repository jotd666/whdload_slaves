; Source: kickdos.s
; Author: JF Fabre
; Purpose: provide a dos.library emulation for whdload slaves
; using (LoadKick/kick13.s or kick31.s)
; Actually interfaces the dos.s file from OSEmu with the whdload slave.
;
;       20.01.2002 JOTD added support for disk based libraries, added compile
;                       directives.
;
; Defines to configure KickDos
;
; set PATCH_DIRECTORY_STUFF in slave to 2 to enable Lock/Examine/ExNext on dirs
; set PATCH_DIRECTORY_STUFF in slave to 1 to disable Lock on dirs, but let it
; work on files
; set PATCH_DIRECTORY_STUFF in slave to 0, and if a directory is scanned, 
; WHDload will fail. You will then know that the EQ must be set either to
; 1 or 2 depending on what the game does (if the game tries to lock directories, 
; you must set it to 1
;
; define CREATE_EMPTY_FILES (set to 1 for instance) to force that the dos.Open
; function first creates a 0 length file (triggering OS swap later when the
; dos.Write is performed, but safer for some rare programs)
; Default behaviour: does not create empty files, so WHDLoad write cache avoids
; OS swaps (but if the new file is written smaller, then the remainder of the
; old, bigger file is still at the end of the file, which is not a problem in most
; cases since programs do not rely on size but on internal data structure of the file.
; For the other ones, just use CREATE_EMPTY_FILES :))
;
; define DOS_MULTITASK (set to 1 for instance) if you think that more than
; one process will access to dos functions (e.g. if 2 DOS processes are running
; and call DOS functions, WHDLoad will break because calls are not reentrant)
; Defender Of The Crown needs that, for instance (in the KickDOS release, but
; pure Kick1.3 dos version is better anyway)
;
; define IGNORE_OPENLIB_FAILURE if you don't want WHDLoad to quit if a library
; was not found
;
; define OPENLIB_IGNORE_VERSION if you want to ignore version requirements
; (but there will be some manual patching I think)
;
; define ENABLE_DISK_LIBRARIES if you want kickdos to try to find a library
; on the disk (in the LIBS/ directory of the game)
;
; define USE_DISK_LOWLEVEL_LIB if you want the original lowlevel library to
; be used. joypad emulation via keyboard is not supported then
; (only works with kick31.s, KICKSIZE=$80000)

	include	"dos/dos.i"
	include	"dos/dosextens.i"
	INCLUDE	"dos/doshunks.i"
	INCLUDE	"dos/filehandler.i"
	include	"lvo/dos.i"

USPLENGTH=$2000		;reserved area for USP, enlarge if necessary

JSRLIB:MACRO
	jsr	_LVO\1(a6)
	ENDM

JMPLIB:MACRO
        jmp    _LVO\1(a6)
        ENDM

; to get a longword without caring for alignment (68000)

GETLONG:MACRO
		move.b	(\1),\2
		lsl.l	#8,\2
		move.b	(1,\1),\2
		lsl.l	#8,\2
		move.b	(2,\1),\2
		lsl.l	#8,\2
		move.b	(3,\1),\2
		ENDM


LF_BUFSIZ = 3000
;-----------------------------------------------
; IN:	D0 = ULONG size of jmp table
;	D1 = ULONG size of variable area
;	A0 = CPTR  subsystem name
; OUT:	D0 = APTR  librarybase

_InitLibrary	movem.l	d0-d1/a0,-(a7)
		add.l	d1,d0
		move.l	#MEMF_CLEAR,d1	;changed by JOTD
		bsr	ForeignAllocMem
		move.l	d0,a0			;jmp table start
                move.l	d0,a1
		add.l	(a7),a1			;jmp table end

		lea	_LVOFail(pc),a2
.1		move.w	#$4EB9,(A0)+
		move.l	a2,(a0)+
		cmp.l	a0,a1
		bhi	.1
		move.l	(8,a7),-4(a0)		;name of library
		move.l	a0,(A7)			;library base
		move.l	a0,a1			;variables start
		add.l	(4,a7),a1		;variables end
.2		move.w	#$eeee,(a0)+
		cmp.l	a0,a1
		bhi	.2

		; sets listfiles buffer (if option is set)
		; if you don't set this option, this shortens the
		; slave by LF_BUFSIZ bytes (~3000)

		IFEQ	PATCH_DIRECTORY_STUFF-2
		lea	LF_BUF(pc),A0
		move.l	A0,D0
		lea	OSM_LISTFILES_BUFFER(pc),A0
		move.l	D0,(A0)		; Lock enabled for files/dirs
		ENDC

		IFEQ	PATCH_DIRECTORY_STUFF-1
		lea	OSM_LISTFILES_BUFFER(pc),A0
		move.l	#-1,(A0)	; Lock only enabled for files
		ENDC

		MOVEM.L	(A7)+,D0/D1/A0
		rts

MYRTZ:
	moveq.l	#0,D0
	rts

_dosbase:
	dc.l	0

; cannot call CacheClearU since we're in kick 1.3 !!!!

ForeignCacheFlush:
	movem.l	D0-D1/A0-A1,-(A7)
	move.l	_resload(pc),a1
	jsr	(resload_FlushCache,a1)
	movem.l	(A7)+,D0-D1/A0-A1
	rts

ForeignAllocMem:
	move.l	A6,-(A7)
	move.l	$4.W,A6
;;;	bset	#MEMB_CLEAR,D1	; forces clear for internal OSEmu calls
	JSRLIB	AllocMem
	move.l	(A7)+,A6
	RTS

ForeignFreeMem:
	move.l	A6,-(A7)
	move.l	$4.W,A6
	JSRLIB	FreeMem
	move.l	(A7)+,A6
	RTS



;>D0:SIZE
;>D1:CONDITIONS
;<D0:ADDY

_AllocVec:
	move.l	D2,-(A7)
	addq.l	#$4,D0	; adds bytes to store the size
	move.l	D0,D2	; saves size

	bsr	ForeignAllocMem
	tst.l	D0
	beq.b	.exit

	move.l	D0,A0	
	move.l	D2,(A0)		; save size at start of block

	; adds $4 to base address

	addq.l	#$4,D0
.exit:
	move.l	(A7)+,D2
	rts

;>A1:Start of block

_FreeVec:
	move.l	-(A1),D0	; gets block length
	bra	ForeignFreeMem


; sets program arguments
; < A0: program arguments (linefeed + 0 terminated)

SetArgsPtr:
	movem.l	A1,-(A7)
	lea	_args_ptr(pc),A1
	move.l	A0,(A1)
	movem.l	(A7)+,A1
	rts


; loads an executable by calling OSEmu LoadSeg()
;
; < A0: name of the executable
; > A1: start address (do a JSR (a1) to start the program)
;

LoadExecutable:
	bsr	LoadSegList
	LSL.L	#2,D0
	MOVE.L	D0,A1
	ADDQ.L	#4,A1
	rts

; loads an executable by calling OSEmu LoadSeg(), and returns seglist
;
; < A0: name of the executable
; > D0: seglist (BPTR)
;

LoadSegList:
	movem.l	A2-A6/D1-D7,-(A7)
	bsr	GetDosBase

	movem.l	A0,-(A7)
	MOVE.L	_resload(PC),A2
	JSR	(resload_GetFileSize,a2)
	movem.l	(A7)+,A0
	tst.l	D0
	bne	.found

	move.l	A0,-(A7)		; file name
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
.found:
	; copy program name in CLI structure

	move.l	A0,A2	; program name
	lea	_BCPL_CommandName(pc),A3
	lea	1(A3),A4
	moveq.l	#0,D0
.copyname
	move.b	(A2)+,(A4)+
	beq.b	.endcopy
	addq.l	#1,D0
	bra.b	.copyname
.endcopy
	move.b	D0,(A3)		; string length in bytes

	; calls dos.LoadSeg()

	MOVE.L	A0,D1
	JSRLIB	LoadSeg
	
	; initializes args_ptr with default value
	; caller must use SetArgsPtr to change it

	lea	_default_args(pc),A0
	bsr	SetArgsPtr

	; < D0: seglist

	movem.l	(A7)+,A2-A6/D1-D7
	rts

DosLibInit:
	;redirect doslib calls: open/oldopen/close/findtask

	move.l	4.W,a0
	add.w	#_LVOOpenLibrary+2,a0
	lea	_openlib_save(pc),a1
	move.l	(a0),(a1)
	lea	_openlib(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOOldOpenLibrary+2,a0
	lea	_oldopenlib_save(pc),a1
	move.l	(a0),(a1)
	lea	_oldopenlib(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOCloseLibrary+2,a0
	lea	_closelib_save(pc),a1
	move.l	(a0),(a1)
	lea	_closelib(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOOpenDevice+2,a0
	lea	_opendev_save(pc),a1
	move.l	(a0),(a1)
	lea	_opendev(pc),a1
	move.l	a1,(a0)

	; sets command name buffer in CLI structure
	; (now buffer is BCPL linked to the CLI structure)

	lea	_CLI_STRUCTURE(pc),A0
	lea	_BCPL_CommandName(pc),A1
	move.l	A1,D0
	lsr.l	#2,D0				; APTR -> BPTR
	move.l	D0,(cli_CommandName,A0)

	move.l	(4),a0
	add.w	#_LVOFindTask+2,a0
	lea	_findtask_save(pc),a1
	move.l	(a0),(a1)
	lea	_findtask(pc),a1
	move.l	a1,(a0)

	rts

_GetArgStr:
	move.l	_args_ptr(pc),D0
	rts

GetDosBase:
	movem.l	A0-A5/D0-D7,-(A7)
	bsr	DOSINIT
	move.l	D0,A6
	movem.l	(A7)+,D0-D7/A0-A5
	rts

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

_hexsearch:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts

; ------------------------------------

EnterDebugger:
	illegal
	rts

_LVOFail
		exg.l	d0,a6
		sub.l	d0,(a7)			;LVO
		exg.l	d0,a6
		subq.l	#6,(a7)
		move.l	(-4,a6),-(a7)		;name of library
_emufail
		pea	TDREASON_OSEMUFAIL
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

_opendev:
		movem.l	D2,-(a7)
		move.l	A0,D2		; save A0 (name)

		pea	.cont(pc)
		move.l	_opendev_save,-(a7)
		rts
.cont:
		tst.l	D0
		beq.b	.ok		; opened from ROM/RAM without trouble

		IFND	IGNORE_OPENLIB_FAILURE
		pea	1.W
		move.l	D2,-(A7)
		pea	TDREASON_OSEMUFAIL
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
		ENDC
.ok
		movem.l	(A7)+,D2
		rts

_openlib
		IFD	OPENLIB_IGNORE_VERSION
		moveq	#0,d0
		ENDC
		movem.l	D2/D3,-(a7)
		move.l	A1,D2		; save A1 (name)
		move.l	D0,D3		; save D0 (version required)
	
		IFD	KICKCD32
		IFNE	KICKSIZE-$40000

		IFND	USE_DISK_LOWLEVEL_LIB
		cmp.l	#"lowl",(a1)
		bne	.skiplowl

		movem.l	D1-A6,-(A7)
		bsr	LOWLINIT		; call dos.s init
		movem.l	(A7)+,D1-A6
		bra.b	.quit
.skiplowl
		ENDC
		ENDC

		cmp.l	#"free",(a1)
		bne	.skipfree

		movem.l	D1-A6,-(A7)
		bsr	FRANINIT		; call dos.s init
		movem.l	(A7)+,D1-A6
		bra.b	.quit
.skipfree
		cmp.l	#"nonv",(a1)
		bne	.skipnonv

		movem.l	D1-A6,-(A7)
		bsr	NONVINIT		; call dos.s init
		movem.l	(A7)+,D1-A6
		bra.b	.quit
.skipnonv
		ENDC

		GETLONG	A1,D1
		cmp.l	#"dos.",D1
		bne	.org
		movem.l	D1-A6,-(A7)
		bsr	DOSINIT		; call dos.s init
		movem.l	(A7)+,D1-A6
		bra.b	.quit

.org
		pea	.cont(pc)
		move.l	_openlib_save,-(a7)
		rts
.cont:
		tst.l	D0
		bne.b	.ok		; opened from ROM/RAM without trouble
	
		IFD	ENABLE_DISK_LIBRARIES
		move.l	d2,a1
		move.l	d3,d0
		bsr	_install_disklib
		ENDC

		IFND	IGNORE_OPENLIB_FAILURE
		tst.l	D0
		bne.b	.ok

		pea	1.W
		move.l	D2,-(A7)
		pea	TDREASON_OSEMUFAIL
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
		ENDC
.ok
.quit
		movem.l	(A7)+,D2/D3
		tst.l	D0
		rts

_findtask	cmp.l	#"dos.",(a1)
		bne	.org
		movem.l	D1-A6,-(A7)
		bsr	DOSINIT		; call dos.s init
		movem.l	(A7)+,D1-A6
		rts

.org		move.l	_findtask_save,-(a7)
		rts

_oldopenlib	GETLONG	A1,D0
		cmp.l	#"dos.",D0
		bne	.org
		movem.l	D1-A6,-(A7)
		bsr	DOSINIT		; call dos.s init
		movem.l	(A7)+,D1-A6
		rts

.org		move.l	_oldopenlib_save,-(a7)
		rts

; < A1: name
; < D0: version

_install_disklib:
	lea	-40(A7),A7
	move.l	A7,A0
	move.l	#':lib',(A0)+
	move.w	#'s/',(a0)+
.copy
	move.b	(a1)+,(a0)+
	bne.b	.copy

	move.l	A7,D1
	move.l	A6,-(A7)
	move.l	_dosbase(pc),a6
	jsr	_LVOLoadSeg(a6)	; load library segments
	move.l	(A7)+,A6
	tst.l	D0
	beq.b	.out		; lib not found

	add.l	D0,D0
	add.l	D0,D0

	move.l	D0,D1		; seglist
	move.l	D0,A1

.illsrch:
	move.w	(A1)+,D0
	cmp.w	#$4AFC,D0
	bne.b	.illsrch
	subq.l	#2,A1		; struct ROMTag
	move.l	$4.W,A6
	jsr	_LVOInitResident(a6)
	; > D0: library base

	; workaround for kickstart 1.3

	ifeq	KICKSIZE-$40000
	; perform a LVOOpenLibrary
	lea	6(A7),A1		; skip ":libs/" dirname
	jsr	_LVOOpenLibrary(a6)
	ENDC

.out
	lea	40(A7),A7
	rts

_closelib	
		IFD	KICKCD32
		IFND	USE_DISK_LOWLEVEL_LIB
		move.l	_lowlbase(pc),D0
		cmp.l	A1,D0		; lowlevellib ?	
		beq.b	.fake
		ENDC
		move.l	_franbase(pc),D0
		cmp.l	A1,D0		; freeanimlib ?	
		beq.b	.fake
		move.l	_nonvbase(pc),D0
		cmp.l	A1,D0		; nonvolatilelib ?	
		beq.b	.fake
		ENDC
		move.l	_dosbase(pc),D0
		cmp.l	A1,D0		; doslib ?
		bne	.org
.fake
		moveq	#0,D0		; close doslib does nothing!
		rts

.org		move.l	_closelib_save,-(a7)
		rts

	include	"dos.s"

_dosname:
	dc.b	"dos.library",0
	even

_openlib_save	dc.l	0
_oldopenlib_save	dc.l	0
_closelib_save	dc.l	0
_findtask_save	dc.l	0
_opendev_save	dc.l	0

OSM_OPEN_CREATE_EMPTY_FILES:
	IFD	CREATE_EMPTY_FILES
	dc.l	-1
	ELSE
	dc.l	0
	ENDC

OSM_LISTFILES_BUFFER:
	dc.l	0
OSM_LISTFILES_SIZE
	IFEQ	PATCH_DIRECTORY_STUFF-2	; mode: full dir and file lock/examine
	dc.l	LF_BUFSIZ
LF_BUF:
	ds.b	LF_BUFSIZ
	ELSE
	dc.l	0
	ENDC

	CNOP	0,4	; must be longword aligned, because pointed by a BCPL pointer

_CLI_STRUCTURE	DC.L	0
		DC.L	$EEEEE1E/4	; /4 because if accessed it's in BCPL
		DC.L	$EEEEEE2
		DC.L	0		; returncode
		DC.L	$ABCDABCD	; command name
		DC.L	20		; fail level
		DC.L	$EEEEEE3	; prompt
		DC.L	$EEEEEE4	; standard input
		DC.L	$EEEEEE5	; current input
		DC.L	$EEEEEE6	; command file
		DC.L	0		; interactive
		DC.L	0		; background
		DC.L	OUTPUT_HANDLER_MAGIC	; output
		DC.L	(USPLENGTH-$20)/4	; default stack (in longwords)
		DC.L	OUTPUT_HANDLER_MAGIC	; output
		DC.L	$EEEEEE8		; module

	CNOP	0,4	; BCPL pointer
_BCPL_CommandName
		blk.b	$40,0	; BSTR (size, and then contents)
_default_args
	dc.b	10,0		; linefeed
_args_ptr:
	dc.l	0
	dc.b	"KickDOS by JOTD",0
	even
