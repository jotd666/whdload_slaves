; Test Drive VERIFY instruments. No code or data from this file in normal builds.
; All game addresses below are hunk offsets or a4-relative, never TD2 offsets.
; The counter/first-failure assertion protocol follows TD2 simulation-verify.s.
verify_init:
    lea verify_tags(pc),a0
    move.l _resload(pc),a2
    jsr resload_Control(a2)
    move.l d7,a0
    adda.l a0,a0
    adda.l a0,a0
    move.l (a0),d0                 ; next hunk BPTR
    lsl.l #2,d0
    addq.l #4,d0
    lea verify_data(pc),a0
    move.l d0,(a0)
    bsr verify_units
    ; Same-period cross-CPU oracle: VERIFY C1 bit 2 forces five fields.
    ; This selects a real simulation period; it never edits state from the host.
    move.l verify_c1(pc),d0
    btst #2,d0
    beq.b .configured
    lea sim_p(pc),a0
    move.w #5,(a0)
.configured
    rts

; Called after the original overlay-load register restore. Patch only a freshly
; loaded h4, identified by its export and original entry signature. Patch ends
; before the final flush/return to the rewritten export; repeated calls are safe.
verify_overlay_loaded:
    movem.l d0-a6,-(sp)
    move.l verify_c1(pc),d0
    and.l #2,d0
    or.l verify_c3(pc),d0
    or.l verify_c4(pc),d0
    or.l verify_c5(pc),d0
    beq .done
    move.l verify_data(pc),a0
    cmp.w #$4ef9,668(a0)
    bne .done
    move.l 670(a0),a1
    cmp.l #$4e55ffcc,(a1)
    bne .done
    cmp.w #$396c,4(a1)
    bne .done
    lea verify_h4(pc),a0
    move.l a1,(a0)
    lea verify_overlay_patches(pc),a0
    move.l _resload(pc),a2
    jsr resload_Patch(a2)
.done
    movem.l (sp)+,d0-a6
    rts

verify_overlay_patches:
    PL_START
    ; VERIFY_RANGE h4 00004 6 always verify_race_entry
    PL_PS $00004,verify_race_entry
    ; VERIFY_RANGE h4 000f6 6 always verify_race_anchor
    PL_PS $000f6,verify_race_anchor
    ; VERIFY_RANGE h4 003d4 8 always verify_race_exit
    PL_PSS $003d4,verify_race_exit,2
    PL_IFC3
    ; VERIFY_RANGE h4 01294 8 C3 verify_traffic_rng
    PL_PSS $01294,verify_traffic_rng,2
    ; VERIFY_RANGE h4 0130c 8 C3 verify_radar_rng
    PL_PSS $0130c,verify_radar_rng,2
    PL_IFC2
    PL_ELSE
    ; VERIFY_RANGE h4 01eee 8 C3!C2 verify_visual_1023
    PL_PSS $01eee,verify_visual_1023,2
    ; VERIFY_RANGE h4 01f00 8 C3!C2 verify_visual_255
    PL_PSS $01f00,verify_visual_255,2
    ; VERIFY_RANGE h4 01f10 8 C3!C2 verify_visual_127
    PL_PSS $01f10,verify_visual_127,2
    ; VERIFY_RANGE h4 01f76 8 C3!C2 verify_visual_3
    PL_PSS $01f76,verify_visual_3,2
    PL_ENDIF
    PL_ENDIF
    PL_IFC5
    ; VERIFY_RANGE h4 000fc 6 C5 verify_events
    PL_PS $000fc,verify_events
    PL_ENDIF
    PL_IFC1X 1
    ; VERIFY_RANGE h4 002ea 6 C1.1 verify_recovery
    PL_PS $002ea,verify_recovery
    PL_ENDIF
    PL_END

verify_race_entry:
    movem.l d0/a0,-(sp)
    lea verify_active(pc),a0
    clr.l (a0)
    lea verify_fired(pc),a0
    clr.l (a0)
    lea verify_recovery_started(pc),a0
    clr.l (a0)
    move.l verify_c5(pc),d0
    btst #0,d0
    beq.b .original
    clr.w -22504(a4)             ; deterministic fixture uses real player physics
.original
    movem.l (sp)+,d0/a0
    move.w -22504(a4),-29324(a4)
    rts
verify_race_anchor:
    movem.l d0/a0,-(sp)
    tst.w -22504(a4)
    bne .done
    lea verify_active(pc),a0
    tst.l (a0)
    bne .done                   ; crash recovery must not restart the tape
    move.l #1,(a0)
    lea verify_epoch(pc),a0
    move.l -31782(a4),(a0)
    lea verify_rng_count(pc),a0
    clr.l (a0)
    lea verify_visual_seed(pc),a0
    move.w #$1234,(a0)
    move.l verify_c3(pc),d0
    beq.b .done
    move.w #$1234,-25640(a4)
    move.w #-1,-25638(a4)
