; fixed-step timing render phase at completed-world loop re-entry. No new sim hooks.
; Cockpit and native pose-copy attached views lease camera/world poses together.
; Orbit/free-camera modes retain native poses until their separate clocks are covered.
time_render_frame:
	movem.l d0-a6,-(sp)
	lea time_render_started(pc),a0
	tst.w (a0)
	beq time_render_done
	move.l time_pose_loop(pc),a0
	tst.w TIME_LOOP_DUE(a0)
	bne time_pose_bad
	lea time_render_active(pc),a0
	clr.w (a0)
	lea .quantum_base(pc),a0
.quantum_base
	adda.l #time_loop_quantum-.quantum_base,a0
	cmpi.w #450,(a0)
	beq .native ; 68000 presents the latest world state
	bsr time_pose_blend
	move.l time_pose_h3(pc),a3
	lea time_pose_header(pc),a4
	move.w $6712(a3),d0
	cmp.w 24(a4),d0
	bne .native
	move.w time_render_camera_active(pc),d1
	bne time_pose_bad
	moveq #0,d4
	move.l a3,a0
	adda.l #$8d72,a0
	move.l (a0),d6
	cmp.l 16(a4),d6
	bne .native
	tst.w d0
	beq .camera_ready
	cmpi.w #5,d0
	bhi .native
	lea .callback_base(pc),a0
.callback_base
	adda.l #time_loop_sim-.callback_base,a0
	move.l (a0),d1
	addi.l #$15666,d1 ; native attached-camera pose copy, no orbit/free update
	cmp.l $1a70(a3),d1
	bne .native
	move.l a3,d1
	addi.l #$677a,d1
	cmp.l d1,d6
	bne .native
	move.l $67ae(a3),d6
	cmp.l time_pose_camera_target(pc),d6
	bne .native
	moveq #1,d4
.camera_ready
	moveq #0,d5 ; require camera among the leased normal objects
	move.w (a4),d7
	beq .native
	subq.w #1,d7
	move.l time_pose_buffers(pc),a2
.preflight
	tst.w 4(a2)
	beq .native
	move.l (a2),a0
	cmp.l (a2),d6
	bne .not_camera
	moveq #1,d5
	tst.w d4
	beq .not_camera
	lea 8(a0),a1
	move.l a3,a6
	adda.l #$6782,a6
	moveq #8,d0
.check_camera
	cmpm.w (a1)+,(a6)+
	bne .native
	dbf d0,.check_camera
.not_camera
	move.w 2(a0),d0
	cmp.w 6(a2),d0
	bne .native
	lea 8(a0),a0
	lea 8(a2),a1
	moveq #8,d0
.check_pose
	cmpm.w (a0)+,(a1)+
	bne .native
	dbf d0,.check_pose
	adda.w #TIME_POSE_STRIDE,a2
	dbf d7,.preflight
	tst.w d5
	beq .native
	lea time_render_active(pc),a0
	move.w #1,(a0)
	tst.w d4
	beq .camera_saved
	move.l a3,a6
	adda.l #$6782,a6
	lea time_render_camera_saved(pc),a1
	moveq #8,d0
.save_camera
	move.w (a6)+,(a1)+
	dbf d0,.save_camera
	lea time_render_camera_active(pc),a0
	move.w #1,(a0)
.camera_saved
	lea .output_base(pc),a2
.output_base
	adda.l #time_blend_output_ptr-.output_base,a2
	move.l (a2),a2
	move.w (a4),d7
	subq.w #1,d7
.apply
	tst.w d4
	beq .apply_object
	cmp.l (a2),d6
	bne .apply_object
	move.l a3,a6
	adda.l #$6782,a6
	lea 8(a2),a1
	moveq #8,d0
.apply_camera
	move.w (a1)+,(a6)+
	dbf d0,.apply_camera
.apply_object
	move.l (a2),a0
	lea 8(a0),a0
	lea 8(a2),a1
	moveq #8,d0
.apply_pose
	move.w (a1)+,(a0)+
	dbf d0,.apply_pose
	adda.w #TIME_POSE_STRIDE,a2
	dbf d7,.apply
	bra .draw
.native
.draw
	move.l time_pose_h3(pc),a3
	move.w #1,-(sp)
	move.w $7856(a3),-(sp)
	lea .sim_base(pc),a0
.sim_base
	adda.l #time_loop_sim-.sim_base,a0
	move.l (a0),a0
	adda.l #$56c,a0
time_render_before_draw:
	jsr (a0)
	addq.l #4,sp
time_render_after_draw:
	nop
	lea time_render_active(pc),a0
	tst.w (a0)
	beq .dirty
	lea time_render_camera_active(pc),a0
	tst.w (a0)
	beq .camera_restored
	move.l time_pose_h3(pc),a6
	adda.l #$6782,a6
	lea time_render_camera_saved(pc),a1
	moveq #8,d0
.restore_camera
	move.w (a1)+,(a6)+
	dbf d0,.restore_camera
	clr.w (a0)
.camera_restored
	lea time_pose_header(pc),a4
	move.w (a4),d7
	subq.w #1,d7
	move.l time_pose_buffers(pc),a2
.restore
	move.l (a2),a0
	lea 8(a0),a0
	lea 8(a2),a1
	moveq #8,d0
.restore_pose
	move.w (a1)+,(a0)+
	dbf d0,.restore_pose
	adda.w #TIME_POSE_STRIDE,a2
	dbf d7,.restore
	lea time_render_active(pc),a0
	clr.w (a0)
.dirty
	move.l time_pose_h3(pc),a3
	subq.w #1,$7856(a3)
	bge .count
	clr.w $7856(a3)
.count
time_render_restored:
	nop
time_render_done:
	movem.l (sp)+,d0-a6
	rts

time_render_started: dc.w 0
time_render_active: dc.w 0

time_render_camera_active: dc.w 0
time_render_camera_saved: dcb.b 18,0
