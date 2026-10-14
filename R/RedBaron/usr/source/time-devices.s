; W6 sampled joystick/analog axes/mouse buttons. Motion is in time-mouse.s.
; PERF_RANGE sim:2d412 8 bit=13
; PERF_RANGE sim:30a4e 6 bit=13
; PERF_RANGE sim:30afc 6 bit=13
; PERF_RANGE sim:1ecfe 6 bit=13
; PERF_RANGE sim:1ece8 6 bit=13
; PERF_RANGE sim:1ecf2 6 bit=13
; PERF_RANGE sim:1edae 6 bit=13
; PERF_RANGE sim:1edec 6 bit=13
TIME_DEVICE_CODE = $200

time_devices_install:
	movem.l d0-a6,-(sp)
	IFD VERIFY
	move.l perf_custom5(pc),d0
	lea time_devices_options(pc),a0
	move.l d0,(a0)
	ENDC
	lea .checks(pc),a3
	moveq #7,d7
.check
	move.l (a3)+,d0
	move.w (a3)+,d1
	move.w (a3)+,d2
	move.l a1,a4
	adda.l d0,a4
	cmp.w (a4),d1
	bne .bad
	move.l (a3)+,d0
	tst.w d2
	beq .absolute
	add.l a1,d0
.absolute
	cmp.l 2(a4),d0
	bne .bad
	dbf d7,.check
	move.l a1,a4
	adda.l #$2d418,a4
	cmpi.w #8,(a4)
	bne .bad
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.bad
	pea time_devices_mismatch(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
.checks:
	dc.l $2d412
	dc.w $4cdf,0
	dc.l $1c04303a
	dc.l $30a4e
	dc.w $3039,0
	dc.l $dff00c
	dc.l $30afc
	dc.w $c039,0
	dc.l $bfe001
	dc.l $1ecfe
	dc.w $207c,0
	dc.l $dff00c
	dc.l $1ece8
	dc.w $1039,1
	dc.l $2d7f2
	dc.l $1ecf2
	dc.w $1039,1
	dc.l $2d7f3
	dc.l $1edae
	dc.w $1039,1
	dc.l $2d6c8
	dc.l $1edec
	dc.w $1039,1
	dc.l $2d6ca
.patch:
	PL_START
	PL_PSS $2d412,time_devices_vbl_end,2
	PL_PS $30a4e,time_devices_joy
	PL_PS $30afc,time_devices_fire
	PL_PS $1ecfe,time_devices_joy_pointer
	PL_PS $1ece8,time_devices_x
	PL_PS $1ecf2,time_devices_y
	PL_PS $1edae,time_devices_left
	PL_PS $1edec,time_devices_right
	PL_END

; End of native VBlank, after calibrated analog callback has run. Replay its
; epilogue with the inserted patch return kept above the original caller return.
time_devices_vbl_end:
	bsr time_devices_capture
	movem.l 4(sp),d2/a2-a4
	move.l (sp),16(sp)
	lea 16(sp),sp
	move.l a0,-(sp)
	move.l time_loop_sim(pc),a0
	adda.l #$2d420,a0
	move.w (a0),d0
	move.l (sp)+,a0
	rts

; a0 packet: JOY1DAT.w, calibrated X/Y bytes, left/right mouse bytes, CIA.b, zero.
time_devices_sample:
	move.w $dff00c,d0
	andi.w #$303,d0
	move.w d0,(a0)
	move.l time_loop_sim(pc),a1
	adda.l #$2d7f2,a1
	move.w (a1),2(a0)
	move.l time_loop_sim(pc),a1
	adda.l #$2d6c8,a1
	move.b (a1),4(a0)
	move.b 2(a1),5(a0)
	move.b $bfe001,d0
	andi.b #$c0,d0
	move.b d0,6(a0)
	clr.b 7(a0)
	IFD VERIFY
	bsr time_devices_fixture
	ENDC
	rts

time_devices_seed:
	movem.l d0-a2,-(sp)
	IFD VERIFY
	move.l time_loop_cia(pc),a1
	lea time_devices_epoch(pc),a0
	move.l (a1),(a0)
	ENDC
	lea time_devices_last(pc),a0
	bsr time_devices_sample
	lea time_devices_live(pc),a1
	move.l (a0)+,(a1)+
	move.l (a0),(a1)
	IFD VERIFY
	lea time_devices_count(pc),a0
	clr.l (a0)
	clr.l 4(a0)
	ENDC
	movem.l (sp)+,d0-a2
	rts

time_devices_capture:
	move.w sr,-(sp)
	ori.w #$0700,sr
	movem.l d0-a6,-(sp)
	move.w time_keys_ready(pc),d0
	beq .done
	lea time_devices_raw(pc),a0
	bsr time_devices_sample
	lea time_devices_last(pc),a1
	move.l (a0),d0
	cmp.l (a1),d0
	bne .changed
	move.l 4(a0),d0
	cmp.l 4(a1),d0
	beq .done
.changed
	move.l (a0),(a1)
	move.l 4(a0),4(a1)
	lea time_devices_event(pc),a2
	move.l time_loop_cia(pc),a1
	move.l (a1),d0
	lea time_loop_state(pc),a3
	tst.l TIME_LOOP_ACTIVE(a3)
	beq .modal
	sub.l TIME_LOOP_PAUSED(a3),d0
	bra .stamp
.modal
	move.l TIME_LOOP_PAUSE_START(a3),d0
	sub.l TIME_LOOP_PAUSE_BASE(a3),d0
.stamp
	addq.l #1,d0
	move.l d0,(a2)
	move.w #TIME_DEVICE_CODE,4(a2)
	move.w (a0),6(a2)
	move.l 2(a0),8(a2)
	clr.l 12(a2)
	move.b 6(a0),12(a2)
	IFD VERIFY
	; Independent acquisition log: wall CIA, paused total, ownership, raw packet.
	lea time_devices_count(pc),a4
	move.l (a4),d0
	cmpi.l #32,d0
	bhs .publish
	mulu.w #20,d0
	lea time_devices_log(pc),a5
	adda.w d0,a5
	move.l (a1),(a5)+
	move.l TIME_LOOP_PAUSED(a3),(a5)+
	move.l TIME_LOOP_ACTIVE(a3),(a5)+
	move.l (a0),(a5)+
	move.l 4(a0),(a5)
.publish
	addq.l #1,(a4)
	ENDC
	move.l time_input_observe_state+8(pc),a0
	move.l a2,a1
	bsr time_input_push
.done
	movem.l (sp)+,d0-a6
	move.w (sp)+,sr
	rts

; a1 event, called on its active-time deadline by the shared input consumer.
time_devices_apply:
	movem.l a0,-(sp)
	lea time_devices_live(pc),a0
	move.w 6(a1),(a0)
	move.l 8(a1),2(a0)
	move.b 12(a1),6(a0)
	IFD VERIFY
	lea time_devices_consumed(pc),a0
	addq.l #1,(a0)
	ENDC
	movem.l (sp)+,a0
	rts

; Returns ownership in Z. Caller saves a0; no other register changes.
time_devices_owned:
	lea time_keys_ready(pc),a0
	tst.w (a0)
	beq .done
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_ACTIVE(a0)
.done
	rts

time_devices_joy:
	move.l a0,-(sp)
	bsr time_devices_owned
	beq .physical
	move.w time_devices_live(pc),d0
	bra .done
.physical
	move.w $dff00c,d0
.done
	move.l (sp)+,a0
	rts

time_devices_fire:
	move.l a0,-(sp)
	bsr time_devices_owned
	beq .physical
	and.b time_devices_live+6(pc),d0
	bra .done
.physical
	and.b $bfe001,d0
.done
	move.l (sp)+,a0
	rts

time_devices_joy_pointer:
	bsr time_devices_owned
	beq .physical
	lea time_devices_live(pc),a0
	rts
.physical
	movea.l #$dff00c,a0
	rts

time_devices_x:
	move.l a0,-(sp)
	bsr time_devices_owned
	beq .physical
	move.b time_devices_live+2(pc),d0
	bra .done
.physical
	move.l time_loop_sim(pc),a0
	adda.l #$2d7f2,a0
	move.b (a0),d0
.done
	move.l (sp)+,a0
	rts

time_devices_y:
	move.l a0,-(sp)
	bsr time_devices_owned
	beq .physical
	move.b time_devices_live+3(pc),d0
	bra .done
.physical
	move.l time_loop_sim(pc),a0
	adda.l #$2d7f3,a0
	move.b (a0),d0
.done
	move.l (sp)+,a0
	rts

time_devices_left:
	move.l a0,-(sp)
	bsr time_devices_owned
	beq .physical
	move.b time_devices_live+4(pc),d0
	bra .done
.physical
	move.l time_loop_sim(pc),a0
	adda.l #$2d6c8,a0
	move.b (a0),d0
.done
	move.l (sp)+,a0
	rts

time_devices_right:
	move.l a0,-(sp)
	bsr time_devices_owned
	beq .physical
	move.b time_devices_live+5(pc),d0
	bra .done
.physical
	move.l time_loop_sim(pc),a0
	adda.l #$2d6ca,a0
	move.b (a0),d0
.done
	move.l (sp)+,a0
	rts

	IFD VERIFY
; CUSTOM5 bit 23: producer-packet fixture, no hardware/game-state writes.
; Real digital decode/button/flight-reader paths consume this sampled packet.
time_devices_fixture:
	btst #7,time_devices_options+1(pc)
	beq .done
	clr.l (a0)
	move.l #$0000c000,4(a0)
	move.l time_loop_cia(pc),a1
	move.l (a1),d0
	sub.l time_devices_epoch(pc),d0
	cmpi.l #2,d0
	blo .done
	cmpi.l #20,d0
	bhs .fire
	move.w #3,(a0) ; native direction table maps JOY1DAT=3 to Right
	bra .done
.fire
	cmpi.l #38,d0
	blo .done
	cmpi.l #56,d0
	bhs .left
	move.b #$40,6(a0)
	bra .done
.left
	cmpi.l #74,d0
	blo .done
	cmpi.l #92,d0
	bhs .right
	move.b #$ff,4(a0)
	bra .done
.right
	cmpi.l #110,d0
	blo .done
	cmpi.l #128,d0
	bhs .done
	move.b #$ff,5(a0)
.done
	rts

	ENDC
time_devices_mismatch: dc.b "Red Baron: unexpected W6 device hook bytes",0
	even
	IFD VERIFY
time_devices_options: dc.l 0
time_devices_epoch: dc.l 0
time_devices_count: dc.l 0
time_devices_consumed: dc.l 0
	ENDC
time_devices_last: dcb.b 8,0
time_devices_raw: dcb.b 8,0
time_devices_live: dcb.b 8,0
time_devices_event: dcb.b 16,0
	IFD VERIFY
time_devices_log: dcb.b 20*32,0
	ENDC
