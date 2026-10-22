; Fixed 20 ms PAL simulation steps, selected by CUSTOM2 and CPU/Fast RAM.
; Rendering remains vsynced and runs as fast as possible. Rider-heading
; prediction affects display only. Input history exhaustion aborts explicitly.

; Select only if enabled, CPU >= 020, and the allocated public slave hunk is
; in a conventional Fast RAM window. Do not mistake Chip or $c00000 slow RAM
; for Fast RAM. Reject the whole reserved upper-24-bit window conservatively.
; No probing of unallocated addresses or extra allocation is needed.
; Save the selected path for relocation/HUD setup. Return d0=0/1.
step_select_path:
	lea enhanced_selected(pc),a0
	clr.l (a0)
	move.l _enhanced_framerate(pc),d0
	beq .no
	move.l cpu_attention(pc),d1
	btst #1,d1
	beq .no
	lea _base(pc),a1
	cmpa.l #$200000,a1
	bcs .no
	cmpa.l #$a00000,a1
	bcs .yes
	cmpa.l #$1000000,a1
	bcs .no
.yes:
	move.l #3,(a0)
	moveq #1,d0
	rts
.no:
	moveq #0,d0
	rts

	IFND STEP_FIELDS
STEP_FIELDS = 1
	ENDC
	IFND STEP_INPUT_SLOTS
STEP_INPUT_SLOTS = 2048
	ENDC
	IFLT STEP_INPUT_SLOTS-2
	FAIL "Input history needs at least two slots"
	ENDC
	IFGT STEP_INPUT_SLOTS-32768
	FAIL "Input history exceeds signed word indexing"
	ENDC
	IFNE STEP_INPUT_SLOTS&(STEP_INPUT_SLOTS-1)
	FAIL "Input history capacity must be a power of two"
	ENDC
step_reset:
	movem.l d0-d7/a0-a6,-(a7)
	bsr step_priority_begin
	move.l $a5d4c,d0
public_ref_19 equ *-4
	bsr step_reset_history
	jsr $8f552
public_ref_20 equ *-4
	lea step_start_frame(pc),a0
	move.w d0,(a0)
	movem.l (a7)+,d0-d7/a0-a6
	move.l #$87040,$a5916
public_ref_21 equ *-8
public_ref_22 equ *-4
	rts

; Native initialization calls the patched race loop and field handler before
; installing the race interrupt. Reset history before those priming calls too.
; Cursor field-1 reproduces the first boot's initial step at field 1.
step_prepare:
	movem.l d0-d7/a0-a6,-(a7)
	bsr e_masks_build
	bsr e_dirty_reset
	bsr f_hud_reset
	bsr step_priority_begin
	move.l $a5d4c,d0
public_ref_23 equ *-4
	subq.l #1,d0
	bsr step_reset_history
	lea step_inputs(pc),a0
	move.w #STEP_INPUT_SLOTS-1,d0
.clear:
	clr.b (a0)+
	dbf d0,.clear
	lea step_start_frame(pc),a0
	clr.w (a0)
	movem.l (a7)+,d0-d7/a0-a6
	move.w #1,$a6f00
public_ref_24 equ *-4
	rts

; d0 is the initial simulation cursor; the queue follows the live field.
; Ready byte followed by hardware selection; cleared for every new race.
step_geometry_reuse_flag: dc.w 0
step_reset_history:
	lea step_geometry_reuse_flag(pc),a1
	clr.w (a1)
	move.l cpu_attention(pc),d1
	andi.w #$88,d1 ; AFF_68040 | AFF_68060; 020/030 rebuild normally
	sne 1(a1)
	IFNE STEP_FIELDS-1
	FAIL "Presentation heading prediction requires one-field simulation"
	ENDC
	lea step_pose_headings(pc),a1
	move.l d0,-(a7)
	moveq #4,d0
.poseclear:
	clr.w (a1)+
	dbf d0,.poseclear
	lea step_pose_render_start(pc),a1
	clr.l (a1)+
	clr.w (a1)
	move.l (a7)+,d0
	lea step_steering_fraction(pc),a1
	clr.l (a1)
	lea step_actor_road_fraction(pc),a1
	moveq #34,d1
.actorroadclear:
	clr.l (a1)+
	dbf d1,.actorroadclear
	lea step_road_fraction(pc),a1
	clr.l (a1)+
	clr.l (a1)+
	clr.l (a1)
	lea step_cursor(pc),a0
	move.l d0,(a0)
	lea step_queued_field(pc),a1
	move.l $a5d4c,(a1)