.done
    movem.l (sp)+,d0/a0
    move.l -31782(a4),-12(a5)
    rts
verify_race_exit:
    move.l a0,-(sp)
    lea verify_active(pc),a0
    clr.l (a0)
    move.l (sp)+,a0
    cmp.l #550,-36(a5)
    rts

; d0 is the full signed-word LCG result, matching the original beam-free RNG.
; The private visual seed never touches game state or the gameplay draw log.
verify_visual_rng:
    move.l a0,-(sp)
    lea verify_visual_seed(pc),a0
    move.w (a0),d0
    muls.w #6907,d0
    add.l #130253,d0
    move.w d0,(a0)
    movem.l (sp)+,a0
    rts
verify_visual_1023:
    bsr verify_visual_rng
    and.w #1023,d0
    rts
verify_visual_255:
    bsr verify_visual_rng
    and.w #255,d0
    rts
verify_visual_127:
    bsr verify_visual_rng
    and.w #127,d0
    rts
verify_visual_3:
    bsr verify_visual_rng
    and.w #3,d0
    rts
verify_traffic_rng:
    jsr -32442(a4)
    movem.l d1/a0,-(sp)
    moveq #1,d1
    bsr verify_log_rng
    movem.l (sp)+,d1/a0
    and.b #$c0,d0
    rts
verify_radar_rng:
    jsr -32442(a4)
    movem.l d1/a0,-(sp)
    moveq #2,d1
    bsr verify_log_rng
    movem.l (sp)+,d1/a0
    and.b #$c0,d0
    rts
verify_log_rng:
    lea verify_rng_count(pc),a0
    cmp.l #256,(a0)
    bcc.b .full
    move.l d2,-(sp)
    move.l (a0),d2
    lsl.w #2,d2
    lea verify_rng_log(pc),a0
    adda.w d2,a0
    move.w d1,(a0)+
    move.w d0,(a0)
    move.l (sp)+,d2
    lea verify_rng_count(pc),a0
.full
    addq.l #1,(a0)              ; overflow is visible, never wrap evidence silently
.done
    rts

; C4 delays view publication by ten WaitTOFs; only the calling drawing task
; waits. Interrupts and the higher-priority CLI simulation continue to run.
verify_slow_view:
    movem.l d0-d1/a0-a1/a6,-(sp)
    move.l verify_active(pc),d0
    beq.b .done
    moveq #9,d1
.wait
    move.l d1,-(sp)
    move.l -31786(a4),a6
    jsr -270(a6)               ; graphics.WaitTOF
    move.l (sp)+,d1
    dbf d1,.wait
.done
    movem.l (sp)+,d0-d1/a0-a1/a6
    move.l 8(sp),a1            ; displaced wrapper's argument, plus patch JSR
    move.l -31786(a4),a6
    rts                        ; root continuation JMP graphics.LoadView

; Pure tape decoder: d0 elapsed fields, d1 C5 bits -> d0 JOYDAT, d1 fire (0/1).
; Boundary-based lookup does not consume entries, so two input polls agree.
verify_tape:
    move.l a0,-(sp)
    lea verify_tape_straight(pc),a0
    btst #4,d1
    bne.b .find
    lea verify_tape_route(pc),a0
.find
    cmp.l (a0),d0
    bcs.b .found
    addq.l #8,a0
    bra.b .find
.found
    move.w 6(a0),d1
    move.w 4(a0),d0
    movem.l (sp)+,a0
    rts
verify_tape_straight:
    dc.l 30
    dc.w $100,1                ; engage first gear
    dc.l 150
    dc.w $100,0
    dc.l 180
    dc.w $100,1                ; second gear
    dc.l 300
    dc.w $100,0
    dc.l 330
    dc.w $100,1                ; third gear
    dc.l 600
    dc.w $100,0
    dc.l 900
    dc.w 1,0                   ; brake
    dc.l 1200
    dc.w 0,0                   ; coast
    dc.l $ffffffff
    dc.w 0,0
verify_tape_route:
    dc.l 30
    dc.w $100,1
    dc.l 150
    dc.w $100,0
    dc.l 180
    dc.w $100,1
    dc.l 300
    dc.w $100,0
    dc.l 330
    dc.w $100,1
    dc.l 400
    dc.w $100,0
    dc.l 420
    dc.w $103,0                ; throttle + right
    dc.l 440
    dc.w $200,0                ; throttle + left
    dc.l 600
    dc.w $100,0
    dc.l 900
    dc.w 1,0
    dc.l $ffffffff
    dc.w 0,0
