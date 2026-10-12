;*---------------------------------------------------------------------------
;  :Program.	GrandPrixCircuitHD.asm
;  :Contents.	Slave for "GrandPrixCircuit"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: GrandPrixCircuitHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;DEBUG
	IFD BARFLY
	OUTPUT	"GrandPrixCircuit.slave"
	IFND	DEBUG
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


	IFD	DEBUG
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
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE
CBDOSLOADSEG

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.1-beta"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

assign
	dc.b	"GrandPrixCircuit",0

; Optional simulation/blitter changes; the v1 display handoff fix is always applied.
slv_config
	dc.b "C2:B:Enhanced framerate;"
	IFD VERIFY
	dc.b "C1:B:Traffic in attract verification;C3:B:Reproducible RNG;C4:X:Slow drawing verification:0;C4:X:Original swap verification:1;C4:X:Force period six verification:2;C5:X:Scripted joystick verification:0;C5:X:Human driver verification:1;C5:X:Immediate start verification:2;"
	ENDC
	dc.b	0

slv_name		dc.b	"Grand Prix Circuit"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1989 Accolade",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"GrandPrixCircuit",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	d1,d1
	add.l	d1,d1

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	bsr	.strip_colon

	; song-123 files

	cmp.b	#'s',(a0)
	bne.b	.nosong
	cmp.b	#'o',1(a0)
	bne.b	.nosong
	cmp.b	#'n',2(a0)
	bne.b	.nosong
	
	; patch song1

	move.l	d1,a1
	addq.l	#4,a1

	lea	h0_end_address(pc),a0
	move.l	$1A6(a1),(a0)
	lea	lab62_address(pc),a0
	move.l	$5CA(a1),(a0)

	lea	pl_song1(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
.nosong
	rts

.strip_colon
	addq.l	#1,a0
	movem.l	a0,-(a7)
.loop
	move.b	(a0)+,d0
	beq.b	.fail
	cmp.b	#':',d0
	bne.b	.loop
	addq.l	#4,a7
	rts	
.fail
	movem.l	(a7)+,a0
	rts

; < a0: str1
; < a1: str2
; > d0: -1: fail, 0: ok

strcmp:
	movem.l	d1/a0-a2,-(A7)
.contstrcmpasm
	move.b	(A0)+,d0
	beq.s	.termstrcmpasm
	move.b	(A1)+,d1
	beq.s	.failstrcmpasm
	bsr.s	.letterstrcmpasm
	exg	d0,d1
	bsr.s	.letterstrcmpasm
	cmp.b	d0,d1
	bne.s	.failstrcmpasm
	bra.s	.contstrcmpasm

.termstrcmpasm
	tst.b	(A1)+
	bne.s	.failstrcmpasm
	moveq.l	#0,d0
	bra.s	.endstrcmpasm

.letterstrcmpasm
	cmp.b	#$60,d0
	bls.s	.letter1strcmpasm
	cmp.b	#$7a,d0
	bhi.s	.letter1strcmpasm
	sub.b	#$20,d0
.letter1strcmpasm
	rts

.failstrcmpasm
	moveq.l	#-1,d0
.endstrcmpasm
	movem.l	(A7)+,d1/a0-a2
	rts


_bootdos
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
		bsr	patch_trackdisk

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)


patch_main
	movem.l d0-a6,-(a7)
	move.l _resload(pc),a2
	lea program(pc),a0
	jsr resload_GetFileSize(a2)
	cmp.l #94708,d0
	bne.b .legacy

	lea sim_code(pc),a0
	move.l d7,d0
	addq.l #4,d0
	move.l d0,(a0)
	bsr sim_configure
	lea render_race_return(pc),a0
	move.l d7,d0
	add.l #4+$a8f2,d0
	move.l d0,(a0)
	lea render_options(pc),a0
	move.l custom2(pc),d0
	beq.b .render_ready
	move.l #2,(a0)
.render_ready
	; v1: PatchSeg takes the LoadSeg BPTR, not the code address.
	lea pl_main_v1(pc),a0
	move.l attnflags(pc),d0
	btst #AFB_68010,d0
	beq.b .v1
	lea pl_main_v1_sr(pc),a0
.v1
	move.l d7,d0
	lsr.l #2,d0
	move.l d0,a1
	IFD VERIFY
	lea verify_v1(pc),a3
	move.l #1,(a3)
	ENDC
	jsr resload_PatchSeg(a2)
	bsr sim_patch
	IFD VERIFY
	bsr verify_cache_state
	ENDC
	bra.b .done

.legacy
	; Preserve JOTD's patch path for sizes not identified as v1.
	moveq #0,d2
	bsr get_section
	lea pl_section0(pc),a0
	move.l attnflags(pc),d0
	btst #AFB_68010,d0
	beq.b .patch
	lea pl_sr(pc),a0
.patch
	jsr resload_Patch(a2)