public_ref_26 equ *-4
	clr.b step_replaying-step_queued_field(a1)
	clr.b step_input_overflow-step_queued_field(a1)
	rts
; Consume every due step without discarding elapsed-time remainder.
step_main:
	btst #0,step_input_overflow(pc)
	bne step_input_failed
; Finish/countdown code can request exit inside a catch-up step. Publish that
; state and let the native outer loop leave the race; never run later ticks.
	tst.w $a59d0
public_ref_27 equ *-4
	bne .render
	lea step_cursor(pc),a0
	move.l (a0),d0
	add.l #STEP_FIELDS,d0
	cmp.l $a5d4c,d0
public_ref_28 equ *-4
	bhi .render
	bsr step_replay_inputs
	lea step_cursor(pc),a0
	move.l (a0),d0
	add.l #STEP_FIELDS,d0
	move.l d0,(a0)
	move.l d0,$a5d50
public_ref_29 equ *-4
	move.w #STEP_FIELDS,$a6f00
public_ref_30 equ *-4
	bsr step_clock
	move.w $a5d1e,d0
public_ref_31 equ *-4
	cmp.w $a5d38,d0
public_ref_32 equ *-4
	ble .highwater
	move.w d0,$a5d38
public_ref_33 equ *-4
.highwater:
	bsr step_collision_objects
	bsr .run
	bra step_main
.run:
	cmpi.w #$20,$a59da
public_ref_34 equ *-4
	jmp $87486
public_ref_35 equ *-4
.render:
	jmp $875bc
public_ref_36 equ *-4
; Run stateful presentation helpers exactly once per simulation step.
step_end:
	bsr step_predict_history
	jsr $89138
public_ref_37 equ *-4
	bsr step_track_events
	bsr step_actor_animations
	bsr step_spark_events
	nop
	nop
	bsr step_scenery_cursor
	bsr step_pose_events
	jsr $8f552
public_ref_38 equ *-4
	lea step_start_frame(pc),a0
	move.w d0,(a0)
	jsr $8eff8
public_ref_39 equ *-4
	bsr step_steering_finish
.done:
	rts
	cnop 0,4
step_cursor:
	dc.l 0

; Keep patch targets within the WHDLoad signed-word reach and
; the helper returns within PC-relative reach of the Fast RAM physics copy.
step_start_sprite:
	move.w step_start_frame(pc),d0
	move.w d0,8(a0)
	rts
step_start_frame:
	dc.w 0

; The original reference loses 1/4 of the crash-camera offset per four fields.
; One field retains (3/4)^(1/4): decay coefficient round(65536*(1-root))=4548.
; Actor displacement already includes delta; only the recovery decay needs this.
step_camera_decay:
	move.l $a7c02,d0
public_ref_44 equ *-4
	bsr step_decay
	move.l d0,$a7c02
public_ref_45 equ *-4
	jmp $891ae
public_ref_46 equ *-4

; Signed 32-bit offset in/out d0. Split the product to avoid overflow and retain
; 68000-compatible instructions.
step_decay:
	movem.l d1-d3,-(a7)
	moveq #STEP_FIELDS-1,d3
.field:
	move.l d0,d2
	move.l d0,d1
	swap d1
	muls.w #4548,d1
	mulu.w #4548,d0
	swap d0
	andi.l #$ffff,d0
	add.l d1,d0
	sub.l d0,d2
	move.l d2,d0
	dbf d3,.field
	movem.l (a7)+,d1-d3
	rts

; Field producer: use existing control/pause handling, but keep the physics
; steering and throttle state owned by the simulation consumer.
; Replace the whole native demo/player dispatch. A hook spanning $8710c..$87115
; is unsafe: the native demo branches land at $87110 inside that replacement.
step_field_input:
	tst.w $a7204
public_ref_47 equ *-4
	beq step_queue_input
	addq.w #1,$a7206
public_ref_48 equ *-4
	cmpi.w #3600,$a7206
public_ref_49 equ *-4
	bmi .poll
	move.w #1,$a59d2
public_ref_50 equ *-4
	move.w #1,$a59d0
public_ref_51 equ *-4
	bra .done
.poll:
	jsr $87276
public_ref_52 equ *-4
.done:
	tst.w $a59d2
public_ref_53 equ *-4
	rts

step_queue_input:
	movem.l d3-d6/a0-a1,-(a7)
	move.b $a598c,d6