verify_input:
    move.l verify_c5(pc),d1
    btst #0,d1
    beq.b .inactive
    move.l verify_active(pc),d0
    beq.b .inactive
    move.l -31782(a4),d0
    sub.l verify_epoch(pc),d0
    bsr verify_tape
    rts
.inactive
    moveq #-1,d1
    rts
verify_joy:
    movem.l d0-d1,-(sp)
    bsr verify_input
    tst.w d1
    bmi.b .original
    move.w d0,2(sp)             ; replace low word only, preserve original high word
.original
    movem.l (sp)+,d0-d1
    rts
verify_fire:
    movem.l d0-d1,-(sp)
    bsr verify_input
    tst.w d1
    bmi.b .original
    bset #7,3(sp)
    tst.w d1
    beq.b .original
    bclr #7,3(sp)
.original
    movem.l (sp)+,d0-d1
    rts

; Threshold crossing plus a one-shot bit, not exact equality to a VBL count.
verify_events:
    movem.l d0-d1/a0,-(sp)
    move.l verify_active(pc),d0
    beq .done
    move.l -31782(a4),d0
    sub.l verify_epoch(pc),d0
    move.l verify_c5(pc),d1
    lea verify_fired(pc),a0
    btst #1,d1
    beq.b .radar
    cmp.l #450,d0
    bcs.b .radar
    bset #0,3(a0)
    bne.b .radar
    move.w #1,-22480(a4)       ; original nonfatal crash path, penalty and animation
.radar
    btst #2,d1
    beq.b .done
    cmp.l #900,d0
    bcs.b .done
    bset #1,3(a0)
    bne.b .done
    move.l -22352(a4),d0
    add.l #15*65536,d0
    move.l d0,-29564(a4)       ; police slot, ahead of player
    move.l -22344(a4),-29528(a4)
    move.l sim_enabled(pc),d0
    beq.b .fixture_speed
    move.l -22360(a4),d0
    lsr.l #6,d0
    move.l d0,-29528(a4)
.fixture_speed
    move.w #70,-29320(a4)
    move.w #1,-29318(a4)
    clr.w -29322(a4)
    move.w #1,-29248(a4)
.done
    movem.l (sp)+,d0-d1/a0
    cmp.w #70,-29320(a4)
    rts
verify_recovery:
    movem.l d1/a0,-(sp)
    lea verify_recovery_started(pc),a0
    tst.l (a0)
    bne.b .elapsed
    move.l -31782(a4),(a0)
.elapsed
    move.l -31782(a4),d1
    sub.l (a0),d1
    cmp.l #100,d1
    bcs.b .original
    clr.l (a0)
    movem.l (sp)+,d1/a0
    moveq #1,d0
    tst.w d0
    rts
.original
    movem.l (sp)+,d1/a0
    jsr -32430(a4)
; Also clear a pending timer on an early manual acknowledgement. Otherwise a
; later crash could inherit the preceding crash's elapsed wait.
verify_recovery_input_result:
    tst.w d0
    beq.b .done
    move.l a0,-(sp)
    lea verify_recovery_started(pc),a0
    clr.l (a0)
    move.l (sp)+,a0
.done
    tst.w d0
    rts

; Assertions exercise the actual tape decoder and visual LCG before PatchSeg.
; More arithmetic vectors are added with phase 8, when those routines exist.
verify_units:
    movem.l d0-a6,-(sp)
    lea verify_unit_results(pc),a0
    clr.l (a0)+
    clr.l (a0)+
    clr.l (a0)
    lea verify_vectors(pc),a2
    moveq #7,d7
.next
    move.l (a2)+,d0
    moveq #17,d1
    bsr verify_tape
    move.w d1,d2
    and.l #$ffff,d0
    move.l (a2)+,d1
    bsr verify_equal
    moveq #0,d0
    move.w d2,d0
    move.l (a2)+,d1
    bsr verify_equal
    dbf d7,.next
    lea verify_visual_seed(pc),a0
    move.w #$1234,(a0)
    bsr verify_visual_rng
    move.l #32316873,d1
    bsr verify_equal
    lea verify_visual_seed(pc),a0
    move.w #$ffff,(a0)
    bsr verify_visual_rng
    move.l #123346,d1
    bsr verify_equal
    lea verify_visual_seed(pc),a0
    move.w #$1234,(a0)
    lea verify_recovery_started(pc),a0
    move.l #1234,(a0)
    moveq #0,d0
    bsr verify_recovery_input_result
    moveq #0,d1
    bsr verify_equal
    move.l (a0),d0
    move.l #1234,d1
    bsr verify_equal
    moveq #1,d0
    bsr verify_recovery_input_result
    moveq #1,d1
    bsr verify_equal
    move.l (a0),d0
    moveq #0,d1
    bsr verify_equal
    bsr verify_math_units
    movem.l (sp)+,d0-a6
    rts
