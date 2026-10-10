; W6 flight-loop integration checkpoint, VERIFY only / CUSTOM2 bit 13.
; Not player enabled: service clocks, interpolation and remaining input gates remain.
; PERF_RANGE sim:21d28 8 bit=13
; PERF_RANGE sim:21e7a 6 bit=13
; PERF_RANGE sim:03d5e 6 bit=13
; PERF_RANGE sim:21f60 6 bit=13
TIME_LOOP_CURSOR = 20
TIME_LOOP_DUE = 24
TIME_LOOP_SERVICES = 26
TIME_LOOP_STEPS = 28
TIME_LOOP_SKIPS = 32
TIME_LOOP_DRAWS = 36
TIME_LOOP_ACTIVE = 40
TIME_LOOP_PAUSED = 44
TIME_LOOP_PAUSE_START = 48
TIME_LOOP_PAUSE_DEPTH = 52
TIME_LOOP_PAUSE_BASE = 56

time_loop_install:
	movem.l d0-a6,-(sp)
	move.l #$21d28,d0
	moveq #8,d1
	lea time_loop_gate_bytes(pc),a0
	bsr perf_check_bytes
	move.l #$21e7a,d0
	moveq #6,d1
	lea time_loop_draw_bytes(pc),a0
	bsr perf_check_bytes
	move.l #$21f60,d0
	lea time_loop_exit_bytes(pc),a0
	bsr perf_check_bytes
	move.l a1,a3
	adda.l #$3d5e,a3
	cmpi.w #$33c0,(a3)
	bne .bad
	; Both relocated operands independently identify the expected h3 region.
	move.l a1,a4
	adda.l #$21d22,a4
	cmpi.w #$4239,(a4)
	bne .bad
	move.l 2(a4),d0
	subi.l #$783c,d0
	move.l d0,a4
	addi.l #$4836,d0
	cmp.l 2(a3),d0
	bne .bad
	lea time_loop_sim(pc),a0
	move.l a1,(a0)+
	move.l a4,(a0)+
	move.l a1,d0
	addi.l #$30006,d0
	move.l d0,(a0)+
	move.l a1,d0
	addi.l #$1ecc2,d0
	move.l d0,(a0)+
	move.l a1,d0
	addi.l #$21d30,d0
	move.l d0,(a0)
	bsr time_message_install
	bsr time_rate_install
	bsr time_pause_selftest
	bsr time_pause_install
	bsr time_devices_install
	bsr time_mouse_install
	bsr time_keys_install
	bsr time_camera_install
	bsr time_auto_install
	bsr time_compress_install
	bsr time_present_selftest
	bsr time_present_state_install
	bsr time_model_install
	move.l a6,-(sp)
	lea .pose_install_base(pc),a6
.pose_install_base
	adda.l #time_pose_install-.pose_install_base,a6
	jsr (a6)
	move.l (sp)+,a6
	lea time_loop_patch(pc),a0
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
.bad
	pea perf_mismatch(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
time_loop_gate_bytes: dc.w $486d,$fff2,$4eba,$cf94
time_loop_draw_bytes: dc.w $4a6d,$ffd0,$6708
time_loop_exit_bytes: dc.w $4cdf,$00e0,$4e5d
time_loop_patch:
	PL_START
	PL_PSS $21d28,time_loop_gate,2
	PL_PS $21e7a,time_loop_draw
	PL_PS $3d5e,time_loop_clock
	PL_P $21f60,time_loop_exit
	PL_END

; Advance the cursor only until a world boundary is due or the observed time is
; exhausted. The next call resumes from this cursor; no elapsed time is dropped.
; a0 = state; preserves all registers. Single main-task owner, IRQ only reads CIA.
time_loop_poll:
	movem.l d0-d3/a1-a2,-(sp)
	tst.w TIME_LOOP_DUE(a0)
	bne .done
	move.l time_loop_cia(pc),a1
	move.l (a1),d3
	move.l d3,d0
	sub.l TIME_LOOP_CURSOR(a0),d0
	tst.l d0
	bmi .bad
.loop
	cmp.l TIME_LOOP_CURSOR(a0),d3
	beq .done
	addq.l #1,TIME_LOOP_CURSOR(a0)
	bsr time_keys_advance
	bsr time_rate_advance
	move.w time_rate_queue+8(pc),d0
	cmpi.w #10,d0
	blo .bad
	cmpi.w #80,d0
	bhi .bad
	moveq #1,d1
	move.l time_loop_h3(pc),a1
	tst.w $45a6(a1)
	beq .rate_ready
	moveq #8,d1
.rate_ready
	bsr time_core_advance
	add.w d1,TIME_LOOP_SERVICES(a0)
	move.w d0,TIME_LOOP_DUE(a0)
	bsr time_camera_advance
	bsr time_message_advance
	move.l TIME_LOOP_PAUSED(a0),d2
	bsr time_auto_advance
	; Modal return rebases the cursor. Do not keep the pre-menu CIA endpoint.
	cmp.l TIME_LOOP_PAUSED(a0),d2
	bne .done
	lea time_auto_exit(pc),a1
	tst.w (a1)
	bne .done
	tst.w TIME_LOOP_DUE(a0)
	beq .loop
.done
	movem.l (sp)+,d0-d3/a1-a2
	rts
.bad
	pea time_loop_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)

