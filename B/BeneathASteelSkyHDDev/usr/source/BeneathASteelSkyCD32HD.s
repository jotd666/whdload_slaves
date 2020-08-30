;*---------------------------------------------------------------------------
;  :Program.	Beneath A Steel Sky CD32HD.asm
;  :Contents.	Slave for "Beneath A Steel Sky CD32"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: Beneath A Steel Sky CD32HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/graphics.i

	IFD BARFLY
	OUTPUT	"BeneathASteelSkyCD32.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

USE_FASTMEM

	IFD	USE_FASTMEM
CHIPMEMSIZE	= $1A0000
FASTMEMSIZE	= $80000
	ELSE
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $40000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
;DOSASSIGN
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
HD_Cyls = 1000


;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick31.s

;============================================================================


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

slv_name		dc.b	"Beneath A Steel Sky CD³²"
	IFND	USE_FASTMEM
	dc.b	" (no fastmem)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1994 Virtual Theatre/Virgin",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
			dc.b	"Thanks to Wepl for ISO image",10,10
			dc.b	"Version "
	DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0


	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	0

	EVEN


_program:
	dc.b	"SteelSky",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

SPRITE_BUFFER_LENGTH = $4848A-$46B10
OTHER_BUFFER_LENGTH = $36B10
SOUND_BUFFER_LENGTH = $4848A-$46FFE

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
	
		IFD	USE_FASTMEM
		move.l	#SPRITE_BUFFER_LENGTH,d0
		move.l	#MEMF_CHIP,d1
		move.l	$4.W,a6
		jsr	_LVOAllocMem(a6)
		lea	sprite_buffer(pc),a0
		move.l	d0,(a0)

		move.l	#OTHER_BUFFER_LENGTH,d0
		move.l	#MEMF_CHIP,d1
		move.l	$4.W,a6
		jsr	_LVOAllocMem(a6)
		lea	other_buffer(pc),a0
		move.l	d0,(a0)

		move.l	#SOUND_BUFFER_LENGTH,d0
		move.l	#MEMF_CHIP,d1
		move.l	$4.W,a6
		jsr	_LVOAllocMem(a6)
		lea	sound_buffer(pc),a0
		move.l	d0,(a0)

		ENDC

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	IFD	USE_FASTMEM
		bsr	_patch_alloc
	ENDC

	;load exe
		lea	_program(pc),a0
		jsr	(resload_GetFileSize,a2)
		cmp.l	#298700,d0
		beq.b	.ok
		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.ok
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

_patch_exe
	IFD	USE_FASTMEM
	bsr	_rem_patch_alloc

	move.l	d7,a1
	add.l	#4,a1
	add.l	#$10000,a1
	move.l	other_buffer(pc),a0	; chipmem
	move.l	#OTHER_BUFFER_LENGTH/4-1,d0
	move.l	a1,a2	; fastmem block
	sub.l	a0,a2	; diff vs fastmem & chipmem
.copy1
	move.l	(a1)+,(a0)+
	dbf	d0,.copy1

	lea	block_offset(pc),a0
	move.l	a2,(a0)

	move.l	d7,a1
	add.l	#4,a1

	; relocate sprite buffer references to chipmem (tricky)
	; so program can run in fastmem

	move.l	sprite_reloc_offsets(pc),d0
	move.l	2(a1,d0.l),a2	; address of the first sprite buffer

	move.l	#(SPRITE_BUFFER_LENGTH/2)-1,d0
	move.l	sprite_buffer(pc),a0	; buffer in chip memory
	move.l	a2,d1
	sub.l	a0,d1			; difference between fastmem and chipmem copy
.copy
	move.w	(a2)+,(a0)+
	dbf	d0,.copy
	
	lea	sprite_reloc_offsets(pc),a0
.loop
	move.l	(a0)+,d0
	bmi.b	.end

	move.l	d0,a2
	add.l	a1,a2	; add program base
	sub.l	d1,(2,a2)	; substract the difference between non-reloc & chipmem
	bra.b	.loop	
