;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
* $Id: dos.s 1.1 1999/02/03 04:09:58 jotd Exp $
**************************************************************************
*   DOS-LIBRARY                                                          *
**************************************************************************
;
;
;       20.01.2002 JOTD fixed a bug in LoadSeg: crashed if file not found
;
; NOTE FROM JOTD: With WHDLoad, OSEmu behaves well, but when there are
; directories or zero-length files involved, then
;  Lock(), Open(), CurrentDir(), etc... may fail if some precautions
; are not taken:
;
; - If a dir is locked by the game, ensure that there is at least 1 file inside
;   If there are only directories in it, it will be ignored
; - If a dir is locked by the game, you cannot possibly set the NoError whdload
;   flag because WHDLoad would fail at the GetFileSize on the directory name
;   (because OSEmu cannot know if it is a file or a directory)
; - If the installed game has empty files (put there to tell the game that such
;   or such disk is inserted, or that the game is in HD mode), an Open or Lock
;   performed on them tells that they don't exist because WHDLoad ignores zero-length
;   files (a very annoying limitation). You have to modify the
;   install script and replace the zero-length file by a 1 byte file. The game
;   will of course ignore the contents, but testing the file with Lock or Open
;   will work.
; - If an Examine is performed on a directory, you've got to set the buffer and
;   length in OSEmu base structure (see offsets in OSEmu.asm)
;
; structure for custom filehandle

	include	"whdmacros.i"

FH_ALLOCLEN = 0
FH_PORT = 4		; exact DOS offset in FileHandle structure
FH_TYPE = 8		; exact DOS offset in FileHandle structure
FH_TASK = 12		; exact (FileLock) offset in FileLock structure (hack!)
FH_VOLUME = 16		; exact (FileLock) offset in FileLock structure
FH_FILELEN = $14	; exact DOS offset in FileHandle structure
FH_WRITEBUFPTR = $18	; buffer pointer
FH_WRITEBUFPOS = $1C	; current buffer position
FH_WRITEBUFLEN = $20	; total length of buffer
FH_WRITESTARTPOS = $24	; the file offset which corresponds to start of write buffer
FH_DIRLISTSTART = $28	; for directories, pointer on first item
FH_OPENMODE = $2C	; open mode, read or write
FH_CURRENTPOS = $30	; current file position
FH_FILENAME = $34	; filename (for locks, real locked name follows null char)

DEFAULT_WRITE_BUFSIZE = 2000	; default 2ko bufferization for _Write

OUTPUT_HANDLER_MAGIC = $DEAF1111
MSGPORT_MAGIC = $C0DE2222

	IFD	OSEMU
CREATE_PROC_DEFINED = 1
	ENDC

BPTR2APTR:MACRO
	add.l	\1,\1
	add.l	\1,\1
	ENDM

APTR2BPTR:MACRO
	lsr.l	#2,\1
	ENDM

DOSRTS:MACRO
	move.l	D0,D1
	rts
	ENDM

EMBEDDED_WHDCALL:MACRO
	IFND	_my_\1
	jsr	(resload_\1,\2)
	ELSE
	bsr	_my_\1
	ENDC
	ENDM

	IFND	DOS_MULTITASK
	; normal call to resload functions
PROTECTED_WHDCALL:MACRO
	EMBEDDED_WHDCALL	\1,\2
	ENDM
	ELSE
	; kickdos: protected calls
PROTECTED_WHDCALL:MACRO
	bsr	LockWhdload
	EMBEDDED_WHDCALL	\1,\2
	bsr	UnLockWhdload
	ENDM
	ENDC

**************************************************************************
*   INITIALIZING                                                         *
**************************************************************************

DOSINIT
		move.l	_dosbase(pc),d0
		beq	.init
		rts

.init
		movem.l	D1/A1-A4,-(a7)

		move.l	#1050,d0	;(reserved function)
		move.l	#$46,d1
		lea	_dosname(pc),a0
		bsr	_InitLibrary
		lea	_dosbase(pc),a0
		move.l	d0,(a0)
		move.l	d0,a0
		
		patch	_LVOParentDir(a0),_ParentDir	; requested by BS
		patch	_LVOLoadSeg(a0),_LoadSeg
		patch	_LVOUnLoadSeg(a0),_UnLoadSeg
		patch	_LVOOpen(a0),_Open		; patched to BCPL
		patch	_LVOOpenFromLock(a0),_OpenFromLock	; patched to BCPL
		patch	_LVOClose(a0),_Close		; patched to BCPL
		patch	_LVORead(a0),_Read		; patched to BCPL
		patch	_LVOWrite(a0),_Write		; patched to BCPL
		patch	_LVOSeek(a0),_Seek		; patched to BCPL
		patch	_LVOInput(A0),MYRTZ
		patch	_LVODeleteFile(A0),_DeleteFile
		patch	_LVOOutput(A0),_Output
		patch	_LVODeviceProc(A0),MYRTZ

		patch	_LVOSetIoErr(A0),_SetIoErr	; added by JOTD
		patch	_LVOIoErr(A0),_IoErr		; added by JOTD
		patch	_LVOUnLock(A0),_UnLock	; patched to BCPL
		patch	_LVOInfo(A0),_Info
		patch	_LVOCli(A0),_Cli		; added by JOTD (kickdos needs it now)
		patch	_LVOAddPart(A0),_AddPart	; added by JOTD (Gunship 2000 CD32)

		patch	_LVOIsInteractive(A0),_IsInteractive	; JOTD
		patch	_LVOCheckSignal(A0),MYRTZ	; JOTD, dummy
		patch	_LVOWaitForChar(A0),MYRTZ
		patch	_LVOAddBuffers(A0),_AddBuffers
		patch	_LVOCurrentDir(A0),_CurrentDir
		patch	_LVODelay(A0),_Delay	; added by JOTD
		patch	_LVODateStamp(A0),_DateStamp	; added by JOTD
		patch	_LVOAssignPath(a0),ASSIGNPATH	; dummy
		patch	_LVOAssignLock(a0),ASSIGNLOCK	; dummy
		patch	_LVOExecute(a0),EXECUTE ; added by JOTD
		patch	_LVONameFromLock(a0),_NameFromLock ; added by JOTD

		IFD	CREATE_PROC_DEFINED
		patch	_LVOCreateProc(a0),_CreateProc ; added by JOTD
		patch	_LVOGetArgStr(a0),_GetArgStr ; added by JOTD
		ENDC

		IFD	OSEMU
		patch	_LVORunCommand(a0),RUNCOMMAND ; added by JOTD
		ENDC

		patch	_LVOGetProgramDir(A0),_GetProgramDir	; added by JOTD
		patch	_LVOLock(A0),_Lock		; patched to BCPL
		patch	_LVOExamine(A0),_Examine	; patched to BCPL
		patch	_LVOExNext(A0),_ExNext		; added by JOTD, patched to BCPL
		patch	_LVOExamineFH(A0),_ExamineFH	; added by JOTD, patched to BCPL
		patch	_LVODupLock(A0),_DupLock	; patched to BCPL

		patch	_LVOFilePart(A0),_FilePart	; JOTD
		patch	_LVOSetVBuf(A0),MYRTZ
		patch	_LVOFRead(a0),_FRead

; init rootnode structure, and all linked structures
; with BCPL correction
		lea	_ROOTNODE(pc),a1
; init default dosinfo structure
		lea	_DEFAULT_DOSINFO(pc),a2
; init devlist structure
		lea	_DEVINFO(pc),a3
; init devname structure
		lea	_DEVNAME(pc),a4
		move.l	a4,D1
		APTR2BPTR	D1
		move.l	D1,dvi_Name(a3)

		lea	_DOSLIST(pc),a4
		move.l	D1,dol_Name(a4)	; sets device name here too

		lea	_FSSM(pc),a4
		move.l	a4,D1
		APTR2BPTR	D1
		move.l	D1,dvi_Startup(a3)
;
		move.l	a3,D1	
		APTR2BPTR	D1
		move.l	D1,di_DevInfo(a2)
;
		move.l	a2,D1
		APTR2BPTR	D1
		move.l	D1,rn_Info(a1)

;
		lea	_TRDNAME(pc),A4
		move.l	a4,D1
		APTR2BPTR	D1
		lea	_FSSM(pc),a3
		move.l	D1,fssm_Device(a3)

; set rootnode
		move.l	a1,dl_Root(A0)

		; cache flush (to be able to use function table at once)
.end
		bsr	ForeignCacheFlush

		movem.l	(A7)+,D1/A1-A4
		rts

_ROOTNODE:
	dc.l	$EEEEEE01
	dc.l	$EEEEEE02
	dc.l	$0		; datestamp
	dc.l	$0
	dc.l	$0
	dc.l	$EEEEEE03
	dc.l	$EA00EE11/4	; dos info
	

	dc.l	$EEEEEE04
	dc.l	$EEEEEE05
	dc.l	$EEEEEE06
	dc.l	$EEEEEE07
	dc.l	$EEEEEE08
	dc.l	$EEEEEE09
	dc.l	$EEEEEE0A	; to be continued...

	CNOP	0,4

