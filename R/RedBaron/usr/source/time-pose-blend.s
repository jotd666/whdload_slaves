; Interpolated candidate-pose buffer. Does not write game objects or publish frames.
; Same 26-byte record layout as time-poses.s. Valid lifecycle/model pairs blend;
; unmatched objects snap to current. Capture phase is observed, never modified.
time_pose_blend:
	movem.l d0-a6,-(sp)
	move.l time_pose_loop(pc),a0
	lea .fraction_base(pc),a6
.fraction_base
	adda.l #time_present_fraction-.fraction_base,a6
	jsr (a6)
	move.l d0,d5
	IFD VERIFY
	lea time_blend_header(pc),a0
	move.l d0,(a0)
	move.w time_pose_header(pc),4(a0)
	clr.l 6(a0)
	clr.w 10(a0)
	ENDC
	lea .output_base(pc),a2
.output_base
	adda.l #time_blend_output_ptr-.output_base,a2
	move.l (a2),a2
	move.l time_pose_buffers(pc),a3
	move.l time_pose_buffers+4(pc),a4
	move.w time_pose_header(pc),d7
	beq .done
	subq.w #1,d7
	move.w time_pose_header+2(pc),d6
	lea .position_base(pc),a6
.position_base
	adda.l #time_present_position-.position_base,a6
	lea .angle_base(pc),a5
.angle_base
	adda.l #time_present_angle-.angle_base,a5
.object
	move.l a3,a0
	move.l a2,a1
	moveq #12,d0
.copy
	move.w (a0)+,(a1)+
	dbf d0,.copy
	move.w 4(a3),d0
	beq .snap
	move.w d6,d0
	beq .snap
	subq.w #1,d0
	move.l a4,a0
	move.l (a3),d1
.find
	cmp.l (a0),d1
	beq .candidate
	adda.w #TIME_POSE_STRIDE,a0
	dbf d0,.find
	bra .snap
.candidate
	tst.w 4(a0)
	beq .snap
	move.w 6(a0),d0
	cmp.w 6(a3),d0
	bne .snap
	lea 8(a0),a0
	lea 8(a3),a1
	lea 8(a2),a2
	move.l d5,d2
	moveq #2,d4
.position
	move.l (a0)+,d0
	move.l (a1)+,d1
	jsr (a6)
	move.l d0,(a2)+
	dbf d4,.position
	moveq #2,d4
.angle
	moveq #0,d0
	moveq #0,d1
	move.w (a0)+,d0
	move.w (a1)+,d1
	jsr (a5)
	move.w d0,(a2)+
	dbf d4,.angle
	IFD VERIFY
	lea time_blend_header(pc),a0
	addq.w #1,6(a0)
	ENDC
	bra .next
.snap
	adda.w #TIME_POSE_STRIDE,a2
	IFD VERIFY
	lea time_blend_header(pc),a0
	addq.w #1,8(a0)
	ENDC
.next
	adda.w #TIME_POSE_STRIDE,a3
	dbf d7,.object
.done
	IFD VERIFY
	lea time_blend_header(pc),a0
	move.w #1,10(a0)
	ENDC
time_pose_blended:
	nop
	movem.l (sp)+,d0-a6
	rts
	IFD VERIFY
time_blend_header: dc.l 0
	dc.w 0,0,0,0 ; count, blended, snapped, ready
	ENDC