.done
	IFD VERIFY
	lea verify_hunk0(pc),a0
	move.l d7,d0
	addq.l #4,d0
	move.l d0,(a0)
	ENDC
	movem.l (a7)+,d0-a6
	rts

; v1 display handoff fix plus inherited JOTD patches. VERIFY can bypass the fix.
pl_main_v1
	PL_START
	IFD VERIFY
	PL_IFC1
	PL_PSS $e06,verify_traffic,4
	PL_ENDIF
	PL_IFC3
	PL_W $c12c,$7200
	PL_NOP $c12e,4
	PL_ENDIF
	PL_IFC4X 3
	PL_PSS $72a2,verify_render_pose,2 ; PERF_RANGE h0:72A2 8 bit=VERIFY_RENDER
	PL_ENDIF
	PL_IFC4X 0
	PL_PSS $729a,verify_slow_draw,2
	PL_ENDIF
	PL_PS $707a,verify_race_start
	PL_IFC5
	PL_PS $c1de,verify_read_joydat
	PL_PSS $7734,verify_event_field,2 ; PERF_RANGE h0:7734 8 bit=VERIFY_C5
	PL_PSS $61f4,verify_pit_key,2 ; PERF_RANGE h0:61F4 8 bit=VERIFY_C5
	PL_ENDIF
	ENDC
	IFD VERIFY
	PL_IFC4X 1
	PL_ELSE
	ENDC
	PL_P $39e,render_swap
	PL_PS $818c,render_before_road
	PL_PS $7094,render_before_pause
	PL_PS $75c8,render_before_exit
	IFD VERIFY
	PL_ENDIF
	ENDC
	PL_IFC2
	PL_PSS $9ee,render_reset_tables,2 ; PERF_RANGE h0:09EE 8 bit=C2
	PL_P $a6ea,sim_latch_enter ; PERF_RANGE h0:A6EA 8 bit=C2
	PL_P $a776,sim_latch_leave ; PERF_RANGE h0:A776 6 bit=C2
	PL_PSS $9a82,render_main_pose,10 ; PERF_RANGE h0:9A82 16 bit=C2
	PL_PSS $91a2,render_mirror_pose,10 ; PERF_RANGE h0:91A2 16 bit=C2
	PL_PSS $8212,render_horizon_pose,2 ; PERF_RANGE h0:8212 8 bit=C2
	PL_PSS $8252,render_scenery_pose,2 ; PERF_RANGE h0:8252 8 bit=C2
	PL_PSS $8d8e,render_car_y,2 ; PERF_RANGE h0:8D8E 8 bit=C2
	PL_PS $8f70,render_car_depth ; PERF_RANGE h0:8F70 6 bit=C2
	PL_PSS $8d9e,render_car_near_y,2 ; PERF_RANGE h0:8D9E 8 bit=C2
	PL_PSS $94f2,render_mirror_car_y,2 ; PERF_RANGE h0:94F2 8 bit=C2
	PL_PS $9aaa,render_angle ; PERF_RANGE h0:9AAA 6 bit=C2
	PL_PS $91c2,render_angle ; PERF_RANGE h0:91C2 6 bit=C2
	PL_PS $91c8,render_mirror_step ; PERF_RANGE h0:91C8 6 bit=C2
	PL_ENDIF
	PL_NEXT pl_section0
pl_main_v1_sr
	PL_START
; Route every v1 CPU through the display fix and optional fixtures.
	PL_W $0ac2c,$42e7
	PL_W $0ac96,$42e7
	PL_W $0ace6,$42e7
	PL_W $0ad36,$42e7
	PL_W $0ad82,$42e7
	PL_W $0af12,$42e7
	PL_W $0af5e,$42e7
	PL_NEXT pl_main_v1

	IFD VERIFY
	include "verification.s"
	include "render-verify.s"
	ENDC

	include "render.s"
	include "render-subunit.s"
	include "simulation.s"

pl_song1
	PL_START

	; write to intreq not intreqr
	PL_L	$4FE,$DFF09C
	PL_L	$A44,$DFF09C
	PL_L	$A74,$DFF09C

	; wait after write to dmacon (music) to avoid sound problems

	PL_PS	$1E8,move_d2_dmacon
	PL_PS	$8FA,move_d2_dmacon
	PL_PS	$110,move_d7_dmacon
	PL_PS	$1A4,move_h0_end_dmacon
	PL_PS	$7E0,move_h0_end_dmacon
	PL_PS	$5C8,move_lab62_dmacon

	PL_PS	$8A,move_f_dmacon
	PL_PS	$23A,move_f_dmacon
	PL_PS	$42E,move_f_dmacon
	PL_PS	$502,move_f_dmacon
	PL_PS	$A78,move_f_dmacon
	PL_END

move_f_dmacon
	move.w	#$F,_custom+dmacon
	addq.l	#2,(a7)
	bra	dmacon_wait
	
move_h0_end_dmacon
	movem.l	a0,-(a7)
	move.l	h0_end_address(pc),a0
	move.w	(a0),_custom+dmacon
	movem.l	(a7)+,a0
	addq.l	#4,(a7)
	bra	dmacon_wait

