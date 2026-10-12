; Development-only live-loop dispatcher. All time in a frame is consumed in
; bounded <=8-field steps. Time spent doing this work belongs to the next frame.
; VERIFY_DISPATCH_CPU experimentally selects one full interval on pre-020 CPUs.
; Large-step handling and other timelines remain unproven: diagnostic use only.
; Replay and other presentation timelines remain separate work.
_dispatch_install:
	movem.l d0-d1/a0-a2,-(a7)
	IFD VERIFY_DISPATCH_CPU
	lea _dispatch_cpu_tags(pc),a0
	movea.l _resload(pc),a2
	jsr resload_Control(a2)
	lea _dispatch_cpu_single(pc),a0
	clr.w (a0)
	move.l _dispatch_cpu_attn(pc),d0
	btst #AFB_68020,d0
	bne.s .cpu_ready
	move.w #1,(a0)
.cpu_ready:
	ENDC
	lea _dispatch_recovery_ptr(pc),a0
	move.l _code_start(pc),d0
	addi.l #$108a2,d0
	move.l d0,(a0)+
	move.l _code_start(pc),d0
	addi.l #$e706,d0
	move.l d0,(a0)
	lea _dispatch_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	lea _dispatch_state(pc),a0
	st DS_ENABLED(a0)
	bsr _events_install
	IFD VERIFY_TIME_SWEEP
	bsr _sweep_install
	ENDC
	IFD VERIFY_TIME_SCENE_CULL
	bsr _scene_cull_install
	ENDC
	movem.l (a7)+,d0-d1/a0-a2
	rts
_dispatch_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_DISPATCH $10f0c $0008: controls once and recovery
	PL_PSS $10f0c,_dispatch_controls,2
	; PERF_RANGE VERIFY_TIME_DISPATCH $10f28 $0008: substep or draw
	PL_PSS $10f28,_dispatch_after_physics,2
	; PERF_RANGE VERIFY_TIME_DISPATCH $07d0a $0008: latch after keyboard processing
	PL_PSS $7d0a,_dispatch_latch,2
	; PERF_RANGE VERIFY_TIME_DISPATCH $0b3a0 $0008: held steering sample
	PL_PSS $b3a0,_dispatch_steering,2
	; Recovery scans both road lists to restore the nearest road. Inline the
	; word absolute values; retain native wraparound, tie order and outputs.
	; PERF_RANGE VERIFY_TIME_DISPATCH $04eb2 $010c: exact nearest-road scan
	PL_DATA $4eb2,_dispatch_road_end-_dispatch_road_patch
_dispatch_road_patch:
 link a5,#0
 movem.l d4-d6/a2,-(a7)
 movea.l -$6720(a4),a2
 move.l a2,-$671c(a4)
 move.w #$7fff,d6
 move.w -$6718(a4),d4
 beq.s .second
 subq.w #1,d4
.first:
 move.w 2(a2),d0
 cmp.w -$670e(a4),d0
 bls.s .distance1
 move.w 8(a2),d0
 cmp.w -$670e(a4),d0
 bhi.s .next1
.distance1:
 move.w (a2),d0
 sub.w -$6710(a4),d0
 bpl.s .x1
 neg.w d0
.x1:
 move.w d0,d5
 move.w 2(a2),d0
 sub.w -$670e(a4),d0
 bpl.s .y1
 neg.w d0
.y1:
 move.w d5,d1
 add.w d0,d1
 move.w 4(a2),d0
 sub.w -$670c(a4),d0
 bpl.s .z1
 neg.w d0
.z1:
 move.w d1,d5
 add.w d0,d5
 cmp.w d6,d5
 bcc.s .next1
 clr.b -$66b0(a4)
 move.w d5,d6
 move.l a2,-$671c(a4)
.next1:
 lea 20(a2),a2
 dbra d4,.first
.second:
 movea.l -$66ae(a4),a2
 move.w -$66aa(a4),d4
 beq.s .done
 subq.w #1,d4
.nextroad:
 move.w 2(a2),d0
 cmp.w -$670e(a4),d0
 bls.s .distance2
 move.w 8(a2),d0
 cmp.w -$670e(a4),d0
 bhi.s .next2
.distance2:
 move.w (a2),d0
 sub.w -$6710(a4),d0
 bpl.s .x2
 neg.w d0
.x2:
 move.w d0,d5
 move.w 2(a2),d0
 sub.w -$670e(a4),d0
 bpl.s .y2
 neg.w d0
.y2:
 move.w d5,d1
 add.w d0,d1
 move.w 4(a2),d0
 sub.w -$670c(a4),d0
 bpl.s .z2
 neg.w d0
