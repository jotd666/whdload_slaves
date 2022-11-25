;*---------------------------------------------------------------------------
;  :Modul.	7CitiesOfGold.asm
;  :Contents.	Slave for "7 Cities Of Gold" (C) 1985 EOA
;  :Author.	JOTD from Wepl Kickstart booter
;  :Original.
;  :Version.	
;  :History.	xx.04.02 started
;		29.12.04 completed
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/graphics.i
	INCLUDE	graphics/view.i

	IFD BARFLY
	OUTPUT	"7CitiesOfGold.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimizer warnings
	SUPER
	ENDC

; TODO: dsk_disk_inserted pourquoi ca reset memwatch
; TODO: ne pas setter $8->$64 sauf $20
;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0
NUMDRIVES	= 1
WPDRIVES	= %0000

DISKSONBOOT
BOOTBLOCK
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH




;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	whdload/kick11.s

;============================================================================
	IFD	BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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


slv_name	dc.b	"7 Cities of Gold",0
slv_copy	dc.b	"1985 Ozark Softscape / Electronic Arts",0
slv_info	dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,0
slv_config:
    dc.b    "C1:L:save disk:2,3,4,5,6;"

	dc.b	0

	EVEN

;============================================================================

_bootblock:
	movem.l	a0-a2/a6/d0-d1,-(A7)

	;get tags
	lea	(_tag,pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Control,a2)

	lea	active_save_disk(pc),a0
	addq.l	#2,(a0)
	
	cmp.l	#2,(a0)
	bcc.b	.ok
	move.l	#2,(a0)	; default: historical disk
