;*---------------------------------------------------------------------------
;  :Program.	OutToLunchCD32HD.asm
;  :Contents.	Slave for "OutToLunchCD32" from
;  :Author.	JOTD
;  :History.	28.01.06
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	OutToLunchCD32.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

USE_FASTMEM
CHIPMEMSIZE = $200000 ; cannot set lower than that
EXPMEMSIZE = $10000

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem|WHDLF_ReqAGA	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	_data-_base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_data		dc.b	"data",0
_name		dc.b	"Pierre le Chef is ... Out To Lunch CD³²",0
_copy		dc.b	"1994 Mindscape",0
_info		dc.b	"adapted & fixed by JOTD",10,10

;;		dc.b	"CUSTOM1=1 disables joypad patch",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

loader_name:
	dc.b	"otl",0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0
		even

BASE_ADDRESS = $400

; in memory, address x -> matches offset x-$324 in the disassembled code

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	bsr	get_expmem

	add.l	#EXPMEMSIZE-$100,d0
	move.l	d0,a7

	; load & version check

	lea	loader_name(pc),a0
	lea	BASE_ADDRESS,a1
	move.l	#$FC,d1
	move.l	#$50420,d0
        jsr	resload_LoadFileOffset(a2)

	lea	BASE_ADDRESS-$DC,a1	; to match the offsets of the disassembled exe

	; reloc rnc from game in fastmem (slave)

	lea	$5F72(a1),a3
	lea	rnc_decrunch(pc),a4
	move.l	#(end_rnc_decrunch-rnc_decrunch)/4,d0
.copy
	move.l	(a3)+,(a4)+
	dbf	d0,.copy

	; patch

	lea	pl_int_2(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	move.w	#$2700,SR

	jmp	BASE_ADDRESS+$F6-$DC	; skip some useless inits

read_file
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d0-a6
	rts

; D0: command
; 5: read the whole file
; 9 and 15 are used to scan/test dirs?
; never mind, ignoring them is OK too :)

cd_routine:
	cmp.w	#$9,d0
	beq.b	.out
	cmp.w	#$F,d0
	beq.b	.out

	cmp.w	#$5,d0
	bne.b	.unk

	; read file

	bsr	read_file

.out	
	moveq	#0,d0
	rts

.unk
	illegal
	bra.b	.out

floppy_routine
	illegal
	moveq	#0,d0
	rts

pl_int_2
	PL_START

	; keyboard handler hook on VBL

;;	PL_PS	$5A62,keyboard_handler

	; install illegal to trap spurious interrupts
	; (instead of stoopid loops with all interrupts off)

	PL_I	$21C
	PL_P	$254,level_2_interrupt
	PL_I	$28C
	PL_I	$2C4
	PL_I	$2FC
	PL_I	$334
	PL_I	$36C

	; change move.w	#$2200,SR by #$2000 (enable keyboard scan)
	; everywhere but in the interrupts (or else there are problems!)

	PL_R	$854	; skip VPOS check which loops forever (to remove?)
;;;	PL_W	$03392+2,$2000
;;;	PL_W	$0342C+2,$2000

	PL_W	$05388+2,$2000

;;;	PL_W	$05A6E+2,$2000
;;;	PL_W	$05AFA+2,$2000

;;;	PL_W	$11756+2,$2000
;;;	PL_W	$11976+2,$2000

;	PL_I	$13524
;	PL_W	$13524+2,$2000

	PL_W	$1910C+2,$2000

	; force keyboard interrupt enable

	PL_S	$E30E,8
	PL_S	$EA4A,8

	PL_AW	$05380+2,8	; C430 -> C438

	PL_AW	$00146+2,8	; C020
	PL_AW	$00FD4+2,8	; 8010
	PL_AW	$03424+2,8	; 8020
	PL_AW	$05AF2+2,8	; 8020
	PL_AW	$1196E+2,8	; 8020
	PL_AW	$1212E+2,8	; C030

	PL_NEXT	pl_boot

	; minimal patches

pl_boot
	PL_START

	PL_S	$E6,$10		; skip CACR set
	PL_S	$116,$30-$16	; skip memory clear
	PL_P	$EA30,cd_routine
	PL_P	$DA9A,floppy_routine
	PL_P	$5F72,rnc_decrunch
	PL_P	$106A,end_read_joypad_buttons

	PL_END

; < D0: joypad state

end_read_joypad_buttons
	cmp.b	#$7F,d0
	bne.b	.noerr
	; joystick connected
	bsr	joystick_test
.noerr
	bsr	.button_keys

	MOVE.B	D0,(A0)
	MOVEM.L	(A7)+,D0-D2/A0
;;	bsr	.arrow_keys
	RTS

.button_keys
	move.b	rawkey(pc),d1

	cmp.b	#$19,d1
	bne.b	.nopause
	bset	#0,d0	; PLAY/PAUSE button

	move.l	a1,-(a7)
	lea	rawkey(pc),a1
	clr.b	(a1)	; ack pause because removes in VBL
	move.l	(a7)+,a1

.nopause
	btst.b	#7,$bfe001
	bne.b	.nofirej
	bset	#5,d0	; RED button
.nofirej
	cmp.b	#99,d1
	bne.b	.nofire
	bset	#5,d0	; RED button
.nofire
	cmp.b	#$40,d1
	bne.b	.nospc
	bset	#6,d0	; BLUE button
.nospc
	cmp.b	#100,d1
	bne.b	.noalt
	bset	#1,d0	; GREEN button?
.noalt
	rts

; some button was pressed, and incorrectly read by joypad routine
; -> it is the joystick 2nd button

joystick_test
	moveq	#0,d0
	bset	#6,d0	; BLUE button	
.jt_out
	rts

	
level_2_interrupt
	movem.l	d0-a6,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ.S	.exit
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here

	lea	rawkey(pc),a0
	move.b	D0,(a0)

	BSET	#$06,$1E01(A5)
	moveq.l	#2,d0
	bsr	_beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge keypress
.exit
	move.w	#8,$DFF09C	; acknowledge keyboard
	movem.l	(a7)+,d0-a6	
	rte

joypad:
	dc.l	0

rawkey:
	dc.w	0


get_expmem
	IFD	USE_FASTMEM
	move.l	_expmem(pc),d0
	ELSE
	move.l	#CHIPMEMSIZE,d0
	ENDC
	rts
_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

;--------------------------------

_resload	dc.l	0		;address of resident loader

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

; WHDLoad decrunch does not work with this type of RNC data
; include room for copying original RNC decrunch routine here

rnc_decrunch
	blk.b	$6200-$5F72
end_rnc_decrunch	; approx end address + margin

