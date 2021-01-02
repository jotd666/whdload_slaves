;*---------------------------------------------------------------------------
;  :Program.	TestDrive2HD.s
;  :Contents.	Slave for "Test Drive II" from Accolade
;  :Author.	JOTD
;  :Original	v1 
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9, vasm
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"TestDrive2.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================
;CHIP_ONLY
	IFD	CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

BLACKSCREEN
;DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
CACHE
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS
CBDOSLOADSEG

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_tdboot
	dc.b	"tdboot",0

slv_name		dc.b	"Test Drive II"
	IFD	CHIP_ONLY
	dc.b	" (chip only)"
	ENDC
	dc.l	0
slv_copy		dc.b	"1989 Accolade",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"duel",0
_args		dc.b	10
_args_end
	dc.b	0
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

;============================================================================

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#'s',1(a0)
	bne.b	.nosong
	cmp.b	#'s',5(a0)
	bne.b	.nosong

	; sfx/song, patch write into read-only custom register

	addq.l	#4,d1
	move.l	d1,a1
	lea	h0_end_ptr(pc),a0
	move.l	($1A6,a1),(a0)
	lea	pl_song(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

.nosong
	rts

pl_song:
	PL_START
	; snoop , writing into read-only register

	PL_L	$4FA+4,$DFF09C
	PL_L	$A40+4,$DFF09C
	PL_L	$A70+4,$DFF09C
	
	; various post-dmacon write waits
	
	PL_PSS	$8A,stop_dma_audio,2
	PL_PS	$110,set_dmacon_sfx
	PL_PSS	$1A4,set_dmacon_music,4
	PL_PS	$1e8,turn_off_dma_wait
	PL_PSS	$23A,stop_dma_audio,2
	PL_PSS	$42E,stop_dma_audio,2
	PL_PSS	$502,stop_dma_audio,2

	;;PL_PS	$776,write_audptr
	PL_PS	$5d2,wait_dma
	
	PL_PSS	$07e0,set_dmacon_music,4
	PL_PS	$8fa,turn_off_dma_wait
	PL_PSS	$a78,stop_dma_audio,2
	PL_END
	
turn_off_dma_wait:
	MOVE.W	D2,$dff096		;08fa: 33c200dff096
	bsr	dmadelay
	rts
stop_dma_audio	
	MOVE.W	#$F,$dff096		;08fa: 33c200dff096
	bsr	dmadelay
	rts
; just after dma write
wait_dma:
	bsr	dmadelay
	MOVEA.L	40(A3),A6		;05d2: 2c6b0028
	CLR.W	(A6)			;05d6: 4256
	rts
dmadelay
	movem.l	D0,-(A7)
	; dma enable should be followed by a wait
	; now that the code runs from fastmem/on fast amigas
	; some sfx could be wrongly played
	moveq.l	#7,d0
	bsr	beamdelay
	movem.l	(a7)+,D0
	rts
	
write_audptr
	MOVEA.L	48(A3),A6		;0776: 2c6b0030
	; write audio pointer
	MOVE.L	A0,(A6)			;077a: 2c88

	bra	dmadelay
	
set_dmacon_sfx:
	movem.l	D0-d1/a0-a1/a6,-(A7)
	; dma enable should be followed by a wait
	; now that the code runs from fastmem/on fast amigas
	; some sfx could be wrongly played
	;
	; wrap that in a disable/enable block so the music
	; doesn't spoil it (it's no use waiting without blocking
	; the interrupts as the music is playing in a separate
	; interrupt/process/whatever)
	move.l	$4.W,A6
	jsr	(_LVODisable,a6)
	MOVE.W	D7,$dff096
	moveq.l	#7,D0
	bsr	beamdelay
	jsr	(_LVOEnable,a6)
	movem.l	(a7)+,D0-d1/a0-a1/a6
	rts
	
set_dmacon_music:
	movem.l	D0-d1/a0-a1/a6,-(A7)
