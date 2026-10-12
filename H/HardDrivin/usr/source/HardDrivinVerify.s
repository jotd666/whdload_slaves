; VERIFY_DRIVE only. SPS 0126 native input tape, indexed by PAL fields.
; Build with -DVERIFY_DRIVE=1; mutually exclusive with VERIFY_ATTRACT.
; Optional VERIFY_STEPINPUT replaces race input with a per-pass constant-input
; coupling control. VERIFY_STEPINPUT_BRAKE selects its braking field. These
; are not the A/B tape; see GAME_TIME.md.
; Calibrated on deterministic PAL A500/68000, 512K Chip + 1536K slow,
; no Fast RAM, PRELOAD, CUSTOM2=0 and both host input ports disabled.
; Other CPU/memory profiles need validation; field-indexed input does not
; make the original frame-stepped physics independent of rendering speed.
;
; The title and first native race entry establish separate field epochs.
; Race field 1 is the first VBL after native $10ecc initialization. The race
; epoch continues across crashes/replays; recovery does not restart the tape.
; Records: field.l, mouse X.w, mouse Y.w, buttons.w, decoded key.w.
; Values hold until the next record; $ffffffff terminates without resetting.
; X/Y are absolute native positions (0..639 / 0..399), not mouse deltas.
; Buttons: 4 raises throttle, 1 lowers it, 5 brakes, 0 releases buttons.
; Release alone does not reset throttle. Any held button can skip replay.
; Absolute positions are published AFTER native VBL input accumulation.
; Keys are delivered once through the native $01212 reader's return path.
; A nonzero overflow byte invalidates a capture (unconsumed key overwritten).
; No pose, velocity, gear, race flag or collision state is injected.
;
; Window boundaries are AFTER VBL publication at game $003f2, [first,end).
; A: initial straight, first recovery waypoint at field 1198; no crash/replay.
;    This pointer change is not a checkpoint time-bonus crossing.
; B: recovered checkpoint -> stunt course -> jump -> collision -> full replay.
;    Ramp lip at field 4364; airborne beyond it; crash 4553..4748;
;    replay 4749..5504 (all 90 iterations); recovered by the end boundary.
; The earlier approach crash/replay (2095..2917) is outside both windows.
; Both windows require replaying the SAME tape from a fresh boot; do not
; start B with a pose injection or reset the field counter at its boundary.
; Sample fixture state, globals/clocks, front buffer and native swap events.
; Generic state capture anchors the race at $10ed4, then samples at VBL ENTRY
; ($00044) and at every physics return ($0cdb0, before RTS). Entry sample 0
; precedes race field 1's input publication; do not equate it with the older
; AFTER-publication window boundaries above. Retain both domains explicitly.
; Capture the complete allocated globals hunk and trailing BSS, including the
; RNG longword at a4-$6fc4 (native recurrence at $00a36). Compare hunk-relative
; pointers after calibrating each build/profile; absolute addresses can differ.
; Local capture/acceptance details and rebuild comparison: tmp/dev/docs/.
;
	IFND VERIFY_STEPINPUT_X
VERIFY_STEPINPUT_X equ 320
	ENDC
	IFLT VERIFY_STEPINPUT_X
	FAIL "VERIFY_STEPINPUT_X must be 0..639"
	ENDC
	IFGT VERIFY_STEPINPUT_X-639
	FAIL "VERIFY_STEPINPUT_X must be 0..639"
	ENDC

VERIFY_DRIVE_A_FIRST equ 1
VERIFY_DRIVE_A_END   equ 1251
VERIFY_DRIVE_B_FIRST equ 3000
VERIFY_DRIVE_B_END   equ 5600

_verify_drive_title:
	movem.l d1/a0-a1,-(a7)
	lea _verify_drive_state(pc),a0
	tst.w (a0)
	bne.s .armed
	lea _verify_drive_menu(pc),a1
	move.l a1,8(a0)
	move.w #1,(a0)
.armed:
	movem.l (a7)+,d1/a0-a1
	jsr -$7f92(a4)
	tst.l d0
	rts

_verify_drive_race:
	jsr -$7ff2(a4)		; displaced native button reset
	jsr -$7ff8(a4)		; displaced native mouse centring
	movem.l d0/a0-a1,-(a7)
	lea _verify_drive_state(pc),a0
	cmpi.w #2,(a0)
	beq.s .done
	clr.w (a0)
	clr.l 4(a0)
	clr.w 18(a0)
	lea _verify_drive_tape(pc),a1
	move.l a1,8(a0)
	IFD VERIFY_STEPINPUT_RAMP
	lea _verify_step_ramp_count(pc),a1
	clr.w (a1)
	ENDC
	move.w #2,(a0)
