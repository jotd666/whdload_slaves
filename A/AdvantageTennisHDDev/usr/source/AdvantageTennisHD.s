;*---------------------------------------------------------------------------
;  :Program.	MarbleMadness.asm
;  :Contents.	Slave for "MarbleMadness"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
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
	OUTPUT	"AdvantageTennis.slave"
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
FASTMEMSIZE = $0
CHIPMEMSIZE	= $100000
HRTMON
	ELSE
FASTMEMSIZE	= $80000
CHIPMEMSIZE	= $80000
BLACKSCREEN
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

STACKSIZE = 8000
SETPATCH


; the diskimage version allows to load the diskimage in RAM
; at once, and avoids constant disk access (ex: with CD32load)

DOSASSIGN
;
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
BOOTDOS
HDINIT

	
;============================================================================


slv_Version=17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	include 	kick13.s


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
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name		dc.b	"Advantage Tennis"
	IFD	CHIP_ONLY
	dc.b	" (CHIPONLY MODE)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1991 Infogrames",0
slv_info		dc.b	"Installed & fixed by JOTD",10,10
			dc.b	"Version "
			DECL_VERSION
		dc.b	0

slv_CurrentDir:
	dc.b	"data",0
slv_config:
;	dc.b	"BW;"
	dc.b    "C1:X:Turn off all speed throttling:0;"			
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
_df0          dc.b    "DF0",0
_avt          dc.b    "AVT",0

program:
	dc.b	"menu",0
args
	dc.b	10
args_end
	dc.b	0
	EVEN
	
PLAYER_FILESIZE = 14884

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

	
_bootdos
	;enable cache
;		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
;		move.l	#WCPUF_All,d1
;		jsr	(resload_SetCPU,a2)

	; install our vbl "handler"
	lea		old_vbl(pc),a0
	move.l	$6C.W,(a0)
	lea	new_vbl(pc),a0
	move.l	a0,$6C.W
	
	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
	;lea	(_tag,pc),a0
	;jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
; useful when stubbing dos C wrappers
		lea	_dosbase(pc),a0
		move.l	a6,(a0)

        ;assigns
		lea     (_df0,pc),a0
		sub.l   a1,a1
		bsr     _dos_assign
		lea     (_avt,pc),a0
		sub.l   a1,a1
		bsr     _dos_assign
		
		PATCH_DOSLIB_OFFSET	Open
		
; load main program
	lea	program(pc),a0
	lea	(args,pc),a1
	move.l	#args_end-args,d0
	lea	patch_exe(pc),a5
	bsr	_load_exe

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
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

	
new_Open:
	move.l	D0,-(A7)
	cmp.l	#MODE_NEWFILE,d2
	bne	.end
	; D1: df0:filename of the savegame.
	; First check that it's really a savegame (who knows???)
	move.l	d1,a0
.toend
	tst.b	(A0)+
	bne.b	.toend
	subq.l	#5,A0
	bsr	get_long
	cmp.l	#".PLY",d0
	bne	.end
	; it's a savegame. In A0 we have the name. Check if the size is okay
	movem.l	d1/a2/a3,-(a7)
	move.l	a0,a3		; save filename
	move.l	_resload(pc),a2
	jsr	(resload_GetFileSize,a2)
	cmp.l	#PLAYER_FILESIZE,d0	
	bcc.b	.big_enough
	; file is smaller than 30kb, means that it will flash on gamesave
	; (because it's a stub or it doesn't exist). Create the file beforehand
	; with trash in it, the contents don't matter as it'll be overwritten
    move.l  #PLAYER_FILESIZE,d0                 ;size
	move.l 	a3,a0           ;name
	sub.l	a1,a1            ;source
	jsr     (resload_SaveFile,a2)	
.big_enough
	movem.l	(a7)+,d1/a2/a3
.end
	move.l	(a7)+,d0
	move.l	old_Open(pc),-(a7)
	rts
	
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
	
patch_exe:
	move.l	_resload(pc),a2
	move.l	d7,a1
	lea	pl_main(pc),a0
	jsr	(resload_PatchSeg,a2)

	rts

pl_main
	PL_START
	PL_L	$86ce,$7001601A    ; disktest patch
	PL_B	$0ae5e,$60    ; crack patch
	PL_I	$0acd6
	PL_L	$0acca,$70004E75	; password protection
	PL_PSS	$16f24,_correct_copperlist,2        ; color burst patch
	PL_IFC1
	PL_ELSE
	PL_PS	$0bc28,game_loop
	PL_PS	$1952e,draw_rect_hook
	PL_ENDIF
	PL_PS	$13cd8,avoid_zero_div
	PL_END

	
	
VBL_WAIT:MACRO
	movem.l	d0/a0,-(a7)
	lea	.step(pc),a0
	sub.w	#1,(a0)
	bne.b	.skip
	move.w	#\1,(a0)
	lea	.prev_value(pc),a0
.wait
	move.l	vbl_int_counter(pc),d0
	cmp.w	(a0),d0
	beq.b	.wait
	move.w	d0,(a0)
.skip	
	movem.l	(A7)+,d0/a0
	bra.b	.cont
.prev_value
	dc.w	0
.step
	dc.w	\1
.cont
	ENDM
	
draw_rect_hook:
	; add 4 to original code we just JSR'd :)
	MOVEM.W	36+4(A7),D0-D3/A5		;1952e: 4caf200f0024
	; wait once every x calls to slow this damn thing down
	; else selection is very difficult on fast CPUs
	VBL_WAIT	70
	RTS
	
avoid_zero_div:
	TST		-$2e8a(A4)
	beq.b	.avoid
	DIVS.W -$2e8a(A4),D0
	SWAP.W D0
	RTS
.avoid
	move.w	#$1000,d0	; big enough result ?
	RTS

game_loop:
LAB_0E03:
	CMPI.B	#$dc,$dff006
	BNE.S	LAB_0E03		;16810: 66f6
LAB_0E04:
	CMPI.B	#$dc,$dff006		;16812: 0c3900dc00dff006
	BEQ.S	LAB_0E04		;1681a: 67f6
	
	; original
	MOVEA.L	-8(A5),A6		;0bc28: 2c6dfff8
	MOVEA.L	(A6),A2			;0bc2c: 2456
	rts

counter:
	dc.w	3
vbl_int_counter:
	dc.l	0
old_vbl
	dc.l	0
	
new_vbl
	movem.l	a0,-(a7)
	lea	vbl_int_counter(pc),a0
	addq.l	#1,(a0)
	movem.l	(a7)+,a0
	; old VBL
	move.l	old_vbl(pc),-(a7)
	rts

	
_correct_copperlist:
	lea	-$28D0(A4),A1
	move.w	#$FFFF,$78(A1)
	move.l	A1,$80(A0)
	rts

;---------------


;_tag		dc.l	WHDLTAG_CUSTOM1_GET
;_game_delay	dc.l	0
;	dc.l	0
_dosbase
	dc.l	0
