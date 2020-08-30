;*---------------------------------------------------------------------------
;  :Program.	4dsportsboxinghd.asm
;  :Contents.	Slave for "4D Sports Boxing" from Mindscape
;  :Author.	JOTD
;  :Original	v1 jffabre@free.fr
;  :Version.	$Id: battleisle.asm 0.5 2000/11/26 21:13:41 jah Exp $
;  :History.	23.05.01 started
;		23.05.01 finished
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
	OUTPUT	"4DSportsBoxing.slave"
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
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
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
;STACKSIZE = 10000
BOOTDOS
CACHE

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.3-B"
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

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"4D Sports Boxing"
			IFD	CHIP_ONLY
			dc.b	" (DEBUG/CHIP MODE)"
			ENDC
			dc.b	0
slv_copy		dc.b	"1991 Distinctive/Mindscape",0
slv_info		dc.b	"Installed & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

; file from disk 2 in case users forget to install disk 2!!
setupdat:
	dc.b	"setup.dat",0
program:
	dc.b	"4DBoxing",0
args:
	dc.b	10
args_end:
	dc.b	0
	even

	;initialize kickstart and environment

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		
		lea	setupdat(pc),a0
		bsr	must_exist
		
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	
	;quit
.quit		pea	TDREASON_OK
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

patch_main
	patch	$100,_fix_accessfault

	move.l	D7,A0
	bsr	_crackit

	move.l	D7,A1
	addq.l	#4,A1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts

_crackit:
	movem.l	A0-A2,-(A7)
	move.l	A0,A1
	add.l	#$20000,A1
	lea	.prot(pc),A2
	moveq	#8,D0
	bsr	hexsearch
	cmp.l	#0,A0
	beq.b	.skip

	; remove password protection

	move.l	#$397c0001,(A0)+
	move.l	#$d75a4e71,(A0)+
	move.l	#$584f4e71,(a0)
.skip
	movem.l	(A7)+,A0-A2
	rts

.prot:
	dc.l	$4eac84d0
	dc.l	$4a6cd75a

_fix_af_2:
	move.l	A1,D0
	rol.l	#8,D0	
	tst.b	D0
	bne.b	.ok	; real fastmem: ok

	; MSB was 0: check if lower part of MSW is below $20

	rol.l	#8,D0
	cmp.b	#$20,D0
	bcs.b	.ok	; D0 < $20: ok
	
	moveq.l	#0,D0
	rts
.ok
	; original code

	move.b	(A1),D0
	ext.w	D0
	ext.l	D0
	rts


_fix_af_3:
	move.l	A0,D0
	rol.l	#8,D0	
	tst.b	D0
	bne.b	.ok	; real fastmem: ok

	; MSB was 0: check if lower part of MSW is below $20

	rol.l	#8,D0
	cmp.b	#$20,D0
	bcs.b	.ok	; D0 < $20: ok
	
	moveq.l	#0,D0
	rts
.ok
	; original code

	move.b	(1,A0),D0
	ext.w	D0
	rts

_fix_af_4:
	move.l	A0,D0
	rol.l	#8,D0	
	tst.b	D0
	bne.b	.ok	; real fastmem: ok

	; MSB was 0: check if lower part of MSW is below $20

	rol.l	#8,D0
	cmp.b	#$20,D0
	bcs.b	.ok	; D0 < $20: ok
	
	moveq.l	#0,D0
	rts
.ok
	; original code

	move.b	(2,A0),D0
	ext.w	D0
	rts

_fix_accessfault:
	move.l	D0,-(A7)
	MOVE.L	-18(A5),D0		;00: 202DFFEE
	beq.b	.out			;NULL: kind of OK
	swap	D0
	lsr	#8,D0
	cmp.b	_expmem(pc),d0
	bne.b	.out			; MSB!=expmem MSB

	MOVE.W	-18(A5),D0		;00: 202DFFEE
	cmp.w	#$0020,D0
	bcs.b	.out			; chipmem, may happen

	; we have an address like xxxx0000: access fault: fix it
	; by setting pointer to 0: dirty but works
	CLR.L	-18(A5)
.out
	move.l	(A7)+,D0
	MOVEA.L	-18(A5),A0		;12: 206DFFEE
	RTS				;16: 4E75

; need to wait only when stopping sounds

;DMA_ON_SOUND_WAIT:MACRO
;dma_on_sound_wait_a\1_\2:
;	move.w	#$800\2,dmacon(a\1)	; stolen
;	bra	beamdelay_7
;	ENDM
DMA_OFF_SOUND_WAIT:MACRO
dma_off_sound_wait_a\1_\2:
	move.w	#$\2,dmacon(a\1)	; stolen
	bra	beamdelay_7
	ENDM
;---------------


;	DMA_ON_SOUND_WAIT	1,1
;	DMA_ON_SOUND_WAIT	1,2
;	DMA_ON_SOUND_WAIT	2,1
;	DMA_ON_SOUND_WAIT	2,2
;	DMA_ON_SOUND_WAIT	2,4
;	DMA_ON_SOUND_WAIT	2,8
	
	DMA_OFF_SOUND_WAIT	1,1
	DMA_OFF_SOUND_WAIT	1,8
	;DMA_OFF_SOUND_WAIT	1,2
	DMA_OFF_SOUND_WAIT	2,1
	DMA_OFF_SOUND_WAIT	2,4
	DMA_OFF_SOUND_WAIT	2,8



after_dma_write:
	movem.l	d2,-(a7)
	btst	#15,d2
	bne.b	.out
	and.w	#$8,d2
	beq.b	.out

	; DMA sound disable: wait

	bsr	beamdelay_7

.out
	movem.l	(a7)+,d2
	MOVE	#$0000,12(A0)	; stolen
	rts
	

beamdelay_7:
	movem.l	D0,-(A7)
	moveq.l	#7,D0
	bsr	beamdelay
	movem.l	(A7)+,D0	
	rts
	
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



pl_main		PL_START
		PL_L	$17B64,$4EB80100
		PL_L	$17A80,$4EB80100
		PL_PS	$17B7E,_fix_af_2
		PL_PS	$17B7E-$C6,_fix_af_3
		PL_PS	$17B7E+$1A,_fix_af_3
		PL_PS	$17B7E+$FA,_fix_af_4

	IFEQ	1
		PL_PS	$217E2,dma_on_sound_wait_a1_1
		PL_PS	$2184E,dma_on_sound_wait_a1_2
		PL_PS	$3480C,dma_on_sound_wait_a2_1
		PL_PS	$34844,dma_on_sound_wait_a2_2
		PL_PS	$3487C,dma_on_sound_wait_a2_4
		PL_PS	$348B4,dma_on_sound_wait_a2_8
	ENDC
	
		PL_PS	$3468A,after_dma_write

		PL_PS	$349C6,dma_off_sound_wait_a1_8
		PL_PS	$34892,dma_off_sound_wait_a2_8
		PL_PS	$3485A,dma_off_sound_wait_a2_4
		PL_PS	$34948,dma_off_sound_wait_a1_1
		PL_PS	$347EA,dma_off_sound_wait_a2_1

		PL_END


; 357c80010096 *
; 33410096 *
; 337c00080096
; 357c00080096
; 357c80080096 *
; 357c00040096
; 357c80040096 *
; 337c00010096
; 357c00010096


;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

hexsearch:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts

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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

;---------------


;============================================================================

	END