public_ref_54 equ *-4
	move.w $a7262,d3
public_ref_55 equ *-4
	move.b $a5dc8,d4
public_ref_56 equ *-4
	lea step_replaying(pc),a0
	move.b (a0),d5
	clr.b (a0)
	jsr $87298
public_ref_57 equ *-4
	lea step_replaying(pc),a0
	move.b d5,(a0)
	move.w d3,$a7262
public_ref_58 equ *-4
	move.b d4,$a5dc8
public_ref_59 equ *-4
	btst #0,step_input_overflow(pc)
	bne .done
	move.l $a5d4c,d3
public_ref_60 equ *-4
	cmp.l step_queued_field(pc),d3
	beq .done
	move.l d3,d4
	sub.l step_cursor(pc),d4
	cmpi.l #STEP_INPUT_SLOTS,d4
	bcc .overflow
	andi.w #STEP_INPUT_SLOTS-1,d3
	lea step_inputs(pc),a0
	move.b $a598c,(a0,d3.w)
public_ref_61 equ *-6
	lea step_queued_field(pc),a0
	move.l $a5d4c,(a0)
public_ref_62 equ *-4
	bra .done
.overflow:
	lea step_input_overflow(pc),a0
	st.b (a0)
.done:
	move.b d6,$a598c
public_ref_63 equ *-4
	movem.l (a7)+,d3-d6/a0-a1
	tst.w $a59d2
public_ref_64 equ *-4
	rts

step_replay_inputs:
; Check again here: the field interrupt can latch failure after step_main's
; check. An overrun never overwrites buffered history, so an interrupt during
; this replay cannot corrupt a sample already being consumed.
	btst #0,step_input_overflow(pc)
	bne step_input_failed
; The demo drives its player through AI. Do not replay an unproduced human queue.
	tst.w $a7204
public_ref_65 equ *-4
	bne .done
	move.l step_cursor(pc),d3
	moveq #STEP_FIELDS-1,d4
	lea step_replaying(pc),a0
	st.b (a0)
.next:
	addq.l #1,d3
	move.w d3,d0
	andi.w #STEP_INPUT_SLOTS-1,d0
	lea step_inputs(pc),a0
	move.b (a0,d0.w),d0
	move.b d0,$a598c
public_ref_66 equ *-4
	tst.b d0
	beq .idle
	jsr $872c0
public_ref_67 equ *-4
	bra .applied
.idle:
	jsr $8744c
public_ref_68 equ *-4
.applied:
	dbf d4,.next
	lea step_replaying(pc),a0
	clr.b (a0)
.done:
	rts

; Abort from the main task, never from the input interrupt. Continuing after
; missing input would silently change gameplay; do not reset the simulation
; clock or replay stale ring contents to conceal the missing history.
step_input_failed:
	pea step_input_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a0
	jmp resload_Abort(a0)
step_input_error:
	dc.b "Enhanced framerate: input history exhausted.",10
	dc.b "The simulation could not keep up. Restart with",10
	dc.b "Enhanced framerate disabled.",0
	even

step_input_key:
	btst #0,step_replaying(pc)
	bne .replayed
	cmpi.b #$40,$ae969
public_ref_69 equ *-4
	jmp $873fc
public_ref_70 equ *-4
.replayed:
	rts

	cnop 0,4
step_queued_field:
	dc.l 0
step_replaying:
	dc.b 0
step_input_overflow:
	dc.b 0
step_inputs:
	ds.b STEP_INPUT_SLOTS

; Cached crash poses let drawing reuse animation without advancing recovery.
step_actor_animations:
	lea $909cc,a2
public_ref_71 equ *-4
.next:
	move.l (a2)+,a1
	cmpa.l #-1,a1
	beq .done
	btst #4,$68(a1)
	beq .flash
	cmpa.l #$a5de0,a1
public_ref_72 equ *-4
	beq .clear_crash
	tst.b $6e(a1)
	bmi .clear_crash
	jsr $8f190
public_ref_73 equ *-4
	move.l a1,d1
	sub.l #$a5d60,d1
public_ref_74 equ *-4
	lsr.w #6,d1
	lea step_crash_frames(pc),a0
	move.w d0,(a0,d1.w)
	tst.b $6e(a1)
	bpl .next
.clear_crash:
	bclr #4,$68(a1)
	bra .next
