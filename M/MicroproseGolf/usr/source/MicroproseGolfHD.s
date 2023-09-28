;*---------------------------------------------------------------------------
;  :Program.	MicroproseGolfHD.asm
;  :Contents.	Slave for "MicroproseGolf"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: MicroproseGolfHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"MicroproseGolf.slave"
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
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH

;============================================================================

KICKSIZE	= $40000			;34.005
;KICKSIZE	= $80000			;40.068
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	CNOP 0,4
_assign1
	dc.b	15,"Microprose Golf",0
	CNOP 0,4
_assign2
	dc.b	13,"Course Disk 1",0
	CNOP 0,4
_assign3
	dc.b	13,"Course Disk 2",0
	CNOP 0,4
_assign4
	dc.b	3,"DF0",0

_name		dc.b	"Microprose Golf",0
_copy		dc.b	"1991 Microprose",0
_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Golf/golf",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot


; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	D1,D1
	add.l	D1,D1

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0
	cmp.b	#13,(a0)
	bne.b	.skipmain
	cmp.b	#'c',10(a0)
	bne.b	.skipmain

	move.l	d1,a1
	bsr	_patch_exe

.skipmain
	rts

_patch_exe:
	movem.l	a1,-(a7)
	addq.l	#4,a1
	lea	_pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a1
	rts


; < d7: seglist

_pl_main:
	PL_START
	PL_L	$118C4,$3B7C14F2
	PL_W	$118C8,$FFFE
	PL_L	$118CA,$4A2D0179
	PL_W	$118CE,$6A06
	PL_L	$118D0,$3B7C14F6
	PL_L	$118D4,$FFFE4E71
	PL_L	$11940,$53464240
	PL_L	$11948,$12231101
	PL_W	$1194C,$B301
	PL_END

	IFEQ	1
	move.l	(a1),a1	
	add.l	a1,a1
	add.l	a1,a1
	; skip chipmem section
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	move.l	a1,a3

	; data section

	move.l	#30156,d0
	bsr	.get_address
	rts

; < d0: line number
; > a1: address	
.get_address:
	sub.l	#25917,d0	; first line of data section in resource
	lsl.l	#4,d0	; * 16, because 1 line = 16 bytes
	lea	(4,a3,d0.l),a1
	rts
	ENDC

_bootdos
	clr.l	$0.W

	bsr	_patchkb

	move.l	(_resload),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

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
	jsr	(a5)
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


_patchkb
	IFEQ	KICKSIZE-$40000

	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
	ELSE
	rts
	ENDC

;============================================================================

	IFEQ	KICKSIZE-$40000
	INCLUDE	whdload/kick13.s
	ELSE
	INCLUDE	kick31.s
	ENDC

;============================================================================

	END