;	move.l	$4.W,A6
;	jsr	(_LVODisable,a6)
	move.l	h0_end_ptr(pc),a0
	move.w	(a0),$dff096
	; dma enable should be followed by a wait
	; now that the code runs from fastmem/on fast amigas
	; some sfx could be wrongly played
	moveq.l	#7,D0
	bsr	beamdelay
;	jsr	(_LVOEnable,a6)
	movem.l	(a7)+,D0-d1/a0-a1/a6
	rts
	
h0_end_ptr
	dc.l	0
	
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

_bootdos	move.l	(_resload,pc),a2		;A2 = resload


	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_tdboot(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

	;patch

	bsr	_patchexe

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

.end		moveq	#0,d0
		rts

set_copper:
	movem.l	d0-d1,-(a7)
	moveq.l	#0,d0
	move.l	#$8400,d1
.wait
	move.w	$DFF006,d0
	cmp.l	d1,d0
	bcs.b	.wait
	movem.l	(a7)+,d0-d1
	MOVE.L	A0,$00DFF080
	rts
	
_patchexe:
	movem.l	d0-a6,-(a7)

	lea	pl_main_v1(pc),a0
	bsr	get_version
	cmp.l	#2,d0
	bne.b	.pp
	lea	pl_main_v2(pc),a0
.pp
	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	(resload_PatchSeg,a2)
	
	movem.l	(a7)+,d0-a6
	rts

.prot1:
	dc.l	$584F6626,$41EC81E8
.prot2:
	dc.l	$584F6732,$0C6D0003

get_version:
	movem.l	a0,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#108868,D0
	beq.b	.v1
	cmp.l	#109248,D0
	beq.b	.v2

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.v1
	moveq	#1,d0
	bra.b	.out
.v2
	moveq	#2,d0

.out
	movem.l	(a7)+,a0
	rts

pl_main_v1
	PL_START
	; protection
	PL_B	$00052A,$60
	PL_NOP	$0041CA,2
	
	; speed regulation
;	PL_PS	$0016BE,sync_dot_fade_1	; works but too scattered
	PL_PS	$0016C8,sync_dot_fade_2
	PL_P	$00588A,set_copper
	PL_END
	
pl_main_v2
	PL_START
	; protection
	PL_B	$000320,$60
	PL_NOP	$002F94,2
	
	; speed regulation
	
;;	PL_PS	$005CBA+$010468,sync_dot_fade_2
	PL_P	$004654,set_copper
	PL_END

sync_dot_fade_1:
	movem.l	d0-d1/a0,-(a7)
	lea	.last_counter(pc),a0
	move.l	(a0),d0
	beq.b	.first
	bmi.b	.first	; reset before it wraps
	add.l	#8,d0
.wait
	cmp.l	-$30E2(A4),d0
	bcc.b	.wait
.first
	; store current counter
	move.l	-$30E2(A4),(a0)
	movem.l	(a7)+,d0-d1/a0
	
	MOVEA.L	$0004(A0),A2	; 0016BE: 	2468 0004
	CLR.W	D7	; 0016C2: 	4247
	rts
.last_counter
	dc.l	0
	
DOT_FADE_NB_CALLS = 20

sync_dot_fade_2:
	movem.l	d0/a0,-(a7)
	lea	.last_counter(pc),a0
	move.l	(a0),d0
	beq.b	.first
	
	lea	.divider_counter(pc),a0
	subq.l	#1,(a0)
	bne.b	.avoid
	move.l	#DOT_FADE_NB_CALLS,(a0)
	lea	.last_counter(pc),a0
	tst.l	d0
	beq.b	.first
	bmi.b	.first	; reset before it wraps
	add.l	#1,d0
	; wait 1 VBL every 5 call
.wait
	cmp.l	-$30E2(A4),d0
	bcc.b	.wait
.first
	; store current counter
	move.l	-$30E2(A4),(a0)
.avoid
	movem.l	(a7)+,d0/a0
	ADD.W	(A0),D4	; 0016C8: 	D850	
	AND.W	#$0007,D4	; 0016CA: 	C87C 0007
	RTS
.last_counter
	dc.l	0
.divider_counter
	dc.l	DOT_FADE_NB_CALLS
	
;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

_hexsearch:
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
