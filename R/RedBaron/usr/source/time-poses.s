; Consecutive completed-world pose snapshots. VERIFY bit 13 / sim v1 only.
; PERF_RANGE sim:0fe1e 6 bit=13
; PERF_RANGE sim:0fed2 6 bit=13
TIME_POSE_CAPACITY = 500
TIME_POSE_STRIDE = 26 ; pointer.l, valid.w, model.w, position.l*3, angle.w*3

time_pose_install:
	movem.l d0-a6,-(sp)
	lea time_pose_resload(pc),a0
	move.l a2,(a0)
	move.l a1,a0
	adda.l #$fe1e,a0
	cmpi.l #$224b2089,(a0)
	bne time_pose_bad
	cmpi.w #$2449,4(a0)
	bne time_pose_bad
	move.l a1,a0
	adda.l #$fed2,a0
	cmpi.l #$7000102b,(a0)
	bne time_pose_bad
	cmpi.w #$0001,4(a0)
	bne time_pose_bad
	lea .loop_base(pc),a0
.loop_base
	adda.l #time_loop_state-.loop_base,a0
	lea time_pose_loop(pc),a3
	move.l a0,(a3)+
	lea .h3_base(pc),a0
.h3_base
	adda.l #time_loop_h3-.h3_base,a0
	move.l (a0),(a3)+
	lea .current_base(pc),a0
.current_base
	adda.l #time_pose_current-.current_base,a0
	move.l a0,(a3)+
	lea .previous_base(pc),a0
.previous_base
	adda.l #time_pose_previous-.previous_base,a0
	move.l a0,(a3)
	lea .attn_base(pc),a0
.attn_base
	adda.l #perf_attnflags+3-.attn_base,a0
	btst #0,(a0)
	beq .patch_ready
	lea time_pose_ccr(pc),a0
	move.w #$42c0,(a0)
.patch_ready
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.patch:
	PL_START
	PL_PS $fe1e,time_pose_added
	PL_PS $fed2,time_pose_removed
	PL_END

time_pose_added:
	bsr time_pose_invalidate
	move.l a3,a1
	move.l a1,(a0)
	move.l a1,a2
	rts
time_pose_removed:
	bsr time_pose_invalidate
	moveq #0,d0
	move.b 1(a3),d0
	rts

; Clear both pair members for the affected address. This catches remove/add
; within one tick even when model ID, address and final active flag are equal.
time_pose_invalidate:
	movem.l d0-d2/a0-a2,-(sp)
	bsr time_pose_ccr
	move.w d0,-(sp)
	lea time_pose_header(pc),a2
	addq.l #1,28(a2)
	moveq #1,d2
	lea time_pose_buffers(pc),a1
.buffer
	move.l (a1)+,a0
	move.w (a2)+,d1
	beq .next_buffer
	subq.w #1,d1
.record
	cmp.l (a0),a3
	bne .next
	clr.w 4(a0)
.next
	adda.w #TIME_POSE_STRIDE,a0
	dbf d1,.record
.next_buffer
	dbf d2,.buffer
	move.w (sp)+,ccr
	movem.l (sp)+,d0-d2/a0-a2
	rts
time_pose_ccr:
	move.w sr,d0
	rts

; Called once at native loop re-entry, before funding the next update. The
; completed step includes the native post-draw bookkeeping and sound path.
time_pose_capture:
	movem.l d0-a6,-(sp)
	lea time_pose_header(pc),a4
	move.l time_pose_loop(pc),a0
	move.l TIME_LOOP_STEPS(a0),d7
	tst.w 12(a4)
	bne .continuing
	clr.l (a4)
	clr.w 12(a4)
	clr.l 28(a4)
	clr.l 32(a4)
.continuing
	move.l time_pose_h3(pc),a3
	move.l a3,a0
	adda.l #$8d72,a0
	move.l (a0),d5
	move.w $6712(a3),d6
	tst.w 12(a4)
	beq .first
	move.l 4(a4),d0
	addq.l #1,d0
	cmp.l d7,d0
	bne time_pose_bad
	move.l 4(a4),8(a4)
	move.l 16(a4),20(a4)
	move.w 24(a4),26(a4)
	move.w (a4),2(a4)
	move.l time_pose_buffers(pc),a0
	move.l time_pose_buffers+4(pc),a1
	moveq #0,d0
	move.w (a4),d0
	mulu #TIME_POSE_STRIDE/2,d0
	beq .copied
	subq.w #1,d0
.copy
	move.w (a0)+,(a1)+
	dbf d0,.copy
.copied
	cmp.l 16(a4),d5
	bne .view_change
	cmp.w 24(a4),d6
	beq .first
.view_change
	clr.w 2(a4) ; discontinuous camera/view: no previous pair
.first
	move.l d7,4(a4)
	move.l d5,16(a4)
	move.w d6,24(a4)
	move.w #1,12(a4)
	move.l a3,a2
	adda.l #$859e,a2
	moveq #0,d7
	move.w (a2)+,d7
	cmpi.w #TIME_POSE_CAPACITY,d7
	bhi time_pose_bad
	move.w d7,(a4)
	move.l time_pose_buffers(pc),a1
	tst.w d7
	beq .done
	subq.w #1,d7
.object
	move.l (a2)+,a0
	move.l a0,d0
	beq time_pose_bad
	btst #0,d0
	bne time_pose_bad
	btst #6,(a0)
	bne time_pose_bad ; compact layout needs a separate contract
	move.l a0,(a1)+
	move.w #1,(a1)+
	move.w 2(a0),(a1)+
	lea 8(a0),a0
	moveq #8,d0
.pose
	move.w (a0)+,(a1)+
	dbf d0,.pose
	dbf d7,.object
.done
	addq.l #1,32(a4)
	bsr time_pose_blend
time_pose_captured:
	nop
	movem.l (sp)+,d0-a6
	rts

time_pose_bad:
	pea time_pose_error(pc)
	pea TDREASON_FAILMSG
	move.l time_pose_resload(pc),a2
	jmp resload_Abort(a2)
time_pose_error: dc.b "Red Baron: W6 pose hook, layout or tick continuity failure",0
	even
time_pose_resload: dc.l 0
time_pose_loop: dc.l 0
time_pose_h3: dc.l 0
time_pose_buffers: dc.l 0,0
; current/previous counts, tick IDs, ready, reserved, camera pointers, view
; modes, lifecycle event count, capture count.
time_pose_header: dcb.b 36,0