verify_equal:
    move.l a0,-(sp)
    lea verify_unit_results(pc),a0
    addq.l #1,4(a0)
    cmp.l d1,d0
    beq.b .equal
    addq.l #1,(a0)
    tst.l 8(a0)
    bne.b .equal
    move.l 4(a0),8(a0)
.equal
    move.l (sp)+,a0
    rts
verify_vectors:
    dc.l 0,$100,1,29,$100,1,30,$100,0,149,$100,0
    dc.l 150,$100,1,600,1,0,900,0,0,1200,0,0
    dc.b 'TDVERIFY7',0
    even
verify_unit_results:
    dc.l 0,0,0
verify_data: dc.l 0
verify_h4: dc.l 0
verify_active: dc.l 0
verify_epoch: dc.l 0
verify_fired: dc.l 0
verify_recovery_started: dc.l 0
verify_rng_count: dc.l 0
verify_visual_seed: dc.w $1234
verify_rng_log: ds.l 256,0
verify_tags:
    dc.l WHDLTAG_CUSTOM1_GET
verify_c1: dc.l 0
    dc.l WHDLTAG_CUSTOM3_GET
verify_c3: dc.l 0
    dc.l WHDLTAG_CUSTOM4_GET
verify_c4: dc.l 0
    dc.l WHDLTAG_CUSTOM5_GET
verify_c5: dc.l 0
    dc.l 0

; BEGIN PHASE8 MATH
; Independent exact-integer vectors: tools/phase8_math.py in the local harness.
verify_math_units:
    movem.l d0-a6,-(sp)
    lea sim_p(pc),a1
    move.w (a1),-(sp)
    lea verify_vectors_sim_scale_long(pc),a2
    lea sim_scale_long(pc),a3
    move.w #85,d7
    bsr verify_math_group
    lea verify_vectors_sim_ratio(pc),a2
    lea sim_ratio(pc),a3
    move.w #5,d7
    bsr verify_math_group
    lea verify_vectors_sim_clock_delta(pc),a2
    lea sim_clock_delta(pc),a3
    move.w #23,d7
    bsr verify_math_group
    lea verify_vectors_sim_distance(pc),a2
    lea sim_distance(pc),a3
    move.w #35,d7
    bsr verify_math_group
    lea verify_vectors_sim_relax_word(pc),a2
    lea sim_relax_word(pc),a3
    move.w #17,d7
    bsr verify_math_group
    lea verify_vectors_sim_cadence(pc),a2
    lea sim_cadence(pc),a3
    move.w #9,d7
    bsr verify_math_group
    lea verify_vectors_verify_width_case(pc),a2
    lea verify_width_case(pc),a3
    move.w #7,d7
    bsr verify_math_group
    lea verify_vectors_sim_traffic_delta(pc),a2
    lea sim_traffic_delta(pc),a3
    move.w #27,d7
    bsr verify_math_group
    lea verify_vectors_sim_reference_velocity(pc),a2
    lea sim_reference_velocity(pc),a3
    move.w #69,d7
    bsr verify_math_group
    lea verify_vectors_sim_lcg(pc),a2
    lea sim_lcg(pc),a3
    move.w #5,d7
    bsr verify_math_group
    lea verify_vectors_verify_visual_samples_case(pc),a2
    lea verify_visual_samples_case(pc),a3
    move.w #4,d7
    bsr verify_math_group
    lea verify_vectors_sim_coarse_rate(pc),a2
    lea sim_coarse_rate(pc),a3
    move.w #25,d7
    bsr verify_math_group
    lea sim_p(pc),a1
    move.w (sp)+,(a1)
    movem.l (sp)+,d0-a6
    rts
verify_math_group:
.next:
    move.l (a2)+,d0
    move.l (a2)+,d1
    move.l (a2)+,d2
    move.l (a2)+,d3
    lea verify_math_carry(pc),a0
    move.w d3,(a0)
    move.l (a2)+,d3
    lea sim_p(pc),a1
    move.w d3,(a1)
    jsr (a3)
    move.l (a2)+,d1
    bsr verify_equal
    move.w (a0),d0
    ext.l d0
    move.l (a2)+,d1
    bsr verify_equal
    dbf d7,.next
    rts
verify_math_carry: dc.w 0
verify_width_case:
    bsr sim_width_decode
    move.w d1,(a0)
    rts
