;*---------------------------------------------------------------------------
;  :Program.	KingsQuest6HD.asm
;  :Contents.	Slave for "KingsQuest6"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: KingsQuest6HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"KingsQuest6.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $A0000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 10000
CBDOSREAD
BOOTDOS
CACHE


;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	;num '*'

;============================================================================

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

_assign
	dc.b	"df0",0
_assign1
	dc.b	"sdisk_1",0
_assign2
	dc.b	"sdisk_2",0
_assign3
	dc.b	"sdisk_3",0
_assign4
	dc.b	"sdisk_4",0
_assign5
	dc.b	"sdisk_5",0
_assign6
	dc.b	"sdisk_6",0
_assign7
	dc.b	"sdisk_7",0
_assign8
	dc.b	"sdisk_8",0
_assign9
	dc.b	"sdisk_9",0
_assign10
	dc.b	"sdisk_10",0

DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_name		dc.b	"King's Quest 6",0
slv_copy		dc.b	"1992 Sierra",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to BTTR for disk images",10,10
		dc.b	"Thanks to Mok/Prestige for the nice crack",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_sdisk_0:
	dc.b	"sdisk_0",0

_sdisk_1:
	dc.b	"sdisk_1",0

_sdisk_2:
	dc.b	"sdisk_2",0

_sdisk_3:
	dc.b	"sdisk_3",0

_sdisk_4:
	dc.b	"sdisk_4",0

_sdisk_5:
	dc.b	"sdisk_5",0

_sdisk_6:
	dc.b	"sdisk_6",0

_sdisk_7:
	dc.b	"sdisk_7",0

_sdisk_8:
	dc.b	"sdisk_8",0

_sdisk_9:
	dc.b	"sdisk_9",0

_sdisk_10:
	dc.b	"sdisk_10",0

_program:
	dc.b	"sdisk_1/KingsQuestvi",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

ASSIGNDSK:MACRO
	lea	_assign\1(pc),a0
	lea	_sdisk_\1(pc),a1
	bsr	_dos_assign
	ENDM

_bootdos
	clr.l	$0.W

	move.l	(_resload),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assign for savegames
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;assigns for data
		ASSIGNDSK	1
		ASSIGNDSK	2
		ASSIGNDSK	3
		ASSIGNDSK	4
		ASSIGNDSK	5
		ASSIGNDSK	6
		ASSIGNDSK	7
		ASSIGNDSK	8
		ASSIGNDSK	9
		ASSIGNDSK	10

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


; < d1 - file pos
; < a0 - name
; < a1 - buffer

_cb_dosRead
	cmp.b	#'5',8(a0)
	bne.b	.out
	cmp.b	#'6',9(a0)
	bne.b	.out
	cmp.b	#'1',10(a0)
	bne.b	.out

	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	lea	_pl_561(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

.out
	rts


; for protection

_pl_561:
	PL_START
	PL_W	$9be,$0009
	PL_W	$9c0,$19fe
	PL_W	$c5e,$0009
	PL_W	$c60,$175e
	PL_W	$d98,$0009
	PL_W	$d9a,$1624
	PL_W	$ed2,$0009
	PL_W	$ed4,$14ea
	PL_W	$1092,$0009
	PL_W	$1094,$132a
	PL_W	$1240,$0009
	PL_W	$1242,$117c
	PL_W	$13b4,$0009
	PL_W	$13b6,$1008
	PL_W	$1574,$0009
	PL_W	$1576,$0e48
	PL_W	$16ae,$0009
	PL_W	$16b0,$0d0e
	PL_W	$185c,$0009
	PL_W	$185e,$0b60
	PL_W	$1996,$0009
	PL_W	$1998,$0a26
	PL_W	$1ad0,$0009
	PL_W	$1ad2,$08ec
	PL_W	$1c44,$0009
	PL_W	$1c46,$0778
	PL_W	$1d7e,$0009
	PL_W	$1d80,$063e
	PL_W	$1ef6,$0009
	PL_W	$1ef8,$04c6
	PL_W	$2100,$0009
	PL_W	$2102,$02bc
	PL_W	$223a,$0009
	PL_W	$223c,$0182
	PL_W	$2242,$0290
	PL_W	$2246,$0004
	PL_W	$2248,$0011
	PL_W	$224a,$0005
	PL_W	$224c,$0186
	PL_W	$2262,$0002
	PL_W	$2264,$000f
	PL_W	$2266,$0006
	PL_W	$2268,$0296
	PL_W	$226a,$0002
	PL_W	$226e,$0006
	PL_W	$2270,$0008
	PL_W	$2272,$0009
	PL_W	$2274,$0014
	PL_W	$23c8,$0290
	PL_W	$23cc,$0002
	PL_W	$23ce,$0011
	PL_W	$23d0,$0005
	PL_W	$23d2,$fe7a
	PL_W	$23e8,$0002
	PL_W	$23ea,$0004
	PL_W	$23ec,$0006
	PL_W	$23ee,$0294
	PL_W	$23f0,$0002
	PL_W	$23f2,$0003
	PL_W	$23f4,$0006
	PL_W	$23f6,$0296
	PL_W	$23f8,$0002
	PL_W	$23fa,$0000
	PL_W	$23fc,$0006
	PL_W	$23fe,$0008
	PL_W	$2400,$0009
	PL_W	$2402,$0016
	PL_W	$2578,$0009
	PL_W	$257a,$fe44
	PL_W	$26ec,$0009
	PL_W	$26ee,$fcd0
	PL_W	$286a,$0009
	PL_W	$286c,$fb52
	PL_W	$29a4,$0009
	PL_W	$29a6,$fa18
	PL_W	$2b18,$0009
	PL_W	$2b1a,$f8a4
	PL_W	$2c52,$0009
	PL_W	$2c54,$f76a
	PL_W	$2d8c,$0009
	PL_W	$2d8e,$f630
	PL_W	$2ec6,$0009
	PL_W	$2ec8,$f4f6
	PL_END

; < d7: seglist



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


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0
