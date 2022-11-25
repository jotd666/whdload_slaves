;*---------------------------------------------------------------------------
;  :Program.	LegendOfFaerghailHD.asm
;  :Contents.	Slave for "LegendOfFaerghail"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: LegendOfFaerghailHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"LegendOfFaerghail.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;;CHIP_ONLY

	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $110000
FASTMEMSIZE	= $0000
	ELSE
;BLACKSCREEN
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
SETPATCH
STACKSIZE = 8000
BOOTDOS
CACHE

slv_Version	= 17
; removed "NoError" flag: should fix 0003301: DOS-Error #205 (object not found) on deleting "SYST/SHOP" 
slv_Flags	= WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;0003066	LegendOfFaerghail	4	Hello JOTD, great page with incredible work!! problem: display is flickering	2014-09-22	2014-09-23	affecté	ouvert	JOTD
;0002867	LegendOfFaerghail	4	Game instructs to press E-key but only works with D-key	2013-11-20	2014-07-13	confirmé	ouvert	JOTD


;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

; kick1.3 compatible doslib patch (nightmare to code :))
PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	cmp.w	#$4EF9,(a1)	; already patched
	beq.b	end_patch_\1
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

DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
assign0
	dc.b	"LEGEND.0",0
assign1
	dc.b	"LEGEND.1",0
assign2
	dc.b	"LEGEND.2",0
assign_save
	dc.b	"LEGEND.SAVE",0
startup_sequence:
	dc.b	"s/startup-sequence",0

slv_name		dc.b	"Legend Of Faerghail"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1990 ReLine",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config
        dc.b    "C1:B:Skip introduction;"
		dc.b	0

saves
	dc.b	"saves",0
setmap:
	dc.b	"c/setmap",0
intro:
	dc.b	"c/intro",0	; decrunched
program:
	dc.b	"LOF",0
d:
	dc.b	"d",10
d_end
	dc.b	0

args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

; strange this code seems to be called twice... is there some reboot at some point? probably
; even if intro is skipped!

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
		move.l	custom1(pc),d0
		beq.b	.noskint
		lea	skip_intro(pc),a0
		move.l	#1,(a0)