.end
	ENDC


	move.l	d7,a1
	add.l	#4,a1

	lea		program_start(pc),a0
	move.l	a1,(a0)
	move.l	a1,$100.w	; debug
	
	; copy data in the buffer
	IFD	USE_FASTMEM
	move.l	a1,a2
	add.l	#$46FFE,a2
	move.l	#SOUND_BUFFER_LENGTH,d0
	lsr.l	#2,d0
	subq.l	#1,d0
	move.l	sound_buffer(pc),a0
.copys
	move.l	(a2),(a0)+
	move.l	#$4AFC4AFC,(a2)+	; trash the original address
	dbf	d0,.copys

	move.l	sound_buffer(pc),a1
	lea	pl_sound_check(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	d7,a1
	add.l	#4,a1
	
	ENDC
	
	move.l	_resload(pc),a2
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)
	rts
program_start:
	dc.l	0
	
	IFD	USE_FASTMEM
pl_sound_check:
	PL_START
	;PL_PS	$047C22-$046FFE,set_audio_channel_0
	;PL_PS	$047C34-$046FFE,set_audio_channel_1
	;PL_PS	$047C46-$046FFE,set_audio_channel_2
	;PL_PS	$047C58-$046FFE,set_audio_channel_3
	PL_END
	; list of offsets with MOVE.L #spriteimage,dx
sprite_reloc_offsets
	dc.l	$007646,$00765A,$00766C,$00767E,$00769A,$0076B6,$0076D4
	dc.l	$0076F2,$007712,$00773A,$00A81E,-1
sprite_buffer
	dc.l	0
other_buffer
	dc.l	0
sound_buffer
	dc.l	0
block_offset
	dc.l	0

		
FIX_BLIT:MACRO
	cmp.l	#CHIPMEMSIZE,a\1
	bcs.b	.dont_fix_a\1
	sub.l	block_offset(pc),a\1
.dont_fix_a\1
	ENDM

do_blit_2
	FIX_BLIT	0
	FIX_BLIT	4

	MOVE.L	A0,72(A6)		;00BDCA: 2D480048
	MOVE.L	A0,84(A6)		;00BDCE: 2D480054
	MOVE.L	A4,80(A6)		;00BDD2: 2D4C0050
	MOVE	D7,88(A6)		;00BDD6: 3D470058
	add.l	#2+8,(a7)
	rts


do_blit_1
	FIX_BLIT	0
	FIX_BLIT	3
	FIX_BLIT	4

	MOVE.L	A0,72(A6)		;00BD88: 2D480048
	MOVE.L	A0,84(A6)		;00BD8C: 2D480054
	MOVE.L	A3,76(A6)		;00BD90: 2D4B004C
	MOVE.L	A4,80(A6)		;00BD94: 2D4C0050
	MOVE	D7,88(A6)		;00BD98: 3D470058
	add.l	#2+12,(a7)
	rts

	ENDC

pl_main
	PL_START
	PL_P	$8B4A,avoid_crash	; the one which makes LINC crash
	PL_P	$911C,menu_correction	; access fault in the menu late in the game
	PL_P	$B226,_quit		; instead of reset
	PL_PS	$CB0C,avoid_af		; access fault #1
	PL_PS	$D7DA,patch_allocmem	; not sure about the Z flag unset (move.l D0,A3)

	; a problem with freeanim?
	; well, DMACON register was not properly set

	PL_PS	$00EB24,dmacon_d1
	PL_PS	$00EB92,dmacon_d1

	PL_PS	$00EBC4,dmacon_d5
	PL_PS	$00ED0C,dmacon_d5
	PL_PS	$00ED2C,dmacon_d5
	PL_PS	$00ED4C,dmacon_d5
	PL_PS	$00ED6C,dmacon_d5

	IFD	USE_FASTMEM
	PL_PS	$BD88,do_blit_1
	PL_PS	$BDCA,do_blit_2
	
	PL_P	$046FFE,sound_routine
	
	ENDC
	
	PL_END


	IFD	USE_FASTMEM