.done:
	movem.l (a7)+,d0/a0-a1
	rts

_verify_drive_vbl:
	movem.l d0-d1/a0-a1,-(a7)
	lea _verify_drive_state(pc),a0
	tst.w (a0)
	beq.s .done
	addq.l #1,4(a0)
	IFD VERIFY_STEPINPUT
	cmpi.w #2,(a0)
	beq.s .constant
	ENDC
	movea.l 8(a0),a1
	move.l 4(a0),d0
.next:
	cmp.l (a1),d0
	bcs.s .publish
	cmpi.l #-1,(a1)
	beq.s .publish
	move.l 4(a1),12(a0)
	move.w 8(a1),16(a0)
	move.w 10(a1),d1
	beq.s .advance
	tst.w 18(a0)
	beq.s .key
	st 2(a0)		; visible queue overrun: capture must reject
.key:
	move.w d1,18(a0)
.advance:
	lea 12(a1),a1
	move.l a1,8(a0)
	bra.s .next
.publish:
	move.l 12(a0),-$6a06(a4)
	move.w 16(a0),-$6a0a(a4)
	IFD VERIFY_STEPINPUT
	bra.s .done
.constant:
	move.l #(VERIFY_STEPINPUT_X<<16)|200,-$6a06(a4)
	move.w #4,-$6a0a(a4)
	IFD VERIFY_STEPINPUT_BRAKE
	bsr _verify_step_brake_buttons
	ENDC
	IFD VERIFY_STEPINPUT_RAMP
	bsr _verify_step_ramp_buttons
	ENDC
	ENDC
.done:
	IFD VERIFY_TIME_REPLAY
	; Release the input latch during crash/replay so native playback is not skipped.
	tst.b -$69fa(a4)
	bne.s .release
	tst.b -$5229(a4)
	beq.s .released
.release:
	clr.w -$6a0a(a4)
.released:
	ENDC
	movem.l (a7)+,d0-d1/a0-a1
	movea.l -$7036(a4),a0	; displaced instructions
	lea $dff180,a1
	rts

_verify_drive_key:
	move.l -4(a5),d0
	move.l a0,-(a7)
	lea _verify_drive_state(pc),a0
	tst.l d0
	bne.s .done
	moveq #0,d0
	move.w 18(a0),d0
	clr.w 18(a0)
.done:
	IFD VERIFY_TIME_PAUSE
	bsr _verify_time_pause_key
	ENDC
	IFD VERIFY_REPLAY_PAUSE
	bsr _verify_replay_pause_key
	ENDC
	movea.l (a7)+,a0
	tst.l d0
	unlk a5
	rts

; Optional controlled coupling experiment, never the field-tape acceptance run.
; X=320/Y=200 and button 4 are held after race entry; reassert at controls entry
; because native controls clears its button latch. No dynamics, clocks or RNG
; are injected. VBL publishes the same values, so mid-step VBL cannot steer it.
	IFD VERIFY_STEPINPUT
_verify_step_input:
	IFD VERIFY_STEPINPUT_RAMP
	move.l a0,-(a7)
	lea _verify_step_ramp_count(pc),a0
	addq.w #1,(a0)
	movea.l (a7)+,a0
	ENDC
	move.l #(VERIFY_STEPINPUT_X<<16)|200,-$6a06(a4)
	move.w #4,-$6a0a(a4)
	IFD VERIFY_STEPINPUT_BRAKE
	bsr _verify_step_brake_buttons
	ENDC
	IFD VERIFY_STEPINPUT_RAMP
	bsr _verify_step_ramp_buttons
	ENDC
	IFD VERIFY_TIME_REPLAY
	; The per-controls constant fixture must not undo the VBL replay release.
	tst.b -$69fa(a4)
	bne.s .replay_release
	tst.b -$5229(a4)
	beq.s .replay_ready
.replay_release:
	clr.w -$6a0a(a4)
.replay_ready:
	ENDC
	jsr -$7f92(a4)		; displaced decoded-key reader
	and.w #$ff,d0		; displaced mask, including its condition codes
	rts
	ENDC

	; phase.w, overflow.b, reserved.b, field.l, next.l, X/Y.w, buttons/key.w
_verify_drive_state:
	dc.w 0,0
	dc.l 0,0
	dc.w 320,200,0,0