_DEFAULT_DOSINFO:
	dc.l	$EEEEFFEE	; private
	dc.l	$EB00EEEE/4	; device list
	dc.l	0		; leave to zero
	dc.l	0		; leave to zero

	CNOP	0,4
_FSSM:
	dc.l	0		; unit 0
	dc.l	$EE11EE11	; device name (will be trackdisk.device)
	dc.l	$EE22EE22	; environment?
	dc.l	0		; flags
	
	CNOP	0,4

_DEVINFO:
	dc.l	0
	dc.l	0
	dc.l	MSGPORT_MAGIC
	dc.l	0
	dc.l	$EEEEEEEE	; normally BCPL pointer on BSTR "L:FastFileSystem"
	dc.l	1000		; stack size
	dc.l	5		; priority
	dc.l	0		; startup
	dc.l	$EEEEEE11
	dc.l	$EEEEEE12
	dc.l	$EC00EEEE/4	; device name

	CNOP	0,4
_DEVNAME:
	dc.b	3,"DH0",0		; BSTR on device name + NULL termination
	CNOP	0,4

_TRDNAME:
	dc.b	16,"trackdisk.device",0
	CNOP	0,4

_DOSLIST
	dc.l	0		; next: end
	dc.l	DLT_VOLUME	; type: volume
	dc.l	MSGPORT_MAGIC	; same msg port as other structures
	dc.l	$EEEE1111/4
	dc.l	$EEEE1121/4
	dc.l	$EEEE1131/4
	dc.l	$EEEE1141/4
	dc.l	$EEEE1151/4
	dc.l	$EEEE1161/4
	dc.l	$EEEE1171/4
	dc.l	$EEEE1181/4	; dol_Name (BSTR)
	CNOP	0,4

**************************************************************************
*   PROGRAM EXECUTION                                                    *
**************************************************************************

; EXECUTE
; <D1: program name
; <D2: input handler
; <D3: output handler
; >D0: success

EXECUTE:
	move.l	D1,A0
	lea	.command(pc),A1
.copy
	; copy name until end or space
	move.b	(A0)+,D0
	cmp.b	#' ',D0
	bne.b	.skipspc
	moveq.l	#0,D0
.skipspc
	move.b	D0,(A1)+
	bne.b	.copy

	; now arguments

	lea	.args(pc),A0

	tst.b	(-1,A1)
	beq.b	.lf

.argcp
	move.b	(A1)+,(A0)+
	bne.b	.argcp

.lf
	move.b	#10,(A0)+	; adds linefeed
	clr.b	(A0)

	lea	.command(pc),A1
	move.l	A1,D1	
	JSRLIB	LoadSeg
	tst.l	D0
	beq.b	.err

	LSL.L	#2,D0
	MOVE.L	D0,A1
	ADDQ.L	#4,A1

	lea	.args(pc),A0
	moveq.l	#0,D0
.count
	tst.b	(A0,D0.W)
	beq.b	.exe
	addq.l	#1,D0
	bra.b	.count

.exe
	JSR	(A1)
	moveq.l	#DOSTRUE,D0	; success
	DOSRTS
.err
	moveq.l	#0,D0
	DOSRTS

.command:
	blk.b	$30,0	
.args:
	blk.b	$40,0

; GetArgStr, RunCommand and CreateProc code is osemu specific
; CreateProc and GetArgStr must be defined in kickdos somewhere if
; CREATE_PROC_DEFINED is set

	IFD	OSEMU

;<D1:NAME
;<D2:PRIORITY
;<D3:SEGLIST
;<D4:STACKSIZE
; this function never returns
;
; ATM this function is designed to handle
; autodetachable code, not for managing multiple tasks!!
; Successful with delphine games (Operation Stealth, Future Wars, Cruise For A Corpse)

_CreateProc:
	move.l	#0,_EXECLIBTASK+172	; now we're in the child process

	move.l	D4,D0
	move.l	#MEMF_CLEAR,D1
	bsr	ForeignAllocMem
	tst.l	D0
	beq	.cpfail		; not enough mem for stack

	move.l	D0,A7
	add.l	D4,A7		; sets new stack pointer

	LSL.L	#2,D3		; BCPL -> normal pointer
	MOVE.L	D3,A1
	ADDQ.L	#4,A1

	moveq.l	#0,D0	; I don't know why I'm doing this
	jmp	(A1)	; executes the program

.cpfail		pea	_LVOCreateProc
		pea	_dosname
		bra	_emufail


;<D1:SEGLIST
;<D2:STACKSIZE
;<D3:ARGPTR
;<D4:ARGSIZE

;RUNCOMMAND will ignore STACKSIZE: it will use the current stack

RUNCOMMAND:
	move.l	D3,args_ptr
;;	move.l	D4,D0

	LSL.L	#2,D1
	MOVE.L	D1,A1
	ADDQ.L	#4,A1

	jmp	(A1)	; executes the program

_GetArgStr:
	move.l	args_ptr(pc),D0
	RTS

args_ptr:
	dc.l	0
	ENDC


_SetIoErr:
	lea	last_io_error(pc),A0
	move.l	D1,(A0)
	DOSRTS

_IoErr:
	move.l	last_io_error(pc),D0
	DOSRTS

last_io_error:
	dc.l	0

; ******************************************
; 2 special macros added by JOTD for LoadSeg

; calls EnterDebugger when a condition is reached:

BREAK_ON_COND:MACRO
	cmp.l	\1,\2
	bne.b	.ok\@
	bsr	EnterDebugger
	nop
	nop
.ok\@
	ENDM

; branch with call to EnterDebugger when true
; (to trap error code source)

; uncomment to activate

	ifeq	1
BRANCH_COND:MACRO
	\1	.sk\@
	bra.b	.end\@
.sk\@
	illegal
	bsr	EnterDebugger
	bra	\2
.end\@
	ENDM
	ENDC
;	ifeq	1
BRANCH_COND:MACRO
	\1	\2	; this is the non-debug configuration
	ENDM
;	ENDC

;<D1: filename
;>D0: return code

_DeleteFile:
	move.l	D1,A0
	bsr	SetCurrentDir
	move.l	_resload(pc),a1
	PROTECTED_WHDCALL	DeleteFile,a1
	bsr	_SetIoErr
	DOSRTS

;>D1:FILENAME
;<D0:FIRST SEGMENT
;INTERNAL: D7-TOTAL # OF SEGMENTS
;	D6-FILEHANDLE
;	D5-SEGMENTBASE
;	A4-8 BYTES SPACE ON STACK FOR HUNKHEADERS+other space for hunk overlay stuff
;LIMITATIONS: ONLY FOLLOWING HUNKS ALLOWED: HUNK_CODE, HUNK_DATA, HUNK_BSS,
;		HUNK_END, HUNK_RELOC32, HUNK_HEADER, HUNK_DEBUG, HUNK_SYMBOL,
;               HUNK_OVERLAY
;               CONTACT IF YOU HAVE AN EXE WITH OTHER HUNKS, IM SIMPLY MISSING 
;		THE EXAMPLES TO IMPLEMENT THEM

OVY_OVERLAYTABLE = 8
OVY_HUNKTABLE = 12
MAX_HUNK_NUMBER = 16
LAST_LOADED_HUNK_NUMBER = 20
FIRST_HUNK_NUMBER = 24

_LoadSeg:
	MOVEM.L	D2-D7/A2-A5,-(A7)

	; allocates some memory from the stack

	SUB.L	#FIRST_HUNK_NUMBER+4,A7
	MOVE.L	A7,A4

	CLR.L	(A4)+	; not overlay ATM
	CLR.L	(A4)+	; not overlay load ATM
	CLR.L	(A4)+
	CLR.L	(A4)+
	CLR.L	(A4)+
	MOVE.L	A7,A4

	tst.l	D1
	bne.b	.normal_call

	; undocumented LoadSeg() call to load the overlay part
	; D1: NULL
	; D2: BPTR on hunk table to complete
	; D3: filehandle

	move.l	D2,(OVY_HUNKTABLE,A4)	; save hunk table
	move.l	D3,D0
	bra.b	.read_header
	
.normal_call
	move.l	D1,A5		; save filename
	MOVE.L	#MODE_OLDFILE,D2
	jsr	_LVOOpen(A6)
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR

	IFD	OSEMU

	; added by JOTD: copy command name & length

	lea	_BCPL_CommandName(pc),A3
	moveq.l	#0,D1
.strcp
	addq.l	#1,D1
	move.b	(A5)+,(A3,D1.W)
	beq.b	.endcp
	bra.b	.strcp
.endcp
	lea	_BCPL_CommandName,A3
	subq.l	#1,D1
	move.b	D1,(A3)			; store length
	ENDC

.read_header:
	MOVE.L	D0,D6			; handler
	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR2
	CMP.L	#$3F3,(A4)		;FIRST LW=HUNK_HEADER?
	BRANCH_COND	BNE.W,.ERR2
	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR2
	TST.L	(A4)			;NO NAME PLEASE (feature removed in OS2.0)
	BRANCH_COND	BNE.W,.ERR2
	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR2
	MOVE.L	(A4),(MAX_HUNK_NUMBER,A4)	; highest hunk in file

	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#8,D3
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR2
	MOVE.L	(A4),(FIRST_HUNK_NUMBER,A4)		;0 but for overlays
