;*---------------------------------------------------------------------------
;  :Program.	ManHunterHD.asm
;  :Contents.	Slave for "ManHunter"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ManHunterHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"ManHunter2.slave"
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
FASTMEMSIZE	= $40000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 4000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

assign_1
	dc.b	"MH2 Disk 1",0
assign_2
	dc.b	"MH2 Disk 2",0
assign_3
	dc.b	"MH2 Disk 3",0

slv_name		dc.b	"ManHunter 2: San Francisco",0
slv_copy		dc.b	"1988-1989 Sierra",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to BTTR for disk images",10,10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"MH2",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

_bootdos
	clr.l	$0.W

	move.l	(_resload),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
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
		lea	assign_1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign_2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign_3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_main:
	rts

	move.l	d7,d1
	move.l	#10,d2
	bsr	get_section
	add.l	#$C6-$60,a1
	move.w	#$4EF9,(a1)+
	pea	crack(pc)
	move.l	(a7)+,(a1)
	rts


; < d1 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d1,a1
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

crack:
	MOVEA.L	(A7),A0			;34: 2057
	movem.l	A1,-(a7)
	lea	.crackflag(pc),A1		;36: 303900000000
	move	(a1),d0
	ADDQ	#1,D0			;3C: 5240
	MOVE	D0,(a1)		;3E: 33C000000000
	movem.l	(a7)+,a1

	CMPI	#$0001,D0		;44: 0C400001
	BNE.S	.nocrack		;48: 6618
	MOVE.L	#$02810000,-10(A0)	;4A: 217C02810000FFF6
	MOVE.L	#$00FFB380,-6(A0)	;52: 217C00FFB380FFFA
	MOVE.L	#$4CDF00C0,-2(A0)	;5A: 217C4CDF00C0FFFE
.nocrack:
	MOVE.L	(A7)+,D0		;62: 201F
	MOVEA.L	(A7)+,A0		;64: 205F
	MOVEM.L	(A7)+,D6-D7		;66: 4CDF00C0
	UNLK	A6			;6A: 4E5E
	MOVEQ	#1,D0			;6C: 7001
	RTS				;6E: 4E75
.crackflag
	dc.w	0

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

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