_verify_drive_menu:
	; Space exits the title; a held click selects native automatic gears.
	dc.l 1
	dc.w 320,200,0,$20
	dc.l 1000
	dc.w 100,200,1,0
	dc.l 1050
	dc.w 100,200,0,0
	dc.l 1300
	dc.w 100,200,1,0
	dc.l 1350
	dc.w 320,200,0,0
	dc.l -1
_verify_drive_tape:
	; Initial straight: keep clear of oncoming traffic.
	dc.l 1
	dc.w 320,200,4,0
	dc.l 8
	dc.w 480,200,4,0
	dc.l 161
	dc.w 440,200,4,0
	dc.l 177
	dc.w 400,200,4,0
	dc.l 193
	dc.w 380,200,4,0
	dc.l 209
	dc.w 160,200,4,0
	dc.l 249
	dc.w 200,200,4,0
	dc.l 265
	dc.w 240,200,4,0
	dc.l 273
	dc.w 260,200,4,0
	dc.l 289
	dc.w 280,200,4,0
	dc.l 305
	dc.w 300,200,4,0
	dc.l 337
	dc.w 320,200,4,0
	dc.l 385
	dc.w 300,200,4,0
	dc.l 401
	dc.w 240,200,4,0
	dc.l 409
	dc.w 260,200,4,0
	dc.l 417
	dc.w 280,200,4,0
	dc.l 433
	dc.w 300,200,4,0
	dc.l 465
	dc.w 320,200,4,0
	dc.l 489
	dc.w 300,200,4,0
	dc.l 513
	dc.w 320,200,4,0
	dc.l 569
	dc.w 300,200,4,0
	dc.l 577
	dc.w 320,200,4,0
	dc.l 782
	dc.w 320,200,5,0
	dc.l 1014
	dc.w 300,200,5,0
	dc.l 1030
	dc.w 320,200,5,0
	dc.l 1038
	dc.w 300,200,5,0
	dc.l 1054
	dc.w 320,200,5,0
	dc.l 1086
	dc.w 320,200,0,0
	dc.l 1094
	dc.w 300,200,5,0
	dc.l 1126
	dc.w 400,200,5,0
	dc.l 1134
	dc.w 400,200,0,0
	dc.l 1150
	dc.w 400,200,5,0
	dc.l 1174
	dc.w 400,200,0,0
	dc.l 1182
	dc.w 400,200,5,0
	dc.l 1198
	dc.w 400,200,0,0
	dc.l 1302
	dc.w 400,200,5,0
	dc.l 1310
	dc.w 400,200,0,0
	dc.l 1462
	dc.w 400,200,4,0
	dc.l 1510
	dc.w 400,200,0,0
	dc.l 1591
	dc.w 420,200,0,0
	dc.l 1864
	dc.w 420,200,4,0
	dc.l 1888
	dc.w 420,200,0,0
	dc.l 1904
	dc.w 400,200,0,0
	dc.l 1912
	dc.w 400,200,5,0
	dc.l 1928
	dc.w 400,200,4,0
	dc.l 1936
	dc.w 420,200,4,0
	dc.l 2048
	dc.w 220,200,4,0
	; Release for the first full replay and native checkpoint recovery.
	dc.l 2096
	dc.w 320,200,0,0
	; Resume on the stunt course after native recovery.
	dc.l 2929
	dc.w 560,200,0,0
	dc.l 3002
	dc.w 560,200,4,0
	dc.l 3122
	dc.w 520,200,4,0
	dc.l 3130
	dc.w 500,200,4,0
	dc.l 3146
	dc.w 460,200,4,0
	dc.l 3162
	dc.w 440,200,0,0
	dc.l 3178
	dc.w 440,200,5,0
	dc.l 3194
	dc.w 420,200,5,0
	dc.l 3202
	dc.w 440,200,5,0
	dc.l 3226
	dc.w 420,200,0,0
	dc.l 3250
	dc.w 360,200,0,0
	dc.l 3267
	dc.w 320,200,0,0
	dc.l 3283
	dc.w 440,200,0,0
	dc.l 3331
	dc.w 360,200,0,0
	dc.l 3347
	dc.w 340,200,0,0
	dc.l 3379
	dc.w 320,200,0,0
	dc.l 3411
	dc.w 440,200,0,0
	dc.l 3427
	dc.w 440,200,4,0
	dc.l 3443
	dc.w 460,200,4,0
	dc.l 3491
	dc.w 400,200,0,0
	dc.l 3507
	dc.w 340,200,0,0
	dc.l 3523
	dc.w 440,200,0,0
	dc.l 3555
	dc.w 440,200,5,0
	dc.l 3571
	dc.w 440,200,0,0
	dc.l 3587
	dc.w 440,200,5,0
	dc.l 3603
	dc.w 360,200,0,0
	dc.l 3619
	dc.w 420,200,0,0
	dc.l 3635
	dc.w 360,200,0,0
	dc.l 3651
	dc.w 340,200,0,0
	dc.l 3667
	dc.w 320,200,0,0
	dc.l 3715
	dc.w 440,200,0,0
	dc.l 3731
	dc.w 360,200,0,0
	dc.l 3747
	dc.w 320,200,0,0
	dc.l 3763
	dc.w 320,200,5,0
	dc.l 3779
	dc.w 360,200,4,0
	dc.l 3811
	dc.w 320,200,4,0
	dc.l 3827
	dc.w 320,200,0,0
	dc.l 3843
	dc.w 360,200,4,0
	dc.l 3859
	dc.w 300,200,4,0
	dc.l 3875
	dc.w 340,200,4,0
	dc.l 3891
	dc.w 320,200,4,0
	dc.l 3939
	dc.w 380,200,4,0
	dc.l 3955
	dc.w 320,200,4,0
	dc.l 3971
	dc.w 380,200,4,0
	dc.l 3987
	dc.w 300,200,4,0
	; Align with the narrow ramp, then hold straight through takeoff.
	dc.l 4001
	dc.w 380,200,4,0
	dc.l 4097
	dc.w 360,200,4,0
	dc.l 4233
	dc.w 320,200,4,0
	; Release before replay begins; hold neutral through its completion.
	dc.l 4595
	dc.w 320,200,0,0
	dc.l -1

	IFD VERIFY_TIME_PAUSE