.ok
	lea	pl_bootblock(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0-a2/a6/d0-d1
	jsr	($C,a4)
	movem.l	a0-a2/a6/d0-d1,-(A7)
	move.l	a0,a1

	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	movem.l	(a7)+,a0-a2/a6/d0-d1
	moveq.l	#0,D0
	rts


add_colormap_intro
	MOVE	#$0140,5998(A4)		;34AD4: 397C0140176E
	bsr	get_colormap
	move.l	d0,5974+4(A4)	; set proper colormap pointer
	rts

add_colormap_game
	MOVE	#$0140,1148(A4)		;stolen
	bsr	get_colormap
	move.l	d0,1124+4(A4)	; set proper colormap pointer
	rts

get_colormap
	lea	.old_colormap(pc),a0
	tst.l	(a0)
	beq.b	.ok

	; free old one before allocating another

	move.l	(a0),a0
	jsr	_LVOFreeColorMap(a6)
.ok
	move.l	#32,d0
	jsr	_LVOGetColorMap(a6)
	lea	.old_colormap(pc),a0
	move.l	d0,(a0)			; store for later free
	rts

.old_colormap
	dc.l	0

run_prog2
	move.l	4(a7),a0
	movem.l	a0-a2/d0-d1,-(A7)
	
	move.l	a0,a1
	lea	pl_prog2(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	movem.l	(a7)+,a0-a2/d0-d1

	jmp	(a0)

ID_TEST:MACRO
	cmp.l	#$\2,d0
	bne.b	.no\1
	cmp.l	#$\3,d1
	bne.b	.no\1
	bra	.\1
.no\1
	ENDM

APPLY_PATCH:MACRO
	move.l	a0,a1
	lea	pl_\1_sr(pc),a0	; MOVE	SR,Dx is privileged on 68010+
	move.l	_attnflags(pc),d0
	btst	#AFB_68010,d0
	bne.b	.do\@
	; plain 68000
	lea	pl_\1(pc),a0	; MOVE	CCR,Dx does not exist on 68000
.do\@
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	ENDM

after_main_call
	; restore game disk in drive

	bsr	set_game_disk
	move.w	#$100,$DFF096	; stolen
	add.l	#2,(a7)
	rts
; < A0: program start

patch_main
	eor.l	d1,d0	; stolen
	bne	.loop

	movem.l	a0-a2/d0-d1,-(A7)

	move.l	_resload(pc),a2

	move.l	(a0),d0		; ID0
	move.l	(4,a0),d1		; ID1

	ID_TEST	sys,44,F99C
	ID_TEST	intro,28,9B15
	ID_TEST	game,8FE0,AB03
	ID_TEST make_another_world,73B0,D3F7
	ID_TEST	historical_map,B0C,F3CE
	; unknown part
	illegal	
.historical_map
	APPLY_PATCH	historical_map
	bra.b	.end


.make_another_world
	APPLY_PATCH	another_world
	bsr	set_save_disk
	bra.b	.end
.game
	bsr	check_save_disk	; exits if no save disk
	APPLY_PATCH	game
	bsr	set_save_disk
	bra.b	.end
.intro
	APPLY_PATCH	intro
.sys
	bra	.end

.end
	move.l	$4.W,A6
	movem.l	(a7)+,a0-a2/d0-d1
	bsr	_flushcache
	addq.l	#8,A0		; skips start (trash)
	rts
.loop
	sub.l	#$FA,(a7)	; never reached yet!!
	illegal
	rts

; computed from diffs between before & after disk protection call
; on a nice Amiga user who sent the dumps
; (as I did not have the original disk to test)

emulate_protect:
	move.l	#$24a3531b,(a1)+
	move.l	#$a8883e0b,(a1)+
	move.l	#$a229eb4d,(a1)+
	move.l	#$4448681a,(a1)+
	move.l	#$14902b4d,(a1)+
	move.l	#$a4443e17,(a1)+
	move.l	#$92a53f4e,(a1)+
	move.l	#$2445d37d,(a1)+
	move.l	#$2895f2ca,(a1)+
	move.l	#$28935817,(a1)+
	move.l	#$a528537d,(a1)+
	move.l	#$9455defd,(a1)+
	move.l	#$4a9058d7,(a1)+
	move.l	#$9455f0d7,(a1)+
	move.l	#$9225d87b,(a1)+
	move.l	#$a2883f1b,(a1)+
	move.l	#$95252ed6,(a1)+
	move.l	#$291032d5,(a1)+
	move.l	#$92a458d6,(a1)+
	move.l	#$11453015,(a1)+
	move.l	#$5225df17,(a1)+
	move.l	#$8a90537d,(a1)+
	move.l	#$4a953f7d,(a1)+
	move.l	#$44945f7b,(a1)+
	move.l	#$5295d875,(a1)+
	move.l	#$444b5f77,(a1)+
	move.l	#$a48bf07d,(a1)+
	move.l	#$922b28fd,(a1)+
	move.l	#$a249ee1a,(a1)+
	move.l	#$114b5f1a,(a1)+
	moveq.l	#0,D0
	move.l	#$8D2,D1
	move.l	#$114A2545,D2
	rts

check_save_disk
	movem.l	d0-d1/a0-a2,-(a7)

	lea	.savedisk_suffix(pc),a0
	move.l	active_save_disk(pc),d0
	add.b	#'0',d0
	move.b	d0,(a0)
	move.l	_resload(pc),a2
	lea	.savedisk_name(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	bne.b	.ok

	pea	.savedisk_name(pc)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
.ok
	movem.l	(a7)+,d0-d1/a0-a2
	rts

.savedisk_name
	dc.b	"disk."
.savedisk_suffix
	dc.b	0,0
	even

set_game_disk
	movem.l	d0/d1,-(a7)
	moveq	#1,d0
	move.b	#%0000,d1
	bsr	set_disk
	movem.l	(a7)+,d0/d1
	rts

set_save_disk
	movem.l	d0/d1,-(a7)
	move.l	active_save_disk(pc),d0
	move.b	#%1111,d1
	bsr	set_disk
	movem.l	(a7)+,d0/d1
	rts

set_disk
	movem.l	a0,-(a7)
	lea	_trd_disk(pc),a0
	move.b	d0,(a0)
	lea	_trd_prot(pc),a0
	move.b	d1,(a0)		; write enabled/disabled (safety for main disk!)
	lea	_trd_chg(pc),a0
	move.b	#%1111,(a0)	; disk changed
	movem.l	(a7)+,a0
	rts

; < A6 GfxBase

game_load_rgb
	; clears pointer active view
	; (otherwise access fault)
	;
	; calling LoadView with A1=0 is too much since
	; it destroys the previous copperlists

	clr.l	(gb_ActiView,a6)

	; set palette (stolen from game)

	LEA	1124(A4),A0		;26CC2: 41EC0464
	LEA	1296(A4),A1		;26CC6: 43EC0510
	MOVEQ	#16,D0			;26CCA: 7010
	MOVEA.L	($4CC,a4),A6		;26CCC: 2C6C04CC
	JSR	_LVOLoadRGB4(A6)	;(graphics.library)
	MOVEM.L	(A7)+,D0-D2/D7		;26CD4: 4CDF0087
	RTS				;26CD8: 4E75

change_histo_disk
	bsr	set_save_disk	; destination disk

	CMPI.B	#$09,D0			;3C556: 0C000009
	BNE.S	.ret
	add.l	#$7E-$5C,(a7)
.ret
	rts

; when program makes use of AllocAbs too much
; reboots the machine so it's clean
; (should not happen now that I've fixed the loop counter issue)

allocabs_error
	pea	.svmode(pc)
	move.l	(a7)+,$80.W
	TRAP	#0
.svmode
	ori	#$700,SR
	bra	kick_reboot

JOYTEST:MACRO
joytest_\1
	addq.l	#4,(a7)
	move.b	$bfe001,\1
	and.b	#$80,\1
	bne.b	.out
.loop
	btst	#7,$bfe001
	beq.b	.loop		; loop till released (debounce feature)
.out
	rts
	ENDM

	JOYTEST	d0
	JOYTEST	d3

; --------------------------------------------------------------

pl_bootblock:
	PL_START
	PL_R	$9C	; avoid green screen + pause
	PL_END

pl_boot:
	PL_START

	; avoid long pause

	PL_R	$D4-$98

	; disk protection
	
	PL_PS	$244,emulate_protect

	; skip faulty FreeMem (worked on kickstart 1.1 but not from 1.2 !)

	;;PL_S	$A14-$740,4

	; program start

	PL_P	$CA0-$740,run_prog2
	PL_END

pl_prog2
	PL_START
	PL_PS	$45A,patch_main
	PL_PS	$464,after_main_call
	PL_P	$2F0,allocabs_error
	PL_END

PL_SRTOCCR:MACRO
	PL_B	\1,$42
	ENDM

pl_intro_sr
	PL_START
	PL_SRTOCCR	$12D2C-$6C28
	PL_SRTOCCR	$13F48-$6C28
	PL_SRTOCCR	$13FCC-$6C28
	PL_SRTOCCR	$13FFA-$6C28
	PL_SRTOCCR	$14808-$6C28
	PL_NEXT	pl_intro

pl_intro
	PL_START

	; clear bitmap loop counter previously was $7D0: memlist corrupt	
	
	PL_W	$14B66-$6C28,$7CF

	; mouse port -> joystick port for menu selection

	PL_L	$9234-$6C28,$DFF00C
	PL_W	$9274-$6C28,$7

	; legal colormap

	PL_PS	$14AD4-$6C28,add_colormap_intro

	PL_END

pl_game_sr
	PL_START
	PL_SRTOCCR	$3924-$1C28
	PL_SRTOCCR	$57A2-$1C28
	PL_SRTOCCR	$595E-$1C28
	PL_SRTOCCR	$5A24-$1C28
	PL_SRTOCCR	$5C32-$1C28
	PL_SRTOCCR	$60C4-$1C28
	PL_NEXT	pl_game

pl_game
	PL_START
	; legal colormap

	;;PL_PS	$6B3E-$1C28,add_colormap_game

	; avoids access fault

	;;PL_P	$6CB2-$1C28,game_load_rgb

	; joystick in port 1; debounce feature added

	PL_L	$5EB4-$1C28,$DFF00C

	PL_PS	$5CDA-$1C28,joytest_d3
	PL_PS	$5CF0-$1C28,joytest_d3
	PL_PS	$5FDE-$1C28,joytest_d3
	PL_PS	$5C70-$1C28,joytest_d0

 
	PL_END

pl_another_world_sr
	PL_START
	PL_SRTOCCR	$DF38-$DC28
	PL_SRTOCCR	$ED80-$DC28
	PL_SRTOCCR	$EDE2-$DC28
	PL_SRTOCCR	$103EC-$DC28
	PL_SRTOCCR	$12D2C-$DC28
	PL_SRTOCCR	$13F48-$DC28
	PL_SRTOCCR	$13FCC-$DC28
	PL_SRTOCCR	$13FFA-$DC28
	PL_SRTOCCR	$14808-$DC28
	PL_NEXT	pl_another_world

pl_another_world
	PL_START

	; clear bitmap loop counter previously was $7D0: memlist corrupt

	;;PL_W	$14B66-$DC28,$7CF

	; joystick in port 1

	PL_B	$E3AB-$DC28,$80
	PL_B	$E3B7-$DC28,$80

	PL_END

pl_historical_map_sr
	PL_START
	PL_SRTOCCR	$CD70-$C428
	PL_NEXT	pl_historical_map

pl_historical_map
	PL_START
	; change disk

	PL_PS	$C556-$C428,change_histo_disk

	; clear bitmap loop counter previously was $7D0: memlist corrupt
	; and allocmem fails (nasty bug, does not occur with KS 1.1 !)
	
	;;PL_W	$C84E-$C428,$7CF

	; joystick in port 1

	PL_B	$C617-$C428,$80
	PL_B	$C623-$C428,$80

	PL_END

_tag
	dc.l	WHDLTAG_CUSTOM1_GET
active_save_disk
	dc.l	0
	dc.l	0
