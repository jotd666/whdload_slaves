;*---------------------------------------------------------------------------
;  :Program.	neuromancer.asm
;  :Contents.	Slave for "Neuromancer" from Interplay
;  :Author.	Wepl
;  :Original	v1 
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

;CHIP_ONLY

	IFD BARFLY
	OUTPUT	"Neuromancer.slave"
	IFND	CHIP_ONLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD CHIP_ONLY
CHIPMEMSIZE	= $C0000
FASTMEMSIZE	= $00000
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
BLACKSCREEN
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111
BOOTDOS
CACHE
;DISKSONBOOT
DOSASSIGN
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
STACKSIZE = 8000
FONTHEIGHT     = 8
SEGTRACKER

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

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


DECL_VERSION:MACRO
	dc.b	"3.2"
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

_gfxname
	dc.b	"graphics.library",0
_df0
	dc.b	"df0",0

slv_name		dc.b	"Neuromancer"
	IFD	CHIP_ONLY
	DC.B	" (DEBUG/CHIP MODE)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1988/1989 Interplay",0
slv_info		dc.b	"Installed by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN
slv_config
	dc.b	"C4:B:skip timing fixes (slow machines);"
    dc.b    0

_program:
	dc.b	"neuro",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos	
        move.l	_resload(pc),a2		;A2 = resload
        
	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)


	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_df0(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end

		;patch

		bsr	_patchexe
        ; game is using graphics library, okay, but it's also
        ; NOT waiting for blitter...
        move.l  no_timing_fix(pc),d0
        bne.b   .skipgp
		bsr	patch_gfxlib
.skipgp

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1

		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check

		movem.l	d0/d7/a2/a6,-(a7)

		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0

		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_end		moveq	#0,d0
		rts

patch_gfxlib:
	move.l	a6,-(A7)
	lea	(_gfxname,pc),a1
	move.l	(4),a6
	jsr	(_LVOOldOpenLibrary,a6)
	move.l	d0,a6			;A6 = dosbase

	PATCH_XXXLIB_OFFSET	BltClear
	PATCH_XXXLIB_OFFSET	BltBitMap
	PATCH_XXXLIB_OFFSET	ClipBlit
	PATCH_XXXLIB_OFFSET	Draw
	move.l	(A7)+,a6
	rts

; completely untested, don't know if the code is used...

MOVETRAP:MACRO
_move\1\2:
	move.l	A0,-(A7)
	move.l	6(A7),A0
	move.l	(a0),a0	; address to change
	move.\1	\2,(a0)	; change it
	bsr	_flushcache	; flush cache
	move.l	(A7)+,A0
	addq.l	#4,2(a7)	; skip 4 bytes
	rte
	ENDM

	MOVETRAP	b,d1
	MOVETRAP	b,d0
	MOVETRAP	w,d0

new_BltBitMap
    pea .follow(pc)
	move.l	old_BltBitMap(pc),-(a7)
    rts
.follow
	movem.l	d0-d1/a0-a1,-(a7)
	jsr	_LVOWaitBlit(a6)
	movem.l	(a7)+,d0-d1/a0-a1
	rts

new_ClipBlit
    pea .follow(pc)
	move.l	old_ClipBlit(pc),-(a7)
    rts
.follow
	movem.l	d0-d1/a0-a1,-(a7)
	jsr	_LVOWaitBlit(a6)
	movem.l	(a7)+,d0-d1/a0-a1
	rts

new_BltClear
    pea .follow(pc)
	move.l	old_BltClear(pc),-(a7)
    rts
.follow
	movem.l	d0-d1/a0-a1,-(a7)
	jsr	_LVOWaitBlit(a6)
	movem.l	(a7)+,d0-d1/a0-a1
	rts
new_Draw
    pea .follow(pc)
	move.l	old_Draw(pc),-(a7)
    rts
.follow
	movem.l	d0-d1/a0-a1,-(a7)
	jsr	_LVOWaitBlit(a6)
	movem.l	(a7)+,d0-d1/a0-a1
	rts

_moved0branch:
	move.l	2(a7),a0		; return address (we can trash a0)
	move.l	(a0),a0
	move.b	d0,(a0)			; change code (branch test instruction)
	bsr		_flushcache		; but flush cache
	RTE

_patchexe:
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2

	; install trap handlers

	lea	_moved0branch(pc),a0	; trap #c
	move.l	a0,$B0.W
	lea	_movebd1(pc),a0		; trap #d
	move.l	a0,$B4.W
	lea	_movewd0(pc),a0		; trap #e
	move.l	a0,$B8.W
	lea	_movebd0(pc),a0		; trap #f
	move.l	a0,$BC.W

	; patch file

	move.l	d7,a1
	lea	pl_main(pc),a0
	jsr	resload_PatchSeg(a2)


	movem.l	(a7)+,d0-a6
	rts


; < D0: value of D0 in line
; .x: DBF D0,x (here 
active_d0_delay
	lsr.l	#5,d0		;  divide by 32
	bsr	beamdelay
	move.w	#$FFFF,d0
	rts

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.l  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	subq.l	#1,d0
	bne.b	.bd_loop1
	rts

_pre_branch:
	bsr	_flushcache
	MOVE.B	0(A1,D0.L),D1		;18F7A: 12310800
	CMP.B	2(A0),D1		;18F7E: B2280002
	RTS
	
_restore_bne:
	move.l	A0,-(a7)
	move.l	4(a7),a0	; return address
	sub.l	#$A356-$AB58,a0
	move.l	#$6600002E,(a0)	; original behavior restored: do not redraw panel
	bsr	_flushcache
	move.l	(A7)+,A0
	move.l	($C,a3),(0,a3)	; stolen code
	rts

pl_main:
	PL_START
    ; section 1
	PL_B	$118,$60
	PL_NOP	$2BA,2
	PL_NOP	$2E8,2
	PL_R	$35E		; insert disk requester



	; section 4
    ; install handler for self-modifying code
	PL_W    $2F50,$4E4D
    
    ; section 8
    PL_W	$82A8,$4E4C			; trap #12
    
    ; section 9
	; remove password protection
    PL_NOP    $090AE,6
    PL_B    $09184,$60

    ; section 10
	; fix bug for games loaded from title screen
	;PL_NOP	$AB58,4
	;PL_PS	$A350,_restore_bne; remove the redraw while in game

    PL_IFC4
    
    PL_ELSE
    ; proper delay on sound dma. This is known to freeze games
    ; when OS is running (Loom was the first one I witnessed)
    ; besides trashing the music
    PL_PSS  $00FB8,move_16_a0_dmacon,2
    PL_PSS  $00FD2,move_18_a0_dmacon,2
    PL_PSS  $01118,move_16_a1_dmacon,2
    PL_PSS  $01156,move_18_a1_dmacon,2
	PL_S    $115E,$1166-$115E   ; skip delay, we do it properly

    ; section 14
	PL_P	$10AF8,active_d0_delay

    ; skip delay after blit bitmap (should have been blitter wait!)
    PL_S    $126EC,12
    PL_ENDIF
    
    ; section 17
    PL_W	$14208,$4E4E
	PL_W	$1465C,$4E4F
	PL_W	$14664,$4E4F
	PL_W	$146A2,$4E4F
	PL_W	$14D9C,$4E4F

    ; section 20
	PL_PSS	$18F7A,_pre_branch,2

	PL_END

move_16_a0_dmacon
    MOVE    16(A0),_custom+dmacon
    bra.b soundwait
move_18_a0_dmacon
    MOVE    18(A0),_custom+dmacon
    bra.b soundwait
move_16_a1_dmacon
    MOVE    16(A1),_custom+dmacon
    bra.b soundwait
move_18_a1_dmacon        
    MOVE    18(A1),_custom+dmacon
soundwait
	move.w  d0,-(a7)
	move.w	#4,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
	rts 


_tag
		dc.l	WHDLTAG_CUSTOM4_GET
no_timing_fix	dc.l	0
		dc.l	0