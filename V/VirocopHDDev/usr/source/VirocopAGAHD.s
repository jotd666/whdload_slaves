;*---------------------------------------------------------------------------
;  :Program.	VirocopHD.asm
;  :Contents.	Slave for "Virocop"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: VirocopHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"VirocopAGA.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
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
;STACKSIZE = 10000
BOOTDOS
CACHE

;;USE_DISK_LOWLEVEL_LIB
;;USE_DISK_NONVOLATILE_LIB

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_NoKbd|WHDLF_ClearMem|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.5"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

_assign1
	dc.b	"ViroCop",0
_assign2
	dc.b	"ViroData1",0
_assign3
	dc.b	"ViroData2",0

slv_name		dc.b	"Virocop AGA",0
slv_copy		dc.b	"1992 Graftgold",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

slv_config
	dc.b    "C1:X:force joystick in mouse port 0:0;"
	dc.b    "C1:X:force mouse in joystick port 1:1;"
	dc.b	0

_program_pal:
	dc.b	"VirocopPAL",0
_program_ntsc:
	dc.b	"VirocopNTSC",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

PATCH_XXXLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1

	ENDM

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
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

		; force joypad/joystick in port 1 (my autosense code does not
		; work at least with WinUAE, so I'm forcing it)

	IFND	USE_DISK_LOWLEVEL_LIB
	lea	OSM_JOYPAD1KEYS(pc),a0
	move.w	#$4019,2(a0)	; SPACE = switch weapon, P = pause
	move.w	#$4545,4(a0)	; both charcoal: ESC so ESC quits the game in pause mode
	;lea	port_1_attribute(pc),a0
	;move.l	#JP_TYPE_GAMECTLR,(a0)

	bsr	_patch_cd32_libs
   
    movem.l a6,-(a7)
    lea	(lowlname,pc),a1
    move.l	4.W,a6
    jsr	(_LVOOldOpenLibrary,a6)
    move.l	d0,a6
    
    move.l  _forcejoy(pc),d0
    btst    #0,d0
    beq.b   .noforcej0
    lea joytags(pc),a1
    moveq.l #0,d0
    JSR	(_LVOSetJoyPortAttrsA,A6)
.noforcej0:
    move.l  _forcejoy(pc),d0
    btst    #1,d0
    beq.b   .noforcej1
    lea mousetags(pc),a1
    moveq.l #1,d0
    JSR	(_LVOSetJoyPortAttrsA,A6)
.noforcej1
    movem.l (a7)+,a6
    ENDC
    
 
    
    
	;load exe
		lea	_program_pal(pc),a0
		lea	_patch_pal_exe(pc),a5
		move.l	_monitor(pc),d0
		cmp.l	#PAL_MONITOR_ID,d0
		beq.b	.pal
		lea	_program_ntsc(pc),a0
		sub.l	a5,a5
.pal
	;load exe
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

lowlname:
    dc.b    "lowlevel.library",0
    even
; < d7: seglist

_patch_pal_exe:
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1

	lea	pl_main_v1(pc),a0
	move.l	#$48E71030,d0
	lea	$626A(a1),a3
	cmp.l	(A3),d0
	beq.b	.reloc
	lea	pl_main_v2(pc),a0
	lea	$61E8(a1),a3
	cmp.l	(A3),d0
	beq.b	.reloc

	; unsupported

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.reloc
	lea	_cpdecrunch(pc),a4
	move.w	#$F5-$6A,d0
.copy
	move.b	(a3)+,(a4)+
	dbf	d0,.copy

	jsr	resload_Patch(a2)

	rts

pl_main_v1:
	PL_START
	PL_L	$428,$91C84E71	; VBR patch: MOVEC A0,VBR -> SUB.L A0,A0
	PL_W	$31DC,$6040	; protection
	PL_P	$626A,_cpdecrunch
	PL_END

pl_main_v2:
	PL_START
	PL_L	$418,$91C84E71	; VBR patch: MOVEC A0,VBR -> SUB.L A0,A0
	PL_W	$31C6,$6040	; protection
	PL_P	$61E8,_cpdecrunch
	PL_END

_cpdecrunch:
	ds.b	$F6-$6A,0


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
_forcejoy	dc.l	0
		dc.l	0
joytags:
        dc.l    SJA_Type,SJA_TYPE_JOYSTK,0    
mousetags:
        dc.l    SJA_Type,SJA_TYPE_MOUSE,0    

