;*---------------------------------------------------------------------------
; Program:	.s
; Contents:	Slave for "Knights Of The Sky"
; Author:	Mad-Matt of Action
; History:	28.11.02 - v0.0
; Requires:	WHDLoad 15+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
		INCLUDE	lvo/dos.i

		IFD BARFLY
		OUTPUT	"KnightsOfTheSky.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		DOSCMD	"WDate >T:date"
		ENDC

;============================================================================

;CHIP_ONLY

; game needs 1,5 MB from harddisk
    IFD CHIP_ONLY
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $0000
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $100000
    ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
HRTMON
IOCACHE		= 10000
;MEMFREE	= $100
;NEEDFPU
SETPATCH
BOOTDOS
CBDOSLOADSEG

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	kick13.s

;============================================================================

_disk1  	dc.b    "KOTS1",0  
_disk2  	dc.b    "KOTS2",0         


DECL_VERSION:MACRO
	dc.b	"1.4"
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

slv_name		dc.b	"Knights Of The Sky"
    IFD CHIP_ONLY
    dc.b    "(DEBUG/CHIP ONLY)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1991 Microprose",0
slv_info		dc.b	"Installed by JOTD",10,10
		dc.b	"Thanks to LockPick for the protection",10,10
		dc.b	"Version "
        DECL_VERSION
		dc.b	0
slv_CurrentDir	dc.b	"data",0
_program	dc.b	"Knights",0
_args		dc.b	10
_args_end	dc.b	0
		EVEN

;============================================================================


; needed to handle overlay call, where the
; protection check is located

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	tst.l	d0
	bne.b	.skip

	; patch overlay LoadSeg call (D1=0)

.loop
	move.l	d1,a0
	add.l	a0,a0
	add.l	a0,a0

	; protection common to both versions

	cmp.l	#$BA6DFFF6,$218+4(a0)
	bne.b	.noprot
	; crack originated from LockPick
	move.l	#$BA3A2DF6,$218+4(a0)
	move.w	#$4E71,$218+8(a0)

.noprot
.next
	move.l	(a0),d1
	bne.b	.loop
.skip
	; no need to flush caches, done by kick13.s
	rts

_bootdos

		move.l	_resload(pc),a2		;a2 = resload

		lea	_dosname(pc),a1		;Open doslib
		move.l	(4),a6
		jsr	_LVOOldOpenLibrary(a6)
		move.l	d0,a6			;A6 = dosbase
		
		;enable cache
		move.l	a0,-(A7)
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
		
		lea	_disk1(pc),a0		;Assigns
		sub.l	a1,a1
		bsr	_dos_assign
		
		lea	_disk2(pc),a0		;Assigns
		sub.l	a1,a1
		bsr	_dos_assign

		bset	#1,$bfe001		;Clear audio filter

	;load exe (much cleaner, because you can chain 2 or more executable loads
	;with that technique and it's more readable)

		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_exe(pc),a5	; pass 0 if no patch to apply
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


; < d7: seglist

_patch_exe:
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3
	move.l	(a3),a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1	; start of segment 1, code

	lea	_pl_seg1_kixx(pc),a0
	move.l	a1,a4
	add.l	#$18000,a4
	cmp.l	#$4EF90000,$5FE(a4)
	beq.b	.patch
	lea	_pl_seg1_v1(pc),a0
	cmp.l	#$4EF90000,$492(a4)
	beq.b	.patch
	lea	_pl_seg1_v2(pc),a0
	cmp.l	#$4EF90000,$46E(a4)
	beq.b	.patch

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.patch

	jsr	resload_Patch(a2)

	pea	_emu_jmp(pc)
	move.l	(a7)+,$BC.W	; TRAP #15
	rts

; corrects SMC $4EF9(address changing all the time)
; fixes color flashes

_emu_jmp
	move.l	A0,-(A7)
	move.l	6(A7),A0	; return address
	move.l	(A0),6(A7)	; RTE -> JMP address
	move.l	(A7)+,A0
	rte

; this fixes the fastmem/caches problem

_pl_seg1_kixx:
	PL_START
	PL_W	$185FE,$4E4F	; smc in interrupt (jmp $0)
	PL_W	$18692,$4E4F	; ""
	PL_W	$1A1EC,$4E4F	; ""
	PL_P	$18956,_quit	; avoids access fault on exit
    PL_PS   $185A6,_kbint
    PL_PSS  $185E2,_kbdelay,2
	PL_END

_pl_seg1_v1:
	PL_START
	PL_W	$18492,$4E4F	; smc in interrupt (jmp $0)
	PL_W	$18526,$4E4F	; ""
	PL_W	$1A070,$4E4F	; ""
	PL_P	$187E2,_quit	; avoids access fault on exit
    PL_PSS  $1846E,_kbint_vx,2
	PL_END

_pl_seg1_v2:
	PL_START
	PL_W	$1846E,$4E4F	; smc in interrupt (jmp $0)
	PL_W	$18502,$4E4F	; ""
	PL_W	$1A064,$4E4F	; ""
	PL_P	$187BE,_quit	; avoids access fault on exit
    PL_PSS  $1844A,_kbint_vx,2
	PL_END

_kbint:
	MOVE.B	$00BFEC01,D0
    movem.l d0,-(a7)
    ror.b   #1,d0
    not.b   d0
    cmp.b   _keyexit(pc),d0 ; quitkey on 680000
    beq   _quit
    movem.l (a7)+,d0
    rts

_kbint_vx
   cmp.b   _keyexit(pc),d0 ; quitkey on 680000
    beq   _quit
	ANDI.W	#$007F,D1   ; original code
	ANDI.W	#$0080,D0
    ; missing kb handshake!
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
    rts
    
    ; fix handshake timing
_kbdelay:
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
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
	jsr	(a5)
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
    IFD CHIP_ONLY
    move.l  (a1),a0
    add.l   a0,a0
    add.l   a0,a0
    move.l  a0,$100.W   ; segment #1 (not 0)
    ENDC
    
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
