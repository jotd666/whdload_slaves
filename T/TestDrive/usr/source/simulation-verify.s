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
    ; VERIFY_RANGE h4 01eee 8 C3 verify_visual_1023
    PL_PSS $01eee,verify_visual_1023,2
    ; VERIFY_RANGE h4 01f00 8 C3 verify_visual_255
    PL_PSS $01f00,verify_visual_255,2
    ; VERIFY_RANGE h4 01f10 8 C3 verify_visual_127
    PL_PSS $01f10,verify_visual_127,2
    ; VERIFY_RANGE h4 01f76 8 C3 verify_visual_3
    PL_PSS $01f76,verify_visual_3,2
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
