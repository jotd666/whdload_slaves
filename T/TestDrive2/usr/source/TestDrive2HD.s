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


; WHDLoad 17 interface (PL_IFCx needs 17.2): nothing here uses the version 20
; additions (ws_MemConfig, WHDLTAG_EXPMEMSIZE_GET), so older WHDLoads run it too.
slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.6b"
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
slv_config
	dc.b "C2:B:Enhanced framerate;"
	IFD VERIFY
	dc.b "C3:B:reproducible verification;"
	dc.b "C4:B:slow renderer verification;"
	dc.b "C5:X:scripted driving verification:0;C5:X:force engine damage verification:1;C5:X:force fatal crash verification:2;C5:X:sub-unit with zero fraction:3;C5:X:straight driving tape:4;"
	ENDC
	dc.b    "C1:X:trainer infinite lives:0;"	
	dc.b	0

slv_name		dc.b	"Test Drive II"
	IFD	CHIP_ONLY
	dc.b	" (chip only)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1989 Accolade",0
slv_info		dc.b	"adapted by JOTD and Vesuri",10
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

        lea    old_kbint(pc),a1
        lea kbint_hook(pc),a0
        cmp.l   (a1),a0
        beq.b   .done
        move.l  $68.W,(a1)
        move.l  a0,$68.W
.done

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

		bsr render_interrupt_option
		jsr	(4,a1)
		bsr render_interrupt_restore
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

.end		moveq	#0,d0
		rts

	include "simulation.s"
	include "render.s"

	IFD VERIFY
; Stress instrument (CUSTOM4): delay only drawing; VBL and task scheduling remain live.
verify_slow_copper:
	move.l d0,-(a7)
	move.w #65535,d0
.delay
	dbf d0,.delay
	move.l (a7)+,d0
	bra set_copper
	ENDC

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
	
; Intro car (original bug). The copper wrote DDFSTOP on the line above a viewport, at hpos
; $a4 for 5-plane viewports after their 32-colour palette. When the stop dropped from $a8 to
; $a0, neither stop matched on that line, the fetch window stayed open and the viewport's first
; line fetched one extra word: every line then read 2 bytes further, and each intro car showed
; 16 pixels left for one field. For those viewports, when the new stop is $a0 or less, the move
; now writes $a8, which always closes that line's window, and the real stop follows after the
; modulo moves (hpos $b0). Other viewports keep the original single move. Later writes, at or
; past $d8 or on the viewport's first line, would also work on hardware but leave a stale column
; at FS-UAE's right edge.
intro_ddfstop_close:			; replaces the pushes of the DDFSTOP move at $4c50
	move.l	(a7)+,a1
	lea	intro_ddfstop_late(pc),a0
	clr.w	(a0)
	move.w	-10(a5),d0
	cmp.w	#$a0,d0
	bhi.b	.push
	move.l	4(a5),d1		; the viewport's caller in duel
	sub.l	a1,d1
	cmp.l	#$343c-$4c56,d1
	beq.b	.palette
	cmp.l	#$4e9a-$4c56,d1
	bne.b	.push
.palette
	move.l	12(a5),a0
	cmp.b	#5,5(a0)		; planes
	bne.b	.push
	lea	intro_ddfstop_late(pc),a0
	move.w	d0,(a0)
	move.w	#$a8,d0
.push
	move.w	d0,-(a7)
	move.w	#$94,-(a7)
	jmp	(a1)

intro_ddfstop:				; replaces clr.w -4(a5); lea 48(sp),sp at $4c8c
	move.l	(a7)+,a1
	lea	48(a7),a7
	clr.w	-4(a5)
	move.w	intro_ddfstop_late(pc),d0
	beq.b	.done
	move.l	a1,-(a7)
	move.w	d0,-(a7)		; DDFSTOP value
	move.w	#$94,-(a7)
	move.l	8(a5),-(a7)		; copper list
	lea	$46e2-$4c92(a1),a0	; the game's copper move builder
	jsr	(a0)
	addq.l	#8,a7
	move.l	(a7)+,a1
.done
	jmp	(a1)

intro_ddfstop_late:
	dc.w	0			; nonzero: the real DDFSTOP still to be written

_patchexe:
	movem.l	d0-a6,-(a7)

	lea	pl_main_v1(pc),a0
	bsr	get_version
	cmp.l	#2,d0
	bne.b	.v1
	lea	pl_main_v2(pc),a0
	bra.b	.pp
.v1
	bsr	sim_init
	lea	pl_main_v1(pc),a0
