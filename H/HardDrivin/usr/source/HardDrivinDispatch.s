; Development-only live-loop dispatcher. All time in a frame is consumed in
; bounded <=8-field steps. Time spent doing this work belongs to the next frame.
; Replay and other presentation timelines remain separate work.
_dispatch_install:
	movem.l d0/a0-a2,-(a7)
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
	movem.l (a7)+,d0/a0-a2
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

; Called with D0 elapsed fields, preserving all registers and X at outer wrapper.
_dispatch_begin:
	movem.l d0-d2/a0-a1,-(a7)
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
	movem.l (a7)+,d0-d2/a0-a1
	rts
; A0 dispatcher state. Empty intervals publish T=0; they never invent time.
_dispatch_take:
	bsr _events_begin_step
	move.l DS_PENDING(a0),d0
	bsr _time_take_fields
	move.l d0,DS_PENDING(a0)
	add.l d2,DS_CONSUMED(a0)
	addq.l #1,DS_STEPS(a0)
	addq.l #1,DS_FRAME_STEPS(a0)
	lea _time_scalar_fields(pc),a1
	move.w d2,(a1)
	lea _time_state(pc),a1
	move.l d1,TS_T(a1)
	rts

_dispatch_latch:
	movem.l d0/a0,-(a7)
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
	move.l a0,8(a7)
.done:
	movem.l (a7)+,d0/a0
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
_dispatch_controls:
	move.l a0,-(a7)
	lea _dispatch_state(pc),a0
	tst.b DS_FIRST(a0)
	beq.s .held
	clr.b DS_FIRST(a0)
	movea.l (a7)+,a0
	jsr -$7e7e(a4)
	bra.s .recover
.held:
	movea.l (a7)+,a0
	bsr _dispatch_held_ramps
.recover:
	move.l _dispatch_recovery_ptr(pc),-(a7)
	rts
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
	jsr -$7fec(a4)
	move.l _dispatch_scene_ptr(pc),-(a7)
	rts

	INCLUDE "HardDrivinEvents.s"