.flash:
	tst.w $12(a1)
	beq .next
	move.b $6a(a1),d0
	btst #2,d0
	beq .next
	andi.b #3,d0
	cmpi.b #2,d0
	bcc .next
	subi.b #STEP_FIELDS,$70(a1)
	bgt .next
	clr.b $70(a1)
	bclr #2,$6a(a1)
	bra .next
.done:
	rts
step_crash_sprite:
	movem.l d1/a0,-(a7)
	move.l a1,d1
	sub.l #$a5d60,d1
public_ref_75 equ *-4
	lsr.w #6,d1
	lea step_crash_frames(pc),a0
	move.w (a0,d1.w),d0
	movem.l (a7)+,d1/a0
	tst.b $6e(a1)
	rts
	even
step_crash_frames:
	ds.w 35

; Physics reads actor +$34, so rendering must not overwrite this derived state.
step_derive_lean:
	move.w $a6ef6,-(a7)
public_ref_76 equ *-4
	clr.w $a6ef6
public_ref_77 equ *-4
	lea step_lean_busy(pc),a0
	st.b (a0)
	lea $909cc,a2
public_ref_78 equ *-4
.next:
	move.l (a2)+,a1
	cmpa.l #-1,a1
	bne .actor
	tst.w $a6ef6
public_ref_79 equ *-4
	bne .special
	move.w #1,$a6ef6
public_ref_80 equ *-4
	lea $941d6,a2
public_ref_81 equ *-4
	bra .next
.special:
	cmpi.w #2,$a6ef6
public_ref_82 equ *-4
	beq .done
	cmpi.l #1800,$a5d50
public_ref_83 equ *-4
	bcs .done
	move.w #2,$a6ef6
public_ref_84 equ *-4
	lea $941e2,a2
public_ref_85 equ *-4
	bra .next
.actor:
; Match the native $89d64..$89de4 list eligibility checks.
	cmpi.w #1,$a6ef6
public_ref_86 equ *-4
	bne .checkspecial
	cmpi.w #-1,$56(a1)
	bne .next
	bra .position
.checkspecial:
	cmpi.w #2,$a6ef6
public_ref_87 equ *-4
	bne .position
	btst #6,$68(a1)
	beq .done
	move.l 4(a1),d0
	sub.l $a5d1e,d0
public_ref_88 equ *-4
	bmi .done
.position:
	move.w 4(a1),d0
	sub.w $a5d1e,d0
public_ref_89 equ *-4
	bmi .next
	cmpi.w #30,d0
	bgt .next
	move.l 4(a1),d2
	bsr step_compute_lean
	bra .next
.done:
	lea step_lean_busy(pc),a0
	clr.b (a0)
	move.w (a7)+,$a6ef6
public_ref_90 equ *-4
	rts
; The simulation owns actor +$34. Pose selection reads that stored lean, so
; neither the per-tick pose pass nor a render needs to derive it again.
; Enter past the presentation hook only for the authoritative lean pass.
step_compute_lean:
	sub.l $a5d1e,d2
public_ref_93 equ *-4
	jmp $89e76
public_ref_94 equ *-4
step_pose_lean:
	jmp $89ef0
public_ref_95 equ *-4
step_lean_end:
	btst #0,step_lean_busy(pc)
	bne .computed
	move.w d0,$a(a0)
	tst.w $a6ef6
public_ref_96 equ *-4
	jmp $89efa
public_ref_97 equ *-4
.computed:
	move.w d2,$34(a1)
	rts
step_lean_busy:
	dc.b 0
	even

step_scenery_cursor:
	move.l $a5d1e,d0
public_ref_98 equ *-4
	move.l $a808e,a1
public_ref_99 equ *-4
.back:
	cmpa.l #$a8096,a1
public_ref_100 equ *-4
	beq .forward
	move.l -4(a1),d1
	clr.w d1
	cmp.l d0,d1
	bcs .forward
	subq.l #4,a1
	bra .back
.forward:
	move.l (a1),d1
	cmpi.l #-1,d1
	beq .done
	clr.w d1
	cmp.l d0,d1
	bcc .done
	addq.l #4,a1
	bra .forward
.done:
	move.l a1,$a808e
public_ref_101 equ *-4
	rts

; Rebuild the world-object collision inputs for every step. The original
; collision code reads these projection records, not just world positions.

; The selected C slave hunk is already verified to be in Fast RAM. All relative
; branches in $8b02e..$8b37d remain inside this block; data addresses are absolute.
; Copy after applying patches so optional width changes are preserved as well.
; Restore the eight-byte entry instruction overwritten by the entry JMP.
; Called once per main-game load, before any native game code resumes.
step_object_fast_init:
	lea step_object_fast_code(pc),a0
	move.l #$33fcffff,(a0)+
	move.l #$000a59e4,(a0)+
