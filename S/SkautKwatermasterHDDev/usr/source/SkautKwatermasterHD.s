
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;DEBUG
	IFD BARFLY
	OUTPUT	"SkautKwatermaster.slave"
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

;============================================================================

	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;INITAGA
HDINIT
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE
DOSASSIGN

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

slv_config:
	dc.b	0
	
slv_name		dc.b	"Skaut Kwatermaster"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1995 Avalon LK",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"Kwatermaster",0
args		dc.b	10
args_end
	dc.b	0

assigna:
	dc.b	"DYSKA",0
assign1:
	dc.b	"DYSK1",0
assign2:
	dc.b	"DYSK2",0
assign3:
	dc.b	"DYSK3",0
assign4:
	dc.b	"DF0",0
	
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos		
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
	
	lea	assigna(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	lea	assign1(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	lea	assign2(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	lea	assign3(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	lea	assign4(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign

	lea	program(pc),a0
	jsr	(resload_GetFileSize,a2)
	cmp.l	#500000,d0
	bcc.b	.okay
	pea	TDREASON_WRONGVER
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
	
.okay
	;load exe
	lea	program(pc),a0
	lea	args(pc),a1
	moveq	#args_end-args,d0
	lea		patch_game(pc),a5
	bsr	load_exe
	;quit
_quit	
	pea	TDREASON_OK
	move.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)

; < D7: BPTR seglist
patch_game:
	move.l	_resload(pc),a2
	move.l	d7,a1
	lea	pl_main(pc),a0
	jsr	(resload_PatchSeg,a2)
	rts
	
pl_main
	PL_START
	; that part makes the game crash, and seems not needed
	; plus it requires the disk to be in drive... well, let's skip that
	PL_S	$06fb6,$C0-$B6
	
	; remove write to beamcon0
	PL_NOP	$029a4,2
	PL_NOP	$02cee,4
	PL_NOP	$02d52,4
	PL_END


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

;============================================================================

	END