move_lab62_dmacon
	movem.l	a0,-(a7)
	move.l	lab62_address(pc),a0
	move.w	(a0),_custom+dmacon
	movem.l	(a7)+,a0
	addq.l	#4,(a7)
	bra	dmacon_wait

move_d2_dmacon
	move.w	d2,_custom+dmacon
	bra	dmacon_wait
move_d7_dmacon
	move.w	d7,_custom+dmacon
	bra	dmacon_wait

dmacon_wait
	movem.l	d0,-(a7)
	move.l	#8,d0
	bsr	beamdelay
	movem.l	(a7)+,d0
	rts

pl_sr
	PL_START
	PL_W	$0AC2C,$42E7
	PL_W	$0AC96,$42E7
	PL_W	$0ACE6,$42E7
	PL_W	$0AD36,$42E7
	PL_W	$0AD82,$42E7
	PL_W	$0AF12,$42E7
	PL_W	$0AF5E,$42E7
	PL_NEXT	pl_section0

pl_section0
	PL_START

	; active CPU loop

	PL_PS	$174,active_delay

	; disk protection

	PL_S	$4978,$84-$78
	PL_S	$2B90,$A4-$90
	PL_R	$B444
	PL_L	$B2F4,$70004E75

	; null pointer passed to CloseWindow (we skip CloseWindow call)

	PL_R	$E516

	PL_END

active_delay
	moveq	#0,d0
	move.w	(-6,a5),d0
	lsr.l	#3,D0
	bsr	beamdelay
	addq.l	#$182-$17A,(a7)
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


; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
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
	bsr render_interrupt_option
	jsr	(4,a3)		; call program
	bsr render_interrupt_restore
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

patch_trackdisk
	movem.l	D0-A6,-(A7)
	lea	_trackdisk_device(pc),A0
	tst.l	(A0)
	bne.b	.out		; already patched
	lea	_trdname(pc),A0

	move.l	$4.W,A6

	lea	-$30(A7),A7
	move.l	A7,A1
	moveq	#0,D0
	moveq	#0,D1
	jsr	_LVOOpenDevice(A6)
	
	lea	_trackdisk_device(pc),A1
	move.l	IO_DEVICE(A7),(A1)		; save trackdisk device pointer

	lea	$30(A7),A7

	move.l	$4.W,A0
	add.w	#_LVODoIO+2,a0
	lea	_doio_save(pc),a1
	move.l	(a0),(a1)
	lea	_doio(pc),a1
	move.l	a1,(a0)
	move.l	$4.W,A0
	add.w	#_LVOSendIO+2,a0
	lea	_sendio_save(pc),a1
	move.l	(a0),(a1)
	lea	_sendio(pc),a1
	move.l	a1,(a0)

.out

	bsr	_flushcache

	movem.l	(A7)+,D0-A6

	rts


_doio:
	tst.l	IO_DEVICE(A1)
	beq.b	.skipit
	move.l	_trackdisk_device(pc),D0
	cmp.l	IO_DEVICE(A1),D0
	bne.b	.org
	bra.b	.skipit		; skip accesses to trackdisk device
.org
	move.l	_doio_save(pc),-(A7)
	rts
.skipit:
	clr.b	$1F(A1)
	moveq.l	#0,D0
	rts

_sendio:
	tst.l	IO_DEVICE(A1)
	beq.b	.skipit
	move.l	_trackdisk_device(pc),D0
	cmp.l	IO_DEVICE(A1),D0
	bne.b	.org

	bra.b	.skipit		; skip accesses to trackdisk device

	move.w	$1C(A1),D0
	cmp.w	#$800A,D0	; seek
	beq.b	.skipit
;	cmp.w	#$00A,D0	; seek
;	beq.b	.skipit
.org
	move.l	_sendio_save(pc),-(A7)
	rts
.skipit:
	clr.b	$1F(A1)
	moveq.l	#0,D0
	rts

_trackdisk_device:
	dc.l	0
_doio_save:
	dc.l	0
_sendio_save:
	dc.l	0

_trdname:
	dc.b	"trackdisk.device",0
	even
	
; sound routine
h0_end_address
	dc.l	0
lab62_address
	dc.l	0

_saveregs
		dcb.l	16,0
_stacksize
		dc.l	0

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
custom2	dc.l	0
	IFD VERIFY
		dc.l WHDLTAG_CUSTOM4_GET
sim_verify_options dc.l 0
		dc.l WHDLTAG_CUSTOM5_GET
verify_drive_options dc.l 0
	ENDC
		dc.l	WHDLTAG_ATTNFLAGS_GET
attnflags
	dc.l	0
	dc.l	0
;============================================================================

    IFD VERIFY
; The optional recording is ignored local input, never distributed or committed.
verify_pilot_tape:
    IFD VERIFY_TAPE
    INCBIN "phase6-tape.bin"
    ELSE
    dcb.w 12288,0
    ENDC
    ENDC
	END
