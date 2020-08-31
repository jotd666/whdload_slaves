;*---------------------------------------------------------------------------
;  :Program.	PinballManiaHD.asm
;  :Contents.	Slave for "PinballMania"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: PinballManiaHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/nonvolatile.i

	IFD	BARFLY
	OUTPUT	"PinballMania.slave"

	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $100000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG	; without it access faults
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CBDOSLOADSEG
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_NoKbd|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	kick31.s

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
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_name		dc.b	"Pinball Mania",0
slv_copy		dc.b	"1995 21st Century Entertainment",0
slv_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

pmam_name
	dc.b	"PMAM1",0

program:
	dc.b	"mania",0
args		dc.b	10
args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment


; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg:
	move.l	d1,a3
	add.l	a3,a3
	add.l	a3,a3
	move.l	d0,a0
	add.l	a0,a0
	add.l	a0,a0

	cmp.b	#'P',1(a0)
	bne.b	.out		; not a patchable file
	cmp.b	#'0',5(a0)
	bne.b	.tables		; corrupt overlay exe shit

	bsr	_remove_vbr
.out
	rts

.tables:
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_tables(pc),a0
	move.l	a3,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts

pl_tables
	PL_START
	PL_PS	$1DC,remove_vbr_a4
;;	PL_PS	$110,alloc_d1
	PL_END

alloc_d1
	move.l	#MEMF_CLEAR,d1	; memf public instead of top shit
	add.l	#8,(a7)
	rts

remove_vbr_a4
	movem.l	d0-d1/a0-a3,-(a7)
	add.l	A4,A4
	add.l	A4,A4
	addq.l	#4,a4

	cmp.l	#$322DFFFC,$2204(a4)
	bne.b	.sk1

; table 1: skip access faults
	lea	_pl_table1(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
.sk1

	cmp.l	#$70003010,$33FA(a4)
	bne.b	.sk3

; table 3: skip access faults
	
	lea	_pl_table3(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

.sk3
	move.l	a4,a3
	bsr	_remove_vbr
	bsr	_flushcache
	movem.l	(a7)+,d0-d1/a0-a3
	rts



_pl_table1:
	PL_START
	PL_W	$2200,$4E71
	PL_PS	$2202,_fix_af_2
	PL_END

_pl_table3:
	PL_START
	PL_PS	$33FA,_fix_af_1
	PL_PS	$341A,_fix_af_1
	PL_PS	$343A,_fix_af_1
	PL_W	$2090,$4E71
	PL_PS	$2092,_fix_af_2

	PL_PS	$27A2,_fix_af_3
	PL_END

_fix_af_1:
	move.l	a0,d0
	bmi.b	.skip

	moveq	#0,d0
	move.w	(a0),d0
	lsl.w	#4,d0
	rts
.skip
	moveq	#0,d0
	rts

_fix_af_2:
	movem.l	d0,-(a7)
	move.l	($10,a3),d0
	and.l	#$1FFFFF,d0
	move.l	d0,a5
	move.w	(-4,a5),d1
	movem.l	(a7)+,d0
	rts

_fix_af_3:
	movem.l	d0,-(a7)
	move.l	a1,d0
	and.l	#$1FFFFF,d0
	move.l	d0,a1
	addq.l	#8,a1		; orig
	lea	12(a2),a2	; orig
	movem.l	(a7)+,d0
	rts
	
; remove VBR read on first segment of files pinball, PINFILE?.DAT

_remove_vbr:
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	a3,a0
	lea	$700(a0),a1
	move.l	#$4E7A0801,D0
	move.l	#$4E717000,D1
	bsr	_hexreplacelong
	movem.l	(a7)+,d0-d1/a0-a1
	rts


_bootdos
	clr.l	$0.W

	move.l	(_resload),a2		;A2 = resload

	;get tags
;		lea	(tag,pc),a0
;		move.l	_resload(pc),a2
;		jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	args(pc),a1
		move.l	#args_end-args,d0

		move.l	start_table(pc),d0
		beq.b	.ok
		lea	pmam_name(pc),a0
		add.b	#'0',d0
		move.b	d0,4(a0)	; PMAM1,2,3,4...
		sub.l	a5,a5		; patch is done though cb_dosloadseg
		bra.b	.load
.ok
		lea	program(pc),a0
		lea	_patch_mania(pc),a5
.load
		bsr	_load_exe

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)


_patch_mania:
	move.l	d7,a1
	addq.l	#4,a1
	lea	_pl_mania(pc),a0
	jsr	resload_Patch(a2)
	rts

_pl_mania:
	PL_START
	PL_PS	$812,_sort_scores
	PL_END

; < a2: score buffer

_sort_scores:
	; the scores are not sorted properly when stored
	; bubblesort them now

	movem.l	d0-d7/a0-a1/a3,-(a7)
	lea	8(a2),a3	; start
	moveq	#3,d4
.loop0
	move.l	a3,a0
	moveq	#2,d0		; repeat 3 times
.loop1
	move.l	d0,d1		; repeat d0 times
	lea	12(a0),a1	; start (ptr 2)

.loop2
	cmp.l	a0,a1
	beq.b	.skip		; same item

	move.l	4(a0),d2	; hiscore1 (BCD)
	move.l	4(a1),d3	; hiscore2
	cmp.l	d3,d2
	bcs.b	.swap
	bne.b	.skip

	; Most sig. scores are equal, test lowest

	move.l	8(a0),d2	; hiscore1 (BCD)
	move.l	8(a1),d3	; hiscore2
	cmp.l	d3,d2
	bcc.b	.skip		; d2 >= d3

	; swap both scores and names
.swap
	move.l	8(a0),-(a7)
	move.l	4(a0),-(a7)
	move.l	(a0),-(a7)

	move.l	(a1),(a0)
	move.l	4(a1),4(a0)
	move.l	8(a1),8(a0)

	move.l	(a7)+,(a1)
	move.l	(a7)+,4(a1)
	move.l	(a7)+,8(a1)

.skip
	lea	12(a1),a1	; next score
	dbf	d1,.loop2

	lea	12(a0),a0	; next score
	dbf	d0,.loop1

	lea	12*4(a3),a3	; next table
	dbf	d4,.loop0

	movem.l	(a7)+,d0-d7/a0-a1/a3

	; original code

	jsr	_LVOStoreNV(a6)
	tst.l	d0
	rts

_hexreplacelong:
	movem.l	A0-A1/D0-D1,-(A7)
.srch
	cmp.l	(A0),D0
	beq.b	.found
.next
	addq.l	#2,A0
	cmp.l	A1,A0
	bcc.b	.exit
	bra.b	.srch
.found
	move.l	D1,(A0)+
	bra	.next
.exit
	movem.l	(A7)+,A0-A1/D0-D1
	rts


tag		dc.l	WHDLTAG_CUSTOM1_GET
start_table	dc.l	0
		dc.l	0


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
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

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
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

;============================================================================

	END
