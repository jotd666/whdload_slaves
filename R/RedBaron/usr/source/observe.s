; VERIFY observers and optional CUSTOM5 bit 0 slowed-drawing coupling test.
; RBSTEPS1 header: version, stride, capacity, committed count, buffer, h3, sim.
; Each 44-byte record: step.l, CIA ticks.l, beam.l, display pointer.l,
; elapsed.w, dt.w, secondary dt.w, F.w, Time Scale.w, view counter.w,
; dirty counter.w, top-text counter.w, world-frame counter.l, message timer.w,
; reserved.w, VBlank count.l. Count is published only after the record is complete.
OBS_STRIDE = 44
OBS_CAPACITY = 256
observe_start:
	lea .resload_base(pc),a0
.resload_base
	adda.l #_resload-.resload_base,a0
	move.l (a0),a0
	lea observe_resload(pc),a1
	move.l a0,(a1)
	move.l perf_attnflags(pc),a0
	lea observe_attnflags(pc),a1
	move.l a0,(a1)
	lea .buffer_base(pc),a0
.buffer_base
	adda.l #observe_buffer-.buffer_base,a0
	lea observe_header(pc),a1
	move.l a0,24(a1)
	rts
observe_step:
	movem.l d0-d2/a0-a2,-(sp)
	lea observe_header(pc),a2
	move.l tape_marker+24(pc),a0
	move.l a0,32(a2)
	move.l a0,a1
	moveq #2,d0
.hunk:
	move.l -4(a1),d1
	lsl.l #2,d1
	addq.l #4,d1
	move.l d1,a1
	dbf d0,.hunk
	move.l a1,28(a2)
	bsr time_probe_step
	move.l 20(a2),d0
	andi.l #OBS_CAPACITY-1,d0
	mulu.w #OBS_STRIDE,d0
	move.l 24(a2),a2
	adda.l d0,a2
	move.l tape_game_steps(pc),(a2)+
	adda.l #$30006,a0
	move.l (a0),(a2)+
	move.l $dff004,(a2)+
	move.l a1,a0
	adda.l #$9d66,a0
	move.l (a0),(a2)+
	move.w $483a(a1),(a2)+
	move.w $4834(a1),(a2)+
	move.w $4836(a1),(a2)+
	move.w $4838(a1),(a2)+
	move.w $3d56(a1),(a2)+
	move.w $6716(a1),(a2)+
	moveq #0,d0
	move.b $711c(a1),d0
	move.w d0,(a2)+
	move.w $45b8(a1),(a2)+
	move.l $3254(a1),(a2)+
	move.w $4820(a1),(a2)+
	clr.w (a2)+
	move.l observe_vbl_count(pc),(a2)+
	lea observe_header(pc),a0
	addq.l #1,20(a0)
	bsr time_input_observe_install
	bsr observe_install_slow
	bsr paint_install
	movem.l (sp)+,d0-d2/a0-a2
	rts
; VERIFY_RANGE sim:2d348 6: replace one LEA in the supervisor VBlank callback.
; Save/restore SR because the displaced LEA preserves flags. This is IRQ context.
observe_vbl:
	move.w sr,-(sp)
	lea observe_vbl_count(pc),a2
	addq.l #1,(a2)
	bsr time_pause_irq
	bsr time_input_fixture
	move.l tape_marker+24(pc),a2
	adda.l #$2d41c,a2
	move.w (sp)+,sr
	rts
	CNOP 0,4
observe_header:
	dc.b "RBSTEPS1"
	dc.l 1,OBS_STRIDE,OBS_CAPACITY,0,0,0,0
observe_vbl_count: dc.l 0
observe_resload: dc.l 0
observe_attnflags: dc.l 0

; Install only at the first true flight step. Menu timing is identical with the
; bit off/on; the test adds delay to drawing, inside the measured frame interval.
observe_install_slow:
	movem.l d0-a6,-(sp)
	move.l tape_game_steps(pc),d0
	cmpi.l #1,d0
	bne.b .done
	move.l perf_custom5(pc),d0
	btst #0,d0
	beq.b .done
	move.l tape_marker+24(pc),a1
	lea $15b2(a1),a0
	cmpi.w #$4ef9,(a0)
	bne.b .bad
	move.l a1,d0
	add.l #$2c552,d0
	cmp.l 2(a0),d0
	bne.b .bad
	lea observe_draw_target(pc),a0
	move.l d0,(a0)
	lea observe_slow_patch(pc),a0
	move.l observe_resload(pc),a2
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
.done
	movem.l (sp)+,d0-a6
	rts
.bad
	pea perf_mismatch(pc)
	pea TDREASON_FAILMSG
	move.l observe_resload(pc),a2
	jmp resload_Abort(a2)

observe_slow_patch:
	PL_START
	; VERIFY_RANGE sim:015b2 6 CUSTOM5 bit 0: whole JMP in the 3D caller stub.
	PL_P $15b2,observe_slow_draw
	PL_END

; Preserve all inputs, SP and X. The callee's move.w at sim:2c562 overwrites
; NZVC before using flags. No user-mode SR access (privileged on 68020).
; Three stable beam wraps add two whole fields plus the initial partial field.
observe_slow_draw:
	movem.l d0-d3,-(sp)
	moveq #2,d2
	bsr.b .beam
	move.l d0,d3
.loop
	bsr.b .beam
	cmp.l d3,d0
	bhs.b .next
	dbf d2,.next
	movem.l (sp)+,d0-d3
	move.l observe_draw_target(pc),-(sp)
	rts
.next
	move.l d0,d3
	bra.b .loop
.beam
	move.l $dff004,d0
	move.l $dff004,d1
	andi.l #$1ff00,d0
	andi.l #$1ff00,d1
	cmp.l d0,d1
	bne.b .beam
	rts
observe_draw_target: dc.l 0

	INCLUDE "time-input-observe.s"
	INCLUDE "time-probe.s"
	INCLUDE "paint-observe.s"

; Long-range VERIFY bridge as instrumentation grows beyond a 16-bit BSR span.
observe_check_bytes:
	move.l a3,-(sp)
	lea .base(pc),a3
.base
	adda.l #perf_check_bytes-.base,a3
	jsr (a3)
	move.l (sp)+,a3
	rts
