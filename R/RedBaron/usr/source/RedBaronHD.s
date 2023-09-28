;*---------------------------------------------------------------------------
;  :Program.	RedBaronHD.asm
;  :Contents.	Slave for "RedBaron"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: RedBaronHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"RedBaron.slave"
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
;DOSASSIGN
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 5000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CBDOSLOADSEG
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

slv_name		dc.b	"Red Baron",0
slv_copy		dc.b	"1992 Dynamix",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Thanks to Angus/BTTR/Seppo for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"baron",0
_args		dc.b	10
_args_end
	dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	; disable Delete() call
		bsr	patch_dos

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

; < a1: APTR seglist


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
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	jsr	(a5)
	bsr	_flushcache
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


SIM_VERSION_TEST:MACRO
	move.l	a1,a0
	add.l	#$\1,a0
	cmp.l	#$082A0001,(a0)
	bne.b	.nov\2

	lea	pl_sim_v\2(pc),a0
	jsr	resload_Patch(a2)

	bra.b	.out
.nov\2
	ENDM

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	move.l	_resload(pc),a2

	add.l	d1,d1
	add.l	d1,d1

	lsl.l	#2,d0
	move.l	d0,d6

	move.l	d6,a0
	cmp.b	#'b',1(A0)
	bne.b	.noredbaron
	cmp.b	#'a',2(A0)
	bne.b	.noredbaron

	; ----------- "baron" startup file -------------

	move.l	d1,a0
	add.l	#4,a0	; first segment
	lea	$1550(a0),a0
	cmp.l	#$58ADFFF4,(a0)
	beq.b	.patch_redbaron		; must be v1.0

	move.l	d1,a0
	add.l	#4,a0	; first segment
	lea	$1568(a0),a0
	cmp.l	#$58ADFFF4,(a0)
	beq.b	.patch_redbaron		; must be german version

	bra.b	.noredbaron

.patch_redbaron
	move.l	#$4E714EB9,(a0)+
	pea	flushit(pc)
	move.l	(A7)+,(a0)+
	bra.b	.out
.noredbaron:

	move.l	d6,a0
	cmp.b	#'p',1(a0)
	bne.b	.nops
	cmp.b	#'s',2(a0)
	bne.b	.nops

	; ----------- "ps" menu exe -------------

	move.l	d1,a1
	add.l	#4,a1	; first segment

	move.l	a1,a0
	add.l	#$2B36A,a0
	cmp.l	#$13FC00F0,(a0)
	bne.b	.nops_v1

	; ps, v1
	lea	pl_ps_v1(pc),a0
	jsr	resload_Patch(a2)
	bra.b	.out	
.nops_v1
	move.l	a1,a0
	add.l	#$2AEF6,a0
	cmp.l	#$13FC00F0,(a0)
	bne.b	.nops_v2

	; ps, v2
	lea	pl_ps_v2(pc),a0
	jsr	resload_Patch(a2)
	bra.b	.out	

.nops_v2
	move.l	a1,a0
	add.l	#$2BEA6,a0
	cmp.l	#$13FC00F0,(a0)
	bne.b	.nops

	; ps, v3
	lea	pl_ps_v3(pc),a0
	jsr	resload_Patch(a2)
	bra.b	.out	

.nops
	move.l	d6,a0
	cmp.b	#'s',1(a0)
	bne.b	.nosim
	cmp.b	#'i',2(a0)
	bne.b	.nosim

	; -------- main "sim" file ---------

	move.l	d1,a1
	add.l	#4,a1	; first segment

	SIM_VERSION_TEST	A66A,1
	SIM_VERSION_TEST	A5A8,2
	SIM_VERSION_TEST	A5CC,3
.nosim
.out
	rts


pl_sim_v1
	PL_START
	PL_PS	$A66A,patch_bittest
	PL_PS	$3089A,kb_delay
	PL_PS	$3CC74,rename_file
	PL_B	$3CC7A,$60	; branch
	PL_END

pl_ps_v1
	PL_START
	PL_PS	$2B36A,kb_delay
	PL_END


pl_sim_v2
	PL_START
	PL_PS	$A5A8,patch_bittest
	PL_PS	$2F71E,kb_delay
	PL_PS	$3C550,rename_file
	PL_B	$3C556,$60	; branch
	PL_END

pl_ps_v2
	PL_START
	PL_PS	$2AEF6,kb_delay
	PL_END


pl_sim_v3
	PL_START
	PL_PS	$A5CC,patch_bittest
	PL_PS	$2F936,kb_delay
	PL_PS	$3C5C8,rename_file
	PL_B	$3C5CE,$60	; branch
	PL_END

pl_ps_v3
	PL_START
	PL_PS	$2BEA6,kb_delay
	PL_END


kb_delay:
;;	move.b	#$f0,$bfec01	; useless

	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	add.l	#2,(a7)
	rts

; rename emulation

rename_file
	movem.l	d0-a6,-(a7)

	move.l	_resload(pc),a2

	move.l	d1,a0
	move.l	d1,d4
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.out

	move.l	d0,d3

	move.l	$4.W,a6
	moveq	#0,d1
	jsr	_LVOAllocMem(a6)
	
	move.l	d0,a3	; temp buffer for copy
	move.l	a3,a1
	move.l	d4,a0	; source name
	jsr	resload_LoadFile(a2)

	move.l	a3,a1	; temp buffer for copy
	move.l	d2,a0	
	jsr	resload_SaveFile(a2)

	move.l	d4,a0
	jsr	resload_DeleteFile(a2)
	
	move.l	a3,a1
	move.l	d3,d0
	jsr	_LVOFreeMem(a6)
.out
	movem.l	(a7)+,d0-a6
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

patch_bittest
	cmp.l	_expmem(pc),a2
	bcc.b	.ok
	cmp.l	#CHIPMEMSIZE,a2
	bcc.b	.skip
.ok
	BTST	#1,$0003(A2)
	rts
.skip
	addq.l	#2,(a7)
	rts

flushit:
	ADDQ.L	#4,-12(A5)		;1274: 58ADFFF4
	MOVEA.L	-12(A5),A0		;1278: 206DFFF4
	bsr	_flushcache
	rts


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

patch_dos:
	; remove delete for savegames

	PATCH_DOSLIB_OFFSET	DeleteFile
	rts

new_DeleteFile:
	movem.l	d0-a2,-(a7)
	move.l	d1,a1
	lea	.dont_delete_table(pc),a0
.cmp
	move.b	(a1)+,d2
	beq.b	.out
	move.b	(a0)+,d3
	beq.b	.next
	cmp.b	d2,d3
	beq.b	.cmp
.next
	tst.b	(a0)
	bne.b	.nextone
	moveq	#1,d0	; Z flag off
	bra.b	.out
.nextone
	move.l	d1,a1	; reload current filename
.tonext
	move.b	(a0)+,d3
	bne.b	.tonext
	bra.b	.cmp
.out
	movem.l	(a7)+,d0-a2
	bne.b	.delete
	moveq.l	#-1,D0		; always OK, but don't perform the delete
	rts
.delete
	move.l	old_DeleteFile(pc),-(a7)
	rts

.dont_delete_table
	dc.b	"script.dat",0
	dc.b	"mreal.prf",0
	dc.b	"sim.in",0
	dc.b	"roster.dat",0
	dc.b	"control.prf",0
	dc.b	"sim.out",0
	dc.b	"simprefs.prf",0
	dc.b	0