; Preserve the original input helper's caller/argument layout, including the
; sim:21d30 return address used by native code and the existing VERIFY tape.
time_loop_gate:
	movem.l d0-a6,-(sp)
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_ACTIVE(a0)
	bne .ready
	move.l a0,a1
	moveq #14,d0
.clear
	clr.l (a1)+
	dbf d0,.clear
	move.l #1,TIME_LOOP_ACTIVE(a0)
	move.l time_loop_cia(pc),a1
	move.l (a1),TIME_LOOP_CURSOR(a0)
	bsr time_rate_reset
	bsr time_message_reset
	bsr time_camera_reset
	bsr time_auto_reset
	bsr time_compress_reset
	lea .pose_reset_base(pc),a1
.pose_reset_base
	adda.l #time_pose_header-.pose_reset_base,a1
	clr.w 12(a1)
.ready
	move.l a6,-(sp)
	lea .pose_capture_base(pc),a6
.pose_capture_base
	adda.l #time_pose_capture-.pose_capture_base,a6
	jsr (a6)
	move.l (sp)+,a6
	bsr time_keys_start
	bsr time_camera_fixture
	bsr time_rate_fixture
	bsr time_message_fixture
.wait
	bsr time_loop_poll
	lea time_auto_exit(pc),a1
	tst.w (a1)
	bne .auto_exit
	tst.w TIME_LOOP_DUE(a0)
	bne .world
	move.l a6,-(sp)
	lea .render_base(pc),a6
.render_base
	adda.l #time_render_frame-.render_base,a6
	jsr (a6)
	move.l (sp)+,a6
	bra .wait
; Route native menu results 2/3 through the original flight exit decision.
; No input arguments were pushed, so the frame stack already matches sim:21d3a.
.auto_exit
	moveq #0,d0
	move.w time_auto_exit(pc),d0
	move.l d0,(sp)
	lea time_auto_exit(pc),a1
	clr.w (a1)
	move.l time_loop_sim(pc),a1
	adda.l #$21d3a,a1
	move.l a1,60(sp)
	movem.l (sp)+,d0-a6
	rts
.world
	subq.w #1,TIME_LOOP_DUE(a0)
	addq.l #1,TIME_LOOP_STEPS(a0)
	move.l time_loop_h3(pc),a1
	move.w #225,$4834(a1)
	movem.l (sp)+,d0-a6
	addq.l #4,sp ; discard patch return, reconstruct original PEA/JSR
	pea -14(a5)
	move.l time_loop_return(pc),-(sp)
	move.l time_loop_input(pc),-(sp)
	rts

; Catch-up must not consume either buffer's dirty countdown. The remaining
; original loop still performs world bookkeeping and sound in native order.
time_loop_draw:
	movem.l d0-a0,-(sp)
	bsr time_compress_fixture
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_ACTIVE(a0)
	beq .original
	; Always defer. Services run only at completed-world gate re-entry.
	; This counter now counts deferred legacy draw sites, not sampled debt.
	addq.l #1,TIME_LOOP_SKIPS(a0)
	lea .started_base(pc),a0
.started_base
	adda.l #time_render_started-.started_base,a0
	move.w #1,(a0)
	move.l time_loop_sim(pc),d0
	addi.l #$21ea8,d0
	move.l d0,36(sp)
	movem.l (sp)+,d0-a0
	rts
.original
	movem.l (sp)+,d0-a0
	tst.w -48(a5)
	bne .done
	addq.l #8,(sp) ; patch return sim:21e80 -> original taken branch sim:21e88
.done
	rts

; Retain the original secondary/elapsed clock for this integration checkpoint.
; Override primary only while the new loop owns flight, even when native
; compression attempts its historical clock overwrite. No menu clock changes.
time_loop_clock:
	move.l a0,-(sp)
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_ACTIVE(a0)
	beq .original
	move.l time_loop_h3(pc),a0
	move.w #225,$4834(a0)
.original
	move.l time_loop_h3(pc),a0
	move.w d0,$4836(a0)
	move.l (sp)+,a0
	rts

; PL_P introduces no extra return. MOVEM and address arithmetic preserve the
; native exit's flags and d0 return value while clearing scheduler ownership.
time_loop_exit:
	movem.l a0-a1,-(sp)
	lea time_loop_state(pc),a1
	suba.l a0,a0
	movem.l a0,TIME_LOOP_ACTIVE(a1)
	lea time_keys_ready(pc),a1
	movem.w a0,(a1)
	movem.l (sp)+,a0-a1
	movem.l (sp)+,d5-d7
	unlk a5
	rts

time_loop_error: dc.b "Red Baron: W6 invalid clock interval or divisor",0
	even
	dc.b "RBTLOOP0"
time_loop_sim: dc.l 0
time_loop_h3: dc.l 0
time_loop_cia: dc.l 0
time_loop_input: dc.l 0
time_loop_return: dc.l 0
time_loop_state: dcb.b 60,0