.z2:
 move.w d1,d5
 add.w d0,d5
 cmp.w d6,d5
 bcc.s .next2
 move.b #1,-$66b0(a4)
 move.w d5,d6
 move.l a2,-$671c(a4)
.next2:
 lea 20(a2),a2
 dbra d4,.nextroad
.done:
 ; Original final SUBQ #1,count reaches zero and clears X. The following
 ; pointer publication supplies N/Z/V/C, independently of loop arithmetic.
 moveq #0,d4
 add.w d4,d4
 move.l -$671c(a4),-$66a8(a4)
 movem.l (a7)+,d4-d6/a2
 unlk a5
 rts
	dcb.w ($10c-(*-_dispatch_road_patch))/2,$4e71
_dispatch_road_end:
	PL_END
DS_PENDING equ 0
DS_CONSUMED equ 4
DS_STEPS equ 8
DS_FRAME_STEPS equ 12
DS_FRAME_FIELDS equ 16
DS_DISCARDED equ 20
DS_ACTIVE equ 24
DS_FIRST equ 25
DS_BUTTONS equ 26
DS_MOUSE equ 28
DS_ENABLED equ 30
DS_OVERLAY_FIELDS equ 32
_dispatch_recovery_ptr: dc.l 0
_dispatch_scene_ptr: dc.l 0
_dispatch_signature: dc.b 'HDDISP01'
_dispatch_state: dcb.b 36,0

	IFD VERIFY_DISPATCH_CPU
; Payload: query tag,reported AttnFlags,terminator,single.w,pad.w,oversized.l.
_dispatch_cpu_signature: dc.b 'HDCPUP01'
_dispatch_cpu_tags: dc.l WHDLTAG_ATTNFLAGS_GET
_dispatch_cpu_attn: dc.l 0
	dc.l 0
_dispatch_cpu_single: dc.w 0,0
_dispatch_cpu_oversized: dc.l 0
	ENDC

; Called with D0 elapsed fields, preserving all registers and X at outer wrapper.
_dispatch_begin:
	movem.l d0-d2/a0-a1,-(a7)
	bsr _dispatch_begin_frame
	movem.l (a7)+,d0-d2/a0-a1
	rts
; Outer epoch already owns D0-D2/A0-A1. Return its time-state base in A0.
_dispatch_begin_frame:
	IFD VERIFY_DISPATCH_TEST_FIELDS
	; Diagnostic interval override exercises the actual elapsed-time paths.
	; Unlike VERIFY_DISPATCH_NATIVE, it does not select compatibility bypasses.
	; This synthetic time is not a wall-time or performance measurement.
	move.l #VERIFY_DISPATCH_TEST_FIELDS,d0
	ENDC
	lea _dispatch_state(pc),a0
	move.l d0,DS_FRAME_FIELDS(a0)
	move.l d0,DS_PENDING(a0)
	move.l d0,DS_OVERLAY_FIELDS(a0)
	clr.l DS_FRAME_STEPS(a0)
	st DS_ACTIVE(a0)
	st DS_FIRST(a0)
	IFD VERIFY_DISPATCH_NATIVE
	; Compatibility instrument: exactly one native step per frame.
	move.l #8,DS_PENDING(a0)
	move.l #8,DS_FRAME_FIELDS(a0)
	move.l #8,DS_OVERLAY_FIELDS(a0)
	ENDC
	bsr _dispatch_take
	lea _time_state(pc),a0
	rts
; A0 dispatcher state. Empty intervals publish T=0; they never invent time.
_dispatch_take:
	lea _events_score_state(pc),a1
	clr.b 2(a1)
	clr.b 6(a1)
	move.l DS_PENDING(a0),d0
	IFD VERIFY_DISPATCH_CPU
	IFND VERIFY_DISPATCH_NATIVE
	lea _dispatch_cpu_single(pc),a1
	tst.w (a1)
	beq.s .bounded
	; Existing scalar interfaces carry unsigned-word intervals. Retain all
	; time and count any oversized fallback instead of truncating silently.
	cmpi.l #65535,d0
	bhi.s .oversized
	move.l d0,d2
	moveq #0,d0
	move.l d2,d1
	swap d1
	lsr.l #3,d1
	bra.s .publish
.oversized:
	lea _dispatch_cpu_oversized(pc),a1
	addq.l #1,(a1)
.bounded:
	ENDC
	ENDC
	bsr _time_take_fields
.publish:
	move.l d0,DS_PENDING(a0)
	add.l d2,DS_CONSUMED(a0)
	addq.l #1,DS_STEPS(a0)
	addq.l #1,DS_FRAME_STEPS(a0)
	lea _time_scalar_fields(pc),a1
	move.w d2,(a1)
	lea _time_state(pc),a1
	move.l d1,TS_T(a1)
	rts

