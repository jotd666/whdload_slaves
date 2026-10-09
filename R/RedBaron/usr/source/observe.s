; VERIFY-only read-only observers. No timing or rendering patch is installed here.
; RBSTEPS1 header: version, stride, capacity, committed count, buffer, h3, sim.
; Each 44-byte record: step.l, CIA ticks.l, beam.l, display pointer.l,
; elapsed.w, dt.w, secondary dt.w, F.w, Time Scale.w, view counter.w,
; dirty counter.w, top-text counter.w, world-frame counter.l, message timer.w,
; reserved.w, VBlank count.l. Count is published only after the record is complete.
OBS_STRIDE = 44
OBS_CAPACITY = 256
observe_start:
	lea observe_buffer(pc),a0
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
	movem.l (sp)+,d0-d2/a0-a2
	rts
; VERIFY_RANGE sim:2d348 6: replace one LEA in the supervisor VBlank callback.
; Save/restore SR because the displaced LEA preserves flags. This is IRQ context.
observe_vbl:
	move.w sr,-(sp)
	lea observe_vbl_count(pc),a2
	addq.l #1,(a2)
	move.l tape_marker+24(pc),a2
	adda.l #$2d41c,a2
	move.w (sp)+,sr
	rts
	CNOP 0,4
observe_header:
	dc.b "RBSTEPS1"
	dc.l 1,OBS_STRIDE,OBS_CAPACITY,0,0,0,0
observe_vbl_count: dc.l 0
observe_buffer:
	dcb.b OBS_STRIDE*OBS_CAPACITY,0