; Enter and leave the real native pause path using two one-shot decoded spaces.
; No mode flag, clock or car state is injected. The drive tape keeps advancing.
_verify_time_pause_key:
	tst.l d0
	bne.s .done
	cmpi.w #2,(a0)
	bne.s .done
	move.l a1,-(a7)
	lea .phase(pc),a1
	tst.b (a1)
	bne.s .resume
	cmpi.l #100,4(a0)
	bcs.s .restore
	move.b #1,(a1)
	moveq #$20,d0
	bra.s .restore
.resume:
	cmpi.b #1,(a1)
	bne.s .restore
	cmpi.l #200,4(a0)
	bcs.s .restore
	move.b #2,(a1)
	moveq #$20,d0
.restore:
	movea.l (a7)+,a1
.done:
	rts
.phase: dc.w 0
	ENDC

	IFD VERIFY_STEPINPUT_RAMP
; Input-only arithmetic coverage: increase for 64 passes, decrease for 64,
; then increase again. The VBL and controls hook publish the same held value.
_verify_step_ramp_buttons:
	move.l d0,-(a7)
	move.w _verify_step_ramp_count(pc),d0
	cmpi.w #64,d0
	bls.s .done
	cmpi.w #128,d0
	bhi.s .done
	move.w #1,-$6a0a(a4)
.done:
	move.l (a7)+,d0
	rts
_verify_step_ramp_count: dc.w 0
	ENDC

	IFD VERIFY_REPLAY_PAUSE
; Input-only replay pause: one SPACE at age>=24, another40 input fields later.
_verify_replay_pause_key:
	tst.l d0
	bne.s .done
	tst.b -$5229(a4)
	beq.s .done
	movem.l d1/a1,-(a7)
	lea .state(pc),a1
	tst.w (a1)
	bne.s .resume
	move.l _replay_state+RP_AGE(pc),d1
	cmpi.l #24,d1
	blo.s .restore
	move.w #1,(a1)
	move.l 4(a0),d1
	addi.l #40,d1
	move.l d1,2(a1)
	moveq #$20,d0
	bra.s .restore
.resume:
	cmpi.w #1,(a1)
	bne.s .restore
	move.l 4(a0),d1
	cmp.l 2(a1),d1
	blo.s .restore
	move.w #2,(a1)
	moveq #$20,d0
.restore:
	movem.l (a7)+,d1/a1
.done:
	rts
.state: dc.w 0
	dc.l 0
	ENDC

	IFD VERIFY_STEPINPUT_BRAKE
; Input-only braking diagnostic: hold throttle, then both buttons from the
; requested race field onward. VBL and controls publish the same held input.
; This is separate from the frozen VERIFY_DRIVE acceptance tape.
_verify_step_brake_buttons:
	move.l a0,-(a7)
	lea _verify_drive_state(pc),a0
	cmpi.l #VERIFY_STEPINPUT_BRAKE,4(a0)
	blo.s .done
	move.w #5,-$6a0a(a4)
.done:
	movea.l (a7)+,a0
	rts
	ENDC