.noskint
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase


		PATCH_DOSLIB_OFFSET	Open

		lea	startup_sequence(pc),a0
		bsr	must_exist		; game checks it for some reason
		lea	saves(pc),a0
		bsr	must_exist		; needed for game save
	;assigns
		lea	assign0(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign1(pc),a0
		move.l	a0,a1
		bsr	_dos_assign
		lea	assign2(pc),a0
		move.l	a0,a1
		bsr	_dos_assign
		lea	assign_save(pc),a0
		lea	saves(pc),a1
		bsr	_dos_assign

	;load exe
		move.l	skip_intro(pc),d0
		bne.b	.skip_intro

		lea	intro(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_intro(pc),a5
		bsr	load_exe
	
.reboot
		lea	skip_intro(pc),a0
		move.l	#1,(a0)
		lea	.doit(pc),a5
		move.l	$4.W,a6
		jsr	_LVOSupervisor(a6)
.doit
		move.w	#$2700,SR
	
		bra	kick_reboot
.skip_intro
		bsr	version_check

;		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
;		move.l	#WCPUF_All,d1
;		jsr	(resload_SetCPU,a2)
	


		move.l	version(pc),d0
		cmp.l	#2,d0
		bra.b	.skip_setmap

		; load german keyboard
		lea	setmap(pc),a0
		lea	d(pc),a1
		moveq	#d_end-d,d0
		lea	patch_setmap(pc),a5
		bsr	load_exe	
.skip_setmap

		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe

		; wait forever

		move.l	$4,a6
		moveq	#0,d0
		jsr	_LVOWait(a6)
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < A0 filename
; < A6 dosbase

must_exist
	movem.l	d0-d1/a0-a1/a3,-(a7)
	move.l	a0,d1
	move.l	a0,a3
	move.l	#ACCESS_READ,d2
	jsr	_LVOLock(a6)
	move.l	d0,d1
	beq.b	.error
	jsr	_LVOUnLock(a6)
	movem.l	(a7)+,d0-d1/a0-a1/a3
	rts

.error
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


; < d7: seglist (APTR)

patch_intro

	;disable cache

	move.l	#WCPUF_Base_NC|WCPUF_Exp_NC|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)
	
	rts

version_check
	lea	version(pc),a3
	move.l	_resload(pc),a2
	lea	program(pc),a0
	jsr	resload_GetFileSize(a2)
	cmp.l	#263264,d0
	beq.b	.v1
	cmp.l	#270464,d0
	beq.b	.v2
	cmp.l	#263052,d0
	beq.b	.v3

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.v1
	move.l	#1,(A3)
	bra	.end
.v2
	move.l	#2,(A3)
	move.l	#2,(A3)
	bra	.end
.v3
	move.l	#3,(A3)
	bra	.end
.end
	rts

version
	dc.l	0

; < d7: seglist (APTR)

patch_setmap
	moveq.l	#0,d2
	bsr	get_section
	lea	pl_setmap(pc),a0
	jsr	resload_Patch(a2)
	rts

pl_setmap
	PL_START
	PL_P	$1DA,return_from_outer_space	; haha
	PL_END

; setmap program uses the returnaddr pointer of the process structure
; and KickEmu with the emulated startup-sequence is not able to support it
; fully (which explains why some whd games need a startup-sequence, and some others
; don't accept HDINIT + files but need diskimage!!)
;
; here's a workaround to be able to use files in the install

return_from_outer_space
	move.l	_savestack(pc),a7
	subq.l	#4,a7
	moveq	#0,d0
	rts

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

patch_main
	;executable filesize: 263264 for caps 1589, 270464 for caps 574 (German)

	move.l	version(pc),d0
	cmp.l	#1,d0
	beq.b	.v1
	cmp.l	#2,d0
	beq.b	.v2
	bra.b	.v3
.v1
	lea	pl_main_seg_0_1589(pc),a0
	bra.b	.doit
.v2
	lea	pl_main_seg_0_524(pc),a0
	bra.b	.doit
.v3
	lea	pl_main_seg_0_2844(pc),a0
	bra	.doit

.doit
	move.l	d7,a1
	add.l	#4,a1
	jsr	resload_Patch(a2)
	rts

pl_main_seg_0_1589
	PL_START
	PL_PS	$18E24,fix_d0_msb
	PL_STR	$01591E,<Equippe(d)> 
	PL_END

; german version
pl_main_seg_0_524
	PL_START
	PL_PS	$19658,fix_d0_msb
	PL_END

pl_main_seg_0_2844
	PL_START
	PL_PS	$18DAA,fix_d0_msb
	PL_STR  $0158A4,<Equippe(d)> 
	PL_END

fix_d0_msb
	cmp.l	#-1,d0
	beq.b	.minus_one
	
	swap	d0
	clr.w	d0
	swap	d0

.skip
.minus_one
	; original
	move.w	d1,d2
	mulu.w	d0,d2
	move.l	d1,d3
	rts

;;.minus_one
	moveq	#0,d0
	bra.b	.skip

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
	add.l	d7,d7
	add.l	d7,d7
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
	lea	_savestack(pc),a4
	move.l	a7,(a4)
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

SAVE_SIZE = 13554

new_Open:
	move.l	D0,-(A7)
	cmp.l	#MODE_NEWFILE,d2
	bne	.end

	; D1: df0:filename of the savegame.
	; First check that it's really a savegame (who knows???)
	move.l	d1,a0
	addq.l	#4,a0
	bsr	get_long

	cmp.l	#$4E442E53,d0   ; part of the label of the save disk
	bne	.end
	; it's a savegame. In A0 we have the name. Check if the size is okay
	movem.l	d1/a2/a3,-(a7)
	
	lea	(8,a0),a0		; skip 4 more label string bytes
	; copy name with full path
	lea	savename(pc),a2
.copyname
	move.b	(a0)+,(a2)+
	bne.b	.copyname
	
	lea		savefile(pc),a0           ;name
	move.l	_resload(pc),a2
	jsr	(resload_GetFileSize,a2)
	cmp.l	#SAVE_SIZE,d0	
	bcc.b	.big_enough
	; file is smaller than 13kb, means that it will flash on gamesave
	; (because it's a stub or it doesn't exist). Create the file beforehand
	; with trash in it, the contents don't matter as it'll be overwritten
    move.l  #SAVE_SIZE,d0                 ;size
	lea		savefile(pc),a0           ;name
	sub.l	a1,a1            ;source
	jsr     (resload_SaveFile,a2)	
.big_enough
	movem.l	(a7)+,d1/a2/a3
.end
	move.l	(a7)+,d0
	move.l	old_Open(pc),-(a7)
	rts

savefile:
	dc.b	"saves/"
savename:
	ds.b	50,0
	even

; < A0: address
; > D0: longword
get_long
	move.l	a0,-(a7)
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	move.l	(a7)+,a0
	rts
	
_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
_savestack
		dc.l	0
tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0
skip_intro
	dc.l	0

;============================================================================

	END
