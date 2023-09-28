;*---------------------------------------------------------------------------
;  :Program.	BuckRogersHD.asm
;  :Contents.	Slave for "BuckRogers"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BuckRogersHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;DEBUG

	IFD BARFLY
	OUTPUT	"BuckRogers.slave"
	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	ENDC
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	
	SUPER
	ENDC

;============================================================================

	IFD	DEBUG
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= 0
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC
NUMDRIVES	= 1
WPDRIVES = %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
BOOTDOS
HDINIT
IOCACHE		= 20000
;MEMFREE	= $200
;NEEDFPU
SETPATCH

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s



;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM


slv_name		dc.b	"Buck Rogers XXVc: Countdown to Doomsday"
		IFD	DEBUG
		dc.b	" (DEBUG MODE)"
		ENDC
			dc.b	0
slv_copy		dc.b	"1990 TSR",0
slv_info		dc.b	"Install & fix by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

	CNOP 0,4
_assign
	dc.b	"Buck2",0

	EVEN

program:
	dc.b	"game",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
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
;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;patch dos lib
		PATCH_DOSLIB_OFFSET	Open
		PATCH_DOSLIB_OFFSET	DeleteFile

	;assigns
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

new_DeleteFile
	moveq	#-1,d0
	rts

new_Open
	cmp.l	#MODE_NEWFILE,d2
	bne.b	.out

	; is it written in "save" dir?
	move.l	d1,a0	; filename
	cmp.b	#'s',(a0)+
	bne.b	.out
	cmp.b	#'a',(a0)+
	bne.b	.out
	cmp.b	#'v',(a0)+
	bne.b	.out
	cmp.b	#'e',(a0)+
	bne.b	.out
	cmp.b	#'/',(a0)+
	bne.b	.out

	movem.l	d0/d3/a2,-(a7)

	move.l	a0,a1	; store simplified name in A1

.raloop
	move.b	(a0)+,d0
	beq.b	.ex
	bra.b	.raloop
.ex

	; A0 points to the end of the name
	subq.l	#5,a0
	move.l	a0,a2	; save extension pointer

	move.l	#140,D3
	cmp.b	#'.',(a0)+
	bne.b	.noswg
	cmp.b	#'S',(a0)+
	bne.b	.noswg
	cmp.b	#'W',(a0)+
	bne.b	.noswg
	cmp.b	#'G',(a0)+
	bne.b	.noswg
	bra	.setmaxsize
.noswg
	move.l	A2,A0
	move.l	#402,D3
	cmp.b	#'.',(a0)+
	bne.b	.nowho
	cmp.b	#'W',(a0)+
	bne.b	.nowho
	cmp.b	#'H',(a0)+
	bne.b	.nowho
	cmp.b	#'O',(a0)+
	bne.b	.nowho
	bra	.setmaxsize
	
.nowho
	; savegame ?
	move.l	A2,A0
	move.l	#4000,D3
	cmp.b	#'.',(a0)+
	bne.b	.nosav
	cmp.b	#'d',(a0)+
	bne.b	.nosav
	cmp.b	#'a',(a0)+
	bne.b	.nosav
	cmp.b	#'a',(a0)+
	bne.b	.nosav
	bra	.setmaxsize
	
.nosav
	bra	.outrestore
	; A1: savename.ans
	; create the file in advance so write to file
	; will be much faster and without os swaps
.setmaxsize
	movem.l	d0-d1/a0-a1,-(a7)

	lea	savebuf(pc),a1	; contents
	move.l  #1,d0                 ;size
	move.l	d1,a0		; filename
	move.l  d3,d1               ;offset (max save size)
	move.l  (_resload,pc),a2

	; wait because RETURN can be pressed at that time
	moveq   #10,d0                  ;1 second
	jsr     (resload_Delay,a2)

	jsr     (resload_SaveFileOffset,a2)

	movem.l	(a7)+,d0-d1/a0-a1

.outrestore
	movem.l	(a7)+,d0/d3/a2
	
.out
	move.l	old_Open(pc),-(a7)
	rts

savebuf:
	dc.b	0,0
	even

; < d7: seglist

patch_main
	movem.l	d0-d1/a0-a2,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#383864,D0
	beq.b	.sps_english

	cmp.l	#384444,d0
	beq.b	.sps_german

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


.sps_english
	lea	pl_section_12_english(pc),a0
	moveq	#12,d2
	bsr	get_section
	jsr	resload_Patch(a2)
	bra.b	out
.sps_german
	lea	pl_section_12_german(pc),a0
	moveq	#12,d2
	bsr	get_section
	jsr	resload_Patch(a2)
	bra.b	out

out
	lea	pl_section_4(pc),a0
	moveq	#4,d2
	bsr	get_section
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-d1/a0-a2
	rts

pl_section_4
	PL_START
	PL_P	$153A-$11FC,_quit
	PL_END

pl_section_12_english
	PL_START
	; removes password protection
	PL_L	$FB60-$F680,$4E714E71
	PL_L	$FB88-$F680,$4E714E71
	PL_END

pl_section_12_german
	PL_START
	; removes password protection
	PL_L	$FBDE-$F728,$4E714E71
	PL_L	$FC06-$F728,$4E714E71
	PL_END

; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
	rts


; protstring section12
;	dc.l	$66000014
;	dc.w	$13FC



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
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
.skip
	;call
	move.l	d7,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length

	sub.l	A6,A6
	sub.l	A4,A4
	sub.l	A3,A3
	sub.l	A2,A2
	moveq.l	#0,D1
	moveq.l	#0,D2
	moveq.l	#0,D3
	moveq.l	#0,D4
	moveq.l	#0,D5
	moveq.l	#0,D6
	moveq.l	#0,D7

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
