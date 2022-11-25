
	INCDIR	Includes:
	INCLUDE whdload.i
	INCLUDE libraries/lowlevel.i
	INCLUDE whdmacros.i
	INCLUDE lvo/dos.i


	IFD BARFLY
	IFD _AGA
	OUTPUT	"DeluxeGalagaAga.Slave"
	else
	OUTPUT	"DeluxeGalagaEcs.Slave"
	ENDC
	BOPT	O+	;enable optimizing
	BOPT	OG+	;enable optimizing
	BOPT	ODd-	;disable mul optimizing
	BOPT	ODe-	;disable mul optimizing
	BOPT	w4-	;disable 64k warnings
	BOPT	wo-	;disable optimize warnings
	SUPER
	ENDC

;============================================================================
;;CHIPDEBUG

 
	IFD CHIPDEBUG
 ; debug mode
	IFD _AGA
CHIPMEMSIZE	= $80000*4
FASTMEMSIZE	= $0
	else
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0
	ENDC
	ELSE
	IFD _AGA
CHIPMEMSIZE	= $80000*4
FASTMEMSIZE	= $80000
 else
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
 ENDC
 ENDC

NUMDRIVES	= 1
WPDRIVES	= 	0000

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSREAD
;CACHE

;DISKSONBOOT
DOSASSIGN
FONTHEIGHT	= 8
HDINIT
HRTMON
IOCACHE	= 1024
;MEMFREE	= $200
;NEEDFPU
POINTERTICKS	= 1
SETPATCH
	IFD _AGA
INITAGA
	ENDC
;STACKSIZE	= 6000
;TRDCHANGEDISK
QUIT_AFTER_PROGRAM_EXIT
; affects lowlevel.s: if button combination pressed, quits to wb
QUIT_JOYPAD_MASK = JPF_BUTTON_FORWARD|JPF_BUTTON_REVERSE|JPF_BUTTON_PLAY
USE_DISK_NONVOLATILE_LIB
IGNORE_OPENLIB_FAILURE	; for xpkmaster

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================
	IFD _AGA
	INCLUDE	kick31cd32.s
	else
	INCLUDE kick13.s
	ENDC

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate	>T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.2"
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
	
slv_CurrentDir	dc.b	"data",0
 IFD _AGA
slv_name	dc.b	"Deluxe Galaga (AGA)"
 else
slv_name	dc.b	"Deluxe Galaga (ECS)"
 ENDC
 IFD CHIPDEBUG
	dc.b	" (DEBUG MODE)"
 ENDC
 dc.b " V2.6",0
 
slv_copy	dc.b	"1995 Edgar M.Vigdal.",0
slv_info	dc.b	"Patch coded by CFou! & JOTD",10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	EVEN

;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required

; the following example is extensive because it saves all registers and
;	restores them before executing the program, the reason for this that some
;	programs (e.g. MANX Aztec-C) require specific registers properly setup on
;	calling
; in most cases a simpler routine is sufficient :-)

	IFD BOOTDOS

_bootdos
	lea	(_saveregs,pc),a0
	movem.l	d1-d6/a2-a6,(a0)
	move.l	(a7)+,(44,a0)
	move.l	(_resload,pc),a2	;A2 = resload
	
	IFD _AGA
	; force pads for both players (don't worry, joysticks work too with that setup)
	lea	port_0_attribute(pc),a0
	move.l	#SJA_TYPE_GAMECTLR,(a0)
	lea	port_1_attribute(pc),a0
	move.l	#SJA_TYPE_GAMECTLR,(a0)
	
	bsr	_patch_cd32_libs
	ENDC
	
	;open doslib
	lea	(_dosname,pc),a1
	move.l	(4),a6
	jsr	(_LVOOldOpenLibrary,a6)
	lea	(dosbase,pc),a0
	move.l	d0,(a0)
	move.l	d0,a6	;A6 = dosbase

	;assigns
	lea	(_disk1,pc),a0
	sub.l	a1,a1
	bsr	_dos_assign

	;check version
	bsr	check_version

	;load exe
	lea	(_program,pc),a0
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7	;D7 = segment
	beq	_program_err


	IFD DEBUG
	;set debug
	clr.l	-(a7)
	move.l	d7,-(a7)
	pea	WHDLTAG_DBGSEG_SET
	move.l	a7,a0
	jsr	(resload_Control,a2)
	add.w	#12,a7
	ENDC

	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	cmp.l	#$487a0178,4(a1)
	bne	.not_crunched

	pea	_AfterDecunch(pc)
	move.w #$4ef9,$17a(a1)
	move.l	(a7)+,$17a+2(a1)
	bsr	_flushcache
	bra.b	.launch
.not_crunched
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	add.l	#4,a1
	move.l	a1,d0
	bsr	Patch
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
.launch
	moveq	#_args_end-_args,d0
	lea	(_args,pc),a0
	movem.l	(_saveregs,pc),d1-d6/a2-a6
	addq.l	#4,a1
	IFD	CHIPDEBUG
	move.l	a1,$100.W
	ENDC
	jsr	(a1)
_fin

	IFD QUIT_AFTER_PROGRAM_EXIT
	pea	TDREASON_OK
	move.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)
	ELSE
	;remove exe
	move.l	d7,d1
	move.l	(dosbase,pc),a6
	jsr	(_LVOUnLoadSeg,a6)

	;return to CLI
	moveq	#0,d0
	move.l	(_saverts,pc),-(a7)
	rts


	ENDC
check_version:
	; only check executable sizes
	movem.l	d0-d1/a1,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	
	IFD _AGA
	cmp.l	#409940,D0
	beq.b	.ok  ; aga_unpacked
	cmp.l	#246892,D0
	beq.b	.ok	;  aga_packed
	ELSE
	cmp.l	#287256,d0
	beq.b	.ok	;  ecs_unpacked
	cmp.l	#125096,d0
	beq.b	.ok	;  ecs_packed
	ENDC

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.ok
	movem.l	(a7)+,d0-d1/a1
	rts
_program_err	jsr	(_LVOIoErr,a6)
	pea	(_program,pc)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	jmp	(resload_Abort,a2)

_AfterDecunch
	movem.l	(a7)+,d0-a6
	move.l	(a7),d0
	move.l	a0,a5

Patch
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	d0,a0
	move.l	-4(a0),d0
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	(a0),d0
	lsl.l	#2,d0
	move.l	d0,a0
	cmp.l	#$01fc0003,$2d28(a0)
	bne	.aga
	; ECS version
	move.l	#$01fc0000,$2d28(a0) ; debug ecs version (gfx bug)
	bra.b	.end
.aga
	lea	_pl_main(pc),a0
	move.l	_resload(pc),a2
	IFD	CHIPDEBUG
	move.l	A1,$100.W
	ENDC
	jsr	resload_Patch(a2)
.end
	movem.l	(a7)+,d0-d1/a0-a2
	rts

_pl_main
	PL_START
	; skip loop which reads the controllers 500 times for what??
	; and configures the ports to nonsense/nonworking
	PL_S	$036e4,$373e-$36e4
	; force joypad flag
	;PL_S	$16222,$16298-$16222
	PL_END

_disk1	dc.b	"df0",0	;for Assign
_program	dc.b	"GALAGA",0
_args	dc.b	10
_args_end	dc.b	0
	EVEN

_saveregs	ds.l	11
_saverts	dc.l	0
dosbase
	dc.l	0

	ENDC


