;*---------------------------------------------------------------------------
;  :Program.	IndyAtlantisHD.asm
;  :Contents.	Slave for "IndyFateOfAtlantis"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: IndyFateOfAtlantisHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	intuition/intuition.i
	INCLUDE	lvo/intuition.i

;CHIPONLY
	IFD BARFLY
	OUTPUT	"Loom.slave"
	IFND	CHIPONLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


	IFD	CHIPONLY
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
;STACKSIZE = 8000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'



	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

df0name:
	dc.b	"df0",0
savedir:
	dc.b	"",0

slv_name		dc.b	"Loom"
	IFD	CHIPONLY
	dc.b	" (CHIP ONLY)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1990 Lucasfilm",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
	dc.b	0


program:
	dc.b	"loom",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	movem.l	a6,-(A7)
	bsr	_patch_dos
	bsr	_patch_intuition
	bsr	_alloc_savebuffer
	movem.l	(a7)+,a6


		lea	df0name(pc),a0
		lea	savedir(pc),a1
		bsr	_dos_assign

	; there's only one version of the executable i know of
	bsr	check_version
	
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

_alloc_savebuffer:
	; alloc memory for save file

	move.l	#SAVEGAME_FILESIZE,D0
	move.l	#MEMF_CLEAR,D1
	move.l	$4.W,A6
	jsr	_LVOAllocMem(a6)
	lea	_savebuffer(pc),A0
	move.l	D0,(A0)
	rts

; increase pointer speed

_patch_intuition:
	lea	.intuiname(pc),A1
	moveq.l	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,A6
	sub.l	#pf_PointerTicks+2,A7
	move.l	A7,A0
	move.l	#pf_PointerTicks+2,D0
	jsr	_LVOGetPrefs(a6)
	move.l	A7,A0
	move.w	#1,pf_PointerTicks(a0)

	move.l	A7,A0
	move.l	#pf_PointerTicks+2,D0
	jsr	_LVOSetPrefs(a6)
	lea	pf_PointerTicks+2(A7),A7
	rts

.intuiname:
	dc.b	"intuition.library",0
	even


check_version:
	movem.l	d0-d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	; all versions (UK, italian, french, CDTV) use the same executable!
	cmp.l	#84028,D0
	beq.b	.out

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.out
	movem.l	(a7)+,d0-d1/a1
	rts


patch_main:
	movem.l	d0-a6,-(a7)
	patch	$100,crackit

	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)

.skip
	movem.l	(a7)+,d0-a6
	rts

;.protect:
;	dc.l	$41ECBC42,$31810800
;	dc.w	$6074
	
pl_main:
	PL_START
	;;PL_PSS	$01948,dmadelay_2,2	; not needed
	PL_PSS	$0198C,dmadelay,2		; without this music is trashed and game sometimes freezes!
	PL_L	$103dC,$4EB80100		; crack
	PL_END

;;dmadelay_2:	
;;	MOVE	16(A1),$DFF096
dmadelay
	movem.l	D0,-(A7)
	; dma enable should be followed by a wait
	; now that the code runs from fastmem/on fast amigas
	; some sfx could be wrongly played
	moveq.l	#7,d0
	bsr	beamdelay
	movem.l	(a7)+,D0
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
	
crackit:
	cmp.w	#$C4,d0
	bne.b	.noc4
	cmp.w	#5,D1
	bne.b	.noc4

	; 4 notes entered

	clr.w	428(A0)	; force protection to accept any code

.noc4
	cmp.w	#$C6,d0
	bne.b	.notry
	move.w	#1,d1
.notry
	move.w	d1,(A0,D0.L)
	rts

	
PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	old_\1(pc),a0
	move.l	A1,(A0)+

	move.l	A6,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)		; moves to d0_value_xxx

	move.w	#$4EF9,(A1)+	
	pea	new_\1_init(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
new_\1_init
	move.l	d0_value_\1(pc),d0
	bra	new_\1
old_\1:
	dc.l	0
d0_value_\1
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
	ENDM
	
_patch_dos:
	PATCH_DOSLIB_OFFSET	Open
	PATCH_DOSLIB_OFFSET	DeleteFile
	rts

new_DeleteFile
	moveq	#-1,d0
	rts

new_Open:
	move.l	d0,-(A7)
	cmp.l	#MODE_OLDFILE,D2
	beq.b	.open			; read: bypass

	move.l	d1,A0
	bsr	get_long
	; TODO 68000 compliant
	CMP.L	#'SAVE',d0
	beq.b	.save
	CMP.L	#'save',d0
	beq.b	.save

	bra	.open
.save
	addq.l	#8,A0
	bsr	get_long
	cmp.l	#'.___',d0
	beq.b	.open

	; savegame file, write

	bsr	.prealloc

.open
	move.l	(a7)+,d0
	move.l	old_Open(pc),-(a7)
	rts


SAVEGAME_FILESIZE = 30000

; < D1: name

.prealloc
	movem.l	D0/D1/D3/A2/A3/A6,-(A7)
	move.l	D1,D3			; save name
	move.l	D1,A0
	move.l	_resload(pc),A2
	JSR	(resload_GetFileSize,a2)
	cmp.l	#SAVEGAME_FILESIZE,D0
	bcc.b	.ok			; already there, and with the proper size

	move.l	_savebuffer(pc),D0
	beq.b	.ok			; failure!!!
	move.l	D0,A3


	move.l	#SAVEGAME_FILESIZE,D0
	moveq.l	#0,D1
	move.l	A3,A1
	move.l	D3,A0				; name
	JSR	(resload_SaveFileOffset,a2)	; empty file

.ok
	movem.l	(A7)+,D0/D1/D3/A2/A3/A6
	rts
	

; < A0: address
; > D0: longword
get_long
	move.l	a0,-(a7)
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	move.l	(a7)+,a0
	rts
; < a1 - buffer




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

_deletefile:
	moveq.l	#-1,D0
	rts

_savebuffer:
	dc.l	0
;============================================================================

	END
