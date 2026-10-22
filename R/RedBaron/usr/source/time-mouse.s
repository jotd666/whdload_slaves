; fixed-step timing relative mouse acquisition and simulation-owned accumulation, bit 13.
TIME_MOUSE_CODE = $201

time_mouse_install:
	movem.l d0-a6,-(sp)
	move.l #$2d35c,d0
	moveq #14,d1
	lea .delta_bytes(pc),a0
	bsr perf_check_bytes
	move.l a1,a3
	adda.l #$1ecd0,a3
	cmpi.w #$3179,(a3)
	bne .bad
	cmpi.w #4,6(a3)
	bne .bad
	cmpi.w #$3179,8(a3)
	bne .bad
	cmpi.w #6,14(a3)
	bne .bad
	move.l a1,d0
	addi.l #$2d6be,d0
	cmp.l 2(a3),d0
	bne .bad
	addq.l #4,d0
	cmp.l 10(a3),d0
	bne .bad
	lea .centers(pc),a4
	moveq #1,d7
.center
	move.l a1,a3
	adda.l (a4)+,a3
	cmpi.l #$33fc00a0,(a3)
	bne .bad
	cmpi.l #$33fc0064,8(a3)
	bne .bad
	move.l a1,d0
	addi.l #$2d6be,d0
	cmp.l 4(a3),d0
	bne .bad
	addq.l #4,d0
	cmp.l 12(a3),d0
	bne .bad
	dbf d7,.center
	move.l #$1eb5c,d0
	moveq #8,d1
	lea .camera_x_bytes(pc),a0
	bsr perf_check_bytes
	move.l #$1eb70,d0
	moveq #6,d1
	lea .camera_y_bytes(pc),a0
	bsr perf_check_bytes
	move.l #$1ebba,d0
	moveq #6,d1
	lea .camera_done_bytes(pc),a0
	bsr perf_check_bytes
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.bad
	pea time_mouse_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
.delta_bytes: dc.w $9200,$1401,$4882,$e048,$e049,$9200,$4881
.camera_x_bytes: dc.w $303c,$ff60,$d06a,$0004
.camera_y_bytes: dc.w $709c,$d06a,$0006
.camera_done_bytes: dc.w $200b,$4cdf,$0cfc
.centers: dc.l $1e8ec,$1eb8a
.patch:
	PL_START
	PL_PSS $2d35c,time_mouse_delta,8
	PL_PSS $1ecd0,time_mouse_read,10
	PL_PSS $1e8ec,time_mouse_center,10
	PL_PSS $1eb8a,time_mouse_camera_center,10
	PL_PSS $1eb5c,time_mouse_camera_x,2
	PL_PS $1eb70,time_mouse_camera_y
	PL_PS $1ebba,time_mouse_camera_done
	PL_END

; Original counter subtraction: signed 8-bit deltas, including byte wrap.
; Native physical cursor and its clamping continue unchanged after this hook.
time_mouse_delta:
	sub.b d0,d1
	move.b d1,d2
	ext.w d2
	lsr.w #8,d0
	lsr.w #8,d1
	sub.b d0,d1
	ext.w d1
	bsr time_mouse_capture
	rts

time_mouse_seed:
	movem.l d0/a0-a1,-(sp)
	move.l time_loop_sim(pc),a0
	adda.l #$2d6be,a0
	lea time_mouse_live(pc),a1
	move.w (a0),(a1)+
	move.w 4(a0),(a1)
	move.l time_mouse_live(pc),d0
	lea time_mouse_camera(pc),a1
	move.l d0,(a1)
	bsr time_mouse_resume
	movem.l (sp)+,d0/a0-a1
	rts

; Supervisor VBlank only. d2/d1 are the independently acquired X/Y deltas.
; UI motion is not a flight action; ignore deltas while ownership is modal.
; Event: eligible.l, code.w, dx.w, dy.w, max_x.w, max_y.w, reserved.w.
; Exclude the partially modal/initial VBlank sample at ownership handoff.
time_mouse_resume:
	movem.l a0,-(sp)
	lea time_mouse_skip(pc),a0
	move.w #1,(a0)
	movem.l (sp)+,a0
	rts

time_mouse_capture:
	move.w sr,-(sp)
	ori.w #$0700,sr
	movem.l d0-a6,-(sp)
	move.w time_keys_ready(pc),d0
	beq .done
	lea time_loop_state(pc),a3
	tst.l TIME_LOOP_ACTIVE(a3)
	beq .done
	lea time_mouse_skip(pc),a0
	tst.w (a0)
	beq .sample
	clr.w (a0)
	bra .done
.sample
	move.w d1,d0
	or.w d2,d0
	beq .done
	lea time_mouse_event(pc),a2
	move.l time_loop_cia(pc),a1
	move.l (a1),d0
	sub.l TIME_LOOP_PAUSED(a3),d0
	addq.l #1,d0
	move.l d0,(a2)
	move.w #TIME_MOUSE_CODE,4(a2)
	move.w d2,6(a2)
	move.w d1,8(a2)
	move.l time_loop_sim(pc),a0
	adda.l #$2d6d2,a0
	move.l (a0),10(a2)
	clr.w 14(a2)
	move.l time_input_observe_state+8(pc),a0
	move.l a2,a1
	bsr time_input_push