public_ref_102 equ *-4
	lea $8b036,a1
public_ref_103 equ *-4
	move.w #($8b37e-$8b036)/4-1,d0
.copy:
	move.l (a1)+,(a0)+
	dbf d0,.copy
	move.l _resload(pc),a2
	jsr (resload_FlushCache,a2)
	rts
	cnop 0,4
step_object_fast_code:
	ds.b $8b37e-$8b02e

	INCLUDE "collision_geometry.s"

step_collision_objects:
	bsr step_geometry_reuse
	clr.w $a8734
public_ref_106 equ *-4
	clr.w $a59fc
public_ref_107 equ *-4
	jsr $8b02e
public_ref_108 equ *-4
	move.w $a8734,$a59fe
public_ref_109 equ *-8
public_ref_110 equ *-4
	jsr $8a492
public_ref_111 equ *-4
	rts

; The live field clock schedules work; the race stopwatch belongs to simulation.
; Preserve the original game's 60-field BCD second, including its finish flag.
step_clock:
	btst #7,$a5dc8
public_ref_112 equ *-4
	bne .done
	moveq #STEP_FIELDS-1,d3
.next:
	addq.w #1,$a5d58
public_ref_113 equ *-4
	cmpi.w #60,$a5d58
public_ref_114 equ *-4
	blt .counted
	clr.w $a5d58
public_ref_115 equ *-4
	move.b $a5d5b,d1
public_ref_116 equ *-4
	moveq #1,d0
	abcd d0,d1
	move.b d1,$a5d5b
public_ref_117 equ *-4
	cmpi.b #$60,d1
	blt .counted
	clr.b $a5d5b
public_ref_118 equ *-4
	move.b $a5d5a,d1
public_ref_119 equ *-4
	abcd d0,d1
	move.b d1,$a5d5a
public_ref_120 equ *-4
	cmpi.b #$60,d1
	blt .counted
	clr.b $a5d5a
public_ref_121 equ *-4
.counted:
	dbf d3,.next
.done:
	rts

; The outer render loop used to notice track-section crossings. Catch-up must
; process each crossing even when no frame is drawn between simulation steps.
step_track_events:
	move.w $a5d38,d1
public_ref_122 equ *-4
	move.w $a5d1e,d0
public_ref_123 equ *-4
	cmp.w d1,d0
	ble .done
	andi.w #$ff,d1
	lsr.w #6,d1
	andi.w #$ff,d0
	lsr.w #6,d0
	cmp.w d1,d0
	beq .done
	jsr $9080c
public_ref_124 equ *-4
.done:
	rts

; Rider spark lifetime is simulation-owned; drawing consults a cached effect.
step_spark_events:
	lea $a5d60,a1
public_ref_125 equ *-4
	lea step_sparks(pc),a0
	moveq #35-1,d0
.next:
	clr.b (a0)
	btst #7,$6a(a1)
	beq .advance
	tst.b $6e(a1)
	bne .advance
	tst.b $6f(a1)
	bne .advance
	st.b (a0)
	bclr #7,$6a(a1)
.advance:
	addq.l #1,a0
	lea $80(a1),a1
	dbf d0,.next
	rts
step_spark_test:
	movem.l d0/a0,-(a7)
	move.l a1,d0
	sub.l #$a5d60,d0
public_ref_126 equ *-4
	lsr.w #7,d0
	lea step_sparks(pc),a0
	btst #0,(a0,d0.w)
	movem.l (a7)+,d0/a0
	rts
step_sparks:
	ds.b 35
	even

; Pose selection contains attack-state transitions and the sound-event gate at
; $a5991. Run it at the simulation boundary, including invisible catch-up steps.
step_pose_events:
	move.l step_cursor(pc),d0
	lsr.l #2,d0
	move.b d0,$a598d
public_ref_127 equ *-4
	move.b d0,$a5990
public_ref_128 equ *-4
	clr.w $a8734
public_ref_129 equ *-4
	lea step_pose_busy(pc),a0
	st.b (a0)
	jsr $89d20
public_ref_130 equ *-4
	lea step_pose_busy(pc),a0
	clr.b (a0)
	rts
step_pose_clear:
	btst #0,step_pose_busy(pc)
	beq .done
	bclr #4,$68(a1)