;	TST.L	(A4)			;FIRST HUNK HAS TO BE 0
;	BRANCH_COND	BNE.W,.ERR2

	MOVE.L	4(A4),(LAST_LOADED_HUNK_NUMBER,A4)	;LAST LOADED HUNK (means: overlay not included)

; loop for all hunks which are to be loaded (don't consider overlays)

	move.l	(LAST_LOADED_HUNK_NUMBER,A4),D7
	sub.l	(FIRST_HUNK_NUMBER,A4),D7

	MOVEQ.L	#0,D4			;ALLOC MEM FOR ALL SEGMENTS
	MOVEQ.L	#0,D5

.1

	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3			;GET SIZE AND MEMFLAGS OF HUNK
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3

	MOVE.L	(A4),D0

	; added by JOTD: check memtype requirement

	bsr	.getmemflag	; >D1: MEMF_xxx

	; compute mem size

	LSL.L	#2,D0
	ADDQ.L	#8,D0
	MOVE.L	D0,D2			;ALLOC MEM IN SIZE
	ADDQ.L	#7,D0
	AND.L	#$FFFFFFF8,D0
	BSR.W	ForeignAllocMem
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3
	MOVE.L	D0,A3
	MOVE.L	D2,(A3)
	CLR.L	4(A3)

	TST.L	D4
	BNE.S	.2
	MOVE.L	D0,D5			;D5-POINTER TO 1ST SEGMENT
	BRA.S	.3

.2
	MOVE.L	D5,A3			;POINTER TO 1ST SEGMENT
.5	TST.L	4(A3)
	BEQ.S	.4
	MOVE.L	4(A3),D2		;NEXT SEGMENT
	LSL.L	#2,D2
	SUBQ.L	#4,D2
	MOVE.L	D2,A3
	BRA.S	.5


.4	ADDQ.L	#4,D0
	LSR.L	#2,D0
	MOVE.L	D0,4(A3)
.3	ADDQ.L	#1,D4
	CMP.L	D7,D4
	BLS.S	.1			; next hunk
					;HEADER COMPLETE, MEM ALLOCATED

	;NOW PROCESSING THE HUNK_CODE, HUNK_DATA AND HUNK_BSS, HUNK_OVERLAY...

	move.l	(MAX_HUNK_NUMBER,A4),D7 ; real hunk count (including overlays)
	sub.l	(FIRST_HUNK_NUMBER,A4),D7	; remove first hunk offset
	subq.l	#1,D7
	bpl.s	.d7positive
	moveq.l	#0,D7
.d7positive

	MOVEQ.L	#0,D4
.HN	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3			;GET TYPE OF HUNK
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3	;END OF FILE ENCOUNTERED
.MAINHUNKS:
	AND.L	#$3FFFFFFF,(A4)
	CMP.L	#$3E9,(A4)		;HUNK_CODE?
	BEQ.W	.HCD
	CMP.L	#$3F1,(A4)		;HUNK_DEBUG?
	BEQ.S	.HDEBUG1
	CMP.L	#$3EA,(A4)		;HUNK_DATA?
	BEQ.S	.HCD
	CMP.L	#$3EB,(A4)		;HUNK_BSS?
	BEQ.S	.HBSS
	CMP.L	#$3F5,(A4)		;HUNK_OVERLAY?
	BEQ.W	.HOVLY
	CMP.L	#$3F2,(A4)		;HUNK_END?
	BEQ.W	.HN			;empty: continue (bootscr of Marble Madness)
	BRANCH_COND	BRA.W,.ERR3

	; debug hunk support, added by JOTD
.HDEBUG1:
	bsr.s	.HDEBUG
	BRA.W	.HN

.HDEBUG2
	bsr.s	.HDEBUG
	bra	.INNERHUNK
	
.HDEBUG:
	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3
	BSR.W	_Read			;GET HUNK LENGTH
	MOVE.L	(A4),D0

	BPTR2APTR	D0

	MOVE.L	D6,D1
	MOVE.L	D0,D2
	MOVE.L	#OFFSET_CURRENT,D3
	BSR.W	_Seek			;SKIP DEBUG DATA
	CMP.L	#-1,D0			;error
	BRANCH_COND	BEQ.W,.ERR3
	RTS

.HBSS	
	MOVE.L	D6,D1			;BSS-HUNK
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3			;IGNORE SIZE OF HUNK
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3
	BRA.S	.INNERHUNK

.HCD
	MOVE.L	D6,D1			;CODE- AND DATA-HUNK
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3			;GET SIZE OF HUNK
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3
	MOVE.L	(A4),D3			;LEN OF HUNK
	beq	.INNERHUNK		; added by JOTD, hunk code can be of 0 length
	LSL.L	#2,D3
	MOVE.L	D4,D1			;ACTUAL HUNK
	MOVE.L	D5,A3			;START OF 1ST SEGMENT
	BRA.S	.HCD1

.HCD2	MOVE.L	4(A3),D2
	LSL.L	#2,D2
	SUBQ.L	#4,D2
	MOVE.L	D2,A3
.HCD1	DBF	D1,.HCD2
	MOVE.L	A3,D2
	ADDQ.L	#8,D2
	MOVE.L	D6,D1

	
	move.l	D2,-(A7)	; save D2
	BSR.W	_Read
	move.l	(A7)+,D2	; restore D2
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3

	; OVERLAY? hunk code loaded:
	; let's check if it's an overlay manager

	move.l	D2,A0
	cmp.w	#$6000,(A0)
	bne.b	.INNERHUNK	; not an overlay manager
	cmp.l	#$ABCD,(4,A0)
	bne.b	.INNERHUNK	; not an overlay manager

	; save overlay manager offset

	addq.l	#8,A0
	move.l	A0,(OVY_OVERLAYTABLE,A4)

	; END OVERLAY?
	; continue hunk processing

.INNERHUNK:
	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3			;GET TYPE OF HUNK
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3
	CMP.L	#$3EC,(A4)		;HUNK_RELOC32?
	BEQ.S	.HRELOCT
	CMP.L	#$3F2,(A4)		;HUNK_END?
	BEQ.W	.HENDT
	CMP.L	#$3F0,(A4)		;HUNK_SYMBOL?
	BEQ.W	.HSYMBOLT
	CMP.L	#$3F1,(A4)		;HUNK_DEBUG?
	BEQ.W	.HDEBUG2
	BRANCH_COND	BRA.W,.ERR3

.HRELOCT
	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3			;GET COUNT OF LW-RELOCS
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3
	TST.L	(A4)			;END OF RELOCATION?
	BEQ.S	.INNERHUNK
	MOVE.L	D6,D1
	MOVE.L	A4,D2
	ADDQ.L	#4,D2
	MOVEQ.L	#4,D3			;GET CORRESPONDING HUNK TO RELOCATE TO
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3

	MOVE.L	(A4),D0

	bsr	.getmemflag

	LSL.L	#2,D0			;ALLOC MEM OF SIZE OF RELOCTABLE
	ADDQ.L	#7,D0
	AND.L	#$FFFFFFF8,D0

	BSR.W	ForeignAllocMem
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR4
	MOVE.L	D0,A2
	MOVE.L	D6,D1
	MOVE.L	A2,D2
	MOVE.L	(A4),D3			;GET CORRESPONDING RELOCS TO RELOCATE
	LSL.L	#2,D3
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR4
	MOVE.L	(A4),D3			;# OF RELOCS
	MOVE.L	4(A4),D2		;WHICH HUNK TO RELOCATE TO?
	MOVE.L	D5,A0
	BRA.S	.HRELOCT3

.HRELOCT4
	MOVE.L	4(A0),D0
	LSL.L	#2,D0
	SUBQ.L	#4,D0
	MOVE.L	D0,A0
.HRELOCT3
	DBF	D2,.HRELOCT4		

	ADDQ.L	#8,A0
	MOVE.L	A0,D0			;GOT THE HUNK TO RELOCATE TO
	LEA.L	8(A3),A1		;THIS HUNK WILL BE RELOCATED
	MOVE.L	A2,A0			;HERE ARE THE RELOCS
	BRA.S	.HRELOCT5

.HRELOCT6
	MOVE.L	(A0)+,D1
	ADD.L	D0,(A1,D1.L)
.HRELOCT5
	DBF	D3,.HRELOCT6
	MOVE.L	A2,A1			;FREE THE MEM OF SIZE OF RELOCTABLE
	MOVE.L	(A4),D0
	LSL.L	#2,D0
	ADDQ.L	#7,D0
	AND.L	#$FFFFFFF8,D0

	bsr	ForeignFreeMem

	BRA.W	.HRELOCT

.HSYMBOLT
	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3
	BSR.W	_Read			;GET NAMELENGTH
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3
	MOVE.L	(A4),D0
	AND.L	#$FFFFFF,D0
	BEQ.W	.INNERHUNK		;IF NO NAMELENGTH -> END OF HUNK
	LSL.L	#2,D0			;LEN OF NAME IS IN LONGWORDS
	ADDQ.L	#4,D0			;SKIP ALSO SYMBOLOFFSET
	MOVE.L	D6,D1
	MOVE.L	D0,D2
	MOVE.L	#OFFSET_CURRENT,D3
	BSR.W	_Seek
	CMP.L	#-1,D0
	BRANCH_COND	BEQ.W,.ERR3
	BRA.S	.HSYMBOLT

	; overlay hunk support, added by JOTD
.HOVLY:
	; overlay file detected!
	; fill in the information needed

	; reads number of longwords - 1

	MOVE.L	D6,D1
	MOVE.L	A4,D2
	MOVEQ.L	#4,D3			;GET TYPE OF HUNK
	BSR.W	_Read
	TST.L	D0
	BRANCH_COND	BEQ.W,.ERR3	;END OF FILE ENCOUNTERED
	move.l	(A4),D0			;number of longwords that follow minus one
	addq.l	#1,D0

;	cmp.l	#5,D0			; too complex: not supported right now
;	BRANCH_COND	BNE.W,.ERR3

	add.l	D0,D0
	add.l	D0,D0
	move.l	D0,D3		; save size
	moveq.l	#0,D1		; any memory
	
	move.l	A6,-(A7)
	move.l	$4.W,A6
	bsr	_AllocVec
	move.l	(A7)+,A6

	move.l	D0,D2		; buffer
	BRANCH_COND	BEQ.W,.ERR3

	move.l	(OVY_OVERLAYTABLE,A4),A0
	move.l	D6,(A0)		; stream on executable file
	move.l	D0,(4,A0)	; overlay table pointer

	; D3: saved size
	move.l	D2,D0
	MOVE.L	D6,D1	; handler
	BSR.W	_Read			;LOAD LONGWORDS

	move.l	(MAX_HUNK_NUMBER,A4),D0
	addq.l	#1,D0
	add.l	D0,D0
	add.l	D0,D0
	moveq.l	#0,D1		; any memory

	move.l	A6,-(A7)
	move.l	$4.W,A6
	bsr	_AllocVec
	move.l	(A7)+,A6

	BRANCH_COND	BEQ.W,.ERR3	;no more mem!

	move.l	(OVY_OVERLAYTABLE,A4),A0
	lsr.l	#2,D0
	move.l	D0,(8,A0)	; hunk table pointer, to fill in the end
	move.l	#-1,($C,A0)	; invalid GlobalVec (unused by non-BCPL programs)

	; stop file parsing from here, exit, without closing file

	bra.b	.END_NOCLOSE
.HENDT
	ADDQ.L	#1,D4
	CMP.L	D7,D4
	BLS.W	.HN

	tst.l	(OVY_HUNKTABLE,A4)
	bne.b	.END_NOCLOSE	; overlay: don't close file

.END
	MOVE.L	D6,D1
	BSR.W	_Close
.END_NOCLOSE
	MOVE.L	D5,D0
	ADDQ.L	#4,D0

	IFD	OSEMU
	MOVE.L	D0,OSM_LASTLOADSEG
	LSR.L	#2,D0
	move.l	D0,LastSegList			; added by JOTD
	move.l	D0,LastSegList2			; added by JOTD
	ELSE
	LSR.L	#2,D0
	ENDC

	move.l	(OVY_HUNKTABLE,A4),A0
	cmp.l	#0,A0
	beq.b	.tryovy

	add.l	(FIRST_HUNK_NUMBER,A4),A0

	; just loaded an overlay hunk by the undocumented call to LoadSeg() with D1=0
	; search for zero

	add.l	A0,A0
	add.l	A0,A0
;.zsearch
;	tst.l	(A0)+
;	bne.b	.zsearch
;.zfound:
;	subq.l	#4,A0

	bra.b	.fillhunktable

	; A0 points now to an empty space to fill in

.tryovy:
	move.l	(OVY_OVERLAYTABLE,A4),A0
	cmp.l	#0,A0
	beq.b	.noovy

	; overlay: fill in the list with hunk list

	move.l	(8,A0),D5
	add.l	D5,D5
	add.l	D5,D5
	move.l	D5,A0	; real pointer on seglist
.fillhunktable:
	move.l	D0,D5
.hunkstrloop:
	move.l	D5,(A0)+
	beq.b	.noovy
	add.l	D5,D5
	add.l	D5,D5	
	move.l	D5,A1
	move.l	(A1),D5
	bra.b	.hunkstrloop

.noovy

	move.l	_resload(pc),a2
	jsr	(resload_FlushCache,a2)		; added by JOTD: cache flush
.exit
	ADD.L	#FIRST_HUNK_NUMBER+4,A7		; restores stack
	MOVEM.L	(A7)+,D2-D7/A2-A5
	DOSRTS

.ERR4
.ERR3
.ERR2
	pea	_LVOLoadSeg
	pea	_dosname(pc)
	bra	_emufail

;	MOVE.L	D6,D1
;	BSR.W	_Close
.ERR	MOVEQ.L	#0,D0

	bra.b	.exit

; utility routines used by LoadSeg()

.getmemflag:
	btst	#HUNKB_CHIP,D0			; CHIPMEM required?
	beq.b	.nochip

	move.l	#MEMF_CHIP,D1
	bra.b	.doalloc
.nochip
	btst	#HUNKB_FAST,D0			; FASTMEM required?
	beq.b	.nofast

	move.l	#MEMF_FAST,D1
	bra.b	.doalloc

.nofast
	MOVEQ.L	#MEMF_ANY,D1			;any memtype will do
.doalloc
	bset	#MEMB_CLEAR,D1			;adds CLEAR flag
	rts

; UnLoadSeg()

_UnLoadSeg:
	MOVE.L	A2,-(A7)
	LSL.L	#2,D1
.1	MOVE.L	D1,A1
	MOVE.L	(A1),D1
	LSL.L	#2,D1
	MOVE.L	D1,A2

	SUBQ.L	#4,A1
	MOVE.L	(A1),D0

	bsr	ForeignFreeMem

	MOVE.L	A2,D1
	BNE.S	.1

	MOVEQ.L	#0,D0
	MOVE.L	(A7)+,A2
	DOSRTS

**************************************************************************
*   I/O FILE FUNCTIONS                                                   *
**************************************************************************

;will not work properly if the program assigns a subdir
;I (JOTD) added it for SlamTilt, which only assigns to PROGDIR:
;so it's OK

ASSIGNLOCK:
	moveq.l	#1,D0
	RTS

;will not work properly if the program assigns a subdir
;I (JOTD) added it for SlamTilt, which only assigns to PROGDIR:
;so it's OK

ASSIGNPATH:
	moveq.l	#1,D0
	RTS

; added by JOTD

_GetProgramDir:
	lea	.volname(pc),A1
	move.l	D1,A1
	bsr	_Lock
	RTS
.volname:
	dc.b	"PROGDIR:",0
	even


;Note: open strips the device from the filename (avoiding problems with assigns)
; < D1: filename
; < D2: openmode
; > D0: BPTR on filehandle

_Open:
	MOVEM.L	D4-D5/A3-A5,-(A7)
	MOVE.L	D1,A3			; filename

	; JOTD: now skips '*' and CON:, RAW:... filenames (tries to open window)
	cmp.b	#'*',(A3)
	bne.b	.trycon
	tst.b	(1,A3)
	beq	.isstdout
.trycon
	move.b	(A3)+,D0
	lsl.l	#8,D0
	move.b	(A3)+,D0
	lsl.l	#8,D0
	move.b	(A3)+,D0
	lsl.l	#8,D0
	move.b	(A3)+,D0

	cmp.l	#'CON:',D0
	beq	.isstdout
	cmp.l	#'con:',D0
	beq	.isstdout
	cmp.l	#'RAW:',D0
	beq	.isstdout
	cmp.l	#'raw:',D0
	beq	.isstdout
	cmp.l	#'ENV:',D0		; denies
	beq	.filenotfound2
	cmp.l	#'env:',D0		; denies
	beq	.filenotfound2
	MOVE.L	D1,A3			; filename
.normal
	MOVEQ.L	#FH_FILENAME,D4			;HEADERLEN
	TST.B	(A3)
	BEQ.W	.ERR
.1	ADDQ.L	#1,D4
	TST.B	(A3)+
	BNE.S	.1
	ADDQ.L	#7,D4			;NEXT $8-BOUNDARY
	AND.L	#$FFFFFFF8,D4
	MOVE.L	D1,D5			;^NAME
	MOVE.L	D4,D0			;ALLOC. LENGTH
	MOVE.L	#MEMF_CLEAR,D1		;mem is better cleared
	BSR.W	ForeignAllocMem
	TST.L	D0
	BEQ.S	.ERR
	MOVE.L	D0,A3
	MOVE.L	D4,FH_ALLOCLEN(A3)			;ALLOC. LENGTH
	MOVE.L	D2,FH_OPENMODE(A3)		;OPENMODE
	CLR.L	FH_CURRENTPOS(A3)		;INFILE-POINTER TO 0
	move.l	#-1,FH_TYPE(A3)			;regular file
	; for buffered write
	clr.l	FH_WRITEBUFPTR(A3)
	clr.l	FH_WRITEBUFPOS(A3)
	clr.l	FH_WRITEBUFLEN(A3)
	clr.l	FH_WRITESTARTPOS(A3)

	; JOTD: cleaned up old Harry's devicename strip by calling my routine

	move.l	D5,A0
	nop
	nop
	nop
	nop
	
	bsr	SetCurrentDir
	lea	FH_FILENAME(A3),A4
.namecopy
	move.b	(A0)+,(A4)+
	bne.b	.namecopy

	CMP.W	#MODE_NEWFILE,D2	;IF MODE_NEWFILE, DELETE FILE
	BEQ.S	.NEWFILE

					;CHECK IF FILE EXISTS
	LEA.L	FH_FILENAME(A3),A0		;filename
	move.l	_resload(PC),a1
	PROTECTED_WHDCALL	GetFileSize,a1
	MOVE.L	D0,FH_FILELEN(A3)
	beq.b	.filenotfound

	MOVE.L	A3,D0
.END
	APTR2BPTR	D0	; BCPL conversion (JOTD)
	MOVEM.L	(A7)+,D4-D5/A3-A5
	DOSRTS

.filenotfound

	MOVE.L	A3,A1
	MOVE.L	FH_ALLOCLEN(A1),D0

	bsr	ForeignFreeMem
.filenotfound2:
	; sets DOS error code
	move.l	#ERROR_OBJECT_NOT_FOUND,D1
	bsr	_SetIoErr

.ERR	MOVEQ.L	#0,D0
	BRA.S	.END

.NEWFILE				;REDUCE FILE TO 0 BYTE
	CLR.L	FH_FILELEN(A3)
	LEA.L	FH_FILENAME(A3),A0

	move.l	OSM_OPEN_CREATE_EMPTY_FILES(pc),D0
	beq.b	.saveok

	MOVEQ.L	#0,D0
	LEA.L	$0.W,A1	; address is not important since we write 0 bytes

	move.l	_resload(pc),a5
	PROTECTED_WHDCALL	SaveFile,a5

	tst.l	D0
	beq.b	.saveok

	; cause of the error
	move.l	#ERROR_WRITE_PROTECTED,D1
	bsr	_SetIoErr
.saveok

.SKIPZFILE
	MOVE.L	A3,D0
	BRA.S	.END

.isstdout
	MOVEM.L	(A7)+,D4-D5/A3-A5
	bra	_Output

; fake output routine

; < D0: output file handler, actually a magic number
;       that Write will recognize

_Output:
	move.l	#OUTPUT_HANDLER_MAGIC,D0
	DOSRTS


_FRead:
	move.l	D3,-(A7)
	mulu	D4,D3
	bsr	_Read
	move.l	(A7)+,D3
	divu	D3,D0
	rts

; < D1: file handler
; < D2: destination buffer
; < D3: number of bytes to read
; > D0: number of bytes read

_Read:
	MOVEM.L	D3/A2-A3,-(A7)

	BPTR2APTR	D1

	MOVE.L	D1,A3
	MOVE.L	FH_CURRENTPOS(A3),D1		;OFFSET (current)
	MOVE.L	D2,A1			;DEST
	LEA.L	FH_FILENAME(A3),A0		;NAME
	MOVE.L	FH_FILELEN(A3),D0		;TOTAL LENGTH OF FILE
	SUB.L	D1,D0
	EXG	D3,D0
	CMP.L	D0,D3			;CMP REQUESTED/REAL
	BHI.S	.1			;IF REQUESTED<=REAL
	MOVE.L	D3,D0
.1	MOVE.L	D0,D3
					;LOAD IT
	MOVE.L	_resload(PC),A2

	PROTECTED_WHDCALL	LoadFileOffset,A2

	ADD.L	D3,FH_CURRENTPOS(A3)
	MOVE.L	D3,D0
	MOVEM.L	(A7)+,D3/A2-A3
	DOSRTS

; Write()
; <D1: filehandle
; <D2: source bytes
; <D3: length
;
; Jeff: added bufferized writes

_Write:
	cmp.l	#OUTPUT_HANDLER_MAGIC,D1	; try to write to output?
	beq	.fake_output

	; JOTD: restored old non-bufferized version

	MOVEM.L	D3-D4/A2-A3,-(A7)

	BPTR2APTR	D1		; APTR conversion (JOTD)

	MOVE.L	D1,A3
	MOVE.L	FH_CURRENTPOS(A3),D1		;OFFSET
	MOVE.L	D2,A1			;DEST
	LEA.L	FH_FILENAME(A3),A0		;NAME
	MOVE.L	D3,D0

	MOVE.L	_resload(PC),A2		;SAVE IT
	PROTECTED_WHDCALL	SaveFileOffset,A2
.SKIPWFILE:
	ADD.L	D3,FH_CURRENTPOS(A3)
	LEA.L	FH_FILENAME(A3),A0		;filename
	move.l	_resload(PC),a1
	PROTECTED_WHDCALL	GetFileSize,a1
	MOVE.L	D0,FH_FILELEN(A3)
	MOVE.L	D3,D0
	MOVEM.L	(A7)+,D3-D4/A2-A3
	DOSRTS

; let the program believe that it wrote into the console

.fake_output:
	move.l	D3,D0		; length written
	DOSRTS


;free allocated structure
_Close:
	cmp.l	#OUTPUT_HANDLER_MAGIC,D1
	beq	_DOSCLOSEMAGIC
	tst.l	D1
	beq	_DOSCLOSENULL
	BPTR2APTR	D1		; APTR conversion (JOTD)
	move.l	D1,A1
	APTR2BPTR	D1		; BCPL conversion (JOTD)

	move.l	FH_WRITEBUFPTR(A1),D0
	beq.b	_UnLock		; no write buffer

	move.l	D1,-(A7)
	move.l	D0,D1
	move.l	FH_WRITEBUFLEN(A1),D0
	move.l	D1,A1

	bsr	ForeignFreeMem

	move.l	(A7)+,D1

_UnLock:
	tst.l	D1
	beq	_DOSCLOSENULL

	BPTR2APTR	D1		; APTR conversion (JOTD)
	MOVE.L	D1,A1
	MOVE.L	FH_ALLOCLEN(A1),D0

	bsr	ForeignFreeMem

;	moveq.l	#DOSTRUE,D0
	moveq.l	#1,D0		; Mr Larmer asked that for Manhattan Dealers (Silmarils)
	DOSRTS

_DOSCLOSENULL:
	moveq.l	#0,D0
	DOSRTS

_DOSCLOSEMAGIC:
;	moveq.l	#DOSTRUE,D0
	moveq.l	#1,D0		; Mr Larmer asked that for Manhattan Dealers (Silmarils)
	DOSRTS

_Seek:
	BPTR2APTR	D1		; APTR conversion (JOTD)
	MOVE.L	D1,A1

	CMP.L	#OFFSET_BEGINNING,D3
	BEQ.S	.BEGM
	CMP.L	#OFFSET_END,D3
	BEQ.S	.ENDM
	CMP.L	#OFFSET_CURRENT,D3
	BEQ.S	.CURM
.ERR
	move.l	#ERROR_SEEK_ERROR,D1
	bsr	_SetIoErr
.exit
	DOSRTS

.CURM
	MOVE.L	FH_CURRENTPOS(A1),D0
	MOVE.L	D0,D1
	ADD.L	D2,D1
	CMP.L	FH_FILELEN(A1),D1
	BHI.S	.ERR
	MOVE.L	D1,FH_CURRENTPOS(A1)
	bra.b	.exit

.ENDM	MOVE.L	FH_CURRENTPOS(A1),D0
	MOVE.L	FH_FILELEN(A1),D1
	ADD.L	D2,D1
	CMP.L	FH_FILELEN(A1),D1
	BHI.S	.ERR
	MOVE.L	D1,FH_CURRENTPOS(A1)
	bra.b	.exit

.BEGM	MOVE.L	FH_CURRENTPOS(A1),D0
	MOVE.L	D2,D1
	CMP.L	FH_FILELEN(A1),D1
	BHI.S	.ERR
	MOVE.L	D1,FH_CURRENTPOS(A1)
	bra.b	.exit

; Added by JOTD. Now Flashback works
; <D2: info structure to fill in
; >D0: TRUE if success (which is always the case)

_Info:
	movem.l	A1,-(A7)
	move.l	D2,A1

	move.l	#0,(id_NumSoftErrors,A1)	; no errors!
	move.l	#0,(id_UnitNumber,A1)		; unit 0 should be OK
	move.l	#ID_VALIDATED,(id_DiskState,A1)	; disk validated
	move.l	#10000,(id_NumBlocks,A1)	; number of blocks = 500 Megs
	move.l	#ID_DOS_DISK,(id_DiskType,A1)	; disk type: OFS
	move.l	#0,(id_VolumeNode,A1)		; zero this entry. it sucks but...
	move.l	#0,(id_InUse,A1)		; not in use

	movem.l	(A7)+,A1
	moveq.l	#DOSTRUE,D0		; returns TRUE (success)
	DOSRTS

;;	IFEQ	1
_Delay:			; added by JOTD
	tst.l	D1
	beq.b	.exit
.loop
	waitvb
	subq.l	#1,D1
	bne.b	.loop
.exit
	rts
;;	ENDC

; make as if the clock was not set

_DateStamp:
	move.l	D1,A0
	clr.l	(A0)+
	clr.l	(A0)+
	clr.l	(A0)
	move.l	D1,D0
	rts

**************************************************************************
*   FILE MANAGEMENT FUNCTIONS                                            *
**************************************************************************

;filehandle represents the following structure (do not try to access it!):
;0-allocated len
;4-total filelength
;8-pointer in file
;$c-openmodus
;$10-filename

;if $10 of filehandle is a : its the volumelock
;atm: 0.L-<bufsiz> len, 4.W-# of file in examine/exnext (-1:invalid), 
;6.W-MAX# OF FILES, 8.L-pointer in table, $c.L-openmode

_Lock:
	MOVEM.L	D4-D5/A2-A5,-(A7)
	MOVE.L	D1,A3			; name
	MOVE.L	#FH_FILENAME,D4			;HEADERLEN
.1	ADDQ.L	#2,D4		; twice as big to hold both names
	TST.B	(A3)+
	BNE.S	.1
	ADDQ.L	#7,D4			;NEXT $8-BOUNDARY
	AND.L	#$FFFFFFF8,D4
	MOVE.L	D1,D5			;^NAME
	MOVE.L	D4,D0			;ALLOC. LENGTH


	MOVE.L	#MEMF_CLEAR,D1
	BSR.W	ForeignAllocMem
	TST.L	D0
	BEQ.S	.ERR

	MOVE.L	D0,A3
	MOVE.L	D4,FH_ALLOCLEN(A3)		;ALLOC. LENGTH
	bsr	.init_filelock_stuff

	MOVE.L	D2,FH_OPENMODE(A3)		;OPENMODE
	CLR.L	FH_CURRENTPOS(A3)		;INFILE-POINTER TO 0

	; JOTD: devicename strip cleaned up

	move.l	D5,A0
	bsr	SetCurrentDir

	lea	FH_FILENAME(A3),A4
.namecopy
	move.b	(A0)+,(A4)+
	bne.b	.namecopy

	move.l	D5,A0		; now copy real name
.namecopy2
	move.b	(A0)+,(A4)+
	bne.b	.namecopy2
	
	tst.b	FH_FILENAME(A3)
	beq.b	.VOLUMELOCK	; lock root directory


	;CHECK IF FILE EXISTS
	;(we need to know if we locked a file or a directory)
	;due to WHDLoad limitations, we've got to work around
	;the directory existence test problem

	LEA.L	FH_FILENAME(A3),A0		;filename
	move.l	_resload(PC),a1
	PROTECTED_WHDCALL	GetFileSize,a1
	MOVE.L	D0,FH_FILELEN(A3)

	TST.L	D0
	BEQ.S	.TRYDIR			;GetFileSize failed, maybe it's a directory...
	MOVE.L	A3,D0
.END
	MOVEM.L	(A7)+,D4-D5/A2-A5
	APTR2BPTR	D0		; BCPL conversion (JOTD)
	DOSRTS

.ERR	MOVEQ.L	#0,D0
	BRA.S	.END

; directory locked: rootdir locked

.VOLUMELOCK
	bsr	_getdirhandlesize
	MOVE.L	#MEMF_CLEAR,D1	; MEMF_CHIP removed
	BSR.W	ForeignAllocMem
	TST.L	D0
	BEQ.W	.ERR

	MOVE.L	A3,A4		; save old ptr

	MOVE.L	D0,A3
	CLR.B	FH_FILENAME(A3)		; no need for ':' anymore
	bsr	.init_filelock_stuff
	MOVE.L	D2,FH_OPENMODE(A3)
	MOVE.W	#-2,FH_FILELEN(A3)	; directory
					;8(A3) is already clear due MEMF_CLEAR

	exg.l	D0,A2
	bsr	_getdirhandlesize
	MOVE.L	D0,FH_ALLOCLEN(A3)
	exg.l	D0,A2

	; now copy full name information form old buffer to new buffer

	lea	FH_FILENAME(A4),A2
	lea	FH_FILENAME(A3),A3
.loop1
	move.b	(A2)+,(A3)+
	bne.b	.loop1
.loop2
	move.b	(A2)+,(A3)+
	bne.b	.loop2

	; now that we copied both names, free the old buffer area

	movem.l	D0,-(A7)	
	move.l	FH_ALLOCLEN(A4),D0
	move.l	A4,A1
	bsr	ForeignFreeMem
	movem.l	(A7)+,D0

	BRA.W	.END

.TRYDIR:
	LEA.L	FH_FILENAME(A3),A0		;filename
	bsr	SetCurrentDir
	move.l	_resload(PC),a2
	lea	.smallbuf(pc),A1
	moveq.l	#4,D0		; small buffer

	bsr	WHDListFiles

	tst.l	D0
	BEQ.S	.LOCKFAILED		; directory not found

	; directory found here

	MOVE.L	FH_ALLOCLEN(A3),D0	; free mem because we need a larger area
	MOVE.L	A3,A1			; JOTD: bugfix: changed D1 to A1
	bsr	ForeignFreeMem
.skipfree
	bsr	_getdirhandlesize
	MOVE.L	#MEMF_CLEAR,D1	; MEMF_CHIP removed
	BSR.W	ForeignAllocMem
	TST.L	D0
	BEQ	.ERR
	MOVE.L	D0,A3

	; copy directory name

	lea	FH_FILENAME(A3),A5
	move.l	A0,A4	; save A0

	move.l	D5,A0
	bsr	SetCurrentDir
.copy
	move.b	(A0)+,(A5)+
	bne.b	.copy

	move.l	A4,A0	; restore A0

	MOVE.L	D2,FH_OPENMODE(A3)
	MOVE.W	#-2,FH_FILELEN(A3)	; -2 for directory

					;8(A3) is already clear due MEMF_CLEAR
	exg	D0,D4
	bsr	_getdirhandlesize
	MOVE.L	D0,FH_ALLOCLEN(A3)	;stores allocated length
	exg	D0,D4
	BRA.W	.END

.smallbuf:
	ds.l	10,0

.LOCKFAILED
	MOVEQ.L	#0,D0
	; sets IoErr()
	move.l	#ERROR_DIR_NOT_FOUND,D1
	BSR	_SetIoErr
.FREEMEM
	MOVE.L	D0,D5
	MOVE.L	FH_ALLOCLEN(A3),D0
	MOVE.L	A3,A1			; bugfix there too

	bsr	ForeignFreeMem

	MOVE.L	D5,D0
	BRA.W	.END

.init_filelock_stuff:
	move.l	#MSGPORT_MAGIC,FH_TASK(A3)		;magic to find task (RocketRanger)
	movem.l	A0/D0,-(A7)
	lea	_DOSLIST(pc),A0
	move.l	A0,D0
	APTR2BPTR	D0
	move.l	D0,FH_VOLUME(A3)		; BPTR on _DOSLIST structure
	movem.l	(A7)+,A0/D0
	rts

; > D0: size of a directory handle (for allocation)

_getdirhandlesize:
	MOVE.L	OSM_LISTFILES_SIZE(pc),D0	; should be enough for directory stuff
	add.l	#FH_FILENAME+$100,D0		; margin
	rts

; OpenFromLock() acts just as DupLock(), but I will have to change this
; when we change filehandle structure to match the real one
; < D1: lock
; > D0: lock copy

_OpenFromLock:

_DupLock:
	TST.L	D1
	BEQ.S	.ROOTLOCK

	BPTR2APTR	D1

	MOVE.L	D1,-(A7)
	MOVE.L	D1,A0
	MOVE.L	FH_ALLOCLEN(A0),D0
	MOVE.L	#MEMF_CLEAR,D1
	BSR.W	ForeignAllocMem
	MOVE.L	(A7)+,A0
	TST.L	D0
	BEQ.S	.ERR
	MOVE.L	D0,A1
	MOVE.L	FH_ALLOCLEN(A0),D1
	SUBQ.L	#1,D1
.1	MOVE.B	(A0)+,(A1)+
	DBF	D1,.1
.EXIT
	APTR2BPTR	D0
	DOSRTS

.ERR	MOVEQ.L	#0,D0
	DOSRTS

; duplicate from no source

.ROOTLOCK
	MOVE.L	#FH_FILENAME+10,D0
	MOVE.L	#MEMF_CLEAR,D1
	BSR.W	ForeignAllocMem
	TST.L	D0
	BEQ.S	.ERR
	MOVE.L	D0,A0
	MOVE.L	#FH_FILENAME+10,FH_ALLOCLEN(A0)
	move.l	#-2,FH_FILELEN(A1)	; directory
	bra.b	.EXIT

; Examine next directory entry
; < D1: lock

_ExNext:
	MOVEM.L	A2-A3,-(A7)
	BPTR2APTR	D1

	; align D2 on longword boundary:
	; some buggy games don't pass aligned buffers, but then
	; expect that the data is written aligned (system converts pointer
	; into BCPL pointers in the meanwhile).

	APTR2BPTR	D2
	BPTR2APTR	D2

	move.l	D1,A3
	move.l	FH_CURRENTPOS(A3),A2

	tst.b	(A2)
	beq.b	.nomorefiles
	bsr	ExamineOneFile

	moveq.l	#DOSTRUE,D0		; ok
.exit
	MOVEM.L	(A7)+,A2-A3
	DOSRTS

.nomorefiles
	move.l	#ERROR_NO_MORE_ENTRIES,D1	; not really an error...
	bsr	_SetIoErr
	moveq.l	#0,D0
	bra.b	.exit

; < A3: filehandle
; > D0: 0 if OK, -1 if error

ExamineOneFile:
	move.l	FH_CURRENTPOS(A3),A1	; current file pointer
	lea	FH_FILENAME(A3),A0	; current directory lock name

	lea	.temp_buffer(pc),A2
	bsr	_AddPart

	lea	.temp_buffer(pc),A0
	MOVE.L	_resload(PC),A2
	PROTECTED_WHDCALL	GetFileSize,a2
	ADDQ.L	#1,FH_FILELEN(A3)	; 1 more file
	MOVE.L	D2,A2		; FIB

	TST.L	D0
	BNE.W	.isfile	; don't care about the errors (dir)
	MOVE.L	#ST_USERDIR,fib_DirEntryType(A2)	; directory
	MOVE.L	#ST_USERDIR,fib_EntryType(A2)	; directory
	bra.b	.fillname
.isfile

	MOVE.L	D0,fib_Size(A2)
	MOVE.L	#2,(A2)	
	MOVE.L	#ST_FILE,fib_DirEntryType(A2)	; regular file
	MOVE.L	#ST_FILE,fib_EntryType(A2)	; regular file
	SUBQ.L	#1,D0
	LSR.L	#8,D0			;ASSUMED FFS
	LSR.L	#1,D0
;	DIVU	#$1E8,D0		;WOULD BE OFS
	ADDQ.L	#1,D0
	MOVE.L	D0,fib_NumBlocks(A2)
.fillname:
	move.l	FH_CURRENTPOS(A3),A0	; current file pointer
	LEA.L	fib_FileName(A2),A1
.COPYFILENAME2
	MOVE.B	(A0)+,(A1)+
	TST.B	-1(A0)
	BNE.S	.COPYFILENAME2

	MOVE.L	A0,FH_CURRENTPOS(A3)		; UPDATE FILENAME POINTER
	moveq.l	#0,D0		; was OK
	RTS
.ERR
	MOVEQ.L	#-1,D0
	rts
.temp_buffer:
	blk.b	256,0

; < A0: dirname
; < A1: filename
; > A2: dirname/filename

_AddPart:
	movem.l	A0-A2,-(A7)
	clr.b	(A2)

	tst.b	(A0)
	beq.b	.cp_filename	; no dirname

.cp_dirname
	move.b	(A0)+,(A2)+
	bne.b	.cp_dirname

	subq.l	#1,A2

	cmp.b	#'/',(-1,A2)	; ends by /
	beq.b	.cp_filename

	move.b	#'/',(A2)+

.cp_filename
	move.b	(A1)+,(A2)+
	bne.b	.cp_filename

	movem.l	(A7)+,A0-A2
	RTS

; < D1: lock
; < D2: file info block

_Examine:
	MOVEM.L	A2-A4,-(A7)

	; align D2 on longword boundary:
	; some buggy games don't pass aligned buffers, but then
	; expect that the data is written aligned (system converts pointer
	; into BCPL pointers in the meanwhile).

	APTR2BPTR	D2
	BPTR2APTR	D2


	BPTR2APTR	D1

	MOVE.L	D1,A3

	cmp.w	#-2,FH_FILELEN(A3)
	bne.b	.ONEFILE

.DIRECTORY:
.VOLUME:
	; volume (current dir)/dir lock
	; skip the directory name

	LEA.L	FH_FILENAME(A3),A2
.zerohunt
	tst.b	(A2)+
	bne.b	.zerohunt
	move.l	A2,FH_DIRLISTSTART(A3)
	LEA.L	FH_FILENAME(A3),A1
	move.l	A2,A4
	sub.l	A1,A4
	
	; clear the filelist zone

	move.l	OSM_LISTFILES_SIZE(pc),D0
	sub.l	#FH_FILENAME-1,D0
	sub.l	A4,D0
	move.l	D0,D1		; save buffer length
.CLR1	CLR.B	(A2)+
	DBF	D0,.CLR1
					
	MOVE.L	D1,D0			; buffer max length
	LEA.L	FH_FILENAME(A3),A0	; GET FILEDIR
	MOVE.L	FH_DIRLISTSTART(A3),A1	; buffer
	move.l	_resload(pc),a2

	bsr	WHDListFiles

	TST.W	D0
	BEQ.W	.ERR

	MOVE.L	FH_DIRLISTSTART(A3),FH_CURRENTPOS(A3)	; init file pointer with first file of dir

	; fill file info block structure fields (dir type, name)

	move.l	D2,A0
	move.l	#ST_USERDIR,fib_DirEntryType(A0)	; directory
	move.l	#ST_USERDIR,fib_EntryType(A0)	; directory
	LEA	fib_FileName(A0),A1	; copy name
	LEA	FH_FILENAME(A3),A0
.COPYFILENAME2
	MOVE.B	(A0)+,(A1)+
;;	TST.B	-1(A0)		; JOTD: useless
	BNE.S	.COPYFILENAME2

	bra	.examine_exit


.ONEFILE
	lea	FH_FILENAME(A3),a0		;filename
	move.l	_resload(PC),a2
	PROTECTED_WHDCALL	GetFileSize,a2
	TST.L	D0
	BEQ.S	.ERR
	MOVE.L	D2,A2
	MOVE.L	D0,fib_Size(A2)
	MOVE.L	#2,(A2)	
	MOVE.L	#ST_FILE,fib_DirEntryType(A2)
	MOVE.L	#ST_FILE,fib_EntryType(A2)	; added by JOTD, Sensible Soccer CD32 v1.2
	MOVE.L	#$F0,fib_Protection(A2)		; added by JOTD, File rwxd
	LSR.L	#8,D0			;ASSUMED FFS
	LSR.L	#1,D0
;	DIVU	#$1E8,D0		;WOULD BE OFS
	ADDQ.L	#1,D0
	MOVE.L	D0,fib_NumBlocks(A2)	
	LEA.L	FH_FILENAME(A3),A0
	LEA.L	fib_FileName(A2),A1
.COPYFILENAME
	MOVE.B	(A0)+,(A1)+
;;	TST.B	-1(A0)		; JOTD: useless
	BNE.S	.COPYFILENAME
	MOVEQ.L	#DOSTRUE,D0
.examine_exit
	MOVEM.L	(A7)+,A2-A4
	DOSRTS

.ERR		pea	_LVOExamine
		pea	_dosname
		bra	_emufail

; Computes basename from full name (JOTD)
; < A0: name
; > A0: name's file part
; kind of strrchr with '/' char
; unused at the moment, but works
	ifeq	1
BaseName:
	movem.l	D0,-(A7)
	; first count string length
	moveq.l	#0,D0		
.loop1
	tst.b	(A0,D0.L)
	beq.b	.countend
	addq.l	#1,D0
	bra.b	.loop1
.countend

.loop2
	cmp.b	#'/',(A0,D0.L)
	beq.b	.found
	cmp.b	#':',(A0,D0.L)
	beq.b	.found
	dbf	D0,.loop2
	bra.b	.exit
.found
	lea	1(A0,D0.L),A0
.exit
	movem.l	(A7)+,D0
	rts
	endif

; < A0: name
; > A0: name with current dir added

SetCurrentDir:
	movem.l	A3,-(A7)

	move.l	$4.W,A3
	move.l	ThisTask(A3),A3

	cmp.b	#NT_PROCESS,LN_TYPE(A3)
	bne.b	.end			; in a task, not process (KickDOS hack)

	IFD	CREATE_PROC_DEFINED
	tst.l	pr_CurrentDir(A3)
	beq.b	.end		; no need to append path

	; the directory was changed
	; we need to check if the path is relative or
	; absolute

	movem.l	D0-D1/A0-A2,-(A7)
	moveq.l	#0,D0
.colonloop
	tst.b	(A0,D0.L)
	beq.b	.relative	; colon not found: relative path
	cmp.b	#':',(A0,D0.L)
	beq.b	.absolute
	addq.l	#1,D0
	bra.b	.colonloop
.relative
	; add the current dirname at start

	move.l	pr_CurrentDir(A3),D0
	BPTR2APTR	D0		; converts to APTR
	move.l	A0,A1			; filename	
	move.l	D0,A0
	lea	(FH_FILENAME,A0),A0	; directory name
	lea	.namebuffer(pc),A2
	bsr	_AddPart
	move.l	A2,8(A7)	; will be in A0 when registers are restored
.absolute:			; absolute path, the current directory has no effect
	movem.l	(A7)+,D0-D1/A0-A2
	ENDC
.end:

	bsr	RemoveColonFromName
	movem.l	(A7)+,A3
	rts

.namebuffer:
	blk.b	256,0

; Removes volumename: prefix if any (only changes pointer)
; < A0: name
; > A0: name without colon
; kind of strchr with ':' char

RemoveColonFromName:
	movem.l	D0/A1,-(A7)
	move.l	A0,A1		; save A0
.loop
	move.b	(A0)+,D0
	beq.b	.endofstring
	cmp.b	#':',D0
	bne.b	.loop
.exit
	movem.l	(A7)+,D0/A1
	rts

; colon was not found: restore original string

.endofstring:
	move.l	A1,A0		; original A0
	bra.b	.exit

; added by JOTD (needed by SlamTilt)

_ExamineFH:
	MOVEM.L	D3/A3,-(A7)

	BPTR2APTR	D1

	MOVE.L	D1,A3
	MOVE.L	D2,D3			;output struct
	LEA.L	FH_FILENAME(A3),A0		;NAME
	move.l	A0,D1
	move.l	#MODE_OLDFILE,D2
	bsr	_Open	
	move.l	D0,-(A7)

	move.l	D3,D2
	move.l	D0,D1			;filehandle!
	bsr	_Examine

	move.l	(A7)+,D1
	bsr	_Close

	MOVEM.L	(A7)+,D3/A3
	RTS

_IsInteractive:
	moveq	#0,D0
	cmp.l	#OUTPUT_HANDLER_MAGIC,D1
	bne.b	.noint
	moveq	#DOSTRUE,D0		; interactive
.noint
	rts

; CurrentDir
; < D1: new dirlock
; > D0: old dirlock

_CurrentDir:
	IFD	CREATE_PROC_DEFINED
	movem.l	D2/A2/A6,-(A7)
	move.l	D1,D2
	sub.l	A1,A1
	move.l	$4.W,A6
	JSRLIB	FindTask	; find ourselves
	move.l	D0,A2
	move.l	pr_CurrentDir(A2),D0		; old lock to return

	tst.l	D2
	beq.b	.root		; NULL lock: root directory

	move.l	D2,A0		; save dir pointer
	BPTR2APTR	D2	; APTR conversion

	; check if it's a file: Cruise For A Corpse tries
	; to CurrentDir() with a file lock!

	move.l	D2,A1
	tst.l	FH_FILELEN(A1)
	bpl.b	.file

	; it's a directory: ok to change lock

	move.l	A0,D2		; restore BPTR lock
.root
	move.l	D2,pr_CurrentDir(A2)	; sets new dirlock as current directory
.file
	movem.l	(A7)+,D2/A2/A6
	DOSRTS
	ELSE
	bra	MYRTZ		; for kickdos without kickproc, unsupported
	ENDC

; > D0: BPTR on cli structure

_Cli:
	lea	_CLI_STRUCTURE(pc),A0
	move.l	A0,D0
	rts

; < D1: lock
; > D0: lock of parent or NULL

_ParentDir:
	; first test if we reached the top directory

	move.l	d0,a1
	BPTR2APTR	A1
	cmp.b	#':',FH_FILENAME(A1)
	beq.b	.root
	tst.b	FH_FILENAME(A1)		; not exact but...
	beq.b	.root

	; not root: duplicates the lock

	bsr	_DupLock

	move.l	D0,A1
	BPTR2APTR	A1
	lea	FH_FILENAME(A1),A1	; pointer on filename
	move.l	A1,A0
.loop1
	tst.b	(A0)+
	bne.b	.loop1
	; reached end of filename, now reverse to find first '/' in name

.loop2
	cmp.b	#'/',-(A0)
	beq.b	.slashfound
	cmp.l	A0,A1
	bne.b	.loop2

	; met start of filename: parent not found: returns lock on root path
	; (should return NULL but...)

	move.l	d0,d1
	bsr	_UnLock		; free lock memory
	bra.b	.root		; returns NULL

	; lock on root path (old behaviour)
;	move.l	D0,A1
;	BPTR2APTR	A1
;	lea	FH_FILENAME(A1),A1	; pointer on filename
;	move.b	#':',(A1)+
;	clr.b	(A1)	
;	bra.b	.out

.slashfound
	; slash found: replaces by 0

	clr.b	(A0)
	
	; returns new lock

.out
	DOSRTS

.root
	moveq	#0,D0
	bra.b	.out

; < D1: filename
; > D0: fileptr

_FilePart:
	move.l	D1,A0
.zs:
	tst.b	(A0)+
	bne.b	.zs
	lea	-1(A0),A0
.pss:
	move.b	-(A0),D0
	cmp.b	#'/',D0
	beq.b	.found
	cmp.b	#':',D0
	beq.b	.found
	cmp.l	A0,D1	; start?
	bne.b	.pss
	move.l	D1,D0
	rts
.found
	lea	1(A0),A0
	move.l	A0,D0
	rts

_AddBuffers:
	; always successful

	moveq.l	#-1,D0
	rts

; < D1: lock
; < D2: buffer
; < D3: buffer length
; > D0: -1 if OK

_NameFromLock:
	move.l	D2,A0	; buffer
	move.l	D3,D0
	lea	.sysname(pc),a1
	tst.l	D1
	beq.b	.loop

	BPTR2APTR	D1
	move.l	D1,A1	; lock
	lea	FH_FILENAME(A1),A1	; filename
.loop
	tst.b	(A1)+
	bne.b	.loop
	; now we've got the real name, when it was first locked
.copy
	move.b	(A1)+,(A0)+
	dbeq	D3,.copy
	move.l	D0,D3		; restore D3 previous value
	moveq.l	#-1,D0
	DOSRTS
.sysname:
	dc.b	"SYS:",0	; default name if NULL lock
	even

; < A2: resload
; < A0: dir name
; < A1:	buffer

WHDListFiles:
	movem.l	D1/D2/A3,-(A7)

	lea	-$100(A7),A7
	move.l	A7,A3

	movem.l	A1,-(A7)
	move.l	A3,A1		; save A3

	; goto end
.goend
	move.b	(A0)+,(A3)+
	bne.b	.goend
	cmp.b	#'/',(-2,A3)
	beq.b	.clrend
	cmp.b	#':',(-2,A3)
	beq.b	.clrend
	bra.b	.cnt
.clrend:
	clr.b	(-2,A3)
.cnt
	move.l	A1,A3
	move.l	A3,A0		; "restore" A0

	move.l	D0,D2			; max buffer size
	move.l	OSM_LISTFILES_BUFFER(pc),D0
	bmi.b	.nodirexam		; -1: not allowed by WHDLoad slave
	beq.b	.nobuf			; no need for buffer (JST)
	move.l	OSM_LISTFILES_BUFFER(pc),A1	; real slave buffer area (WHDLoad)
	move.l	OSM_LISTFILES_SIZE(pc),D0	; real slave buffer size
.nobuf
	PROTECTED_WHDCALL	ListFiles,a2
	movem.l	(A7)+,A1

	move.l	D0,D1
	beq.b	.nocopy			; error: quit
	move.l	OSM_LISTFILES_BUFFER(pc),D0
	beq.b	.nocopy			; no need for buffer (JST)
	cmp.l	OSM_LISTFILES_SIZE(pc),D2
	bcs.b	.bigger		; D2 < size: use D2
	move.l	OSM_LISTFILES_SIZE(pc),D2	; size < D2: use size
.bigger
	move.l	OSM_LISTFILES_BUFFER(pc),A3	; real slave buffer area (WHDLoad)

	; copy slave buffer to osemu memory
.copy
	move.b	(A3)+,(A1)+
	bne.b	.samename
	subq.l	#1,D1
	beq.b	.nocopy		; no more names to copy: out
.samename
	subq.l	#1,D2
	bne.b	.copy		; buffer overflow: out
.nocopy
	lea	$100(A7),A7	; free buffer on stack
	movem.l	(A7)+,D1/D2/A3
	rts
.nodirexam:
	movem.l	(A7)+,A1
	moveq.l	#0,D0	; error
	bra.b	.nocopy


	IFD	DOS_MULTITASK

; sort of semaphore to ensure that in a multitasking environment
; two whdload accesses do not enter in conflict (else WHDload complains)
; (only needed in KickDos/KickProc right now because there may be
; more than 1 process using the dos lib !)

LockWhdload:
	movem.l	D0-D1/A0-A1/A6,-(A7)
	move.l	$4.W,A6

.retry
	JSRLIB	Forbid		; disable multitasking
	; we're alone. Try to get the lock

	move.w	_whdlock(pc),d0
	bne.b	.locked			; damn, it's reserved

	exg	D0,A6
	lea	_whdlock(pc),A6
	st.b	(A6)			; successfully take the lock
	exg	D0,A6
	bra.b	.success
.locked
	JSRLIB	Permit		; enable multitasking

	; failed to take the lock, we're going to retry forever
	; but first we wait a little while

	moveq.l	#10,D1
	bsr	_Delay	
	bra.b	.retry
	
.success
	; we could take the lock: go out

	JSRLIB	Permit		; enable multitasking

	movem.l	(A7)+,D0-D1/A0-A1/A6
	rts

; releases the lock
; Note: we assume we took the lock before, or else this does not work

UnLockWhdload:
	movem.l	A6,-(A7)
	lea	_whdlock(pc),a6
	clr.b	(A6)		; release the lock
	movem.l	(A7)+,A6
	rts

_whdlock:
	dc.w	0
	ENDC
