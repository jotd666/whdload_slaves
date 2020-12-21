;*---------------------------------------------------------------------------
;  :Program.	BubbaNStixHD.asm
;  :Contents.	Slave for "BubbaNStix"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BubbaNStixHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================
    IFD CD32
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0000
    
    ELSE
	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
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
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

    IFD CD32
	include	kick31cd32.s    
    ELSE
	include	kick13.s    
    ENDC
    
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_assign1
	dc.b	"Bubba1",0
_assign2
	dc.b	"Bubba2",0
	IFD	CD32
_assign3
	dc.b	"CD0",0
_assign4
	dc.b	"Bubba",0
	ENDC
slv_name		dc.b	"Bubba'N'Stix "
		IFD CD32
		dc.b	"CD³²",0
		ELSE
		dc.b	"ECS",0
		ENDC
slv_copy		dc.b	"1993 Core Design",0
slv_info		dc.b	"adapted & fixed by JOTD",10
	IFD CD32
		dc.b	10,"Thanks to Henri Lange for CD image"
	ELSE
		dc.b	10,"Thanks to Bored Seal"
	ENDC
		dc.b	10,10,"Version 3.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

	IFD  CD32
_intro:
	dc.b	"Intro",0
	ENDC
_program:
	dc.b	"Bubba",0
_args		dc.b	10
_args_end
	dc.b	0
slv_config
	;dc.b    "C1:X:Trainer Infinite energy:0;"
	;dc.b	"C5:B:disable speed regulation;"
	dc.b	0	
	EVEN



_bootdos
	clr.l	$0.W


	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

	;enable cache
	;	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	;	move.l	#WCPUF_All,d1
	;	jsr	(resload_SetCPU,a2)

		IFD   CD32
		bsr	_patch_cd32_libs
		ENDC

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
	IFEQ	KICKSIZE-$80000
		lea	_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		move.l	_custom1(pc),d0
		bne.b	.skipintro

	;load exe
		lea	_intro(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		bne	.ok1			;file not found
		pea	_intro(pc)
		bra	_end
.ok1
	;patch here

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

.skipintro:
	ENDC

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		bne	.ok2			;file not found
		pea	_program(pc)
		bra	_end
.ok2

	;patch here
		bsr	_patch_exe
	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_end
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts


_load_a5
	lea	$dff000,a5
	bra.b	_wait_blit
_load_a6
	lea	$dff000,a6
_wait_blit
	btst	#6,dmaconr+$dff000
	bne.b	_wait_blit
	rts

_wb_1:
	bsr.b	_wait_blit
	; stolen code
	ADD.L	(A0)+,D1		;0D30E: D298
	MOVE.L	D1,(A3)			;0D310: 2681 blit here
	MOVEA.L	(A0)+,A2		;0D312: 2458
	rts

    IFD CD32

_patch_exe:
	;;bsr	_patch_joypad
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1
	lea	_pl_main(pc),a0
	jsr	resload_Patch(a2)
	rts

_pl_main:
	PL_START
	PL_R	$83F8		; drive stuff
	PL_PS	$1548,_load_a5	; wait blit problem
	PL_PS	$3BAC,_load_a6	; wait blit problem
	PL_PS	$49D4,_load_a6
	PL_PS	$D30E,_wb_1
	PL_END
    
    ELSE
    
COPYLOCK_ID = $38891291


_patch_exe:
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1

	move.l	$38F8(a1),a0	; get address
	move.l	#COPYLOCK_ID,$F4.W
	move.l	#COPYLOCK_ID,(a0)		; modify copylock entry address (strange!)

	lea	_pl_ecs(pc),a0
	jsr	resload_Patch(a2)

	rts

_pl_ecs:
	PL_START
	PL_W	$2,$391C	; skip copylock call

	PL_R	$7A16		; drive stuff
	PL_PS	$0BFC,_load_a5	; wait blit problem
	PL_PS	$325A,_load_a6	; wait blit problem
	PL_PS	$4052,_load_a6
	PL_PS	$C718,_wb_1

	PL_END
    ENDC
    
_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	0

;============================================================================