sound_routine
	; call original code, but in chipmem
	move.l	sound_buffer(pc),-(a7)
	RTS
	
	
DEF_SET_AUDIO_CHANNEL:MACRO
set_audio_channel_\1:
	movem.l	D0/A0-A1,-(a7)
	move.l	program_start(pc),a1
	move.l	a1,a0
	add.l	#\2,a0
	move.l	(a0),d0
	
	cmp.l	#$200000,d0
	bcs.b	.ok
	; fastmem
	illegal
.ok

	add.l	a1,d0
	MOVE.L	d0,($A0+\1*16,A6)	;047C22: 2D7AFECE00A0
	movem.l	(a7)+,D0/a0-a1
	rts
	ENDM
	
	DEF_SET_AUDIO_CHANNEL	0,$047AF2
	DEF_SET_AUDIO_CHANNEL	1,$047B40
	DEF_SET_AUDIO_CHANNEL	2,$047B8C
	DEF_SET_AUDIO_CHANNEL	3,$047BD8	
_patch_alloc:
	movem.l	a0/a1,-(a7)
	move.l	$4.W,A0
	add.w	#_LVOAllocMem+2,a0
	lea	_alloc_save(pc),a1
	move.l	(a0),(a1)
	lea	_my_alloc(pc),a1
	move.l	a1,(a0)
	bsr	_flushcache
	movem.l	(a7)+,a0/a1
	rts

_rem_patch_alloc:
	movem.l	a0,-(a7)
	move.l	$4.W,A0
	add.w	#_LVOAllocMem+2,a0
	move.l	_alloc_save(pc),(A0)
	bsr	_flushcache
	move.l	(a7)+,a0
	rts

_my_alloc:
	btst	#MEMB_CHIP,d1
	beq.b	.out
	cmp.l	#$48494,d0	; size of the code segment allocation
	beq.b	.fix
	bra.b	.out
.fix
	bclr	#MEMB_CHIP,d1
.out
	move.l	_alloc_save(pc),-(A7)
	rts

_alloc_save
	dc.l	0
	ENDC


DMACON_DX:MACRO
dmacon_d\1
	btst	#15,d\1
	beq.b	.sk
	ori.w	#$0120,d\1
.sk
	move	d\1,$DFF096
	rts
	ENDM

	DMACON_DX	1
	DMACON_DX	5

patch_allocmem
	jsr	_LVOAllocMem(a6)
	move.l	d0,a3
	tst.l	d0		; really tests result of allocation
	rts


	IFEQ	1
avoid_af_2
	addq.w	#1,d1
	asl.w	#1,d1
	move.l	a0,d2
	bmi.b	.skip
	move.b	(a0)+,d2
	rts
.skip
	clr.b	d2
	addq.l	#1,a0
	rts

avoid_af_3
	move.l	a0,d1
	bmi.b	.skip
	move.b	(a0)+,d2
	move.w	#7,d1
	btst	D1,D2
	rts
.skip
	addq.l	#1,a0
	move.w	#7,d1
	clr.b	d2
	rts
	ENDC

avoid_crash:
	move.l	D1,-(a7)
	move.l	(A3,D0.W),D1
	and.l	#$FFFFFF,D1	; avoids access fault with LINC
	move.l	D1,A6
	add.l	A3,A6
	move.l	(A7)+,D1
	jmp	(A6)

avoid_af:
	movem.l	D0/D1,-(A7)
	move.l	A1,D0
	movem.l	(A7)+,D0/D1
	bpl.b	.ok

	; access fault on $FFFFxxxx address: return with D0=1

	moveq.l	#1,D0
	addq.l	#4,A7
	rts

.ok
	move.w	(A0)+,$E(A1)	; stolen code
	MOVE	(A0),16(A1)		;00CB10: 33500010
	addq.l	#2,(a7)
	rts

menu_correction:
	move.l	(A1,D0.W),D1
	and.l	#$FFFFFF,D1	; removes MSB which causes access fault
	add.l	D1,A1
	move.l	(A7)+,D1
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
	movem.l	d0-a6,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d0-a6
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




;============================================================================

	END
