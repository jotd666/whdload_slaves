;*---------------------------------------------------------------------------
;  :Program.	CastlevaniaHD.asm
;  :Contents.	Slave for "Castlevania" from 
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

	IFD BARFLY
	OUTPUT	"Castlevania.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIP_ONLY

	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $50000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE
SEGTRACKER


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.0"
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

slv_data		dc.b	"data",0
slv_name		dc.b	"Castlevania"
        IFD CHIP_ONLY
        dc.b    " (DEBUG/CHIP mode)"
        ENDC
            dc.b    0
slv_copy		dc.b	"1990 Konami",0
slv_info		dc.b	"Installed by JOTD",10,10
		dc.b	"Thanks to C.Vella & R.Cruz for original diskimage",10,10
		dc.b	"Version "
        DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config
	;dc.b    "C1:X:Trainer Infinite lives:0;"
	dc.b	0

_exename:
	dc.b	"cast",0
_lf:
	dc.b	10,0
	even

_bootdos	

        move.l	(_resload,pc),a2	;a2 = resload
		
	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load program

	lea	_exename(pc),A0
	lea	_lf(pc),A1
	moveq	#1,D0
    lea patch_main(pc),a5
    bsr load_exe


_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

patch_main
	patch	$100.W,_emulate_dbf
    move.l  d7,a1
    move.l  _resload(pc),a2
	lea	_patchlist_1(pc),a0
	jsr	(resload_PatchSeg,a2)
    rts
    
;---------------

_patchlist_1	PL_START
    PL_PS	$CF4C,_kb_hook
    PL_S	$CF52,$14	; skip original shitty ack kb
    PL_L	$BDB6,$4EB80100
    PL_L	$EF6E,$4EB80100
    PL_L	$F4F0,$4EB80100	; cpu dependent loops
    PL_R	$A7C0	; manual protection

    ;PL_PS	$DDD4,_loadprogname

    PL_END


_kb_hook
    move.b  $BFEC01,d0
    not.b   d0
    ror.b   #1,d0
    cmp.b   _keyexit(pc),d0
    beq _quit
    
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
	rts

_emulate_dbf:
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts

_beamdelay:
	tst.w	D0
	beq.b	.exit
.loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS

.loop2
	cmp.b	$dff006,d0
	beq.s	.loop2
	move.w	(a7)+,d0
	dbf	d0,.loop1

.exit
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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
;---------------

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	0


;============================================================================

	END
