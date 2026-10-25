; fixed-step timing continuous camera service. One original 128-unit camera update per
; funded secondary tick. View commands remain exactly once on the world path.

time_camera_install:
	movem.l d0-a6,-(sp)
	lea .checks(pc),a3
	moveq #2,d7
.next
	move.l (a3)+,d0
	move.w (a3)+,d1
	move.l a3,a0
	bsr perf_check_bytes
	adda.w d1,a3
	dbf d7,.next
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.checks:
	dc.l $21dce
	dc.w 8,$4eba,$ccb2,$4fef,$000c
	dc.l $16774
	dc.w 6,$6100,$efee,$584f
	dc.l $16788
	dc.w 6,$6100,$f0a6,$584f
.patch:
	PL_START
	PL_PSS $21dce,time_camera_world_build,2
	PL_PS $16774,time_camera_world_orbit
	PL_PS $16788,time_camera_world_free
	PL_END

time_camera_reset:
	movem.l d0/a0,-(sp)
	lea time_camera_state(pc),a0
	moveq #7,d0
.clear
	clr.l (a0)+
	dbf d0,.clear
	clr.w (a0)
	movem.l (sp)+,d0/a0
	rts

; Caller has just funded d1=0/1 service ticks. Preserve its world-due result.
; Before the route's input handoff, retain the original camera behavior.
time_camera_advance:
	movem.l d0-a6,-(sp)
	tst.w d1
	beq time_camera_advance_done
	bsr time_devices_owned
	beq time_camera_advance_done
	lea time_camera_sampling(pc),a0
	move.w #1,(a0)
	lea time_camera_input(pc),a0
	clr.l (a0)
	clr.l 4(a0)
	clr.l 8(a0)
	clr.w 12(a0)
	move.l a0,-(sp)
	move.l time_loop_input(pc),a0
	jsr (a0)
	addq.l #4,sp
	; F7/F8 are native world-input overrides used by camera controls too.
	lea time_keys_bitmap(pc),a0
	lea time_camera_input(pc),a1
	move.w #-127,d0
	tst.b $57(a0)
	bne .override
	move.w #127,d0
	tst.b $58(a0)
	beq .build
.override
	ori.b #$30,10(a1)
	clr.w (a1)
	move.w d0,2(a1)
.build
	move.w #1,-(sp)
	pea time_camera_input(pc)
	pea time_camera_controls(pc)
	move.l time_loop_sim(pc),a0
	adda.l #$1ea82,a0
	jsr (a0)
	lea 10(sp),sp
	lea time_camera_sampling(pc),a0
	clr.w (a0)
	move.l time_loop_h3(pc),a2
	move.w $4836(a2),-(sp)
	move.w #128,$4836(a2)
	tst.w $1ada(a2)
	bne .orbit
	cmpi.w #24,$6712(a2)
	bne .restore_clock
	move.l time_loop_sim(pc),a0
	adda.l #$15830,a0
	bra .update
.orbit
	move.l time_loop_sim(pc),a0
	adda.l #$15764,a0
.update
	pea time_camera_controls(pc)
	jsr (a0)
	addq.l #4,sp
	; Native follow/orbit callback refreshes the camera pose after its controls.
	move.l $1a70(a2),d0
	beq .restore_clock
	move.l d0,a0
	jsr (a0)
.restore_clock
	move.w (sp)+,$4836(a2)
time_camera_observe:
	nop
time_camera_advance_done:
	movem.l (sp)+,d0-a6
	rts

; Rebuild only the one-shot view command on a world boundary. Continuous input
; comes from the latest service packet and must not consume another mouse sample.
; Original call has output.l, input.l, allow_mouse.w, padding.w on its stack.
time_camera_world_build:
	movem.l d0-a6,-(sp)
	move.l 64(sp),a3
	move.l 68(sp),a4
	move.w 72(sp),d7
	bsr time_devices_owned
	beq .native
	lea time_camera_world_sampling(pc),a0
	move.w #1,(a0)
	moveq #0,d7
.native
	move.w d7,-(sp)
	move.l a4,-(sp)
	move.l a3,-(sp)
	move.l time_loop_sim(pc),a0
	adda.l #$1ea82,a0
	jsr (a0)
	lea 10(sp),sp
	lea time_camera_world_sampling(pc),a0
	tst.w (a0)
	beq .done
	clr.w (a0)
	lea time_camera_controls(pc),a0
	move.w 2(a0),2(a3)
	move.l 4(a0),4(a3)
.done
	move.l a3,(sp) ; native return d0 is the output pointer
	movem.l (sp)+,d0-a6
	move.l (sp),12(sp)
	lea 12(sp),sp
	tst.l d0
	rts

; Skip only the timed camera calls on world updates. Other native camera work,
; view commands, change detection and mission-tape packet emission stay intact.
time_camera_world_orbit:
	movem.l d0-a6,-(sp)
	move.l time_loop_sim(pc),a3
	adda.l #$15764,a3
	bra time_camera_world_timed
time_camera_world_free:
	movem.l d0-a6,-(sp)
	move.l time_loop_sim(pc),a3
	adda.l #$15830,a3
time_camera_world_timed:
	bsr time_devices_owned
	bne .done
	move.l 64(sp),-(sp)
	jsr (a3)
	addq.l #4,sp
.done
	movem.l (sp)+,d0-a6
	move.l (sp),4(sp)
	addq.l #4,sp
	rts

; Sampling returns no command and never changes the world's command FIFO.
; time_keys_pop branches here after saving a0 when sampling is active.
time_camera_no_command:
	moveq #0,d0
	move.l time_loop_sim(pc),a0
	adda.l #$309fc,a0
	move.l a0,4(sp)
	move.l (sp)+,a0
	rts

	even
time_camera_state:
time_camera_sampling: dc.w 0
time_camera_world_sampling: dc.w 0
	dcb.l 2,0 ; reserved in the camera packet layout
time_camera_controls: dcb.b 8,0
time_camera_input: dcb.b 14,0