.done
	movem.l (sp)+,d0-a6
	move.w (sp)+,sr
	rts

; Exact native word-add, signed-negative and unsigned-limit clamp semantics.
; d0 position.w, d1 delta.w, d2 limit.w -> d0 position.w.
time_mouse_accumulate:
	add.w d1,d0
	bpl .positive
	moveq #0,d0
	rts
.positive
	cmp.w d2,d0
	bls .done
	move.w d2,d0
.done
	rts

time_mouse_apply:
	movem.l d0-d2/a0,-(sp)
	lea time_mouse_live(pc),a0
	bsr time_mouse_apply_pair
	lea time_mouse_camera(pc),a0
	bsr time_mouse_apply_pair
	movem.l (sp)+,d0-d2/a0
	rts

; Same acquisition, separate accumulation/recentering for each consumer.
time_mouse_apply_pair:
	move.w (a0),d0
	move.w 6(a1),d1
	move.w 10(a1),d2
	bsr time_mouse_accumulate
	move.w d0,(a0)
	move.w 2(a0),d0
	move.w 8(a1),d1
	move.w 12(a1),d2
	bsr time_mouse_accumulate
	move.w d0,2(a0)
	rts

; Preserve the input helper's a0 output pointer and original final MOVE flags.
time_mouse_read:
	movem.l a0-a1,-(sp)
	bsr time_devices_owned
	beq .physical
	lea time_mouse_live(pc),a1
	move.l (sp),a0
	move.w (a1),4(a0)
	move.w 2(a1),6(a0)
	bra .done
.physical
	move.l time_loop_sim(pc),a1
	adda.l #$2d6be,a1
	move.l (sp),a0
	move.w (a1),4(a0)
	move.w 4(a1),6(a0)
.done
	movem.l (sp)+,a0-a1
	rts

; World and camera control resets belong to their simulation/service boundary.
; Keep native physical writes for UI compatibility; IRQ producers use raw deltas.
time_mouse_center:
	movem.l a0-a1,-(sp)
	lea time_mouse_live(pc),a1
	bra time_mouse_center_common

time_mouse_camera_center:
	movem.l a0-a1,-(sp)
	lea time_mouse_camera(pc),a1
time_mouse_center_common:
	bsr time_devices_owned
	beq .physical
	bsr time_mouse_center_pair
.physical
	move.l time_loop_sim(pc),a1
	adda.l #$2d6be,a1
	move.w #160,(a1)
	move.w #100,4(a1)
	movem.l (sp)+,a0-a1
	rts

; Each helper preserves the displaced arithmetic's X/N/Z/V/C result.
time_mouse_camera_x:
	movem.l a0-a1,-(sp)
	bsr time_devices_owned
	beq .native
	lea time_mouse_camera(pc),a1
	move.w #-160,d0
	add.w (a1),d0
	bra .done
.native
	move.w #-160,d0
	add.w 4(a2),d0
.done
	movem.l (sp)+,a0-a1
	rts

time_mouse_camera_y:
	movem.l a0-a1,-(sp)
	bsr time_devices_owned
	beq .native
	lea time_mouse_camera(pc),a1
	moveq #-100,d0
	add.w 2(a1),d0
	bra .done
.native
	moveq #-100,d0
	add.w 6(a2),d0
.done
	movem.l (sp)+,a0-a1
	rts

; Sampling consumes this camera interval even if joystick/button priority chose
; another input. Ignored mouse movement must not leak into a later camera sample.
; Replay the original MOVE/MOVEM epilogue with the patch return above saved regs.
time_mouse_camera_done:
	movem.l a0-a1,-(sp)
	lea time_camera_world_sampling(pc),a0
	tst.w (a0)
	bne .restore
	bsr time_devices_owned
	beq .restore
	lea time_mouse_camera(pc),a1
	bsr time_mouse_center_pair
.restore
	movem.l (sp)+,a0-a1
	move.l a3,d0
	movem.l 4(sp),d2-d7/a2-a3
	move.l (sp),32(sp)
	lea 32(sp),sp
	tst.l d0 ; original MOVE.L a3,d0 flags, after relocating the patch return
	rts

time_mouse_center_pair:
	move.w #160,(a1)
	move.w #100,2(a1)
	rts

; A private interleaving test uses the actual acquisition and reset primitives.
; No hardware, game state, native input queue or clock is modified.
time_mouse_error: dc.b "Red Baron: W6 mouse bytes or self-test mismatch",0
	even
time_mouse_live: dc.w 160,100
time_mouse_camera: dc.w 160,100
time_mouse_skip: dc.w 0
time_mouse_event: dcb.b 16,0