verify_visual_samples_case:
    lea sim_visual_seed(pc),a1
    move.w d0,(a1)
    bsr sim_visual_samples
    move.w (a1),(a0)
    move.l sim_visual_values(pc),d0
    rts
verify_vectors_sim_scale_long:
    dc.l -2147483648,0,0,-4,2,-858993460,0
    dc.l -2147483648,0,0,0,2,-858993459,-1
    dc.l -2147483648,0,0,4,2,-858993458,-2
    dc.l -270336,0,0,-4,2,-108135,-1
    dc.l -270336,0,0,0,2,-108134,-2
    dc.l -270336,0,0,4,2,-108133,-3
    dc.l -65537,0,0,-4,2,-26215,-3
    dc.l -65537,0,0,0,2,-26214,-4
    dc.l -65537,0,0,4,2,-26214,0
    dc.l -6,0,0,-4,2,-3,-1
    dc.l -6,0,0,0,2,-2,-2
    dc.l -6,0,0,4,2,-1,-3
    dc.l -5,0,0,-4,2,-2,-4
    dc.l -5,0,0,0,2,-2,0
    dc.l -5,0,0,4,2,-1,-1
    dc.l -4,0,0,-4,2,-2,-2
    dc.l -4,0,0,0,2,-1,-3
    dc.l -4,0,0,4,2,0,-4
    dc.l -1,0,0,-4,2,-1,-1
    dc.l -1,0,0,0,2,0,-2
    dc.l -1,0,0,4,2,0,2
    dc.l 0,0,0,-4,2,0,-4
    dc.l 0,0,0,0,2,0,0
    dc.l 0,0,0,4,2,0,4
    dc.l 1,0,0,-4,2,0,-2
    dc.l 1,0,0,0,2,0,2
    dc.l 1,0,0,4,2,1,1
    dc.l 4,0,0,-4,2,0,4
    dc.l 4,0,0,0,2,1,3
    dc.l 4,0,0,4,2,2,2
    dc.l 5,0,0,-4,2,1,1
    dc.l 5,0,0,0,2,2,0
    dc.l 5,0,0,4,2,2,4
    dc.l 6,0,0,-4,2,1,3
    dc.l 6,0,0,0,2,2,2
    dc.l 6,0,0,4,2,3,1
    dc.l 65537,0,0,-4,2,26214,0
    dc.l 65537,0,0,0,2,26214,4
    dc.l 65537,0,0,4,2,26215,3
    dc.l 270336,0,0,-4,2,108133,3
    dc.l 270336,0,0,0,2,108134,2
    dc.l 270336,0,0,4,2,108135,1
    dc.l 2147483647,0,0,-4,2,858993458,0
    dc.l 2147483647,0,0,0,2,858993458,4
    dc.l 2147483647,0,0,4,2,858993459,3
    dc.l -2147483648,0,0,0,5,-2147483648,0
    dc.l -270336,0,0,0,5,-270336,0
    dc.l -65537,0,0,0,5,-65537,0
    dc.l -6,0,0,0,5,-6,0
    dc.l -5,0,0,0,5,-5,0
    dc.l -4,0,0,0,5,-4,0
    dc.l -1,0,0,0,5,-1,0
    dc.l 0,0,0,0,5,0,0
    dc.l 1,0,0,0,5,1,0
    dc.l 4,0,0,0,5,4,0
    dc.l 5,0,0,0,5,5,0
    dc.l 6,0,0,0,5,6,0
    dc.l 65537,0,0,0,5,65537,0
    dc.l 270336,0,0,0,5,270336,0
    dc.l 2147483647,0,0,0,5,2147483647,0
    dc.l 1,0,0,0,2,0,2
    dc.l 1,0,0,2,2,0,4
    dc.l 1,0,0,4,2,1,1
    dc.l 1,0,0,1,2,0,3
    dc.l 1,0,0,3,2,1,0
    dc.l -1,0,0,0,2,0,-2
    dc.l -1,0,0,-2,2,0,-4
    dc.l -1,0,0,-4,2,-1,-1
    dc.l -1,0,0,-1,2,0,-3
    dc.l -1,0,0,-3,2,-1,0
    dc.l 270336,0,0,0,2,108134,2
    dc.l 270336,0,0,2,2,108134,4
    dc.l 270336,0,0,4,2,108135,1
    dc.l 270336,0,0,1,2,108134,3
    dc.l 270336,0,0,3,2,108135,0
    dc.l -270336,0,0,0,2,-108134,-2
    dc.l -270336,0,0,-2,2,-108134,-4
    dc.l -270336,0,0,-4,2,-108135,-1
    dc.l -270336,0,0,-1,2,-108134,-3
    dc.l -270336,0,0,-3,2,-108135,0
    dc.l 5,0,0,0,2,2,0
    dc.l -1,0,0,0,2,0,-2
    dc.l -4,0,0,-2,2,-2,0
    dc.l 1,0,0,0,2,0,2
    dc.l -5,0,0,2,2,-1,-3
    dc.l 4,0,0,-3,2,1,0
