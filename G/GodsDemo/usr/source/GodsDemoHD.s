;*---------------------------------------------------------------------------
;  :Program.	GodsDemoHD.asm
;  :Contents.	Slave for "Gods Demo" from
;  :Author.	JOTD
;  :History.	28.01.05
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
	OUTPUT	GodsDemo.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;USE_FASTMEM

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap	;ws_flags
		IFD	USE_FASTMEM
		dc.l	$80000		;ws_BaseMemSize
		ELSE
		dc.l	$100000
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	datadir-_base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	$80000			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

datadir
	dc.b	"data",0
	even

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Gods Demo",0
_copy		dc.b	"1991 The Bitmap Brothers",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
	dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	$A,$D,0

BASE_ADDRESS = $84

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	;enable cache in fastmem
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	lea	$7FF00,a7
	move.l	#$FFFFFFFE,(a7)
	move.l	a7,$dff080		; install default copperlist

	LEA	$DFF000,A3
	MOVE	#$2700,SR
	LEA	$120(A3),A0
	; clear sprites
	moveq	#0,d0
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	
	MOVE.L	D0,(A0)+	

	MOVE	#$7FFF,154(A3)		;02C: 377C7FFF009A
	MOVE	#$7FFF,156(A3)		;032: 377C7FFF009C
	MOVE	#$7DEF,150(A3)		;038: 377C7DEF0096
	MOVE	#$8250,150(A3)		;03E: 377C82500096

	; load boot file

	lea	bootname(pc),a0
	lea	BASE_ADDRESS,A1
	move.l	#$A78,D0	; size
	move.l	#$84,D1		; offset
	move.l	_resload(pc),a2
	jsr	resload_LoadFileOffset(a2)
.cont
	lea	pl_boot(pc),a0
	lea	BASE_ADDRESS,A1
	jsr	resload_Patch(a2)
		
	jmp	BASE_ADDRESS

pl_boot
	PL_START
	PL_P	$2A,read_exe_file
	PL_END

; < A0 filename
; < A1 address

read_file
	move.w	#$FFFF,d3	; orig
	movem.l	d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d1/a0-a2
	moveq	#0,d0
	rts

read_exe_file
	bsr	read_file
	move.b	4(a0),d0
	cmp.b	#'1',d0
	bne.b	.main
	
	; intro/music

	movem.l	d0-d1/a0-a2,-(a7)

	lea	$71282,a0
	bsr	relocate_decrunch

	sub.l	a1,a1
	lea	pl_decrunch_music(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	bra.b	.out
.main
	cmp.b	#'2',d0
	bne.b	.pb

	lea	$58CE2,a0
	bsr	relocate_decrunch

	movem.l	d0-d1/a0-a2,-(a7)
	sub.l	a1,a1
	lea	pl_decrunch_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

.out
	moveq.l	#0,d0
	rts
.pb
	illegal
	bra.b	.out

relocate_decrunch:
	lea	decrunch(pc),a1
	move.l	#$17C,d0
.copy
	move.l	(a0)+,(a1)+
	dbf	d0,.copy

	lea	decrunch(pc),a1
	move.w	#$6004,$18E(a1)
	move.w	#$6004,$26A(a1)

	rts

jmp_1000
	movem.l	d0-d1/a0-a2,-(a7)
	sub.l	a1,a1
	lea	pl_music(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$1000.W

jmp_84
	movem.l	d0-d1/a0-a2,-(a7)

	lea	$2000.W,a0
	lea	$20000,a1
	bsr	fix_rts_nop_smc

	sub.l	a1,a1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	;enable cache in chipmem for game

	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$84.W

fix_rom_accesses
	move.w	#$64FF,$1E16A	; like in kickstart 1.3
	add.l	#$E,(A7)
	rts

fix_rts_nop_smc
.loop
	move.l	(a0),d0
	cmp.l	#$33FC4E75,d0
	beq.b	.movertslong
	cmp.l	#$31FC4E75,d0
	beq.b	.movertsword
	cmp.l	#$33FC4E71,d0
	beq.b	.movenoplong
	cmp.l	#$31FC4E71,d0
	beq.b	.movenopword
	addq.l	#2,a0
	cmp.l	a0,a1
	bne.b	.loop
	rts

.movertslong
	move.l	#$4EB80010,(a0)+
	bra.b	.loop
.movertsword
	move.l	#$4EB80016,(a0)+
	bra.b	.loop
.movenoplong
	move.l	#$4EB80020,(a0)+
	bra.b	.loop
.movenopword
	move.l	#$4EB80026,(a0)+
	bra.b	.loop


FIX_MOVE_L:MACRO
	move.l	a0,-(a7)
	move.l	4(a7),a0
	move.l	(a0),a0
	move.w	#\1,(a0)
	move.l	(a7)+,a0
	addq.l	#4,(a7)
	bsr	_flushcache
	rts
	ENDM

FIX_MOVE_W:MACRO
	move.l	a0,-(a7)
	move.l	4(a7),a0
	move.l	d0,-(a7)
	moveq	#0,d0
	move.w	(a0),d0
	move.l	d0,a0
	move.w	#\1,(a0)
	move.l	(a7)+,d0
	move.l	(a7)+,a0
	addq.l	#2,(a7)
	bra	_flushcache
	ENDM

fix_move_rts_l
	FIX_MOVE_L	$4E75

fix_move_rts_w
	FIX_MOVE_W	$4E75

fix_move_nop_l
	FIX_MOVE_L	$4E71

fix_move_nop_w
	FIX_MOVE_W	$4E71

_flushcache
	move.l	_resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts
	

soundtracker_fix
	moveq	#7,d0
	addq.l	#2,(a7)
	bra	_beamdelay

smc1		bsr	_flushcache
		MOVE	4(A5),D2	;original
		CMPI	#$0007,D2	;original
		rts

pl_main
	PL_START
	; SMC

	PL_P	$10,fix_move_rts_l
	PL_P	$16,fix_move_rts_w
	PL_P	$20,fix_move_nop_l
	PL_P	$26,fix_move_nop_w
	PL_PS	$9744,smc1
	PL_NOP	$974A,2

	; read file from floppy (RN routine)
	PL_P	$1E49E,read_file

	; strange access to ROM addresses
	PL_PS	$7816,fix_rom_accesses

	PL_END

pl_music
	PL_START
	PL_PS	$1772,soundtracker_fix
	PL_PS	$178A,soundtracker_fix
	PL_END

pl_decrunch_music
	PL_START

	PL_P	$71282,decrunch

	; no colors during decrunch

	PL_W	$71410,$6004
	PL_W	$714EC,$6004

	; flush cache and start

	PL_P	$710B8,jmp_1000
	PL_END

pl_decrunch_main
	PL_START

	; relocate decrunch routine

	PL_P	$58CE2,decrunch

	; no colors during decrunch

	PL_W	$58E70,$6004
	PL_W	$58F4C,$6004

	; patch main program
	PL_P	$58CD8,jmp_84
	PL_END

bootname
	dc.b	"gods",0
	even


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

decrunch
	blk.l	$180,0
