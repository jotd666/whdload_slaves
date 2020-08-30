
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;DEBUG
	IFD BARFLY
	OUTPUT	"CaptainFizz.slave"
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
CHIPMEMSIZE	= $C0000
FASTMEMSIZE	= $0000
	ELSE
	; game isn't compatible with fast memory unfortunately
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $00000
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

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_config:
	dc.b	"BW;"
 	dc.b	0
	
slv_name		dc.b	"Captain Fizz"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1988 Psygnosis",0
slv_info		dc.b	"adapted by Bored Seal & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"game",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

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
		lea	(_dosbase,pc),a1
		move.l	a6,(a1)
		
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

; < d7: seglist (APTR)

patch_main:
	lea	patchlist(pc),a0
	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	(resload_PatchSeg,a2)
	rts
	
patchlist:
	PL_START
	PL_L	$eb60,$70004E75		; remove protection
	PL_NOP	$5A6,4
	PL_P	$1FD6,fix
	PL_IFBW
	PL_PSS	$3E4,dos_open_1,4
	PL_PSS	$532,dos_open_2,4
	PL_ENDIF
	
	PL_END
	
; < a0: str1
; < a1: str2
; > d0: -1: fail, 0: ok

strcmp:
	movem.l	d1/a0-a2,-(A7)
.contstrcmpasm
	move.b	(A0)+,d0
	beq.s	.termstrcmpasm
	move.b	(A1)+,d1
	beq.s	.failstrcmpasm
	bsr.s	.letterstrcmpasm
	exg	d0,d1
	bsr.s	.letterstrcmpasm
	cmp.b	d0,d1
	bne.s	.failstrcmpasm
	bra.s	.contstrcmpasm

.termstrcmpasm
	tst.b	(A1)+
	bne.s	.failstrcmpasm
	moveq.l	#0,d0
	bra.s	.endstrcmpasm

.letterstrcmpasm
	cmp.b	#$60,d0
	bls.s	.letter1strcmpasm
	cmp.b	#$7a,d0
	bhi.s	.letter1strcmpasm
	sub.b	#$20,d0
.letter1strcmpasm
	rts

.failstrcmpasm
	moveq.l	#-1,d0
.endstrcmpasm
	movem.l	(A7)+,d1/a0-a2
	rts

dos_open_1
	move.l	_dosbase(pc),a6
	bra	cont
dos_open_2
	MOVE.L	#$000003ed,D2
cont
	move.l	d1,a0
	lea		sprites(pc),a1
	bsr	strcmp
	tst.l	d0
	bne.b	.nosprite
.wait
	btst	#6,$bfe001
	beq.b	.nosprite
	btst	#7,$bfe001
	bne.b	.wait
.nosprite:
	jmp	(_LVOOpen,a6)

sprites:
	dc.b	"icarus.sprites",0
	even
	
	
	; probably fixing access fault
fix		clr.l	d0
		cmp.l	#$7f000,a0
		bge	nothing
		move.b	(a0),d0
		rts
nothing		move.l	d0,a0
		rts
		
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

_dosbase
	dc.l	0
_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0

;============================================================================

	END