verify_vectors_sim_ratio:
    dc.l 0,2,5,-4,2,0,-4
    dc.l 0,2,5,4,2,0,4
    dc.l 5,2,5,-4,2,1,1
    dc.l -5,2,5,4,2,-1,-1
    dc.l 2147483647,2,3200,3199,2,1342178,893
    dc.l -2147483648,2,3200,-3199,2,-1342178,-895
verify_vectors_sim_clock_delta:
    dc.l 0,0,0,0,2,0,0
    dc.l 0,0,0,24,2,0,24
    dc.l 1,0,0,0,2,0,12
    dc.l 1,0,0,24,2,1,11
    dc.l 17,0,0,0,2,8,4
    dc.l 17,0,0,24,2,9,3
    dc.l 85,0,0,0,2,40,20
    dc.l 85,0,0,24,2,41,19
    dc.l 200,0,0,0,2,96,0
    dc.l 200,0,0,24,2,96,24
    dc.l 32767,0,0,0,2,15728,4
    dc.l 32767,0,0,24,2,15729,3
    dc.l 0,0,0,0,5,0,0
    dc.l 0,0,0,24,5,0,24
    dc.l 1,0,0,0,5,1,5
    dc.l 1,0,0,24,5,2,4
    dc.l 17,0,0,0,5,20,10
    dc.l 17,0,0,24,5,21,9
    dc.l 85,0,0,0,5,102,0
    dc.l 85,0,0,24,5,102,24
    dc.l 200,0,0,0,5,240,0
    dc.l 200,0,0,24,5,240,24
    dc.l 32767,0,0,0,5,39320,10
    dc.l 32767,0,0,24,5,39321,9
verify_vectors_sim_distance:
    dc.l 0,0,0,0,2,0,0
    dc.l 0,0,0,3199,2,0,3199
    dc.l 1,0,0,0,2,0,20
    dc.l 1,0,0,3199,2,1,19
    dc.l 63,0,0,0,2,0,1260
    dc.l 63,0,0,3199,2,1,1259
    dc.l 64,0,0,0,2,0,1280
    dc.l 64,0,0,3199,2,1,1279
    dc.l 65536,65536,0,0,2,532,1536
    dc.l 65536,65536,0,3199,2,533,1535
    dc.l 65536,-65536,0,0,2,286,2304
    dc.l 65536,-65536,0,3199,2,287,2303
    dc.l 0,-270336,0,0,2,0,0
    dc.l 0,-270336,0,3199,2,0,0
    dc.l 10000000,270336,0,0,2,63006,2816
    dc.l 10000000,270336,0,3199,2,63007,2815
    dc.l 16777215,1048576,0,0,2,106823,2156
    dc.l 16777215,1048576,0,3199,2,106824,2155
    dc.l 0,0,0,0,5,0,0
    dc.l 0,0,0,3199,5,0,0
    dc.l 1,0,0,0,5,0,0
    dc.l 1,0,0,3199,5,0,0
    dc.l 63,0,0,0,5,0,0
    dc.l 63,0,0,3199,5,0,0
    dc.l 64,0,0,0,5,1,0
    dc.l 64,0,0,3199,5,1,0
    dc.l 65536,65536,0,0,5,1024,0
    dc.l 65536,65536,0,3199,5,1024,0
    dc.l 65536,-65536,0,0,5,1024,0
    dc.l 65536,-65536,0,3199,5,1024,0
    dc.l 0,-270336,0,0,5,0,0
    dc.l 0,-270336,0,3199,5,0,0
    dc.l 10000000,270336,0,0,5,156250,0
    dc.l 10000000,270336,0,3199,5,156250,0
    dc.l 16777215,1048576,0,0,5,262143,0
    dc.l 16777215,1048576,0,3199,5,262143,0
verify_vectors_sim_relax_word:
    dc.l -32768,827,0,0,2,-32354,-32768
    dc.l -32768,827,0,65535,2,-32355,32767
    dc.l -8000,827,0,0,2,-7899,3136
    dc.l -8000,827,0,65535,2,-7900,3135
    dc.l -32,827,0,0,2,-31,-26464
    dc.l -32,827,0,65535,2,-32,-26465
    dc.l -1,827,0,0,2,0,-827
    dc.l -1,827,0,65535,2,-1,-828
    dc.l 0,827,0,0,2,0,0
    dc.l 0,827,0,65535,2,0,-1
    dc.l 1,827,0,0,2,1,827
    dc.l 1,827,0,65535,2,0,826
    dc.l 32,827,0,0,2,32,26464
    dc.l 32,827,0,65535,2,31,26463
    dc.l 8000,827,0,0,2,7900,-3136
    dc.l 8000,827,0,65535,2,7899,-3137
    dc.l 32767,827,0,0,2,32354,31941
    dc.l 32767,827,0,65535,2,32353,31940