.pp
	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	(resload_PatchSeg,a2)
	bsr	sim_set_deadline	; v1 only: v2 reads no options
	movem.l	(a7)+,d0-a6
	rts


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
	include "simulation-patches.i"
	PL_IFC2
	PL_PS $006c66,render_subunit_main
	PL_PS $006daa,render_subunit_mirror
	PL_PS $006474,render_subunit_latch
	PL_PS $007a34,render_subunit_forward
	PL_PS $007a78,render_subunit_oncoming
	PL_PS $00801a,render_subunit_opponent
	PL_PS $008052,render_subunit_police
	PL_PS $0073ec,render_subunit_road_angles
	PL_S $0073f2,$742a-$73f2	; render_subunit_road_angles skips to 0742a
	PL_PSS $008c90,render_subunit_backdrop,8
	PL_ENDIF
	; protection
	PL_B	$00052A,$60
	PL_NOP	$0041CA,2
	
	; speed regulation
;	PL_PS	$0016BE,sync_dot_fade_1	; works but too scattered
	PL_PS	$0016C8,sync_dot_fade_2
	PL_P	$00588A,set_copper
	PL_PSS	$004C50,intro_ddfstop_close,2	; intro car jump
	PL_PSS	$004C8C,intro_ddfstop,2
    
    ; keyboard support
	PL_PS	$001A1A,read_joydat
	PL_PS	$00EAA2,read_joydat
    
    PL_PS   $001A02,read_fire1
    PL_PSS  $00EA8E,read_fire2,2
    
    PL_IFC1X    0
    ;PL_W    $59B6,10   ; start with 10 lives
    PL_NOP  $005D0E,4
    PL_ENDIF

	IFD VERIFY
	; Instruments. PatchSeg applies entries in order: these win at shared offsets.
	PL_IFC3
	PL_W $00E9F0,$7200	; RNG without beam position: moveq #0,d1
	PL_NOP $00E9F2,4
	PL_ENDIF
	PL_IFC4
	PL_P $00588A,verify_slow_copper
	PL_ENDIF
	PL_IFC5X 3
	PL_PS $006c66,render_zero_main
	PL_PS $006daa,render_zero_mirror
	PL_ENDIF
	PL_IFC5
	PL_PS $001A1A,verify_read_joydat
	PL_PS $00EAA2,verify_read_joydat
	PL_ENDIF
	ENDC
	PL_END
	
pl_main_v2
	PL_START
	; protection
	PL_B	$000320,$60
	PL_NOP	$002F94,2
	
	; speed regulation
	
;;	PL_PS	$005CBA+$010468,sync_dot_fade_2
	PL_P	$004654,set_copper

    ; keyboard support
	PL_PS	$000C78,read_joydat
	PL_PS	$00D976,read_joydat 

    PL_PS   $000C60,read_fire1
    PL_PSS  $00D962,read_fire2,2

    PL_IFC1X    0
    PL_NOP  $004AD8,4
    PL_ENDIF
	PL_END

read_fire1:
    MOVE.B  $00BFE001,D0
    move.l  a0,-(a7)
    lea keyboard_table(pc),a0
    tst.b   ($40,a0)    ; space key
    beq.b   .no_space
    bclr    #7,d0
.no_space    
    move.l  (a7)+,a0
    rts

read_fire2:
     move.w d0,-(a7)
     bsr    read_fire1
     btst   #7,d0
     movem.w    (a7)+,d0
     rts
   
read_joydat
    move.w  _custom+joy1dat,d0
    move.l  a0,-(a7)
    lea keyboard_table(pc),a0
    tst.b   ($4C,a0)    ; up key
    beq.b   .no_up
	; set UP
	bset	#8,d0
	bclr	#9,d0
    bra.b   .no_down
.no_up    
    tst.b   ($4D,a0)    ; down key
    beq.b   .no_down
	; set DOWN
	bset	#0,d0
	bclr	#1,d0
.no_down    
    tst.b   ($4F,a0)    ; left key
    beq.b   .no_left
	; set LEFT
	bset	#9,d0
    tst.b   ($4C,a0)    ; up key
    bne.b   .diag_left_up
    bset    #8,d0
    bra.b   .no_right
.diag_left_up
	bclr	#8,d0
    bra.b   .no_right    
.no_left
    tst.b   ($4E,a0)    ; right key
    beq.b   .no_right
	; set RIGHT
	bset	#1,d0
    tst.b   ($4D,a0)    ; down key
    bne.b   .diag_right_down
    bset    #0,d0
    bra.b   .no_right    
.diag_right_down
	bclr	#0,d0
    
.no_right   

    
    move.l  (a7)+,a0
    rts
    

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
	

    
kbint_hook:
    movem.l  a5/d0-d3,-(a7)
	LEA	$00BFD000,A5
    ; we can't test this as this clears ICR and fucks up ROM code
;	MOVEQ	#$08,D0
;	AND.B	$1D01(A5),D0
;	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
    ror.b   #1,d0
    not.b   d0
    and.w   #$FF,d0
    bclr    #7,d0
    seq d1      ; D1 = $FF if key up
    lea keyboard_table(pc),a5
    move.b  d1,(a5,d0.w)
.nokey    
    movem.l  (a7)+,a5/d0-d3
    
    move.l  old_kbint(pc),-(a7)
    rts
    
keyboard_table:
    ds.b    $100,0
        
old_kbint:
    dc.l    0
    

