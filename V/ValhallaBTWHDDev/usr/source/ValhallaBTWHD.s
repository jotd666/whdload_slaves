;*---------------------------------------------------------------------------
;  :Program.	ValhallaBTWHD.asm
;  :Contents.	Slave for "ValhallaBTW"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ValhallaBTWHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"ValhallaBTW.slave"
	IFND	CHIP_ONLY
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


	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $90000
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
;STACKSIZE = 10000
BOOTDOS
CACHE
CBDOSLOADSEG
NO68020

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'


	include	kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

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

assign1
	dc.b	"VALHALLA",0

	IFEQ	1
assign0:
	dc.b	"DATADISK",0
assign2:
	dc.b	"LEVEL1",0
assign3:
	dc.b	"LEVEL2",0
assign4:
	dc.b	"LEVEL3",0
assign5:
	dc.b	"LEVEL4",0
	ENDC

slv_name		dc.b	"Valhalla - Before The War"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1994 Vulcan",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"BeforeTheWar",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN


PATCH_LOV:MACRO
	lea	.lov\1_str(pc),a1
	bsr	strcmp
	tst.l	d0
	bne.b	.no_lov\1\2
	move.l	d1,a1
	lea	pl_lov\1_v\2(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
	bra	.out
.no_lov\1\2
	ENDM

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	; now D1 is BPTR seglist

	lsl.l	#2,d0
	move.l	d0,a0

	bsr	.strip_colon

    move.l  version(pc),d2
    cmp.l   #2,d2
    beq.b   .v2
	PATCH_LOV	1,1
	PATCH_LOV	2,1
	PATCH_LOV	3,1
	PATCH_LOV	4,1
    bra.b   .out
.v2
	PATCH_LOV	1,2
	PATCH_LOV	2,2
	PATCH_LOV	3,2
	PATCH_LOV	4,2

.out
	rts


.strip_colon
	addq.l	#1,a0
	movem.l	a0,-(a7)
.loop
	move.b	(a0)+,d0
	beq.b	.fail
	cmp.b	#':',d0
	bne.b	.loop
	addq.l	#4,a7
	rts	
.fail
	movem.l	(a7)+,a0
	rts

.lov1_str
	dc.b	"-V-/LOV1",0
.lov2_str
	dc.b	"-V-/LOV2",0
.lov3_str
	dc.b	"-V-/LOV3",0
.lov4_str
	dc.b	"-V-/LOV4",0
	even

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

pl_lov1_v1
	PL_START
	PL_NOP	$120D6,4	; dos.UnLock workaround
	PL_END

pl_lov2_v1
	PL_START
	PL_NOP	$141B4,4	; dos.UnLock workaround
	PL_END

pl_lov3_v1
	PL_START
	PL_NOP	$12E20,4	; dos.UnLock workaround
	PL_END

pl_lov4_v1
	PL_START
	PL_NOP	$146D6,4	; dos.UnLock workaround
	PL_END
    ; version 2
pl_lov1_v2
	PL_START
	PL_NOP	$1207c,4	; dos.UnLock workaround
	PL_END

pl_lov2_v2
	PL_START
	PL_NOP	$1418a,4	; dos.UnLock workaround
	PL_END

pl_lov3_v2
	PL_START
	PL_NOP	$12df6,4	; dos.UnLock workaround
	PL_END

pl_lov4_v2
	PL_START
	PL_NOP	$146ac,4	; dos.UnLock workaround
	PL_END

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		lea	dosbase_copy(pc),a0
		move.l	d0,(a0)

	;assigns
		lea	assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
	IFEQ	1
		lea	assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
	ENDC
        lea version(pc),a3
		lea	program(pc),a0
        jsr (resload_GetFileSize,a2)
        cmp.l   #96364,d0
        beq.b   .v1
        cmp.l   #85828,d0
        beq.b   .v2

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.v1
    move.l  #1,(A3)
		lea	patch_main_v1(pc),a5
        bra .load
.v2
    ; "mini edition" of the game
   move.l  #2,(A3)
		lea	patch_main_v2(pc),a5
.load
	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

	
patch_main_v1
    move.l  d7,a1
	lea	pl_main_v1(pc),a0
	jsr	resload_PatchSeg(a2)
    rts
patch_main_v2
    move.l  d7,a1
	lea	pl_main_v2(pc),a0
	jsr	resload_PatchSeg(a2)
    rts
    

pl_main_v1
	PL_START
	PL_P	$6E4,_flushcache

	; removes protection check, no need to enter 3 codes neither
	PL_NOP	$10B4,4
	PL_NOP	$10C6,4
	; delirium crack
	IFEQ	1
	PL_L	$1038,$26EE001A
	PL_L	$103C,$4E7150C3
	ENDC
	PL_S	$6D9A,$A6-$9A	; workaround for kickfs dos.UnLock "bug"

	PL_P	$F8F2,_flushcache
	PL_END
    
pl_main_v2
	PL_START
	PL_P	$6E4,_flushcache


	PL_S	$0678e,$9A-$8E	; workaround for kickfs dos.UnLock "bug"

	PL_P	$f2e2,_flushcache
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

    IFD CHIP_ONLY
    add.l   d0,d0
    add.l   d0,d0
    move.l  d0,$100.W   ; save seglist
    ENDC
    
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

version:
    dc.l    0
dosbase_copy
	dc.l	0
;============================================================================

	END