verify_vectors_sim_cadence:
    dc.l 2,0,0,0,2,0,2
    dc.l 2,0,0,1,2,0,3
    dc.l 2,0,0,2,2,0,4
    dc.l 2,0,0,3,2,1,0
    dc.l 2,0,0,4,2,1,1
    dc.l 5,0,0,0,5,1,0
    dc.l 5,0,0,1,5,1,1
    dc.l 5,0,0,2,5,1,2
    dc.l 5,0,0,3,5,1,3
    dc.l 5,0,0,4,5,1,4
verify_vectors_verify_width_case:
    dc.l 0,0,0,0,2,320,320
    dc.l 1,0,0,0,2,320,384
    dc.l 15,0,0,0,2,320,1280
    dc.l 16,0,0,0,2,384,320
    dc.l 85,0,0,0,2,640,640
    dc.l 171,0,0,0,2,960,1024
    dc.l 240,0,0,0,2,1280,320
    dc.l 254,0,0,0,2,1280,1216
verify_vectors_sim_traffic_delta:
    dc.l 0,0,0,0,2,0,0
    dc.l 0,0,0,49,2,0,0
    dc.l 0,-1536,0,0,2,0,0
    dc.l 0,-1536,0,49,2,0,0
    dc.l 1,0,0,0,2,0,20
    dc.l 1,0,0,49,2,1,19
    dc.l 100000,0,0,0,2,40000,0
    dc.l 100000,0,0,49,2,40000,49
    dc.l 100000,1536,0,0,2,39815,34
    dc.l 100000,1536,0,49,2,39816,33
    dc.l 100000,-1536,0,0,2,40184,16
    dc.l 100000,-1536,0,49,2,40185,15
    dc.l 16777215,1048576,0,0,2,6585056,44
    dc.l 16777215,1048576,0,49,2,6585057,43
    dc.l 0,0,0,0,5,0,0
    dc.l 0,0,0,49,5,0,0
    dc.l 0,-1536,0,0,5,0,0
    dc.l 0,-1536,0,49,5,0,0
    dc.l 1,0,0,0,5,1,0
    dc.l 1,0,0,49,5,1,0
    dc.l 100000,0,0,0,5,100000,0
    dc.l 100000,0,0,49,5,100000,0
    dc.l 100000,1536,0,0,5,100000,0
    dc.l 100000,1536,0,49,5,100000,0
    dc.l 100000,-1536,0,0,5,100000,0
    dc.l 100000,-1536,0,49,5,100000,0
    dc.l 16777215,1048576,0,0,5,16777215,0
    dc.l 16777215,1048576,0,49,5,16777215,0