.done:
	rts
; Pose selection above $89f48 owns attack transitions and sound gates.
; Everything after it emits projection/effect records. The next simulation
; tick rebuilds collision records independently; only a render needs these.
step_pose_project:
	btst #0,step_pose_busy(pc)
	bne .next
	move.l 4(a1),d0
	sub.l $a5d1e,d0
public_ref_131 equ *-4
	jmp $89f52
public_ref_132 equ *-4
.next:
	jmp $89d5e
public_ref_133 equ *-4
step_pose_busy:
	dc.b 0
	even

; Estimate presentation heading from the latest authoritative increment.
; Integer heading can repeat during a continuing turn: on those ticks use
; the four-tick average. History stores four times the estimated rate so the
; prediction multiply below retains its existing quarter-unit scaling.
; Use the measured render interval for heading prediction.
; Never write prediction to an actor or use it in the simulation pose pass.
step_predict_history:
	movem.l d0-d2/a0,-(a7)
	move.l step_cursor(pc),d0
	andi.w #3,d0
	add.w d0,d0
	lea step_pose_headings(pc),a0
	move.w $a5d6c,d1
public_ref_134 equ *-4
	move.w d1,d2
	subq.w #2,d0
	andi.w #6,d0
	sub.w (a0,d0.w),d2
	addq.w #2,d0
	andi.w #6,d0
	tst.w d2
	beq .average
	lsl.w #2,d2
	bra .store
.average:
	move.w d1,d2
	sub.w (a0,d0.w),d2
.store:
	move.w d1,(a0,d0.w)
	move.w d2,8(a0)
	movem.l (a7)+,d0-d2/a0
	rts
step_predict_pose:
	move.w $c(a1),d1
	cmpa.l #$a5d60,a1
public_ref_135 equ *-4
	bne .done
	btst #0,step_pose_busy(pc)
	bne .done
	movem.l d0/d2,-(a7)
	move.w step_pose_headings+8(pc),d2
	move.b $a598c,d0
public_ref_136 equ *-4
	andi.b #12,d0
	tst.w d2
	beq .restore
	bmi .left
	cmpi.b #8,d0
	bne .restore
	tst.w d1
	bmi .restore
	bra .predict
.left:
	cmpi.b #4,d0
	bne .restore
; The native mirror bit was already chosen from the authoritative heading.
; At zero it uses the positive orientation; do not predict across that sign.
	tst.w d1
	bge .restore
.predict:
	muls.w step_pose_render_fields(pc),d2
	asr.l #2,d2
	add.w d2,d1
.restore:
	movem.l (a7)+,d0/d2
.done:
	cmpa.l #$a5d60,a1
public_ref_137 equ *-4
	rts
step_pose_headings:
	ds.w 5
; Observe drawing plus the native vsync handoff. Start conservatively at zero
; after each reset and bound extrapolation to four fields even after a stall.
; These hooks neither delay presentation nor alter its original handshake.
step_predict_render_begin:
	move.l a0,-(a7)
	lea step_geometry_reuse_flag(pc),a0
	move.b 1(a0),(a0)
	lea step_pose_render_start(pc),a0
	move.l $a5d4c,(a0)
public_ref_138 equ *-4
	move.l (a7)+,a0
	jmp $8970e
public_ref_139 equ *-4
step_predict_render_end:
	movem.l d0/a0,-(a7)
	move.l $a5d4c,d0
public_ref_140 equ *-4
	sub.l step_pose_render_start(pc),d0
	cmpi.l #4,d0
	bls .store
	moveq #4,d0
.store:
	lea step_pose_render_fields(pc),a0
	move.w d0,(a0)
	movem.l (a7)+,d0/a0
	jmp $b2b2c
public_ref_141 equ *-4
step_pose_render_start:
	dc.l 0
step_pose_render_fields:
	dc.w 0

	include steering.s

	include runtime_stack.s

	include physics_fast.s

	include physics_aux.s

; Keep these helpers within PC-relative reach of their callers.
	include lean_pose.s

; Consume render geometry once, before the next movement update.
; Additional catch-up ticks rebuild it normally; no tick or input is skipped.
step_geometry_reuse:
 lea step_geometry_reuse(pc),a0
 suba.l #step_geometry_reuse-step_geometry_reuse_flag,a0
 tst.b (a0)
 beq .build
 clr.b (a0)
 rts
.build:
 jmp step_collision_geometry_code(pc)

	include bus_priority.s
	include reference_motion.s