; Native 7D12..7DEA defines A0 before using it; it is caller scratch.
_dispatch_latch:
	lea _dispatch_state(pc),a0
	tst.b DS_ACTIVE(a0)
	beq.s .test
	move.w -$6a0a(a4),DS_BUTTONS(a0)
	move.w -$6a06(a4),DS_MOUSE(a0)
.test:
	tst.w -$6a0a(a4)
	bne.s .done
	movea.l _code_start(pc),a0
	adda.l #$7dea,a0
	move.l a0,(a7)
.done:
	tst.w -$6a0a(a4)
	rts
_dispatch_steering:
	move.w -$6a06(a4),d0
	move.l a0,-(a7)
	lea _dispatch_state(pc),a0
	tst.b DS_ACTIVE(a0)
	beq.s .native
	move.w DS_MOUSE(a0),d0
.native:
	movea.l (a7)+,a0
	sub.w #320,d0
	rts
; Controls/recovery are native C calls: A0 is scratch at these boundaries.
_dispatch_controls:
	lea _dispatch_state(pc),a0
	tst.b DS_FIRST(a0)
	beq.s .held
	clr.b DS_FIRST(a0)
	jsr -$7e7e(a4)
	bra.s .recover
.held:
	bsr _dispatch_held_ramps
.recover:
	IFD VERIFY_TIME_SWEEP
	pea .sweep_ready(pc)
	ENDC
	; Native 108A2 has no work unless recovery is requested. Keep the
	; presentation companion reset, without its native save/restore frame.
	tst.b -$69fb(a4)
	bne.s .recover_native
	IFD VERIFY_TIME_PRESENTATION
	lea _presentation_recovery(pc),a0
	clr.l (a0)
	ENDC
	rts
.recover_native:
	move.l _dispatch_recovery_ptr(pc),-(a7)
	rts
	IFD VERIFY_TIME_SWEEP
.sweep_ready:
	bsr _sweep_begin
	rts
	ENDC
; Keyboard, gear selection, start sounds and other edge events run only above.
; Continuous throttle ramps repeat against the held button sample and live gates.
_dispatch_held_ramps:
	movem.l d0-d2/a0,-(a7)
	tst.b -$6864(a4)
	bne.s .timeout
	tst.b -$69fa(a4)
	bne.s .done
	lea _dispatch_state(pc),a0
	cmpi.w #4,DS_BUTTONS(a0)
	bne.s .down
	tst.b -$5224(a4)
	beq.s .down
	bsr _time_throttle_up
	ble.s .down
	move.b #100,-$66e4(a4)
.down:
	lea _dispatch_state(pc),a0
	btst #0,DS_BUTTONS+1(a0)
	beq.s .done
	bsr _time_throttle_down
	bpl.s .done
	clr.b -$66e4(a4)
	bra.s .done
.timeout:
	bsr _time_expired_throttle
.done:
	movem.l (a7)+,d0-d2/a0
	rts
_dispatch_after_physics:
	; Most active frames have no debt left: save only A0.
	tst.b -$522c(a4)
	beq.s .slow
	move.l a0,-(a7)
	lea _dispatch_state(pc),a0
	tst.l DS_PENDING(a0)
	beq.s .finished
	movea.l (a7)+,a0
.slow:
	movem.l d0-d2/a0-a1,-(a7)
	lea _dispatch_state(pc),a0
	tst.b -$522c(a4)
	bne.s .continuing
	; Leaving the race cancels the rest of this frame explicitly, never silently.
	move.l DS_PENDING(a0),d0
	add.l d0,DS_DISCARDED(a0)
	clr.l DS_PENDING(a0)
.continuing:
	tst.l DS_PENDING(a0)
	beq.s .draw
	bsr _dispatch_take
	movea.l _code_start(pc),a1
	adda.l #$10edc,a1
	move.l a1,20(a7)
	movem.l (a7)+,d0-d2/a0-a1
	rts
.draw:
	clr.b DS_ACTIVE(a0)
	; Overlays draw once and therefore consume the whole outer interval.
	movem.l (a7)+,d0-d2/a0-a1
	bra.s .render
.finished:
	clr.b DS_ACTIVE(a0)
	movea.l (a7)+,a0
.render:
	jsr -$7fec(a4)
	move.l _dispatch_scene_ptr(pc),-(a7)
	rts

	INCLUDE "HardDrivinEvents.s"

	IFD VERIFY_TIME_SCENE_CULL
	INCLUDE "HardDrivinScene.s"
	ENDC

	IFD VERIFY_TIME_SWEEP
	INCLUDE "HardDrivinSweep.s"
	ENDC