verify_vectors_sim_reference_velocity:
    dc.l 0,-1048576,0,0,2,314572,0
    dc.l 0,-270336,0,0,2,81100,0
    dc.l 0,-1,0,0,2,0,0
    dc.l 0,0,0,0,2,0,0
    dc.l 0,1,0,0,2,0,0
    dc.l 0,270336,0,0,2,0,0
    dc.l 0,1048576,0,0,2,0,0
    dc.l 1,-1048576,0,0,2,314573,0
    dc.l 1,-270336,0,0,2,81101,0
    dc.l 1,-1,0,0,2,1,0
    dc.l 1,0,0,0,2,1,0
    dc.l 1,1,0,0,2,1,0
    dc.l 1,270336,0,0,2,0,0
    dc.l 1,1048576,0,0,2,0,0
    dc.l 65536,-1048576,0,0,2,380108,0
    dc.l 65536,-270336,0,0,2,146636,0
    dc.l 65536,-1,0,0,2,65536,0
    dc.l 65536,0,0,0,2,65536,0
    dc.l 65536,1,0,0,2,65536,0
    dc.l 65536,270336,0,0,2,0,0
    dc.l 65536,1048576,0,0,2,0,0
    dc.l 10000000,-1048576,0,0,2,10314572,0
    dc.l 10000000,-270336,0,0,2,10081100,0
    dc.l 10000000,-1,0,0,2,10000000,0
    dc.l 10000000,0,0,0,2,10000000,0
    dc.l 10000000,1,0,0,2,10000000,0
    dc.l 10000000,270336,0,0,2,9918900,0
    dc.l 10000000,1048576,0,0,2,9685428,0
    dc.l 16777215,-1048576,0,0,2,17091787,0
    dc.l 16777215,-270336,0,0,2,16858315,0
    dc.l 16777215,-1,0,0,2,16777215,0
    dc.l 16777215,0,0,0,2,16777215,0
    dc.l 16777215,1,0,0,2,16777215,0
    dc.l 16777215,270336,0,0,2,16696115,0
    dc.l 16777215,1048576,0,0,2,16462643,0
    dc.l 0,-1048576,0,0,5,0,0
    dc.l 0,-270336,0,0,5,0,0
    dc.l 0,-1,0,0,5,0,0
    dc.l 0,0,0,0,5,0,0
    dc.l 0,1,0,0,5,0,0
    dc.l 0,270336,0,0,5,0,0
    dc.l 0,1048576,0,0,5,0,0
    dc.l 1,-1048576,0,0,5,1,0
    dc.l 1,-270336,0,0,5,1,0
    dc.l 1,-1,0,0,5,1,0
    dc.l 1,0,0,0,5,1,0
    dc.l 1,1,0,0,5,1,0
    dc.l 1,270336,0,0,5,1,0
    dc.l 1,1048576,0,0,5,1,0
    dc.l 65536,-1048576,0,0,5,65536,0
    dc.l 65536,-270336,0,0,5,65536,0
    dc.l 65536,-1,0,0,5,65536,0
    dc.l 65536,0,0,0,5,65536,0
    dc.l 65536,1,0,0,5,65536,0
    dc.l 65536,270336,0,0,5,65536,0
    dc.l 65536,1048576,0,0,5,65536,0
    dc.l 10000000,-1048576,0,0,5,10000000,0
    dc.l 10000000,-270336,0,0,5,10000000,0
    dc.l 10000000,-1,0,0,5,10000000,0
    dc.l 10000000,0,0,0,5,10000000,0
    dc.l 10000000,1,0,0,5,10000000,0
    dc.l 10000000,270336,0,0,5,10000000,0
    dc.l 10000000,1048576,0,0,5,10000000,0
    dc.l 16777215,-1048576,0,0,5,16777215,0
    dc.l 16777215,-270336,0,0,5,16777215,0
    dc.l 16777215,-1,0,0,5,16777215,0
    dc.l 16777215,0,0,0,5,16777215,0
    dc.l 16777215,1,0,0,5,16777215,0
    dc.l 16777215,270336,0,0,5,16777215,0
    dc.l 16777215,1048576,0,0,5,16777215,0
verify_vectors_sim_lcg:
    dc.l 0,0,0,0,2,130253,0
    dc.l 1,0,0,0,2,137160,0
    dc.l -1,0,0,0,2,123346,0
    dc.l 4660,0,0,0,2,32316873,0
    dc.l 32767,0,0,0,2,226451922,0
    dc.l -32768,0,0,0,2,-226198323,0
verify_vectors_verify_visual_samples_case:
    dc.l 4660,0,0,0,2,32316873,26225
    dc.l 26225,0,0,0,2,181266328,5328
    dc.l 5328,0,0,0,2,36930749,-28635
    dc.l 4444,0,0,0,2,30824961,19241
    dc.l 19241,0,0,0,2,133027840,-23880
verify_vectors_sim_coarse_rate:
    dc.l -858993459,0,0,0,2,-2147483647,0
    dc.l -393216,0,0,0,2,-983040,0
    dc.l -65537,0,0,0,2,-163842,0
    dc.l -3,0,0,0,2,-7,0
    dc.l -2,0,0,0,2,-5,0
    dc.l -1,0,0,0,2,-2,0
    dc.l 0,0,0,0,2,0,0
    dc.l 1,0,0,0,2,2,0
    dc.l 2,0,0,0,2,5,0
    dc.l 3,0,0,0,2,7,0
    dc.l 65537,0,0,0,2,163842,0
    dc.l 393216,0,0,0,2,983040,0
    dc.l 858993459,0,0,0,2,2147483647,0
    dc.l -858993459,0,0,0,5,-858993459,0
    dc.l -393216,0,0,0,5,-393216,0
    dc.l -65537,0,0,0,5,-65537,0
    dc.l -3,0,0,0,5,-3,0
    dc.l -2,0,0,0,5,-2,0
    dc.l -1,0,0,0,5,-1,0
    dc.l 0,0,0,0,5,0,0
    dc.l 1,0,0,0,5,1,0
    dc.l 2,0,0,0,5,2,0
    dc.l 3,0,0,0,5,3,0
    dc.l 65537,0,0,0,5,65537,0
    dc.l 393216,0,0,0,5,393216,0
    dc.l 858993459,0,0,0,5,858993459,0
